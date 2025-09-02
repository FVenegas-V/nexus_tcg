# notifications/tests/test_basic_email.py
"""
Tests básicos para verificar el email service
"""

from django.test import TestCase
from django.contrib.auth import get_user_model
from django.core import mail

from ..models import Notification, NotificationPreferences

User = get_user_model()


class BasicEmailTest(TestCase):
    """Test básico del sistema de emails"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123',
            email_verified=True
        )
        
    def test_notification_creation(self):
        """Test básico: crear notificación"""
        notification = Notification.objects.create(
            user=self.user,
            type='NEW_POST',
            title='Test Title',
            message='Test message'
        )
        
        self.assertEqual(notification.user, self.user)
        self.assertEqual(notification.type, 'NEW_POST')
        self.assertFalse(notification.email_sent)
        
    def test_notification_preferences_exist(self):
        """Test: preferencias se crean automáticamente"""
        prefs = NotificationPreferences.objects.get(user=self.user)
        self.assertTrue(prefs.email_enabled)
        
    def test_import_email_service(self):
        """Test: verificar que se puede importar el email service"""
        try:
            from ..email_service import NotificationEmailService
            self.assertTrue(True)
        except ImportError:
            self.fail("No se pudo importar NotificationEmailService")
