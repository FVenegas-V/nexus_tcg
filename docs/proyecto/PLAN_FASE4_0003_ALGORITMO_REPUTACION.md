# PLAN FASE 4.3 - ALGORITMO DE CÁLCULO DE REPUTACIÓN

**Fecha de creación:** 25 de agosto de 2025  
**Ticket:** fase4-0003.md - Algoritmo de Cálculo de Reputación  
**Estimación:** 4-5 horas  
**Prioridad:** Alta

## 🎯 OBJETIVOS PRINCIPALES

Implementar un algoritmo inteligente y escalable para calcular la reputación de usuarios basado en valoraciones recibidas, considerando múltiples factores para generar un score justo y resistente a manipulación.

## 📋 CRITERIOS DE ACEPTACIÓN DETALLADOS

### ✅ Funcionalidades Core
- [ ] **Algoritmo Core**: Función `calculate_user_reputation()` con 5 factores
- [ ] **Peso Temporal**: Decay lineal configurable (365 días)
- [ ] **Credibilidad del Evaluador**: Peso basado en reputación del valorador
- [ ] **Volumen de Valoraciones**: Manejo escalable de 1 a 1000+ valoraciones
- [ ] **Confianza Estadística**: Factor de confianza basado en número de valoraciones

### ✅ Automatización y Performance
- [ ] **Actualización Automática**: Signals Django para actualización en tiempo real
- [ ] **Task en Background**: Celery task para recálculos masivos
- [ ] **Comando de Recálculo**: Management command para recálculo masivo
- [ ] **Performance**: Cálculo individual <100ms

### ✅ Datos y APIs
- [ ] **Campos en User**: `reputation_score` y `reputation_count` automáticos
- [ ] **API de Estadísticas**: Endpoint GET `/api/users/{id}/reputation-stats/`
- [ ] **Logging Completo**: Auditoría de cambios de reputación

### ✅ Testing y Calidad
- [ ] **Testing**: Tests unitarios con múltiples escenarios y edge cases
- [ ] **Tests de Performance**: Validación con volúmenes grandes
- [ ] **Tests de Integración**: Signals y tasks de Celery

## 🏗️ ARQUITECTURA DE LA SOLUCIÓN

### Componentes Principales

1. **Algoritmo de Cálculo** (`users/reputation.py`)
2. **Signals de Actualización** (`users/signals.py`) 
3. **Celery Tasks** (`users/tasks.py`)
4. **Management Command** (`users/management/commands/`)
5. **API Endpoints** (`users/views.py` y `users/serializers.py`)
6. **Testing Suite** (`users/tests_reputation.py`)

### Flujo de Datos

```
Valoración Creada/Modificada 
    ↓
Signal Triggered
    ↓
Celery Task Encolada
    ↓
Algoritmo Ejecutado
    ↓
User.reputation_score Actualizado
    ↓
Log de Cambio Generado
```

## 📊 ALGORITMO DETALLADO

### Factores Considerados (con Decay Lineal)

```python
def calculate_user_reputation(user):
    """
    Algoritmo de reputación con 5 factores:
    1. Score base (1-5)
    2. Decay temporal lineal (365 días)
    3. Credibilidad del evaluador (0.5x - 2.0x)
    4. Volumen total (confianza estadística)
    5. Distribución (anti-manipulación)
    """
    
    # Configuración MVP
    DECAY_DAYS = 365
    MIN_WEIGHT = 0.1
    CONFIDENCE_THRESHOLD = 10
    MAX_RATER_MULTIPLIER = 2.0
    MIN_RATER_MULTIPLIER = 0.5
```

### Parámetros de Configuración MVP

- **Decay temporal**: 365 días para llegar al peso mínimo (0.1)
- **Peso máximo evaluador**: 2.0x para usuarios con reputación 5.0
- **Confianza estadística**: 10 valoraciones para confianza máxima
- **Peso mínimo evaluador**: 0.5x para usuarios con baja reputación

## 🗂️ PLAN DE IMPLEMENTACIÓN

### **FASE 1: Modelo y Migraciones (30 min)**
1. Agregar campos `reputation_score` y `reputation_count` al modelo User
2. Crear migración para los nuevos campos
3. Aplicar migración y verificar integridad

