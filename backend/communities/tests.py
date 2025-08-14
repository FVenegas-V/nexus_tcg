"""
Tests para modelos de comunidades TCG.
"""
from django.test import TestCase
from django.core.exceptions import ValidationError
from django.contrib.auth import get_user_model
from .models import CommunityCategory, Community, CommunityMembership

User = get_user_model()


class CommunityCategoryModelTest(TestCase):
    """Tests para el modelo CommunityCategory."""
    
    def test_category_creation(self):
        """Test básico de creación de categoría."""
        category = CommunityCategory.objects.create(
            name="Test Category",
            description="Una categoría de prueba",
            icon="test_icon",
            color="#FF0000"
        )
        
        self.assertEqual(category.name, "Test Category")
        self.assertEqual(category.slug, "test-category")  # Auto-generado
        self.assertTrue(category.is_active)
        self.assertEqual(category.community_count, 0)
    
    def test_category_str_representation(self):
        """Test de representación string."""
        category = CommunityCategory.objects.create(
            name="Competitive",
            community_count=5
        )
        
        self.assertEqual(str(category), "Competitive (5 comunidades)")
    
    def test_is_popular_property(self):
        """Test de la propiedad is_popular."""
        category = CommunityCategory.objects.create(
            name="Popular Category",
            community_count=15
        )
        
        self.assertTrue(category.is_popular)
        
        category.community_count = 5
        self.assertFalse(category.is_popular)


class CommunityModelTest(TestCase):
    """Tests para el modelo Community."""
    
    def setUp(self):
        """Setup para tests."""
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123"
        )
        
        self.category = CommunityCategory.objects.create(
            name="Test Category",
            icon="test_icon"
        )
    
    def test_community_creation(self):
        """Test básico de creación de comunidad."""
        community = Community.objects.create(
            name="Test Community",
            description="Una comunidad de prueba",
            game_type="Magic: The Gathering",
            difficulty_level="intermedio",
            category=self.category,
            created_by=self.user
        )
        
        self.assertEqual(community.name, "Test Community")
        self.assertEqual(community.slug, "test-community")  # Auto-generado
        self.assertTrue(community.is_public)
        self.assertFalse(community.requires_approval)
        self.assertEqual(community.member_count, 0)
        self.assertEqual(list(community.tags), [])
    
    def test_community_str_representation(self):
        """Test de representación string."""
        community = Community.objects.create(
            name="Magic Community",
            description="Test",
            game_type="Magic: The Gathering",
            category=self.category,
            created_by=self.user,
            member_count=50
        )
        
        self.assertEqual(str(community), "Magic Community (50 miembros)")
    
    def test_is_full_property(self):
        """Test de la propiedad is_full."""
        community = Community.objects.create(
            name="Limited Community",
            description="Test",
            game_type="Magic: The Gathering",
            category=self.category,
            created_by=self.user,
            max_members=10,
            member_count=10
        )
        
        self.assertTrue(community.is_full)
        
        # Sin límite
        community.max_members = None
        self.assertFalse(community.is_full)
    
    def test_is_popular_property(self):
        """Test de la propiedad is_popular."""
        community = Community.objects.create(
            name="Popular Community",
            description="Test",
            game_type="Magic: The Gathering",
            category=self.category,
            created_by=self.user,
            member_count=150
        )
        
        self.assertTrue(community.is_popular)
        
        community.member_count = 50
        self.assertFalse(community.is_popular)
    
    def test_member_capacity_percentage(self):
        """Test del cálculo de porcentaje de capacidad."""
        community = Community.objects.create(
            name="Test Community",
            description="Test",
            game_type="Magic: The Gathering",
            category=self.category,
            created_by=self.user,
            max_members=100,
            member_count=25
        )
        
        self.assertEqual(community.member_capacity_percentage, 25.0)
        
        # Sin límite
        community.max_members = None
        self.assertIsNone(community.member_capacity_percentage)


