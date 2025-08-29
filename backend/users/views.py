from rest_framework.generics import CreateAPIView
from rest_framework.response import Response
from rest_framework import status, viewsets
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import api_view, permission_classes, action
from django.contrib.auth import authenticate, get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings
from django.shortcuts import render, redirect
from django.contrib import messages
from django.views import View
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.utils import timezone
from django.utils import timezone
from django.db.models import Q
from django.shortcuts import get_object_or_404
from datetime import timedelta
from users.serializers import (
    RegisterSerializer, 
    PasswordResetRequestSerializer, 
    PasswordResetConfirmSerializer,
    EmailVerificationResendSerializer,
    EmailVerifySerializer,
    ChangePasswordSerializer,
    UserProfileSerializer,
    PublicUserProfileSerializer,
    UserSearchSerializer,
    UserPublicProfileDetailSerializer
)
from .models import PasswordResetToken, EmailVerificationToken, UserProfile, RatingFlag

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
        Envía el email de recuperación de contraseña usando template HTML profesional
        """
        subject = 'Nexus TCG - Recuperación de Contraseña'
        
        # URL para resetear la contraseña (vista web de Django)
        reset_url = f"http://127.0.0.1:8000/api/auth/password-reset/{reset_token.token}/"
        
        # Contexto para el template
        context = {
            'user': user,
            'reset_url': reset_url,
            'app_name': 'Nexus TCG'
        }
        
        # Renderizar el template HTML
        html_message = render_to_string('emails/password_reset.html', context)
        
        # Contenido del email en texto plano (fallback)
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


class PasswordResetWebView(View):
    """
    Vista web para el reset de contraseña desde el navegador
    """
    template_name = 'reset_password.html'
    
    def get(self, request, token):
        """Mostrar el formulario de reset de contraseña"""
        try:
            reset_token = PasswordResetToken.objects.get(token=token)
            
            if reset_token.is_valid():
                context = {
                    'token': token,
                    'user_email': reset_token.user.email,
                    'valid': True
                }
                return render(request, self.template_name, context)
            else:
                context = {
                    'valid': False,
                    'error': 'El token ha expirado o ya fue usado.'
                }
                return render(request, self.template_name, context)
                
        except PasswordResetToken.DoesNotExist:
            context = {
                'valid': False,
                'error': 'Token inválido.'
            }
            return render(request, self.template_name, context)
    
    def post(self, request, token):
        """Procesar el formulario de reset de contraseña"""
        try:
            reset_token = PasswordResetToken.objects.get(token=token)
            
            if not reset_token.is_valid():
                messages.error(request, 'El token ha expirado o ya fue usado.')
                return redirect('password_reset_web', token=token)
            
            new_password = request.POST.get('new_password')
            confirm_password = request.POST.get('confirm_password')
            
            # Validaciones
            if not new_password or not confirm_password:
                messages.error(request, 'Todos los campos son requeridos.')
                return redirect('password_reset_web', token=token)
            
            if new_password != confirm_password:
                messages.error(request, 'Las contraseñas no coinciden.')
                return redirect('password_reset_web', token=token)
            
            if len(new_password) < 8:
                messages.error(request, 'La contraseña debe tener al menos 8 caracteres.')
                return redirect('password_reset_web', token=token)
            
            # Cambiar la contraseña
            user = reset_token.user
            user.set_password(new_password)
            user.save()
            
            # Marcar el token como usado
            reset_token.is_used = True
            reset_token.save()
            
            # Mensaje de éxito
            context = {
                'success': True,
                'message': 'Tu contraseña ha sido cambiada exitosamente. Ya puedes iniciar sesión en la aplicación con tu nueva contraseña.'
            }
            return render(request, self.template_name, context)
            
        except PasswordResetToken.DoesNotExist:
            messages.error(request, 'Token inválido.')
            return redirect('password_reset_web', token=token)


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
        """Enviar email de verificación usando template profesional"""
        # URL de verificación
        verification_url = f"{settings.FRONTEND_URL}/verify-email/{verification_token.token}/"
        
        # Asunto del email
        subject = "Nexus TCG - Verifica tu cuenta"
        
        # Contexto para el template
        context = {
            'user': user,
            'verification_url': verification_url,
            'verification_token': verification_token,
        }
        
        # Renderizar template HTML
        html_message = render_to_string('emails/email_verification.html', context)
        
        # Mensaje de texto plano (fallback)
        plain_message = f"""
        Verificación de Cuenta - Nexus TCG
        
        Hola {user.first_name or user.username},
        
        ¡Gracias por unirte a Nexus TCG! Estamos emocionados de tenerte en nuestra comunidad de jugadores de Trading Card Games.
        
        Para completar tu registro y comenzar a explorar comunidades, crear posts y conectar con otros jugadores, necesitamos verificar tu dirección de email:
        
        {verification_url}
        
        Este enlace expira en 1 hora por seguridad.
        
        Si no creaste esta cuenta, puedes ignorar este email de forma segura.
        
        ¡Esperamos verte pronto en Nexus TCG!
        
        El equipo de Nexus TCG
        Conectando jugadores de TCG
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


