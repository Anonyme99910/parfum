#!/bin/bash
# Final comprehensive fix

echo "=========================================="
echo "FINAL FIX FOR GT-ACADEMY.COM"
echo "=========================================="

# Check current state
echo "Current directory contents:"
ls -la /var/www/html/gt-academy.com/ | grep -E "index|assets|backend"

# Make sure index.html is in the right place
cd /var/www/html/gt-academy.com
if [ ! -f "index.html" ]; then
    echo "ERROR: index.html missing!"
    exit 1
fi

echo "index.html exists: $(ls -lh index.html)"

# Remove ALL conflicting nginx configs
echo "Removing conflicting configs..."
rm -f /etc/nginx/sites-enabled/parfumes*
rm -f /etc/nginx/sites-enabled/gt-academy-*
rm -f /etc/nginx/sites-available/parfumes*
rm -f /etc/nginx/sites-available/gt-academy-parfumes

# Create fresh config
echo "Creating fresh Nginx config..."
cat > /etc/nginx/sites-available/gt-academy.com << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name gt-academy.com www.gt-academy.com;
    
    root /var/www/html/gt-academy.com;
    index index.html index.htm;

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
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable it
ln -sf /etc/nginx/sites-available/gt-academy.com /etc/nginx/sites-enabled/gt-academy.com

# Test
nginx -t
if [ $? -ne 0 ]; then
    echo "Nginx config error!"
    exit 1
fi

# Restart
systemctl restart nginx
systemctl restart php8.1-fpm

# Wait a moment
sleep 2

# Test
echo ""
echo "Testing http://localhost/..."
curl -v http://localhost/ 2>&1 | head -20

echo ""
echo "=========================================="
echo "DONE! Check https://gt-academy.com/"
echo "=========================================="
