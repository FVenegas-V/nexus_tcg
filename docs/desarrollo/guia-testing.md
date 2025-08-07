# Guía de Testing - Nexus TCG

## 🧪 Estrategia de Testing

El proyecto Nexus TCG implementa una estrategia de testing integral que asegura la calidad del código y la funcionalidad del sistema.

## 📊 Cobertura Actual

```
Name                        Stmts   Miss  Cover
-----------------------------------------------
nexus_api/__init__.py          0      0   100%
nexus_api/settings.py         42      0   100%
nexus_api/urls.py              6      0   100%
users/__init__.py              0      0   100%
users/admin.py                 1      0   100%
users/apps.py                  4      0   100%
users/models.py               15      0   100%
users/serializers.py          45      0   100%
users/views.py                89      0   100%
-----------------------------------------------
TOTAL                        202      0   100%
```

## 🔧 Configuración de Testing

### Estructura de Tests
```
backend/
├── users/
│   ├── tests.py                 # Test suite principal
│   └── test_*.py               # Tests específicos (futuro)
├── manage.py
└── nexus_api/
    └── settings.py             # Configuración de test DB
```

### Base de Datos de Testing
```python
# settings.py - Configuración automática
if 'test' in sys.argv:
    DATABASES['default'] = {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:'
    }
```

## 🏃‍♂️ Ejecutar Tests

### Comandos Básicos
```bash
# Todos los tests
python manage.py test

# Tests específicos de users
python manage.py test users

# Con verbosidad
python manage.py test --verbosity=2

# Tests en paralelo
python manage.py test --parallel
```

### Con Docker
```bash
# Ejecutar tests en contenedor
docker-compose exec backend python manage.py test

# Con coverage
docker-compose exec backend coverage run --source='.' manage.py test
docker-compose exec backend coverage report
docker-compose exec backend coverage html
```

### Con Coverage
```bash
# Instalar coverage
pip install coverage

# Ejecutar con coverage
coverage run --source='.' manage.py test

# Reporte en consola
coverage report

# Reporte HTML
coverage html
# Abrir htmlcov/index.html
```

## 📝 Tests Implementados

### 1. Tests de Modelos
```python
class UserModelTest(TestCase):
    def test_user_creation()           # Creación de usuario
    def test_user_str_representation() # Representación string
    def test_user_email_unique()       # Email único
```

### 2. Tests de Autenticación
```python
class AuthenticationTest(TestCase):
    def test_user_registration()       # Registro exitoso
    def test_registration_validation() # Validaciones
    def test_user_login()             # Login exitoso
    def test_login_invalid()          # Credenciales inválidas
    def test_jwt_token_generation()   # Generación JWT
    def test_token_refresh()          # Renovación de tokens
```

### 3. Tests de Verificación de Email
```python
class EmailVerificationTest(TestCase):
    def test_send_verification_code()  # Envío de código
    def test_verify_email_success()    # Verificación exitosa
    def test_verify_invalid_code()     # Código inválido
    def test_verify_expired_code()     # Código expirado
```

### 4. Tests de Recuperación de Contraseña
```python
class PasswordRecoveryTest(TestCase):
    def test_password_reset_request()   # Solicitud de reset
    def test_password_reset_confirm()   # Confirmación de reset
    def test_invalid_token()           # Token inválido
    def test_expired_token()           # Token expirado
```

### 5. Tests de Cambio de Contraseña
```python
class ChangePasswordTest(TestCase):
    def test_change_password_success()  # Cambio exitoso
    def test_wrong_old_password()      # Contraseña actual incorrecta
    def test_weak_new_password()       # Contraseña débil
```

### 6. Tests de Endpoints Protegidos
```python
class ProtectedEndpointsTest(TestCase):
    def test_access_with_valid_token()  # Acceso con token válido
    def test_access_without_token()     # Acceso sin token
    def test_access_with_expired_token() # Token expirado
```

## 🚀 CI/CD Testing

### GitHub Actions
```yaml
# .github/workflows/django-ci.yml
- name: Run tests
  run: |
    cd backend
    python manage.py test --verbosity=2

- name: Generate coverage report
  run: |
    cd backend
    coverage run --source='.' manage.py test
    coverage xml

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
```

### Local Pre-commit
```bash
# Script recomendado para antes de commit
#!/bin/bash
echo "🧪 Ejecutando tests..."
python manage.py test

echo "📊 Generando reporte de coverage..."
coverage run --source='.' manage.py test
coverage report --fail-under=95

echo "🔍 Verificando linting..."
flake8 .

echo "✅ Todo listo para commit!"
```

## 📋 Mejores Prácticas

### 1. Naming Conventions
```python
class TestUserAuthentication(TestCase):
    def test_should_create_user_when_valid_data_provided(self):
        """Test descriptivo de lo que debe hacer"""
        pass
    
    def test_should_fail_when_email_already_exists(self):
        """Test descriptivo del caso de fallo"""
        pass
```

### 2. Test Data
```python
def setUp(self):
    """Configuración común para todos los tests"""
    self.user_data = {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'TestPass123!',
        'password2': 'TestPass123!'
    }
    
def create_test_user(self):
    """Helper para crear usuarios de prueba"""
    return User.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='TestPass123!'
    )
```

### 3. Assertions Claras
```python
# ❌ Assertion poco clara
self.assertTrue(response.status_code == 201)

# ✅ Assertion clara
self.assertEqual(response.status_code, 201)
self.assertIn('access', response.data)
self.assertEqual(User.objects.count(), 1)
```

### 4. Test Isolation
```python
def tearDown(self):
    """Limpieza después de cada test"""
    User.objects.all().delete()
    cache.clear()
```

## 🎯 Métricas de Calidad

### Objetivos de Coverage
- **Objetivo mínimo**: 90%
- **Objetivo actual**: 100%
- **Mantenimiento**: No permitir decrease

### Tiempo de Ejecución
```
Ran 23 tests in 2.847s

Objetivo: < 5 segundos para suite completa
```

### Categorización de Tests
```
Unit Tests:        18 tests (78%)
Integration Tests:  4 tests (17%)
E2E Tests:         1 test  (4%)
```

## 🐛 Debugging Tests

### Tests Fallidos
```bash
# Ejecutar test específico
python manage.py test users.tests.TestUserAuthentication.test_user_login

# Con debugging
python manage.py test --debug-mode

# Con pdb
import pdb; pdb.set_trace()
```

### Logs de Testing
```python
import logging
logger = logging.getLogger(__name__)

def test_something(self):
    logger.debug("Test starting...")
    # test code
    logger.debug("Test completed")
```

## 📚 Herramientas Recomendadas

### Testing Libraries
```bash
pip install pytest-django    # Framework alternativo
pip install factory-boy      # Test data factories
pip install freezegun        # Mock de datetime
pip install responses        # Mock de HTTP requests
```

### VS Code Extensions
- Python Test Explorer
- Coverage Gutters
- Test Adapter

## 🔄 Próximos Tests

### Fase 2: Communities
```python
class CommunityTestCase(TestCase):
    def test_community_creation()
    def test_community_membership()
    def test_community_permissions()
```

### Fase 3: Cards
```python
class CardTestCase(TestCase):
    def test_card_creation()
    def test_card_collection()
    def test_card_trading()
```

---

*Para más información sobre testing en Django: [Django Testing Documentation](https://docs.djangoproject.com/en/5.0/topics/testing/)*
