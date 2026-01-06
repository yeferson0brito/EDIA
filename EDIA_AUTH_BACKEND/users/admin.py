from django.contrib import admin
from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin as DefaultUserAdmin
#CAMPOS MOSTRADOS EN EL PANEL DE ADMINISTRACION DE DJANGO (Exactament en el modelo del User)*****************************************************************************************


class UserAdmin(DefaultUserAdmin):
    #columnas a mostrar
    list_display = ('username', 'email', 'first_name', 'last_name', 'get_groups')

    #se extraen los datos
    def get_groups(self, obj):
        return ", ".join([g.name for g in obj.groups.all()])
    get_groups.short_description = 'Groups'
    get_groups.admin_order_field = None  # Establecemos que la columna no se puede ordenar

# reemplazamos el UserAdmin por defecto
admin.site.unregister(User)
admin.site.register(User, UserAdmin)
