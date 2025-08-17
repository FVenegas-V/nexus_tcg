from django.contrib.auth import get_user_model
from communities.models import Community, CommunityMembership

User = get_user_model()
user = User.objects.get(username='test1')
community = Community.objects.get(pk=1)

print(f"Usuario: {user.username}")
print(f"Comunidad: {community.name}")

# Verificar membresía
membership = CommunityMembership.objects.filter(community=community, user=user).first()
print(f"Membership: {membership}")
if membership:
    print(f"Status: {membership.status}")
    print(f"Role: {membership.role}")

# Verificar método
result = community.is_user_member(user)
print(f"is_user_member: {result}")
