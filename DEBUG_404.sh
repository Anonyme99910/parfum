#!/bin/bash
echo "=== DEBUGGING 404 ERROR ==="
echo ""
echo "1. Check what Nginx is actually serving:"
curl -v http://127.0.0.1/ 2>&1 | grep -A 5 "HTTP"
echo ""

echo "2. Check Nginx error log:"
tail -20 /var/log/nginx/gt-academy-error.log
echo ""

echo "3. Check which config is being used:"
nginx -T 2>&1 | grep -A 30 "server_name gt-academy.com"
echo ""

echo "4. Check if there's a CloudPanel vhost:"
ls -la /home/*/htdocs/ 2>/dev/null || echo "No CloudPanel vhosts found"
echo ""

echo "5. Check all enabled sites:"
ls -la /etc/nginx/sites-enabled/
echo ""

echo "6. Try accessing the file directly:"
cat /var/www/html/gt-academy.com/index.html | head -5
echo ""

echo "7. Check Nginx process:"
ps aux | grep nginx
