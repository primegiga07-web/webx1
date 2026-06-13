from django.db import models

class ShardRegistry(models.Model):
    prefix = models.CharField(max_length=10, unique=True)  # e.g., RW100
    shard_url = models.CharField(max_length=255)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = "Shard Registries"

    def __str__(self):
        return f"{self.prefix} -> {self.shard_url} ({'Active' if self.is_active else 'Inactive'})"
