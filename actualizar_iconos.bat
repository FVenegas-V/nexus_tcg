@echo off
chcp 65001 >nul
echo ==========================================
echo    NEXUS TCG - Actualizador de Iconos
echo ==========================================
echo.

echo Verificando archivos de logo...
echo.

REM Verificar si existe la carpeta de iconos
if not exist "assets\icons\" (
    echo [INFO] Creando carpeta assets\icons\...
    mkdir "assets\icons\"
)

if not exist "assets\icons\nexus_tcg_logo.png" (
    echo [ERROR] No se encontró nexus_tcg_logo.png
    echo.
    echo Por favor, guarda tu logo de Nexus TCG como:
    echo "assets\icons\nexus_tcg_logo.png"
    echo.
    echo Especificaciones:
    echo - Tamaño: 1024x1024 pixels
    echo - Formato: PNG
    echo - Contenido: Logo completo (carta + texto "NEXUS TCG")
    echo.
    echo Presiona cualquier tecla para salir...
    pause >nul
    exit /b 1
)

if not exist "assets\icons\nexus_tcg_logo_foreground.png" (
    echo [ADVERTENCIA] No se encontró nexus_tcg_logo_foreground.png
    echo.
    echo Este archivo es opcional para iconos adaptativos de Android.
    echo Si lo tienes, debería contener solo la carta coral sin texto.
    echo.
    timeout /t 3 >nul
)

echo [OK] ✓ Archivos de logo encontrados
echo.

echo Verificando Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter no está instalado o no está en el PATH
    echo Por favor, instala Flutter y asegúrate de que esté en el PATH
    echo.
    echo Presiona cualquier tecla para salir...
    pause >nul
    exit /b 1
)
echo [OK] ✓ Flutter encontrado
echo.

echo Instalando dependencias...
echo Ejecutando: flutter pub get
flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Error al instalar dependencias
    echo.
    echo Presiona cualquier tecla para salir...
    pause >nul
    exit /b 1
)
echo [OK] ✓ Dependencias instaladas
echo.

echo Generando iconos para todas las plataformas...
echo Ejecutando: flutter pub run flutter_launcher_icons
echo.
flutter pub run flutter_launcher_icons
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Error al generar iconos
    echo.
    echo Posibles soluciones:
    echo 1. Verifica que las imágenes estén en formato PNG válido
    echo 2. Asegúrate de que las imágenes sean de 1024x1024 pixels
    echo 3. Ejecuta 'flutter clean' y vuelve a intentar
    echo.
    echo Presiona cualquier tecla para salir...
    pause >nul
    exit /b 1
)
echo [OK] ✓ Iconos generados exitosamente

echo.
echo ==========================================
echo    ✓ ICONOS ACTUALIZADOS EXITOSAMENTE!
echo ==========================================
echo.
echo Los iconos de Nexus TCG se han generado para:
echo.
echo  📱 Android
echo     - Iconos normales: mipmap-hdpi, mipmap-mdpi, etc.
echo     - Iconos adaptativos: con fondo coral (#FF6B6B)
echo.
echo  🍎 iOS
echo     - AppIcon.appiconset: todos los tamaños requeridos
echo.
echo  🌐 Web
echo     - Favicon: 16x16, 32x32
echo     - Iconos PWA: 192x192, 512x512
echo.
echo  🪟 Windows
echo     - App icon: 48x48 (configurable)
echo.
echo  🖥️  macOS
echo     - AppIcon.appiconset: todos los tamaños requeridos
echo.
echo ==========================================
echo.
echo 🚀 Próximos pasos:
echo    1. Ejecuta 'flutter run' para probar la app
echo    2. Verifica que el icono aparezca en el launcher
echo    3. ¡Disfruta tu app con el branding de Nexus TCG!
echo.
echo Presiona cualquier tecla para continuar...
pause >nul
