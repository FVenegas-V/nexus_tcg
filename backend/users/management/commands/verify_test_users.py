from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Verifica y crea usuarios de prueba para testing del sistema anti-gaming'

    def handle(self, *args, **options):
        # Lista de usuarios de prueba
        test_users = [
            {'username': 'test_user_1', 'email': 'test_user_1@test.com', 'password': 'password123'},
            {'username': 'test_user_2', 'email': 'test_user_2@test.com', 'password': 'password123'},
            {'username': 'test_user_3', 'email': 'test_user_3@test.com', 'password': 'password123'},
        ]
        
        self.stdout.write("=== VERIFICANDO USUARIOS DE PRUEBA ===\n")
        
        # Verificar usuarios existentes
        existing_users = User.objects.all()
        self.stdout.write(f"📊 Total usuarios en sistema: {existing_users.count()}")
        
        for user in existing_users.filter(username__startswith='test_user_'):
            self.stdout.write(f"  - {user.username} / {user.email} (ID: {user.id})")
        
        self.stdout.write("\n=== CREANDO/VERIFICANDO USUARIOS DE PRUEBA ===\n")
        
        for user_data in test_users:
            username = user_data['username']
            email = user_data['email']
            password = user_data['password']
            
            # Verificar si el usuario ya existe por email (que es el USERNAME_FIELD)
            try:
                user = User.objects.get(email=email)
                # Actualizar password por si acaso
                user.set_password(password)
                user.username = username  # Asegurar username correcto
                user.save()
                self.stdout.write(
                    self.style.WARNING(f"⚠️  Usuario existente actualizado: {username} / {email}")
                )
            except User.DoesNotExist:
                # Crear nuevo usuario
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    password=password,
                    first_name='Test',
                    last_name=f'User {username.split("_")[-1]}',
                    is_active=True,
                    email_verified=True
                )
                self.stdout.write(
                    self.style.SUCCESS(f"✅ Usuario creado: {username} / {email}")
                )
        
        self.stdout.write("\n=== VERIFICANDO CREDENCIALES ===\n")
        
        # Verificar que las credenciales funcionan
        from django.contrib.auth import authenticate
        
        for user_data in test_users:
            username = user_data['username']
            email = user_data['email']
            password = user_data['password']
            
            # Probar autenticación por email (USERNAME_FIELD)
            auth_user = authenticate(username=email, password=password)
            if auth_user:
                self.stdout.write(
                    self.style.SUCCESS(f"✅ Credenciales OK (email): {email} / {password}")
                )
            else:
                self.stdout.write(
                    self.style.ERROR(f"❌ Error credenciales (email): {email} / {password}")
                )
            
            # También probar por username (por si acaso)
            auth_user = authenticate(username=username, password=password)
            if auth_user:
                self.stdout.write(
                    self.style.SUCCESS(f"✅ Credenciales OK (username): {username} / {password}")
                )
        
        self.stdout.write("\n=== RESUMEN ===")
        self.stdout.write("Los siguientes usuarios están listos para testing:")
        self.stdout.write("(NOTA: Este sistema usa EMAIL para login, no username)")
        for user_data in test_users:
            self.stdout.write(f"  � Email: {user_data['email']} / Password: {user_data['password']}")
            self.stdout.write(f"     Username: {user_data['username']}")
        
        self.stdout.write("\n🚀 Usuarios de prueba listos para testing del sistema anti-gaming!")
        self.stdout.write("💡 IMPORTANTE: En la app usa el EMAIL para hacer login, no el username.")
