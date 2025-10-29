@echo off
echo ========================================
echo  PUSHING TO GITHUB
echo ========================================
echo.

cd /d C:\xampp\htdocs\parfumes

echo [1/6] Initializing Git...
git init
echo.

echo [2/6] Adding files...
git add .
echo.

echo [3/6] Creating commit...
git commit -m "Complete Perfume Store with Invoices and Stock Management"
echo.

echo [4/6] Adding remote...
git remote add origin https://github.com/Anonyme99910/parfum.git
echo.

echo [5/6] Setting branch...
git branch -M main
echo.

echo [6/6] Pushing to GitHub...
git push -u origin main --force
echo.

echo ========================================
echo  PUSH COMPLETE!
echo ========================================
echo.
echo Repository: https://github.com/Anonyme99910/parfum
echo.
echo Next: SSH to server and run:
echo   cd /var/www/html/gt-academy.com
echo   git clone https://github.com/Anonyme99910/parfum.git parfumes
echo   cd parfumes
echo   bash deploy_server.sh
echo.
pause
