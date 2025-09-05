# Nexus TCG

<div align="center">

![Nexus TCG Logo](https://img.shields.io/badge/Nexus_TCG-MVP_COMPLETO_100%25-green?style=for-the-badge&logo=flutter&logoColor=white)


## 📋 **Descripción del Proyecto**

**Nexus TCG** es una aplicación móvil completa para jugadores de Trading Card Games que conecta comunidades, facilita el intercambio de cartas y permite crear experiencias compartidas en el mundo de los juegos de cartas coleccionables.

### ✨ **Características Principales**
- 🎯 **Comunidades por juego** - Organiza por tipos de TCG (Magic, Pokémon, Yu-Gi-Oh, etc.)
- 💬 **Sistema social** - Posts, comentarios, reacciones y discusiones
- ⭐ **Sistema de calificaciones** - Valoraciones entre jugadores con anti-gaming
- 🔔 **Notificaciones en tiempo real** - Sistema completo con preferencias personalizables
- 📱 **App móvil nativa** - Flutter con Material Design 3

---
<div>

## 📊 **Estado de Desarrollo**


| Fase | Descripción | Progreso | Estado |
|------|-------------|-----------|---------|
| **Fase 0** | 🏗️ Fundación | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 1** | 🔐 Autenticación | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 2** | 👥 Comunidades | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 3** | 💬 Posts & Comentarios | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 4** | ⭐ Sistema de Calificaciones | 100% (6/6) | ✅ **COMPLETADA** |
| **Fase 5** | 🔔 Sistema de Notificaciones | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 7** | 📱 Frontend Flutter | 100% (7/7) | ✅ **COMPLETADA** |

**📊 MVP COMPLETADO:**
- Total: 38 tickets implementados
- **Estado: 100% COMPLETADO ✅**mplementaciones Completadas**

</div>

<div>

#### 🔔 **Fase 5: Sistema de Notificaciones COMPLETO** *(NUEVA - 2 septiembre 2025)*
- 🔔 **APIs REST Completas**: 11 endpoints para gestión completa de notificaciones
- 📱 **Frontend Flutter Completo**: UI reactiva con polling inteligente cada 30 segundos
- 🎨 **UI Completa**: Badges en tiempo real, cards optimizadas, navegación fluida
- ⚙️ **Preferencias Granulares**: Configuración detallada por tipo de notificación
- 🔄 **Gestión del Ciclo de Vida**: Pausa/reanudación automática del polling
- 🎯 **UX Optimizada**: Indicadores visuales, contadores precisos, navegación contextual

#### 🐛 **Fixes Críticos de Comunidades** *(2 septiembre 2025)*
- 🔧 **Bug Filtrado Posts**: Corrección crítica - posts ahora se filtran correctamente por comunidad
- 📊 **Contadores Sincronizados**: Corrección automática de contadores de posts desactualizados
- ♾️ **Vista Completa de Posts**: Implementación de scroll infinito con paginación de 20 posts
- ⚡ **Actualización Tiempo Real**: Posts aparecen inmediatamente después de crearlos
- 🎨 **UX Mejorada**: Navegación fluida sin interrupciones, animaciones optimizadas

#### 📱 **Fase 7: Frontend Flutter COMPLETO** *(Septiembre 2025)*
- 🔐 **Autenticación Completa**: Login/registro con validaciones robustas
- 🧭 **Navegación**: Bottom tabs + rutas protegidas con estado persistente
- 👥 **Comunidades**: Listado, búsqueda, detalles, gestión completa de membresías
- 📄 **Feed Posts**: Paginación infinita + filtros + crear posts con imágenes
- 😀 **Reacciones**: Sistema completo con 6 emojis + UI tiempo real optimizada
- 👤 **Perfil**: Edición completa, configuraciones, gestión de avatar
- 🔔 **Notificaciones**: UI completa con preferencias personalizables
- 🎨 **UI/UX**: Material Design 3 + animaciones responsivas y fluidasBackend MVP: 100% completo | Frontend MVP: 100% completo*

</div>

---

## 🏗️ **Arquitectura del Proyecto**

### 🎨 **Frontend (Flutter)**
```
lib/
├── 📱 main.dart              # Punto de entrada principal
├── 🎨 themes/               # Temas y estilos
├── 📄 screens/              # Pantallas de la aplicación
├── 🧩 widgets/              # Componentes reutilizables
├── 🔧 services/             # Servicios y API calls
├── 📦 models/               # Modelos de datos
└── 🗂️ utils/                # Utilidades y helpers
```

**Tecnologías Frontend:**
- ![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat-square&logo=flutter) **Flutter 3.0+** - Framework multiplataforma
- ![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart) **Dart 3.0+** - Lenguaje de programación
- 📱 **Plataformas**: Android, iOS.


**Tecnologías Backend:**
- ![Django](https://img.shields.io/badge/Django-5.2.4-092E20?style=flat-square&logo=django) **Django 5.2.4** - Framework backend robusto
- ![DRF](https://img.shields.io/badge/DRF-Latest-red?style=flat-square) **Django REST Framework** - APIs REST potentes
- ![JWT](https://img.shields.io/badge/JWT-Simple_JWT-000000?style=flat-square) **JWT Authentication** - Autenticación segura
- ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Prod-336791?style=flat-square&logo=postgresql) **PostgreSQL** - Base de datos producción
- ![SQLite](https://img.shields.io/badge/SQLite-Dev-003B57?style=flat-square&logo=sqlite) **SQLite** - Base de datos desarrollo

---

## 🛡️ **Seguridad y Calidad Implementada**

### 🔒 **Seguridad**
- 🔐 **Autenticación JWT** con refresh tokens
- 🔒 **Tokens UUID** criptográficamente seguros para recuperación
- ⏰ **Expiración automática** de tokens (1 hora)
- 🛡️ **Hash seguro** de contraseñas con Django
- ✅ **Validaciones** exhaustivas en todos los endpoints
- 🚫 **Tokens de un solo uso** para evitar reutilización

### 🧪 **Calidad y Testing**
- ✅ **100% Test Coverage** en módulos core
- 🔄 **CI/CD Pipeline** con GitHub Actions
- 📊 **Security Checks** automáticos
- 📚 **Documentación** completa y organizada

---


### 📱 **Frontend Flutter COMPLETADO AL 100%**
```
🔐 Autenticación     ✅ Login/registro con validaciones robustas
🧭 Navegación        ✅ Bottom tabs + rutas protegidas con estado persistente
👥 Comunidades       ✅ Listado, búsqueda, detalles, gestión completa de membresías
📄 Feed Posts        ✅ Paginación infinita + filtros + crear posts con actualización tiempo real
✏️ Crear Posts       ✅ Editor con imágenes + validaciones + navegación sin interrupciones
😀 Reacciones        ✅ Sistema completo con 6 emojis + UI tiempo real optimizada
👤 Perfil            ✅ Edición completa, configuraciones, gestión de avatar
🔔 Notificaciones    ✅ UI completa con preferencias + polling inteligente + badges
🎨 UI/UX            ✅ Material Design 3 + animaciones responsivas + fixes críticos
🛠️ Fixes Críticos    ✅ Filtrado posts + contadores sincronizados + scroll infinito
```

#### 🔔 **Notificaciones - Detalles Técnicos de Implementación**
- 📊 **Polling Inteligente**: Cada 30 segundos con gestión de ciclo de vida
- 🏷️ **Badges Dinámicos**: Contadores en tiempo real con estado reactivo
- 🎨 **UI Optimizada**: Cards responsive, navegación contextual
- ⚙️ **Preferencias Granulares**: 7 tipos configurables individualmente
- 🔄 **Gestión de Estado**: Provider pattern con persistencia local
- 📱 **UX Fluida**: Animaciones suaves, feedback visual inmediato

---

## 🎯 **MVP Completado - Próximos Pasos**

### ✅ **Estado de Producción**
- **Backend**: Dockerizado y listo para deploy
- **Frontend**: APK optimizado para distribución
- **Base de Datos**: Migrado y optimizado para PostgreSQL
- **CI/CD**: Pipeline automatizado funcionando
- **Documentación**: Completa para mantenimiento

### � **Roadmap Post-MVP**
1. **Notificaciones Push Nativas** - iOS/Android
2. **Chat en Tiempo Real** - WebSockets
3. **Sistema de Trading** - Intercambio de cartas
4. **Torneos y Eventos** - Organización de competencias
5. **Monetización** - Features premium

## 🚀 **Quick Start**

### 📋 **Prerrequisitos**
- Python 3.11+
- PostgreSQL (producción)
- Git

## 🚀 **Instalación**

### ⚡ **Instalación Rápida (Desarrollo)**

```bash
# 1. Clonar repositorio
git clone https://github.com/FVenegas-V/nexus_tcg.git
cd nexus_tcg

# 2. Levantar Backend con Docker
docker-compose up --build

# 3. Para Flutter (desarrollo móvil)
cd nexus_tcg
flutter pub get
flutter run

# 4. Acceder a la aplicación
# API Backend: http://localhost:8000
# Admin DB: http://localhost:8080
# Flutter: Emulador o dispositivo físico
```

### 📚 **Documentación Completa**
- 📖 **[Guía de Desarrollo](docs/desarrollo/configuracion-entorno.md)**
- 🔌 **[APIs Backend](docs/apis/autenticacion.md)**
- � **[Frontend Flutter](docs/desarrollo/)**
- 🧪 **[Testing](docs/desarrollo/guia-testing.md)**


---

<div align="center">

### 🎮 *"Conectando jugadores, construyendo comunidades"*

**Hecho con ❤️ para la comunidad TCG**

![Star the repo](https://img.shields.io/github/stars/FVenegas-V/nexus_tcg?style=social)
![Follow](https://img.shields.io/github/followers/FVenegas-V?style=social)

</div>
