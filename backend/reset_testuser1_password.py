#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User

def reset_testuser1_password():
    print("🔧 RESETEANDO CONTRASEÑA DE TESTUSER1")
    print("=" * 50)
    
    try:
        user = User.objects.get(username='testuser1')
        
        # Resetear a una contraseña conocida
        new_password = 'password123'
        user.set_password(new_password)
        user.save()
        
        print(f"✅ Contraseña reseteada exitosamente!")
        print(f"👤 Username: {user.username}")
        print(f"📧 Email: {user.email}")
        print(f"🔑 Nueva contraseña: {new_password}")
        
        # Verificar que funciona
        if user.check_password(new_password):
            print(f"✅ Contraseña verificada correctamente")
        else:
            print(f"❌ Error al verificar la nueva contraseña")
            
        print(f"\n📱 CREDENCIALES PARA LA APP:")
        print(f"   Username: testuser1")
        print(f"   Password: password123")
        print(f"   (También puede usar email: test1@comments.com)")
        
    except User.DoesNotExist:
        print("❌ Usuario testuser1 no encontrado")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    reset_testuser1_password()
