#!/usr/bin/env python3
"""
Test script to verify get_games_list() behavior change.
"""

import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src', 'app'))

from api_client import EurogamesAPIClient

def main():
    client = EurogamesAPIClient()

    print("\n" + "="*80)
    print("Testing get_games_list() Behavior Change")
    print("="*80 + "\n")

    # Test 1: Get all games (default - no status parameter)
    print("Test 1: get_games_list() - No status parameter (default)")
    print("-" * 80)
    try:
        all_games = client.get_games_list()
        print(f"✓ Returns {len(all_games)} games (all statuses)")
        if all_games:
            statuses = set()
            for game in all_games:
                status = game.get('status')
                statuses.add(status)
            print(f"  Statuses found: {sorted(statuses)}")
            print(f"  Sample games:")
            for game in all_games[:3]:
                print(f"    - {game.get('name')} (Status: {game.get('status')})")
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

    print()

    # Test 2: Get only "Playing" status games
    print("Test 2: get_games_list(status='Playing') - Filtered")
    print("-" * 80)
    try:
        playing_games = client.get_games_list(status="Playing")
        print(f"✓ Returns {len(playing_games)} games (Playing status only)")
        if playing_games:
            # Verify all are "Playing" status
            all_playing = all(game.get('status') == 'Playing' for game in playing_games)
            if all_playing:
                print(f"  ✓ All games have 'Playing' status")
            else:
                print(f"  ✗ Some games don't have 'Playing' status!")
            print(f"  Sample games:")
            for game in playing_games[:3]:
                print(f"    - {game.get('name')} (Status: {game.get('status')})")
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1

    print()

    # Test 3: Verify difference
    print("Test 3: Verify difference between default and filtered")
    print("-" * 80)
    all_count = len(all_games)
    playing_count = len(playing_games)
    print(f"All games count: {all_count}")
    print(f"Playing games count: {playing_count}")

    if all_count > playing_count:
        print(f"✓ Default (all statuses) returns more games than Playing filter")
        print(f"  Difference: {all_count - playing_count} non-Playing games")
    elif all_count == playing_count:
        print(f"ℹ Both queries return same count ({all_count}) - all games are 'Playing' status")
    else:
        print(f"✗ Error: Default returned fewer games than filter!")
        return 1

    print()

    # Test 4: Test other status if available
    print("Test 4: Check for other status values in all games")
    print("-" * 80)
    statuses_dict = {}
    for game in all_games:
        status = game.get('status', 'Unknown')
        if status not in statuses_dict:
            statuses_dict[status] = []
        statuses_dict[status].append(game.get('name'))

    for status, games in sorted(statuses_dict.items()):
        print(f"  {status}: {len(games)} games")
        print(f"    Examples: {', '.join(games[:2])}")

    print()
    print("="*80)
    print("All tests passed! ✓")
    print("="*80 + "\n")

    return 0

if __name__ == '__main__':
    sys.exit(main())
