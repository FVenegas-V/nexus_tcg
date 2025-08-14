# 📋 Documentación de Modelos - Sistema de Comunidades TCG

## 🏗️ **Arquitectura General**

El sistema de comunidades de Nexus TCG está compuesto por tres modelos principales que manejan la estructura, categorización y membresías de las comunidades de juegos de cartas coleccionables.

### **📊 Diagrama de Relaciones**

```
CommunityCategory (1) -----> (N) Community (1) -----> (N) CommunityMembership (N) <----- (1) User
                                       |
                                       |
                                  (1) created_by
                                       |
                                       v
                                     User
```

---

## 🏷️ **CommunityCategory**

### **Propósito**
Modelo para categorizar comunidades según su enfoque y tipo de actividad (Competitivo, Casual, Trading, etc.).

### **Ubicación**
`backend/communities/models/category.py`

### **Campos**

| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `id` | AutoField | Identificador único | Primary Key |
| `name` | CharField(100) | Nombre de la categoría | UNIQUE, NOT NULL |
| `slug` | SlugField(100) | URL amigable | UNIQUE, auto-generado |
| `description` | TextField | Descripción detallada | Opcional |
| `icon` | CharField(50) | Icono para UI | Opcional |
| `color` | CharField(7) | Color hexadecimal | Formato #RRGGBB |
| `is_active` | BooleanField | Estado activo/inactivo | Default: True |
| `community_count` | PositiveIntegerField | Contador de comunidades | Default: 0 |
| `created_at` | DateTimeField | Fecha de creación | auto_now_add=True |
| `updated_at` | DateTimeField | Última actualización | auto_now=True |

### **Métodos y Propiedades**

```python
def __str__(self):
    """Representación string del objeto."""
    return "{} ({} comunidades)".format(self.name, self.community_count)

def save(self, *args, **kwargs):
    """Override save para generar slug automáticamente."""
    if not self.slug:
        self.slug = slugify(self.name)
    super().save(*args, **kwargs)

@property
def is_popular(self):
    """Determina si la categoría es popular (>10 comunidades)."""
    return self.community_count > 10
```

### **Índices y Constraints**
- **Primary Key:** `id`
- **Unique:** `name`, `slug`
- **Ordering:** `-community_count`, `name`

### **Relaciones**
- **communities:** Relación inversa a `Community.category` (OneToMany)

---

## 🏘️ **Community**

### **Propósito**
Modelo principal que representa una comunidad de TCG con toda su configuración, metadatos y estadísticas.

### **Ubicación**
`backend/communities/models/community.py`

### **Campos**

#### **Información Básica**
| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `id` | AutoField | Identificador único | Primary Key |
| `name` | CharField(200) | Nombre de la comunidad | NOT NULL |
| `slug` | SlugField(200) | URL amigable | UNIQUE, auto-generado |
| `description` | TextField | Descripción completa | NOT NULL |
| `image_url` | URLField | URL de imagen de portada | Opcional, validación URL |

#### **Categorización**
| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `game_type` | CharField(50) | Tipo de juego TCG | NOT NULL, indexed |
| `difficulty_level` | CharField(20) | Nivel de dificultad | Choices: principiante/intermedio/avanzado |
| `category` | ForeignKey | Categoría temática | CASCADE, indexed |

#### **Configuración**
| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `is_public` | BooleanField | Visibilidad pública | Default: True |
| `requires_approval` | BooleanField | Requiere aprobación | Default: False |
| `max_members` | PositiveIntegerField | Límite de miembros | Opcional |

#### **Metadatos**
| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `member_count` | PositiveIntegerField | Contador de miembros | Default: 0 |
| `post_count` | IntegerField | Contador de posts | Default: 0 |
| `tags` | JSONField | Etiquetas flexibles | Default: [] |
| `rules` | TextField | Reglas de la comunidad | Opcional |
| `created_at` | DateTimeField | Fecha de creación | auto_now_add=True |
| `updated_at` | DateTimeField | Última actualización | auto_now=True |
| `created_by` | ForeignKey(User) | Usuario creador | CASCADE, indexed |

### **Métodos y Propiedades**

```python
def __str__(self):
    """Representación string del objeto."""
    return "{} ({} miembros)".format(self.name, self.member_count)

def save(self, *args, **kwargs):
    """Override save para generar slug y validaciones."""
    if not self.slug:
        self.slug = slugify(self.name)
    
    # Validar límite de miembros
    if self.max_members and self.member_count > self.max_members:
        raise ValidationError("El número de miembros no puede exceder el límite")
    
    super().save(*args, **kwargs)

@property
def is_full(self):
    """Determina si la comunidad ha alcanzado su capacidad máxima."""
    if not self.max_members:
        return False
    return self.member_count >= self.max_members

@property
def is_popular(self):
    """Determina si la comunidad es popular (>100 miembros)."""
    return self.member_count >= 100

@property
def member_capacity_percentage(self):
    """Retorna el porcentaje de capacidad usado."""
    if not self.max_members:
        return None
    return (self.member_count / self.max_members) * 100

def get_absolute_url(self):
    """URL canónica de la comunidad."""
    return "/communities/{}/".format(self.slug)
```

