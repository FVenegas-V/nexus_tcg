"""
Signals para actualización automática de contadores en modelos de posts y membresías.
"""
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db.models import F
from .models import Post, Comment, Reaction, CommunityMembership


@receiver(post_save, sender=Comment)
def update_post_comment_count_on_create(sender, instance, created, **kwargs):
    """Actualizar comment_count del post cuando se crea un comentario."""
    if created and instance.is_active:
        Post.objects.filter(id=instance.post.id).update(
            comment_count=F('comment_count') + 1
        )


@receiver(post_delete, sender=Comment)
def update_post_comment_count_on_delete(sender, instance, **kwargs):
    """Actualizar comment_count del post cuando se elimina un comentario."""
    if instance.is_active:  # Solo si estaba activo
        Post.objects.filter(id=instance.post.id).update(
            comment_count=F('comment_count') - 1
        )


@receiver(post_save, sender=Comment)
def update_comment_replies_count(sender, instance, created, **kwargs):
    """Actualizar replies_count del comentario padre cuando se crea una respuesta."""
    try:
        if created and hasattr(instance, 'parent_id') and instance.parent_id and instance.is_active:
            # Verificar que el padre existe antes de actualizar
            if Comment.objects.filter(id=instance.parent_id).exists():
                Comment.objects.filter(id=instance.parent_id).update(
                    replies_count=F('replies_count') + 1
                )
    except (Comment.DoesNotExist, AttributeError):
        # Si hay algún error, simplemente continuar
        pass


@receiver(post_delete, sender=Comment)
def update_comment_replies_count_on_delete(sender, instance, **kwargs):
    """Actualizar replies_count del comentario padre cuando se elimina una respuesta."""
    try:
        # Verificar si el comentario tenía padre antes de ser eliminado
        if hasattr(instance, 'parent_id') and instance.parent_id and instance.is_active:
            # Verificar que el padre aún existe antes de actualizar
            if Comment.objects.filter(id=instance.parent_id).exists():
                Comment.objects.filter(id=instance.parent_id).update(
                    replies_count=F('replies_count') - 1
                )
    except (Comment.DoesNotExist, AttributeError):
        # Si hay algún error (objeto ya eliminado, etc.), simplemente continuar
        pass


@receiver(post_save, sender=Reaction)
def update_reaction_count_on_create(sender, instance, created, **kwargs):
    """Actualizar reaction_count cuando se crea una reacción."""
    if created:
        content_object = instance.content_object
        if content_object and hasattr(content_object, 'reaction_count'):
            # Usar update directo en la clase del modelo para evitar signals recursivos
            model_class = content_object.__class__
            model_class.objects.filter(id=content_object.id).update(
                reaction_count=F('reaction_count') + 1
            )


@receiver(post_delete, sender=Reaction)
def update_reaction_count_on_delete(sender, instance, **kwargs):
    """Actualizar reaction_count cuando se elimina una reacción."""
    try:
        content_object = instance.content_object
        if content_object and hasattr(content_object, 'reaction_count'):
            # Verificar que el objeto aún existe antes de actualizar
            model_class = content_object.__class__
            if model_class.objects.filter(id=content_object.id).exists():
                model_class.objects.filter(id=content_object.id).update(
                    reaction_count=F('reaction_count') - 1
                )
    except (Exception,):
        # Si hay algún error (objeto ya eliminado, etc.), simplemente continuar
        pass


@receiver(post_save, sender=Post)
def update_community_post_count_on_create(sender, instance, created, **kwargs):
    """Actualizar post_count de la comunidad cuando se crea un post."""
    if created and instance.is_active:
        from .models import Community
        Community.objects.filter(id=instance.community.id).update(
            post_count=F('post_count') + 1
        )


@receiver(post_delete, sender=Post)
def update_community_post_count_on_delete(sender, instance, **kwargs):
    """Actualizar post_count de la comunidad cuando se elimina un post."""
    try:
        if instance.is_active and hasattr(instance, 'community_id') and instance.community_id:
            from .models import Community
            # Verificar que la comunidad aún existe antes de actualizar
            if Community.objects.filter(id=instance.community_id).exists():
                Community.objects.filter(id=instance.community_id).update(
                    post_count=F('post_count') - 1
                )
    except (Exception,):
        # Si hay algún error (objeto ya eliminado, etc.), simplemente continuar
        pass


