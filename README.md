# 🎮 Nexus TCG

---

## 🌟 **Descripción del Proyecto**

**Nexus TCG** Nexus TCG es una aplicación móvil completa para jugadores de Trading Card Games que conecta comunidades, facilita el intercambio de cartas y permite crear experiencias compartidas en el mundo de los juegos de cartas coleccionables.


### ✨ **Características Principales**
- 🎯 **Comunidades por juego** - Organiza por tipos de TCG (Magic, Pokémon, Yu-Gi-Oh, etc.)
- � **Sistema social** - Posts, comentarios, reacciones y discusiones
- ⭐ **Reputación de usuarios** - Sistema de valoraciones entre jugadores


---

## 📊 **Estado de Desarrollo**

<div align="center">

### *Tu aplicación para coleccionistas de TCG*

### 🎯 **Progreso General: 72% del MVP**
*Backend: 85% completo | Frontend: 55% completo*

</div>

| Fase | Descripción | Progreso | Estado |
|------|-------------|-----------|---------|
| **Fase 0** | 🏗️ Fundación | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 1** | 🔐 Autenticación | 100% MVP (5/5) | ✅ **COMPLETADA** |
| **Fase 2** | 👥 Comunidades | 100% (5/5) | ✅ **COMPLETADA** |
| **Fase 3** | 💬 Posts & Comentarios | **100% Completado** (5/5) | ✅ **COMPLETADA** |
| **Fase 4** | ⭐ Reputación | 0% (0/5) | 🔴 Pendiente |
| **Fase 5** | 📱 Notificaciones | 0% (0/4) | 🔴 Pendiente |
| **Fase 6** | 🔍 Búsqueda | 0% (0/4) | 🔴 Pendiente |
| **Fase 7** | 📱 Frontend Flutter | 55% (4/7) | 🟡 **En Desarrollo** |
| **Fase 8** | 🚀 Producción | 0% (0/5) | 🔴 Pendiente |

### 🎉 **Últimas Implementaciones Completadas**

#### ✅ **Fase 7: Frontend Flutter - Reacciones en Tiempo Real** *(Actualizado - 19 ago 2025)*
- 😀 **Sistema de Reacciones UI**: 6 tipos de emoji con interfaz completa 
- ⚡ **UI Optimista**: Actualizaciones instantáneas con fallback automático
- 🔧 **Corrección de Permisos**: Usuarios pueden reaccionar a posts de otros miembros
- 🐛 **Fix UI Overflow**: Widgets responsivos que se adaptan al espacio disponible
- 🎯 **ReactionsWidget**: Componente reutilizable con Wrap para evitar overflow
- 📱 **Post Detail Screen**: Vista completa con reacciones funcionales
- 🔄 **Estado Sincronizado**: PostsState actualizado en tiempo real
- ✨ **UX Mejorada**: Animaciones suaves y feedback visual

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


### 📱 **Frontend Flutter Completado**
```
🔐 Autenticación     ✅ Login/registro con validaciones
🧭 Navegación        ✅ Bottom tabs + rutas protegidas  
👥 Comunidades       ✅ Listado, búsqueda, detalles
📄 Feed Posts        ✅ Paginación infinita + filtros
✏️ Crear Posts       ✅ Editor con imágenes + validaciones
� Reacciones        ✅ Sistema completo con 6 emojis + UI tiempo real
�👤 Perfil            ✅ Edición, configuraciones, avatar
🎨 UI/UX            ✅ Material Design 3 + animaciones responsivas
```

---

## 📈 **Roadmap de Desarrollo**

### 🎯 **Próximas Implementaciones**

#### � **Fase 2: Sistema de Comunidades** *(Próximo Objetivo)*
- 🏷️ Modelos para diferentes tipos de TCG
- 🔍 Búsqueda y filtrado de comunidades  
- 📝 Suscripción a comunidades de interés
- 👤 Perfiles públicos de usuarios

#### ⭐ **Fase 4: Reputación**
- 🌟 Sistema de valoraciones entre usuarios
- 📊 Algoritmo de reputación
- 🛡️ Prevención de abuso

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

### 🏭 **Instalación en Producción**

#### 📋 **1. CLONAR:** 
```bash
git clone https://github.com/FVenegas-V/nexus_tcg.git
cd nexus_tcg
```

#### 🐍 **2. PREPARAR:** Entorno aislado
```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# .\venv\Scripts\activate  # Windows
```

#### 📦 **3. INSTALAR:** Dependencias
```bash
pip install -r backend/requirements.txt
pip install gunicorn psycopg2-binary
```

#### 🗄️ **4. CONFIGURAR:** Base de datos
```bash
# PostgreSQL
sudo -u postgres createdb nexus_tcg_prod
sudo -u postgres createuser nexus_user
```

#### ⚙️ **5. VARIABLES:** Entorno de producción
```bash
# Crear backend/.env
ENVIRONMENT=production
SECRET_KEY=tu_secret_key_seguro
DEBUG=False
DB_NAME=nexus_tcg_prod
DB_USER=nexus_user
DB_PASSWORD=tu_password
```

#### 🚀 **6. LANZAR:**
```bash
cd backend
python manage.py migrate
python manage.py collectstatic
gunicorn nexus_api.wsgi:application
```

#### ✨ **¡Listo!** Abre [http://127.0.0.1:8000](http://127.0.0.1:8000) y prepárate para el wow

---

### 📚 **Documentación Completa**
- 📖 **[Guía de Desarrollo](docs/desarrollo/configuracion-entorno.md)**
- 🔌 **[APIs Backend](docs/apis/autenticacion.md)**
- � **[Frontend Flutter](docs/desarrollo/)**
- 🧪 **[Testing](docs/desarrollo/guia-testing.md)**


---

### �🎮 *"Conectando jugadores, construyendo comunidades"*

<div align="center">

**Hecho con ❤️ para la comunidad TCG**

![Star the repo](https://img.shields.io/github/stars/FVenegas-V/nexus_tcg?style=social)
![Follow](https://img.shields.io/github/followers/FVenegas-V?style=social)

</div>
