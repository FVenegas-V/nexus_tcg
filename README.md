# 🎮 Nexus TCG
### *Tu plataforma definitiva para Trading Card Games*

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Django](https://img.shields.io/badge/Django-5.2.4-092E20?style=for-the-badge&logo=django&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Ready-336791?style=for-the-badge&logo=postgresql&logoColor=white)

![Progreso](https://img.shields.io/badge/Progreso_MVP-10.2%25-4CAF50?style=for-the-badge)
![Estado](https://img.shields.io/badge/Estado-En_Desarrollo-orange?style=for-the-badge)
![Licencia](https://img.shields.io/badge/Licencia-MIT-blue?style=for-the-badge)

</div>

---

## 🌟 **Descripción del Proyecto**

**Nexus TCG** es una plataforma social completa para jugadores de Trading Card Games que conecta comunidades, facilita el intercambio de cartas y permite crear experiencias compartidas en el mundo de los juegos de cartas coleccionables.

### ✨ **Características Principales**
- 🎯 **Comunidades por juego** - Organiza por tipos de TCG (Magic, Pokémon, Yu-Gi-Oh, etc.)
- 💬 **Sistema social** - Posts, comentarios, reacciones y discusiones
- ⭐ **Reputación de usuarios** - Sistema de valoraciones entre jugadores
- 📱 **Notificaciones push** - Mantente conectado con tu comunidad
- 🔍 **Búsqueda avanzada** - Encuentra jugadores, cartas y eventos
- 🌍 **Geolocalización** - Conecta con jugadores cercanos

---

## 📊 **Estado de Desarrollo**

<div align="center">

### 🎯 **Progreso General: 10.2% del MVP**
*5 de 49 tickets completados*

</div>

| Fase | Descripción | Progreso | Estado |
|------|-------------|-----------|---------|
| **Fase 0** | 🏗️ Fundación | 40% (2/5) | 🟡 En Progreso |
| **Fase 1** | 🔐 Autenticación | 42.9% (3/7) | 🟡 En Progreso |
| **Fase 2** | 👥 Comunidades | 0% (0/5) | 🔴 Pendiente |
| **Fase 3** | 💬 Posts & Comentarios | 0% (0/6) | 🔴 Pendiente |
| **Fase 4** | ⭐ Reputación | 0% (0/5) | 🔴 Pendiente |
| **Fase 5** | 📱 Notificaciones | 0% (0/4) | 🔴 Pendiente |
| **Fase 6** | 🔍 Búsqueda | 0% (0/4) | 🔴 Pendiente |
| **Fase 7** | 📱 Frontend Flutter | 0% (0/8) | 🔴 Pendiente |
| **Fase 8** | 🚀 Producción | 0% (0/5) | 🔴 Pendiente |

### 🎉 **Últimas Implementaciones Completadas**

#### ✅ **Fase 1-0003: Sistema de Recuperación de Contraseñas** *(Recién Completado)*
- 🔒 Tokens UUID seguros con expiración de 1 hora
- 📧 Sistema de email con templates HTML profesionales
- 🔌 3 nuevas APIs REST para flujo completo
- 🧪 Testing exhaustivo (unitarios + integración + demo)
- 📚 Documentación técnica completa

#### ✅ **Fase 1-0002: Autenticación JWT**
- 🎫 Tokens JWT con refresh automático
- 🔐 Endpoints seguros con permisos
- ⏰ Expiración configurable (60min access, 7 días refresh)

#### ✅ **Fase 1-0001: Registro de Usuarios**
- 👤 Modelo de usuario personalizado
- ✅ Validaciones completas de datos
- 🛡️ Hash seguro de contraseñas

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
- ![Django](https://img.shields.io/badge/Django-5.2.4-092E20?style=flat-square&logo=django) **Django 5.2.4** - Framework web robusto
- ![DRF](https://img.shields.io/badge/DRF-Latest-red?style=flat-square) **Django REST Framework** - APIs REST potentes
- ![JWT](https://img.shields.io/badge/JWT-Simple_JWT-000000?style=flat-square) **JWT Authentication** - Autenticación segura
- ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Prod-336791?style=flat-square&logo=postgresql) **PostgreSQL** - Base de datos producción
- ![SQLite](https://img.shields.io/badge/SQLite-Dev-003B57?style=flat-square&logo=sqlite) **SQLite** - Base de datos desarrollo

---

## 🛡️ **Seguridad Implementada**

- 🔐 **Autenticación JWT** con refresh tokens
- 🔒 **Tokens UUID** criptográficamente seguros para recuperación
- ⏰ **Expiración automática** de tokens (1 hora)
- 🛡️ **Hash seguro** de contraseñas con Django
- ✅ **Validaciones** exhaustivas en todos los endpoints
- 🚫 **Tokens de un solo uso** para evitar reutilización

---

## 📈 **Roadmap de Desarrollo**

### 🎯 **Próximas Implementaciones (Q3 2025)**

#### 🔄 **Fase 1-0004: Verificación de Email** *(Próximo)*
- 📧 Email de verificación para nuevos usuarios
- 🔗 Links de activación con tokens seguros
- ✅ Estados de verificación en perfil

#### 👥 **Fase 2: Sistema de Comunidades**
- 🏷️ Modelos para diferentes tipos de TCG
- 🔍 Búsqueda y filtrado de comunidades
- 📝 Suscripción a comunidades de interés

#### 💬 **Fase 3: Posts y Comentarios**
- 📰 Sistema de posts con imágenes
- 💬 Comentarios anidados
- ❤️ Sistema de reacciones (likes/emojis)


---

### 🎮 *"Conectando jugadores, construyendo comunidades"*

**Hecho con ❤️ para la comunidad TCG**

</div>

