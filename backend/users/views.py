from rest_framework.generics import CreateAPIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import authenticate, get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from users.serializers import (
    RegisterSerializer, 
    PasswordResetRequestSerializer, 
    PasswordResetConfirmSerializer
)
from .models import PasswordResetToken

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
        username = request.data.get('username')
        password = request.data.get('password')
        
        # Validar que se proporcionen username y password
        if not username or not password:
            return Response(
                {'error': 'Se requieren username y password'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Autenticar usuario
        user = authenticate(username=username, password=password)
        
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
            'is_active': user.is_active,
        }, status=status.HTTP_200_OK)


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
