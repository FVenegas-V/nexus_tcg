# 🎮 Nexus TCG

---

## 🌟 **Descripción del Proyecto**

**Nexus TCG** Nexus TCG es una aplicación móvil completa para jugadores de Trading Card Games que conecta comunidades, facilita el intercambio de cartas y permite crear experiencias compartidas en el mundo de los juegos de cartas coleccionables.


### 🎯 **Próximas Implementaciones**

#### 💬 **Fase 3: Posts y Comentarios** *(100% Completado - 5/5 tickets)*
- ✅ **Modelos Django**: Post, Comment, Reaction implementados (fase3-0001)
- ✅ **APIs REST Posts**: Sistema completo con reacciones (fase3-0002) - **COMPLETADO**
- ✅ **APIs REST Comments**: Threading y endpoints anidados (fase3-0003) - **COMPLETADO**
- ✅ **Sistema Reacciones**: Integrado en Posts APIs (fase3-0004) - **COMPLETADO**
- ✅ **Upload Imágenes**: Sistema completo con múltiples resoluciones (fase3-0005) - **COMPLETADO**

### ✨ **Características Principales**
- 🎯 **Comunidades por juego** - Organiza por tipos de TCG (Magic, Pokémon, Yu-Gi-Oh, etc.)
- � **Sistema social** - Posts, comentarios, reacciones y discusiones
- ⭐ **Reputación de usuarios** - Sistema de valoraciones entre jugadores
- 🚀 **GitHub Actions**: Deploy staging automático y validacioness Completadas**

- 🔍 **Búsqueda avanzada** - Encuentra jugadores, cartas y eventos

---

## 📊 **Estado de Desarrollo**

<div align="center">

### *Tu aplicació### 🎯 **Progreso General: 51.1% del MVP**
*24 de 47 tickets completados*

</div>

| Fase | Descripción | Progreso | Estado |
|------|-------------|-----------|---------|
| **Fase 0** | 🏗️ Fundación | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 1** | 🔐 Autenticación | 100% MVP (5/5) | ✅ **COMPLETADA** |
| **Fase 2** | 👥 Comunidades | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 3** | 💬 Posts & Comentarios | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 4** | ⭐ Reputación | 0% (0/5) | 🔴 Pendiente |
| **Fase 5** | 📱 Notificaciones | 0% (0/4) | 🔴 Pendiente |
| **Fase 6** | 🔍 Búsqueda | 0% (0/4) | 🔴 Pendiente |
| **Fase 7** | 📱 Frontend Flutter | 86% (6/7) | ✅ **CASI COMPLETO** |
| **Fase 8** | 🚀 Producción | 0% (0/5) | 🔴 Pendiente |

### 🎉 **Últimas Implementaciones Completadas**

#### ✅ **Fase 3: Sistema Social COMPLETO** *(100% Completada - 18 ago 2025)*
- 🏗️ **Modelos Django**: 4 modelos (Post, Comment, Reaction, PostImage) con threading completo
- 🧵 **Sistema de Threading**: Comentarios anidados hasta 3 niveles operativo con APIs
- 😀 **Sistema de Reacciones**: 6 tipos de emoji con toggle automático y estadísticas
- � **APIs REST Completas**: 43+ endpoints (Posts, Comments, Reactions, Images)
- 🖼️ **Sistema de Imágenes**: Upload múltiple con 3 resoluciones automáticas
- 🎯 **Optimización**: Conversión WebP, validación MIME, estructura organizada
- � **Contadores Automáticos**: Signals para sincronización en tiempo real
- 🛡️ **Validaciones Robustas**: Permisos granulares, soft delete, seguridad completa
- 🧪 **Testing Completo**: 40+ tests unitarios y de API (100% funcional)
- 📋 **Admin Interface**: Gestión optimizada con displays jerárquicos

#### ✅ **Fase 2: Backend de Comunidades COMPLETO** *(100% Completada - 14 ago 2025)*
- 🏗️ **Modelos Django**: 5 modelos (Community, CommunityCategory, CommunityMembership, GameType, CommunityTag)
- 📡 **APIs REST**: 20+ endpoints con filtros avanzados, paginación y búsqueda
- 🎮 **Sistema de GameTypes**: Filtros por tipo de juego (Magic, Pokemon, Yu-Gi-Oh, etc.)
- 🏷️ **Sistema de Tags**: Categorización dinámica con autocompletado
- 👥 **Sistema de Membresías**: Join/leave con validaciones robustas
- 🛡️ **Permisos Granulares**: 6 clases de permisos por roles (member, moderator, admin)
- ⚙️ **Admin Panel**: Interface administrativa completa con filtros
- 🧪 **Testing Completo**: Colección Postman con 20+ pruebas validadas
- 📋 **Comandos Management**: Carga de datos y estadísticas automáticas
- 🔍 **Búsqueda Avanzada**: Filtros, sugerencias y autocompletado funcionales

#### ✅ **Fase 0: Infraestructura Completa** *(Completada - 7 ago 2025)*
- 🔄 **CI/CD Pipeline**: Tests automáticos, coverage, security checks
- 🐳 **Docker Compose**: Multi-servicio (Backend, PostgreSQL, Redis, Celery, Adminer)  
- 📚 **Documentación**: Reorganizada en español con estructura lógica
- 🚀 **GitHub Actions**: Deploy staging automático y validaciones

#### ✅ **Fase 1: Sistema de Autenticación MVP Ready** *(Completada)*
- 🔐 **Login/Registro**: JWT con refresh tokens
- 📧 **Verificación Email**: Tokens UUID con expiración
- 🔒 **Recuperación Password**: Sistema completo con emails HTML
- 🛡️ **Cambio Password**: Validaciones robustas + notificaciones
- 🧪 **Testing**: 100% coverage con tests automatizados

