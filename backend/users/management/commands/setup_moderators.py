"""
Management command para configurar grupos de moderadores
"""
from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType
from users.models import User, UserRating, RatingFlag, UserSuspension

class Command(BaseCommand):
    help = 'Configura los grupos de moderadores para Nexus TCG'

    def add_arguments(self, parser):
        parser.add_argument(
            '--create-test-moderators',
            action='store_true',
            help='Crear moderadores de prueba',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🔧 CONFIGURANDO SISTEMA DE MODERADORES'))
        self.stdout.write('=' * 50)
        
        # 1. Crear grupos de moderadores
        self.create_moderator_groups()
        
        # 2. Asignar permisos a los grupos
        self.assign_permissions()
        
        # 3. Crear moderadores de prueba si se solicita
        if options['create_test_moderators']:
            self.create_test_moderators()
        
        self.stdout.write(self.style.SUCCESS('\n✅ CONFIGURACIÓN DE MODERADORES COMPLETADA'))

    def create_moderator_groups(self):
        """Crea los grupos de moderadores"""
        groups_info = {
            'rating_moderators': 'Moderadores de Valoraciones - Pueden revisar flags, suspender usuarios por abuso de valoraciones',
            'community_moderators': 'Moderadores de Comunidades - Pueden moderar comunidades, posts, y contenido',
            'moderators': 'Moderadores Generales - Acceso limitado a funciones básicas de moderación'
        }
        
        for group_name, description in groups_info.items():
            group, created = Group.objects.get_or_create(name=group_name)
            if created:
                self.stdout.write(f'  ✅ Grupo creado: {group_name}')
            else:
                self.stdout.write(f'  ♻️  Grupo existente: {group_name}')
            self.stdout.write(f'     📝 {description}')

    def assign_permissions(self):
        """Asigna permisos específicos a cada grupo"""
        
        # Obtener grupos
        rating_mods = Group.objects.get(name='rating_moderators')
        community_mods = Group.objects.get(name='community_moderators')
        general_mods = Group.objects.get(name='moderators')
        
        # Permisos para moderadores de valoraciones
        rating_permissions = [
            'view_userrating',
            'change_userrating',
            'view_ratingflag',
            'change_ratingflag',
            'add_usersuspension',
            'change_usersuspension',
            'view_usersuspension',
            'view_abuselog',
        ]
        
        self.stdout.write('\n📋 ASIGNANDO PERMISOS...')
        
        # Asignar permisos a moderadores de valoraciones
        for perm_codename in rating_permissions:
            try:
                permission = Permission.objects.get(codename=perm_codename)
                rating_mods.permissions.add(permission)
                self.stdout.write(f'  ✅ Permiso {perm_codename} asignado a rating_moderators')
            except Permission.DoesNotExist:
                self.stdout.write(f'  ⚠️  Permiso {perm_codename} no encontrado')
        
        # Los moderadores de comunidad también pueden ver algunas cosas
        community_permissions = [
            'view_userrating',
            'view_ratingflag',
            'view_usersuspension',
        ]
        
        for perm_codename in community_permissions:
            try:
                permission = Permission.objects.get(codename=perm_codename)
                community_mods.permissions.add(permission)
            except Permission.DoesNotExist:
                pass

    def create_test_moderators(self):
        """Crea moderadores de prueba para testing"""
        self.stdout.write('\n👥 CREANDO MODERADORES DE PRUEBA...')
        
        test_moderators = [
            {
                'username': 'rating_mod_test',
                'email': 'rating_mod@nexustcg.com',
                'password': 'TestMod123!',
                'group': 'rating_moderators',
                'description': 'Moderador de valoraciones de prueba'
            },
            {
                'username': 'community_mod_test',
                'email': 'community_mod@nexustcg.com',
                'password': 'TestMod123!',
                'group': 'community_moderators',
                'description': 'Moderador de comunidades de prueba'
            },
            {
                'username': 'general_mod_test',
                'email': 'general_mod@nexustcg.com',
                'password': 'TestMod123!',
                'group': 'moderators',
                'description': 'Moderador general de prueba'
            }
        ]
        
        for mod_info in test_moderators:
            user, created = User.objects.get_or_create(
                username=mod_info['username'],
                email=mod_info['email'],
                defaults={
                    'email_verified': True,
                }
            )
            
            if created:
                user.set_password(mod_info['password'])
                user.save()
                self.stdout.write(f'  ✅ Usuario creado: {mod_info["username"]}')
            else:
                self.stdout.write(f'  ♻️  Usuario existente: {mod_info["username"]}')
            
            # Asignar al grupo
            group = Group.objects.get(name=mod_info['group'])
            user.groups.add(group)
            
            self.stdout.write(f'     📧 Email: {mod_info["email"]}')
            self.stdout.write(f'     🔑 Password: {mod_info["password"]}')
            self.stdout.write(f'     👔 Rol: {mod_info["description"]}')
            self.stdout.write('')
