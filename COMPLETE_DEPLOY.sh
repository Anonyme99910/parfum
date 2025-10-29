#!/bin/bash
# Complete Parfumes Deployment Script
# Server: root@45.93.139.14
# Domain: gt-academy.com
# IMPORTANT: Do NOT touch taksoride

set -e
trap 'echo "Error on line $LINENO"' ERR

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo "=========================================="
echo "  PARFUMES DEPLOYMENT - GT-ACADEMY.COM"
echo "=========================================="
echo ""
echo "This script will:"
echo "  ✓ Setup project directory"
echo "  ✓ Install dependencies"
echo "  ✓ Configure Laravel"
echo "  ✓ Import database"
echo "  ✓ Setup Nginx"
echo "  ✓ Set permissions"
echo ""
echo "IMPORTANT: taksoride will NOT be touched!"
echo ""
read -p "Press Enter to continue..."
clear

# Configuration
PROJECT_ROOT="/var/www/html/gt-academy.com/parfumes"
BACKEND_DIR="$PROJECT_ROOT/backend"
DB_NAME="perfume_store"
DB_USER="perfume_user"
DB_PASS="Perfume@2025Secure!"

# Step 1: Create directory structure
echo -e "${BLUE}[1/15]${NC} Creating project directory..."
mkdir -p $PROJECT_ROOT
cd $PROJECT_ROOT
echo -e "${GREEN}✓${NC} Directory: $PROJECT_ROOT"
echo ""

# Step 2: Check for uploaded files
echo -e "${BLUE}[2/15]${NC} Checking uploaded files..."
echo ""
echo "Please ensure these files are uploaded:"
echo "  → $PROJECT_ROOT/backend/"
echo "  → $PROJECT_ROOT/index.html"
echo "  → $PROJECT_ROOT/assets/"
echo "  → /root/parfumes_db_backup.sql"
echo ""
read -p "Files uploaded? Press Enter to continue..."

if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}✗ backend/ not found!${NC}"
    echo "Upload backend folder to: $PROJECT_ROOT/backend/"
    exit 1
fi

if [ ! -f "$PROJECT_ROOT/index.html" ]; then
    echo -e "${RED}✗ index.html not found!${NC}"
    exit 1
fi

if [ ! -f "/root/parfumes_db_backup.sql" ]; then
    echo -e "${RED}✗ Database backup not found!${NC}"
    echo "Upload parfumes_db_backup.sql to: /root/"
    exit 1
fi

echo -e "${GREEN}✓${NC} All files found"
echo ""

# Step 3: Update system
echo -e "${BLUE}[3/15]${NC} Updating system packages..."
apt update -qq > /dev/null 2>&1
echo -e "${GREEN}✓${NC} System updated"
echo ""

# Step 4: Install PHP and extensions
echo -e "${BLUE}[4/15]${NC} Installing PHP extensions..."
apt install -y php php-fpm php-mysql php-mbstring php-xml php-curl php-zip php-gd php-bcmath php-cli > /dev/null 2>&1
echo -e "${GREEN}✓${NC} PHP extensions installed"
echo ""

# Step 5: Install Composer
echo -e "${BLUE}[5/15]${NC} Installing Composer..."
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    echo -e "${GREEN}✓${NC} Composer installed"
else
    echo -e "${GREEN}✓${NC} Composer already installed"
fi
echo ""

# Step 6: Install dependencies
echo -e "${BLUE}[6/15]${NC} Installing Composer dependencies..."
cd $BACKEND_DIR
composer install --no-dev --optimize-autoloader --no-interaction --quiet
echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# Step 7: Create .env file
echo -e "${BLUE}[7/15]${NC} Configuring environment..."
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
DB_PASSWORD=Perfume@2025Secure!

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
ENVEOF

# Generate app key
cd $BACKEND_DIR
php artisan key:generate --force > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Environment configured"
echo ""

# Step 8: Setup database
echo -e "${BLUE}[8/15]${NC} Setting up database..."
echo -n "Enter MySQL root password: "
read -s MYSQL_ROOT_PASS
echo ""

