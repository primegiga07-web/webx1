import random
import requests
from datetime import date, timedelta
from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.db import transaction
from django.utils import timezone
from django.core.mail import send_mail
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from .models import UserProfile, ReferralSeries, Referral, Withdrawal, OutboxReferralCredit, OTPVerification

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

# --- Background Outbox Sync Runner ---
def sync_pending_credits():
    """
    Attempts to sync all pending cross-shard referral credits.
    Can be run synchronously during streak claims or via a cron job/worker.
    """
    pending = OutboxReferralCredit.objects.filter(status='PENDING_SYNC')
    shards_dir = getattr(settings, 'SHARDS_DIRECTORY', {})
    secret_key = getattr(settings, 'SHARD_SECRET_KEY', '')

    for credit in pending:
        credit.attempts += 1
        credit.last_attempt = timezone.now()
        
        prefix = credit.referrer_uid[:5]
        target_shard_url = shards_dir.get(prefix)

        if not target_shard_url:
            credit.status = 'FAILED'
            credit.save()
            continue

        try:
            url = f"{target_shard_url.rstrip('/')}/api/shards/credit-referral/"
            headers = {
                'Authorization': f"Bearer {secret_key}",
                'Content-Type': 'application/json'
            }
            payload = {
                'referrer_uid': credit.referrer_uid,
                'referee_uid': credit.referee_uid,
                'amount': credit.amount
            }
            resp = requests.post(url, headers=headers, json=payload, timeout=5)
            if resp.status_code == 200:
                credit.status = 'SYNCED'
            else:
                if credit.attempts >= 5:
                    credit.status = 'FAILED'
        except requests.RequestException:
            # Keep PENDING_SYNC for retry later
            pass
            
        credit.save()

# --- Shard Internal / Gateway API Endpoints ---

@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def verify_email(request):
    """
    Called securely by Gateway to check if an email exists on this shard.
    """
    # Verify secure bearer token
    auth_header = request.headers.get('Authorization', '')
    expected_token = f"Bearer {getattr(settings, 'SHARD_SECRET_KEY', '')}"
    if auth_header != expected_token:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    email = request.data.get('email', '').strip().lower()
    if not email:
        return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
        
    try:
        user = User.objects.get(email=email)
        return Response({
            'exists': True,
            'uid': user.username
        }, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'exists': False}, status=status.HTTP_200_OK)

@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
def verify_uid(request):
    """
    Called by Gateway to check if a UID exists on this shard.
    """
    uid = request.query_params.get('uid', '').strip().upper()
    try:
        profile = UserProfile.objects.get(uid=uid)
        return Response({
            'exists': True,
            'username': profile.user.username
        }, status=status.HTTP_200_OK)
    except UserProfile.DoesNotExist:
        return Response({'exists': False}, status=status.HTTP_200_OK)

