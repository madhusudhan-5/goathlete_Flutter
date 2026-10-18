import requests
import json
import uuid

BASE_URL = "http://127.0.0.1:8000/api"

# Use the credentials I just generated
email = "testexec_2c66e1@goathlete.com"
password = "Test@12345"

print("--- END TO END TEST: FORCE PASSWORD CHANGE ---")
print(f"1. Logging in as {email} with default password...")
res = requests.post(f"{BASE_URL}/users/login/", json={"username": email, "password": password})
if res.status_code != 200:
    print(f"FAILED TO LOGIN: {res.text}")
    exit(1)

token = res.json().get('access')
print(f"✓ Login successful! Received JWT token.")

print("\n2. Fetching profile to check requires_password_change flag...")
headers = {"Authorization": f"Bearer {token}"}
prof_res = requests.get(f"{BASE_URL}/users/profile/", headers=headers)
if prof_res.status_code != 200:
    print(f"FAILED TO FETCH PROFILE: {prof_res.text}")
    exit(1)

requires_change = prof_res.json().get('requires_password_change')
print(f"✓ Profile fetch successful! requires_password_change = {requires_change}")

if not requires_change:
    print("❌ FAILED: Flag is false on fresh login. Expected True!")
    exit(1)

print("\n3. Changing password...")
new_password = "NewSecurePassword123!"
change_res = requests.post(
    f"{BASE_URL}/users/change-password/", 
    json={"old_password": password, "new_password": new_password},
    headers=headers
)

if change_res.status_code != 200:
    print(f"FAILED TO CHANGE PASSWORD: {change_res.text}")
    exit(1)

print("✓ Password changed successfully!")

print("\n4. Logging in with NEW password...")
res2 = requests.post(f"{BASE_URL}/users/login/", json={"username": email, "password": new_password})
if res2.status_code != 200:
    print(f"FAILED TO LOGIN with new password: {res2.text}")
    exit(1)

token2 = res2.json().get('access')
print("✓ Login successful with NEW password!")

print("\n5. Fetching profile to ensure flag is cleared...")
headers2 = {"Authorization": f"Bearer {token2}"}
prof_res2 = requests.get(f"{BASE_URL}/users/profile/", headers=headers2)
requires_change2 = prof_res2.json().get('requires_password_change')
print(f"✓ Profile fetch successful! requires_password_change = {requires_change2}")

if requires_change2:
    print("❌ FAILED: Flag is still true after changing password. Expected False!")
    exit(1)

print("\n✅ ALL END TO END TESTS PASSED SUCCESSFULLY!")
