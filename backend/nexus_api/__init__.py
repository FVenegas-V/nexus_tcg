from __future__ import absolute_import, unicode_literals

# Esto asegura que la app de Celery se importe cuando Django se inicia
from .celery import app as celery_app

__all__ = ('celery_app',)