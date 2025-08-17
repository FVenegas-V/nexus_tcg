#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community
from users.models import User

print('=== ESTADO ACTUAL EN DJANGO ===')

print('\n1. COMUNIDADES Y MEMBER_COUNT:')
communities = Community.objects.all()
for c in communities:
    print(f'   ID: {c.id}, Nombre: {c.name}, Member Count: {c.member_count}')

print('\n2. MEMBRESÍAS DESDE User model:')
test_user = User.objects.filter(username='test1').first()
if test_user:
    print(f'   Usuario encontrado: {test_user.username} (ID: {test_user.id})')
    # Usar reverse lookup desde CommunityMembership
    from communities.models import CommunityMembership
    memberships = CommunityMembership.objects.filter(user=test_user)
    print(f'   Número de membresías: {memberships.count()}')
    for membership in memberships:
        print(f'   - Comunidad: {membership.community.name}, Rol: {membership.role}, Joined: {membership.joined_at}')
else:
    print('   Usuario test1 no encontrado')

print('\n3. VERIFICAR MEMBER_COUNT VS REAL MEMBERSHIPS:')
from communities.models import CommunityMembership
for c in communities:
    real_count = CommunityMembership.objects.filter(community=c).count()
    stored_count = c.member_count
    status = "✅ CORRECTO" if real_count == stored_count else "❌ DESINCRONIZADO"
    print(f'   {c.name}: Almacenado={stored_count}, Real={real_count} {status}')

print('\n4. TODAS LAS MEMBRESÍAS EN EL SISTEMA:')
from communities.models import CommunityMembership
all_memberships = CommunityMembership.objects.all().order_by('-joined_at')
for m in all_memberships[:10]:  # Solo las últimas 10
    print(f'   ID: {m.id}, User: {m.user.username}, Comunidad: {m.community.name}, Fecha: {m.joined_at.strftime("%Y-%m-%d %H:%M")}')

print(f'\nTotal membresías en el sistema: {all_memberships.count()}')
