# 📱 PLAN DE PRUEBAS EN DISPOSITIVO REAL
## Sistema de Comentarios - Nexus TCG

### 🎯 **Objetivo**
Verificar que el sistema de comentarios funciona correctamente en dispositivo/emulador real con backend Django activo.

---

## 📋 **CHECKLIST DE PRUEBAS**

### ✅ **1. PRUEBAS DE CONECTIVIDAD**
- [ ] App inicia correctamente
- [ ] Login funciona con backend real
- [ ] Navegación entre pantallas
- [ ] Carga de comunidades desde API
- [ ] Carga de posts desde API

### ✅ **2. PRUEBAS DE SISTEMA DE COMENTARIOS**

#### **2.1 Visualización de Comentarios**
- [ ] Lista de comentarios carga correctamente
- [ ] Threading visual (indentación) funciona
- [ ] Indicadores de nivel (↳) aparecen
- [ ] Formateo de tiempo relativo
- [ ] Avatar y username del autor
- [ ] Contadores de reacciones

#### **2.2 Creación de Comentarios**
- [ ] Abrir composer de comentario principal
- [ ] Escribir texto en el campo
- [ ] Enviar comentario principal
- [ ] Ver comentario creado en la lista
- [ ] Actualización en tiempo real

#### **2.3 Threading y Respuestas**
- [ ] Botón "Responder" en comentario principal
- [ ] Composer muestra preview del comentario padre
- [ ] Crear respuesta nivel 1
- [ ] Verificar indentación visual correcta
- [ ] Crear respuesta nivel 2 (máximo)
- [ ] Verificar límite de 3 niveles

#### **2.4 Edición de Comentarios**
- [ ] Botón "Editar" disponible en comentarios propios
- [ ] Modo edición inline funciona
- [ ] Timer de 15 minutos visible
- [ ] Guardar cambios
- [ ] Cancelar edición

#### **2.5 Sistema de Reacciones**
- [ ] Botones de reacciones visibles
- [ ] Reaccionar a comentario (like, love, etc.)
- [ ] Cambio visual inmediato
- [ ] Contadores actualizados
- [ ] Toggle de reacciones (quitar/cambiar)

#### **2.6 Scroll y Paginación**
- [ ] Scroll infinito en lista de comentarios
- [ ] Carga de más comentarios automática
- [ ] Performance con muchos comentarios
- [ ] Mantener posición al volver

### ✅ **3. PRUEBAS DE UX/UI**

#### **3.1 Responsive Design**
- [ ] Layout correcto en orientación portrait
- [ ] Layout correcto en orientación landscape
- [ ] Elementos touch-friendly
- [ ] Spaciado y margenes apropiados

#### **3.2 Estados y Feedback**
- [ ] Loading states durante carga
- [ ] Estados vacíos (sin comentarios)
- [ ] Mensajes de error comprensibles
- [ ] Animaciones suaves

#### **3.3 Navegación**
- [ ] Back navigation funciona
- [ ] Deep linking a post específico
- [ ] Transiciones entre pantallas
- [ ] Memory management (no leaks)

### ✅ **4. PRUEBAS DE PERFORMANCE**

#### **4.1 Tiempo de Respuesta**
- [ ] Carga inicial < 3 segundos
- [ ] Creación de comentario < 2 segundos
- [ ] Respuesta < 1 segundo
- [ ] Edición < 1 segundo

#### **4.2 Uso de Memoria**
- [ ] No memory leaks evidentes
- [ ] Scroll suave con 50+ comentarios
- [ ] Cache funcionando correctamente
- [ ] Liberación de recursos

### ✅ **5. PRUEBAS DE EDGE CASES**

#### **5.1 Conectividad**
- [ ] Comportamiento sin internet
- [ ] Reconexión automática
- [ ] Operaciones offline/online
- [ ] Estados de error de red

#### **5.2 Datos Extremos**
- [ ] Comentarios muy largos
- [ ] Threads muy profundos
- [ ] Muchas reacciones
- [ ] Caracteres especiales/emojis

#### **5.3 Estados Límite**
- [ ] Sin comentarios en post
- [ ] Post con 100+ comentarios
- [ ] Usuario sin permisos
- [ ] Sesión expirada

---

## 📊 **MÉTRICAS A MEDIR**

### **Tiempo de Respuesta**
- Carga inicial de comentarios: ___ ms
- Crear comentario: ___ ms
- Crear respuesta: ___ ms
- Editar comentario: ___ ms
- Reaccionar: ___ ms

### **Usabilidad**
- Facilidad de uso (1-10): ___
- Intuitividad del threading: ___
- Claridad visual: ___
- Performance general: ___

---

## 🐛 **REGISTRO DE BUGS**

### **Bug #1**
- **Descripción**: 
- **Pasos para reproducir**: 
- **Esperado**: 
- **Actual**: 
- **Severidad**: 
- **Screenshot**: 

### **Bug #2**
- **Descripción**: 
- **Pasos para reproducir**: 
- **Esperado**: 
- **Actual**: 
- **Severidad**: 
- **Screenshot**: 

---

## ✅ **CRITERIOS DE ACEPTACIÓN**

Para considerar las pruebas exitosas:

1. **✅ Funcionalidad Core (100%)**: Todos los flujos básicos funcionan
2. **✅ Threading Visual (100%)**: Indentación y niveles correctos
3. **✅ Performance (>80%)**: Tiempos de respuesta aceptables
4. **✅ UX (>80%)**: Interfaz intuitiva y responsive
5. **✅ Estabilidad (>95%)**: Sin crashes o errors críticos

---

## 📝 **INSTRUCCIONES DE TESTING**

### **Preparación**
1. Backend Django ejecutándose en localhost:8000
2. App instalada en emulador/dispositivo
3. Usuario de prueba creado y loggeado
4. Datos de prueba disponibles

### **Flujo de Testing**
1. **Login** → Crear usuario o usar existente
2. **Navegación** → Ir a comunidad con posts
3. **Post Detail** → Abrir post con comentarios
4. **Testing Sistemático** → Seguir checklist paso a paso
5. **Documentación** → Registrar resultados y bugs

### **Datos de Prueba Recomendados**
- Usuario: `testuser_comments` / `TestPass123!`
- Comunidad: cualquiera con posts
- Posts: con al menos 3-5 comentarios existentes
- Comentarios: con diferentes niveles de threading

---

*Última actualización: 18 de agosto de 2025*
*Estado: Lista para ejecutar*
