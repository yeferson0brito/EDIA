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
from .models import Profile
from .serializers import ProfileSerializer, OnboardingSerializer
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

        role = user.profile.role.name if hasattr(user, 'profile') and user.profile.role else None
        groups = [g.name for g in user.groups.all()]
        return Response({
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "role": role,
                "groups": groups
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
        token['group'] = [g.name for g in user.groups.all()]

        # Comprobamos si el usuario tiene un perfil asociado y que el campo no este vacio
        if hasattr(user, 'profile') and user.profile.role:
            # Añade al token el rol asociado
            token['role'] = user.profile.role.name
        else:
            token['role'] = None  # Si no tiene rol, enviamos null

        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user
        data['user'] = {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
            "role": user.profile.role.name if hasattr(user, 'profile') and user.profile.role else None,
            "groups": [g.name for g in user.groups.all()],
            "onboarded": user.profile.onboarded if hasattr(user, 'profile') else False
        }
        return data


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_user_view(request, user_id_to_delete):
    # Así se comprueba el permiso
    if not request.user.has_perm('users.can_delete_user'):
        return Response({"detail": "No tienes permiso para eliminar usuarios."}, status=403)

    try:
        user_to_delete = User.objects.get(id=user_id_to_delete)
        user_to_delete.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)   # <- devolver 204 sin body
    except User.DoesNotExist:
        return Response({"detail": "Usuario no encontrado."}, status=404)

    return Response({"detail": "Usuario eliminado."}, status=204)


class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def onboarding_view(request):
    profile = getattr(request.user, 'profile', None)
    if request.method == 'GET':
        if not profile:
            return Response({}, status=status.HTTP_200_OK)
        return Response(ProfileSerializer(profile).data, status=status.HTTP_200_OK)

    # POST: actualizar datos y marcar onboarded True
    if not profile:
        return Response({"detail": "Profile not found."}, status=status.HTTP_400_BAD_REQUEST)
    serializer = OnboardingSerializer(profile, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    profile = serializer.save()
    profile.onboarded = True
    profile.save()
    return Response(ProfileSerializer(profile).data, status=status.HTTP_200_OK)
