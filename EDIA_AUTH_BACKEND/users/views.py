# IMPORTS ************************************************************************************************
# users/views.py
from django.shortcuts import render
from rest_framework import generics  # Vistas genéricas de DRF para CRUD
from rest_framework.response import Response  # Para construir respuestas HTTP
# Para códigos de estado HTTP (ej. 200 OK, 400 Bad Request)
from rest_framework import status
# Importamos nuestro serializador de registro
from .serializers import RegisterSerializer
# El modelo de usuario de Django
from django.contrib.auth.models import User, Group
from rest_framework.permissions import DjangoModelPermissions
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response

# Vistas para JWT
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

# CLASE REGISTERVIEW*********************************************************************************************************
# -------------------------------------------------------------------------------
# Vista para Registro de Usuario
# -------------------------------------------------------------------------------


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()  # Define el conjunto de datos sobre el que trabajará
    # Usamos el serializador que creamos en el archivo serializers.py
    serializer_class = RegisterSerializer

    def post(self, request, *args, **kwargs):
        # Instancia de RegisterSerializer para los datos enviados por frontend
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)  # Valida los datos recibidos
        user = serializer.save()  # Si es válido, crea el usuario

        return Response({
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name
            },
            "message": "Usuario registrado exitosamente."
        }, status=status.HTTP_201_CREATED)  # Código 201: Creado
# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

# CLASE TOKENOBTAINPAIR*******************************************************************************************************
# -------------------------------------------------------------------------------
# Vista y Serializador para Login (Token Obtain Pair)
# -------------------------------------------------------------------------------


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Añadir campos personalizados al token si es necesario
        token['username'] = user.username
        token['email'] = user.email

        # Comprobamos si el usuario tiene un perfil asociado y que el campo no este vacio
        if hasattr(user, 'profile') and user.profile.role:
            # Añade al token el rol asociado
            token['role'] = user.profile.role.name
        else:
            token['role'] = None  # Si no tiene rol, enviamos null

        return token


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_user_view(request, user_id_to_delete):
    # Así se comprueba el permiso
    if not request.user.has_perm('users.can_delete_user'):
        return Response({"detail": "No tienes permiso para eliminar usuarios."}, status=403)

        # Lógica para eliminar el usuario
        try:
            user_to_delete = User.objects.get(id=user_id_to_delete)
            user_to_delete.delete()
            return Response({"detail": "Usuario eliminado."}, status=204)
        except User.DoesNotExist:
            return Response({"detail": "Usuario no encontrado."}, status=404)

    return Response({"detail": "Usuario eliminado."}, status=204)


class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer
