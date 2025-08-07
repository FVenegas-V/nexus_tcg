# Configuración de PostgreSQL - Nexus TCG

## Para Desarrollo (Actual - SQLite)

El proyecto está configurado para usar SQLite en desarrollo por defecto. No necesitas hacer nada adicional.

## Para Producción (PostgreSQL)

### 1. Instalar PostgreSQL

```bash
# En Windows, descargar desde: https://www.postgresql.org/download/windows/
# En Ubuntu/Debian:
sudo apt-get install postgresql postgresql-contrib

# En macOS con Homebrew:
brew install postgresql
```

### 2. Crear base de datos

```sql
# Conectar a PostgreSQL como superuser
sudo -u postgres psql

# Crear base de datos y usuario
CREATE DATABASE nexus_tcg;
CREATE USER nexus_user WITH PASSWORD 'tu_password_seguro';
GRANT ALL PRIVILEGES ON DATABASE nexus_tcg TO nexus_user;
\q
```

### 3. Configurar variables de entorno

Copia `.env.example` a `.env` y configura:

```bash
cp .env.example .env
```

Edita `.env`:
```
ENVIRONMENT=production
DB_NAME=nexus_tcg
DB_USER=nexus_user
DB_PASSWORD=tu_password_seguro
DB_HOST=localhost
DB_PORT=5432
DEBUG=False
SECRET_KEY=una_clave_secreta_muy_segura
```

### 4. Migrar base de datos

```bash
python manage.py migrate
python manage.py createsuperuser
```

## Verificar configuración

```bash
# Verificar que Django detecta PostgreSQL
python manage.py dbshell

# Debería abrir psql conectado a tu base de datos
```

## Notas importantes

- En desarrollo: usa SQLite (automático)
- En producción: usa PostgreSQL (configurar .env)
- Nunca subas archivos .env al repositorio
- Usa .env.example como plantilla
