# Quick Deployment Guide - gt-academy.com

## 🚀 Quick Start (5 Steps)

### Step 1: Prepare Files (Local Machine)
```bash
# Run the deployment script
cd C:\xampp\htdocs\parfumes
deploy.bat
```

This will:
- Export database
- Build frontend
- Prepare all files

### Step 2: Upload Files to Server

**Use FileZilla or WinSCP:**
- **Host:** 45.93.139.14
- **Username:** root
- **Password:** [Your SSH password]
- **Port:** 22

**Upload these to `/var/www/html/gt-academy.com/parfumes/`:**
- ✅ `backend/` (entire folder)
- ✅ `index.html`
- ✅ `assets/` (entire folder)

**Upload this to `/root/`:**
- ✅ `parfumes_db_backup.sql`
- ✅ `server_setup.sh`

### Step 3: Run Server Setup
```bash
# SSH to server
ssh root@45.93.139.14

# Make script executable
chmod +x /root/server_setup.sh

# Run setup
/root/server_setup.sh
```

### Step 4: Configure Web Server

**For Nginx:**
```bash
nano /etc/nginx/sites-available/gt-academy.com
```

**Paste this:**
```nginx
server {
    listen 80;
    server_name gt-academy.com www.gt-academy.com;
    root /var/www/html/gt-academy.com/parfumes;
    index index.html;

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
```

**Enable and restart:**
```bash
ln -s /etc/nginx/sites-available/gt-academy.com /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### Step 5: Setup SSL (Optional but Recommended)
```bash
# Install certbot
apt install -y certbot python3-certbot-nginx

# Get certificate
certbot --nginx -d gt-academy.com -d www.gt-academy.com
```

---

## ✅ Verification

**Test these URLs:**
1. https://gt-academy.com/parfumes
2. https://gt-academy.com/backend/public/api
3. https://gt-academy.com/backend/public/api/products

---

## 🔧 Troubleshooting

### Issue: 500 Error
```bash
# Check logs
tail -f /var/www/html/gt-academy.com/parfumes/backend/storage/logs/laravel.log
```

### Issue: Permission Denied
```bash
cd /var/www/html/gt-academy.com/parfumes/backend
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
```

### Issue: Database Connection Failed
```bash
# Test connection
mysql -u parfumes_user -p parfumes_db

# Check .env
cat /var/www/html/gt-academy.com/parfumes/backend/.env | grep DB_
```

---

## 📋 Important Info

**Database Credentials:**
- Name: `parfumes_db`
- User: `parfumes_user`
- Pass: `Parfumes@2025#Secure` (change in server_setup.sh)

**File Locations:**
- Frontend: `/var/www/html/gt-academy.com/parfumes/`
- Backend: `/var/www/html/gt-academy.com/parfumes/backend/`
- Logs: `/var/www/html/gt-academy.com/parfumes/backend/storage/logs/`

**Important:**
- ⚠️ Do NOT touch taksoride project
- ✅ Database is preserved from local
- ✅ All features included (POS, Invoices, Stock, Payments)

---

## 🎯 Post-Deployment

1. **Test Login:** Use your existing credentials
2. **Test POS:** Create a sale
3. **Test Invoices:** View and create payments
4. **Test Stock:** Check stock levels
5. **Test PDF:** Download invoice PDF
6. **Test WhatsApp:** Share invoice

---

**Need help? Check DEPLOYMENT_GUIDE.md for detailed instructions! 🚀**
