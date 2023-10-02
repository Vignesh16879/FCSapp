# Django
from django.urls import include, path
from django.contrib.auth.views import LogoutView

# main.apps
from . import views


urlpatterns = [
    path("", views.index, name="index"),
    path("login/", views.login, name="login"),
    path("accounts/", include('allauth.urls')),
    path('logout', LogoutView.as_view()),
]