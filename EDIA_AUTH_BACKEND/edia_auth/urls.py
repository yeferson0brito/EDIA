"""
URL configuration for edia_auth project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))

from django.contrib import admin
from django.urls import path

urlpatterns = [
    path('admin/', admin.site.urls),
]

# myproject/urls.py

"""

from django.contrib import admin
from django.urls import path, include # Importa 'include'
# Importa las vistas JWT para que simplejwt las incluya automáticamente
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
# Importa tu vista personalizada de JWT
from users.views import MyTokenObtainPairView


urlpatterns = [
    path('admin/', admin.site.urls),
    # Incluye las URLs de nuestra app 'users' bajo el prefijo 'api/'
    path('api/', include('users.urls')), # TODAS las URLs de la app 'users' estarán bajo '/api/'
    # Opcionalmente, puedes incluirlas directamente si no quieres un prefijo 'api/'
    # path('auth/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    # path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]