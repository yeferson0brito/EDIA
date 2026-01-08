# IMPORTS PARA SERIALIZERS**********************************************************************************
from django.contrib.auth.models import User, Group
from .models import Profile, DailyRecord
from rest_framework import serializers
from rest_framework.validators import UniqueValidator  # Para validar campos únicos
import re  # expresiones regulares
from django.core.exceptions import ObjectDoesNotExist

class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ('date_of_birth', 'height_cm', 'weight_kg', 'gender', 'onboarded', 'role')
        read_only_fields = ('onboarded', 'role')

class OnboardingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ('date_of_birth', 'height_cm', 'weight_kg', 'gender')

class DailyRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyRecord
        fields = ('id', 'date', 'steps', 'sleep_hours', 'mood', 'hydration_ml')
        # El usuario se asignará automáticamente en la vista, no se pide en el JSON

class RegisterSerializer(serializers.ModelSerializer):
    # DEFINICION DE CAMPOS************************************************************************************************************************************************************
    email = serializers.EmailField(
        required=True,
        validators=[UniqueValidator(
            # valida que el email no este registrado
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
# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

# CLASE META**************************************************************************************************************************************
    class Meta:
        model = User  # Usamos el modelo User de Django
        fields = ('username', 'password', 'password2', 'email',
                  'first_name', 'last_name')  # Campos que esperamos de Flutter
        extra_kwargs = {
            # first_name y last_name son opcionalesss
            'first_name': {'required': False},
            'last_name': {'required': False},
        }
# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


# LOGICA DE VALIDACION********************************************************************************************************************************************

    def validate(self, attrs):  # Se ejecuta cuando las validaciones de campo pasen
        # Validar que las dos contraseñas coincidan con attrs que contiene los datos de los campos
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError(
                {"password": "Las contraseñas no coinciden."})

        if len(attrs['password']) < 8:
            raise serializers.ValidationError(
                {"password": "La contraseña debe tener al menos 8 caracteres."})

        if not re.search(r'\d', attrs['password']):
            raise serializers.ValidationError(
                {"password": "La contraseña debe contener al menos un número."})

        return attrs
# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

# CREACION DE LOS NUEVOS USUARIOS**********************************************************************************************************************************************************
    def create(self, validated_data):
        # Se llama cuando en la vista se guardan los datos
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)

        try:
            # Es mejor ser específico con la excepción.
            basic_user_group = Group.objects.get(name='Usuario Basico')
            user.groups.add(basic_user_group)
            user.profile.role = basic_user_group
            user.profile.save()
        except Group.DoesNotExist:
            # En una aplicación real, es mejor usar el sistema de logging de Django.
            print("ADVERTENCIA: El grupo 'Usuario Basico' no existe. El usuario se creó sin un rol.")

        return user

"""
Valida campo por campo 

user = User.objects.create_user( # para enviar hashing y no los datos texto plano
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            # Usar .get para campos opcionales
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')"""


# 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
