#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User

def check_testuser1_credentials():
    print("🔍 VERIFICANDO CREDENCIALES DE TESTUSER1")
    print("=" * 50)
    
    try:
        user = User.objects.get(username='testuser1')
        
        print(f"👤 Username: {user.username}")
        print(f"📧 Email: {user.email}")
        print(f"🔑 Password Hash: {user.password}")
        print(f"📅 Fecha creación: {user.date_joined.strftime('%Y-%m-%d %H:%M')}")
        print(f"📅 Último login: {user.last_login}")
        print(f"✅ Activo: {user.is_active}")
        print(f"👑 Staff: {user.is_staff}")
        print(f"🛡️ Superuser: {user.is_superuser}")
        
        # Como no podemos ver la contraseña directamente (está hasheada),
        # vamos a verificar si funciona con contraseñas comunes de testing
        test_passwords = [
            'password123',
            'testpass',
            'test123',
            'admin123',
            '123456',
            'password',
            'test',
        ]
        
        print(f"\n🔐 PROBANDO CONTRASEÑAS COMUNES:")
        print("-" * 30)
        
        for password in test_passwords:
            if user.check_password(password):
                print(f"✅ CONTRASEÑA ENCONTRADA: '{password}'")
                return
            else:
                print(f"❌ No es: '{password}'")
        
        print(f"\n⚠️ No se encontró la contraseña entre las opciones comunes.")
        print(f"💡 Puedes resetear la contraseña si es necesario.")
        
    except User.DoesNotExist:
        print("❌ Usuario testuser1 no encontrado")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_testuser1_credentials()
