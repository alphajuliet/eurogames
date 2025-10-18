#!/usr/bin/env python3
"""
Script to inspect the winner API response structure.
"""

import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src', 'app'))

from api_client import EurogamesAPIClient

def main():
    client = EurogamesAPIClient()

    print("\n" + "="*80)
    print("WINNER STATS API RESPONSE INSPECTION")
    print("="*80 + "\n")

    # Get raw response for winner stats
    import requests
    url = "https://eurogames.web-c10.workers.dev/v1/stats/winners"
    headers = client._get_auth_header()

    try:
        response = requests.get(url, headers=headers)
        data = response.json()

        print("GET /v1/stats/winners Response:")
        print("-" * 80)
        print(f"Status Code: {response.status_code}")
        print(f"Response Type: {type(data)}")
        print(f"Response Keys: {list(data.keys()) if isinstance(data, dict) else 'N/A'}")
        print()

        # Get the actual winner data
        winners = data.get('data', data) if isinstance(data, dict) else data

        if isinstance(winners, list):
            print(f"Number of winners: {len(winners)}")
            if winners:
                print(f"\nFirst winner item:")
                print(json.dumps(winners[0], indent=2))
                print(f"\nFirst item keys: {list(winners[0].keys())}")

                # Show a few more items to see if all have same structure
                print(f"\nSecond item keys: {list(winners[1].keys()) if len(winners) > 1 else 'N/A'}")

                # Check what keys are present in all items
                all_keys = set()
                for winner in winners:
                    if isinstance(winner, dict):
                        all_keys.update(winner.keys())

                print(f"\nAll unique keys across all items: {sorted(all_keys)}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

    print("\n" + "="*80)

if __name__ == '__main__':
    main()
