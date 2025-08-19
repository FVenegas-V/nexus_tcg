# 📮 Guía de Pruebas con Postman - FASE2-0005

## 🎯 **Objetivo**
Esta guía te ayudará a probar completamente todas las APIs implementadas en FASE2-0005 usando Postman.

---

## 🚀 **Configuración Inicial**

### **1. Importar la Colección**
1. Abre Postman
2. Haz clic en **"Import"**
3. Selecciona el archivo: `FASE2_0005_Postman_Collection.json`
4. La colección se importará con todas las variables y tests automáticos

### **2. Verificar Variables de Entorno**
- **base_url**: `http://127.0.0.1:8000` (servidor local Django)
- **api_version**: `v1`
- **timestamp**: `{{$timestamp}}` (automático)

### **3. Asegurar que el Servidor está Ejecutándose**
```bash
# En terminal, desde backend/
python manage.py runserver
```
Deberías ver: `Starting development server at http://127.0.0.1:8000/`

---

## 📂 **Estructura de la Colección**

### **🎮 GameType APIs (6 requests)**
1. **📋 Lista todos los GameTypes** - GET `/api/games/`
2. **⭐ GameTypes Destacados** - GET `/api/games/featured/`
3. **🔍 GameTypes con Filtros** - GET `/api/games/?featured=true&ordering=-community_count`
4. **📄 Detalle de GameType específico** - GET `/api/games/1/`
5. **🏘️ Comunidades de un GameType** - GET `/api/games/1/communities/`
6. **📊 Ordenamiento por Año** - GET `/api/games/?ordering=release_year`

### **🏷️ CommunityTag APIs (6 requests)**
1. **📋 Lista todos los Tags** - GET `/api/tags/`
2. **🔥 Tags Populares** - GET `/api/tags/popular/`
3. **🔍 Búsqueda de Tags** - GET `/api/tags/search/?q=comp`
4. **💡 Sugerencias (Autocomplete)** - GET `/api/tags/suggestions/?prefix=tr`
5. **📊 Tags con Uso Mínimo** - GET `/api/tags/?min_usage=1&ordering=-usage_count`
6. **🔤 Búsqueda Vacía** - GET `/api/tags/search/?q=`

### **🧪 Casos de Prueba Específicos (4 requests)**
1. **❌ GameType No Existente** - GET `/api/games/999/` (debe devolver 404)
2. **🔍 Búsqueda Sin Resultados** - GET `/api/tags/search/?q=inexistente123`
3. **📊 Ordenamiento Múltiple** - Ordenamiento complejo
4. **🔢 Paginación Personalizada** - Control de paginación

### **🚀 Tests de Rendimiento (2 requests)**
1. **⚡ Carga Rápida** - GET muchos elementos
2. **🔍 Búsqueda Intensiva** - Búsqueda con letra común

---

## ✅ **Tests Automáticos Incluidos**

Cada request incluye tests automáticos que verifican:

### **Tests Básicos:**
- ✅ Status code es 200 o 404
- ⏱️ Response time menor a 2000ms
- 📋 Content-Type es JSON
- 📊 Response body es JSON válido

### **Logs Automáticos:**
- 🚀 Nombre de la request ejecutada
- 🌐 URL completa
- ⏰ Timestamp de ejecución
- 📊 Status code recibido
- ⏱️ Tiempo de respuesta

---

## 🔄 **Secuencia de Pruebas Recomendada**

### **Paso 1: Verificación Básica**
1. **Lista todos los GameTypes** ➜ Debe devolver 7 games
2. **Lista todos los Tags** ➜ Debe devolver 3 tags iniciales
3. **GameTypes Destacados** ➜ Debe devolver games con `is_featured: true`

### **Paso 2: Pruebas de Detalle**
4. **Detalle GameType ID=1** ➜ Magic: The Gathering completo
5. **Comunidades del Game ID=1** ➜ Lista de comunidades asociadas al game
6. **Tags Populares** ➜ Top tags ordenados por uso

### **Paso 3: Filtros y Búsquedas**
7. **Búsqueda de Tags "comp"** ➜ Debe devolver "competitive"
8. **Sugerencias "tr"** ➜ Debe devolver "trading"
9. **GameTypes con Filtros** ➜ Solo destacados, ordenados

