# users/urls.py

from django.urls import path
from .views import RegisterView, MyTokenObtainPairView, onboarding_view, DailyRecordListCreateView, DailyRecordDetailView # Importamosw las visatas

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('onboarding/', onboarding_view, name='onboarding'),
    path('history/', DailyRecordListCreateView.as_view(), name='history'),
    path('history/<int:pk>/', DailyRecordDetailView.as_view(), name='history_detail'),
    # Para obtener el token
    # Si más adelante necesitas refrescar el token sin login:
    # path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]