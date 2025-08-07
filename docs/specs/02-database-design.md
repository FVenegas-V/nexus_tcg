# Especificación de Diseño de Base de Datos - Nexus TCG

## Introducción

El diseño de base de datos para Nexus TCG está optimizado para soportar las funcionalidades core de comunidades TCG, sistema de reputación y interacciones sociales, manteniendo integridad referencial y performance.

## Modelo de Datos Conceptual

### Entidades Principales

1. **Users** - Jugadores registrados
2. **Communities** - Comunidades temáticas de TCG
3. **Posts** - Publicaciones en comunidades
4. **Comments** - Comentarios en publicaciones
5. **Reactions** - Reacciones (likes, emojis)
6. **Ratings** - Valoraciones entre usuarios
7. **Notifications** - Notificaciones push
8. **Subscriptions** - Suscripciones a comunidades

## Esquema Detallado

### Tabla: users
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(30) UNIQUE NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    password_hash VARCHAR(128) NOT NULL,
    first_name VARCHAR(30),
    last_name VARCHAR(30),
    avatar_url VARCHAR(500),
    bio TEXT,
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    location_name VARCHAR(100),
    reputation_score DECIMAL(3, 2) DEFAULT 0.00,
    reputation_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    date_joined TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    
    -- Índices
    INDEX idx_users_username (username),
    INDEX idx_users_email (email),
    INDEX idx_users_location (location_lat, location_lng),
    INDEX idx_users_reputation (reputation_score DESC)
);
```

### Tabla: communities
```sql
CREATE TABLE communities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    game_type VARCHAR(50) NOT NULL, -- 'magic', 'pokemon', 'yugioh', etc.
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    member_count INTEGER DEFAULT 0,
    post_count INTEGER DEFAULT 0,
    
    -- Índices
    INDEX idx_communities_game_type (game_type),
    INDEX idx_communities_member_count (member_count DESC),
    INDEX idx_communities_created_at (created_at DESC)
);
```

### Tabla: community_subscriptions
```sql
CREATE TABLE community_subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notifications_enabled BOOLEAN DEFAULT TRUE,
    
    -- Constraints
    UNIQUE(user_id, community_id),
    
    -- Índices
    INDEX idx_subscriptions_user (user_id),
    INDEX idx_subscriptions_community (community_id),
    INDEX idx_subscriptions_date (subscribed_at DESC)
);
```

### Tabla: posts
```sql
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    community_id INTEGER NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
    title VARCHAR(200),
    content TEXT NOT NULL,
    image_urls TEXT[], -- Array de URLs de imágenes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    comment_count INTEGER DEFAULT 0,
    reaction_count INTEGER DEFAULT 0,
    
    -- Índices
    INDEX idx_posts_author (author_id),
    INDEX idx_posts_community (community_id),
    INDEX idx_posts_created_at (created_at DESC),
    INDEX idx_posts_community_date (community_id, created_at DESC),
    INDEX idx_posts_active (is_active, created_at DESC)
);
```

### Tabla: comments
```sql
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    author_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    reaction_count INTEGER DEFAULT 0,
    
    -- Índices
    INDEX idx_comments_post (post_id, created_at),
    INDEX idx_comments_author (author_id),
    INDEX idx_comments_created_at (created_at DESC)
);
```

### Tabla: reactions
```sql
CREATE TABLE reactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(10) NOT NULL, -- 'post' or 'comment'
    object_id INTEGER NOT NULL, -- ID del post o comment
    reaction_type VARCHAR(20) NOT NULL, -- 'like', 'love', 'laugh', 'sad', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(user_id, content_type, object_id),
    CHECK (content_type IN ('post', 'comment')),
    CHECK (reaction_type IN ('like', 'love', 'laugh', 'wow', 'sad', 'angry')),
    
    -- Índices
    INDEX idx_reactions_content (content_type, object_id),
    INDEX idx_reactions_user (user_id),
    INDEX idx_reactions_type (reaction_type)
);
```

### Tabla: user_ratings
```sql
CREATE TABLE user_ratings (
    id SERIAL PRIMARY KEY,
    rater_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rated_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    interaction_context VARCHAR(100), -- 'trade', 'game', 'event', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Constraints
    UNIQUE(rater_id, rated_id),
    CHECK (rater_id != rated_id), -- No auto-rating
    
    -- Índices
    INDEX idx_ratings_rated (rated_id, is_active),
    INDEX idx_ratings_rater (rater_id),
    INDEX idx_ratings_created_at (created_at DESC)
);
```

### Tabla: notifications
```sql
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(30) NOT NULL, -- 'new_post', 'new_comment', 'rating', 'mention'
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    data JSONB, -- Datos adicionales (IDs relacionados, etc.)
    is_read BOOLEAN DEFAULT FALSE,
    is_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CHECK (type IN ('new_post', 'new_comment', 'rating', 'mention', 'subscription')),
    
    -- Índices
    INDEX idx_notifications_user (user_id, is_read, created_at DESC),
    INDEX idx_notifications_type (type),
    INDEX idx_notifications_pending (is_sent, created_at) WHERE NOT is_sent
);
```

### Tabla: login_attempts
```sql
CREATE TABLE login_attempts (
    id SERIAL PRIMARY KEY,
    username VARCHAR(30),
    ip_address INET NOT NULL,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Índices
    INDEX idx_login_attempts_ip (ip_address, attempted_at DESC),
    INDEX idx_login_attempts_username (username, attempted_at DESC),
    INDEX idx_login_attempts_failed (success, attempted_at DESC) WHERE NOT success
);
```

## Triggers y Funciones

### Actualización Automática de Contadores

```sql
-- Trigger para actualizar post_count en communities
CREATE OR REPLACE FUNCTION update_community_post_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE communities 
        SET post_count = post_count + 1 
        WHERE id = NEW.community_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE communities 
        SET post_count = post_count - 1 
        WHERE id = OLD.community_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_community_post_count
    AFTER INSERT OR DELETE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_community_post_count();