# Signal para manejar soft deletes
@receiver(post_save, sender=Post)
def handle_post_soft_delete(sender, instance, **kwargs):
    """Manejar cambios en is_active para posts (soft delete/restore)."""
    if hasattr(instance, '_previous_is_active'):
        previous_active = instance._previous_is_active
        current_active = instance.is_active
        
        # Solo procesar si cambió el estado
        if previous_active != current_active:
            from .models import Community
            if current_active and not previous_active:
                # Restaurado: incrementar contador
                Community.objects.filter(id=instance.community.id).update(
                    post_count=F('post_count') + 1
                )
            elif not current_active and previous_active:
                # Soft deleted: decrementar contador
                Community.objects.filter(id=instance.community.id).update(
                    post_count=F('post_count') - 1
                )


@receiver(post_save, sender=Comment)
def handle_comment_soft_delete(sender, instance, **kwargs):
    """Manejar cambios en is_active para comentarios (soft delete/restore)."""
    if hasattr(instance, '_previous_is_active'):
        previous_active = instance._previous_is_active
        current_active = instance.is_active
        
        # Solo procesar si cambió el estado
        if previous_active != current_active:
            if current_active and not previous_active:
                # Restaurado: incrementar contadores
                try:
                    Post.objects.filter(id=instance.post.id).update(
                        comment_count=F('comment_count') + 1
                    )
                    if hasattr(instance, 'parent_id') and instance.parent_id:
                        if Comment.objects.filter(id=instance.parent_id).exists():
                            Comment.objects.filter(id=instance.parent_id).update(
                                replies_count=F('replies_count') + 1
                            )
                except (Exception,):
                    pass
            elif not current_active and previous_active:
                # Soft deleted: decrementar contadores
                try:
                    Post.objects.filter(id=instance.post.id).update(
                        comment_count=F('comment_count') - 1
                    )
                    if hasattr(instance, 'parent_id') and instance.parent_id:
                        if Comment.objects.filter(id=instance.parent_id).exists():
                            Comment.objects.filter(id=instance.parent_id).update(
                                replies_count=F('replies_count') - 1
                            )
                except (Exception,):
                    pass


# Helpers para tracking de estados previos
def track_previous_state(sender, instance, **kwargs):
    """Registra el estado previo para detectar cambios en soft delete."""
    if instance.pk:  # Solo para objetos existentes
        try:
            previous = sender.objects.get(pk=instance.pk)
            instance._previous_is_active = previous.is_active
        except sender.DoesNotExist:
            instance._previous_is_active = None


# Conectar el helper para tracking
from django.db.models.signals import pre_save

pre_save.connect(track_previous_state, sender=Post)
pre_save.connect(track_previous_state, sender=Comment)


# === SIGNALS PARA MEMBER COUNT ===

@receiver(post_save, sender=CommunityMembership)
def update_community_member_count_on_create(sender, instance, created, **kwargs):
    """Actualizar member_count de la comunidad cuando se crea una membresía."""
    if created and instance.status == 'active':
        from .models import Community
        Community.objects.filter(id=instance.community.id).update(
            member_count=F('member_count') + 1
        )
        print(f"✅ SIGNAL: Incrementado member_count para {instance.community.name}")


@receiver(post_delete, sender=CommunityMembership)
def update_community_member_count_on_delete(sender, instance, **kwargs):
    """Actualizar member_count de la comunidad cuando se elimina una membresía."""
    if instance.status == 'active':  # Solo si estaba activa
        from .models import Community
        Community.objects.filter(id=instance.community.id).update(
            member_count=F('member_count') - 1
        )
        print(f"✅ SIGNAL: Decrementado member_count para {instance.community.name}")


@receiver(post_save, sender=CommunityMembership)
def handle_membership_status_change(sender, instance, **kwargs):
    """Manejar cambios en el status de membresía (activación/desactivación)."""
    if hasattr(instance, '_previous_status'):
        previous_status = instance._previous_status
        current_status = instance.status
        
        # Solo procesar si cambió el estado
        if previous_status != current_status:
            from .models import Community
            if current_status == 'active' and previous_status != 'active':
                # Activada: incrementar contador
                Community.objects.filter(id=instance.community.id).update(
                    member_count=F('member_count') + 1
                )
                print(f"✅ SIGNAL: Activada membresía - incrementado member_count para {instance.community.name}")
            elif current_status != 'active' and previous_status == 'active':
                # Desactivada: decrementar contador
                Community.objects.filter(id=instance.community.id).update(
                    member_count=F('member_count') - 1
                )
                print(f"✅ SIGNAL: Desactivada membresía - decrementado member_count para {instance.community.name}")


def track_membership_previous_status(sender, instance, **kwargs):
    """Registra el estado previo de status para detectar cambios."""
    if instance.pk:  # Solo para objetos existentes
        try:
            previous = sender.objects.get(pk=instance.pk)
            instance._previous_status = previous.status
        except sender.DoesNotExist:
            instance._previous_status = None


# Conectar el tracking de status de membresía
pre_save.connect(track_membership_previous_status, sender=CommunityMembership)
