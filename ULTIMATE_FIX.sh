#!/bin/bash
# ULTIMATE FIX - Will make gt-academy.com work no matter what

echo "=========================================="
echo "ULTIMATE FIX FOR GT-ACADEMY.COM"
echo "=========================================="

# Find where CloudPanel sites are
CLOUDPANEL_ROOT=$(find /home -maxdepth 2 -name "htdocs" -path "*/gt-academy.com/*" 2>/dev/null | head -1)

if [ -n "$CLOUDPANEL_ROOT" ]; then
    echo "CloudPanel detected! Using: $CLOUDPANEL_ROOT"
    TARGET_DIR="$CLOUDPANEL_ROOT"
else
    echo "No CloudPanel, using: /var/www/html/gt-academy.com"
    TARGET_DIR="/var/www/html/gt-academy.com"
fi

echo "Target directory: $TARGET_DIR"

# Ensure directory exists
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Copy all files from our deployment
echo "Copying files..."
if [ -d "/var/www/html/gt-academy.com" ]; then
    cp -r /var/www/html/gt-academy.com/* "$TARGET_DIR/" 2>/dev/null || true
    cp -r /var/www/html/gt-academy.com/.* "$TARGET_DIR/" 2>/dev/null || true
fi

# Verify index.html
if [ ! -f "$TARGET_DIR/index.html" ]; then
    echo "Downloading index.html..."
    curl -sL https://raw.githubusercontent.com/Anonyme99910/parfum/main/index.html -o "$TARGET_DIR/index.html"
fi

# Download assets if missing
if [ ! -d "$TARGET_DIR/assets" ]; then
    echo "Downloading assets..."
    mkdir -p "$TARGET_DIR/assets"
    cd /tmp
    git clone --depth 1 https://github.com/Anonyme99910/parfum.git parfum-temp
    cp -r parfum-temp/assets/* "$TARGET_DIR/assets/"
    rm -rf parfum-temp
fi

cd "$TARGET_DIR"
echo "Files in $TARGET_DIR:"
ls -la | head -15

# Set permissions
chown -R www-data:www-data "$TARGET_DIR"
chmod -R 755 "$TARGET_DIR"

# Create/update Nginx config
cat > /etc/nginx/sites-available/gt-academy.com << 'NGINX'
server {
    listen 80;
    listen [::]:80;
    server_name gt-academy.com www.gt-academy.com;
    
    root /var/www/html/gt-academy.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ /index.html =404;
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

# Also create for CloudPanel if detected
if [ -n "$CLOUDPANEL_ROOT" ]; then
    CLOUDPANEL_NGINX="/etc/nginx/sites-available/gt-academy.com-cloudpanel"
    cat > "$CLOUDPANEL_NGINX" << CPNGINX
server {
    listen 80;
    listen [::]:80;
    server_name gt-academy.com www.gt-academy.com;
    
    root $TARGET_DIR;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.html =404;
    }

    location /backend/public {
        alias $TARGET_DIR/backend/public;
        try_files \$uri \$uri/ @backend;
        
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
        }
    }

    location @backend {
        rewrite /backend/public/(.*)\$ /backend/public/index.php?/\$1 last;
    }
}
CPNGINX
    ln -sf "$CLOUDPANEL_NGINX" /etc/nginx/sites-enabled/
fi

# Enable main config
ln -sf /etc/nginx/sites-available/gt-academy.com /etc/nginx/sites-enabled/gt-academy.com

# Test and restart
nginx -t
systemctl restart nginx
systemctl restart php8.1-fpm

sleep 3

# Test
echo ""
echo "Testing http://localhost/..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
echo "Response: $RESPONSE"

if [ "$RESPONSE" = "200" ]; then
    echo "✅ SUCCESS!"
else
    echo "Response body:"
    curl -s http://localhost/ | head -20
fi

echo ""
echo "=========================================="
echo "Visit: https://gt-academy.com/"
echo "=========================================="
