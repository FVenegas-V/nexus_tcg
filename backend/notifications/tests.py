"""
Tests para el sistema de notificaciones MVP
Implementación para fase5-0001: Testing Backend
"""

from django.test import TestCase, override_settings
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Notification, NotificationPreferences

User = get_user_model()


@override_settings(CELERY_TASK_ALWAYS_EAGER=True)  # Para tests síncronos


class NotificationModelTest(TestCase):
    """Tests para el modelo Notification"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_notification(self):
        """Test crear notificación básica"""
        notification = Notification.create_notification(
            user=self.user,
            notification_type='NEW_POST',
            title='Test Notification',
            message='This is a test notification'
        )
        
        self.assertEqual(notification.user, self.user)
        self.assertEqual(notification.type, 'NEW_POST')
        self.assertEqual(notification.title, 'Test Notification')
        self.assertFalse(notification.is_read)
        self.assertEqual(notification.priority, 'NORMAL')
    
    def test_mark_as_read(self):
        """Test marcar notificación como leída"""
        notification = Notification.create_notification(
            user=self.user,
            notification_type='NEW_COMMENT',
            title='Test',
            message='Test message'
        )
        
        self.assertFalse(notification.is_read)
        self.assertIsNone(notification.read_at)
        
        notification.mark_as_read()
        
        self.assertTrue(notification.is_read)
        self.assertIsNotNone(notification.read_at)
    
    def test_get_unread_for_user(self):
        """Test obtener notificaciones no leídas"""
        # Crear varias notificaciones
        for i in range(7):
            Notification.create_notification(
                user=self.user,
                notification_type='NEW_POST',
                title=f'Notification {i}',
                message=f'Message {i}'
            )
        
        # Marcar algunas como leídas
        notifications = Notification.objects.filter(user=self.user)[:3]
        for notif in notifications:
            notif.mark_as_read()
        
        # Obtener no leídas (límite 5)
        unread = Notification.get_unread_for_user(self.user, limit=5)
        
        self.assertEqual(len(unread), 4)  # 7 - 3 leídas = 4 no leídas
        for notif in unread:
            self.assertFalse(notif.is_read)


class NotificationPreferencesModelTest(TestCase):
    """Tests para el modelo NotificationPreferences"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
    
    def test_create_preferences(self):
        """Test crear preferencias por defecto"""
        # Obtener preferencias existentes (creadas por signal) o crear nuevas
        prefs, created = NotificationPreferences.objects.get_or_create(
            user=self.user
        )
        
        # Verificar valores por defecto
        self.assertTrue(prefs.app_new_posts)
        self.assertTrue(prefs.app_new_comments)
        self.assertTrue(prefs.email_new_ratings)
        self.assertEqual(prefs.summary_frequency, 'weekly')
    
    def test_allows_notification_type(self):
        """Test verificar si permite tipo de notificación"""
        # Obtener preferencias existentes o crear nuevas
        prefs, created = NotificationPreferences.objects.get_or_create(
            user=self.user
        )
        
        # Por defecto permite todas
        self.assertTrue(prefs.allows_notification_type('NEW_POST'))
        self.assertTrue(prefs.allows_notification_type('NEW_COMMENT'))
        
        # Desactivar posts
        prefs.app_new_posts = False
        prefs.save()
        
        self.assertFalse(prefs.allows_notification_type('NEW_POST'))
        self.assertTrue(prefs.allows_notification_type('NEW_COMMENT'))


