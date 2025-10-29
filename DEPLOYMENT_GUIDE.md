# Deployment Guide - gt-academy.com

## Server Information
- **Domain:** gt-academy.com
- **IP:** 45.93.139.14
- **SSH:** root@45.93.139.14
- **Important:** Do NOT touch taksoride project

---

## Pre-Deployment Checklist

### 1. Export Current Database
```bash
# On local machine (XAMPP)
cd C:\xampp\mysql\bin
.\mysqldump.exe -u root parfumes_db > C:\xampp\htdocs\parfumes\parfumes_db_backup.sql
```

### 2. Prepare Files for Upload
```bash
# Create deployment package
# Backend files
# Frontend built files
# Database backup
```

---

## Deployment Steps

### Step 1: Connect to Server
```bash
ssh root@45.93.139.14
```

### Step 2: Create Project Directory
```bash
# Navigate to web root (don't touch taksoride)
cd /var/www/html

# Create new directory for parfumes
mkdir -p gt-academy.com/parfumes
cd gt-academy.com/parfumes
```

### Step 3: Upload Backend Files
```bash
# On local machine, use SCP or SFTP
# Upload backend folder
scp -r C:\xampp\htdocs\parfumes\backend root@45.93.139.14:/var/www/html/gt-academy.com/parfumes/

# Or use FileZilla/WinSCP with these credentials:
# Host: 45.93.139.14
# Username: root
# Port: 22
# Path: /var/www/html/gt-academy.com/parfumes/
```

### Step 4: Upload Frontend Built Files
```bash
# Upload the built frontend (dist folder contents)
scp -r C:\xampp\htdocs\parfumes\index.html root@45.93.139.14:/var/www/html/gt-academy.com/parfumes/
scp -r C:\xampp\htdocs\parfumes\assets root@45.93.139.14:/var/www/html/gt-academy.com/parfumes/
```

### Step 5: Upload Database Backup
```bash
scp C:\xampp\htdocs\parfumes\parfumes_db_backup.sql root@45.93.139.14:/root/
```

### Step 6: Server Configuration

#### A. Install Required PHP Extensions (if not installed)
```bash
ssh root@45.93.139.14

# Check PHP version
php -v

# Install required extensions
apt update
apt install -y php-mysql php-mbstring php-xml php-curl php-zip php-gd
```

#### B. Configure Backend
```bash
cd /var/www/html/gt-academy.com/parfumes/backend

# Set permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Create .env file
cp .env.example .env
nano .env
```

**Update .env with production settings:**
```env
APP_NAME="Perfume Store"
APP_ENV=production
APP_KEY=base64:YOUR_KEY_HERE
APP_DEBUG=false
APP_URL=https://gt-academy.com/parfumes

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=parfumes_db
DB_USERNAME=parfumes_user
DB_PASSWORD=STRONG_PASSWORD_HERE

SESSION_DRIVER=file
QUEUE_CONNECTION=sync
```

#### C. Install Composer Dependencies
```bash
cd /var/www/html/gt-academy.com/parfumes/backend

# Install composer if not installed
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Install dependencies
composer install --no-dev --optimize-autoloader
```

#### D. Generate Application Key
```bash
php artisan key:generate
php artisan config:cache
php artisan route:cache
```

### Step 7: Database Setup

#### A. Create Database and User
```bash
# Login to MySQL
mysql -u root -p

# Create database
CREATE DATABASE parfumes_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Create user
CREATE USER 'parfumes_user'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_HERE';

# Grant privileges
GRANT ALL PRIVILEGES ON parfumes_db.* TO 'parfumes_user'@'localhost';
FLUSH PRIVILEGES;

# Exit MySQL
EXIT;
```

#### B. Import Database
```bash
# Import the backup
mysql -u parfumes_user -p parfumes_db < /root/parfumes_db_backup.sql

# Verify import
mysql -u parfumes_user -p parfumes_db -e "SHOW TABLES;"
```

#### C. Create Storage Link
```bash
cd /var/www/html/gt-academy.com/parfumes/backend
php artisan storage:link
```

### Step 8: Configure Nginx/Apache

#### For Nginx:
```bash
nano /etc/nginx/sites-available/gt-academy.com
```

**Add this configuration:**
```nginx
server {
    listen 80;
    server_name gt-academy.com www.gt-academy.com;
    root /var/www/html/gt-academy.com/parfumes;
    index index.html;

    # Frontend
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Backend API
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

    # Storage files
    location /backend/storage {
        alias /var/www/html/gt-academy.com/parfumes/backend/storage/app/public;
    }
}
```

#### For Apache:
```bash
nano /etc/apache2/sites-available/gt-academy.com.conf
```

**Add this configuration:**
```apache
<VirtualHost *:80>
    ServerName gt-academy.com
    ServerAlias www.gt-academy.com
    DocumentRoot /var/www/html/gt-academy.com/parfumes

    <Directory /var/www/html/gt-academy.com/parfumes>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    Alias /backend/public /var/www/html/gt-academy.com/parfumes/backend/public
    
    <Directory /var/www/html/gt-academy.com/parfumes/backend/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        
        <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^ index.php [L]
        </IfModule>
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/gt-academy-error.log
    CustomLog ${APACHE_LOG_DIR}/gt-academy-access.log combined
</VirtualHost>
```

