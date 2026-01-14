#IMPORTS *******************************************************************************************
from django.db import models
from django.contrib.auth.models import User, Group # Importamos Group y User
from django.db.models.signals import post_save #Siganal para saber cuando se crea un nuevo usuario 
from django.dispatch import receiver
from django.core.validators import MinValueValidator, MaxValueValidator

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class Profile(models.Model):   
    GENDER_CHOICES = (
        ('M', 'Male'),
        ('F', 'Female'),
        ('O', 'Other'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile') #Relacion uno a uno para perfil y usuario
    date_of_birth = models.DateField(null=True, blank=True)
    height_cm = models.PositiveIntegerField(null=True, blank=True)
    weight_kg = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES, null=True, blank=True)
    activity_level = models.CharField(max_length=50, blank=True, null=True)
    onboarded = models.BooleanField(default=False)
    role = models.ForeignKey(Group, null=True, blank=True, on_delete=models.SET_NULL) 

    def __str__(self):
        return f"Perfil de {self.user.username}"
    
    class Meta:
        #Para permisos personalizado s
        permissions = (
            ("can_delete_user", "Podrá eliminar usuarios"),
        )

class DailyRecord(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='daily_records')
    date = models.DateField() # Fecha del registro
    steps = models.PositiveIntegerField(default=0) # Pasos
    sleep_hours = models.FloatField(default=0.0) # Horas de sueño
    mood = models.IntegerField( # Estado de ánimo (1-5)
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True, blank=True
    )
    hydration_ml = models.PositiveIntegerField(default=0) # Hidratación en ml

    class Meta:
        unique_together = ('user', 'date') # Un solo registro por usuario por día
        ordering = ['-date'] # Ordenar del más reciente al más antiguo
    
#CREAR PERFIL AUTOMATICO PARA CADA USUARIO NUEVO CREADO ******************************************************************************************************************************************************************
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
