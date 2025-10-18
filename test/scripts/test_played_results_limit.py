#!/usr/bin/env python3
"""
Test script to verify get_played_results() limit parameter works correctly.
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src', 'app'))

from api_client import EurogamesAPIClient

def main():
    client = EurogamesAPIClient()

    print("\n" + "="*80)
    print("Testing get_played_results() with limit parameter")
    print("="*80 + "\n")

    # Test default limit (50)
    print("Test 1: get_played_results() - Default limit (50)")
    print("-" * 80)
    try:
        results = client.get_played_results()
        print(f"✓ Results returned: {len(results)} games")
        if results:
            print(f"  First result: {results[0].get('name')} - {results[0].get('winner')} won")
            print(f"  Last result: {results[-1].get('name')} - {results[-1].get('winner')} won")
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

    print()

    # Test with custom limit (10)
    print("Test 2: get_played_results(limit=10) - Custom limit")
    print("-" * 80)
    try:
        results_10 = client.get_played_results(limit=10)
        print(f"✓ Results returned: {len(results_10)} games")
        if results_10:
            print(f"  First result: {results_10[0].get('name')}")
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

    print()

    # Test with different limit (25)
    print("Test 3: get_played_results(limit=25) - Different limit")
    print("-" * 80)
    try:
        results_25 = client.get_played_results(limit=25)
        print(f"✓ Results returned: {len(results_25)} games")
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

    print()

    # Verify limits work as expected
    print("Test 4: Verify limit parameters are respected")
    print("-" * 80)
    if len(results_10) <= 10:
        print(f"✓ limit=10 returned {len(results_10)} games (≤ 10)")
    else:
        print(f"✗ limit=10 returned {len(results_10)} games (should be ≤ 10)")
        return 1

    if len(results_25) <= 25:
        print(f"✓ limit=25 returned {len(results_25)} games (≤ 25)")
    else:
        print(f"✗ limit=25 returned {len(results_25)} games (should be ≤ 25)")
        return 1

    if len(results) <= 50:
        print(f"✓ limit=50 (default) returned {len(results)} games (≤ 50)")
    else:
        print(f"✗ limit=50 returned {len(results)} games (should be ≤ 50)")
        return 1

    print()
    print("="*80)
    print("All tests passed! ✓")
    print("="*80 + "\n")

    return 0

if __name__ == '__main__':
    sys.exit(main())
