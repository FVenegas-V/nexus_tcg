# 📋 README - Modelos de Comunidades

## 🎯 **Visión General**

Este directorio contiene los modelos Django para el sistema de comunidades de Nexus TCG, diseñado para gestionar comunidades de juegos de cartas coleccionables con roles, categorías y membresías.

## 📁 **Estructura**

```
communities/models/
├── __init__.py          # Configuración de importaciones
├── category.py          # CommunityCategory - Categorización
├── community.py         # Community - Modelo principal
└── membership.py        # CommunityMembership - Relaciones usuario-comunidad
```

## 🏗️ **Arquitectura**

### **Relaciones Principales**
- **CommunityCategory** (1) → (N) **Community**
- **Community** (1) → (N) **CommunityMembership** (N) ← (1) **User**
- **User** (1) → (N) **Community** (como created_by)

### **Flujo de Datos**
1. Se crean **categorías** para organizar comunidades
2. Los usuarios crean **comunidades** asignadas a categorías
3. Los usuarios se unen creando **membresías** con roles específicos

## 🚀 **Uso Básico**

### **Importar Modelos**
```python
from communities.models import Community, CommunityCategory, CommunityMembership
```

### **Crear Categoría**
```python
category = CommunityCategory.objects.create(
    name="Competitivo",
    description="Comunidades enfocadas en torneos",
    icon="trophy",
    color="#FFD700"
)
```

### **Crear Comunidad**
```python
community = Community.objects.create(
    name="Magic Pro League",
    description="Comunidad para jugadores profesionales",
    game_type="Magic: The Gathering",
    difficulty_level="avanzado",
    category=category,
    created_by=user,
    max_members=50
)
```

### **Crear Membresía**
```python
membership = CommunityMembership.objects.create(
    user=player,
    community=community,
    role='member',
    status='active'
)
```

## 📊 **Consultas Comunes**

### **Listar Comunidades Populares**
```python
popular_communities = Community.objects.filter(
    member_count__gte=100,
    is_public=True
).select_related('category', 'created_by')
```

### **Obtener Membresías de Usuario**
```python
user_memberships = CommunityMembership.objects.filter(
    user=current_user,
    status='active'
).select_related('community', 'community__category')
```

### **Buscar por Juego**
```python
magic_communities = Community.objects.filter(
    game_type__icontains='Magic',
    is_public=True
).order_by('-member_count')
```

## ⚙️ **Configuración**

### **Settings Requeridos**
```python
INSTALLED_APPS = [
    'communities',
    # ...
]
```

### **URLs (Próximamente)**
```python
# urls.py
urlpatterns = [
    path('api/communities/', include('communities.urls')),
]
```

## 🧪 **Testing**

### **Ejecutar Tests**
```bash
python manage.py test communities
```

### **Coverage Actual**
- ✅ Modelos: 100%
- ✅ Validaciones: 100%
- ✅ Métodos de negocio: 100%

## 📚 **Documentación Completa**

- **📋 Documentación Detallada:** `/docs/models/communities.md`
- **🎯 Especificaciones:** `/docs/specs/02-database-design.md`
- **🎫 Ticket Original:** `/tickets/fase2-0001.md`

## 🔧 **Mantenimiento**

### **Migraciones**
```bash
python manage.py makemigrations communities
python manage.py migrate
```

### **Admin Panel**
Acceder a: http://127.0.0.1:8000/admin/communities/

### **Shell Django**
```bash
python manage.py shell
>>> from communities.models import *
>>> Community.objects.count()
```

## 🚨 **Notas Importantes**

- **Performance:** Los modelos incluyen índices optimizados para consultas frecuentes
- **Integridad:** Constraints de base de datos mantienen consistencia
- **Auditoría:** Todos los cambios de roles son registrados en `notes`
- **Escalabilidad:** Campos desnormalizados (`member_count`) para mejor performance

## 🎯 **Próximos Pasos**

1. **FASE2-0002:** Implementar APIs REST
2. **FASE2-0003:** Sistema CRUD completo
3. **FASE2-0004:** Gestión avanzada de membresías

---

**⚡ Modelos listos para producción - FASE2-0001 ✅**
