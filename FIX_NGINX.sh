#!/bin/bash
# Fix Nginx configuration for gt-academy.com

echo "Fixing Nginx configuration..."

# Remove conflicting configs
rm -f /etc/nginx/sites-enabled/parfumes
rm -f /etc/nginx/sites-enabled/parfumes-store
rm -f /etc/nginx/sites-enabled/gt-academy-parfumes

# Enable gt-academy.com
ln -sf /etc/nginx/sites-available/gt-academy.com /etc/nginx/sites-enabled/gt-academy.com

# Test
nginx -t

# Restart
systemctl restart nginx

echo "Done! Testing..."
curl -I http://localhost/

echo ""
echo "gt-academy.com should now be working!"
