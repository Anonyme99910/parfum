#!/bin/bash
# Perfume Store - Server Deployment Script
# For: gt-academy.com
# Run: bash deploy_server.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "=========================================="
echo "  PERFUME STORE DEPLOYMENT"
echo "  gt-academy.com"
echo "=========================================="
echo ""

# Configuration
CURRENT_DIR=$(pwd)
PROJECT_ROOT="$CURRENT_DIR"
BACKEND_DIR="$PROJECT_ROOT/backend"
DB_NAME="perfume_store"
DB_USER="perfume_user"
DB_PASS="Perfume2025Secure!"

echo -e "${BLUE}Project Directory:${NC} $PROJECT_ROOT"
echo ""

# Step 1: Update system
echo -e "${YELLOW}[1/11]${NC} Updating system packages..."
apt update -qq > /dev/null 2>&1
echo -e "${GREEN}✓${NC} System updated"
echo ""

# Step 2: Install PHP
echo -e "${YELLOW}[2/11]${NC} Installing PHP and extensions..."
apt install -y php php-fpm php-mysql php-mbstring php-xml php-curl php-zip php-gd php-bcmath php-cli unzip > /dev/null 2>&1
echo -e "${GREEN}✓${NC} PHP installed"
echo ""

# Step 3: Install Composer
echo -e "${YELLOW}[3/11]${NC} Installing Composer..."
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    echo -e "${GREEN}✓${NC} Composer installed"
else
    echo -e "${GREEN}✓${NC} Composer already installed"
fi
echo ""

# Step 4: Install Composer dependencies
echo -e "${YELLOW}[4/11]${NC} Installing Composer dependencies..."
cd $BACKEND_DIR
composer install --no-dev --optimize-autoloader --no-interaction --quiet
echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# Step 5: Configure environment
echo -e "${YELLOW}[5/11]${NC} Configuring environment..."
if [ ! -f "$BACKEND_DIR/.env" ]; then
    cp $BACKEND_DIR/.env.example $BACKEND_DIR/.env
fi

# Update .env
cat > $BACKEND_DIR/.env << 'ENVEOF'
APP_NAME="Perfume Store"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://gt-academy.com

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=perfume_store
DB_USERNAME=perfume_user
DB_PASSWORD=Perfume2025Secure!

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
ENVEOF

# Generate app key
php artisan key:generate --force > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Environment configured"
echo ""

# Step 6: Setup database
echo -e "${YELLOW}[6/11]${NC} Setting up database..."
read -sp "Enter MySQL root password: " MYSQL_ROOT_PASS
echo ""

mysql -u root -p"$MYSQL_ROOT_PASS" << SQLEOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SQLEOF

echo -e "${GREEN}✓${NC} Database created"
echo ""

# Step 7: Run migrations
echo -e "${YELLOW}[7/11]${NC} Running migrations..."
cd $BACKEND_DIR
php artisan migrate --force > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Migrations completed"
echo ""

# Ask about seeding
read -p "Run database seeders? (y/n): " RUN_SEED
if [ "$RUN_SEED" = "y" ] || [ "$RUN_SEED" = "Y" ]; then
    php artisan db:seed --force > /dev/null 2>&1
    echo -e "${GREEN}✓${NC} Database seeded"
fi
echo ""

# Step 8: Laravel setup
echo -e "${YELLOW}[8/11]${NC} Configuring Laravel..."
cd $BACKEND_DIR

# Create directories
mkdir -p storage/app/public/invoices
mkdir -p storage/framework/{sessions,views,cache}
mkdir -p storage/logs
mkdir -p bootstrap/cache

# Create storage link
php artisan storage:link --force > /dev/null 2>&1

# Cache configuration
php artisan config:cache > /dev/null 2>&1
php artisan route:cache > /dev/null 2>&1
php artisan view:cache > /dev/null 2>&1

echo -e "${GREEN}✓${NC} Laravel configured"
echo ""

# Step 9: Set permissions
echo -e "${YELLOW}[9/11]${NC} Setting permissions..."
cd $PROJECT_ROOT
chown -R www-data:www-data .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod -R 775 $BACKEND_DIR/storage
chmod -R 775 $BACKEND_DIR/bootstrap/cache
echo -e "${GREEN}✓${NC} Permissions set"
echo ""

