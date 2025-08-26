# Sistema de Reputación - Nexus TCG

## Introducción

El sistema de reputación de Nexus TCG permite a los usuarios valorar sus interacciones y construir una reputación basada en múltiples factores algoritmos inteligentes.

## Arquitectura del Sistema

### Componentes Principales

1. **Modelo UserRating**: Almacena las valoraciones entre usuarios (1-5 estrellas)
2. **Algoritmo de Reputación**: Calcula puntuaciones basadas en 5 factores
3. **Sistema de Tareas**: Procesamiento asíncrono con Celery
4. **API Endpoints**: Consulta de estadísticas y detalles
5. **Management Commands**: Herramientas de administración

### Algoritmo de Reputación

El algoritmo utiliza 5 factores principales:

#### 1. Puntuación Base
- Promedio ponderado de las valoraciones recibidas (1-5 estrellas)

#### 2. Peso Temporal (Decay Lineal)
- Las valoraciones más recientes tienen mayor peso
- Configuración: 365 días para llegar al peso mínimo (10%)
- Fórmula: `max(0.1, 1 - (días_transcurridos / 365))`

#### 3. Credibilidad del Evaluador
- Usuarios con mayor reputación tienen más influencia
- Multiplicador entre 0.5x y 2.0x
- Basado en la reputación del usuario que evalúa

#### 4. Factor de Confianza Estadística
- Mayor confianza con más valoraciones
- Configuración: 10 valoraciones para confianza máxima
- Fórmula: `min(1.0, cantidad_valoraciones / 10)`

#### 5. Normalización
- Resultado final redondeado a 2 decimales
- Rango: 0.00 - 5.00

### Configuración

```python
# En settings.py
REPUTATION_SETTINGS = {
    'DECAY_PERIOD_DAYS': 365,       # Período de decay temporal
    'MIN_TEMPORAL_WEIGHT': 0.1,     # Peso mínimo temporal
    'CONFIDENCE_THRESHOLD': 10,     # Valoraciones para confianza máxima
    'MAX_RATER_MULTIPLIER': 2.0,    # Multiplicador máximo por credibilidad
    'MIN_RATER_MULTIPLIER': 0.5,    # Multiplicador mínimo por credibilidad
}
```

## Uso del Sistema

### Crear una Valoración

```python
from users.models import UserRating

rating = UserRating.objects.create(
    rater=usuario_evaluador,
    rated_user=usuario_evaluado,
    rating=4,  # 1-5 estrellas
    comment="Excelente intercambio de cartas",
    interaction_type='trade'
)
```

### Calcular Reputación

```python
from users.reputation import calculate_user_reputation

score, count = calculate_user_reputation(usuario)
print(f"Reputación: {score} basada en {count} valoraciones")
```

### Obtener Desglose Detallado

```python
from users.reputation import get_reputation_breakdown

breakdown = get_reputation_breakdown(usuario)
print(f"Puntuación final: {breakdown['final_score']}")
print(f"Factores del algoritmo: {breakdown['algorithm_factors']}")
```

## API Endpoints

### 1. Estadísticas Generales
```
GET /api/users/reputation/stats/
```

Respuesta:
```json
{
    "total_users": 1250,
    "users_with_reputation": 890,
    "users_with_ratings": 456,
    "average_reputation": 3.45,
    "max_reputation": 4.87,
    "min_reputation": 0.12
}
```

### 2. Reputación de Usuario
```
GET /api/users/reputation/user/{user_id}/
```

Respuesta:
```json
{
    "user_id": 123,
    "username": "jugador_pro",
    "reputation_score": 4.25,
    "reputation_count": 15
}
```

### 3. Desglose Detallado
```
GET /api/users/reputation/breakdown/{user_id}/
```

Respuesta:
```json
{
    "final_score": 4.25,
    "total_ratings": 15,
    "ratings_data": [
        {
            "rater": "usuario1",
            "score": 5,
            "temporal_weight": 0.95,
            "rater_credibility": 1.2,
            "weighted_contribution": 5.7
        }
    ],
    "algorithm_factors": {
        "base_score": 4.3,
        "confidence_factor": 0.98,
        "evaluator_avg_credibility": 1.15
    }
}
```

## Management Commands

### Recalcular Reputaciones
```bash
# Todos los usuarios
python manage.py manage_reputation recalculate --force

# Usuario específico
python manage.py manage_reputation update --user username

# Solo simulación
python manage.py manage_reputation recalculate --dry-run
```

