# users/serializers.py

from rest_framework import serializers
from django.contrib.auth.models import User  # Django's built-in User model
from rest_framework.validators import UniqueValidator  # Para validar campos únicos


class RegisterSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(
        required=True,
        validators=[UniqueValidator(
            queryset=User.objects.all(), message="Este email ya está registrado.")]
    )
    username = serializers.CharField(
        required=True,
        validators=[UniqueValidator(queryset=User.objects.all(
        ), message="Este nombre de usuario ya está en uso.")]
    )
    password = serializers.CharField(
        write_only=True, required=True, help_text='Debe contener al menos 8 caracteres y ser complejo.')
    password2 = serializers.CharField(
        write_only=True, required=True, help_text='Confirma tu contraseña.')

    class Meta:
        model = User  # Usamos el modelo User de Django
        fields = ('username', 'password', 'password2', 'email',
                  'first_name', 'last_name')  # Campos que esperamos de Flutter
        extra_kwargs = {
            # first_name y last_name son opcionaless
            'first_name': {'required': False},
            'last_name': {'required': False},
        }

    def validate(self, attrs):
        # Validar que las dos contraseñas coincidan
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError(
                {"password": "Las contraseñas no coinciden."})

        # Validar complejidad de la contraseña (opcional, pero buena práctica)
        # Aquí podrías añadir más reglas, ej. mínimo 8 caracteres, al menos un número, etc.
        if len(attrs['password']) < 8:
            raise serializers.ValidationError(
                {"password": "La contraseña debe tener al menos 8 caracteres."})

        return attrs

    def create(self, validated_data):
        # Crear un nuevo usuario usando los datos validados
        # Es importante usar create_user para que la contraseña se encripte correctamente
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            # Usar .get para campos opcionales
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user