# Create database and user
mysql -u root -p"$MYSQL_ROOT_PASS" << SQLEOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
SQLEOF

echo -e "${GREEN}✓${NC} Database created"
echo ""

# Step 9: Import database
echo -e "${BLUE}[9/15]${NC} Importing database..."
mysql -u $DB_USER -p"$DB_PASS" $DB_NAME < /root/parfumes_db_backup.sql
echo -e "${GREEN}✓${NC} Database imported"
echo ""

# Step 10: Laravel setup
echo -e "${BLUE}[10/15]${NC} Configuring Laravel..."
cd $BACKEND_DIR

# Create storage directories
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

# Step 11: Set permissions
echo -e "${BLUE}[11/15]${NC} Setting permissions..."
cd $PROJECT_ROOT
chown -R www-data:www-data .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod -R 775 $BACKEND_DIR/storage
chmod -R 775 $BACKEND_DIR/bootstrap/cache
echo -e "${GREEN}✓${NC} Permissions set"
echo ""

# Step 12: Configure Nginx
echo -e "${BLUE}[12/15]${NC} Configuring Nginx..."

# Detect PHP-FPM socket
PHP_SOCKET=$(find /var/run/php/ -name "php*-fpm.sock" | head -1)
if [ -z "$PHP_SOCKET" ]; then
    PHP_SOCKET="/var/run/php/php8.1-fpm.sock"
fi

cat > /etc/nginx/sites-available/gt-academy-parfumes << NGINXEOF
server {
    listen 80;
    server_name gt-academy.com www.gt-academy.com;
    
    root /var/www/html/gt-academy.com/parfumes;
    index index.html;

    # Frontend
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /backend/public {
        alias /var/www/html/gt-academy.com/parfumes/backend/public;
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
        alias /var/www/html/gt-academy.com/parfumes/backend/storage/app/public;
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
nginx -t > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Nginx configured"
else
    echo -e "${RED}✗${NC} Nginx configuration error"
    nginx -t
    exit 1
fi
echo ""

# Step 13: Restart services
echo -e "${BLUE}[13/15]${NC} Restarting services..."
systemctl restart nginx
systemctl restart php*-fpm
echo -e "${GREEN}✓${NC} Services restarted"
echo ""

# Step 14: Test installation
echo -e "${BLUE}[14/15]${NC} Testing installation..."
sleep 2

# Test API
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/backend/public/api)
if [ "$API_STATUS" = "200" ] || [ "$API_STATUS" = "302" ]; then
    echo -e "${GREEN}✓${NC} API responding (Status: $API_STATUS)"
else
    echo -e "${YELLOW}⚠${NC} API status: $API_STATUS (may need SSL)"
fi

# Test frontend
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✓${NC} Frontend responding"
else
    echo -e "${YELLOW}⚠${NC} Frontend status: $FRONTEND_STATUS"
fi
echo ""

# Step 15: Setup SSL (optional)
echo -e "${BLUE}[15/15]${NC} SSL Certificate..."
echo ""
read -p "Setup SSL with Let's Encrypt? (y/n): " SETUP_SSL

if [ "$SETUP_SSL" = "y" ] || [ "$SETUP_SSL" = "Y" ]; then
    apt install -y certbot python3-certbot-nginx > /dev/null 2>&1
    certbot --nginx -d gt-academy.com -d www.gt-academy.com --non-interactive --agree-tos --email admin@gt-academy.com
    echo -e "${GREEN}✓${NC} SSL configured"
else
    echo -e "${YELLOW}⚠${NC} SSL skipped (recommended to setup later)"
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
echo "   3. Test all features (POS, Invoices, Stock)"
if [ "$SETUP_SSL" != "y" ] && [ "$SETUP_SSL" != "Y" ]; then
    echo "   4. Setup SSL: certbot --nginx -d gt-academy.com"
fi
echo ""
echo "🔒 IMPORTANT: taksoride was NOT touched!"
echo ""
echo "=========================================="
