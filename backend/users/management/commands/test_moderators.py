"""
Management command para probar el sistema de moderadores
"""
from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group
from users.models import User
from users.permissions import (
    is_rating_moderator, 
    is_community_moderator, 
    is_any_moderator,
    get_user_moderation_level
)

class Command(BaseCommand):
    help = 'Prueba el sistema de moderadores y permisos'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🧪 PROBANDO SISTEMA DE MODERADORES'))
        self.stdout.write('=' * 40)
        
        # Obtener usuarios de prueba
        try:
            admin_user = User.objects.filter(is_staff=True).first()
            rating_mod = User.objects.filter(username='rating_mod_test').first()
            community_mod = User.objects.filter(username='community_mod_test').first()
            general_mod = User.objects.filter(username='general_mod_test').first()
            regular_user = User.objects.filter(is_staff=False, groups__isnull=True).first()
            
            users_to_test = [
                ('Administrador', admin_user),
                ('Moderador Valoraciones', rating_mod),
                ('Moderador Comunidades', community_mod),
                ('Moderador General', general_mod),
                ('Usuario Regular', regular_user)
            ]
            
            self.stdout.write("\n👥 USUARIOS DE PRUEBA:")
            for name, user in users_to_test:
                if user:
                    self.stdout.write(f"   ✅ {name}: {user.username}")
                else:
                    self.stdout.write(f"   ❌ {name}: No encontrado")
            
            self.stdout.write("\n🔍 PROBANDO PERMISOS:")
            self.stdout.write("-" * 30)
            
            for name, user in users_to_test:
                if not user:
                    continue
                    
                self.stdout.write(f"\n👤 {name} ({user.username}):")
                self.stdout.write(f"   📊 Nivel: {get_user_moderation_level(user)}")
                self.stdout.write(f"   🏆 Es admin: {user.is_staff}")
                self.stdout.write(f"   ⭐ Mod. valoraciones: {is_rating_moderator(user)}")
                self.stdout.write(f"   🏘️  Mod. comunidades: {is_community_moderator(user)}")
                self.stdout.write(f"   🛡️  Cualquier mod: {is_any_moderator(user)}")
                
                # Mostrar grupos
                groups = user.groups.all()
                if groups:
                    group_names = [g.name for g in groups]
                    self.stdout.write(f"   👥 Grupos: {', '.join(group_names)}")
                else:
                    self.stdout.write(f"   👥 Grupos: Ninguno")
            
            self.stdout.write("\n🔒 PRUEBAS DE ACCESO:")
            self.stdout.write("-" * 25)
            
            # Simular accesos a funciones
            test_cases = [
                ("Dashboard Anti-Gaming", lambda u: is_rating_moderator(u)),
                ("Gestión de Flags", lambda u: is_rating_moderator(u)),
                ("Moderación General", lambda u: is_any_moderator(u)),
                ("Admin del Sistema", lambda u: u.is_staff),
            ]
            
            for func_name, permission_check in test_cases:
                self.stdout.write(f"\n🔧 {func_name}:")
                for name, user in users_to_test:
                    if not user:
                        continue
                    access = "✅ PERMITIDO" if permission_check(user) else "❌ DENEGADO"
                    self.stdout.write(f"   {name}: {access}")
            
            self.stdout.write("\n📊 ESTADÍSTICAS:")
            self.stdout.write("-" * 20)
            total_users = User.objects.count()
            admins = User.objects.filter(is_staff=True).count()
            
            try:
                rating_mods = Group.objects.get(name='rating_moderators').user_set.count()
                community_mods = Group.objects.get(name='community_moderators').user_set.count()
                general_mods = Group.objects.get(name='moderators').user_set.count()
            except Group.DoesNotExist:
                rating_mods = community_mods = general_mods = 0
            
            self.stdout.write(f"   👥 Total usuarios: {total_users}")
            self.stdout.write(f"   🏆 Administradores: {admins}")
            self.stdout.write(f"   ⭐ Mod. valoraciones: {rating_mods}")
            self.stdout.write(f"   🏘️  Mod. comunidades: {community_mods}")
            self.stdout.write(f"   🛡️  Mod. generales: {general_mods}")
            
            self.stdout.write(self.style.SUCCESS("\n✅ PRUEBA DE MODERADORES COMPLETADA"))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"❌ Error en pruebas: {e}"))
