# Configuración Docker - Nexus TCG

## 🐳 Arquitectura de Contenedores

El proyecto utiliza Docker Compose para gestionar múltiples servicios en desarrollo:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   Flutter       │◄───┤   Django API    │◄───┤   PostgreSQL    │
│   (Futuro)      │    │   Port: 8000    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Cache         │    │   Workers       │
                       │   Redis         │    │   Celery        │
                       │   Port: 6379    │    │   Background    │
                       └─────────────────┘    └─────────────────┘
```

## 🚀 Comandos Principales

### Desarrollo Local
```bash
# Levantar todos los servicios
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Rebuilder imágenes
docker-compose up --build

# Parar todos los servicios
docker-compose down

# Limpiar volúmenes (⚠️ BORRA DATOS)
docker-compose down -v
```

### Gestión de Base de Datos
```bash
# Aplicar migraciones
docker-compose exec backend python manage.py migrate

# Crear superusuario
docker-compose exec backend python manage.py createsuperuser

# Cargar datos de prueba
docker-compose exec backend python manage.py loaddata fixtures/sample_data.json
```

### Testing
```bash
# Ejecutar tests
docker-compose exec backend python manage.py test

# Tests con coverage
docker-compose exec backend coverage run --source='.' manage.py test
docker-compose exec backend coverage report
```

## 📋 Servicios Disponibles

| Servicio | Puerto | URL | Descripción |
|----------|--------|-----|-------------|
| **backend** | 8000 | http://localhost:8000 | Django API |
| **postgres** | 5432 | localhost:5432 | Base de datos |
| **redis** | 6379 | localhost:6379 | Cache y broker |
| **adminer** | 8080 | http://localhost:8080 | Admin DB |
| **celery** | - | - | Workers background |
| **celery-beat** | - | - | Scheduler |

## 🔧 Configuración

### Variables de Entorno (Development)
```env
DEBUG=True
SECRET_KEY=docker-dev-secret-key-change-in-production
DATABASE_URL=postgres://nexus_user:nexus_password@postgres:5432/nexus_tcg_dev
REDIS_URL=redis://redis:6379/0
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
```

### Volúmenes Persistentes
- `postgres_data`: Datos de PostgreSQL
- `redis_data`: Datos de Redis
- `backend_media`: Archivos media de Django

## 🐛 Debugging

### Ver logs específicos
```bash
# Backend Django
docker-compose logs -f backend

# Base de datos
docker-compose logs -f postgres

# Workers Celery
docker-compose logs -f celery
```

### Acceder a contenedores
```bash
# Shell del backend
docker-compose exec backend bash

# Shell de PostgreSQL
docker-compose exec postgres psql -U nexus_user -d nexus_tcg_dev

# Shell de Redis
docker-compose exec redis redis-cli
```

### Problemas Comunes

#### Puerto ya en uso
```bash
# Ver qué está usando el puerto
netstat -ano | findstr :8000

# Cambiar puerto en docker-compose.yml
ports:
  - "8001:8000"  # Cambia puerto local
```

#### Problemas de migraciones
```bash
# Reset completo de base de datos
docker-compose down -v
docker-compose up -d postgres
docker-compose exec backend python manage.py migrate
```

#### Problemas de permisos
```bash
# En Windows con WSL
chmod +x gradlew
```

## 📱 Integración con Flutter

### URLs para desarrollo
```dart
// En desarrollo local
const String baseUrl = 'http://localhost:8000/api';

// En emulador Android
const String baseUrl = 'http://10.0.2.2:8000/api';

// En dispositivo físico (cambiar IP)
const String baseUrl = 'http://192.168.1.100:8000/api';
```

### Testing API desde Flutter
```bash
# Verificar conectividad
curl http://localhost:8000/api/auth/

# Test de login
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test123"}'
```

## 🚀 Producción

### Consideraciones
- Cambiar `SECRET_KEY` por una clave segura
- Usar `DEBUG=False`
- Configurar HTTPS
- Usar base de datos externa (no en contenedor)
- Configurar email backend real
- Implementar logs centralizados

### Docker Compose para Producción
```bash
# Usar archivo específico
docker-compose -f docker-compose.prod.yml up -d
```

## 📚 Referencias

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Django en Docker](https://docs.djangoproject.com/en/5.0/topics/install/#installing-official-release)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Redis Docker](https://hub.docker.com/_/redis)
