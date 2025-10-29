#!/bin/bash
# Parfumes Deployment Script for gt-academy.com
# Run this on server: bash DEPLOY_NOW.sh

set -e  # Exit on error

echo "=========================================="
echo "Parfumes Deployment to gt-academy.com"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Create directory
echo -e "${YELLOW}[1/12] Creating project directory...${NC}"
mkdir -p /var/www/html/gt-academy.com/parfumes
cd /var/www/html/gt-academy.com/parfumes
echo -e "${GREEN}✓ Directory created at: $(pwd)${NC}"
echo ""

# Step 2: Wait for file upload
echo -e "${YELLOW}[2/12] Waiting for files...${NC}"
echo -e "${RED}ACTION REQUIRED:${NC}"
echo "Please upload these files now using FileZilla/WinSCP:"
echo "  To: /var/www/html/gt-academy.com/parfumes/"
echo "    - backend/ (folder)"
echo "    - index.html"
echo "    - assets/ (folder)"
echo ""
echo "  To: /root/"
echo "    - parfumes_db_backup.sql"
echo ""
read -p "Press Enter when upload is complete..."
echo -e "${GREEN}✓ Files uploaded${NC}"
echo ""

# Step 3: Check files
echo -e "${YELLOW}[3/12] Verifying files...${NC}"
if [ ! -d "backend" ]; then
    echo -e "${RED}✗ backend/ folder not found!${NC}"
    exit 1
fi
if [ ! -f "index.html" ]; then
    echo -e "${RED}✗ index.html not found!${NC}"
    exit 1
fi
if [ ! -f "/root/parfumes_db_backup.sql" ]; then
    echo -e "${RED}✗ Database backup not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ All files verified${NC}"
echo ""

# Step 4: Install Composer
echo -e "${YELLOW}[4/12] Installing Composer...${NC}"
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
    echo -e "${GREEN}✓ Composer installed${NC}"
else
    echo -e "${GREEN}✓ Composer already installed${NC}"
fi
echo ""

# Step 5: Install PHP extensions
echo -e "${YELLOW}[5/12] Installing PHP extensions...${NC}"
apt update -qq
apt install -y php-mysql php-mbstring php-xml php-curl php-zip php-gd php-bcmath > /dev/null 2>&1
echo -e "${GREEN}✓ PHP extensions installed${NC}"
echo ""

# Step 6: Install Composer dependencies
echo -e "${YELLOW}[6/12] Installing Composer dependencies...${NC}"
cd /var/www/html/gt-academy.com/parfumes/backend
composer install --no-dev --optimize-autoloader --quiet
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 7: Configure .env
echo -e "${YELLOW}[7/12] Configuring environment...${NC}"
if [ ! -f ".env" ]; then
    cp .env.example .env
fi

# Update .env
cat > .env << 'EOF'
APP_NAME="Perfume Store"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://gt-academy.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=parfumes_db
DB_USERNAME=parfumes_user
DB_PASSWORD=Parfumes2025Secure!

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF

# Generate key
php artisan key:generate --force
echo -e "${GREEN}✓ Environment configured${NC}"
echo ""

# Step 8: Setup database
echo -e "${YELLOW}[8/12] Setting up database...${NC}"
read -sp "Enter MySQL root password: " MYSQL_PASS
echo ""

mysql -u root -p"$MYSQL_PASS" << 'EOSQL'
CREATE DATABASE IF NOT EXISTS parfumes_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'parfumes_user'@'localhost' IDENTIFIED BY 'Parfumes2025Secure!';
GRANT ALL PRIVILEGES ON parfumes_db.* TO 'parfumes_user'@'localhost';
FLUSH PRIVILEGES;
EOSQL

# Import database
mysql -u parfumes_user -pParfumes2025Secure! parfumes_db < /root/parfumes_db_backup.sql
echo -e "${GREEN}✓ Database imported${NC}"
echo ""

# Step 9: Laravel setup
echo -e "${YELLOW}[9/12] Configuring Laravel...${NC}"
cd /var/www/html/gt-academy.com/parfumes/backend

php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo -e "${GREEN}✓ Laravel configured${NC}"
echo ""

# Step 10: Set permissions
echo -e "${YELLOW}[10/12] Setting permissions...${NC}"
cd /var/www/html/gt-academy.com/parfumes
chown -R www-data:www-data .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod -R 775 backend/storage backend/bootstrap/cache
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Step 11: Configure Nginx
echo -e "${YELLOW}[11/12] Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/gt-academy-parfumes << 'NGINX_EOF'
server {
    listen 80;
    server_name gt-academy.com www.gt-academy.com;
    
    root /var/www/html/gt-academy.com/parfumes;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /backend/public {
        alias /var/www/html/gt-academy.com/parfumes/backend/public;
        try_files $uri $uri/ @backend;

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $request_filename;
        }
    }

    location @backend {
        rewrite /backend/public/(.*)$ /backend/public/index.php?/$1 last;
    }

    location /backend/storage {
        alias /var/www/html/gt-academy.com/parfumes/backend/storage/app/public;
    }
}
NGINX_EOF

# Enable site
ln -sf /etc/nginx/sites-available/gt-academy-parfumes /etc/nginx/sites-enabled/

# Test and restart
nginx -t
systemctl restart nginx
systemctl restart php8.1-fpm

echo -e "${GREEN}✓ Nginx configured and restarted${NC}"
echo ""

# Step 12: Final verification
echo -e "${YELLOW}[12/12] Verifying installation...${NC}"
sleep 2

# Test API
API_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/backend/public/api)
if [ "$API_TEST" = "200" ]; then
    echo -e "${GREEN}✓ API is responding${NC}"
else
    echo -e "${YELLOW}⚠ API returned status: $API_TEST${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Deployment Complete!${NC}"
echo "=========================================="
echo ""
echo "URLs:"
echo "  Frontend: http://gt-academy.com/"
echo "  API: http://gt-academy.com/backend/public/api"
echo ""
echo "Database:"
echo "  Name: parfumes_db"
echo "  User: parfumes_user"
echo "  Pass: Parfumes2025Secure!"
echo ""
echo "Next steps:"
echo "1. Setup SSL: certbot --nginx -d gt-academy.com"
echo "2. Test the application in browser"
echo "3. Check logs: tail -f /var/www/html/gt-academy.com/parfumes/backend/storage/logs/laravel.log"
echo ""
