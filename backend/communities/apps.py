from django.apps import AppConfig


class CommunitiesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'communities'
    
    def ready(self):
        """Importar signals cuando la app esté lista."""
        import communities.signals
        import communities.signals_image  # Nuevo: signals para procesamiento de imágenes
