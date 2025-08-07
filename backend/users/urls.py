from django.urls import path
from . import views

urlpatterns = [
    # URLs de autenticación
    path('register/', views.RegisterView.as_view(), name='register'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('profile/', views.ProfileView.as_view(), name='profile'),
    
    # URLs de recuperación de contraseña
    path('password-reset/', views.PasswordResetRequestView.as_view(), name='password_reset_request'),
    path('password-reset-confirm/', views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('password-reset-verify/<uuid:token>/', views.PasswordResetVerifyTokenView.as_view(), name='password_reset_verify'),
    
    # URLs de verificación de email
    path('verify-email/<uuid:token>/', views.EmailVerificationView.as_view(), name='email_verification'),
    path('resend-verification/', views.EmailVerificationResendView.as_view(), name='email_verification_resend'),
    
    # URLs de gestión de cuenta
    path('me/password/', views.ChangePasswordView.as_view(), name='change_password'),
]
