#!/usr/bin/env python3
"""
Debug script to test API connectivity and responses.
"""

import sys
import os
import logging

# Add src/app to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src', 'app'))

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

from api_client import EurogamesAPIClient, APIError

def main():
    print("\n" + "="*80)
    print("EUROGAMES API DEBUG TEST")
    print("="*80 + "\n")

    # Check environment variables
    print("Environment Variables:")
    print(f"  EUROGAMES_API_URL: {os.environ.get('EUROGAMES_API_URL', 'NOT SET')}")
    print(f"  EUROGAMES_API_KEY: {'SET' if os.environ.get('EUROGAMES_API_KEY') else 'NOT SET'}")
    if os.environ.get('EUROGAMES_API_KEY'):
        key = os.environ.get('EUROGAMES_API_KEY')
        print(f"    Key length: {len(key)} chars")
        print(f"    Key starts with: {key[:5]}...")
    print()

    # Initialize client
    print("Initializing API Client...")
    try:
        client = EurogamesAPIClient()
        print(f"✓ Client initialized")
        print(f"  Base URL: {client.base_url}")
        print(f"  API Key configured: {bool(client.api_key)}")
        print()
    except Exception as e:
        print(f"✗ Failed to initialize client: {e}")
        return 1

    # Test each endpoint
    tests = [
        ("Games List", lambda: client.get_games_list()),
        ("All Games", lambda: client.get_all_games()),
        ("Played Results", lambda: client.get_played_results()),
        ("Last Played", lambda: client.get_last_played()),
        ("Winner Stats", lambda: client.get_winner_stats()),
        ("Totals", lambda: client.get_totals()),
    ]

    print("Testing Endpoints:")
    print("-" * 80)

    for test_name, test_func in tests:
        try:
            print(f"\n{test_name}:")
            result = test_func()
            if isinstance(result, list):
                print(f"  ✓ Success: Got list with {len(result)} items")
                if result:
                    print(f"    First item keys: {list(result[0].keys()) if isinstance(result[0], dict) else 'N/A'}")
            elif isinstance(result, dict):
                print(f"  ✓ Success: Got dict with keys: {list(result.keys())}")
            else:
                print(f"  ✓ Success: Got {type(result).__name__}")
        except APIError as e:
            print(f"  ✗ API Error: {e}")
        except Exception as e:
            print(f"  ✗ Error: {e}")
            import traceback
            traceback.print_exc()

    print("\n" + "="*80)
    print("Debug test complete")
    print("="*80 + "\n")

    return 0

if __name__ == '__main__':
    sys.exit(main())
