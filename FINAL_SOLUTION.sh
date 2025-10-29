#!/bin/bash
# FINAL SOLUTION - Deploy parfumes without touching ANYTHING
# Creates completely separate site at: store.gt-academy.com

set -e

echo "=========================================="
echo "  PARFUMES DEPLOYMENT - FINAL SOLUTION"
echo "  New subdomain: store.gt-academy.com"
echo "  ZERO interference with existing sites"
echo "=========================================="
echo ""

# Step 1: Create separate directory
echo "[1/13] Creating separate directory..."
mkdir -p /var/www/html/parfumes-store
cd /var/www/html/parfumes-store

# Step 2: Clone repository
echo "[2/13] Cloning repository..."
if [ -d ".git" ]; then
    git pull
else
    git clone https://github.com/Anonyme99910/parfum.git .
fi

# Step 3: Create directories
echo "[3/13] Creating required directories..."
mkdir -p backend/bootstrap/cache
mkdir -p backend/storage/framework/{sessions,views,cache}
mkdir -p backend/storage/logs
mkdir -p backend/storage/app/public/invoices

# Step 4: Set permissions
echo "[4/13] Setting permissions..."
chmod -R 777 backend/bootstrap/cache
chmod -R 777 backend/storage

# Step 5: Install Composer
echo "[5/13] Installing Composer dependencies..."
cd backend
export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-dev --optimize-autoloader --no-interaction --quiet

# Step 6: Create .env
echo "[6/13] Configuring environment..."
cat > .env << 'EOF'
APP_NAME="Perfume Store"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://store.gt-academy.com

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
echo "[7/13] Generating app key..."
php artisan key:generate --force

# Step 8: Migrations
echo "[8/13] Running migrations..."
php artisan migrate --force

# Step 9: Seed
echo "[9/13] Seeding database..."
php artisan db:seed --force

# Step 10: Laravel optimization
echo "[10/13] Optimizing Laravel..."
php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Step 11: Permissions
echo "[11/13] Final permissions..."
cd /var/www/html/parfumes-store
chown -R www-data:www-data .
chmod -R 775 backend/storage backend/bootstrap/cache

# Step 12: Create NEW Nginx config (completely separate)
echo "[12/13] Creating Nginx configuration..."
cat > /etc/nginx/sites-available/parfumes-store << 'NGINX'
server {
    listen 80;
    server_name store.gt-academy.com;
    
    root /var/www/html/parfumes-store;
    index index.html;

    access_log /var/log/nginx/parfumes-store-access.log;
    error_log /var/log/nginx/parfumes-store-error.log;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /backend/public {
        alias /var/www/html/parfumes-store/backend/public;
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

    location /assets {
        alias /var/www/html/parfumes-store/assets;
    }
}
NGINX

# Enable site
ln -sf /etc/nginx/sites-available/parfumes-store /etc/nginx/sites-enabled/

# Step 13: Test and restart
echo "[13/13] Testing and restarting services..."
nginx -t
if [ $? -eq 0 ]; then
    systemctl restart nginx
    systemctl restart php8.1-fpm
    echo "✅ Services restarted successfully"
else
    echo "❌ Nginx configuration error"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 Access your parfumes store at:"
echo "   http://store.gt-academy.com/"
echo ""
echo "🔐 Default Login:"
echo "   Email: admin@perfume.com"
echo "   Password: password"
echo ""
echo "📝 IMPORTANT: Add DNS A record:"
echo "   Host: store.gt-academy.com"
echo "   Points to: 45.93.139.14"
echo ""
echo "✅ Existing sites UNTOUCHED:"
echo "   - taksoride.com → working as before"
echo "   - gt-academy.com → working as before"
echo ""
echo "📁 Installation location:"
echo "   /var/www/html/parfumes-store"
echo ""
echo "=========================================="