# ================================
# FASE 4: PERFILES PÚBLICOS
# ================================

from rest_framework import viewsets
from rest_framework.decorators import action
from django.db.models import Count, Prefetch
from communities.models import CommunityMembership, Post


class UserProfileViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para ver perfiles públicos de usuarios.
    Proporciona endpoints para ver información del perfil, actividad y relaciones.
    """
    
    def get_queryset(self):
        """
        Optimiza consultas con select_related y prefetch_related
        """
        return UserProfile.objects.select_related(
            'user'
        ).prefetch_related(
            'user__authored_posts__community',
            'user__memberships__community'
        ).all()
    
    def get_object(self):
        """
        Obtiene el perfil de usuario
        Los perfiles son públicos por defecto, pero respetan configuraciones de privacidad
        """
        user_id = self.kwargs.get('pk')
        profile = get_object_or_404(UserProfile, user_id=user_id)
        
        # Los perfiles son públicos por defecto
        # Las configuraciones de privacidad se respetan en el serializer
        return profile
    
    def retrieve(self, request, *args, **kwargs):
        """
        Endpoint principal para obtener perfil público completo
        GET /api/users/profiles/{user_id}/
        """
        profile = self.get_object()
        serializer = UserPublicProfileDetailSerializer(profile)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def activity(self, request, pk=None):
        """
        Endpoint para obtener actividad reciente del usuario
        GET /api/users/profiles/{user_id}/activity/
        """
        profile = self.get_object()
        
        # Obtener posts recientes con información de comunidad
        recent_posts = []
        if hasattr(profile.user, 'authored_posts'):
            posts = profile.user.authored_posts.select_related('community').all()[:10]
            recent_posts = [{
                'id': post.id,
                'title': post.title or post.content[:50] + "..." if len(post.content) > 50 else post.content,
                'created_at': post.created_at,
                'community': {
                    'id': post.community.id,
                    'name': post.community.name
                } if post.community else None
            } for post in posts]
        
        return Response({
            'stats': {
                'communities_count': profile.communities_count,
                'posts_count': profile.posts_count,
                'likes_received': profile.likes_received,
                'reputation_score': profile.reputation_score,
            },
            'recent_posts': recent_posts
        })
    
    @action(detail=True, methods=['get'])
    def communities(self, request, pk=None):
        """
        Endpoint para obtener comunidades del usuario
        GET /api/users/profiles/{user_id}/communities/
        """
        profile = self.get_object()
        
        # Obtener membresías con información de comunidades  
        memberships = []
        if hasattr(profile.user, 'memberships'):
            user_memberships = profile.user.memberships.select_related('community').all()[:20]
            memberships = [{
                'id': membership.community.id,
                'name': membership.community.name,
                'description': membership.community.description,
                'role': membership.role,
                'joined_at': membership.joined_at,
                'is_active': membership.is_active
            } for membership in user_memberships]
        
        return Response({
            'communities': memberships,
            'total_count': profile.communities_count
        })
    
    @action(detail=True, methods=['get'])
    def posts(self, request, pk=None):
        """
        Endpoint para obtener posts del usuario
        GET /api/users/profiles/{user_id}/posts/
        """
        profile = self.get_object()
        
        # Paginación básica
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 10))
        offset = (page - 1) * page_size
        
        # Obtener posts con información de comunidad
        user_posts = []
        if hasattr(profile.user, 'authored_posts'):
            posts = profile.user.authored_posts.select_related('community').all()
            total_posts = posts.count()
            posts_page = posts[offset:offset + page_size]
            
            user_posts = [{
                'id': post.id,
                'title': post.title,
                'content': post.content[:200] + "..." if len(post.content) > 200 else post.content,
                'created_at': post.created_at,
                'likes_count': getattr(post, 'likes_count', 0),
                'comments_count': getattr(post, 'comments_count', 0),
                'community': {
                    'id': post.community.id,
                    'name': post.community.name
                } if post.community else None
            } for post in posts_page]
        else:
            total_posts = 0
        
        return Response({
            'posts': user_posts,
            'pagination': {
                'current_page': page,
                'page_size': page_size,
                'total_posts': total_posts,
                'total_pages': (total_posts + page_size - 1) // page_size
            }
        })


# ================================
# FASE 4.2: SISTEMA DE VALORACIONES
# ================================

from .models import UserRating
from .serializers import (
    UserRatingSerializer,
    UserRatingCreateSerializer, 
    UserRatingDetailSerializer,
    UserRatingStatsSerializer
)
from rest_framework.permissions import IsAuthenticated
from .permissions import IsRatingModerator, IsModeratorOrAdmin
from django.db.models import Avg, Count


class UserRatingViewSet(viewsets.ModelViewSet):
    """
    ViewSet para el sistema de valoraciones entre usuarios.
    Proporciona endpoints para valorar usuarios, ver valoraciones y estadísticas.
    """
    
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Filtrar valoraciones según la acción
        """
        queryset = UserRating.objects.filter(is_active=True).select_related(
            'rater', 'rated_user', 'rater__profile', 'rated_user__profile'
        )
        
        # Filtrar según el contexto
        if self.action in ['received_ratings', 'stats']:
            # Para valoraciones recibidas, filtrar por usuario valorado
            user_id = self.kwargs.get('pk') or self.request.user.id
            return queryset.filter(rated_user_id=user_id)
        elif self.action == 'my_ratings':
            # Para mis valoraciones, filtrar por usuario que valora
            return queryset.filter(rater=self.request.user)
        
        return queryset
    
    def get_serializer_class(self):
        """
        Retorna el serializer apropiado según la acción
        """
        if self.action == 'create' or self.action == 'rate_user':
            return UserRatingCreateSerializer
        elif self.action in ['received_ratings', 'my_ratings']:
            return UserRatingDetailSerializer
        elif self.action == 'stats':
            return UserRatingStatsSerializer
        else:
            return UserRatingSerializer
    
    def create(self, request, *args, **kwargs):
        """
        No se usa directamente, se redirecciona a rate_user
        """
        return Response(
            {'detail': 'Use el endpoint rate-user para crear valoraciones'}, 
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
    
    @action(detail=False, methods=['post'])
    def rate_user(self, request):
        """
        Endpoint para valorar a un usuario
        POST /api/users/ratings/rate-user/
        
        Body esperado:
        {
            "rated_user": 123,
            "rating": 5,
            "comment": "Excelente usuario",
            "interaction_type": "trade",
            "interaction_reference": "post_456"
        }
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Verificar que el usuario valorado existe
        rated_user_id = serializer.validated_data['rated_user'].id
        try:
            rated_user = User.objects.get(id=rated_user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'Usuario no encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Crear la valoración
        rating = serializer.save()
        
        # Devolver la valoración creada con detalles
        detail_serializer = UserRatingDetailSerializer(rating)
        
        return Response(
            {
                'message': f'Valoración de {rating.rating} estrellas creada exitosamente',
                'rating': detail_serializer.data
            },
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['get'])
    def received_ratings(self, request, pk=None):
        """
        Endpoint para obtener valoraciones recibidas por un usuario
        GET /api/users/ratings/{user_id}/received-ratings/
        """
        try:
            user = User.objects.get(id=pk)
        except User.DoesNotExist:
            return Response(
                {'error': 'Usuario no encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Paginación
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 10))
        offset = (page - 1) * page_size
        
        # Filtros opcionales
        rating_filter = request.query_params.get('rating')
        interaction_type = request.query_params.get('interaction_type')
        
        queryset = self.get_queryset()
        
        if rating_filter:
            queryset = queryset.filter(rating=rating_filter)
        if interaction_type:
            queryset = queryset.filter(interaction_type=interaction_type)
        
        # Ordenar por fecha (más recientes primero)
        queryset = queryset.order_by('-created_at')
        
        total_ratings = queryset.count()
        ratings_page = queryset[offset:offset + page_size]
        
        serializer = self.get_serializer(ratings_page, many=True)
        
        return Response({
            'ratings': serializer.data,
            'pagination': {
                'current_page': page,
                'page_size': page_size,
                'total_ratings': total_ratings,
                'total_pages': (total_ratings + page_size - 1) // page_size
            }
        })
    
    @action(detail=False, methods=['get'])
    def my_ratings(self, request):
        """
        Endpoint para obtener valoraciones que el usuario actual ha dado
        GET /api/users/ratings/my-ratings/
        """
        # Paginación
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 10))
        offset = (page - 1) * page_size
        
        # Filtros opcionales
        rating_filter = request.query_params.get('rating')
        interaction_type = request.query_params.get('interaction_type')
        
        queryset = self.get_queryset()
        
        if rating_filter:
            queryset = queryset.filter(rating=rating_filter)
        if interaction_type:
            queryset = queryset.filter(interaction_type=interaction_type)
        
        # Ordenar por fecha (más recientes primero)
        queryset = queryset.order_by('-created_at')
        
        total_ratings = queryset.count()
        ratings_page = queryset[offset:offset + page_size]
        
        serializer = self.get_serializer(ratings_page, many=True)
        
        return Response({
            'ratings': serializer.data,
            'pagination': {
                'current_page': page,
                'page_size': page_size,
                'total_ratings': total_ratings,
                'total_pages': (total_ratings + page_size - 1) // page_size
            }
        })
    
    @action(detail=True, methods=['get'])
    def stats(self, request, pk=None):
        """
        Endpoint para obtener estadísticas de valoraciones de un usuario
        GET /api/users/ratings/{user_id}/stats/
        """
        try:
            user = User.objects.get(id=pk)
        except User.DoesNotExist:
            return Response(
                {'error': 'Usuario no encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Obtener resumen de valoraciones usando el método del modelo
        summary = UserRating.get_user_rating_summary(user)
        
        # Obtener valoraciones recientes (últimas 5)
        recent_ratings = UserRating.objects.filter(
            rated_user=user, 
            is_active=True
        ).select_related(
            'rater', 'rater__profile'
        ).order_by('-created_at')[:5]
        
        # Serializar valoraciones recientes
        recent_serializer = UserRatingDetailSerializer(recent_ratings, many=True)
        
        # Preparar datos para el serializer de estadísticas
        stats_data = {
            'total_ratings': summary['total_ratings'],
            'average_rating': summary['average_rating'],
            'rating_distribution': summary['rating_distribution'],
            'recent_ratings': recent_ratings
        }
        
        serializer = self.get_serializer(stats_data)
        
        return Response({
            'user': {
                'id': user.id,
                'username': user.username
            },
            'stats': serializer.data
        })
    
    def update(self, request, *args, **kwargs):
        """
        Actualizar una valoración existente
        Solo el usuario que creó la valoración puede actualizarla
        """
        instance = self.get_object()
        
        # Verificar que el usuario actual es quien creó la valoración
        if instance.rater != request.user:
            return Response(
                {'error': 'Solo puedes modificar tus propias valoraciones'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        
        updated_rating = serializer.save()
        
        # Devolver la valoración actualizada con detalles
        detail_serializer = UserRatingDetailSerializer(updated_rating)
        
        return Response({
            'message': 'Valoración actualizada exitosamente',
            'rating': detail_serializer.data
        })
    
    def destroy(self, request, *args, **kwargs):
        """
        Eliminar (soft delete) una valoración
        Solo el usuario que creó la valoración puede eliminarla
        """
        instance = self.get_object()
        
        # Verificar que el usuario actual es quien creó la valoración
        if instance.rater != request.user:
            return Response(
                {'error': 'Solo puedes eliminar tus propias valoraciones'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Soft delete
        instance.soft_delete()
        
        return Response(
            {'message': 'Valoración eliminada exitosamente'}, 
            status=status.HTTP_200_OK
        )


# ======================================
# REPUTATION ENDPOINTS
# ======================================

class UserReputationViewSet(viewsets.ViewSet):
    """
    ViewSet para gestionar endpoints relacionados con reputación de usuarios.
    Proporciona estadísticas, desglose detallado y operaciones de mantenimiento.
    """
    permission_classes = [IsAuthenticated]

    @action(detail=True, methods=['get'], url_path='reputation-stats')
    def get_reputation_stats(self, request, pk=None):
        """
        Obtiene las estadísticas de reputación de un usuario específico.
        
        GET /api/users/{user_id}/reputation-stats/
        """
        try:
            user = get_object_or_404(User, pk=pk)
            
            from .reputation import get_reputation_breakdown
            breakdown = get_reputation_breakdown(user, include_ratings=True)
            
            # Estadísticas básicas
            stats = {
                'user': {
                    'id': user.id,
                    'username': user.username
                },
                'reputation': {
                    'score': breakdown['final_score'],
                    'rating_count': breakdown['rating_count'],  # Usar rating_count, no total_ratings
                    'percentile': self._calculate_percentile(user),
                    'last_updated': user.updated_at.isoformat() if hasattr(user, 'updated_at') else None,
                },
                'breakdown': breakdown['breakdown']
            }
            
            # Si es el propio usuario o admin, mostrar más detalles
            if request.user == user or request.user.is_staff:
                if 'ratings_detail' in breakdown['breakdown']:
                    stats['detailed_breakdown'] = {
                        'ratings_data': breakdown['breakdown']['ratings_detail'][:20]  # Últimas 20
                    }
            
            return Response(stats)
            
        except Exception as e:
            return Response(
                {'error': f'Error obteniendo estadísticas de reputación: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'], url_path='recalculate-reputation')
    def recalculate_reputation(self, request, pk=None):
        """
        Recalcula la reputación de un usuario específico.
        Solo disponible para administradores.
        
        POST /api/users/{user_id}/recalculate-reputation/
        """
        if not request.user.is_staff:
            return Response(
                {'error': 'Solo los administradores pueden recalcular reputaciones'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            user = get_object_or_404(User, pk=pk)
            
            # Obtener valores actuales
            old_score = user.reputation_score or 0
            old_count = user.reputation_count or 0
            
            # Recalcular
            from .reputation import update_user_reputation_sync
            new_score, new_count = update_user_reputation_sync(user)
            
            return Response({
                'message': 'Reputación recalculada exitosamente',
                'user': {
                    'id': user.id,
                    'username': user.username
                },
                'changes': {
                    'old_score': float(old_score),
                    'new_score': float(new_score),
                    'old_count': old_count,
                    'new_count': new_count,
                    'score_change': float(new_score - old_score)
                },
                'recalculated_at': timezone.now()
            })
            
        except Exception as e:
            return Response(
                {'error': f'Error recalculando reputación: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'], url_path='system-stats')
    def get_system_stats(self, request):
        """
        Obtiene estadísticas generales del sistema de reputación.
        Solo disponible para administradores.
        
        GET /api/users/reputation/system-stats/
        """
        if not request.user.is_staff:
            return Response(
                {'error': 'Solo los administradores pueden ver estadísticas del sistema'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            from django.db.models import Avg, Max, Min, Count
            
            # Estadísticas básicas
            total_users = User.objects.count()
            users_with_reputation = User.objects.filter(
                reputation_score__isnull=False
            ).count()
            users_with_ratings = User.objects.filter(
                ratings_received__is_active=True
            ).distinct().count()
            
            # Estadísticas de reputación
            reputation_stats = User.objects.filter(
                reputation_score__isnull=False
            ).aggregate(
                avg_score=Avg('reputation_score'),
                max_score=Max('reputation_score'),
                min_score=Min('reputation_score'),
                total_with_score=Count('id')
            )
            
            # Distribución por rangos
            ranges = [
                (0, 1, "Muy Baja"),
                (1, 2, "Baja"),
                (2, 3, "Media"),
                (3, 4, "Alta"),
                (4, 5, "Muy Alta")
            ]
            
            distribution = []
            for min_val, max_val, label in ranges:
                count = User.objects.filter(
                    reputation_score__gte=min_val,
                    reputation_score__lt=max_val
                ).count()
                percentage = (count / users_with_reputation * 100) if users_with_reputation > 0 else 0
                distribution.append({
                    'range': f"{min_val}-{max_val}",
                    'label': label,
                    'count': count,
                    'percentage': round(percentage, 1)
                })
            
            # Top usuarios por reputación
            top_users = User.objects.filter(
                reputation_score__isnull=False
            ).order_by('-reputation_score')[:10].values(
                'id', 'username', 'reputation_score', 'reputation_count'
            )
            
            return Response({
                'system_overview': {
                    'total_users': total_users,
                    'users_with_reputation': users_with_reputation,
                    'users_with_ratings': users_with_ratings,
                    'coverage_percentage': round(
                        (users_with_reputation / total_users * 100) if total_users > 0 else 0, 1
                    )
                },
                'reputation_statistics': {
                    'average': round(float(reputation_stats['avg_score'] or 0), 3),
                    'maximum': round(float(reputation_stats['max_score'] or 0), 3),
                    'minimum': round(float(reputation_stats['min_score'] or 0), 3),
                    'total_scored': reputation_stats['total_with_score']
                },
                'distribution': distribution,
                'top_users': list(top_users),
                'generated_at': timezone.now()
            })
            
        except Exception as e:
            return Response(
                {'error': f'Error obteniendo estadísticas del sistema: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'], url_path='validate-consistency')
    def validate_consistency(self, request):
        """
        Valida la consistencia de las reputaciones en el sistema.
        Solo disponible para administradores.
        
        POST /api/users/reputation/validate-consistency/
        """
        if not request.user.is_staff:
            return Response(
                {'error': 'Solo los administradores pueden validar consistencia'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            # Opción de ejecutar asíncronamente
            run_async = request.data.get('async', False)
            
            if run_async:
                from .tasks import validate_reputation_consistency_task
                task = validate_reputation_consistency_task.delay()
                
                return Response({
                    'message': 'Validación de consistencia iniciada en background',
                    'task_id': task.id,
                    'status': 'PENDING',
                    'check_url': f'/api/tasks/{task.id}/status/'
                })
            else:
                # Ejecutar síncronamente (para sistemas pequeños)
                from .reputation import validate_reputation_consistency
                
                batch_size = request.data.get('batch_size', 100)
                report = validate_reputation_consistency(batch_size)
                
                return Response({
                    'message': 'Validación de consistencia completada',
                    'report': report
                })
                
        except Exception as e:
            return Response(
                {'error': f'Error validando consistencia: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'], url_path='bulk-recalculate')
    def bulk_recalculate(self, request):
        """
        Recalcula reputaciones en lote.
        Solo disponible para administradores.
        
        POST /api/users/reputation/bulk-recalculate/
        Body: {
            "user_ids": [1, 2, 3],  // Opcional, si no se proporciona recalcula todos
            "async": true,          // Opcional, ejecutar en background
            "batch_size": 50        // Opcional, tamaño del lote
        }
        """
        if not request.user.is_staff:
            return Response(
                {'error': 'Solo los administradores pueden realizar recálculos masivos'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            user_ids = request.data.get('user_ids', [])
            run_async = request.data.get('async', True)  # Por defecto asíncrono
            batch_size = request.data.get('batch_size', 50)
            
            # Si no se proporcionan IDs, obtener todos los usuarios con valoraciones
            if not user_ids:
                user_ids = list(User.objects.filter(
                    ratings_received__is_active=True
                ).distinct().values_list('id', flat=True))
            
            if not user_ids:
                return Response(
                    {'message': 'No hay usuarios con valoraciones para recalcular'},
                    status=status.HTTP_200_OK
                )
            
            if run_async:
                from .tasks import bulk_update_reputations_task
                task = bulk_update_reputations_task.delay(user_ids, batch_size)
                
                return Response({
                    'message': f'Recálculo masivo iniciado para {len(user_ids)} usuarios',
                    'task_id': task.id,
                    'total_users': len(user_ids),
                    'batch_size': batch_size,
                    'status': 'PENDING',
                    'check_url': f'/api/tasks/{task.id}/status/'
                })
            else:
                # Ejecutar síncronamente (solo para lotes pequeños)
                if len(user_ids) > 100:
                    return Response(
                        {'error': 'Para más de 100 usuarios, usa modo asíncrono (async: true)'}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                from .reputation import update_user_reputation_sync
                
                processed = 0
                errors = []
                
                for user_id in user_ids:
                    try:
                        user = User.objects.get(id=user_id)
                        update_user_reputation_sync(user)
                        processed += 1
                    except User.DoesNotExist:
                        errors.append(f"Usuario {user_id} no encontrado")
                    except Exception as e:
                        errors.append(f"Error con usuario {user_id}: {str(e)}")
                
                return Response({
                    'message': 'Recálculo masivo completado',
                    'total_users': len(user_ids),
                    'processed': processed,
                    'errors': len(errors),
                    'error_details': errors[:10]  # Solo primeros 10 errores
                })
                
        except Exception as e:
            return Response(
                {'error': f'Error en recálculo masivo: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _calculate_percentile(self, user):
        """
        Calcula el percentil de reputación del usuario.
        """
        if not user.reputation_score:
            return 0
        
        total_users = User.objects.filter(
            reputation_score__isnull=False
        ).count()
        
        if total_users == 0:
            return 0
        
        users_below = User.objects.filter(
            reputation_score__lt=user.reputation_score
        ).count()
        
        percentile = (users_below / total_users) * 100
        return round(percentile, 1)


# ======================================
# FASE 4-0006: RATE LIMITING ENDPOINTS
# ======================================

class RatingLimitsAPIView(APIView):
    """
    API para verificar límites de valoración y obtener información
    sobre restricciones del sistema anti-abuso
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        """
        Obtiene información sobre límites de valoración para el usuario actual
        GET /api/users/rating-limits/
        
        Response:
        {
            "can_rate": true,
            "daily_remaining": 12,
            "weekly_remaining": 35,
            "daily_used": 3,
            "weekly_used": 15,
            "next_daily_reset": "2025-08-27T00:00:00Z",
            "next_weekly_reset": "2025-08-31T00:00:00Z",
            "config": {
                "daily_limit": 15,
                "weekly_limit": 50,
                "cooldown_days": 5
            }
        }
        """
        try:
            from .validators import get_user_rating_limits
            limits_info = get_user_rating_limits(request.user)
            
            # Agregar configuración actual del sistema
            from .validators import RatingRateLimitValidator
            validator = RatingRateLimitValidator()
            
            response_data = {
                **limits_info,
                'config': {
                    'daily_limit': validator.config['daily_limit'],
                    'weekly_limit': validator.config['weekly_limit'],
                    'cooldown_days': validator.config['cooldown_days'],
                    'enabled': validator.config.get('enabled', True)
                }
            }
            
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Error obteniendo límites de valoración: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def post(self, request):
        """
        Verifica si se puede valorar a un usuario específico
        POST /api/users/rating-limits/
        
        Body:
        {
            "rated_user_id": 123
        }
        
        Response:
        {
            "can_rate": false,
            "reason": "Debes esperar 3 días más para valorar nuevamente a este usuario",
            "next_allowed": "2025-08-29T15:30:00Z",
            "limits": {
                "daily_remaining": 12,
                "weekly_remaining": 35
            }
        }
        """
        try:
            rated_user_id = request.data.get('rated_user_id')
            
            if not rated_user_id:
                return Response(
                    {'error': 'Se requiere el campo rated_user_id'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                rated_user = User.objects.get(id=rated_user_id)
            except User.DoesNotExist:
                return Response(
                    {'error': 'Usuario no encontrado'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
            
            from .validators import validate_rating_limits
            from django.core.exceptions import ValidationError
            
            try:
                limits_info = validate_rating_limits(request.user, rated_user)
                return Response({
                    'can_rate': True,
                    'limits': limits_info
                }, status=status.HTTP_200_OK)
                
            except ValidationError as e:
                # No puede valorar - obtener información básica de límites
                from .validators import get_user_rating_limits
                current_limits = get_user_rating_limits(request.user)
                
                return Response({
                    'can_rate': False,
                    'reason': str(e),
                    'limits': current_limits
                }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response(
                {'error': f'Error verificando límites: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


# ======================================
# FASE 4-0006: ANTI-GAMING MANAGEMENT
# ======================================

class RatingFlagViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para gestión de flags de valoraciones sospechosas
    Solo accesible para moderadores de valoraciones y administradores
    """
    permission_classes = [IsRatingModerator]
    
    def get_queryset(self):
        """Moderadores de valoraciones pueden ver flags"""
        return RatingFlag.objects.select_related(
            'rating__rater', 'rating__rated_user', 'reviewed_by'
        ).order_by('-created_at')
    
    def get_serializer_class(self):
        from .serializers import RatingFlagSerializer
        return RatingFlagSerializer
    
    def list(self, request):
        """
        Lista flags con filtros
        GET /api/users/flags/
        """
        if not request.user.is_staff:
            return Response(
                {'error': 'Solo moderadores pueden ver flags'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        queryset = self.get_queryset()
        
        # Filtros opcionales
        status_filter = request.query_params.get('status')
        severity_filter = request.query_params.get('severity')
        flag_type_filter = request.query_params.get('flag_type')
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if severity_filter:
            queryset = queryset.filter(severity=severity_filter)
        if flag_type_filter:
            queryset = queryset.filter(flag_type=flag_type_filter)
        
        # Paginación
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 20))
        offset = (page - 1) * page_size
        
        total_flags = queryset.count()
        flags_page = queryset[offset:offset + page_size]
        
        serializer = self.get_serializer(flags_page, many=True)
        
        return Response({
            'flags': serializer.data,
            'pagination': {
                'current_page': page,
                'page_size': page_size,
                'total_flags': total_flags,
                'total_pages': (total_flags + page_size - 1) // page_size
            },
            'summary': {
                'pending': queryset.filter(status='pending').count(),
                'reviewed': queryset.filter(status='reviewed').count(),
                'resolved': queryset.filter(status='resolved').count(),
                'false_positive': queryset.filter(status='false_positive').count()
            }
        })
    
    @action(detail=True, methods=['post'])
    def review(self, request, pk=None):
        """
        Marcar flag como revisado
        POST /api/users/flags/{flag_id}/review/
        """
        if not request.user.is_staff:
            return Response(
                {'error': 'Solo moderadores pueden revisar flags'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        flag = self.get_object()
        new_status = request.data.get('status')
        notes = request.data.get('notes', '')
        
        if new_status not in ['reviewed', 'resolved', 'false_positive']:
            return Response(
                {'error': 'Estado inválido. Use: reviewed, resolved, false_positive'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        flag.status = new_status
        flag.reviewed_by = request.user
        flag.reviewed_at = timezone.now()
        flag.moderator_notes = notes
        flag.save()
        
        # Crear log de auditoría
        from .models import AbuseLog
        AbuseLog.objects.create(
            action_type='flag_reviewed',
            target_user=flag.rating.rated_user,
            moderator=request.user,
            details={
                'flag_id': flag.id,
                'old_status': 'pending',
                'new_status': new_status,
                'flag_type': flag.flag_type,
                'severity': flag.severity
            },
            notes=f"Flag marcado como {new_status}. Notas: {notes}"
        )
        
        serializer = self.get_serializer(flag)
        return Response({
            'message': f'Flag marcado como {new_status}',
            'flag': serializer.data
        })


@api_view(['GET'])
@permission_classes([IsRatingModerator])
def anti_gaming_dashboard(request):
    """
    Dashboard para moderadores con estadísticas anti-gaming
    GET /api/users/anti-gaming/dashboard/
    Solo accesible para moderadores de valoraciones y administradores
    """
    try:
        from django.db.models import Count
        from .models import RatingFlag, UserSuspension, AbuseLog
        
        # Estadísticas de flags
        today = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        week_ago = today - timedelta(days=7)
        
        flag_stats = {
            'total_flags': RatingFlag.objects.count(),
            'pending_flags': RatingFlag.objects.filter(status='pending').count(),
            'flags_today': RatingFlag.objects.filter(created_at__gte=today).count(),
            'flags_this_week': RatingFlag.objects.filter(created_at__gte=week_ago).count(),
        }
        
        # Distribución por tipo
        flag_types = RatingFlag.objects.filter(
            status='pending'
        ).values('flag_type').annotate(count=Count('id')).order_by('-count')
        
        # Distribución por severidad
        flag_severity = RatingFlag.objects.filter(
            status='pending'
        ).values('severity').annotate(count=Count('id')).order_by('-count')
        
        # Suspensiones activas
        active_suspensions = UserSuspension.objects.filter(
            is_active=True
        ).filter(
            Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now())
        ).count()
        
        # Actividad reciente de moderación
        recent_actions = AbuseLog.objects.filter(
            moderator__isnull=False,
            timestamp__gte=week_ago
        ).count()
        
        # Top usuarios con más flags
        from django.db.models import Count
        flagged_users = User.objects.filter(
            ratings_given__flags__status='pending'
        ).annotate(
            flag_count=Count('ratings_given__flags')
        ).order_by('-flag_count')[:10]
        
        flagged_users_data = [{
            'user_id': user.id,
            'username': user.username,
            'flag_count': user.flag_count
        } for user in flagged_users]
        
        return Response({
            'summary': flag_stats,
            'distributions': {
                'by_type': list(flag_types),
                'by_severity': list(flag_severity)
            },
            'suspensions': {
                'active_suspensions': active_suspensions
            },
            'activity': {
                'recent_moderator_actions': recent_actions
            },
            'top_flagged_users': flagged_users_data,
            'generated_at': timezone.now()
        })
        
    except Exception as e:
        return Response(
            {'error': f'Error generando dashboard: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsRatingModerator])
def run_anti_gaming_analysis(request):
    """
    Ejecuta análisis anti-gaming manual
    POST /api/users/anti-gaming/analyze/
    Solo accesible para moderadores de valoraciones y administradores
    """
    try:
        hours = request.data.get('hours', 24)
        
        from .anti_gaming import AntiGamingDetector
        detector = AntiGamingDetector()
        
        # Ejecutar análisis
        result = detector.bulk_analyze_recent_ratings(hours=hours)
        
        return Response({
            'message': 'Análisis anti-gaming completado',
            'result': result
        })
        
    except Exception as e:
        return Response(
            {'error': f'Error ejecutando análisis: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_suspicious_activity(request, user_id):
    """
    Obtiene resumen de actividad sospechosa de un usuario
    GET /api/users/{user_id}/suspicious-activity/
    """
    if not request.user.is_staff:
        return Response(
            {'error': 'Solo moderadores pueden ver actividad sospechosa'}, 
            status=status.HTTP_403_FORBIDDEN
        )
    
    try:
        user = get_object_or_404(User, pk=user_id)
        
        from .anti_gaming import get_user_suspicious_activity_summary
        summary = get_user_suspicious_activity_summary(user)
        
        return Response(summary)
        
    except Exception as e:
        return Response(
            {'error': f'Error obteniendo actividad sospechosa: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_suspension_status(request, user_id=None):
    """
    Verifica el estado de suspensión de un usuario
    GET /api/users/suspension-status/
    GET /api/users/{user_id}/suspension-status/  (solo admin)
    """
    try:
        # Determinar qué usuario consultar
        if user_id:
            if not request.user.is_staff:
                return Response(
                    {'error': 'Solo los administradores pueden consultar otros usuarios'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
            try:
                target_user = User.objects.get(id=user_id)
            except User.DoesNotExist:
                return Response(
                    {'error': 'Usuario no encontrado'}, 
                    status=status.HTTP_404_NOT_FOUND
                )
        else:
            target_user = request.user
        
        # Obtener suspensiones activas
        from .models import UserSuspension
        active_suspensions = UserSuspension.objects.filter(
            user=target_user,
            is_active=True
        ).filter(
            Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now())
        ).order_by('-suspended_at')
        
        suspensions_data = []
        for suspension in active_suspensions:
            suspensions_data.append({
                'id': suspension.id,
                'type': suspension.suspension_type,
                'reason': suspension.reason,
                'suspended_at': suspension.suspended_at,
                'expires_at': suspension.expires_at,
                'is_permanent': suspension.expires_at is None,
                'days_remaining': (
                    (suspension.expires_at - timezone.now()).days 
                    if suspension.expires_at else None
                )
            })
        
        return Response({
            'user': {
                'id': target_user.id,
                'username': target_user.username
            },
            'is_suspended': len(suspensions_data) > 0,
            'active_suspensions': suspensions_data,
            'can_rate': len([s for s in suspensions_data if s['type'] in ['rating_ban', 'temporary', 'permanent']]) == 0
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response(
            {'error': f'Error consultando estado de suspensión: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
