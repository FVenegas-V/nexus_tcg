# Instrucciones de Documentación


## Persona y Objetivo

Eres un exelente ingenieros en software encargado de discutir y acordar la hoja de ruta de implementación para mi proyecto NexusTCG y documentarla.


## Proyecto

Nexus TCG es una aplicación móvil diseñada para fortalecer y dinamizar las comunidades locales de jugadores de Trading Card Games (TCG). Su objetivo principal es centralizar la interacción entre usuarios, permitiendo: 

- Registro y autenticación de jugadores mediante correo y contraseña, con recuperación de cuenta segura.

- Gestión de perfil: edición de datos personales, avatar y biografía.

- Exploración y suscripción a comunidades temáticas (por juego, región o formato).

- Muro social por comunidad: publicación de texto e imágenes, comentarios y reacciones (me gusta, emojis).

- Sistema de reputación: valoraciones de 1 a 5 estrellas entre usuarios, cómputo de scores y ranking para incentivar la confianza en intercambios.

- Notificaciones push: alertas en tiempo real sobre menciones, nuevos posts en comunidades suscritas y cambios en valoraciones.

- Búsqueda y listado de jugadores y comunidades según criterios (nombre, etiquetas, proximidad geográfica).

-------------------------------------------------------------------------------------------------------------

* Fortalecer la confianza en intercambios

- Cada usuario crea un perfil verificado (email + OTP), donde puede registrar su colección y preferencias de juego.

- El sistema de reputación (valoraciones de 1 a 5 estrellas) se calcula mediante un algoritmo que pondera antigüedad de la valoración y actividad del usuario, evitando calificaciones sesgadas.

* Centralizar la interacción en comunidades temáticas

- Las comunidades se definen por etiquetas: por tipo de juego.

- El usuario puede suscribirse a múltiples comunidades y recibir, vía push, publicaciones nuevas o menciones.

* Publicaciones con contenido multimedia y flujos de interacción

- En el “muro” de cada comunidad, un usuario crea posts con texto,  imágenes (u otros formatos, p. ej. vídeo corto).

- Otros usuarios pueden comentar (texto, emojis) y reaccionar (me gusta, triste, sorprendido).

- Se implementa paginación infinita y cache en frontend para optimizar carga de contenidos.

* Búsqueda avanzada y filtrado

- Filtros por etiquetas, distancia geográfica (hasta 50 km), nivel de reputación mínima y fecha de publicación.

- El endpoint GET /api/communities/?tag={}&region={} soporta consultas compuestas para ayudar a nuevos jugadores a encontrar grupos locales activos.

- Seguridad y escalabilidad de la MVP

* Autenticación basada en JWT con refresco automático de tokens.

- Recuperación de contraseña mediante link seguro con expiración en 15 min.

- Todas las peticiones CRUD (posts, comentarios, valoraciones) pasan por validadores de DRF y permisos basados en rol.

* Administración y métricas

- Panel de administrador web (Django Admin) para gestionar usuarios, moderar contenido y revisar reportes de abuso.


## Stack Tecnológico

- Flutter (Dart)

- Provider / Riverpod

- Dio

- Django 4.x

- Django REST Framework

- Gunicorn

- Nginx

- PostgreSQL

- SQLite

- djangorestframework-simplejwt

- Python-Decouple / django-environ

- Firebase Cloud Messaging

- AWS S3 / Google Cloud Storage

- Docker & Docker Compose

- GitHub Actions

- pytest

- Flutter Test

- Postman

## Documentación


### 1. Especificaciones

Define la arquitectura apropiada según las directrices generales en `/docs/guidelines.md` y desarrolla las especificaciones completas, describe cada sistema necesario y cómo operan juntos, escribe cada especificación en su propio archivo. Esta es una documentación fundamental que será referenciada intensamente, así que hazla valer. Usa el directorio `/docs/specs`.


### 2. Plan

Describe un enfoque paso a paso para lograr este proyecto haciendo referencia a tus especificaciones. Ten en cuenta los requisitos de capas para construir gradualmente el proyecto. Agrupa funcionalidad relacionada o pasos en fases. Este es un documento único con la hoja de ruta general de un vistazo. Guarda esta salida en el archivo `/docs/plan.md`.


### 3. Tickets

Usa el `/docs/ticket-template.md` disponible.

Basado en `/docs/plan.md` y `/docs/specs.md`, crea cada ticket dentro del directorio `/tickets`, usa `/tickets/0000-index.md` como una lista de verificación general para hacer seguimiento del progreso general.

Cada ticket debe:
- tener un ID único (incremental) y pertenecer a una fase
- abordar una unidad única de trabajo
- puede tener más de una tarea para completar los criterios de aceptación
- referenciar las especificaciones correctas para el alcance del ticket actual
- puede referenciar otros tickets según sea necesario