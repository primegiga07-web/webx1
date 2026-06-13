from django.contrib import admin
from django.db import transaction
from .models import UserProfile, ReferralSeries, Referral, Withdrawal, OutboxReferralCredit, OTPVerification

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('uid', 'email_display', 'rocket_coins', 'streak_count', 'last_streak_claim', 'last_active')
    search_fields = ('uid', 'user__email', 'user__username')
    list_filter = ('last_streak_claim',)

    def email_display(self, obj):
        return obj.user.email
    email_display.short_description = 'Email'

@admin.register(ReferralSeries)
class ReferralSeriesAdmin(admin.ModelAdmin):
    list_display = ('prefix', 'current_counter', 'max_limit', 'is_active')
    list_filter = ('is_active',)

@admin.register(Referral)
class ReferralAdmin(admin.ModelAdmin):
    list_display = ('referee_uid', 'referrer_uid', 'reward_amount', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('referee_uid', 'referrer_uid')

@admin.register(Withdrawal)
class WithdrawalAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'name', 'upi_id', 'amount_coins', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('user__uid', 'upi_id', 'name')
    actions = ['approve_withdrawals', 'reject_withdrawals']

    @admin.action(description="Approve selected pending withdrawals")
    def approve_withdrawals(self, request, queryset):
        updated = queryset.filter(status='PENDING').update(status='SUCCESSFUL')
        self.message_user(request, f"Successfully approved {updated} pending withdrawals.")

    @admin.action(description="Reject selected pending withdrawals (refund coins)")
    def reject_withdrawals(self, request, queryset):
        count = 0
        with transaction.atomic():
            for withdrawal in queryset.filter(status='PENDING'):
                # Refund the coins
                profile = withdrawal.user
                profile.rocket_coins += withdrawal.amount_coins
                profile.save()
                
                # Mark as failed
                withdrawal.status = 'FAILED'
                withdrawal.save()
                count += 1
        self.message_user(request, f"Successfully rejected {count} pending withdrawals and refunded coins to users.")

@admin.register(OutboxReferralCredit)
class OutboxReferralCreditAdmin(admin.ModelAdmin):
    list_display = ('referrer_uid', 'referee_uid', 'amount', 'status', 'attempts', 'last_attempt', 'created_at')
    list_filter = ('status', 'last_attempt')
    search_fields = ('referrer_uid', 'referee_uid')

@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    list_display = ('email', 'code', 'created_at')
    search_fields = ('email',)
