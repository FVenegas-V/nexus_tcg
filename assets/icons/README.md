# Nexus TCG Logo Assets

## Logo Principal
- `nexus_logo.svg` - Versión vectorial del logo
- Para generar el PNG de 1024x1024 pixels, puedes usar herramientas como:
  - Inkscape: `inkscape --export-type=png --export-width=1024 --export-height=1024 nexus_logo.svg`
  - Online converters: svg2png.com
  - Figma/Adobe Illustrator

## Configuración Flutter
El logo está configurado en `pubspec.yaml` con flutter_launcher_icons para generar automáticamente todos los tamaños necesarios para cada plataforma.

## Colores del Logo
- Coral principal: #FF6B6B (RGB: 255, 107, 107)
- Texto: #666666 (RGB: 102, 102, 102)
- Fondo carta: Blanco #FFFFFF
- Fondo general: Transparente o blanco para iconos

## Nota
Reemplaza `nexus_logo.png` con la versión PNG real del logo que tienes para obtener el resultado final.
