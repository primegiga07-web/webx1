import json
import requests
from django.conf import settings
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import ShardRegistry
from concurrent.futures import ThreadPoolExecutor, as_completed

def _check_email_on_shard(shard_url, email):
    try:
        verify_url = f"{shard_url.rstrip('/')}/api/shards/verify-email/"
        headers = {
            'Authorization': f"Bearer {getattr(settings, 'SHARD_SECRET_KEY', '')}",
            'Content-Type': 'application/json'
        }
        payload = {'email': email}
        resp = requests.post(verify_url, headers=headers, json=payload, timeout=4)
        if resp.status_code == 200:
            data = resp.json()
            if data.get('exists') == True:
                return data.get('uid'), shard_url
    except requests.RequestException:
        pass
    return None

@api_view(['POST'])
@permission_classes([AllowAny])
def check_email(request):
    email = request.data.get('email', '').strip().lower()
    if not email:
        return Response({'success': False, 'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    shards = ShardRegistry.objects.all()
    exists = False
    
    with ThreadPoolExecutor(max_workers=max(len(shards), 1)) as executor:
        futures = {executor.submit(_check_email_on_shard, s.shard_url, email): s for s in shards}
        for future in as_completed(futures):
            res = future.result()
            if res:
                exists = True
                break
                
    return Response({'success': True, 'exists': exists}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([AllowAny])
def gateway_login(request):
    email = request.data.get('email', '').strip().lower()
    if not email:
        return Response({'success': False, 'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)

    shards = ShardRegistry.objects.all()
    found_uid = None
    found_shard_url = None

    with ThreadPoolExecutor(max_workers=max(len(shards), 1)) as executor:
        futures = {executor.submit(_check_email_on_shard, s.shard_url, email): s for s in shards}
        for future in as_completed(futures):
            res = future.result()
            if res:
                found_uid, found_shard_url = res
                break

    if found_shard_url:
        return Response({
            'success': True,
            'shard_url': found_shard_url,
            'uid': found_uid
        }, status=status.HTTP_200_OK)
    else:
        return Response({
            'success': False,
            'error': 'User not registered'
        }, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([AllowAny])
def gateway_signup(request):
    email = request.data.get('email', '').strip().lower()
    password = request.data.get('password', '')
    referral_code = request.data.get('referral_code', '').strip().upper()

    if not email or not password:
        return Response({'success': False, 'error': 'Email and password are required'}, status=status.HTTP_400_BAD_REQUEST)

    # 1. Check duplicate email globally across all shards in parallel
    shards = ShardRegistry.objects.all()
    exists = False
    
    with ThreadPoolExecutor(max_workers=max(len(shards), 1)) as executor:
        futures = {executor.submit(_check_email_on_shard, s.shard_url, email): s for s in shards}
        for future in as_completed(futures):
            res = future.result()
            if res:
                exists = True
                break

    if exists:
        return Response({'success': False, 'error': 'Email already registered'}, status=status.HTTP_400_BAD_REQUEST)

    # 2. Find active shard
    active_shard = ShardRegistry.objects.filter(is_active=True).first()
    if not active_shard:
        return Response({'success': False, 'error': 'No active signup server available'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    referred_by_uid = None
    referrer_info = None

    # 3. Validate Referral Code if provided
    if referral_code:
        if len(referral_code) < 5:
            return Response({'success': False, 'error': 'Invalid referral code format'}, status=status.HTTP_400_BAD_REQUEST)
        
        prefix = referral_code[:5]
        
        try:
            ref_shard = ShardRegistry.objects.get(prefix=prefix)
            ref_shard_url = ref_shard.shard_url
        except ShardRegistry.DoesNotExist:
            shards_dir = getattr(settings, 'SHARDS_DIRECTORY', {})
            ref_shard_url = shards_dir.get(prefix)

        if not ref_shard_url:
            return Response({'success': False, 'error': 'Invalid referral code prefix'}, status=status.HTTP_400_BAD_REQUEST)

        # Call the referrer's shard verify-uid API
        try:
            verify_url = f"{ref_shard_url.rstrip('/')}/api/shards/verify-uid/"
            resp = requests.get(verify_url, params={'uid': referral_code}, timeout=5)
            if resp.status_code == 200:
                resp_data = resp.json()
                if resp_data.get('exists') == True:
                    referred_by_uid = referral_code
                    referrer_info = f"You're referred by {resp_data.get('username')}"
                else:
                    return Response({'success': False, 'error': 'Referral code does not exist'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                return Response({'success': False, 'error': 'Referral verification failed'}, status=status.HTTP_400_BAD_REQUEST)
        except requests.RequestException:
            return Response({
                'success': False,
                'error': 'Referrer server is temporarily unreachable. Please report this to support.'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    # 4. Reserve user on active shard
    try:
        reserve_url = f"{active_shard.shard_url.rstrip('/')}/api/shards/reserve-user/"
        print(f"DEBUG GATEWAY: sending token Bearer {getattr(settings, 'SHARD_SECRET_KEY', '')!r} to url {reserve_url}")
        headers = {
            'Authorization': f"Bearer {getattr(settings, 'SHARD_SECRET_KEY', '')}",
            'Content-Type': 'application/json'
        }
        payload = {
            'email': email,
            'password': password,
            'referred_by_uid': referred_by_uid
        }
        resp = requests.post(reserve_url, headers=headers, json=payload, timeout=8)
        
        if resp.status_code == 200 or resp.status_code == 201:
            resp_data = resp.json()
            uid = resp_data.get('uid')
            
            return Response({
                'success': True,
                'shard_url': active_shard.shard_url,
                'uid': uid,
                'referrer_info': referrer_info,
                'message': 'Registration successful. OTP sent.'
            }, status=status.HTTP_201_CREATED)
        else:
            resp_data = resp.json()
            return Response({
                'success': False,
                'error': resp_data.get('error', 'Failed to register on signup server')
            }, status=resp.status_code)
            
    except requests.RequestException:
        return Response({
            'success': False,
            'error': 'Active signup server is temporarily unreachable. Please report this to support.'
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
