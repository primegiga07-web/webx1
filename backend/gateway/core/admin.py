from django.contrib import admin
from .models import ShardRegistry

@admin.register(ShardRegistry)
class ShardRegistryAdmin(admin.ModelAdmin):
    list_display = ('prefix', 'shard_url', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('prefix', 'shard_url')
