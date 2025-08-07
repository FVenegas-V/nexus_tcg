# Especificación de API REST - Nexus TCG

## Introducción

Esta especificación define todos los endpoints REST para la API de Nexus TCG, incluyendo autenticación, gestión de usuarios, comunidades, publicaciones y sistema de reputación.

## Principios de Diseño de API

### Convenciones REST
- **URLs**: Sustantivos en plural (`/api/users/`, `/api/posts/`)
- **HTTP Methods**: GET (lectura), POST (creación), PUT/PATCH (actualización), DELETE (eliminación)
- **Status Codes**: Uso estándar de códigos HTTP
- **Versionado**: `/api/v1/` para versionado explícito

### Formato de Respuesta Estándar
```json
{
    "success": true,
    "data": {...},
    "message": "Mensaje descriptivo",
    "errors": [...],
    "pagination": {
        "count": 100,
        "next": "url",
        "previous": "url",
        "page": 1,
        "pages": 10
    }
}
```

## Autenticación y Autorización

### POST /api/auth/register/
Registro de nuevo usuario.

**Request:**
```json
{
    "username": "string (3-30 chars, alphanumeric + underscore)",
    "email": "string (valid email)",
    "password": "string (min 8 chars)",
    "first_name": "string (optional)",
    "last_name": "string (optional)"
}
```

**Response 201:**
```json
{
    "success": true,
    "data": {
        "user": {
            "id": 1,
            "username": "player123",
            "email": "player@example.com",
            "first_name": "Juan",
            "last_name": "Pérez",
            "avatar_url": null,
            "reputation_score": 0.0,
            "reputation_count": 0,
            "date_joined": "2024-08-04T10:30:00Z"
        },
        "tokens": {
            "access": "jwt_access_token",
            "refresh": "jwt_refresh_token"
        }
    },
    "message": "Usuario registrado exitosamente"
}
```

**Errores:**
- 400: Validación fallida (email duplicado, username en uso, etc.)

### POST /api/auth/login/
Autenticación de usuario existente.

**Request:**
```json
{
    "username": "string", // o email
    "password": "string"
}
```

**Response 200:**
```json
{
    "success": true,
    "data": {
        "user": {...}, // mismo formato que register
        "tokens": {
            "access": "jwt_access_token",
            "refresh": "jwt_refresh_token"
        }
    },
    "message": "Inicio de sesión exitoso"
}
```

**Errores:**
- 401: Credenciales inválidas
- 429: Demasiados intentos fallidos

### POST /api/auth/refresh/
Renovación de token de acceso.

**Request:**
```json
{
    "refresh": "jwt_refresh_token"
}
```

**Response 200:**
```json
{
    "success": true,
    "data": {
        "access": "new_jwt_access_token"
    }
}
```

### POST /api/auth/logout/
Cerrar sesión (invalidar tokens).

**Headers:** `Authorization: Bearer {access_token}`

**Response 200:**
```json
{
    "success": true,
    "message": "Sesión cerrada exitosamente"
}
```

## Gestión de Usuarios

### GET /api/users/me/
Obtener perfil del usuario autenticado.

**Headers:** `Authorization: Bearer {access_token}`

**Response 200:**
```json
{
    "success": true,
    "data": {
        "id": 1,
        "username": "player123",
        "email": "player@example.com",
        "first_name": "Juan",
        "last_name": "Pérez",
        "avatar_url": "https://cdn.example.com/avatars/123.jpg",
        "bio": "Jugador de Magic desde 2010",
        "location_name": "Santiago, Chile",
        "reputation_score": 4.5,
        "reputation_count": 23,
        "is_verified": true,
        "date_joined": "2024-01-15T08:30:00Z",
        "subscribed_communities_count": 5
    }
}
```