### **Índices y Constraints**
- **Primary Key:** `id`
- **Unique:** `slug`
- **Indexes:** `name`, `game_type`, `difficulty_level`, `category_id`, `created_by_id`
- **Ordering:** `-member_count`, `name`

### **Relaciones**
- **category:** ForeignKey a `CommunityCategory`
- **created_by:** ForeignKey a `User`
- **memberships:** Relación inversa a `CommunityMembership` (OneToMany)

### **Validaciones de Negocio**
- El `member_count` no puede exceder `max_members` si está definido
- El `slug` se genera automáticamente del `name` si no se proporciona
- Los `tags` deben ser una lista válida de strings

---

## 👥 **CommunityMembership**

### **Propósito**
Modelo que gestiona la relación entre usuarios y comunidades, incluyendo roles, estados y auditoría de cambios.

### **Ubicación**
`backend/communities/models/membership.py`

### **Campos**

#### **Relaciones Principales**
| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `id` | AutoField | Identificador único | Primary Key |
| `user` | ForeignKey(User) | Usuario miembro | CASCADE, indexed |
| `community` | ForeignKey(Community) | Comunidad | CASCADE, indexed |

#### **Configuración de Membresía**
| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `role` | CharField(20) | Rol del usuario | Choices: member/moderator/admin |
| `status` | CharField(20) | Estado de la membresía | Choices: active/pending/suspended/banned |

#### **Metadatos y Auditoría**
| Campo | Tipo | Descripción | Restricciones |
|-------|------|-------------|---------------|
| `joined_at` | DateTimeField | Fecha de unión | auto_now_add=True |
| `updated_at` | DateTimeField | Última actualización | auto_now=True |
| `notes` | TextField | Notas administrativas | Opcional |
| `invited_by` | ForeignKey(User) | Usuario que invitó | Opcional, CASCADE |

### **Choices Definidos**

#### **ROLE_CHOICES**
```python
ROLE_CHOICES = [
    ('member', 'Miembro'),
    ('moderator', 'Moderador'),
    ('admin', 'Administrador'),
]
```

#### **STATUS_CHOICES**
```python
STATUS_CHOICES = [
    ('active', 'Activo'),
    ('pending', 'Pendiente'),
    ('suspended', 'Suspendido'),
    ('banned', 'Expulsado'),
]
```

### **Métodos y Propiedades**

```python
def __str__(self):
    """Representación string del objeto."""
    return "{} en {} ({})".format(
        self.user.username, 
        self.community.name, 
        self.get_role_display()
    )

def clean(self):
    """Validaciones custom del modelo."""
    # Validar que admin/moderador debe ser activo
    if self.role in ['admin', 'moderator'] and self.status != 'active':
        raise ValidationError(
            "Los administradores y moderadores deben tener status 'active'"
        )
    
    # Validar límite de miembros
    if (self.status == 'active' and 
        self.community.max_members and 
        self.community.member_count >= self.community.max_members):
        if not self.pk:  # Nueva membresía
            raise ValidationError(
                "La comunidad '{}' ha alcanzado su límite de {} miembros".format(
                    self.community.name, self.community.max_members
                )
            )

@property
def is_active(self):
    """Determina si la membresía está activa."""
    return self.status == 'active'

@property
def is_staff(self):
    """Determina si el usuario tiene permisos de staff."""
    return self.role in ['moderator', 'admin']

@property
def can_moderate(self):
    """Determina si puede moderar la comunidad."""
    return self.role in ['moderator', 'admin'] and self.is_active

@property
def can_admin(self):
    """Determina si tiene permisos de administrador."""
    return self.role == 'admin' and self.is_active

def promote_to_moderator(self, promoted_by=None):
    """Promover usuario a moderador."""
    if self.status != 'active':
        raise ValidationError("Solo se puede promover a miembros activos")
    
    self.role = 'moderator'
    if promoted_by:
        self.notes += "\nPromovido a moderador por {} el {}".format(
            promoted_by.username, timezone.now()
        )
    self.save()

def demote_to_member(self, demoted_by=None):
    """Degradar usuario a miembro regular."""
    self.role = 'member'
    if demoted_by:
        self.notes += "\nDegradado a miembro por {} el {}".format(
            demoted_by.username, timezone.now()
        )
    self.save()

def suspend(self, suspended_by=None, reason=""):
    """Suspender membresía."""
    self.status = 'suspended'
    self.role = 'member'  # Remover permisos de staff
    if suspended_by:
        self.notes += "\nSuspendido por {} el {}. Razón: {}".format(
            suspended_by.username, timezone.now(), reason
        )
    self.save()

def reactivate(self, reactivated_by=None):
    """Reactivar membresía suspendida."""
    if self.status == 'banned':
        raise ValidationError("No se puede reactivar un usuario expulsado")
    
    self.status = 'active'
    if reactivated_by:
        self.notes += "\nReactivado por {} el {}".format(
            reactivated_by.username, timezone.now()
        )
    self.save()
```

