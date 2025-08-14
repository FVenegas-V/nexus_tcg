from rest_framework.generics import CreateAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from django.contrib.auth import authenticate, get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.db.models import Q
from django.shortcuts import get_object_or_404
from users.serializers import (
    RegisterSerializer, 
    PasswordResetRequestSerializer, 
    PasswordResetConfirmSerializer,
    EmailVerificationResendSerializer,
    EmailVerifySerializer,
    ChangePasswordSerializer,
    UserProfileSerializer,
    PublicUserProfileSerializer,
    UserSearchSerializer
)
from .models import PasswordResetToken, EmailVerificationToken

User = get_user_model()


class RegisterView(CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]  # Permitir registro sin autenticación
    
    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        return Response(
            {
                'username': user.username,
                'email': user.email
            },
            status=status.HTTP_201_CREATED
        )


class LoginView(APIView):
    permission_classes = [AllowAny]  # Permitir login sin autenticación previa
    
    def post(self, request, *args, **kwargs):
        username_or_email = request.data.get('username')
        password = request.data.get('password')
        
        # Validar que se proporcionen username y password
        if not username_or_email or not password:
            return Response(
                {'error': 'Se requieren username y password'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Intentar autenticar con email primero (ya que USERNAME_FIELD = 'email')
        user = authenticate(username=username_or_email, password=password)
        
        # Si falla y parece ser un username (no tiene @), buscar el email del usuario
        if user is None and '@' not in username_or_email:
            try:
                user_obj = User.objects.get(username=username_or_email)
                user = authenticate(username=user_obj.email, password=password)
            except User.DoesNotExist:
                pass
        
        if user is not None:
            # Usuario autenticado exitosamente
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                }
            }, status=status.HTTP_200_OK)
        else:
            # Credenciales inválidas
            return Response(
                {'error': 'Credenciales inválidas'},
                status=status.HTTP_401_UNAUTHORIZED
            )


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]  # Requiere JWT válido
    
    def get(self, request):
        """
        Devuelve información del perfil del usuario autenticado.
        Esta vista requiere un token JWT válido en el header Authorization.
        """
        user = request.user
        
        return Response({
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'date_joined': user.date_joined,
            'is_email_verified': user.email_verified,  # Campo para el frontend
            'is_active': user.is_active,
        }, status=status.HTTP_200_OK)
    
    def put(self, request):
        """
        Actualiza la información del perfil del usuario autenticado.
        Permite actualizar: first_name, last_name, email
        """
        user = request.user
        data = request.data
        
        # Validar que no se intente cambiar username o id
        if 'username' in data or 'id' in data:
            return Response({
                'error': 'No se puede modificar username o id'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validar email si se está actualizando
        if 'email' in data:
            email = data.get('email', '').strip()
            if email:
                # Verificar que el email no esté en uso por otro usuario
                if User.objects.filter(email=email).exclude(id=user.id).exists():
                    return Response({
                        'error': 'Este email ya está en uso por otro usuario'
                    }, status=status.HTTP_400_BAD_REQUEST)
                user.email = email
        
        # Actualizar nombres si se proporcionan
        if 'first_name' in data:
            user.first_name = data.get('first_name', '').strip()
        
        if 'last_name' in data:
            user.last_name = data.get('last_name', '').strip()
        
        try:
            # Guardar los cambios
            user.save()
            
            # Devolver datos actualizados
            return Response({
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'date_joined': user.date_joined,
                'is_email_verified': user.email_verified,  # Campo para el frontend
                'is_active': user.is_active,
                'message': 'Perfil actualizado exitosamente'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': f'Error al actualizar perfil: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PasswordResetRequestView(APIView):
    """
    Vista para solicitar recuperación de contraseña via email
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        user = User.objects.get(email=email)
        
        # Crear token de recuperación
        reset_token = PasswordResetToken.objects.create(user=user)
        
        # Enviar email con el token
        self.send_password_reset_email(user, reset_token)
        
        return Response({
            'message': 'Se ha enviado un enlace de recuperación a tu email.'
        }, status=status.HTTP_200_OK)
    
    def send_password_reset_email(self, user, reset_token):
        """
        Envía el email de recuperación de contraseña
        """
        subject = 'Nexus TCG - Recuperación de Contraseña'
        
        # URL para resetear la contraseña (esto sería manejado por el frontend)
        reset_url = f"http://localhost:3000/reset-password?token={reset_token.token}"
        
        # Contenido del email en HTML
        html_message = f"""
        <html>
        <body>
            <h2>Recuperación de Contraseña - Nexus TCG</h2>
            <p>Hola {user.username},</p>
            <p>Has solicitado recuperar tu contraseña. Haz clic en el siguiente enlace para crear una nueva contraseña:</p>
            <p><a href="{reset_url}" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Recuperar Contraseña</a></p>
            <p>Este enlace expirará en 1 hora.</p>
            <p>Si no solicitaste este cambio, puedes ignorar este email.</p>
            <p>Saludos,<br>El equipo de Nexus TCG</p>
        </body>
        </html>
        """
        
        # Contenido del email en texto plano
        plain_message = f"""
        Recuperación de Contraseña - Nexus TCG
        
        Hola {user.username},
        
        Has solicitado recuperar tu contraseña. Copia y pega el siguiente enlace en tu navegador para crear una nueva contraseña:
        
        {reset_url}
        
        Este enlace expirará en 1 hora.
        
        Si no solicitaste este cambio, puedes ignorar este email.
        
        Saludos,
        El equipo de Nexus TCG
        """
        
        try:
            send_mail(
                subject=subject,
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_message,
                fail_silently=False,
            )
        except Exception as e:
            # En desarrollo, mostrar el enlace en consola si falla el email
            if settings.DEBUG:
                print(f"Email de recuperación para {user.email}: {reset_url}")
                print(f"Token: {reset_token.token}")


class PasswordResetConfirmView(APIView):
    """
    Vista para confirmar el cambio de contraseña usando el token
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        token_value = serializer.validated_data['token']
        new_password = serializer.validated_data['new_password']
        
        try:
            # Buscar el token
            reset_token = PasswordResetToken.objects.get(token=token_value)
            
            # Verificar que el token sea válido
            if not reset_token.is_valid():
                return Response({
                    'error': 'El token ha expirado o ya fue usado.'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Cambiar la contraseña del usuario
            user = reset_token.user
            user.set_password(new_password)
            user.save()
            
            # Marcar el token como usado
            reset_token.mark_as_used()
            
            return Response({
                'message': 'Contraseña cambiada exitosamente.'
            }, status=status.HTTP_200_OK)
            
        except PasswordResetToken.DoesNotExist:
            return Response({
                'error': 'Token inválido.'
            }, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetVerifyTokenView(APIView):
    """
    Vista para verificar si un token de recuperación es válido
    """
    permission_classes = [AllowAny]
    
    def get(self, request, token):
        try:
            reset_token = PasswordResetToken.objects.get(token=token)
            
            if reset_token.is_valid():
                return Response({
                    'valid': True,
                    'user_email': reset_token.user.email
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'valid': False,
                    'error': 'El token ha expirado o ya fue usado.'
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except PasswordResetToken.DoesNotExist:
            return Response({
                'valid': False,
                'error': 'Token inválido.'
            }, status=status.HTTP_400_BAD_REQUEST)


class EmailVerificationView(APIView):
    """
    Vista para verificar email usando el token enviado
    """
    permission_classes = [AllowAny]
    
    def get(self, request, token):
        """Verificar email usando el token de la URL"""
        serializer = EmailVerifySerializer(data={'token': token})
        serializer.is_valid(raise_exception=True)
        
        token_value = serializer.validated_data['token']
        
        try:
            # Buscar el token
            verification_token = EmailVerificationToken.objects.get(token=token_value)
            
            # Verificar que el token sea válido
            if verification_token.is_valid():
                # Marcar token como usado y email como verificado
                verification_token.mark_as_used()
                
                return Response({
                    'success': True,
                    'message': 'Email verificado exitosamente',
                    'data': {
                        'user_id': verification_token.user.id,
                        'email': verification_token.user.email,
                        'verified_at': verification_token.used_at
                    }
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'error': 'El token ha expirado o ya fue usado.'
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except EmailVerificationToken.DoesNotExist:
            return Response({
                'success': False,
                'error': 'Token inválido.'
            }, status=status.HTTP_404_NOT_FOUND)


class EmailVerificationResendView(APIView):
    """
    Vista para reenviar email de verificación
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        """Reenviar email de verificación"""
        serializer = EmailVerificationResendSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        user = User.objects.get(email=email)
        
        # Eliminar token anterior si existe
        EmailVerificationToken.objects.filter(user=user).delete()
        
        # Crear nuevo token
        verification_token = EmailVerificationToken.objects.create(user=user)
        
        # Enviar email de verificación
        self._send_verification_email(user, verification_token)
        
        return Response({
            'success': True,
            'message': 'Email de verificación reenviado',
            'data': {
                'sent_to': user.email,
                'expires_at': verification_token.expires_at
            }
        }, status=status.HTTP_200_OK)
    
    def _send_verification_email(self, user, verification_token):
        """Enviar email de verificación"""
        # URL de verificación
        verification_url = f"{settings.FRONTEND_URL}/verify-email/{verification_token.token}/"
        
        # Asunto del email
        subject = "Nexus TCG - Verifica tu cuenta"
        
        # Mensaje HTML (similar al de password recovery)
        html_message = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Verifica tu cuenta - Nexus TCG</title>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #2c3e50; color: white; padding: 20px; text-align: center; }}
                .content {{ padding: 30px; background-color: #f8f9fa; }}
                .button {{ display: inline-block; padding: 12px 24px; background-color: #3498db; 
                          color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                .footer {{ padding: 20px; text-align: center; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Nexus TCG</h1>
                    <p>Verifica tu cuenta</p>
                </div>
                <div class="content">
                    <h2>¡Hola {user.username}!</h2>
                    
                    <p>Gracias por registrarte en Nexus TCG. Para completar tu registro y activar tu cuenta, necesitas verificar tu dirección de email.</p>
                    
                    <p>Haz clic en el siguiente botón para verificar tu cuenta:</p>
                    
                    <a href="{verification_url}" class="button">Verificar mi cuenta</a>
                    
                    <p>O copia y pega este enlace en tu navegador:</p>
                    <p style="word-break: break-all; background-color: #ecf0f1; padding: 10px; border-radius: 3px;">
                        {verification_url}
                    </p>
                    
                    <p><strong>Este enlace expirará en 24 horas.</strong></p>
                    
                    <p>Si no te registraste en Nexus TCG, puedes ignorar este email.</p>
                </div>
                <div class="footer">
                    <p>Nexus TCG - Conectando jugadores de Trading Card Games</p>
                    <p>Este email fue enviado automáticamente, por favor no respondas.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        # Mensaje de texto plano (fallback)
        plain_message = f"""
        Verificación de Cuenta - Nexus TCG
        
        Hola {user.username},
        
        Gracias por registrarte en Nexus TCG. Para completar tu registro, verifica tu email haciendo clic en el siguiente enlace:
        
        {verification_url}
        
        Este enlace expirará en 24 horas.
        
        Si no te registraste en Nexus TCG, puedes ignorar este email.
        
        Saludos,
        El equipo de Nexus TCG
        """
        
        try:
            send_mail(
                subject=subject,
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_message,
                fail_silently=False,
            )
        except Exception as e:
            # En desarrollo, mostrar el enlace en consola si falla el email
            if settings.DEBUG:
                print(f"Email de verificación para {user.email}: {verification_url}")
                print(f"Token: {verification_token.token}")


class ChangePasswordView(APIView):
    """Vista para cambio de contraseña de usuario autenticado"""
    permission_classes = [IsAuthenticated]
    
    def put(self, request):
        """Cambiar contraseña del usuario autenticado"""
        serializer = ChangePasswordSerializer(
            data=request.data,
            user=request.user
        )
        
        if serializer.is_valid():
            new_password = serializer.validated_data['new_password']
            
            # Cambiar la contraseña
            request.user.set_password(new_password)
            request.user.save()
            
            # Invalidar todos los tokens JWT existentes por seguridad
            self._invalidate_user_tokens(request.user)
            
            # Enviar email de confirmación
            self._send_password_changed_email(request.user)
            
            return Response({
                'success': True,
                'message': 'Contraseña actualizada exitosamente',
                'data': {
                    'user_id': request.user.id,
                    'email': request.user.email,
                    'changed_at': request.user.updated_at.isoformat(),
                    'tokens_invalidated': True,
                    'email_sent': True
                }
            }, status=status.HTTP_200_OK)
        
        else:
            return Response({
                'success': False,
                'message': 'Error en los datos proporcionados',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
    
    def _invalidate_user_tokens(self, user):
        """Invalida tokens JWT forzando actualización de updated_at"""
        user.save(update_fields=['updated_at'])
        print(f"🔒 Tokens JWT invalidados para usuario {user.username}")
    
    def _send_password_changed_email(self, user):
        """Envía email de confirmación de cambio de contraseña"""
        subject = 'Nexus TCG - Contraseña cambiada exitosamente'
        
        html_message = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #2c3e50;">Contraseña Cambiada Exitosamente</h2>
                
                <p>Hola <strong>{user.first_name or user.username}</strong>,</p>
                
                <p>Tu contraseña en <strong>Nexus TCG</strong> ha sido cambiada exitosamente.</p>
                
                <div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #28a745; margin: 20px 0;">
                    <p style="margin: 0;"><strong>Detalles del cambio:</strong></p>
                    <ul style="margin: 10px 0;">
                        <li>Fecha: {user.updated_at.strftime('%d/%m/%Y')}</li>
                        <li>Hora: {user.updated_at.strftime('%H:%M')} UTC</li>
                        <li>Usuario: {user.username}</li>
                    </ul>
                </div>
                
                <div style="background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0;">
                    <p style="margin: 0; font-weight: bold;">⚠️ Si NO realizaste este cambio:</p>
                    <ul style="margin: 10px 0;">
                        <li>Contacta inmediatamente a nuestro soporte</li>
                        <li>Revisa tu cuenta en busca de actividad sospechosa</li>
                        <li>Considera habilitar autenticación de dos factores</li>
                    </ul>
                </div>
                
                <p style="background-color: #e3f2fd; padding: 15px; border-radius: 5px;">
                    <strong>🔒 Por tu seguridad:</strong> Todos tus dispositivos han sido desconectados 
                    y necesitarás iniciar sesión nuevamente con tu nueva contraseña.
                </p>
                
                <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
                
                <p style="color: #666; font-size: 14px;">
                    Saludos,<br>
                    <strong>El equipo de Nexus TCG</strong>
                </p>
            </div>
        </body>
        </html>
        """
        
        # Versión texto plano (fallback)
        plain_message = f"""
        Hola {user.first_name or user.username},
        
        Tu contraseña en Nexus TCG ha sido cambiada exitosamente el {user.updated_at.strftime('%d/%m/%Y')} a las {user.updated_at.strftime('%H:%M')} UTC.
        
        Si no realizaste este cambio:
        - Contacta inmediatamente a soporte
        - Revisa tu cuenta en busca de actividad sospechosa
        
        Por tu seguridad, todos tus dispositivos han sido desconectados y necesitarás iniciar sesión nuevamente.
        
        Saludos,
        El equipo de Nexus TCG
        """
        
        try:
            send_mail(
                subject=subject,
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_message,
                fail_silently=False,
            )
            print(f"📧 Email de confirmación enviado a {user.email}")
        except Exception as e:
            print(f"❌ Error enviando email: {e}")
            # En producción, podrías querer loggear esto o usar un sistema de colas


# ===== VISTAS PARA PERFILES DE USUARIO =====

class UserProfileDetailView(APIView):
    """
    Vista para ver y actualizar el perfil del usuario autenticado
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """Obtiene el perfil completo del usuario autenticado"""
        try:
            profile = request.user.profile
            serializer = UserProfileSerializer(profile)
            return Response({
                'user': {
                    'id': request.user.id,
                    'username': request.user.username,
                    'first_name': request.user.first_name,
                    'last_name': request.user.last_name,
                    'email': request.user.email,
                    'email_verified': request.user.email_verified,
                    'created_at': request.user.created_at,
                },
                'profile': serializer.data
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': 'Error al obtener el perfil del usuario'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def put(self, request):
        """Actualiza el perfil del usuario autenticado"""
        try:
            profile = request.user.profile
            serializer = UserProfileSerializer(profile, data=request.data, partial=True)
            
            if serializer.is_valid():
                serializer.save()
                return Response({
                    'message': 'Perfil actualizado exitosamente',
                    'profile': serializer.data
                }, status=status.HTTP_200_OK)
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response(
                {'error': 'Error al actualizar el perfil'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class PublicUserProfileView(APIView):
    """
    Vista para ver el perfil público de cualquier usuario
    """
    permission_classes = [AllowAny]
    
    def get(self, request, user_id):
        """Obtiene el perfil público de un usuario específico"""
        try:
            user = get_object_or_404(User, id=user_id)
            profile = user.profile
            
            # Preparar datos básicos del usuario
            user_data = {
                'id': user.id,
                'username': user.username,
                'first_name': user.first_name,
                'last_name': user.last_name,
            }
            
            # Serializar perfil público respetando privacidad
            profile_serializer = PublicUserProfileSerializer(profile)
            
            # Obtener comunidades si el usuario permite mostrarlas
            communities_data = []
            if profile.show_communities and hasattr(user, 'memberships'):
                # TODO: Implementar cuando esté disponible el modelo de membresías
                # memberships = user.memberships.filter(is_active=True).select_related('community')
                # communities_data = [
                #     {
                #         'id': membership.community.id,
                #         'name': membership.community.name,
                #         'role': membership.role,
                #         'joined_at': membership.created_at
                #     }
                #     for membership in memberships
                # ]
                pass
            
            return Response({
                'user': user_data,
                'profile': profile_serializer.data,
                'communities': communities_data if profile.show_communities else None
            }, status=status.HTTP_200_OK)
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Usuario no encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': 'Error al obtener el perfil público'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@api_view(['GET'])
@permission_classes([AllowAny])
def search_users(request):
    """
    API para buscar usuarios públicos
    """
    try:
        # Parámetros de búsqueda
        query = request.GET.get('q', '').strip()
        game = request.GET.get('game', '').strip()
        location = request.GET.get('location', '').strip()
        play_style = request.GET.get('play_style', '').strip()
        experience_level = request.GET.get('experience_level', '').strip()
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))
        
        # Limitar page_size para evitar sobrecarga
        page_size = min(page_size, 50)
        
        # Construir queryset base
        users = User.objects.select_related('profile').filter(
            profile__isnull=False
        )
        
        # Aplicar filtros de búsqueda
        if query:
            users = users.filter(
                Q(username__icontains=query) |
                Q(first_name__icontains=query) |
                Q(last_name__icontains=query)
            )
        
        if game:
            users = users.filter(profile__favorite_games__contains=[game])
        
        if location:
            users = users.filter(
                profile__location__icontains=location,
                profile__show_location=True
            )
        
        if play_style:
            users = users.filter(profile__play_style=play_style)
        
        if experience_level:
            users = users.filter(profile__experience_level=experience_level)
        
        # Paginación manual
        total_count = users.count()
        start = (page - 1) * page_size
        end = start + page_size
        users_page = users[start:end]
        
        # Serializar resultados
        serializer = UserSearchSerializer(users_page, many=True)
        
        return Response({
            'count': total_count,
            'page': page,
            'page_size': page_size,
            'total_pages': (total_count + page_size - 1) // page_size,
            'results': serializer.data
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response(
            {'error': 'Parámetros de paginación inválidos'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    except Exception as e:
        return Response(
            {'error': 'Error en la búsqueda de usuarios'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_profile_stats(request):
    """
    API para actualizar estadísticas del perfil manualmente
    (útil para debugging o sincronización)
    """
    try:
        profile = request.user.profile
        
        # Actualizar contadores
        if hasattr(request.user, 'memberships'):
            profile.communities_count = request.user.memberships.filter(is_active=True).count()
        
        # TODO: Implementar cuando estén disponibles los modelos
        # if hasattr(request.user, 'posts'):
        #     profile.posts_count = request.user.posts.count()
        #     profile.likes_received = sum(post.likes.count() for post in request.user.posts.all())
        
        profile.save()
        
        return Response({
            'message': 'Estadísticas actualizadas exitosamente',
            'stats': {
                'communities_count': profile.communities_count,
                'posts_count': profile.posts_count,
                'likes_received': profile.likes_received,
                'reputation_score': profile.reputation_score,
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': 'Error al actualizar estadísticas'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