@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def reserve_user(request):
    """
    Called securely by the Gateway to initialize a new user on this active shard.
    """
    # Verify secure bearer token
    auth_header = request.headers.get('Authorization', '')
    expected_token = f"Bearer {getattr(settings, 'SHARD_SECRET_KEY', '')}"
    print(f"DEBUG SHARD: auth_header={auth_header!r}")
    print(f"DEBUG SHARD: expected_token={expected_token!r}")
    if auth_header != expected_token:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    email = request.data.get('email', '').strip().lower()
    password = request.data.get('password', '')
    referred_by_uid = request.data.get('referred_by_uid')

    if not email or not password:
        return Response({'error': 'Email and password are required'}, status=status.HTTP_400_BAD_REQUEST)

    if User.objects.filter(email=email).exists():
        return Response({'error': 'Email already registered on this shard'}, status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        # Get active sequence series
        series = ReferralSeries.objects.filter(is_active=True).first()
        if not series:
            # Auto-create a default series fallback
            prefix = getattr(settings, 'SHARD_PREFIX', 'RW100')
            series = ReferralSeries.objects.create(prefix=prefix, current_counter=1, max_limit=999)

        uid = f"{series.prefix}{str(series.current_counter).zfill(3)}"
        
        # Increment counter
        series.current_counter += 1
        if series.current_counter > series.max_limit:
            series.is_active = False
        series.save()

        # Create auth User (inactive until OTP verification)
        user = User.objects.create_user(
            username=uid,
            email=email,
            password=password,
            is_active=False
        )

        # Create Profile
        UserProfile.objects.create(
            uid=uid,
            user=user,
            referred_by_uid=referred_by_uid
        )

        # Create local referral record
        if referred_by_uid:
            Referral.objects.create(
                referee_uid=uid,
                referrer_uid=referred_by_uid,
                reward_amount=300,
                status='PENDING_SYNC'
            )

    # Generate 5-digit verification OTP
    otp_code = str(random.randint(10000, 99999))
    OTPVerification.objects.update_or_create(
        email=email,
        defaults={'code': otp_code}
    )

    # Send email
    print(f"[OTP SYSTEM] Signup OTP for {email}: {otp_code}")
    try:
        send_mail(
            'WebX Verification Code',
            f'Your 5-digit WebX verification code is: {otp_code}',
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False,
        )
    except Exception as e:
        print(f"[OTP SYSTEM] SMTP failed to send signup OTP: {e}")

    return Response({
        'success': True,
        'uid': uid,
        'message': 'Registration successful. OTP sent.'
    }, status=status.HTTP_201_CREATED)

@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def credit_referral(request):
    """
    Called securely by another shard to credit a referrer's wallet.
    """
    auth_header = request.headers.get('Authorization', '')
    expected_token = f"Bearer {getattr(settings, 'SHARD_SECRET_KEY', '')}"
    if auth_header != expected_token:
        return Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

    referrer_uid = request.data.get('referrer_uid', '').strip().upper()
    referee_uid = request.data.get('referee_uid', '').strip().upper()
    amount = request.data.get('amount', 300)

    try:
        profile = UserProfile.objects.get(uid=referrer_uid)
        profile.rocket_coins += amount
        profile.save()
        return Response({'success': True, 'message': 'Coins credited successfully'}, status=status.HTTP_200_OK)
    except UserProfile.DoesNotExist:
        return Response({'error': 'Referrer profile not found on this shard'}, status=status.HTTP_404_NOT_FOUND)

# --- User-Facing Auth & Account API Endpoints ---

@api_view(['POST'])
@permission_classes([AllowAny])
def user_login(request):
    """
    Logs in the user and returns simple JWT tokens.
    """
    email = request.data.get('email', '').strip().lower()
    password = request.data.get('password', '')

    if not email or not password:
        return Response({'success': False, 'error': 'Email and password are required'}, status=status.HTTP_400_BAD_REQUEST)

    # Find username from email
    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({'success': False, 'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

    user = authenticate(username=user.username, password=password)
    if user is not None:
        if not user.is_active:
            # Resend OTP
            otp_code = str(random.randint(10000, 99999))
            OTPVerification.objects.update_or_create(email=email, defaults={'code': otp_code})
            print(f"[OTP SYSTEM] Resend OTP for {email}: {otp_code}")
            try:
                send_mail(
                    'WebX Verification Code',
                    f'Your 5-digit WebX verification code is: {otp_code}',
                    settings.DEFAULT_FROM_EMAIL,
                    [email],
                    fail_silently=False,
                )
            except Exception as e:
                print(f"[OTP SYSTEM] SMTP failed to resend OTP: {e}")
            return Response({'success': False, 'error': 'Account not verified. OTP sent to your email.'}, status=status.HTTP_403_FORBIDDEN)
        
        tokens = get_tokens_for_user(user)
        return Response({
            'success': True,
            'uid': user.username,
            'email': user.email,
            'tokens': tokens
        }, status=status.HTTP_200_OK)
    else:
        return Response({'success': False, 'error': 'Wrong password'}, status=status.HTTP_401_UNAUTHORIZED)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    """
    Confirms registration code and activates the account.
    """
    email = request.data.get('email', '').strip().lower()
    code = request.data.get('code', '').strip()

    if not email or not code:
        return Response({'success': False, 'error': 'Email and code are required'}, status=status.HTTP_400_BAD_REQUEST)

    # Allow validOtp '86300' for developer testing convenience
    is_test_otp = (code == '86300')

    try:
        verification = OTPVerification.objects.get(email=email)
        is_valid = (verification.code == code or is_test_otp)
    except OTPVerification.DoesNotExist:
        is_valid = is_test_otp

    if is_valid:
        try:
            user = User.objects.get(email=email)
            # Delete verification OTP only for signup flow (inactive users).
            # For forgot password flow, we preserve it so update_password view can verify it.
            if not user.is_active:
                user.is_active = True
                user.save()
                OTPVerification.objects.filter(email=email).delete()
            
            tokens = get_tokens_for_user(user)
            return Response({
                'success': True,
                'message': 'Code verified successfully',
                'uid': user.username,
                'email': user.email,
                'tokens': tokens
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'success': False, 'error': 'User matching this email not found'}, status=status.HTTP_404_NOT_FOUND)
    else:
        return Response({'success': False, 'error': 'Invalid code. Please try again.'}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    """
    Sends reset OTP code to the email.
    """
    email = request.data.get('email', '').strip().lower()
    if not email:
        return Response({'success': False, 'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)

    if not User.objects.filter(email=email).exists():
        return Response({'success': False, 'error': 'Email not registered'}, status=status.HTTP_404_NOT_FOUND)

    otp_code = str(random.randint(10000, 99999))
    OTPVerification.objects.update_or_create(email=email, defaults={'code': otp_code})

    print(f"[OTP SYSTEM] Reset Password OTP for {email}: {otp_code}")
    try:
        send_mail(
            'WebX Reset Code',
            f'Your 5-digit password reset verification code is: {otp_code}',
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False,
        )
    except Exception as e:
        print(f"[OTP SYSTEM] SMTP failed to send reset OTP: {e}")

    return Response({
        'success': True,
        'message': f'Reset code sent successfully to {email}'
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def update_password(request):
    """
    Sets a new password. Needs OTP verify step code validation.
    """
    email = request.data.get('email', '').strip().lower()
    code = request.data.get('code', '').strip()
    new_password = request.data.get('new_password', '')
    confirm_password = request.data.get('confirm_password', '')

    if not email or not code or not new_password or not confirm_password:
        return Response({'success': False, 'error': 'All fields are required'}, status=status.HTTP_400_BAD_REQUEST)

    if new_password != confirm_password:
        return Response({'success': False, 'error': 'Passwords do not match'}, status=status.HTTP_400_BAD_REQUEST)

    if len(new_password) < 6:
        return Response({'success': False, 'error': 'Password must be at least 6 characters'}, status=status.HTTP_400_BAD_REQUEST)

    # Check OTP
    is_test_otp = (code == '86300')
    try:
        verification = OTPVerification.objects.get(email=email)
        is_valid = (verification.code == code or is_test_otp)
    except OTPVerification.DoesNotExist:
        is_valid = is_test_otp

    if not is_valid:
        return Response({'success': False, 'error': 'Invalid code. Please try again.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
        user.set_password(new_password)
        user.is_active = True
        user.save()
        
        OTPVerification.objects.filter(email=email).delete()
        
        return Response({
            'success': True,
            'message': 'Password reset successful. You can now login.'
        }, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'success': False, 'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    """
    Returns user details, coins balance, and streaks.
    """
    profile = request.user.profile
    return Response({
        'success': True,
        'uid': profile.uid,
        'username': request.user.username,
        'email': request.user.email,
        'rocket_coins': profile.rocket_coins,
        'streak_count': profile.streak_count,
        'referred_by_uid': profile.referred_by_uid
    }, status=status.HTTP_200_OK)

# --- Streak Claims & Payouts APIs ---

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_streak(request):
    """
    Increments daily streak and claims milestone bonuses.
    """
    profile = request.user.profile
    today = date.today()

    if profile.last_streak_claim == today:
        return Response({'success': False, 'error': 'Already claimed today'}, status=status.HTTP_400_BAD_REQUEST)

    consecutive = False
    if profile.last_streak_claim:
        yesterday = today - timedelta(days=1)
        if profile.last_streak_claim == yesterday:
            consecutive = True

    with transaction.atomic():
        if consecutive:
            profile.streak_count += 1
        else:
            profile.streak_count = 1
        
        profile.last_streak_claim = today

        # Calculate milestone bonus
        bonus = 0
        if profile.streak_count == 5:
            bonus = 250
        elif profile.streak_count == 10:
            bonus = 500
        elif profile.streak_count == 30:
            bonus = 2500
        else:
            # Standard daily check-in reward
            bonus = 20

        profile.rocket_coins += bonus
        profile.save()

        # Unlock pending referral reward if streak exceeds 3 (greater than 3)
        if profile.referred_by_uid and profile.streak_count >= 4:
            referral = Referral.objects.filter(
                referee_uid=profile.uid,
                referrer_uid=profile.referred_by_uid,
                status='PENDING_SYNC'
            ).first()
            
            if referral:
                # Add to outbox sync queue
                OutboxReferralCredit.objects.create(
                    referrer_uid=profile.referred_by_uid,
                    referee_uid=profile.uid,
                    amount=referral.reward_amount,
                    status='PENDING_SYNC'
                )
                referral.status = 'SYNCED'
                referral.save()

    # Trigger outbox sync synchronously to process referral immediately if possible
    if profile.referred_by_uid and profile.streak_count >= 4:
        sync_pending_credits()

    return Response({
        'success': True,
        'message': f"Claimed successfully! Streak count is now {profile.streak_count} days. +{bonus} Rocket Coins.",
        'streak_count': profile.streak_count,
        'rocket_coins': profile.rocket_coins
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_withdrawal(request):
    """
    Creates a pending withdrawal, debits user balance, and resets streak.
    """
    profile = request.user.profile
    name = request.data.get('name', '').strip()
    upi_id = request.data.get('upi_id', '').strip()
    amount_coins = request.data.get('amount_coins')

    if not name or not upi_id or amount_coins is None:
        return Response({'success': False, 'error': 'Name, UPI ID, and amount are required'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        amount_coins = int(amount_coins)
    except ValueError:
        return Response({'success': False, 'error': 'Invalid amount'}, status=status.HTTP_400_BAD_REQUEST)

    if amount_coins < 1000:
        return Response({'success': False, 'error': 'Minimum withdrawal limit is 1000 Rocket Coins.'}, status=status.HTTP_400_BAD_REQUEST)

    if profile.rocket_coins < amount_coins:
        return Response({'success': False, 'error': 'Insufficient balance'}, status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        # Debit coins
        profile.rocket_coins -= amount_coins
        # Reset streak on withdrawal
        profile.streak_count = 0
        profile.save()

        # Create Withdrawal
        Withdrawal.objects.create(
            user=profile,
            name=name,
            upi_id=upi_id,
            amount_coins=amount_coins,
            status='PENDING'
        )

    return Response({
        'success': True,
        'message': f"Withdrawal request of {amount_coins} Rocket Coins submitted successfully.",
        'rocket_coins': profile.rocket_coins,
        'streak_count': profile.streak_count
    }, status=status.HTTP_201_CREATED)
