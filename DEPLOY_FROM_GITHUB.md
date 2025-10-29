# 🚀 Deploy from GitHub to gt-academy.com

## Quick Deployment (One Command)

SSH to your server and run:

```bash
curl -sL https://raw.githubusercontent.com/Anonyme99910/parfum/main/deploy_server.sh | bash
```

---

## Manual Deployment Steps

### 1. SSH to Server
```bash
ssh root@45.93.139.14
```

### 2. Clone Repository
```bash
cd /var/www/html/gt-academy.com
git clone https://github.com/Anonyme99910/parfum.git parfumes
cd parfumes
```

### 3. Run Deployment Script
```bash
chmod +x deploy_server.sh
./deploy_server.sh
```

### 4. Enter MySQL Password When Prompted

### 5. Done!
Visit: http://gt-academy.com/

---

## What the Script Does

1. ✅ Installs PHP and dependencies
2. ✅ Installs Composer
3. ✅ Configures Laravel
4. ✅ Creates database
5. ✅ Sets up Nginx
6. ✅ Configures permissions
7. ✅ Restarts services

---

## Database Setup

The script will ask for:
- MySQL root password
- Whether to import existing database (if you have a backup)

---

## Post-Deployment

### Test URLs:
- Frontend: http://gt-academy.com/
- API: http://gt-academy.com/backend/public/api

### Setup SSL (Recommended):
```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d gt-academy.com -d www.gt-academy.com
```

### Check Logs:
```bash
tail -f /var/www/html/gt-academy.com/parfumes/backend/storage/logs/laravel.log
```

---

## Troubleshooting

### Permission Issues:
```bash
cd /var/www/html/gt-academy.com/parfumes
chown -R www-data:www-data .
chmod -R 775 backend/storage backend/bootstrap/cache
```

### Restart Services:
```bash
systemctl restart nginx
systemctl restart php8.1-fpm
```

---

**Repository:** https://github.com/Anonyme99910/parfum
