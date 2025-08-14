#!/bin/bash

# Configurar colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   NEXUS TCG - Actualizador de Iconos${NC}"
echo -e "${BLUE}==========================================${NC}"
echo

echo "Verificando archivos de logo..."
echo

# Verificar si existe la carpeta de iconos
if [ ! -d "assets/icons" ]; then
    echo -e "${BLUE}[INFO] Creando carpeta assets/icons/...${NC}"
    mkdir -p "assets/icons"
fi

if [ ! -f "assets/icons/nexus_tcg_logo.png" ]; then
    echo -e "${RED}[ERROR] No se encontró nexus_tcg_logo.png${NC}"
    echo
    echo "Por favor, guarda tu logo de Nexus TCG como:"
    echo "'assets/icons/nexus_tcg_logo.png'"
    echo
    echo "Especificaciones:"
    echo "- Tamaño: 1024x1024 pixels"
    echo "- Formato: PNG"
    echo "- Contenido: Logo completo (carta + texto 'NEXUS TCG')"
    echo
    exit 1
fi

if [ ! -f "assets/icons/nexus_tcg_logo_foreground.png" ]; then
    echo -e "${YELLOW}[ADVERTENCIA] No se encontró nexus_tcg_logo_foreground.png${NC}"
    echo
    echo "Este archivo es opcional para iconos adaptativos de Android."
    echo "Si lo tienes, debería contener solo la carta coral sin texto."
    echo
    sleep 2
fi

echo -e "${GREEN}[OK] ✓ Archivos de logo encontrados${NC}"
echo

echo "Verificando Flutter..."
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}[ERROR] Flutter no está instalado o no está en el PATH${NC}"
    echo "Por favor, instala Flutter y asegúrate de que esté en el PATH"
    exit 1
fi
echo -e "${GREEN}[OK] ✓ Flutter encontrado${NC}"
echo

echo "Instalando dependencias..."
echo "Ejecutando: flutter pub get"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] Error al instalar dependencias${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] ✓ Dependencias instaladas${NC}"
echo

echo "Generando iconos para todas las plataformas..."
echo "Ejecutando: flutter pub run flutter_launcher_icons"
echo
flutter pub run flutter_launcher_icons
if [ $? -ne 0 ]; then
    echo
    echo -e "${RED}[ERROR] Error al generar iconos${NC}"
    echo
    echo "Posibles soluciones:"
    echo "1. Verifica que las imágenes estén en formato PNG válido"
    echo "2. Asegúrate de que las imágenes sean de 1024x1024 pixels"
    echo "3. Ejecuta 'flutter clean' y vuelve a intentar"
    echo
    exit 1
fi
echo -e "${GREEN}[OK] ✓ Iconos generados exitosamente${NC}"

echo
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   ✓ ICONOS ACTUALIZADOS EXITOSAMENTE!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo
echo "Los iconos de Nexus TCG se han generado para:"
echo
echo -e "${BLUE} 📱 Android${NC}"
echo "    - Iconos normales: mipmap-hdpi, mipmap-mdpi, etc."
echo "    - Iconos adaptativos: con fondo coral (#FF6B6B)"
echo
echo -e "${BLUE} 🍎 iOS${NC}"
echo "    - AppIcon.appiconset: todos los tamaños requeridos"
echo
echo -e "${BLUE} 🌐 Web${NC}"
echo "    - Favicon: 16x16, 32x32"
echo "    - Iconos PWA: 192x192, 512x512"
echo
echo -e "${BLUE} 🪟 Windows${NC}"
echo "    - App icon: 48x48 (configurable)"
echo
echo -e "${BLUE} 🖥️  macOS${NC}"
echo "    - AppIcon.appiconset: todos los tamaños requeridos"
echo
echo -e "${GREEN}==========================================${NC}"
echo
echo -e "${YELLOW}🚀 Próximos pasos:${NC}"
echo "   1. Ejecuta 'flutter run' para probar la app"
echo "   2. Verifica que el icono aparezca en el launcher"
echo "   3. ¡Disfruta tu app con el branding de Nexus TCG!"
echo
