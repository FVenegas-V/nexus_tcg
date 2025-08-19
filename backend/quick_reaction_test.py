import requests
import sys

print("=== QUICK REACTION TEST ===")

# Login
print("1. Login...")
login_response = requests.post(
    "http://127.0.0.1:8000/api/auth/login/",
    json={"username": "test1", "password": "password123"}
)

print(f"Login status: {login_response.status_code}")

if login_response.status_code == 200:
    token = login_response.json()["access"]
    print("✅ Login OK")
    
    # Test reacción
    print("2. Testing reaction...")
    reaction_response = requests.post(
        "http://127.0.0.1:8000/api/posts/29/toggle_reaction/",
        json={"reaction_type": "like"},
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
    )
    
    print(f"Reaction status: {reaction_response.status_code}")
    print(f"Reaction response: {reaction_response.text}")
    
    if reaction_response.status_code == 200:
        print("✅ SUCCESS!")
    else:
        print("❌ FAILED!")
else:
    print("❌ Login failed")
    print(f"Response: {login_response.text}")

print("=== END TEST ===")
sys.exit(0)
