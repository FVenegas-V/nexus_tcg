"""
Serializers para el sistema de reacciones (likes, emojis) en posts y comentarios.
"""
from rest_framework import serializers
from django.contrib.contenttypes.models import ContentType
from django.db.models import Count, Q

from ..models import Reaction, Post, Comment


class ReactionSerializer(serializers.ModelSerializer):
    """
    Serializer base para reacciones individuales.
    """
    emoji = serializers.SerializerMethodField()
    author = serializers.SerializerMethodField()
    content_type_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Reaction
        fields = [
            'id', 'reaction_type', 'emoji', 'created_at',
            'author', 'content_type_name', 'object_id'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_emoji(self, obj):
        """Obtener emoji correspondiente al tipo de reacción."""
        return Reaction.EMOJI_MAP.get(obj.reaction_type, '❓')
    
    def get_author(self, obj):
        """Información básica del autor de la reacción."""
        return {
            'id': obj.user.id,
            'username': obj.user.username,
            'avatar_url': getattr(obj.user.userprofile, 'avatar_url', None) if hasattr(obj.user, 'userprofile') else None
        }
    
    def get_content_type_name(self, obj):
        """Tipo de contenido legible (post o comment)."""
        return obj.content_type.model


class ReactionCreateSerializer(serializers.Serializer):
    """
    Serializer para crear o actualizar reacciones.
    """
    reaction_type = serializers.ChoiceField(choices=Reaction.REACTION_TYPES)
    
    def validate_reaction_type(self, value):
        """Validar que el tipo de reacción sea válido."""
        valid_types = [choice[0] for choice in Reaction.REACTION_TYPES]
        if value not in valid_types:
            raise serializers.ValidationError(
                f"Tipo de reacción inválido. Opciones válidas: {', '.join(valid_types)}"
            )
        return value


class ReactionBreakdownSerializer(serializers.Serializer):
    """
    Serializer para el breakdown detallado de reacciones por tipo.
    """
    total_count = serializers.IntegerField()
    user_reaction = ReactionSerializer(allow_null=True)
    breakdown = serializers.DictField()
    
    def to_representation(self, instance):
        """
        Generar breakdown completo de reacciones.
        instance debe ser un diccionario con:
        - content_object: El post o comentario
        - user: Usuario actual (para user_reaction)
        """
        content_object = instance['content_object']
        current_user = instance.get('user')
        include_users = instance.get('include_users', False)
        
        # Obtener ContentType del objeto
        content_type = ContentType.objects.get_for_model(content_object)
        
        # Query base para las reacciones
        reactions_qs = Reaction.objects.filter(
            content_type=content_type,
            object_id=content_object.id
        ).select_related('user')
        
        # Calcular totales por tipo
        breakdown_data = reactions_qs.values('reaction_type').annotate(
            count=Count('id')
        ).order_by('-count')
        
        # Inicializar breakdown con todos los tipos
        breakdown = {}
        for reaction_type, label in Reaction.REACTION_TYPES:
            breakdown[reaction_type] = {
                'count': 0,
                'emoji': Reaction.EMOJI_MAP[reaction_type],
                'label': label.split(' ', 1)[1] if ' ' in label else label  # Quitar emoji del label
            }
            
            if include_users:
                breakdown[reaction_type]['users'] = []
        
        # Llenar con datos reales
        for item in breakdown_data:
            reaction_type = item['reaction_type']
            count = item['count']
            breakdown[reaction_type]['count'] = count
            
            # Si se solicitan usuarios, obtenerlos
            if include_users and count > 0:
                users = reactions_qs.filter(
                    reaction_type=reaction_type
                ).select_related('user')[:10]  # Límite de 10 usuarios
                
                breakdown[reaction_type]['users'] = [
                    {
                        'id': reaction.user.id,
                        'username': reaction.user.username,
                        'avatar_url': getattr(reaction.user.userprofile, 'avatar_url', None) 
                                    if hasattr(reaction.user, 'userprofile') else None
                    }
                    for reaction in users
                ]
        
        # Obtener reacción del usuario actual
        user_reaction = None
        if current_user and current_user.is_authenticated:
            try:
                user_reaction_obj = reactions_qs.get(user=current_user)
                user_reaction = ReactionSerializer(user_reaction_obj).data
            except Reaction.DoesNotExist:
                user_reaction = None
        
        # Calcular total
        total_count = sum(item['count'] for item in breakdown.values())
        
        return {
            'total_count': total_count,
            'user_reaction': user_reaction,
            'breakdown': breakdown
        }


class ReactionDetailSerializer(serializers.ModelSerializer):
    """
    Serializer completo para reacciones con información del contenido.
    """
    emoji = serializers.SerializerMethodField()
    author = serializers.SerializerMethodField()
    content_info = serializers.SerializerMethodField()
    
    class Meta:
        model = Reaction
        fields = [
            'id', 'reaction_type', 'emoji', 'created_at',
            'author', 'content_info'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_emoji(self, obj):
        """Obtener emoji correspondiente al tipo de reacción."""
        return Reaction.EMOJI_MAP.get(obj.reaction_type, '❓')
    
    def get_author(self, obj):
        """Información completa del autor de la reacción."""
        user_profile = getattr(obj.user, 'userprofile', None)
        return {
            'id': obj.user.id,
            'username': obj.user.username,
            'email': obj.user.email,
            'avatar_url': getattr(user_profile, 'avatar_url', None) if user_profile else None,
            'is_verified': getattr(user_profile, 'is_verified', False) if user_profile else False
        }
    
    def get_content_info(self, obj):
        """Información del contenido al que se reaccionó."""
        content_obj = obj.content_object
        
        if isinstance(content_obj, Post):
            return {
                'type': 'post',
                'id': content_obj.id,
                'title': content_obj.title,
                'author_username': content_obj.author.username,
                'community_name': content_obj.community.name,
                'created_at': content_obj.created_at,
                'reaction_count': content_obj.reaction_count
            }
        elif isinstance(content_obj, Comment):
            return {
                'type': 'comment',
                'id': content_obj.id,
                'content_excerpt': content_obj.content[:100] + '...' if len(content_obj.content) > 100 else content_obj.content,
                'author_username': content_obj.author.username,
                'post_title': content_obj.post.title,
                'thread_level': content_obj.thread_level,
                'created_at': content_obj.created_at,
                'reaction_count': getattr(content_obj, 'reaction_count', 0)
            }
        else:
            return {
                'type': 'unknown',
                'id': obj.object_id
            }


class ReactionResponseSerializer(serializers.Serializer):
    """
    Serializer para respuestas de endpoints de reacciones.
    """
    action = serializers.ChoiceField(choices=['added', 'updated', 'removed'])
    user_reaction = ReactionSerializer(allow_null=True)
    breakdown = serializers.DictField()
    content = serializers.DictField()
    
    def to_representation(self, instance):
        """
        Crear respuesta completa para acciones de reacción.
        instance debe contener:
        - action: 'added', 'updated', 'removed'
        - user_reaction: Objeto Reaction o None
        - content_object: Post o Comment
        - user: Usuario actual
        """
        action = instance['action']
        user_reaction = instance.get('user_reaction')
        content_object = instance['content_object']
        current_user = instance['user']
        
        # Serializar reacción del usuario
        user_reaction_data = None
        if user_reaction:
            user_reaction_data = ReactionSerializer(user_reaction).data
        
        # Obtener breakdown actualizado
        breakdown_serializer = ReactionBreakdownSerializer()
        breakdown_data = breakdown_serializer.to_representation({
            'content_object': content_object,
            'user': current_user,
            'include_users': False
        })
        
        # Información del contenido
        if isinstance(content_object, Post):
            content_data = {
                'type': 'post',
                'id': content_object.id,
                'title': content_object.title,
                'reaction_count': content_object.reaction_count,
                'author_username': content_object.author.username
            }
        elif isinstance(content_object, Comment):
            content_data = {
                'type': 'comment',
                'id': content_object.id,
                'content_excerpt': content_object.content[:50] + '...' if len(content_object.content) > 50 else content_object.content,
                'reaction_count': getattr(content_object, 'reaction_count', 0),
                'author_username': content_object.author.username
            }
        else:
            content_data = {'type': 'unknown', 'id': content_object.id}
        
        return {
            'action': action,
            'user_reaction': user_reaction_data,
            'breakdown': breakdown_data['breakdown'],
            'content': content_data
        }


class MyReactionsSerializer(serializers.Serializer):
    """
    Serializer para listar las reacciones del usuario actual.
    """
    page_size = serializers.IntegerField(default=20, min_value=1, max_value=100)
    content_type = serializers.ChoiceField(
        choices=['all', 'post', 'comment'], 
        default='all'
    )
    reaction_type = serializers.ChoiceField(
        choices=['all'] + [choice[0] for choice in Reaction.REACTION_TYPES],
        default='all'
    )
    
    def to_representation(self, instance):
        """
        Listar reacciones del usuario con filtros.
        """
        user = instance['user']
        filters = instance.get('filters', {})
        
        # Query base
        reactions_qs = Reaction.objects.filter(user=user).select_related(
            'content_type'
        ).order_by('-created_at')
        
        # Aplicar filtros
        if filters.get('content_type') and filters['content_type'] != 'all':
            content_type = ContentType.objects.get(model=filters['content_type'])
            reactions_qs = reactions_qs.filter(content_type=content_type)
        
        if filters.get('reaction_type') and filters['reaction_type'] != 'all':
            reactions_qs = reactions_qs.filter(reaction_type=filters['reaction_type'])
        
        # Serializar reacciones
        reactions_data = []
        for reaction in reactions_qs[:filters.get('page_size', 20)]:
            reactions_data.append(ReactionDetailSerializer(reaction).data)
        
        # Estadísticas del usuario
        total_reactions = Reaction.objects.filter(user=user).count()
        by_type = Reaction.objects.filter(user=user).values('reaction_type').annotate(
            count=Count('id')
        )
        
        stats = {reaction_type: 0 for reaction_type, _ in Reaction.REACTION_TYPES}
        for item in by_type:
            stats[item['reaction_type']] = item['count']
        
        return {
            'reactions': reactions_data,
            'total_count': total_reactions,
            'stats_by_type': stats,
            'filters_applied': filters
        }
