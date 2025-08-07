# 🚀 Guía de Setup de Desarrollo - Nexus TCG

## 📋 Prerrequisitos

### Herramientas Requeridas
- **Python 3.11+** - [Descargar aquí](https://www.python.org/downloads/)
- **Node.js 18+** - [Descargar aquí](https://nodejs.org/)
- **Flutter 3.0+** - [Instalar Flutter](https://flutter.dev/docs/get-started/install)
- **PostgreSQL 13+** - [Descargar aquí](https://www.postgresql.org/download/)
- **Git** - [Descargar aquí](https://git-scm.com/)

### Cuentas de Servicios (Opcional para desarrollo local)
- **Firebase** - Para notificaciones push
- **AWS S3 / Google Cloud Storage** - Para almacenamiento de archivos

## 🛠️ Setup del Proyecto

### 1. Clonar el Repositorio
```bash
git clone https://github.com/FVenegas-V/nexus_tcg.git
cd nexus_tcg
```

### 2. Setup Backend (Django)

#### Crear entorno virtual
```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

#### Instalar dependencias
```bash
pip install -r requirements.txt
```

#### Configurar base de datos
```bash
# Crear base de datos PostgreSQL
createdb nexus_tcg_dev

# Copiar archivo de configuración
cp .env.example .env
```

#### Configurar variables de entorno (.env)
```bash
# Configuración básica para desarrollo
SECRET_KEY=your-secret-key-here
DEBUG=True
DATABASE_URL=postgres://username:password@localhost:5432/nexus_tcg_dev

# Email (opcional - usa console backend por defecto)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend

# Para testing con email real
# EMAIL_HOST=smtp.gmail.com
# EMAIL_PORT=587
# EMAIL_USE_TLS=True
# EMAIL_HOST_USER=your-email@gmail.com
# EMAIL_HOST_PASSWORD=your-app-password
```

#### Ejecutar migraciones
```bash
python manage.py migrate
```

#### Crear superusuario
```bash
python manage.py createsuperuser
```

#### Ejecutar servidor de desarrollo
```bash
python manage.py runserver
```

✅ **Backend funcionando en**: http://localhost:8000

### 3. Setup Frontend (Flutter)

#### Verificar instalación de Flutter
```bash
flutter doctor
```

#### Obtener dependencias
```bash
cd ../lib  # Desde la raíz del proyecto
flutter pub get
```

#### Ejecutar en emulador/dispositivo
```bash
# Android
flutter run

# iOS (solo en macOS)
flutter run -d ios

# Web (para testing)
flutter run -d web
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
python manage.py test
```

### Coverage Report
```bash
pip install coverage
coverage run --source='.' manage.py test
coverage report
coverage html  # Genera reporte HTML en htmlcov/
```

### Frontend Tests
```bash
cd ../lib
flutter test
```

## 🐳 Setup con Docker (Alternativo)

### Prerrequisitos Docker
- **Docker Desktop** - [Descargar aquí](https://www.docker.com/products/docker-desktop)
- **Docker Compose** - Incluido con Docker Desktop

### Ejecutar con Docker
```bash
# Desde la raíz del proyecto
docker-compose up --build

# En background
docker-compose up -d
```

✅ **Servicios disponibles**:
- Backend API: http://localhost:8000
- PostgreSQL: localhost:5432
- Adminer (DB Admin): http://localhost:8080

### Comandos útiles Docker
```bash
# Ver logs
docker-compose logs -f backend

# Ejecutar migraciones
docker-compose exec backend python manage.py migrate

# Crear superusuario
docker-compose exec backend python manage.py createsuperuser

# Ejecutar tests
docker-compose exec backend python manage.py test

# Parar servicios
docker-compose down
```

## 🔧 Herramientas de Desarrollo

### Extensiones VS Code Recomendadas
```json
{
    "recommendations": [
        "ms-python.python",
        "Dart-Code.flutter",
        "ms-python.black-formatter",
        "ms-python.isort",
        "ms-python.flake8",
        "bradlc.vscode-tailwindcss"
    ]
}
```

### Pre-commit Hooks
```bash
# Instalar pre-commit
pip install pre-commit

# Configurar hooks
pre-commit install

# Ejecutar manualmente
pre-commit run --all-files
```

## 📡 APIs de Desarrollo

### Endpoints Principales
- **Admin Panel**: http://localhost:8000/admin/
- **API Root**: http://localhost:8000/api/
- **API Documentation**: http://localhost:8000/api/docs/

### Datos de Prueba
```bash
# Cargar datos de ejemplo
python manage.py loaddata fixtures/sample_data.json
```

## ❗ Troubleshooting

### Problemas Comunes

#### Error: "No module named 'django'"
```bash
# Verificar que el entorno virtual esté activado
pip list | grep Django
```

#### Error de base de datos
```bash
# Verificar conexión PostgreSQL
python manage.py dbshell
```

#### Flutter doctor issues
```bash
# Verificar instalación
flutter doctor -v
```

### Logs y Debugging
```bash
# Backend logs
python manage.py runserver --verbosity=2

# Django shell para debugging
python manage.py shell

# Ver migraciones
python manage.py showmigrations
```

## 🤝 Contribución

### Flujo de Trabajo
1. Crear branch desde `main`
2. Desarrollar funcionalidad
3. Ejecutar tests localmente
4. Crear Pull Request
5. Review y merge

### Commits
```bash
# Formato de commits
git commit -m "feat: implementar autenticación JWT"
git commit -m "fix: corregir validación de email"
git commit -m "docs: actualizar README"
```

## 📚 Recursos Adicionales

- [Documentación Django](https://docs.djangoproject.com/)
- [Documentación Flutter](https://flutter.dev/docs)
- [DRF Documentation](https://www.django-rest-framework.org/)
- [Especificaciones del Proyecto](./docs/specs/)

---

**¿Problemas durante el setup?** Crear un issue en GitHub o contactar al equipo de desarrollo.
