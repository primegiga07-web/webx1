from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.db import connection

def health(request):
    try:
        # Ping the DB so Supabase never pauses the project
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1')
        return JsonResponse({'status': 'ok', 'db': 'ok'})
    except Exception as e:
        return JsonResponse({'status': 'ok', 'db': 'error', 'detail': str(e)}, status=200)


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    path('health/', health),
]
