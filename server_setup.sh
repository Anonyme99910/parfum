#!/bin/bash

# Parfumes Project - Server Setup Script
# Server: root@45.93.139.14
# Domain: gt-academy.com

echo "========================================="
echo "Parfumes Project - Server Setup"
echo "========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/var/www/html/gt-academy.com/parfumes"
BACKEND_DIR="$PROJECT_DIR/backend"
DB_NAME="parfumes_db"
DB_USER="parfumes_user"
DB_PASS="Parfumes@2025#Secure"  # Change this!

# Step 1: Create project directory
echo -e "${YELLOW}[1/10] Creating project directory...${NC}"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
echo -e "${GREEN}✓ Directory created${NC}"
echo ""

# Step 2: Set initial permissions
echo -e "${YELLOW}[2/10] Setting initial permissions...${NC}"
chown -R www-data:www-data $PROJECT_DIR
echo -e "${GREEN}✓ Permissions set${NC}"
echo ""

# Step 3: Install PHP extensions (if needed)
echo -e "${YELLOW}[3/10] Checking PHP extensions...${NC}"
apt update
apt install -y php-mysql php-mbstring php-xml php-curl php-zip php-gd php-bcmath
echo -e "${GREEN}✓ PHP extensions installed${NC}"
echo ""

# Step 4: Install Composer (if not installed)
echo -e "${YELLOW}[4/10] Checking Composer...${NC}"
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    echo -e "${GREEN}✓ Composer installed${NC}"
else
    echo -e "${GREEN}✓ Composer already installed${NC}"
fi
echo ""

# Step 5: Wait for files to be uploaded
echo -e "${YELLOW}[5/10] Waiting for files...${NC}"
echo -e "${RED}PAUSE: Please upload the following files now:${NC}"
echo "  - backend/ folder"
echo "  - index.html"
echo "  - assets/ folder"
echo "  - parfumes_db_backup.sql to /root/"
echo ""
read -p "Press Enter when files are uploaded..."
echo -e "${GREEN}✓ Files uploaded${NC}"
echo ""

# Step 6: Install Composer dependencies
echo -e "${YELLOW}[6/10] Installing Composer dependencies...${NC}"
cd $BACKEND_DIR
composer install --no-dev --optimize-autoloader
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 7: Configure .env
echo -e "${YELLOW}[7/10] Configuring environment...${NC}"
if [ ! -f "$BACKEND_DIR/.env" ]; then
    cp $BACKEND_DIR/.env.example $BACKEND_DIR/.env
fi

# Update .env file
sed -i "s/APP_ENV=.*/APP_ENV=production/" $BACKEND_DIR/.env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" $BACKEND_DIR/.env
sed -i "s|APP_URL=.*|APP_URL=https://gt-academy.com|" $BACKEND_DIR/.env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" $BACKEND_DIR/.env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" $BACKEND_DIR/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" $BACKEND_DIR/.env

# Generate app key
php artisan key:generate
echo -e "${GREEN}✓ Environment configured${NC}"
echo ""

# Step 8: Setup Database
echo -e "${YELLOW}[8/10] Setting up database...${NC}"
read -sp "Enter MySQL root password: " MYSQL_ROOT_PASS
echo ""

mysql -u root -p$MYSQL_ROOT_PASS <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import database
if [ -f "/root/parfumes_db_backup.sql" ]; then
    mysql -u $DB_USER -p$DB_PASS $DB_NAME < /root/parfumes_db_backup.sql
    echo -e "${GREEN}✓ Database imported${NC}"
else
    echo -e "${RED}✗ Database backup not found at /root/parfumes_db_backup.sql${NC}"
fi
echo ""

# Step 9: Laravel setup
echo -e "${YELLOW}[9/10] Finalizing Laravel setup...${NC}"
cd $BACKEND_DIR

# Storage link
php artisan storage:link

# Cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

echo -e "${GREEN}✓ Laravel setup complete${NC}"
echo ""

# Step 10: Configure web server
echo -e "${YELLOW}[10/10] Web server configuration...${NC}"
echo ""
echo -e "${YELLOW}Please configure your web server (Nginx/Apache)${NC}"
echo "See DEPLOYMENT_GUIDE.md for configuration examples"
echo ""
echo -e "${GREEN}Configuration file locations:${NC}"
echo "  Nginx: /etc/nginx/sites-available/gt-academy.com"
echo "  Apache: /etc/apache2/sites-available/gt-academy.com.conf"
echo ""

# Final permissions
chown -R www-data:www-data $PROJECT_DIR
find $PROJECT_DIR -type d -exec chmod 755 {} \;
find $PROJECT_DIR -type f -exec chmod 644 {} \;
chmod -R 775 $BACKEND_DIR/storage $BACKEND_DIR/bootstrap/cache

echo ""
echo "========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Configure web server (Nginx/Apache)"
echo "2. Setup SSL certificate (certbot)"
echo "3. Test the application"
echo ""
echo "Application URLs:"
echo "  Frontend: https://gt-academy.com/parfumes"
echo "  API: https://gt-academy.com/backend/public/api"
echo ""
echo "Database:"
echo "  Name: $DB_NAME"
echo "  User: $DB_USER"
echo "  Pass: $DB_PASS"
echo ""
