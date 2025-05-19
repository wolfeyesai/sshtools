@echo off
setlocal EnableDelayedExpansion

echo.
echo Flutter Project Management Script
echo ================================
echo 1. Build Flutter Project (Android)
echo 2. Build Flutter Project (Windows)
echo 3. Run Flutter Project (Debug Mode)
echo 4. Run Flutter Project (Release Mode with Verbose Logging)
echo 5. Create New Flutter Project (Android ^& iOS only)
echo 6. Flutter Clean
echo 7. Flutter Pub Get
echo 8. Set Windows App Icon
echo 9. Run Flutter Project on Windows (Debug Mode with Hot Reload)
echo 10. Build Flutter Project (Web)
echo.

set /p choice="Please enter your choice (1-10): "

if "%choice%"=="1" (
    echo.
    echo Building Flutter project for Android...
    echo ================================
    
    echo Step 1: Running flutter clean...
    call flutter clean
    echo.
    
    echo Step 2: Running flutter pub get...
    call flutter pub get
    echo.
    
    echo Step 3: Generating app icons...
    call flutter pub run flutter_launcher_icons
    echo.
    
    echo Step 4: Building APK...
    call flutter build apk --release
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed! Please check the error messages above.
        pause
        goto :eof
    ) else (
        echo.
        REM Create release directory if not exists
        if not exist "release" mkdir release
        
        REM Copy APK to release directory
        echo Step 5: Copying APK to release directory...
        copy /Y "build\app\outputs\flutter-apk\app-release.apk" "release\sshtools-release.apk"
        
        echo.
        echo Build completed successfully! 
        echo APK file has been copied to: release\sshtools-release.apk
    )
    pause
    goto :eof
)

if "%choice%"=="2" (
    echo.
    echo Building Flutter project for Windows...
    echo ================================
    
    echo Checking development environment...
    flutter doctor -v
    
    echo.
    echo Continuing with Windows build...
    echo.
    echo Checking Windows support...
    flutter config --enable-windows-desktop
    
    echo.
    echo Adding Windows platform support...
    flutter create --platforms=windows .
    
    echo.
    echo Cleaning and getting dependencies...
    flutter clean
    flutter pub get
    
    echo.
    echo Building Windows application...
    flutter build windows --release
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed! Please check the error messages above.
        echo Try running 'flutter doctor -v' for more details.
        pause
        goto :eof
    ) else (
        echo.
        REM Create release directory if not exists
        if not exist "release" mkdir release
        
        REM Create temporary directory for release files
        echo Creating temporary directory for release files...
        if exist "build\windows\temp_release" rmdir /S /Q "build\windows\temp_release"
        mkdir "build\windows\temp_release"
        mkdir "build\windows\temp_release\sshtools"
        
        REM Copy Windows release files to temporary directory
        echo Copying Windows release files to temporary directory...
        xcopy /E /I /Y "build\windows\runner\Release\*" "build\windows\temp_release\sshtools\"
        
        REM Copy to release directory
        echo Copying sshtools folder to release directory...
        xcopy /E /I /Y "build\windows\temp_release\*" "release\"
        
        REM Clean up temporary directory
        echo Cleaning up temporary directory...
        rmdir /S /Q "build\windows\temp_release"
        
        echo.
        echo Build completed successfully!
        echo The Windows application has been copied to: release\sshtools\
        echo You can distribute these files directly.
    )
    
    pause
    goto :eof
)

if "%choice%"=="3" (
    echo.
    echo Running Flutter project in Debug Mode...
    echo ================================
    flutter run
    pause
    goto :eof
)

if "%choice%"=="4" (
    echo.
    echo Running Flutter project in Release Mode with Verbose Logging...
    echo ================================
    flutter run --release --verbose
    pause
    goto :eof
)

if "%choice%"=="5" (
    echo.
    echo Creating new Flutter project...
    echo ================================
    goto project_name_input
)

if "%choice%"=="6" (
    echo.
    echo Running Flutter Clean...
    echo ================================
    flutter clean
    echo.
    echo Clean completed!
    pause
    goto :eof
)

if "%choice%"=="7" (
    echo.
    echo Running Flutter Pub Get...
    echo ================================
    flutter pub get
    echo.
    echo Dependencies updated successfully!
    pause
    goto :eof
)

