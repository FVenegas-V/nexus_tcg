# 🧪 GUÍA DE PRUEBAS: SISTEMA ANTI-GAMING

**Testing en Vivo del Sistema de Prevención de Abuso**

---

## 🎯 **Objetivo de las Pruebas**

Validar que el sistema anti-gaming implementado en **FASE4-0006** funciona correctamente en la aplicación Flutter, protegiendo el sistema de reputación contra:

- 🎯 Gaming de valoraciones (sesgo 5 estrellas)
- 🔄 Círculos de valoración mutua
- 📧 Spam de cuentas nuevas
- 🚀 Ráfagas de valoraciones
- 🌐 Ataques desde misma IP

---

## 🔧 **Setup de Pruebas**

### **✅ Prerrequisitos Completados:**
- [x] Backend Django ejecutándose en `localhost:8000`
- [x] Sistema anti-gaming configurado y activo
- [x] Base de datos con moderadores y configuración
- [x] Frontend Flutter ejecutándose (Chrome/Android)

### **👥 Usuarios de Prueba Disponibles:**

#### **Usuarios Normales:**
- `test_user_1` / `password123`
- `test_user_2` / `password123`
- `test_user_3` / `password123`

#### **Moderadores:**
- `rating_mod` / `modpass123` (Rating Moderator)
- `community_mod` / `modpass123` (Community Moderator)
- `general_mod` / `modpass123` (General Moderator)

#### **Admin:**
- `admin` / `adminpass123` (Super Admin)

**💡 NOTA IMPORTANTE:** El sistema acepta login tanto con username como con email. Los usuarios de prueba están configurados para funcionar con ambos métodos.

---

## 🎭 **Escenarios de Prueba**

### **🎯 Prueba 1: Detección de Sesgo 5 Estrellas**

#### **Objetivo:** Verificar que el sistema detecta usuarios que solo dan 5 estrellas

#### **Pasos:**
1. Login como `test_user_1`
2. Valorar a 8+ usuarios diferentes con solo 5 estrellas
3. Verificar que aparece un flag automático
4. Login como `rating_mod` para ver el flag generado

#### **Resultado Esperado:**
- ✅ Flag automático generado después de 8 valoraciones de 5 estrellas
- ✅ Tipo de flag: "five_star_bias"
- ✅ Usuario marcado como sospechoso para revisión

---

### **🔄 Prueba 2: Rate Limiting Efectivo**

#### **Objetivo:** Verificar límites de velocidad funcionan sin frustrar UX

#### **Pasos:**
1. Login como `test_user_2`
2. Intentar valorar al mismo usuario 2 veces seguidas
3. Verificar cooldown de 1 hora entre valoraciones
4. Intentar hacer 16+ valoraciones en 1 hora
5. Verificar que se aplica rate limiting

#### **Resultado Esperado:**
- ✅ Mensaje: "Debes esperar 1 hora para valorar al mismo usuario"
- ✅ Bloqueo después de 15 valoraciones por hora
- ✅ Mensaje claro explicando el límite

---

### **📧 Prueba 3: Control Cuentas Nuevas**

#### **Objetivo:** Verificar límites para usuarios recién registrados

#### **Pasos:**
1. Crear nueva cuenta `new_user_test`
2. Intentar hacer 6 valoraciones en 2 días
3. Verificar que se bloquea en la 6ta valoración
4. Esperar 7 días y verificar que se resetea el límite

#### **Resultado Esperado:**
- ✅ Límite de 5 valoraciones en 7 días para cuentas nuevas
- ✅ Mensaje explicativo del límite
- ✅ Reset automático después de 7 días

---

### **🚀 Prueba 4: Detección de Ráfagas**

#### **Objetivo:** Verificar detección de patrones robóticos

#### **Pasos:**
1. Login como `test_user_3`
2. Hacer valoraciones cada 5 minutos durante 1 hora
3. Superar 15 valoraciones por hora
4. Verificar flag de comportamiento sospechoso

#### **Resultado Esperado:**
- ✅ Flag automático por "rating_burst"
- ✅ Análisis de intervalos temporales
- ✅ Detección de patrón robótico

---

### **🌐 Prueba 5: Sistema de Moderación**

#### **Objetivo:** Verificar herramientas de moderación funcionan

#### **Pasos:**
1. Login como `rating_mod`
2. Revisar flags automáticos generados
3. Aprobar/rechazar flags según criterio
4. Verificar escalado a `general_mod` si es necesario
5. Login como `admin` para ver panel completo

#### **Resultado Esperado:**
- ✅ Dashboard moderación funcional
- ✅ Lista de flags pendientes
- ✅ Acciones de moderación disponibles
- ✅ Escalado de permisos correcto

