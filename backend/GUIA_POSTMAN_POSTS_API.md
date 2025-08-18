# 🚀 Guía de Uso - Colección Postman API Posts

## 📋 Descripción
Esta colección de Postman contiene **26 requests** organizadas para probar completamente el sistema de Posts API implementado en la fase3-0002.

## 📁 Estructura de la Colección

### 1. **Autenticación** (1 request)
- `Login - Obtener Token`: Obtiene el token JWT necesario para las demás operaciones

### 2. **Posts - Lectura** (5 requests)
- `Listar Todos los Posts`: Obtiene todos los posts con paginación
- `Feed Personalizado`: Feed basado en comunidades del usuario
- `Mis Posts`: Posts creados por el usuario autenticado
- `Posts por Comunidad`: Filtro específico por comunidad
- `Detalle de Post Específico`: Información completa de un post

### 3. **Posts - Búsqueda y Filtros** (4 requests)
- `Búsqueda por Término`: Búsqueda en título y contenido
- `Filtro por Comunidad`: Filtrado por ID de comunidad
- `Ordenamiento por Fecha`: Ordenación temporal
- `Filtros Combinados`: Múltiples filtros aplicados simultáneamente

### 4. **Posts - Creación y Edición** (2 requests)
- `Crear Nuevo Post`: Creación de posts nuevos
- `Actualizar Post`: Modificación de posts existentes

### 5. **Sistema de Reacciones** (4 requests)
- `Agregar Reacción Like`: Agrega reacción tipo "like"
- `Cambiar a Reacción Love`: Cambia tipo de reacción
- `Quitar Reacción`: Elimina reacción del usuario
- `Ver Todas las Reacciones`: Lista agrupada de reacciones

### 6. **Tests de Estrés** (2 requests)
- `Crear Múltiples Posts`: Prueba de carga para creación
- `Búsqueda Intensiva`: Prueba de rendimiento en búsquedas

## 🔧 Configuración Inicial

### Importar la Colección
1. Abre Postman
2. Click en "Import"
3. Selecciona el archivo `Nexus_TCG_Posts_API_Collection.postman_collection.json`
4. La colección aparecerá en tu sidebar

### Variables de Entorno
La colección incluye variables automáticas:
- `base_url`: http://localhost:8000 (configurado automáticamente)
- `access_token`: Se obtiene automáticamente tras el login
- `refresh_token`: Token de refresco (si necesario)
- `first_post_id`: ID del primer post (para tests)
- `created_post_id`: ID del post creado (para edición)

## 🎯 Cómo Usar la Colección

### Opción 1: Ejecutar Todo Automáticamente
1. Click derecho en la colección "Nexus TCG - Posts API (Fase 3-0002)"
2. Selecciona "Run collection"
3. En el Collection Runner:
   - Asegúrate que todas las requests estén seleccionadas
   - Iterations: 1 (o más para test de estrés)
   - Delay: 100ms entre requests
4. Click "Run Nexus TCG - Posts API"

### Opción 2: Ejecutar Paso a Paso
1. **OBLIGATORIO PRIMERO**: Ejecuta `1. Autenticación > Login - Obtener Token`
2. Una vez autenticado, puedes ejecutar cualquier request en cualquier orden
3. Las variables se configuran automáticamente

### Opción 3: Test de Funcionalidades Específicas
- **Solo lectura**: Ejecuta carpeta "Posts - Lectura"
- **Solo creación**: Ejecuta carpeta "Posts - Creación y Edición"
- **Solo reacciones**: Ejecuta carpeta "Sistema de Reacciones"

## 📊 Tests Automatizados

Cada request incluye tests automáticos que verifican:
- **Status codes correctos** (200, 201, etc.)
- **Estructura de respuesta** (propiedades requeridas)
- **Tipos de datos** (strings, numbers, arrays)
- **Tiempos de respuesta** (< 5 segundos)
- **Content-Type** correcto (application/json)

### Tests Específicos por Funcionalidad:
- **Autenticación**: Verifica que se obtenga el token
- **Lectura**: Valida estructura de paginación y datos
- **Búsqueda**: Confirma filtros y ordenamiento
- **Creación**: Verifica IDs únicos y datos correctos
- **Reacciones**: Valida cambios de estado y conteos
- **Estrés**: Mide tiempos de respuesta bajo carga

## 🔍 Monitoreo y Debugging

### Console Logs
La colección incluye logs automáticos en la consola de Postman:
```javascript
Request a: http://localhost:8000/api/posts/
Response status: 200
Response time: 145ms
```

### Variables Dinámicas
Los tests de estrés usan variables dinámicas de Postman:
- `{{$randomInt}}`: Números aleatorios
- `{{$timestamp}}`: Timestamp actual
- `{{$randomLoremText}}`: Texto aleatorio

## ⚠️ Requisitos Previos

1. **Servidor Django corriendo**: `python manage.py runserver`
2. **Base de datos con datos de prueba**: Ejecutar los scripts de inicialización
3. **Usuario de prueba**: Usuario "gamer1" con password "gamer123"
4. **Comunidades existentes**: Al menos 1-2 comunidades para testing

## 📈 Resultados Esperados

### Ejecución Completa Exitosa:
- ✅ 26 requests ejecutadas
- ✅ ~80+ tests pasados
- ✅ 0 fallos
- ✅ Tiempo total < 30 segundos

### Métricas Típicas:
- **Autenticación**: ~200ms
- **Lectura**: ~150ms
- **Creación**: ~250ms
- **Reacciones**: ~180ms
- **Búsquedas**: ~300ms

## 🐛 Troubleshooting

### Error: "Could not send request"
- Verifica que Django esté corriendo en puerto 8000
- Checa la URL base en las variables

### Error: "401 Unauthorized"
- Ejecuta primero el request de Login
- Verifica que el token no haya expirado

### Error: "400 Bad Request" en creación
- Verifica que exista la comunidad especificada
- Checa que el usuario tenga permisos

### Error: "404 Not Found"
- Verifica que existan posts en la base de datos
- Ejecuta los scripts de datos de prueba

## 🎉 ¡Listo para Usar!

La colección está completamente configurada y lista para probar todo el sistema de Posts API. ¡Ejecuta y disfruta viendo cómo todo funciona perfectamente! 🚀