### **Paso 4: Casos Edge**
10. **GameType 999** ➜ Debe devolver 404
11. **Búsqueda inexistente** ➜ Lista vacía
12. **Ordenamiento múltiple** ➜ Verificar orden correcto

### **Paso 5: Rendimiento**
13. **Carga masiva** ➜ Tiempo < 2000ms
14. **Búsqueda intensiva** ➜ Resultados rápidos

---

## 📊 **Resultados Esperados**

### **GameTypes (7 registros esperados):**
```json
{
  "count": 7,
  "results": [
    {
      "id": 1,
      "name": "Magic: The Gathering",
      "slug": "magic-the-gathering",
      "community_count": 1,
      "is_featured": true
    },
    // ... más games
  ]
}
```

### **CommunityTags (3 registros iniciales):**
```json
{
  "count": 3,
  "results": [
    {
      "id": 1,
      "name": "competitive",
      "slug": "competitive",
      "usage_count": 1,
      "color": "#FF5722"
    },
    // ... más tags
  ]
}
```

### **GameType Detalle:**
```json
{
  "id": 1,
  "name": "Magic: The Gathering",
  "description": "El TCG original creado por Richard Garfield",
  "publisher": "Wizards of the Coast",
  "release_year": 1993,
  "min_players": 2,
  "max_players": 8,
  "is_featured": true,
  "community_count": 1,
  "display_info": {
    "age_range": "2-8 jugadores",
    "year_status": "Más de 30 años en el mercado"
  }
}
```

---

## ⚡ **Ejecución Rápida**

### **Opción 1: Runner de Colección**
1. Haz clic derecho en la colección
2. Selecciona **"Run collection"**
3. Ejecuta todas las requests de una vez
4. Revisa el reporte automático

### **Opción 2: Requests Individuales**
1. Expande cada carpeta
2. Ejecuta requests una por una
3. Revisa logs en la consola de Postman
4. Verifica tests en la pestaña "Test Results"

---

## 🐛 **Troubleshooting**

### **❌ Error: Connection refused**
**Problema:** El servidor Django no está ejecutándose
**Solución:** 
```bash
cd backend/
python manage.py runserver
```

### **❌ Error 404 en todas las requests**
**Problema:** URLs no coinciden
**Solución:** Verificar que `base_url` sea `http://127.0.0.1:8000`

### **❌ Error 500 Internal Server Error**
**Problema:** Error en el servidor
**Solución:** Revisar logs del servidor Django y verificar migraciones

### **❌ Response vacío en GameTypes**
**Problema:** No hay datos cargados
**Solución:**
```bash
python manage.py load_game_types
python manage.py update_stats
```

---

## 📈 **Métricas de Éxito**

### **✅ Criterios de Aceptación TOTALMENTE CORREGIDOS:**
- [x] Todas las requests devuelven status 200 (excepto test 404) ✅
- [x] Tiempo de respuesta < 2000ms para todas las requests ✅
- [x] GameTypes: 7 registros cargados ✅
- [x] Tags: 3 registros iniciales ✅
- [x] **GameTypes destacados funcionando** ✅
- [x] **Detalle de GameType funcional** ✅
- [x] **🔧 Comunidades por GameType CORREGIDO** ✅
- [x] **Sugerencias de tags implementadas** ✅
- [x] **Búsqueda vacía corregida** ✅
- [x] **🔧 GameType No Existente (404) CORREGIDO** ✅
- [x] **🔧 Búsqueda Intensiva (letra 'a') CORREGIDA** ✅
- [x] Filtros funcionan correctamente ✅
- [x] Búsquedas devuelven resultados esperados ✅
- [x] Paginación funciona ✅
- [x] Ordenamiento es correcto ✅

### **📊 Benchmarks Esperados:**
- **Lista GameTypes:** ~50-200ms
- **Detalle GameType:** ~30-100ms
- **Búsqueda Tags:** ~100-300ms
- **Filtros complejos:** ~200-500ms

---

## 🎉 **Finalización**

Una vez completadas todas las pruebas exitosamente, tienes la garantía de que:
- ✅ **FASE2-0005 está 100% funcional**
- ✅ **Todas las APIs responden correctamente**
- ✅ **Los filtros y búsquedas funcionan**
- ✅ **El rendimiento es aceptable**
- ✅ **El sistema está listo para producción**

¡Tu sistema de filtros por tipo de juego y categorías está completamente operativo! 🚀
