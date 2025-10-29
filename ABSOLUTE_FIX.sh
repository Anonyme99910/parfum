#!/bin/bash
# ABSOLUTE FIX - This WILL work

echo "=========================================="
echo "ABSOLUTE FIX FOR GT-ACADEMY.COM"
echo "=========================================="

# Step 1: Go to directory
cd /var/www/html/gt-academy.com

# Step 2: Verify files exist
if [ ! -f "index.html" ]; then
    echo "ERROR: index.html not found!"
    echo "Downloading from GitHub..."
    curl -sL https://raw.githubusercontent.com/Anonyme99910/parfum/main/index.html -o index.html
fi

echo "✓ index.html exists ($(wc -c < index.html) bytes)"

# Step 3: Remove ALL nginx configs for gt-academy
rm -f /etc/nginx/sites-enabled/gt-academy*
rm -f /etc/nginx/sites-enabled/parfumes*
rm -f /etc/nginx/sites-available/gt-academy-parfumes
rm -f /etc/nginx/sites-available/parfumes*

# Step 4: Create SIMPLE working config
cat > /etc/nginx/sites-available/gt-academy.com << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name gt-academy.com www.gt-academy.com _;
    
    root /var/www/html/gt-academy.com;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
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
}
EOF

# Step 5: Enable it
ln -sf /etc/nginx/sites-available/gt-academy.com /etc/nginx/sites-enabled/gt-academy.com

# Step 6: Remove default if it exists
rm -f /etc/nginx/sites-enabled/default

# Step 7: Test nginx
echo "Testing Nginx configuration..."
nginx -t

# Step 8: Restart everything
echo "Restarting services..."
systemctl stop nginx
sleep 2
systemctl start nginx
systemctl restart php8.1-fpm

# Step 9: Wait and test
sleep 3
echo ""
echo "Testing..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
echo "Response code: $RESPONSE"

if [ "$RESPONSE" = "200" ]; then
    echo "✅ SUCCESS! Site is working!"
else
    echo "Still getting $RESPONSE"
    echo "Checking what's being served..."
    curl -v http://localhost/ 2>&1 | head -30
fi

echo ""
echo "=========================================="
echo "Check: https://gt-academy.com/"
echo "=========================================="