**Enable site and restart:**
```bash
# For Apache
a2ensite gt-academy.com
a2enmod rewrite
systemctl restart apache2

# For Nginx
ln -s /etc/nginx/sites-available/gt-academy.com /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### Step 9: SSL Certificate (Optional but Recommended)
```bash
# Install Certbot
apt install -y certbot python3-certbot-nginx  # For Nginx
# OR
apt install -y certbot python3-certbot-apache  # For Apache

# Get certificate
certbot --nginx -d gt-academy.com -d www.gt-academy.com  # For Nginx
# OR
certbot --apache -d gt-academy.com -d www.gt-academy.com  # For Apache
```

### Step 10: Update Frontend API URL

**Update the built index.html or rebuild with production URL:**

On local machine, update:
```javascript
// frontend/src/services/api.js
const API_BASE_URL = 'https://gt-academy.com/backend/public/api'
```

Then rebuild:
```bash
cd C:\xampp\htdocs\parfumes\frontend
npm run build
```

Upload new build:
```bash
scp -r C:\xampp\htdocs\parfumes\frontend\dist/* root@45.93.139.14:/var/www/html/gt-academy.com/parfumes/
```

### Step 11: Set Proper Permissions
```bash
cd /var/www/html/gt-academy.com/parfumes

# Set ownership
chown -R www-data:www-data .

# Set directory permissions
find . -type d -exec chmod 755 {} \;

# Set file permissions
find . -type f -exec chmod 644 {} \;

# Storage and cache writable
chmod -R 775 backend/storage backend/bootstrap/cache
```

### Step 12: Verify Deployment

**Check these URLs:**
- https://gt-academy.com/parfumes (Frontend)
- https://gt-academy.com/backend/public/api (API)
- https://gt-academy.com/backend/public/api/products (Test endpoint)

---

## Post-Deployment

### 1. Test All Features
- [ ] Login
- [ ] POS
- [ ] Invoices list
- [ ] Invoice detail
- [ ] Payment recording
- [ ] Stock management
- [ ] PDF generation
- [ ] WhatsApp sharing

### 2. Monitor Logs
```bash
# Laravel logs
tail -f /var/www/html/gt-academy.com/parfumes/backend/storage/logs/laravel.log

# Nginx logs
tail -f /var/log/nginx/error.log

# Apache logs
tail -f /var/log/apache2/gt-academy-error.log
```

### 3. Setup Backup Cron
```bash
crontab -e

# Add daily backup at 2 AM
0 2 * * * mysqldump -u parfumes_user -pPASSWORD parfumes_db > /root/backups/parfumes_$(date +\%Y\%m\%d).sql
```

---

## Quick Deployment Script

Create this script on the server:

```bash
nano /root/deploy_parfumes.sh
```

```bash
#!/bin/bash

echo "Deploying Parfumes Project..."

# Navigate to project
cd /var/www/html/gt-academy.com/parfumes/backend

# Pull latest changes (if using git)
# git pull origin main

# Install dependencies
composer install --no-dev --optimize-autoloader

# Clear caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# Optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

echo "Deployment complete!"
```

Make executable:
```bash
chmod +x /root/deploy_parfumes.sh
```

---

## Troubleshooting

### Issue: 500 Error
```bash
# Check Laravel logs
tail -f /var/www/html/gt-academy.com/parfumes/backend/storage/logs/laravel.log

# Check permissions
ls -la /var/www/html/gt-academy.com/parfumes/backend/storage
```

### Issue: Database Connection Failed
```bash
# Test connection
mysql -u parfumes_user -p parfumes_db

# Check .env file
cat /var/www/html/gt-academy.com/parfumes/backend/.env | grep DB_
```

### Issue: API Not Found
```bash
# Check web server config
nginx -t  # For Nginx
apachectl configtest  # For Apache

# Check routes
cd /var/www/html/gt-academy.com/parfumes/backend
php artisan route:list
```

---

## Important Notes

1. **Keep taksoride untouched** - All parfumes files in separate directory
2. **Database is preserved** - Using backup and import
3. **Production environment** - Debug mode OFF
4. **SSL recommended** - Use Let's Encrypt (free)
5. **Regular backups** - Setup automated backups
6. **Monitor logs** - Check for errors regularly

---

## File Structure on Server

```
/var/www/html/gt-academy.com/
├── parfumes/
│   ├── index.html (Frontend)
│   ├── assets/ (Frontend assets)
│   └── backend/
│       ├── app/
│       ├── config/
│       ├── database/
│       ├── public/
│       ├── storage/
│       └── .env
└── (taksoride remains untouched)
```

---

**Ready to deploy! Follow these steps carefully and the project will be live on gt-academy.com! 🚀**
