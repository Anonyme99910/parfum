#!/bin/bash
# Final Safe Deployment - Does NOT touch taksoride or existing gt-academy.com
# Deploys parfumes to: parfumes.gt-academy.com

set -e

echo "=========================================="
echo "  SAFE PARFUMES DEPLOYMENT"
echo "  Domain: parfumes.gt-academy.com"
echo "  Does NOT touch existing sites"
echo "=========================================="
echo ""

# Step 1: Ensure directory exists
echo "[1/12] Setting up directory..."
cd /var/www/html/gt-academy.com
if [ ! -d "parfumes" ]; then
    mkdir parfumes
fi
cd parfumes

# Step 2: Clone if needed
if [ ! -d ".git" ]; then
    echo "[2/12] Cloning repository..."
    git clone https://github.com/Anonyme99910/parfum.git .
else
    echo "[2/12] Repository already exists, pulling latest..."
    git pull
fi

# Step 3: Create directories
echo "[3/12] Creating directories..."
mkdir -p backend/bootstrap/cache
mkdir -p backend/storage/framework/{sessions,views,cache}
mkdir -p backend/storage/logs
mkdir -p backend/storage/app/public/invoices

# Step 4: Set permissions
echo "[4/12] Setting permissions..."
chmod -R 777 backend/bootstrap/cache
chmod -R 777 backend/storage

# Step 5: Install Composer
echo "[5/12] Installing Composer dependencies..."
cd backend
export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-dev --optimize-autoloader --no-interaction --quiet

# Step 6: Create .env
echo "[6/12] Configuring environment..."
cat > .env << 'EOF'
APP_NAME="Perfume Store"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://parfumes.gt-academy.com

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=parfume
DB_USERNAME=store
DB_PASSWORD=Terma987@@

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF

# Step 7: Generate key
echo "[7/12] Generating app key..."
php artisan key:generate --force

# Step 8: Migrations
echo "[8/12] Running migrations..."
php artisan migrate --force

# Step 9: Seed
echo "[9/12] Seeding database..."
php artisan db:seed --force

# Step 10: Laravel optimization
echo "[10/12] Optimizing Laravel..."
php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Step 11: Permissions
echo "[11/12] Final permissions..."
cd /var/www/html/gt-academy.com/parfumes
chown -R www-data:www-data .
chmod -R 775 backend/storage backend/bootstrap/cache

# Step 12: Nginx config (SEPARATE - does not touch existing)
echo "[12/12] Configuring Nginx..."
cat > /etc/nginx/sites-available/parfumes-gt-academy << 'NGINX'
server {
    listen 80;
    server_name parfumes.gt-academy.com;
    
    root /var/www/html/gt-academy.com/parfumes;
    index index.html;

    access_log /var/log/nginx/parfumes-access.log;
    error_log /var/log/nginx/parfumes-error.log;

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
}
NGINX

# Enable site
ln -sf /etc/nginx/sites-available/parfumes-gt-academy /etc/nginx/sites-enabled/

# Test nginx
nginx -t

# Restart services
systemctl restart nginx
systemctl restart php8.1-fpm

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 Access your site at:"
echo "   http://parfumes.gt-academy.com/"
echo ""
echo "🔐 Default Login:"
echo "   Email: admin@perfume.com"
echo "   Password: password"
echo ""
echo "📝 Note: Add DNS A record for parfumes.gt-academy.com"
echo "   pointing to your server IP"
echo ""
echo "✅ Existing sites NOT touched:"
echo "   - taksoride.com (unchanged)"
echo "   - gt-academy.com (unchanged)"
echo ""
echo "=========================================="
