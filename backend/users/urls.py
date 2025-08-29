from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from .views import (
    RatingLimitsAPIView, 
    user_suspension_status, 
    anti_gaming_dashboard,
    run_anti_gaming_analysis,
    user_suspicious_activity,
    RatingFlagViewSet
)

# Router para ViewSets
router = DefaultRouter()
router.register(r'profiles', views.UserProfileViewSet, basename='user-profiles')
router.register(r'ratings', views.UserRatingViewSet, basename='user-ratings')
router.register(r'reputation', views.UserReputationViewSet, basename='user-reputation')
router.register(r'flags', views.RatingFlagViewSet, basename='rating-flags')

urlpatterns = [
    # URLs de autenticación
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('profile/', views.ProfileView.as_view(), name='profile'),
    
    # Endpoint adicional para compatibilidad con frontend (misma vista)
    path('me/', views.ProfileView.as_view(), name='user_profile'),
    
    # URLs de recuperación de contraseña
    path('password-reset-request/', views.PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('password-reset-confirm/', views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('password-reset-verify/<uuid:token>/', views.PasswordResetVerifyTokenView.as_view(), name='password_reset_verify'),
    
    # Vista web para reset de contraseña (desde navegador)
    path('password-reset/<uuid:token>/', views.PasswordResetWebView.as_view(), name='password_reset_web'),
    
    # URLs de verificación de email
    path('verify-email/<uuid:token>/', views.EmailVerificationView.as_view(), name='email_verification'),
    path('resend-verification/', views.EmailVerificationResendView.as_view(), name='email_verification_resend'),
    
    # URLs de gestión de cuenta
    path('me/password/', views.ChangePasswordView.as_view(), name='change_password'),
    
    # APIs de Rate Limiting (Fase 4-0006)
    path('rating-limits/', views.RatingLimitsAPIView.as_view(), name='rating_limits'),
    path('suspension-status/', views.user_suspension_status, name='user_suspension_status'),
    path('<int:user_id>/suspension-status/', views.user_suspension_status, name='user_suspension_status_admin'),
    
    # APIs de Anti-Gaming (Fase 4-0006)
    path('anti-gaming/dashboard/', views.anti_gaming_dashboard, name='anti_gaming_dashboard'),
    path('anti-gaming/analyze/', views.run_anti_gaming_analysis, name='run_anti_gaming_analysis'),
    path('<int:user_id>/suspicious-activity/', views.user_suspicious_activity, name='user_suspicious_activity'),
    
    # ViewSets - Perfiles públicos (Fase 4)
    path('', include(router.urls)),
]