class NotificationAPITest(APITestCase):
    """Tests para las APIs de notificaciones"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com', 
            password='testpass123'
        )
        
        # Autenticación JWT
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
        
        # Crear algunas notificaciones de test
        for i in range(3):
            Notification.create_notification(
                user=self.user,
                notification_type='NEW_POST',
                title=f'Test Notification {i}',
                message=f'Test message {i}'
            )
    
    def test_list_notifications(self):
        """Test listar notificaciones"""
        url = reverse('notification-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 3)
    
    def test_unread_notifications(self):
        """Test endpoint de polling para no leídas"""
        url = reverse('notification-unread')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 3)
        self.assertEqual(len(response.data['latest']), 3)
        self.assertIn('last_check', response.data)
    
    def test_mark_notification_read(self):
        """Test marcar notificación como leída"""
        notification = Notification.objects.filter(user=self.user).first()
        url = reverse('notification-mark-read', kwargs={'pk': notification.id})
        
        response = self.client.put(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verificar que se marcó como leída
        notification.refresh_from_db()
        self.assertTrue(notification.is_read)
    
    def test_mark_all_read(self):
        """Test marcar todas como leídas"""
        url = reverse('notification-mark-all-read')
        response = self.client.put(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['updated_count'], 3)
        
        # Verificar que todas están leídas
        unread_count = Notification.objects.filter(
            user=self.user,
            is_read=False
        ).count()
        self.assertEqual(unread_count, 0)
    
    def test_notification_stats(self):
        """Test estadísticas de notificaciones"""
        url = reverse('notification-stats')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['total_unread'], 3)
        self.assertEqual(response.data['total_notifications'], 3)
        self.assertIn('unread_by_type', response.data)
    
    def test_notification_count_endpoint(self):
        """Test endpoint ligero de contador"""
        url = reverse('notification-count')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['unread_count'], 3)
    
    def test_unauthenticated_access(self):
        """Test que endpoints requieren autenticación"""
        self.client.credentials()  # Remover autenticación
        
        url = reverse('notification-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class NotificationPreferencesAPITest(APITestCase):
    """Tests para las APIs de preferencias"""
    
    def setUp(self):
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # Autenticación JWT
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')
    
    def test_get_preferences(self):
        """Test obtener preferencias (crear si no existen)"""
        url = reverse('notification-preferences-list')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['app_new_posts'])
        self.assertEqual(response.data['summary_frequency'], 'weekly')
        
        # Verificar que se creó el objeto
        self.assertTrue(
            NotificationPreferences.objects.filter(user=self.user).exists()
        )
    
    def test_update_preferences(self):
        """Test actualizar preferencias"""
        url = reverse('notification-preferences-list')
        
        data = {
            'app_new_posts': False,
            'email_new_ratings': False,
            'summary_frequency': 'daily'
        }
        
        response = self.client.put(url, data)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['app_new_posts'])
        self.assertFalse(response.data['email_new_ratings'])
        self.assertEqual(response.data['summary_frequency'], 'daily')
    
    def test_reset_to_defaults(self):
        """Test restaurar preferencias por defecto"""
        # Obtener preferencias existentes o crear nuevas
        prefs, created = NotificationPreferences.objects.get_or_create(
            user=self.user
        )
        
        # Modificar preferencias
        prefs.app_new_posts = False
        prefs.summary_frequency = 'never'
        prefs.save()
        
        url = reverse('notification-preferences-reset-to-defaults')
        response = self.client.post(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verificar que se restauraron los defaults
        prefs.refresh_from_db()
        self.assertTrue(prefs.app_new_posts)
        self.assertEqual(prefs.summary_frequency, 'weekly')


class NotificationSignalsTest(TestCase):
    """Tests para los signals automáticos"""
    
    def setUp(self):
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@example.com',
            password='testpass123'
        )
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@example.com', 
            password='testpass123'
        )
    
    def test_notification_preferences_created_for_new_user(self):
        """Test que se crean preferencias automáticamente para nuevos usuarios"""
        new_user = User.objects.create_user(
            username='newuser',
            email='new@example.com',
            password='testpass123'
        )
        
        # Verificar que se crearon las preferencias
        self.assertTrue(
            NotificationPreferences.objects.filter(user=new_user).exists()
        )
        
        prefs = new_user.notification_preferences
        self.assertTrue(prefs.app_new_posts)  # Valor por defecto
