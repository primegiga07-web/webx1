from django.urls import path
from . import views

urlpatterns = [
    path('gateway/check-email/', views.check_email, name='check_email'),
    path('gateway/login/', views.gateway_login, name='gateway_login'),
    path('gateway/signup/', views.gateway_signup, name='gateway_signup'),
]
