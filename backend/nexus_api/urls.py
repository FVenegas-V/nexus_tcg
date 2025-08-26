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
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenRefreshView

# Importar views desde el archivo views.py específicamente
from users.views import (
    RegisterView, 
    LoginView, 
    ProfileView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    PasswordResetVerifyTokenView,
    EmailVerificationView,
    EmailVerificationResendView,
    ChangePasswordView,
    UserProfileDetailView,
    PublicUserProfileView,
    search_users,
    update_profile_stats
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
    # APIs de perfiles de usuario
    path('api/users/me/profile/', UserProfileDetailView.as_view(), name='user_profile_detail'),
    path('api/users/<int:user_id>/profile/', PublicUserProfileView.as_view(), name='public_user_profile'),
    path('api/users/search/', search_users, name='search_users'),
    path('api/users/me/profile/update-stats/', update_profile_stats, name='update_profile_stats'),
    # APIs de perfiles públicos (Fase 4)
    path('api/users/', include('users.urls')),
    # APIs de comunidades
    path('', include('communities.urls')),
]

# Serve media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