### PUT /api/users/me/
Actualizar perfil del usuario autenticado.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
    "first_name": "string (optional)",
    "last_name": "string (optional)",
    "bio": "string (optional, max 500 chars)",
    "location_name": "string (optional)",
    "location_lat": "decimal (optional)",
    "location_lng": "decimal (optional)"
}
```

**Response 200:** Mismo formato que GET /api/users/me/

### POST /api/users/me/avatar/
Subir avatar del usuario.

**Headers:** 
- `Authorization: Bearer {access_token}`
- `Content-Type: multipart/form-data`

**Request:** `Form data con campo 'avatar' (imagen)`

**Response 200:**
```json
{
    "success": true,
    "data": {
        "avatar_url": "https://cdn.example.com/avatars/123.jpg"
    },
    "message": "Avatar actualizado exitosamente"
}
```

### GET /api/users/{id}/
Obtener perfil público de usuario.

**Response 200:**
```json
{
    "success": true,
    "data": {
        "id": 1,
        "username": "player123",
        "first_name": "Juan",
        "avatar_url": "https://cdn.example.com/avatars/123.jpg",
        "bio": "Jugador de Magic desde 2010",
        "reputation_score": 4.5,
        "reputation_count": 23,
        "date_joined": "2024-01-15T08:30:00Z",
        "recent_ratings": [
            {
                "rating": 5,
                "comment": "Excelente jugador, muy confiable",
                "rater_username": "user456",
                "created_at": "2024-08-01T15:20:00Z"
            }
        ]
    }
}
```

## Comunidades

### GET /api/communities/
Listar comunidades con filtros y paginación.

**Query Parameters:**
- `game_type`: Filtrar por tipo de juego
- `search`: Búsqueda por nombre/descripción
- `page`: Número de página (default: 1)
- `page_size`: Elementos por página (default: 20, max: 100)

**Response 200:**
```json
{
    "success": true,
    "data": {
        "results": [
            {
                "id": 1,
                "name": "Magic: The Gathering Santiago",
                "description": "Comunidad de jugadores de MTG en Santiago",
                "game_type": "magic",
                "image_url": "https://cdn.example.com/communities/1.jpg",
                "member_count": 1250,
                "post_count": 3840,
                "created_at": "2024-01-01T00:00:00Z",
                "is_subscribed": false // solo si user autenticado
            }
        ]
    },
    "pagination": {
        "count": 45,
        "next": "https://api.nexustcg.com/api/communities/?page=2",
        "previous": null,
        "page": 1,
        "pages": 3
    }
}
```

### GET /api/communities/{id}/
Obtener detalles de una comunidad específica.

**Response 200:**
```json
{
    "success": true,
    "data": {
        "id": 1,
        "name": "Magic: The Gathering Santiago",
        "description": "Comunidad oficial de jugadores de MTG en Santiago...",
        "game_type": "magic",
        "image_url": "https://cdn.example.com/communities/1.jpg",
        "member_count": 1250,
        "post_count": 3840,
        "created_at": "2024-01-01T00:00:00Z",
        "created_by": {
            "id": 5,
            "username": "admin_user",
            "avatar_url": "https://cdn.example.com/avatars/5.jpg"
        },
        "is_subscribed": true,
        "recent_posts": [
            {
                "id": 123,
                "title": "Torneo este sábado",
                "author_username": "player123",
                "created_at": "2024-08-04T09:00:00Z",
                "comment_count": 8,
                "reaction_count": 15
            }
        ]
    }
}
```

### POST /api/communities/{id}/subscribe/
Suscribirse a una comunidad.

**Headers:** `Authorization: Bearer {access_token}`

**Response 201:**
```json
{
    "success": true,
    "message": "Suscripción exitosa a la comunidad"
}
```

### DELETE /api/communities/{id}/subscribe/
Cancelar suscripción a una comunidad.

**Headers:** `Authorization: Bearer {access_token}`

**Response 200:**
```json
{
    "success": true,
    "message": "Suscripción cancelada"
}
```

## Publicaciones

### GET /api/communities/{id}/posts/
Listar publicaciones de una comunidad.

**Query Parameters:**
- `page`: Número de página
- `ordering`: Campo de ordenamiento (`-created_at`, `reaction_count`, etc.)

**Response 200:**
```json
{
    "success": true,
    "data": {
        "results": [
            {
                "id": 123,
                "title": "Torneo este sábado en Plaza Italia",
                "content": "Hola comunidad! Este sábado haremos un torneo...",
                "image_urls": [
                    "https://cdn.example.com/posts/123_1.jpg",
                    "https://cdn.example.com/posts/123_2.jpg"
                ],
                "author": {
                    "id": 15,
                    "username": "player123",
                    "avatar_url": "https://cdn.example.com/avatars/15.jpg",
                    "reputation_score": 4.5
                },
                "community": {
                    "id": 1,
                    "name": "Magic: The Gathering Santiago"
                },
                "created_at": "2024-08-04T09:00:00Z",
                "updated_at": "2024-08-04T09:00:00Z",
                "comment_count": 8,
                "reaction_count": 15,
                "user_reaction": "like", // solo si user autenticado
                "reactions_summary": {
                    "like": 12,
                    "love": 2,
                    "wow": 1
                }
            }
        ]
    },
    "pagination": {...}
}
```

### POST /api/communities/{id}/posts/
Crear nueva publicación en comunidad.

**Headers:** 
- `Authorization: Bearer {access_token}`
- `Content-Type: multipart/form-data`

**Request:**
```
title: "string (optional, max 200 chars)"
content: "string (required, max 5000 chars)"
images: File[] (optional, max 5 images, 10MB each)
```

**Response 201:**
```json
{
    "success": true,
    "data": {
        // mismo formato que GET post individual
    },
    "message": "Publicación creada exitosamente"
}
```

### GET /api/posts/{id}/
Obtener publicación específica con comentarios.

**Response 200:**
```json
{
    "success": true,
    "data": {
        // formato completo del post
        "comments": [
            {
                "id": 456,
                "content": "¡Excelente! Ahí estaré",
                "author": {
                    "id": 20,
                    "username": "user456",
                    "avatar_url": "https://cdn.example.com/avatars/20.jpg"
                },
                "created_at": "2024-08-04T10:15:00Z",
                "reaction_count": 3,
                "user_reaction": null
            }
        ]
    }
}
```

### POST /api/posts/{id}/comments/
Agregar comentario a publicación.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
    "content": "string (required, max 1000 chars)"
}
```

