from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    uid = models.CharField(max_length=12, primary_key=True)  # e.g., RW100001
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    referred_by_uid = models.CharField(max_length=12, blank=True, null=True)  # Tracks who referred them
    rocket_coins = models.IntegerField(default=0)
    streak_count = models.IntegerField(default=0)
    last_streak_claim = models.DateField(blank=True, null=True)
    last_active = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.uid} ({self.user.email}) - {self.rocket_coins} coins, {self.streak_count} streak"

class ReferralSeries(models.Model):
    prefix = models.CharField(max_length=10, default="RW100", unique=True)
    current_counter = models.IntegerField(default=1)
    max_limit = models.IntegerField(default=999)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Referral Series"

    def __str__(self):
        return f"{self.prefix}: {self.current_counter}/{self.max_limit} ({'Active' if self.is_active else 'Inactive'})"

class Referral(models.Model):
    STATUS_CHOICES = (
        ('PENDING_SYNC', 'Pending Sync'),
        ('SYNCED', 'Synced'),
        ('FAILED', 'Failed'),
    )
    referee_uid = models.CharField(max_length=12)
    referrer_uid = models.CharField(max_length=12)
    reward_amount = models.IntegerField(default=300)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING_SYNC')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Referee: {self.referee_uid} -> Referrer: {self.referrer_uid} ({self.status})"

class Withdrawal(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('SUCCESSFUL', 'Successful'),
        ('FAILED', 'Failed'),
    )
    user = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='withdrawals')
    name = models.CharField(max_length=100)
    upi_id = models.CharField(max_length=100)
    amount_coins = models.IntegerField()  # Min 1000
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Withdrawal by {self.user.uid} - {self.amount_coins} coins ({self.status})"

class OutboxReferralCredit(models.Model):
    STATUS_CHOICES = (
        ('PENDING_SYNC', 'Pending Sync'),
        ('SYNCED', 'Synced'),
        ('FAILED', 'Failed'),
    )
    referrer_uid = models.CharField(max_length=12)
    referee_uid = models.CharField(max_length=12)
    amount = models.IntegerField(default=300)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING_SYNC')
    attempts = models.IntegerField(default=0)
    last_attempt = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Outbox: Sync reward {self.amount} to {self.referrer_uid} ({self.status})"

class OTPVerification(models.Model):
    email = models.EmailField(unique=True)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"OTP for {self.email}: {self.code}"

