# INSTRUCCIONES PARA ACTUALIZAR EL LOGO DE NEXUS TCG

## 📱 Pasos para actualizar los iconos de la aplicación:

### 1. **Preparar tu imagen del logo**
Tu logo actual se ve perfecto. Necesitas guardarlo en dos versiones:

**Versión principal (nexus_tcg_logo.png):**
- Tamaño: 1024x1024 pixels
- Formato: PNG con fondo transparente o blanco
- El logo completo (carta + texto "NEXUS TCG")
- Centrado en el canvas cuadrado

**Versión foreground (nexus_tcg_logo_foreground.png):**
- Tamaño: 1024x1024 pixels  
- Solo la carta coral con el diamante blanco
- Sin el texto "NEXUS TCG"
- Fondo transparente
- Para iconos adaptativos de Android

### 2. **Guardar los archivos**
Guarda ambas imágenes en:
```
assets/icons/
├── nexus_tcg_logo.png (1024x1024 - logo completo)
└── nexus_tcg_logo_foreground.png (1024x1024 - solo carta)
```

### 3. **Generar los iconos**
Ejecuta estos comandos en la terminal:

```bash
# Instalar o actualizar flutter_launcher_icons
flutter pub get

# Generar todos los iconos para todas las plataformas
flutter pub run flutter_launcher_icons
```

### 4. **Verificar los resultados**
Los iconos se generarán automáticamente en:
- **Android**: `android/app/src/main/res/mipmap-*/`
- **iOS**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- **Web**: `web/icons/`
- **Windows**: `windows/runner/resources/`
- **macOS**: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

### 5. **Colores configurados**
- **Color principal**: #FF6B6B (coral del logo)
- **Fondo adaptativo**: Coral para Android
- **Tema web**: Coral para coherencia visual

### 6. **Testear en dispositivos**
```bash
# Ejecutar en Android
flutter run

# Verificar que el icono aparezca en el launcher
```

## 🎨 Especificaciones técnicas:

### Formatos recomendados:
- **PNG**: Para mejor calidad en iconos
- **Resolución**: 1024x1024 mínimo
- **Transparencia**: Sí para foreground, opcional para principal

### Colores del logo:
- **Coral principal**: #FF6B6B
- **Texto**: #666666 (gris)
- **Diamante**: #FFFFFF (blanco)

## ✅ Una vez completado:
- El logo de Nexus TCG aparecerá en todas las plataformas
- Colores consistentes con el branding
- Iconos adaptativos para Android
- Soporte completo multiplataforma

**¡Tu aplicación tendrá el branding completo de Nexus TCG!** 🎮
