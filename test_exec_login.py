import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"
email = "testexec_2c66e1@goathlete.com"
password = "Test@12345"

# 1. Login
print("1. Logging in...")
res = requests.post(f"{BASE_URL}/users/login/", json={"username": email, "password": password})
if res.status_code != 200:
    print(f"FAILED TO LOGIN: {res.text}")
    exit(1)

data = res.json()
token = data.get('access')
requires_change = data.get('requires_password_change')
print(f"Login successful! requires_password_change={requires_change}")

if not requires_change:
    print("FAILED: Flag is false on fresh login.")
    exit(1)

# 2. Change password
print("2. Changing password...")
headers = {"Authorization": f"Bearer {token}"}
change_res = requests.post(
    f"{BASE_URL}/users/change_password/", 
    json={"old_password": password, "new_password": "NewSecurePassword123!"},
    headers=headers
)

if change_res.status_code != 200:
    print(f"FAILED TO CHANGE PASSWORD: {change_res.text}")
    exit(1)

print("Password changed successfully!")

# 3. Login with new password
print("3. Logging in with new password...")
res2 = requests.post(f"{BASE_URL}/users/login/", json={"username": email, "password": "NewSecurePassword123!"})
if res2.status_code != 200:
    print(f"FAILED TO LOGIN with new password: {res2.text}")
    exit(1)

data2 = res2.json()
requires_change2 = data2.get('requires_password_change')
print(f"Login successful! requires_password_change={requires_change2}")

if requires_change2:
    print("FAILED: Flag is still true after changing password.")
    exit(1)

print("ALL TESTS PASSED!")