class CommunityMembershipModelTest(TestCase):
    """Tests para el modelo CommunityMembership."""
    
    def setUp(self):
        """Setup para tests."""
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123"
        )
        
        self.moderator = User.objects.create_user(
            username="moderator",
            email="mod@example.com",
            password="modpass123"
        )
        
        self.category = CommunityCategory.objects.create(
            name="Test Category"
        )
        
        self.community = Community.objects.create(
            name="Test Community",
            description="Test",
            game_type="Magic: The Gathering",
            category=self.category,
            created_by=self.user
        )
    
    def test_membership_creation(self):
        """Test básico de creación de membresía."""
        membership = CommunityMembership.objects.create(
            user=self.user,
            community=self.community
        )
        
        self.assertEqual(membership.role, 'member')
        self.assertEqual(membership.status, 'active')
        self.assertTrue(membership.is_active)
        self.assertFalse(membership.is_staff)
    
    def test_membership_str_representation(self):
        """Test de representación string."""
        membership = CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='moderator'
        )
        
        expected = f"{self.user.username} en {self.community.name} (Moderador)"
        self.assertEqual(str(membership), expected)
    
    def test_unique_constraint(self):
        """Test de constraint único user-community."""
        # Crear primera membresía
        CommunityMembership.objects.create(
            user=self.user,
            community=self.community
        )
        
        # Intentar crear duplicada debe fallar
        with self.assertRaises(Exception):  # IntegrityError esperado
            CommunityMembership.objects.create(
                user=self.user,
                community=self.community
            )
    
    def test_staff_permissions(self):
        """Test de permisos de staff."""
        # Miembro regular
        member = CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='member'
        )
        
        self.assertFalse(member.is_staff)
        self.assertFalse(member.can_moderate)
        self.assertFalse(member.can_admin)
        
        # Moderador
        moderator = CommunityMembership.objects.create(
            user=self.moderator,
            community=self.community,
            role='moderator'
        )
        
        self.assertTrue(moderator.is_staff)
        self.assertTrue(moderator.can_moderate)
        self.assertFalse(moderator.can_admin)
        
        # Admin
        moderator.role = 'admin'
        moderator.save()
        
        self.assertTrue(moderator.can_admin)
    
    def test_validation_admin_must_be_active(self):
        """Test que admin/moderador debe tener status activo."""
        membership = CommunityMembership(
            user=self.user,
            community=self.community,
            role='admin',
            status='suspended'
        )
        
        with self.assertRaises(ValidationError):
            membership.clean()
    
    def test_promote_demote_methods(self):
        """Test de métodos de promoción/degradación."""
        membership = CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='member'
        )
        
        # Promover a moderador
        membership.promote_to_moderator(self.moderator)
        self.assertEqual(membership.role, 'moderator')
        
        # Degradar a miembro
        membership.demote_to_member(self.moderator)
        self.assertEqual(membership.role, 'member')
    
    def test_suspend_reactivate_methods(self):
        """Test de métodos de suspensión/reactivación."""
        membership = CommunityMembership.objects.create(
            user=self.user,
            community=self.community,
            role='moderator'
        )
        
        # Suspender
        membership.suspend(self.moderator, "Comportamiento inadecuado")
        self.assertEqual(membership.status, 'suspended')
        self.assertEqual(membership.role, 'member')  # Debe perder privilegios
        
        # Reactivar
        membership.reactivate(self.moderator)
        self.assertEqual(membership.status, 'active')
        
        # No se puede reactivar un usuario expulsado
        membership.status = 'banned'
        membership.save()
        
        with self.assertRaises(ValidationError):
            membership.reactivate()


class CommunityModelIntegrationTest(TestCase):
    """Tests de integración entre modelos."""
    
    def setUp(self):
        """Setup para tests."""
        self.user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123"
        )
        
        self.category = CommunityCategory.objects.create(
            name="Test Category"
        )
        
        self.community = Community.objects.create(
            name="Test Community",
            description="Test",
            game_type="Magic: The Gathering",
            category=self.category,
            created_by=self.user,
            max_members=5
        )
    
    def test_membership_limits_validation(self):
        """Test de validación de límites de membresía."""
        # Crear membresías hasta el límite
        for i in range(5):
            user = User.objects.create_user(
                username=f"user{i}",
                email=f"user{i}@example.com",
                password="pass123"
            )
            CommunityMembership.objects.create(
                user=user,
                community=self.community,
                status='active'
            )
        
        # Intentar crear una más debería fallar por límite
        extra_user = User.objects.create_user(
            username="extra",
            email="extra@example.com",
            password="pass123"
        )
        
        membership = CommunityMembership(
            user=extra_user,
            community=self.community,
            status='active'
        )
        
        # Simular member_count actualizado
        self.community.member_count = 5
        self.community.save()
        
        with self.assertRaises(ValidationError):
            membership.clean()
