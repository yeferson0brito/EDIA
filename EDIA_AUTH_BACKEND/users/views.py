from django.shortcuts import render

# Create your views here.

# users/views.py

from rest_framework import generics  # Vistas genéricas de DRF para CRUD
from rest_framework.response import Response  # Para construir respuestas HTTP
# Para códigos de estado HTTP (ej. 200 OK, 400 Bad Request)
from rest_framework import status
# Importamos nuestro serializador de registro
from .serializers import RegisterSerializer
from django.contrib.auth.models import User  # El modelo de usuario de Django

# Vistas para JWT
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

# ------------------
# Vista para Registro de Usuario
# ------------------


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()  # Define el conjunto de datos sobre el que trabajará
    # Usa nuestro serializador para el registro
    serializer_class = RegisterSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)  # Valida los datos recibidos
        user = serializer.save()  # Si es válido, crea el usuario

        # Puedes personalizar la respuesta si lo deseas
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

# ------------------
# Vista y Serializador para Login (Token Obtain Pair)
# ------------------


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # Añadir campos personalizados al token si es necesario
        token['username'] = user.username
        token['email'] = user.email
        # ... puedes añadir más datos del usuario aquí si los necesitas en Flutter

        return token


class MyTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer
