from django.contrib import admin
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.authtoken import views
from api.views import UserView, ImageStoreView, ImageSearchView

urlpatterns = [
                  path('admin/', admin.site.urls),
                  path('auth/', views.obtain_auth_token),
                  path('user/', UserView.as_view()),
                  path('search/', ImageSearchView.as_view()),
                  path('images/', ImageStoreView.as_view())
              ] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
