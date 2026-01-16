# c:\Users\yebri\PROYECTOS\EDIA\EDIA_AUTH_BACKEND\users\authentication.py
from django.contrib.auth.models import User
from rest_framework.authentication import BaseAuthentication

class DevAuthentication(BaseAuthentication):
    """
    Autenticación temporal para desarrollo.
    Fuerza el inicio de sesión como un usuario específico sin necesidad de token.
    """
    def authenticate(self, request):
        target_username = 'admin' 
        try:
            user = User.objects.get(username=target_username)
            # Retorna una tupla (user, auth), 
            return (user, None) #-- no hay token real
        except User.DoesNotExist:
            # Fallback: Si no encuentra al usuario específico, intenta usar el primer superusuario o usuario
            user = User.objects.first()
            if user:
                return (user, None)
            return None
