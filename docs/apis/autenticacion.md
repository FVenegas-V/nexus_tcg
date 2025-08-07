# Sistema de Autenticación JWT - Nexus TCG

## Endpoints Disponibles

### 1. Registro de Usuario
**POST** `/api/auth/register/`

```json
// Request
{
    "username": "nuevo_usuario",
    "email": "usuario@email.com",
    "password": "contraseña_segura",
    "password2": "contraseña_segura"
}

// Response (201 Created)
{
    "username": "nuevo_usuario",
    "email": "usuario@email.com"
}
```

### 2. Login (Obtener Tokens)
**POST** `/api/auth/login/`

```json
// Request
{
    "username": "nuevo_usuario",
    "password": "contraseña_segura"
}

// Response (200 OK)
{
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "user": {
        "id": 1,
        "username": "nuevo_usuario",
        "email": "usuario@email.com",
        "first_name": "",
        "last_name": ""
    }
}
```

### 3. Renovar Token de Acceso
**POST** `/api/auth/refresh/`

```json
// Request
{
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}

// Response (200 OK)
{
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

### 4. Perfil de Usuario (Requiere Autenticación)
**GET** `/api/users/me/`

```bash
# Header requerido
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

```json
// Response (200 OK)
{
    "id": 1,
    "username": "nuevo_usuario",
    "email": "usuario@email.com",
    "first_name": "",
    "last_name": "",
    "date_joined": "2025-08-04T12:00:00Z",
    "is_active": true
}
```

## Configuración de Tokens

- **Access Token**: Válido por 60 minutos
- **Refresh Token**: Válido por 7 días
- **Rotación**: Se genera nuevo refresh token en cada renovación
- **Blacklisting**: Tokens antiguos se invalidan automáticamente

## Uso en Flutter

```dart
// 1. Login
final response = await http.post(
  Uri.parse('http://localhost:8000/api/auth/login/'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': 'usuario',
    'password': 'contraseña'
  }),
);

final tokens = jsonDecode(response.body);
String accessToken = tokens['access'];
String refreshToken = tokens['refresh'];

// 2. Usar token en requests protegidos
final profileResponse = await http.get(
  Uri.parse('http://localhost:8000/api/users/me/'),
  headers: {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  },
);
```

## Manejo de Errores

### Login Fallido
```json
// Response (401 Unauthorized)
{
    "error": "Credenciales inválidas"
}
```

### Token Expirado
```json
// Response (401 Unauthorized)
{
    "detail": "Given token not valid for any token type",
    "code": "token_not_valid",
    "messages": [
        {
            "token_class": "AccessToken",
            "token_type": "access",
            "message": "Token is invalid or expired"
        }
    ]
}
```

### Acceso sin Token
```json
// Response (401 Unauthorized)
{
    "detail": "Authentication credentials were not provided."
}
```

## Próximos Pasos

1. **Logout**: Implementar blacklisting de tokens
2. **Recuperación de contraseña**: Sistema de reset por email
3. **Rate limiting**: Prevenir ataques de fuerza bruta
4. **Logging**: Registrar intentos de acceso
