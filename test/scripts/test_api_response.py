#!/usr/bin/env python3
"""
Script to inspect the actual API response structure.
"""

import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src', 'app'))

from api_client import EurogamesAPIClient

def main():
    client = EurogamesAPIClient()

    print("\n" + "="*80)
    print("API RESPONSE STRUCTURE INSPECTION")
    print("="*80 + "\n")

    # Get raw response for games
    import requests
    url = "https://eurogames.web-c10.workers.dev/v1/games"
    headers = client._get_auth_header()

    try:
        response = requests.get(url, headers=headers, params={'status': 'Playing'})
        data = response.json()

        print("GET /v1/games?status=Playing Response:")
        print("-" * 80)
        print(f"Status Code: {response.status_code}")
        print(f"Response Type: {type(data)}")
        print(f"Response Keys: {list(data.keys()) if isinstance(data, dict) else 'N/A'}")
        print(f"\nFull Response (first 500 chars):")
        print(json.dumps(data, indent=2)[:500])
        print()

        # Check the structure
        if isinstance(data, dict):
            for key, value in data.items():
                if isinstance(value, list):
                    print(f"Key '{key}': list with {len(value)} items")
                    if value:
                        print(f"  First item: {value[0]}")
                elif isinstance(value, dict):
                    print(f"Key '{key}': dict with keys: {list(value.keys())}")
                else:
                    print(f"Key '{key}': {type(value).__name__} = {value}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

    print("\n" + "="*80)

if __name__ == '__main__':
    main()
