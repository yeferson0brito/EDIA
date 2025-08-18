from django.contrib import admin
from django.urls import path, include # Importa 'include'


"""# Importa las vistas JWT para que simplejwt las incluya automáticamente
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
# Importa tu vista personalizada de JWT
from users.views import MyTokenObtainPairView"""


urlpatterns = [
    path('admin/', admin.site.urls),
    # URLs de la app 'users' bajo el prefijo 'api/'
    path('api/', include('users.urls')),
]