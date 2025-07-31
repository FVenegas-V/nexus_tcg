from rest_framework.generics import CreateAPIView
from rest_framework.response import Response
from rest_framework import status
from users.serializers import RegisterSerializer


class RegisterView(CreateAPIView):
    serializer_class = RegisterSerializer
    
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