### **FASE 2: Algoritmo Core (90 min)**
1. Crear módulo `users/reputation.py`
2. Implementar función `calculate_user_reputation()`
3. Implementar función `get_reputation_breakdown()` para debugging
4. Crear configuración centralizada de parámetros

### **FASE 3: Signals y Tasks (60 min)**
1. Crear signals para actualización automática
2. Implementar Celery task `update_user_reputation_task`
3. Manejar casos edge (usuario no existe, errores)
4. Implementar logging de cambios

### **FASE 4: Management Command (45 min)**
1. Crear comando `recalculate_reputations`
2. Implementar modo síncrono y asíncrono
3. Agregar opciones de batch size y filtrado
4. Incluir progreso y estadísticas

### **FASE 5: API Endpoints (60 min)**
1. Crear serializers para estadísticas de reputación
2. Implementar endpoint `reputation-stats`
3. Optimizar consultas con select_related/prefetch_related
4. Agregar validaciones y permisos

### **FASE 6: Testing Comprehensivo (90 min)**
1. Tests unitarios del algoritmo
2. Tests de signals y tasks
3. Tests de performance con volúmenes grandes
4. Tests de edge cases y validaciones

### **FASE 7: Integración y Documentación (45 min)**
1. Actualizar sistema de valoraciones para usar nuevos campos
2. Documentar parámetros configurables
3. Crear guía de troubleshooting
4. Validar integración end-to-end

## 📈 MÉTRICAS DE ÉXITO

### Performance
- [ ] Cálculo individual < 100ms (target: 50ms)
- [ ] Recálculo masivo sin impacto en API response times
- [ ] Memory usage < 100MB para 10,000 usuarios

### Funcionalidad
- [ ] 100% de valoraciones reflejadas en reputation_score
- [ ] Signals funcionando en tiempo real
- [ ] Celery tasks procesando sin errores

### Calidad
- [ ] Cobertura de tests > 95%
- [ ] Cero errores en logs durante testing
- [ ] Validación con datos reales exitosa

## 🔧 CONFIGURACIÓN TÉCNICA

### Settings Django
```python
# Parámetros del algoritmo de reputación
REPUTATION_SETTINGS = {
    'DECAY_PERIOD_DAYS': 365,
    'MIN_TEMPORAL_WEIGHT': 0.1,
    'CONFIDENCE_THRESHOLD': 10,
    'MAX_RATER_MULTIPLIER': 2.0,
    'MIN_RATER_MULTIPLIER': 0.5,
}
```

### Celery Configuration
```python
# Task routing para reputación
CELERY_TASK_ROUTES = {
    'users.tasks.update_user_reputation_task': {'queue': 'reputation'},
}
```

## 🚀 DEPENDENCIAS Y PREREQUISITOS

### ✅ Completado
- [x] Sistema de valoraciones (fase4-0002)
- [x] Celery configurado en proyecto
- [x] Django signals framework

### 🔄 En Progreso
- [ ] Algoritmo de reputación (este ticket)

### ⏳ Bloqueado
- Dashboard de reputación (fase4-0005)
- Filtrado por reputación (fase6)

## 📝 NOTAS DE IMPLEMENTACIÓN

### Consideraciones de Escalabilidad
1. **Índices de base de datos** para consultas de reputación
2. **Batch processing** para recálculos masivos
3. **Cache layer** para consultas frecuentes (futuro)

### Anti-Gaming Measures
1. **Peso mínimo** para nuevos usuarios
2. **Análisis de distribución** para detectar manipulación
3. **Logging completo** para auditoría

### Monitoreo y Alertas
1. **Métricas de performance** en tiempo real
2. **Alertas** por errores en cálculos
3. **Dashboard** de salud del sistema

## ✅ CRITERIOS DE FINALIZACIÓN

El ticket se considera completado cuando:

1. **Todos los tests pasan** (unitarios, integración, performance)
2. **API endpoints funcionan** correctamente
3. **Signals actualizan** reputación automáticamente
4. **Management command** ejecuta sin errores
5. **Performance cumple** objetivos (<100ms)
6. **Documentación completa** y actualizada

---

**¡Listo para comenzar implementación con decay lineal! 🚀**
