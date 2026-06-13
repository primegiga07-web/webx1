from django.urls import path
from . import views

urlpatterns = [
    # Gateway/Inter-shard Secure APIs
    path('shards/verify-uid/', views.verify_uid, name='verify_uid'),
    path('shards/verify-email/', views.verify_email, name='verify_email'),
    path('shards/reserve-user/', views.reserve_user, name='reserve_user'),
    path('shards/credit-referral/', views.credit_referral, name='credit_referral'),

    # User Auth & Session APIs
    path('auth/login/', views.user_login, name='user_login'),
    path('auth/verify-otp/', views.verify_otp, name='verify_otp'),
    path('auth/forgot-password/', views.request_password_reset, name='request_password_reset'),
    path('auth/reset-password/', views.update_password, name='update_password'),
    path('auth/profile/', views.get_user_profile, name='get_user_profile'),

    # Streaks & Wallet APIs
    path('activity/claim-streak/', views.claim_streak, name='claim_streak'),
    path('wallet/withdraw/', views.request_withdrawal, name='request_withdrawal'),
]
