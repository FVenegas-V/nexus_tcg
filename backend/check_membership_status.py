#!/usr/bin/env python
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth import get_user_model
from communities.models import Community, CommunityMembership

User = get_user_model()

print("🔍 Verificando estado de membresías...")

user = User.objects.get(username='test1')
print(f"Usuario: {user.username}")

# Verificar membresías existentes
memberships = CommunityMembership.objects.filter(user=user)
print(f"Membresías actuales: {memberships.count()}")

for membership in memberships:
    print(f"  - {membership.community.name} (ID: {membership.community.id}) - Rol: {membership.role}")

# Verificar comunidades disponibles
communities = Community.objects.all()
print(f"\nComunidades disponibles: {communities.count()}")

for community in communities:
    is_member = CommunityMembership.objects.filter(community=community, user=user).exists()
    print(f"  - {community.name} (ID: {community.id})")
    print(f"    * Es miembro: {'Sí' if is_member else 'No'}")
    print(f"    * is_public: {community.is_public}")
    print(f"    * requires_approval: {community.requires_approval}")
    print(f"    * member_count: {community.member_count}")
    print(f"    * max_members: {community.max_members}")