---

## 📊 **Métricas a Verificar**

### **🎯 Performance:**
- ⚡ Tiempo respuesta valoraciones < 2 segundos
- 🚀 Análisis anti-gaming < 100ms
- 💾 Sin degradación performance app

### **🛡️ Detección:**
- 🎯 Flags automáticos generados correctamente
- 🔍 Precisión detección sin falsos positivos
- ⚡ Respuesta en tiempo real

### **👥 UX:**
- 😊 Usuarios legítimos no afectados
- 📝 Mensajes claros y útiles
- 🔄 Recovery automático de límites

---

## 📱 **Pruebas Específicas Flutter**

### **🖱️ Pruebas de Interfaz:**

#### **Valoración Normal:**
1. Navegar a perfil de usuario
2. Seleccionar estrellas (1-5)
3. Escribir comentario opcional
4. Enviar valoración
5. Verificar confirmación visual

#### **Manejo de Errores:**
1. Intentar valoración duplicada
2. Verificar mensaje de cooldown
3. Intentar exceder límites
4. Verificar mensajes informativos
5. Validar UX no se rompe

#### **Dashboard Moderación:**
1. Login como moderador
2. Navegar a panel moderación
3. Ver lista de flags
4. Procesar flags individuales
5. Verificar actualización en tiempo real

---

## 🚨 **Casos Edge a Probar**

### **🔧 Robustez del Sistema:**

1. **Conexión Intermitente:**
   - Valorar con internet lento
   - Verificar que no se duplican valoraciones
   - Confirmar manejo graceful de errores

2. **Carga Simultanea:**
   - Multiple usuarios valorando al mismo tiempo
   - Verificar concurrencia sin conflicts
   - Confirmar rate limiting por usuario

3. **Datos Corruptos:**
   - Valoraciones con datos inválidos
   - Comentarios con caracteres especiales
   - Verificar validación robusta

---

## ✅ **Checklist de Validación**

### **🎯 Sistema Anti-Gaming:**
- [ ] Detección sesgo 5 estrellas funciona
- [ ] Rate limiting efectivo sin frustrar UX
- [ ] Control cuentas nuevas operativo
- [ ] Detección ráfagas activa
- [ ] Flags automáticos generados
- [ ] Performance < 100ms mantenido

### **👥 Sistema Moderación:**
- [ ] Dashboard moderación funcional
- [ ] Permisos por rol correctos
- [ ] Escalado automático funciona
- [ ] Acciones moderación operativas
- [ ] Audit trail completo

### **📱 Experiencia Usuario:**
- [ ] Interface intuitiva y clara
- [ ] Mensajes de error útiles
- [ ] No interferencia usuarios legítimos
- [ ] Recovery automático límites
- [ ] Performance app mantenida

### **🔧 Integración Backend:**
- [ ] APIs funcionando correctamente
- [ ] Validación datos robusta
- [ ] Manejo errores graceful
- [ ] Logs estructurados
- [ ] Métricas capturadas

---

## 📈 **Reportes de Resultados**

### **📊 Formato de Reporte:**

```
RESULTADO PRUEBA: [Nombre Prueba]
Fecha: [DD/MM/YYYY HH:MM]
Usuario: [username utilizado]
Status: ✅ PASS / ❌ FAIL
Tiempo Respuesta: [ms]
Observaciones: [detalles relevantes]
Screenshots: [si aplicable]
```

### **🎯 Métricas Clave:**
- **Precisión Detección**: % de gaming detectado correctamente
- **Falsos Positivos**: % usuarios legítimos afectados
- **Performance**: Tiempo respuesta promedio
- **UX Score**: Satisfacción usuario en pruebas

---

## 🚀 **Next Steps Post-Testing**

### **✅ Si Todo Pasa:**
1. **Deploy a Producción** - Sistema validado listo
2. **Monitor Métricas** - Seguimiento KPIs en vivo
3. **User Feedback** - Recopilar experiencia usuarios reales
4. **Fine-tuning** - Ajustes basados en datos reales

### **🔧 Si Se Encuentran Issues:**
1. **Documentar Bugs** - Descripción detallada problemas
2. **Fix Prioritario** - Corrección inmediata issues críticos
3. **Re-testing** - Validación fixes implementados
4. **Regression Testing** - Verificar no se rompió nada más

---

## 🎉 **Objetivo Final**

**Confirmar que el sistema FASE4-0006 está 100% funcional en la app Flutter y listo para proteger Nexus TCG desde el día uno del lanzamiento.**

---

*Creado por: GitHub Copilot*  
*Fecha: 26 Agosto 2025*  
*Estado: Listo para Ejecución ✅*
