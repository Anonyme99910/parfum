@echo off
echo ========================================
echo Parfumes Project - Deployment Preparation
echo ========================================
echo.

REM Step 1: Export Database
echo [1/4] Exporting database...
cd C:\xampp\mysql\bin
mysqldump.exe -u root parfumes_db > C:\xampp\htdocs\parfumes\parfumes_db_backup.sql
if %errorlevel% neq 0 (
    echo ERROR: Database export failed!
    pause
    exit /b 1
)
echo Database exported successfully!
echo.

REM Step 2: Build Frontend
echo [2/4] Building frontend...
cd C:\xampp\htdocs\parfumes\frontend
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Frontend build failed!
    pause
    exit /b 1
)
echo Frontend built successfully!
echo.

REM Step 3: Copy built files to root
echo [3/4] Copying built files...
xcopy /E /Y dist\* C:\xampp\htdocs\parfumes\
echo Files copied successfully!
echo.

REM Step 4: Create deployment package info
echo [4/4] Creating deployment info...
cd C:\xampp\htdocs\parfumes
echo Deployment Package Ready > DEPLOYMENT_READY.txt
echo Date: %date% %time% >> DEPLOYMENT_READY.txt
echo. >> DEPLOYMENT_READY.txt
echo Files to upload: >> DEPLOYMENT_READY.txt
echo - backend/ (entire folder) >> DEPLOYMENT_READY.txt
echo - index.html >> DEPLOYMENT_READY.txt
echo - assets/ (entire folder) >> DEPLOYMENT_READY.txt
echo - parfumes_db_backup.sql >> DEPLOYMENT_READY.txt
echo. >> DEPLOYMENT_READY.txt
echo Server: root@45.93.139.14 >> DEPLOYMENT_READY.txt
echo Domain: gt-academy.com >> DEPLOYMENT_READY.txt
echo Path: /var/www/html/gt-academy.com/parfumes/ >> DEPLOYMENT_READY.txt

echo.
echo ========================================
echo Deployment package ready!
echo ========================================
echo.
echo Next steps:
echo 1. Use FileZilla or WinSCP to upload files
echo 2. Server: 45.93.139.14
echo 3. Username: root
echo 4. Upload to: /var/www/html/gt-academy.com/parfumes/
echo.
echo See DEPLOYMENT_GUIDE.md for detailed instructions
echo.
pause