if "%choice%"=="8" (
    echo.
    echo Setting Windows App Icon from assets directory...
    echo ================================
    
    echo This will use your existing PNG icon from assets/icon/app_ico.png
    echo and copy it to the Windows resources directory.
    echo.
    
    REM Set source and destination paths
    set source_icon=assets\icon\app_ico.png
    
    if not exist "!source_icon!" (
        echo.
        echo Error: Source icon file not found at !source_icon!
        echo Please place your icon in assets/icon/app_ico.png
        pause
        goto :eof
    )
    
    if not exist "windows\runner\resources" (
        echo.
        echo Creating Windows platform files first...
        flutter create --platforms=windows .
    )
    
    echo.
    echo Copying PNG icon to Windows resources...
    copy /Y "!source_icon!" "windows\runner\resources\app_icon.png"
    
    echo.
    echo Windows PNG icon set successfully.
    echo.
    echo Note: For optimal Windows display, you may want to create an ICO file:
    echo 1. Convert your PNG to ICO using an online converter
    echo 2. Save the ICO file as assets/icon/app_ico.ico
    echo 3. Run this option again to copy it to Windows resources
    
    REM Check if ICO file exists and copy it
    if exist "assets\icon\app_ico.ico" (
        echo.
        echo Found ICO file, copying to Windows resources...
        copy /Y "assets\icon\app_ico.ico" "windows\runner\resources\app_icon.ico"
        echo ICO file copied successfully.
    )
    
    echo.
    echo Windows icon process completed.
    echo The new icon will appear when you rebuild the Windows application.
    echo Run option 2 to build the Windows application.
    
    pause
    goto :eof
)

if "%choice%"=="9" (
    flutter config --enable-windows-desktop >nul 2>&1
    
    if not exist "windows" (
        flutter create --platforms=windows . >nul 2>&1
    )
    
    flutter run -d windows --debug --hot
    goto :eof
)

if "%choice%"=="10" (
    echo.
    echo Building Flutter project for Web with Obfuscation...
    echo ================================
    
    echo Checking web support...
    flutter config --enable-web
    
    echo.
    echo Adding web platform support...
    flutter create --platforms=web .
    
    echo.
    echo Cleaning and getting dependencies...
    flutter clean
    flutter pub get
    
    echo.
    echo Generating app icons...
    flutter pub run flutter_launcher_icons
    
    echo.
    echo Building web application with obfuscation and optimization...
    flutter build web --release --dart-define=FLUTTER_WEB_OBFUSCATE=true --dart-define=FLUTTER_WEB_BUILD_MODE=release
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed! Please check the error messages above.
        pause
        goto :eof
    ) else (
        echo.
        REM Create release directory if not exists
        if not exist "release" mkdir release
        if not exist "release\web" mkdir release\web
        
        echo Copying web files to release directory...
        xcopy /E /I /Y "build\web\*" "release\web\"
        
        echo.
        echo Build completed successfully with code obfuscation!
        echo The web application has been copied to: release\web\
        echo You can deploy these files to any web server.
        echo.
        echo Security notes:
        echo - Code is obfuscated but not fully encrypted
        echo - Critical business logic should remain on server-side
        echo - Sensitive data should be handled through secure APIs
        echo.
        echo To test locally, you can run:
        echo cd release\web
        echo python -m http.server 8000
        echo Then open http://localhost:8000 in your browser
    )
    
    pause
    goto :eof
)

if not "%choice%"=="1" if not "%choice%"=="2" if not "%choice%"=="3" if not "%choice%"=="4" if not "%choice%"=="5" if not "%choice%"=="6" if not "%choice%"=="7" if not "%choice%"=="8" if not "%choice%"=="9" if not "%choice%"=="10" (
    echo.
    echo Invalid choice! Please select 1, 2, 3, 4, 5, 6, 7, 8, 9, or 10.
    pause
    goto :eof
)

:project_name_input
set "project_name="

echo Enter project name (lowercase, no spaces):
set /p project_name=

if "!project_name!"=="" (
    echo Error: Project name cannot be empty.
    goto project_name_input
)

rem Validate project name doesn't contain spaces - using string replacement method
set "temp_name=!project_name: =!"
if not "!temp_name!"=="!project_name!" (
    echo Error: Project name cannot contain spaces. Please use lowercase letters, numbers, and underscores.
    goto project_name_input
)

rem Automatically use parent directory
for %%I in (..) do set "TARGET_DIR=%%~fI"

echo.
echo Creating project "!project_name!" in: !TARGET_DIR!
echo Platform: Android and iOS only

rem Navigate to target directory
cd /d "!TARGET_DIR!" || (
    echo Error: Could not navigate to the specified directory.
    pause
    goto :eof
)

rem Create project command
echo Running: flutter create --platforms=android,ios !project_name!
flutter create --platforms=android,ios !project_name!

rem Check if project was created successfully
if !ERRORLEVEL! EQU 0 (
    echo.
    echo Project created successfully!
    echo Project location: !TARGET_DIR!\!project_name!
    echo.
    echo To work with this project:
    echo cd !TARGET_DIR!\!project_name!
    echo flutter pub get
) else (
    echo.
    echo Failed to create project. Please check Flutter installation and project name.
    echo Error code: !ERRORLEVEL!
)

rem Return to original directory
cd /d "%~dp0"

pause
goto :eof

endlocal 