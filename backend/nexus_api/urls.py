"""
URL configuration for nexus_api project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from users.views import (
    RegisterView, 
    LoginView, 
    ProfileView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    PasswordResetVerifyTokenView,
    EmailVerificationView,
    EmailVerificationResendView,
    ChangePasswordView
)

urlpatterns = [
    path('admin/', admin.site.urls),
    # APIs de autenticación
    path('api/auth/register/', RegisterView.as_view(), name='register'),
    path('api/auth/login/', LoginView.as_view(), name='login'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # APIs de recuperación de contraseña
    path('api/auth/password-reset/', PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('api/auth/password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('api/auth/password-reset/verify/<uuid:token>/', PasswordResetVerifyTokenView.as_view(), name='password_reset_verify'),
    # APIs de verificación de email
    path('api/auth/verify-email/<uuid:token>/', EmailVerificationView.as_view(), name='email_verification'),
    path('api/auth/resend-verification/', EmailVerificationResendView.as_view(), name='email_verification_resend'),
    # APIs de usuario
    path('api/users/me/', ProfileView.as_view(), name='profile'),
    path('api/users/me/password/', ChangePasswordView.as_view(), name='change_password'),
]
