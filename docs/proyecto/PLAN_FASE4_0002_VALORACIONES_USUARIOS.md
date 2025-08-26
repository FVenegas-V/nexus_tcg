# 📋 PLAN DE IMPLEMENTACIÓN - FASE4-0002: Sistema de Valoraciones entre Usuarios

## 🎯 **OBJETIVO**
Implementar un sistema completo de valoraciones entre usuarios (1-5 estrellas) con comentarios opcionales, validaciones anti-abuso y tracking de contexto de interacciones.

## 📊 **CONTEXTO Y DEPENDENCIAS**

### ✅ **Prerequisitos Completados**
- **fase4-0001** - Perfiles Públicos ✅ COMPLETADO
- **Fase 1** - Sistema de autenticación ✅ COMPLETADO  
- **Fase 3** - Posts y comentarios ✅ COMPLETADO

### 🔄 **Bloquea a Futuros Tickets**
- **fase4-0003** - Cálculo algorítmico de reputación
- **fase4-0004** - Historial de valoraciones

## 🏗️ **ARQUITECTURA DE IMPLEMENTACIÓN**

### 1. **MODELO DE BASE DE DATOS**
**Archivo:** `backend/users/models.py`

```python
class UserRating(models.Model):
    """Sistema de valoraciones entre usuarios (1-5 estrellas)"""
    
    # Relaciones principales
    rater = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_given')
    rated_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_received')
    
    # Valoración y contexto
    rating = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(max_length=500, blank=True)
    interaction_type = models.CharField(max_length=20, choices=INTERACTION_CHOICES)
    
    # Metadatos y control
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    # Constraints únicos
    class Meta:
        unique_together = ['rater', 'rated_user']
        indexes = [
            models.Index(fields=['rated_user', '-created_at']),
            models.Index(fields=['rater', '-created_at']),
        ]
```

### 2. **SERIALIZERS ESPECIALIZADOS**
**Archivo:** `backend/users/serializers.py`

```python
class UserRatingSerializer(serializers.ModelSerializer):
    """Serializer principal para valoraciones"""
    rater_info = UserBasicSerializer(source='rater', read_only=True)
    rated_user_info = UserBasicSerializer(source='rated_user', read_only=True)
    
class UserRatingCreateSerializer(serializers.ModelSerializer):
    """Serializer para crear/actualizar valoraciones"""
    
class UserRatingStatsSerializer(serializers.Serializer):
    """Serializer para estadísticas agregadas"""
    average_rating = serializers.FloatField()
    total_ratings = serializers.IntegerField()
    rating_distribution = serializers.DictField()
```

### 3. **VIEWSET CON ENDPOINTS ESPECIALIZADOS**
**Archivo:** `backend/users/views.py`

```python
class UserRatingViewSet(viewsets.ModelViewSet):
    """
    ViewSet para sistema de valoraciones entre usuarios
    
    Endpoints:
    - POST /api/ratings/rate-user/{user_id}/ - Crear/actualizar valoración
    - GET /api/ratings/received/{user_id}/ - Ver valoraciones recibidas
    - GET /api/ratings/my-ratings/ - Mis valoraciones dadas
    - DELETE /api/ratings/{rating_id}/ - Eliminar valoración (soft delete)
    - GET /api/ratings/stats/{user_id}/ - Estadísticas de valoraciones
    """
    
    @action(detail=True, methods=['post'])
    def rate_user(self, request, pk=None):
        """Valorar a un usuario específico"""
        
    @action(detail=True, methods=['get'])
    def received_ratings(self, request, pk=None):
        """Ver valoraciones recibidas por un usuario"""
        
    @action(detail=False, methods=['get'])
    def my_ratings(self, request):
        """Mis valoraciones dadas"""
        
    @action(detail=True, methods=['get'])
    def stats(self, request, pk=None):
        """Estadísticas agregadas de valoraciones"""
```

### 4. **VALIDACIONES DE NEGOCIO**

#### 🛡️ **Anti-Abuse Measures**
- **Auto-valoración:** Usuario no puede valorarse a sí mismo
- **Duplicados:** Solo una valoración por par de usuarios (unique_together)
- **Rate Limiting:** Máximo 5 valoraciones por día
- **Rango válido:** Solo 1-5 estrellas
- **Comentarios:** Filtro básico de contenido inapropiado

#### 📊 **Contexto de Interacciones**
```python
INTERACTION_CHOICES = [
    ('post_interaction', 'Interacción en Post'),
    ('comment_interaction', 'Interacción en Comentario'), 
    ('community_interaction', 'Interacción en Comunidad'),
    ('direct_interaction', 'Interacción Directa'),
]
```

### 5. **SISTEMA DE PERMISOS**
**Archivo:** `backend/users/permissions.py`

```python
class RatingPermission(permissions.BasePermission):
    """Permisos específicos para sistema de valoraciones"""
    
    def has_permission(self, request, view):
        # Solo usuarios autenticados pueden valorar
        
    def has_object_permission(self, request, view, obj):
        # Solo el autor puede modificar/eliminar su valoración
```

## 📋 **PLAN DE EJECUCIÓN PASO A PASO**

### **FASE 1: MODELO Y MIGRACIÓN (30 min)**
1. ✅ Crear modelo `UserRating` en `users/models.py`
2. ✅ Generar y aplicar migración
3. ✅ Actualizar admin.py para gestión

