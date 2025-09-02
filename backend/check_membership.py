#!/usr/bin/env python3
"""
Quick script to verify if Poison (user 110) is a member of the community
that contains post 45, and check post details.
"""

import requests

# API credentials  
POISON_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzM3NzcwMzU1LCJpYXQiOjE3MzU5NzAzNTUsImp0aSI6IjJmOWJkNzNjMzQ0OTRmMmU5YTQwNjY3ODY1MzFkN2QwIiwidXNlcl9pZCI6MTEwfQ.yJCfZVnJ2FYkiAJv7YwqEjJlT7fEQqwFbJo4KOWJa0s"
BASE_URL = "http://localhost:8000"

def get_post_details(post_id, token):
    """Get post details including community info"""
    headers = {'Authorization': f'Bearer {token}'}
    
    try:
        # Get post details
        response = requests.get(f"{BASE_URL}/api/posts/{post_id}/", headers=headers)
        
        if response.status_code == 200:
            post_data = response.json()
            print(f"📝 Post {post_id} Details:")
            print(f"  - Title: {post_data.get('title', 'N/A')}")
            print(f"  - Community ID: {post_data.get('community', 'N/A')}")
            print(f"  - Community Name: {post_data.get('community_name', 'N/A')}")
            print(f"  - Author ID: {post_data.get('author', 'N/A')}")
            print(f"  - Author Username: {post_data.get('author_username', 'N/A')}")
            return post_data.get('community')
        else:
            print(f"❌ Failed to get post details: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error getting post details: {e}")
        return None

def check_community_membership(community_id, token):
    """Check if user is member of the community"""
    headers = {'Authorization': f'Bearer {token}'}
    
    try:
        # Get user's memberships
        response = requests.get(f"{BASE_URL}/api/memberships/", headers=headers)
        
        if response.status_code == 200:
            memberships = response.json()
            
            # Check if user is member of the specific community
            for membership in memberships:
                if membership.get('community') == community_id:
                    print(f"✅ User IS a member of community {community_id}")
                    print(f"  - Role: {membership.get('role', 'N/A')}")
                    print(f"  - Joined: {membership.get('created_at', 'N/A')}")
                    return True
            
            print(f"❌ User is NOT a member of community {community_id}")
            print(f"🔍 User's communities:")
            for membership in memberships:
                print(f"  - Community {membership.get('community')}: {membership.get('role', 'N/A')}")
            return False
            
        else:
            print(f"❌ Failed to get memberships: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error checking membership: {e}")
        return False

def main():
    print("🔍 Checking Post 45 and Poison's Membership")
    print("=" * 50)
    
    # Get post details
    community_id = get_post_details(45, POISON_TOKEN)
    
    if community_id:
        print(f"\n👥 Checking membership in community {community_id}")
        is_member = check_community_membership(community_id, POISON_TOKEN)
        
        if is_member:
            print(f"\n✅ CONCLUSION: Poison should be able to react to post 45")
            print(f"   The 500 error is NOT due to community membership")
        else:
            print(f"\n❌ CONCLUSION: This explains the 500 error!")
            print(f"   Poison needs to join community {community_id} first")
    else:
        print(f"\n❌ Could not determine community for post 45")

if __name__ == "__main__":
    main()