**Response 201:**
```json
{
    "success": true,
    "data": {
        // formato completo del comentario
    },
    "message": "Comentario agregado exitosamente"
}
```

### POST /api/posts/{id}/react/
Agregar/cambiar reacción a publicación.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
    "reaction_type": "like|love|laugh|wow|sad|angry"
}
```

**Response 200:**
```json
{
    "success": true,
    "data": {
        "reaction_type": "like",
        "reactions_summary": {
            "like": 13,
            "love": 2,
            "wow": 1
        }
    }
}
```

### DELETE /api/posts/{id}/react/
Quitar reacción de publicación.

**Headers:** `Authorization: Bearer {access_token}`

**Response 200:**
```json
{
    "success": true,
    "data": {
        "reactions_summary": {
            "like": 12,
            "love": 2,
            "wow": 1
        }
    }
}
```

## Sistema de Reputación

### POST /api/users/{id}/rate/
Valorar a otro usuario.

**Headers:** `Authorization: Bearer {access_token}`

**Request:**
```json
{
    "rating": 1-5,
    "comment": "string (optional, max 500 chars)",
    "interaction_context": "trade|game|event|other"
}
```

**Response 201:**
```json
{
    "success": true,
    "data": {
        "rating": 5,
        "comment": "Excelente jugador, muy confiable",
        "interaction_context": "trade",
        "created_at": "2024-08-04T11:30:00Z"
    },
    "message": "Valoración registrada exitosamente"
}
```

### GET /api/users/{id}/ratings/
Obtener valoraciones recibidas por un usuario.

**Response 200:**
```json
{
    "success": true,
    "data": {
        "summary": {
            "average_rating": 4.5,
            "total_ratings": 23,
            "distribution": {
                "5": 15,
                "4": 6,
                "3": 2,
                "2": 0,
                "1": 0
            }
        },
        "recent_ratings": [
            {
                "rating": 5,
                "comment": "Excelente jugador",
                "interaction_context": "trade",
                "rater": {
                    "username": "user456",
                    "avatar_url": "https://cdn.example.com/avatars/456.jpg"
                },
                "created_at": "2024-08-01T15:20:00Z"
            }
        ]
    }
}
```

## Notificaciones

### GET /api/notifications/
Obtener notificaciones del usuario autenticado.

**Headers:** `Authorization: Bearer {access_token}`

**Query Parameters:**
- `unread_only`: Filtrar solo no leídas (default: false)
- `type`: Filtrar por tipo de notificación

**Response 200:**
```json
{
    "success": true,
    "data": {
        "results": [
            {
                "id": 789,
                "type": "new_comment",
                "title": "Nuevo comentario en tu publicación",
                "message": "user456 comentó en tu publicación 'Torneo este sábado'",
                "data": {
                    "post_id": 123,
                    "comment_id": 456,
                    "author_id": 20
                },
                "is_read": false,
                "created_at": "2024-08-04T10:15:00Z"
            }
        ]
    },
    "pagination": {...}
}
```

### PUT /api/notifications/{id}/read/
Marcar notificación como leída.

**Headers:** `Authorization: Bearer {access_token}`

**Response 200:**
```json
{
    "success": true,
    "message": "Notificación marcada como leída"
}
```

### PUT /api/notifications/read-all/
Marcar todas las notificaciones como leídas.

**Headers:** `Authorization: Bearer {access_token}`

**Response 200:**
```json
{
    "success": true,
    "message": "Todas las notificaciones marcadas como leídas"
}
```

## Búsqueda

### GET /api/search/
Búsqueda global en usuarios, comunidades y posts.

**Query Parameters:**
- `q`: Término de búsqueda (required)
- `type`: Tipo de contenido (`users|communities|posts|all`)
- `location_lat`, `location_lng`: Coordenadas para búsqueda geográfica
- `radius`: Radio en km para búsqueda geográfica (max 50)

**Response 200:**
```json
{
    "success": true,
    "data": {
        "users": [
            {
                "id": 1,
                "username": "player123",
                "avatar_url": "...",
                "reputation_score": 4.5,
                "location_name": "Santiago"
            }
        ],
        "communities": [
            {
                "id": 1,
                "name": "Magic: The Gathering Santiago",
                "game_type": "magic",
                "member_count": 1250
            }
        ],
        "posts": [
            {
                "id": 123,
                "title": "Torneo este sábado",
                "community_name": "Magic: The Gathering Santiago",
                "author_username": "player123",
                "created_at": "2024-08-04T09:00:00Z"
            }
        ]
    }
}
```

## Códigos de Error Estándar

### Formato de Error
```json
{
    "success": false,
    "message": "Mensaje general del error",
    "errors": [
        {
            "field": "email",
            "code": "unique",
            "message": "Este email ya está registrado"
        }
    ]
}
```

### Códigos HTTP Principales
- **200 OK**: Operación exitosa
- **201 Created**: Recurso creado exitosamente
- **400 Bad Request**: Error de validación
- **401 Unauthorized**: No autenticado o token inválido
- **403 Forbidden**: No autorizado para esta acción
- **404 Not Found**: Recurso no encontrado
- **429 Too Many Requests**: Rate limit excedido
- **500 Internal Server Error**: Error interno del servidor

## Rate Limiting

### Límites por Endpoint
- **Autenticación**: 5 intentos por minuto por IP
- **Creación de contenido**: 10 posts/comentarios por hora por usuario
- **Búsquedas**: 100 requests por minuto por usuario
- **General**: 1000 requests por hora por usuario autenticado

### Headers de Rate Limiting
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1625097600
```
