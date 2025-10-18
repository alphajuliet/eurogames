#!/usr/bin/env python3
"""
Test to check all games across all statuses from the API.
"""

import sys
import os
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src', 'app'))

def main():
    import requests
    from api_client import EurogamesAPIClient

    client = EurogamesAPIClient()

    print("\n" + "="*80)
    print("Checking All Games Across All Statuses")
    print("="*80 + "\n")

    # Direct API call without status parameter
    print("Test 1: Raw API call with NO status parameter")
    print("-" * 80)
    try:
        url = "https://eurogames.web-c10.workers.dev/v1/games"
        headers = client._get_auth_header()
        response = requests.get(url, headers=headers)
        data = response.json()

        games = data.get('data', []) if isinstance(data, dict) else data
        print(f"Total games returned: {len(games)}")

        # Count by status
        status_counts = {}
        for game in games:
            status = game.get('status', 'Unknown')
            status_counts[status] = status_counts.get(status, 0) + 1

        print(f"\nBreakdown by status:")
        for status, count in sorted(status_counts.items()):
            print(f"  {status}: {count} games")

        # Show samples of different statuses
        print(f"\nSample games by status:")
        status_samples = {}
        for game in games:
            status = game.get('status', 'Unknown')
            if status not in status_samples:
                status_samples[status] = []
            if len(status_samples[status]) < 2:
                status_samples[status].append(game.get('name'))

        for status in sorted(status_samples.keys()):
            print(f"  {status}: {', '.join(status_samples[status])}")

        print(f"\nMeta info:")
        meta = data.get('meta', {})
        print(f"  Total: {meta.get('total')}")
        print(f"  Limit: {meta.get('limit')}")
        print(f"  Offset: {meta.get('offset')}")

    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

    print()

    # Test 2: Using updated get_games_list()
    print("Test 2: Using updated get_games_list() method (no parameters)")
    print("-" * 80)
    try:
        all_games = client.get_games_list()
        print(f"✓ Returns {len(all_games)} games")

        # Count by status
        status_counts = {}
        for game in all_games:
            status = game.get('status', 'Unknown')
            status_counts[status] = status_counts.get(status, 0) + 1

        print(f"\nBreakdown by status:")
        for status, count in sorted(status_counts.items()):
            print(f"  {status}: {count} games")

    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

    print()
    print("="*80)
    print("Complete - Check if there are games with different statuses")
    print("="*80 + "\n")

    return 0

if __name__ == '__main__':
    sys.exit(main())
