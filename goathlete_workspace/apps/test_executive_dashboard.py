import requests

BASE_URL = 'http://127.0.0.1:8000/api'
PHONE = '9999999999'

try:
    print("Sending OTP...")
    resp = requests.post(f"{BASE_URL}/users/send-otp/", json={'phone_number': PHONE})
    resp.raise_for_status()
    otp = resp.json().get('dev_otp')
    print("OTP:", otp)

    print("Verifying OTP...")
    resp = requests.post(f"{BASE_URL}/users/verify-otp/", json={'phone_number': PHONE, 'otp_code': otp})
    resp.raise_for_status()
    token = resp.json().get('access')
    print("Token received")

    # The user might be CUSTOMER by default. Let's try hitting the dashboard anyway to see if it 500s or 403s.
    print("Hitting dashboard stats...")
    headers = {'Authorization': f'Bearer {token}'}
    resp = requests.get(f"{BASE_URL}/venues/pre-register-venues/dashboard_stats/", headers=headers)
    print("Status:", resp.status_code)
    print("Response:", resp.text)

except Exception as e:
    print("Error:", e)
    if hasattr(e, 'response') and e.response is not None:
        print(e.response.text)
