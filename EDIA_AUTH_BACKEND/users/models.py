#IMPORTS *******************************************************************************************
from django.db import models
from django.contrib.auth.models import User, Group # Importamos Group y User
from django.db.models.signals import post_save #Siganal para saber cuando se crea un nuevo usuario 
from django.dispatch import receiver

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
    onboarded = models.BooleanField(default=False)
    role = models.ForeignKey(Group, null=True, blank=True, on_delete=models.SET_NULL) 

    def __str__(self):
        return f"Perfil de {self.user.username}"
    
    class Meta:
        #Para permisos personalizado s
        permissions = (
            ("can_delete_user", "Podrá eliminar usuarios"),
        )
    
#CREAR PERFIL AUTOMATICO PARA CADA USUARIO NUEVO CREADO ******************************************************************************************************************************************************************
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)

#////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