# Step 10: Configure Nginx
echo -e "${YELLOW}[10/11]${NC} Configuring Nginx..."

# Detect PHP-FPM socket
PHP_SOCKET=$(find /var/run/php/ -name "php*-fpm.sock" 2>/dev/null | head -1)
if [ -z "$PHP_SOCKET" ]; then
    PHP_SOCKET="/var/run/php/php8.1-fpm.sock"
fi

cat > /etc/nginx/sites-available/gt-academy-parfumes << NGINXEOF
server {
    listen 80;
    server_name gt-academy.com www.gt-academy.com;
    
    root $PROJECT_ROOT;
    index index.html;

    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /backend/public {
        alias $PROJECT_ROOT/backend/public;
        try_files \$uri \$uri/ @backend;

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:$PHP_SOCKET;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
            fastcgi_param PATH_INFO \$fastcgi_path_info;
        }
    }

    location @backend {
        rewrite /backend/public/(.*)\$ /backend/public/index.php?/\$1 last;
    }

    # Storage files
    location /backend/storage {
        alias $PROJECT_ROOT/backend/storage/app/public;
        try_files \$uri =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Disable access to hidden files
    location ~ /\. {
        deny all;
    }
}
NGINXEOF

# Enable site
ln -sf /etc/nginx/sites-available/gt-academy-parfumes /etc/nginx/sites-enabled/

# Test configuration
if nginx -t > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Nginx configured"
else
    echo -e "${RED}✗${NC} Nginx configuration error"
    nginx -t
    exit 1
fi
echo ""

# Step 11: Restart services
echo -e "${YELLOW}[11/11]${NC} Restarting services..."
systemctl restart nginx
systemctl restart php*-fpm
echo -e "${GREEN}✓${NC} Services restarted"
echo ""

# Test installation
echo -e "${BLUE}Testing installation...${NC}"
sleep 2

API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/backend/public/api 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ] || [ "$API_STATUS" = "302" ]; then
    echo -e "${GREEN}✓${NC} API responding (Status: $API_STATUS)"
else
    echo -e "${YELLOW}⚠${NC} API status: $API_STATUS"
fi

FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✓${NC} Frontend responding"
else
    echo -e "${YELLOW}⚠${NC} Frontend status: $FRONTEND_STATUS"
fi
echo ""

# SSL Setup
read -p "Setup SSL with Let's Encrypt? (y/n): " SETUP_SSL
if [ "$SETUP_SSL" = "y" ] || [ "$SETUP_SSL" = "Y" ]; then
    echo "Installing Certbot..."
    apt install -y certbot python3-certbot-nginx > /dev/null 2>&1
    certbot --nginx -d gt-academy.com -d www.gt-academy.com --non-interactive --agree-tos --email admin@gt-academy.com || echo "SSL setup failed, run manually later"
fi
echo ""

# Final summary
clear
echo "=========================================="
echo -e "${GREEN}  DEPLOYMENT SUCCESSFUL!${NC}"
echo "=========================================="
echo ""
echo "📍 URLs:"
echo "   Frontend: http://gt-academy.com/"
echo "   API: http://gt-academy.com/backend/public/api"
echo ""
echo "🗄️  Database:"
echo "   Name: $DB_NAME"
echo "   User: $DB_USER"
echo "   Pass: $DB_PASS"
echo ""
echo "📁 Project Location:"
echo "   $PROJECT_ROOT"
echo ""
echo "📝 Logs:"
echo "   Laravel: $BACKEND_DIR/storage/logs/laravel.log"
echo "   Nginx: /var/log/nginx/error.log"
echo ""
echo "✅ Next Steps:"
echo "   1. Visit http://gt-academy.com/ in browser"
echo "   2. Login with your credentials"
echo "   3. Test all features"
if [ "$SETUP_SSL" != "y" ] && [ "$SETUP_SSL" != "Y" ]; then
    echo "   4. Setup SSL: certbot --nginx -d gt-academy.com"
fi
echo ""
echo "=========================================="