#### � **Infraestructura Robusta Lista**
- ✅ CI/CD pipeline con GitHub Actions
- ✅ Docker Compose para desarrollo local
- ✅ Documentación técnica completa en `/docs`
- ✅ Sistema de tickets y metodología establecida

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
- ![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker) **Docker** - Contenedorización y desarrollo

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
- 🐳 **Docker** para entornos reproducibles
- 📊 **Security Checks** automáticos
- 📚 **Documentación** completa y organizada

---

## 🔌 **APIs Implementadas**

### 🔐 **Autenticación**
```
POST   /api/auth/register/              # Registro de usuarios
POST   /api/auth/login/                 # Login (username/email + password)
POST   /api/auth/refresh/               # Renovar tokens JWT
GET    /api/users/me/                   # Perfil del usuario autenticado
PUT    /api/users/me/                   # Actualizar perfil de usuario
PUT    /api/users/me/password/          # Cambio de contraseña
```

### 📧 **Verificación y Recuperación**
```
POST   /api/auth/resend-verification/   # Reenviar email de verificación
GET    /api/auth/verify-email/{token}/  # Verificar email con token
POST   /api/auth/password-reset/        # Solicitar recuperación
GET    /api/auth/password-reset/verify/{token}/  # Verificar token
POST   /api/auth/password-reset/confirm/  # Confirmar nueva contraseña
```

### 👥 **Comunidades**
```
GET    /api/communities/               # Listar comunidades con filtros
POST   /api/communities/               # Crear nueva comunidad
GET    /api/communities/{id}/          # Detalle de comunidad específica
PUT    /api/communities/{id}/          # Actualizar comunidad (admin)
POST   /api/communities/{id}/join/     # Unirse a comunidad
POST   /api/communities/{id}/leave/    # Abandonar comunidad
GET    /api/communities/my-communities/ # Mis comunidades
```

### 💬 **Posts y Comentarios**
```
GET    /api/posts/                     # Listar posts con filtros
POST   /api/communities/{id}/posts/    # Crear post en comunidad
GET    /api/posts/{id}/                # Detalle de post específico
PUT    /api/posts/{id}/                # Actualizar post (autor)
DELETE /api/posts/{id}/                # Eliminar post (soft delete)
GET    /api/posts/feed/                # Feed personalizado
POST   /api/posts/{id}/toggle-reaction/ # Toggle reacción emoji

POST   /api/posts/{id}/comments/       # Crear comentario
GET    /api/posts/{id}/comments/       # Listar comentarios con threading
GET    /api/comments/{id}/             # Detalle de comentario
PUT    /api/comments/{id}/             # Actualizar comentario (autor)
DELETE /api/comments/{id}/             # Eliminar comentario (soft delete)
POST   /api/comments/{id}/reply/       # Responder a comentario (threading)
GET    /api/comments/{id}/thread/      # Ver hilo completo
GET    /api/comments/my-comments/      # Mis comentarios
```

### 📱 **Frontend Flutter Completado**
```
🔐 Autenticación     ✅ Login/registro con validaciones
🧭 Navegación        ✅ Bottom tabs + rutas protegidas
👥 Comunidades       ✅ Listado, búsqueda, detalles
📄 Feed Posts        ✅ Paginación infinita + filtros
✏️ Crear Posts       ✅ Editor con imágenes + validaciones
👤 Perfil            ✅ Edición, configuraciones, avatar
🎨 UI/UX            ✅ Material Design 3 + animaciones
```

---

## 📈 **Roadmap de Desarrollo**

### 🎯 **Próximas Implementaciones**

#### � **Fase 2: Sistema de Comunidades** *(Próximo Objetivo)*
- 🏷️ Modelos para diferentes tipos de TCG
- 🔍 Búsqueda y filtrado de comunidades  
- 📝 Suscripción a comunidades de interés
- 👤 Perfiles públicos de usuarios

#### ⭐ **Fase 4: Sistema de Reputación**
- 🌟 Valoraciones entre usuarios (1-5 estrellas)
- � Algoritmo de cálculo de reputación
- ❤️ Sistema de reacciones (likes/emojis)

#### ⭐ **Fase 4: Reputación**
- 🌟 Sistema de valoraciones entre usuarios
- 📊 Algoritmo de reputación
- 🛡️ Prevención de abuso

## 🚀 **Quick Start**

### 📋 **Prerrequisitos**
- Python 3.11+
- Docker & Docker Compose
- Git

### ⚡ **Instalación Rápida**

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
- �🐳 **[Docker Setup](docs/despliegue/configuracion-docker.md)**
- 🧪 **[Testing](docs/desarrollo/guia-testing.md)**

### 🎯 **Próximos Pasos**
- 🚀 **Completar Fase 2** - Gestión avanzada de roles y filtros (fase2-0004, fase2-0005)
- 🔗 **Integración Flutter + Backend** - Conectar frontend con APIs reales
- 🔜 **Sistema de Posts** backend (Fase 3)
- 🔜 **Sistema de Reputación** completo (Fase 4)


---

### �🎮 *"Conectando jugadores, construyendo comunidades"*

<div align="center">

**Hecho con ❤️ para la comunidad TCG**

![Star the repo](https://img.shields.io/github/stars/FVenegas-V/nexus_tcg?style=social)
![Follow](https://img.shields.io/github/followers/FVenegas-V?style=social)

</div>

