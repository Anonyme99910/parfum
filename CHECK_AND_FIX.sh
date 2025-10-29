#!/bin/bash
# Check and fix gt-academy.com deployment

echo "=========================================="
echo "CHECKING GT-ACADEMY.COM DEPLOYMENT"
echo "=========================================="
echo ""

echo "1. Checking files..."
ls -la /var/www/html/gt-academy.com/ | head -20
echo ""

echo "2. Checking if index.html exists..."
if [ -f "/var/www/html/gt-academy.com/index.html" ]; then
    echo "✓ index.html found"
else
    echo "✗ index.html NOT found - FIXING..."
    cd /var/www/html/gt-academy.com
    if [ ! -f "index.html" ]; then
        echo "Copying from repository..."
        git clone https://github.com/Anonyme99910/parfum.git temp
        cp temp/index.html .
        cp -r temp/assets .
        rm -rf temp
    fi
fi
echo ""

echo "3. Checking Nginx config..."
cat /etc/nginx/sites-available/gt-academy.com
echo ""

echo "4. Testing Nginx..."
nginx -t
echo ""

echo "5. Checking what's enabled..."
ls -la /etc/nginx/sites-enabled/
echo ""

echo "6. Restarting services..."
systemctl restart nginx
systemctl restart php8.1-fpm
echo "✓ Services restarted"
echo ""

echo "7. Testing locally..."
curl -I http://localhost/
echo ""

echo "8. Checking permissions..."
ls -la /var/www/html/gt-academy.com/index.html
echo ""

echo "=========================================="
echo "DIAGNOSTIC COMPLETE"
echo "=========================================="