### **FASE 2: SERIALIZERS (20 min)**
4. ✅ Crear `UserRatingSerializer` 
5. ✅ Crear `UserRatingCreateSerializer`
6. ✅ Crear `UserRatingStatsSerializer`

### **FASE 3: VIEWSET Y ENDPOINTS (45 min)**
7. ✅ Implementar `UserRatingViewSet`
8. ✅ Action `rate_user` - Crear/actualizar valoración
9. ✅ Action `received_ratings` - Ver valoraciones recibidas
10. ✅ Action `my_ratings` - Mis valoraciones dadas
11. ✅ Action `stats` - Estadísticas agregadas

### **FASE 4: VALIDACIONES Y PERMISOS (25 min)**
12. ✅ Crear `RatingPermission`
13. ✅ Implementar validaciones de negocio
14. ✅ Rate limiting básico

### **FASE 5: RUTAS Y CONFIGURACIÓN (15 min)**
15. ✅ Configurar URLs en `users/urls.py`
16. ✅ Registrar router en URLs principales

### **FASE 6: TESTING COMPLETO (30 min)**
17. ✅ Tests unitarios del modelo
18. ✅ Tests de API endpoints
19. ✅ Tests de validaciones y edge cases
20. ✅ Tests de permisos

### **FASE 7: OPTIMIZACIONES (20 min)**
21. ✅ Índices de base de datos
22. ✅ Paginación optimizada
23. ✅ Queries de estadísticas eficientes

## 🎯 **ENDPOINTS RESULTANTES**

```bash
# Valorar a un usuario
POST /api/ratings/rate-user/{user_id}/
{
    "rating": 4,
    "comment": "Excelente jugador, muy respetuoso",
    "interaction_type": "community_interaction"
}

# Ver valoraciones recibidas
GET /api/ratings/received/{user_id}/?page=1&page_size=10

# Mis valoraciones dadas
GET /api/ratings/my-ratings/?page=1&page_size=10

# Estadísticas de un usuario
GET /api/ratings/stats/{user_id}/

# Eliminar mi valoración
DELETE /api/ratings/{rating_id}/
```

## 📊 **ESTRUCTURA DE RESPUESTAS**

### **Valoración Individual**
```json
{
    "id": 1,
    "rating": 4,
    "comment": "Excelente jugador",
    "interaction_type": "community_interaction",
    "created_at": "2025-08-25T23:00:00Z",
    "updated_at": "2025-08-25T23:00:00Z",
    "rater_info": {
        "id": 1,
        "username": "player1",
        "avatar_url": "..."
    },
    "rated_user_info": {
        "id": 2,
        "username": "player2", 
        "avatar_url": "..."
    }
}
```

### **Estadísticas Agregadas**
```json
{
    "average_rating": 4.3,
    "total_ratings": 15,
    "rating_distribution": {
        "1": 0,
        "2": 1,
        "3": 2,
        "4": 7,
        "5": 5
    },
    "recent_ratings": [...] // Últimas 5 valoraciones
}
```

## 🛡️ **MEDIDAS DE SEGURIDAD**

### **Validaciones Backend**
- Rate limiting: 5 valoraciones/día máximo
- Anti auto-valoración
- Validación de rango 1-5 estrellas
- Sanitización de comentarios

### **Permisos**
- Solo usuarios autenticados pueden valorar
- Solo el autor puede modificar su valoración
- Soft delete para mantener integridad

## ⚡ **OPTIMIZACIONES DE PERFORMANCE**

### **Base de Datos**
- Índices en `rated_user + created_at` 
- Índices en `rater + created_at`
- Unique constraint para prevenir duplicados

### **Queries**
- Paginación obligatoria (max 20 items)
- Select_related para datos de usuarios
- Agregación eficiente para estadísticas

### **Caching (Futuro)**
- Cache de estadísticas agregadas
- Cache de valoraciones recientes

## 🧪 **PLAN DE TESTING**

### **Tests Unitarios**
- Modelo UserRating: validaciones, constraints
- Serializers: datos válidos/inválidos
- Permisos: casos de acceso permitido/denegado

### **Tests de API**
- CRUD completo de valoraciones
- Validaciones de negocio
- Rate limiting
- Paginación y filtros

### **Tests de Integración**
- Flujo completo de valoración
- Actualización de estadísticas
- Soft delete functionality

## 📈 **MÉTRICAS DE ÉXITO**

### **Funcionalidad**
- ✅ Todos los endpoints responden <300ms
- ✅ Validaciones previenen abuse 100%
- ✅ Cobertura de tests >90%

### **Datos**
- ✅ Constraint unique_together funciona
- ✅ Índices mejoran consultas 
- ✅ Soft delete mantiene integridad

## 🔄 **ITERACIÓN Y MEJORAS FUTURAS**

### **Fase 4.1 (Post-MVP)**
- Sistema de reportes de valoraciones
- Algoritmo de detección de valoraciones falsas
- Moderación automática de comentarios

### **Fase 4.2 (Avanzado)**
- Valoraciones contextuales (intercambios, torneos)
- Sistema de badges por valoraciones altas
- Analytics de tendencias de valoraciones

---

**⏱️ Tiempo Estimado Total:** 3 horas  
**🎯 Complejidad:** Media-Alta  
**📊 Prioridad:** Alta (Prerrequisito para reputación)  
**🔗 Dependencias:** fase4-0001 (Completado ✅)  
