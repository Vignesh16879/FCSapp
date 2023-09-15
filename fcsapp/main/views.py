from django.shortcuts import render
from django.contrib.auth import logout as auth_logout
from django.contrib.auth.decorators import login_required


# Login
def login(request):
    pass


# Logout
def logout(request):
    pass


# go to Home Page
def index(request):
    return render(request, "login.html")