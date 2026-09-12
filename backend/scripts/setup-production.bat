@echo off
REM Production Admin Key Setup Script for Windows
REM This script helps you set up admin keys for production deployment

echo ==========================================
echo   Production Admin Key Setup
echo ==========================================
echo.

REM Check if .env file exists
if exist .env (
    echo ⚠️  .env file already exists
    echo    Current MODERATOR_ADMIN_KEY will be preserved
    echo.
)

REM Generate new admin key using the npm script
echo 🔑 Generating new admin key...
for /f "delims=" %%A in ('npm run generate-admin-key-quiet') do set ADMIN_KEY=%%A

echo ✅ Admin key generated
echo.
echo 📝 Your new admin key:
echo    %ADMIN_KEY%
echo.

REM Ask if user wants to add to .env file
set /p ADD_TO_ENV="Add this key to .env file? (y/n): "
if /i "%ADD_TO_ENV%"=="y" (
    REM Backup existing .env file
    if exist .env (
        copy .env .env.backup >nul
        echo 📦 Backed up existing .env file to .env.backup
    )
    
    REM Add or update MODERATOR_ADMIN_KEY
    if exist .env (
        findstr /C:"MODERATOR_ADMIN_KEY" .env >nul
        if %errorlevel% equ 0 (
            REM Update existing key
            powershell -Command "(Get-Content .env) -replace '^MODERATOR_ADMIN_KEY=.*', 'MODERATOR_ADMIN_KEY=%ADMIN_KEY%' | Set-Content .env"
            echo ✅ Updated MODERATOR_ADMIN_KEY in .env file
        ) else (
            REM Add new key
            echo MODERATOR_ADMIN_KEY=%ADMIN_KEY% >> .env
            echo ✅ Added MODERATOR_ADMIN_KEY to .env file
        )
    ) else (
        REM Create new .env file
        echo MODERATOR_ADMIN_KEY=%ADMIN_KEY% > .env
        echo ✅ Created .env file with MODERATOR_ADMIN_KEY
    )
) else (
    echo ⏭️  Skipping .env file update
)

echo.
echo ==========================================
echo   Setup Complete
echo ==========================================
echo.
echo 🚀 Next Steps:
echo    1. For local development: The key is in your .env file
echo    2. For production deployment: Set as environment variable
echo       set MODERATOR_ADMIN_KEY=%ADMIN_KEY%
echo.
echo 📖 For detailed deployment instructions, see:
echo    scripts\setup-production-keys.md
echo.
echo ⚠️  Security Reminders:
echo    - Never commit .env file to version control
echo    - Use different keys for different environments
echo    - Rotate keys periodically
echo    - Share only with authorized personnel
echo ==========================================

pause
