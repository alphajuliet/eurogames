#!/usr/bin/env python3
"""
Test different ways to query the API for all games/statuses.
"""

import sys
import os
import requests

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src', 'app'))

from api_client import EurogamesAPIClient

def main():
    client = EurogamesAPIClient()

    print("\n" + "="*80)
    print("Testing Different API Query Options")
    print("="*80 + "\n")

    tests = [
        ("No status param", {}),
        ("status=null", {"status": None}),
        ("status=*", {"status": "*"}),
        ("status=all", {"status": "all"}),
        ("status=''", {"status": ""}),
        ("status=Inbox", {"status": "Inbox"}),
        ("status=Evaluating", {"status": "Evaluating"}),
        ("status=Playing", {"status": "Playing"}),
    ]

    url = "https://eurogames.web-c10.workers.dev/v1/games"
    headers = client._get_auth_header()

    for test_name, params_dict in tests:
        try:
            # Build params properly
            params = {k: v for k, v in params_dict.items() if v is not None} if params_dict else None

            response = requests.get(url, params=params, headers=headers, timeout=10)
            data = response.json()

            games = data.get('data', []) if isinstance(data, dict) else data
            game_count = len(games)

            # Count statuses
            statuses = {}
            for game in games:
                status = game.get('status', 'Unknown')
                statuses[status] = statuses.get(status, 0) + 1

            status_str = ", ".join([f"{s}:{c}" for s, c in sorted(statuses.items())])

            print(f"{test_name:.<30} Total: {game_count:3d}  [{status_str}]")

        except Exception as e:
            print(f"{test_name:.<30} Error: {str(e)[:50]}")

    print("\n" + "="*80)
    print("Check which query returns games with all statuses")
    print("="*80 + "\n")

    return 0

if __name__ == '__main__':
    sys.exit(main())
