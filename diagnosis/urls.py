from django.urls import path
from .views import ask_doctor

urlpatterns = [
    path('ask/', ask_doctor, name='ask_doctor'),
]