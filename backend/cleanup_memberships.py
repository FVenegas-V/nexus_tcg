#!/usr/bin/env python
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth import get_user_model
from communities.models import Community, CommunityMembership

User = get_user_model()

print("🧹 Limpiando membresías de test1...")

user = User.objects.get(username='test1')
print(f"Usuario: {user.username}")

# Verificar membresías existentes antes
memberships = CommunityMembership.objects.filter(user=user)
print(f"Membresías antes: {memberships.count()}")

for membership in memberships:
    print(f"  - {membership.community.name} (ID: {membership.community.id}) - Rol: {membership.role}")

# Eliminar todas las membresías
deleted_count = memberships.delete()[0]
print(f"\n🗑️ Eliminadas {deleted_count} membresías")

# Verificar después
memberships_after = CommunityMembership.objects.filter(user=user)
print(f"Membresías después: {memberships_after.count()}")

# Actualizar contadores de comunidades
print("\n🔄 Actualizando contadores de comunidades...")
for community in Community.objects.all():
    # Recalcular member_count
    actual_count = CommunityMembership.objects.filter(community=community).count()
    if community.member_count != actual_count:
        print(f"  - {community.name}: {community.member_count} -> {actual_count}")
        community.member_count = actual_count
        community.save()

print("✅ Limpieza completada")