### Validar Consistencia
```bash
# Validación sincrónica
python manage.py manage_reputation validate --verbose

# Validación asíncrona
python manage.py manage_reputation async-validate
```

### Estadísticas del Sistema
```bash
python manage.py manage_reputation stats
```

### Desglose de Usuario
```bash
python manage.py manage_reputation breakdown --user username
```

## Tareas Asíncronas (Celery)

### Configuración de Celery

```python
# En settings.py
CELERY_BROKER_URL = 'redis://localhost:6379/0'
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'
```

### Tareas Disponibles

1. **update_user_reputation_task**: Actualiza reputación individual
2. **bulk_update_reputations_task**: Actualización masiva en lotes
3. **recalculate_all_reputations_task**: Recalculo completo del sistema
4. **validate_reputation_consistency_task**: Validación de consistencia

### Ejecutar Worker
```bash
celery -A nexus_api worker --loglevel=info
```

## Signals Automáticos

El sistema incluye signals que actualizan automáticamente las reputaciones:

```python
# Cuando se crea/actualiza una valoración
@receiver(post_save, sender=UserRating)
def update_reputation_on_rating_save(sender, instance, created, **kwargs):
    # Lanza tarea asíncrona de actualización
    update_user_reputation_task.delay(instance.rated_user.id)

# Cuando se elimina una valoración
@receiver(pre_delete, sender=UserRating)
def update_reputation_on_rating_delete(sender, instance, **kwargs):
    # Programa actualización después de la eliminación
    update_user_reputation_task.delay(instance.rated_user.id)
```

## Testing

### Tests Unitarios
```bash
# Ejecutar todos los tests de reputación
python manage.py test users.tests.test_reputation

# Test específico
python manage.py test users.tests.test_reputation.ReputationCalculationTests.test_single_rating
```

### Tests de API
```bash
# Tests de endpoints
python manage.py test users.tests.test_reputation.ReputationAPITests
```

## Monitoreo y Logs

### Configuración de Logging
```python
LOGGING = {
    'loggers': {
        'users.reputation': {
            'handlers': ['file'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
```

### Métricas Importantes

1. **Tiempo de cálculo**: Debe ser < 100ms por usuario
2. **Consistencia**: Validación periódica sin inconsistencias
3. **Throughput**: Capacidad de procesamiento de valoraciones/segundo

## Consideraciones de Rendimiento

### Optimizaciones Implementadas

1. **Índices de Base de Datos**: En campos críticos de consulta
2. **Select Related**: Para evitar N+1 queries
3. **Procesamiento Asíncrono**: Para operaciones costosas
4. **Caché de Resultados**: En endpoints de alta frecuencia

### Límites Recomendados

- **Valoraciones por usuario**: Sin límite técnico
- **Recálculo completo**: Máximo 1 vez por día
- **Validación de consistencia**: Semanal

## Troubleshooting

### Problemas Comunes

#### 1. Reputaciones Inconsistentes
```bash
python manage.py manage_reputation validate
python manage.py manage_reputation recalculate --force
```

#### 2. Celery No Disponible
El sistema automáticamente cambia a procesamiento síncrono.

#### 3. Performance Lenta
- Verificar índices de base de datos
- Optimizar configuración de Celery
- Revisar logs de queries lentas

### Logs de Error

```python
# Configurar logging detallado
import logging
logging.getLogger('users.reputation').setLevel(logging.DEBUG)
```

## Roadmap Futuro

### Versión 2.0 (Planificada)

1. **Machine Learning**: Detección de patterns de valoraciones falsas
2. **Reputación por Categoría**: Diferentes reputaciones por tipo de actividad
3. **Gamificación**: Badges y logros basados en reputación
4. **API GraphQL**: Consultas más flexibles
5. **Cache Distribuido**: Redis para alta escala

### Mejoras de Performance

1. **Materialized Views**: Para consultas complejas
2. **Read Replicas**: Separación de lectura/escritura
3. **Sharding**: Distribución horizontal de datos

## Seguridad

### Protecciones Implementadas

1. **Anti-Gaming**: Un usuario solo puede valorar a otro una vez
2. **Validación de Entrada**: Rango 1-5 estrellas obligatorio
3. **Soft Delete**: Las valoraciones se marcan como inactivas
4. **Auditoría**: Logs completos de todas las operaciones

### Consideraciones Adicionales

- Monitoreo de patrones sospechosos
- Rate limiting en endpoints públicos
- Validación de permisos en operaciones sensibles

---

**Documentación generada para Nexus TCG - Sistema de Reputación v1.0**
*Última actualización: Agosto 2025*