### **Índices y Constraints**
- **Primary Key:** `id`
- **Unique Together:** `(user, community)`
- **Indexes:** `user_id`, `community_id`, `role`, `status`, `-joined_at`
- **Ordering:** `-joined_at`

### **Relaciones**
- **user:** ForeignKey a `User`
- **community:** ForeignKey a `Community`
- **invited_by:** ForeignKey a `User` (opcional)

### **Validaciones de Negocio**
- Solo puede haber una membresía por usuario-comunidad
- Los administradores y moderadores deben tener status 'active'
- No se puede exceder el límite de miembros de la comunidad
- No se puede reactivar un usuario 'banned'

---

## 🔧 **Configuración de Base de Datos**

### **Migraciones Aplicadas**
- `0001_initial.py`: Creación de tablas, índices y constraints

### **Índices de Performance**
```sql
-- Índices en Community
CREATE INDEX communities_community_name_idx ON communities_community(name);
CREATE INDEX communities_community_game_type_idx ON communities_community(game_type);
CREATE INDEX communities_community_difficulty_level_idx ON communities_community(difficulty_level);
CREATE INDEX communities_community_category_id_idx ON communities_community(category_id);
CREATE INDEX communities_community_created_by_id_idx ON communities_community(created_by_id);

-- Índices en CommunityMembership
CREATE INDEX communities_communitymembership_user_id_idx ON communities_communitymembership(user_id);
CREATE INDEX communities_communitymembership_community_id_idx ON communities_communitymembership(community_id);
CREATE INDEX communities_communitymembership_role_idx ON communities_communitymembership(role);
CREATE INDEX communities_communitymembership_status_idx ON communities_communitymembership(status);
```

### **Constraints de Integridad**
- **Foreign Keys:** Cascada en eliminación para mantener integridad
- **Unique Constraints:** Prevenir duplicados en campos críticos
- **Check Constraints:** Validación de formatos y rangos

---

## 📊 **Casos de Uso Principales**

### **1. Creación de Comunidad**
```python
# Crear nueva comunidad
community = Community.objects.create(
    name="Magic Moderno Competitivo",
    description="Comunidad para jugadores de Modern MTG",
    game_type="Magic: The Gathering",
    difficulty_level="avanzado",
    category=competitive_category,
    created_by=user,
    max_members=100,
    tags=["modern", "competitive", "tournaments"]
)
```

### **2. Unirse a Comunidad**
```python
# Crear membresía
membership = CommunityMembership.objects.create(
    user=current_user,
    community=community,
    role='member',
    status='active' if community.requires_approval else 'pending'
)
```

### **3. Búsqueda de Comunidades**
```python
# Buscar comunidades por filtros
communities = Community.objects.filter(
    game_type='Magic: The Gathering',
    difficulty_level='intermedio',
    is_public=True
).select_related('category', 'created_by')
```

### **4. Gestión de Moderadores**
```python
# Promover a moderador
membership = CommunityMembership.objects.get(user=user, community=community)
membership.promote_to_moderator(promoted_by=admin_user)
```

---

## 🧪 **Testing**

### **Cobertura de Tests**
- **CommunityCategory:** 4 tests (creación, slugs, popularidad, string representation)
- **Community:** 6 tests (creación, capacidad, estadísticas, propiedades)
- **CommunityMembership:** 5+ tests (roles, estados, validaciones, métodos)
- **Integration:** 2 tests (límites, interacciones)

### **Ejecutar Tests**
```bash
cd backend
python manage.py test communities
```

---

## 📚 **Referencias y Documentación Adicional**

- **Django Models:** https://docs.djangoproject.com/en/5.2/topics/db/models/
- **Field Types:** https://docs.djangoproject.com/en/5.2/ref/models/fields/
- **Model Validation:** https://docs.djangoproject.com/en/5.2/ref/models/instances/#validating-objects
- **Database Indexes:** https://docs.djangoproject.com/en/5.2/ref/models/options/#django.db.models.Options.indexes

---

**📝 Documentación generada el 14 de Agosto 2025 - FASE2-0001**