```

### Cálculo de Reputación

```sql
-- Función para recalcular reputación de usuario
CREATE OR REPLACE FUNCTION calculate_user_reputation(user_id INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET reputation_score = (
        SELECT COALESCE(AVG(rating), 0.0)
        FROM user_ratings 
        WHERE rated_id = user_id AND is_active = TRUE
    ),
    reputation_count = (
        SELECT COUNT(*)
        FROM user_ratings 
        WHERE rated_id = user_id AND is_active = TRUE
    )
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;
```

## Índices de Performance

### Búsquedas Geográficas
```sql
-- Índice espacial para búsquedas por proximidad
CREATE INDEX idx_users_location_gist 
ON users USING GIST(ST_Point(location_lng, location_lat));
```

### Búsquedas de Texto
```sql
-- Índices para búsqueda full-text
CREATE INDEX idx_posts_content_gin 
ON posts USING GIN(to_tsvector('spanish', content));

CREATE INDEX idx_communities_search_gin 
ON communities USING GIN(to_tsvector('spanish', name || ' ' || description));
```

## Estrategia de Particionamiento

### Posts por Fecha (Para Escalabilidad Futura)
```sql
-- Tabla particionada por año/mes para posts
CREATE TABLE posts_partitioned (
    LIKE posts INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- Particiones por mes
CREATE TABLE posts_2024_01 PARTITION OF posts_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

## Migraciones y Versionado

### Estrategia de Migraciones
1. **Schema migrations**: Django migrations para cambios de estructura
2. **Data migrations**: Scripts SQL para transformaciones de datos
3. **Rollback strategy**: Siempre incluir migration reversa
4. **Testing**: Todas las migraciones probadas en staging

### Backup y Restauración
- **Backup diario**: pg_dump con compresión
- **Point-in-time recovery**: WAL archiving habilitado
- **Replica lectura**: Para queries pesadas y reporting

## Consideraciones de Seguridad

### Protección de Datos
- **Encriptación**: Passwords con bcrypt
- **PII Protection**: Datos sensibles encriptados en columnas específicas
- **Audit Trail**: Registro de cambios críticos
- **Data Retention**: Políticas de eliminación de datos antiguos

### Performance y Optimización
- **Connection Pooling**: pgBouncer para gestión de conexiones
- **Query Monitoring**: pg_stat_statements habilitado
- **Slow Query Alerts**: Monitoreo de queries > 1s
- **Index Monitoring**: Análisis regular de usage de índices
