#!/bin/bash
# Deploy to gt-academy.com WITHOUT touching taksoride.com
# This will REPLACE the current gt-academy.com content

set -e

echo "=========================================="
echo "  DEPLOYING TO GT-ACADEMY.COM"
echo "  WARNING: This will replace gt-academy.com"
echo "  taksoride.com will NOT be touched"
echo "=========================================="
echo ""

# Step 1: Backup current gt-academy.com
echo "[1/14] Backing up current gt-academy.com..."
if [ -d "/var/www/html/gt-academy.com.backup" ]; then
    rm -rf /var/www/html/gt-academy.com.backup
fi
cp -r /var/www/html/gt-academy.com /var/www/html/gt-academy.com.backup
echo "✓ Backup created at /var/www/html/gt-academy.com.backup"

# Step 2: Clear gt-academy.com directory (keep taksoride untouched)
echo "[2/14] Preparing gt-academy.com directory..."
cd /var/www/html/gt-academy.com
# Remove everything except taksoride
find . -maxdepth 1 ! -name 'taksoride*' ! -name '.' ! -name '..' -exec rm -rf {} +
echo "✓ Directory prepared"

# Step 3: Clone parfumes
echo "[3/14] Cloning parfumes repository..."
git clone https://github.com/Anonyme99910/parfum.git temp-parfumes
mv temp-parfumes/* .
mv temp-parfumes/.* . 2>/dev/null || true
rm -rf temp-parfumes
echo "✓ Repository cloned"

# Step 4: Create directories
echo "[4/14] Creating directories..."
mkdir -p backend/bootstrap/cache
mkdir -p backend/storage/framework/{sessions,views,cache}
mkdir -p backend/storage/logs
mkdir -p backend/storage/app/public/invoices
chmod -R 777 backend/bootstrap/cache backend/storage

# Step 5: Install Composer
echo "[5/14] Installing Composer dependencies..."
cd backend
export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-dev --optimize-autoloader --no-interaction --quiet

# Step 6: Create .env
echo "[6/14] Configuring environment..."
cat > .env << 'EOF'
APP_NAME="Perfume Store"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://gt-academy.com

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
echo "[7/14] Generating app key..."
php artisan key:generate --force

# Step 8: Migrations
echo "[8/14] Running migrations..."
php artisan migrate --force

# Step 9: Seed (skip if data exists)
echo "[9/14] Seeding database..."
php artisan db:seed --force 2>/dev/null || echo "Skipping seed (data exists)"

# Step 10: Laravel optimization
echo "[10/14] Optimizing Laravel..."
php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Step 11: Permissions
echo "[11/14] Setting permissions..."
cd /var/www/html/gt-academy.com
chown -R www-data:www-data .
chmod -R 775 backend/storage backend/bootstrap/cache

# Step 12: Update Nginx config
echo "[12/14] Updating Nginx configuration..."
cat > /etc/nginx/sites-available/gt-academy.com << 'NGINX'
server {
    listen 80;
    server_name gt-academy.com www.gt-academy.com;
    
    root /var/www/html/gt-academy.com;
    index index.html;

    access_log /var/log/nginx/gt-academy-access.log;
    error_log /var/log/nginx/gt-academy-error.log;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /backend/public {
        alias /var/www/html/gt-academy.com/backend/public;
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
        alias /var/www/html/gt-academy.com/assets;
    }
}
NGINX

# Step 13: Test and restart
echo "[13/14] Testing Nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
    echo "[14/14] Restarting services..."
    systemctl restart nginx
    systemctl restart php8.1-fpm
    echo "✓ Services restarted"
else
    echo "✗ Nginx configuration error"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 Your parfumes store is now at:"
echo "   https://gt-academy.com/"
echo ""
echo "🔐 Default Login:"
echo "   Email: admin@perfume.com"
echo "   Password: password"
echo ""
echo "✅ Status:"
echo "   - gt-academy.com → Parfumes Store (NEW)"
echo "   - taksoride.com → Untouched"
echo ""
echo "📁 Backup of old gt-academy.com:"
echo "   /var/www/html/gt-academy.com.backup"
echo ""
echo "=========================================="
