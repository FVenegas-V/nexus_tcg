# 📧 Configuración de Gmail para Nexus TCG

## 🎯 Objetivo
Configurar `nexustcg.app@gmail.com` para enviar emails reales desde el sistema Django de Nexus TCG.

## 📋 Pasos para Configurar Gmail

### 1. Preparar la cuenta de Gmail

1. **Inicia sesión en Gmail** con `nexustcg.app@gmail.com`
2. **Ve a tu cuenta de Google**: https://myaccount.google.com/

### 2. Habilitar Verificación en 2 pasos (REQUERIDO)

1. Ve a **Seguridad** → **Verificación en 2 pasos**
2. Sigue los pasos para habilitarla (necesario para contraseñas de aplicación)
3. Confirma con tu número de teléfono

### 3. Generar Contraseña de Aplicación

1. **Ve a**: https://myaccount.google.com/apppasswords
2. **Selecciona la aplicación**: "Correo" 
3. **Selecciona el dispositivo**: "Otro (nombre personalizado)"
4. **Escribe**: "Nexus TCG Django App"
5. **Haz clic en "Generar"**
6. **Copia la contraseña** de 16 caracteres que aparece (formato: xxxx xxxx xxxx xxxx)

### 4. Configurar en el archivo .env

1. Abre `/backend/.env`
2. Reemplaza la línea:
   ```
   EMAIL_HOST_PASSWORD=PENDIENTE_CONFIGURAR_APP_PASSWORD
   ```
   
   Por:
   ```
   EMAIL_HOST_PASSWORD=la_contraseña_de_16_caracteres_que_copiaste
   ```

3. **Guarda el archivo**

### 5. Probar la configuración

Ejecuta el script de prueba:

```bash
cd backend
python test_gmail_config.py
```

## 📧 Configuración Final esperada

Archivo `/backend/.env`:
```env
# Configuración de Email Real - Gmail
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=nexustcg.app@gmail.com
EMAIL_HOST_PASSWORD=abcd efgh ijkl mnop  # Tu contraseña de aplicación
DEFAULT_FROM_EMAIL=nexustcg.app@gmail.com
```

## ✅ Verificación exitosa

Cuando funcione, verás:
```
🎉 ¡CONFIGURACIÓN COMPLETA!
   Gmail está configurado correctamente para Nexus TCG
   Ya puedes usar emails de verificación y recuperación de contraseñas
```

## 🚨 Troubleshooting

### Error: "Username and Password not accepted"
- ✅ Verifica que la verificación en 2 pasos esté habilitada
- ✅ Regenera la contraseña de aplicación
- ✅ Copia la contraseña sin espacios adicionales

### Error: "SMTPAuthenticationError"
- ✅ Verifica que estés usando la contraseña de aplicación, NO la contraseña normal de Gmail
- ✅ Asegúrate que el EMAIL_HOST_USER sea exactamente `nexustcg.app@gmail.com`

### Error: "Connection refused"
- ✅ Verifica tu conexión a internet
- ✅ Comprueba que EMAIL_PORT=587 y EMAIL_USE_TLS=True

## 🔐 Seguridad

- ❌ **NUNCA** subas el archivo `.env` a Git
- ✅ El archivo `.env` ya está en `.gitignore`
- ✅ Solo comparte las credenciales por canales seguros
- ✅ Puedes rotar la contraseña de aplicación cuando quieras

## 📱 Funcionalidades que usarán Gmail

Una vez configurado, estos features enviarán emails reales:

1. **✅ Verificación de email** al registrarse
2. **✅ Recuperación de contraseña**
3. **✅ Cambio de contraseña** (notificación)
4. **🔄 Notificaciones Fase 5** (emails de respaldo)

## 📞 Soporte

Si tienes problemas:
1. Ejecuta `python test_gmail_config.py` para diagnosticar
2. Revisa que la cuenta `nexustcg.app@gmail.com` tenga verificación en 2 pasos
3. Regenera la contraseña de aplicación si es necesario
