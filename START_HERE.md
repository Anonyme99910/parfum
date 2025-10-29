# 🚀 PARFUMES DEPLOYMENT - START HERE

## ✅ Step 1: Files Ready (DONE)
- ✅ Database exported: `parfumes_db_backup.sql`
- ✅ Deployment script: `COMPLETE_DEPLOY.sh`
- ✅ Backend ready: `backend/`
- ✅ Frontend ready: `index.html` + `assets/`

---

## 📤 Step 2: Upload Files

### Use FileZilla or WinSCP:
- **Host:** 45.93.139.14
- **Username:** root
- **Password:** [your SSH password]
- **Port:** 22

### Upload These Files:

**To: `/var/www/html/gt-academy.com/parfumes/`**
```
✓ backend/ (entire folder)
✓ index.html
✓ assets/ (entire folder)
```

**To: `/root/`**
```
✓ parfumes_db_backup.sql
✓ COMPLETE_DEPLOY.sh
```

---

## 🖥️ Step 3: Run Deployment

### In your SSH terminal (already connected):

```bash
cd /root
chmod +x COMPLETE_DEPLOY.sh
bash COMPLETE_DEPLOY.sh
```

### The script will ask you:
1. **MySQL root password** - Enter it when prompted
2. **Setup SSL?** - Type `y` for yes (recommended)

### That's it! The script handles:
- ✅ Installing dependencies
- ✅ Configuring Laravel
- ✅ Importing database
- ✅ Setting up Nginx
- ✅ Configuring permissions
- ✅ Testing installation

---

## 🎯 Step 4: Verify

### Open in browser:
- **Frontend:** http://gt-academy.com/
- **API:** http://gt-academy.com/backend/public/api

### Test these features:
1. Login
2. POS - Create a sale
3. Invoices - View and record payment
4. Stock - Check inventory
5. PDF - Download invoice
6. WhatsApp - Share invoice

---

## 🔧 Troubleshooting

### If something goes wrong:

**Check logs:**
```bash
tail -f /var/www/html/gt-academy.com/parfumes/backend/storage/logs/laravel.log
```

**Fix permissions:**
```bash
cd /var/www/html/gt-academy.com/parfumes
chown -R www-data:www-data .
chmod -R 775 backend/storage backend/bootstrap/cache
```

**Restart services:**
```bash
systemctl restart nginx
systemctl restart php8.1-fpm
```

---

## 📋 Important Info

**Database:**
- Name: `perfume_store`
- User: `perfume_user`
- Pass: `Perfume@2025Secure!`

**Locations:**
- Project: `/var/www/html/gt-academy.com/parfumes/`
- Backend: `/var/www/html/gt-academy.com/parfumes/backend/`
- Logs: `/var/www/html/gt-academy.com/parfumes/backend/storage/logs/`

**Security:**
- ⚠️ Change database password after deployment
- ✅ SSL certificate recommended
- ✅ taksoride is NOT touched

---

## 🎉 Success Indicators

When deployment is successful, you'll see:
```
==========================================
  DEPLOYMENT SUCCESSFUL!
==========================================

📍 URLs:
   Frontend: http://gt-academy.com/
   API: http://gt-academy.com/backend/public/api

✅ API responding (Status: 200)
✅ Frontend responding
```

---

**Need help? All files are in: `C:\xampp\htdocs\parfumes\`**

**Ready to deploy! Just upload files and run the script! 🚀**
