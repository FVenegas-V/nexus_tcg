# nexus_tcg

A new Flutter project.

## Descripción del Proyecto

Nexus TCG es una aplicación movil desarrolada en Flutter para comunidades de juegos de cartas coleccionables.
## Estructura del Proyecto

### Frontend (Flutter)
- **Framework:** Flutter
- **Plataformas soportadas:** Android, iOS, Web, Windows, macOS, Linux
- **Archivo principal:** `lib/main.dart`

### Backend (Django API)
La carpeta `backend/` contiene una API REST desarrollada con Django que incluye:

#### Estructura del Backend:
- **`manage.py`** - Herramienta de línea de comandos de Django para tareas administrativas
- **`db.sqlite3`** - Base de datos SQLite para desarrollo
- **`nexus_api/`** - Configuración principal del proyecto Django
  - `settings.py` - Configuraciones del proyecto (Django 5.2.4)
  - `urls.py` - Configuración de URLs principales
  - `wsgi.py` / `asgi.py` - Configuración para despliegue
- **`users/`** - Aplicación Django para gestión de usuarios
  - `models.py` - Modelos de datos de usuarios
  - `views.py` - Vistas de la API
  - `serializers.py` - Serializadores para la API REST
  - `admin.py` - Configuración del panel de administración
  - `migrations/` - Migraciones de base de datos
- **`venv/`** - Entorno virtual de Python

#### Características del Backend:
- Framework: Django 5.2.4
- Base de datos: SQLite (desarrollo)
- API REST para gestión de usuarios
- Panel de administración de Django disponible

## Historial de Commits Recientes

- **4f736bf** (HEAD -> main, origin/main) - Inicio de desarrollo
- **5302619** - Merge branch 'main' of github.com:FVenegas-V/nexus_tcg
- **9bd3906** - Commit inicial: estructura Flutter creada con flutter create
- **8b86e42** - Nuevo cambio prueba
- **986edb8** - Initial commit

## Cambios Implementados

### Backend
✅ **Configuración inicial del proyecto Django**
- Creado proyecto Django `nexus_api` con configuración base
- Implementada aplicación `users` para gestión de usuarios
- Configurado entorno virtual Python
- Base de datos SQLite inicializada
- Estructura de serializadores y vistas preparada para API REST

### Frontend
✅ **Aplicación Flutter base**
- Estructura inicial de proyecto Flutter multi-plataforma
- Configuración para Android, iOS, Web y Desktop
- Widget principal con mensaje de bienvenida

### Pruebas
✅ **Corrección de errores en tests**
- Solucionado error de constructor constante en `widget_test.dart`
- Tests de widgets funcionando correctamente

## Próximos Pasos

- [ ] Implementar modelos de datos para cartas TCG
- [ ] Integrar autenticación de usuarios
- [ ] Conectar frontend Flutter con backend Django

