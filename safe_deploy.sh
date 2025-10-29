#!/bin/bash
# Safe Deployment - Keeps existing gt-academy.com redirect to taksoride
# Adds parfumes at: gt-academy.com/parfumes

set -e

echo "=========================================="
echo "  SAFE PARFUMES DEPLOYMENT"
echo "  Path: gt-academy.com/parfumes"
echo "  Keeps redirect to taksoride intact"
echo "=========================================="
echo ""

# Step 1: Setup directory
echo "[1/12] Setting up directory..."
cd /var/www/html/gt-academy.com
if [ ! -d "parfumes" ]; then
    mkdir parfumes
fi
cd parfumes

# Step 2: Clone
if [ ! -d ".git" ]; then
    echo "[2/12] Cloning repository..."
    git clone https://github.com/Anonyme99910/parfum.git .
else
    echo "[2/12] Updating repository..."
    git pull
fi

# Step 3: Create directories
echo "[3/12] Creating directories..."
mkdir -p backend/bootstrap/cache
mkdir -p backend/storage/framework/{sessions,views,cache}
mkdir -p backend/storage/logs
mkdir -p backend/storage/app/public/invoices
chmod -R 777 backend/bootstrap/cache backend/storage

# Step 4: Install Composer
echo "[4/12] Installing dependencies..."
cd backend
export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-dev --optimize-autoloader --no-interaction --quiet

# Step 5: Create .env
echo "[5/12] Configuring environment..."
cat > .env << 'EOF'
APP_NAME="Perfume Store"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://gt-academy.com/parfumes

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

# Step 6: Generate key
echo "[6/12] Generating app key..."
php artisan key:generate --force

# Step 7: Migrations
echo "[7/12] Running migrations..."
php artisan migrate --force

# Step 8: Seed
echo "[8/12] Seeding database..."
php artisan db:seed --force

# Step 9: Laravel optimization
echo "[9/12] Optimizing Laravel..."
php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Step 10: Permissions
echo "[10/12] Setting permissions..."
cd /var/www/html/gt-academy.com/parfumes
chown -R www-data:www-data .
chmod -R 775 backend/storage backend/bootstrap/cache

# Step 11: Update Nginx - ADD location block without breaking redirect
echo "[11/12] Updating Nginx configuration..."

# Backup existing config
cp /etc/nginx/sites-available/gt-academy.com /etc/nginx/sites-available/gt-academy.com.backup

# Check if parfumes location already exists
if grep -q "location /parfumes" /etc/nginx/sites-available/gt-academy.com; then
    echo "Parfumes location already exists in config"
else
    # Add parfumes location before the last closing brace
    sed -i '/^}$/i \
    # Parfumes application\
    location /parfumes {\
        alias /var/www/html/gt-academy.com/parfumes;\
        try_files $uri $uri/ /parfumes/index.html;\
        index index.html;\
    }\
\
    location /parfumes/backend/public {\
        alias /var/www/html/gt-academy.com/parfumes/backend/public;\
        try_files $uri $uri/ @parfumes_backend;\
        location ~ \\.php$ {\
            include snippets/fastcgi-php.conf;\
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;\
            fastcgi_param SCRIPT_FILENAME $request_filename;\
        }\
    }\
\
    location @parfumes_backend {\
        rewrite /parfumes/backend/public/(.*)$ /parfumes/backend/public/index.php?/$1 last;\
    }\
' /etc/nginx/sites-available/gt-academy.com
fi

# Step 12: Test and restart
echo "[12/12] Restarting services..."
nginx -t
systemctl restart nginx
systemctl restart php8.1-fpm

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 Access your parfumes store at:"
echo "   http://gt-academy.com/parfumes"
echo ""
echo "🔐 Default Login:"
echo "   Email: admin@perfume.com"
echo "   Password: password"
echo ""
echo "✅ Existing configuration preserved:"
echo "   - gt-academy.com redirect → still works"
echo "   - taksoride.com → untouched"
echo ""
echo "📝 Config backup saved at:"
echo "   /etc/nginx/sites-available/gt-academy.com.backup"
echo ""
echo "=========================================="
