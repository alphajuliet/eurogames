"""
REST API client for Eurogames database.
Replaces direct SQLite database access with HTTP API calls.
"""

import requests
import os
import logging
from typing import List, Dict, Any, Optional
from urllib.parse import urljoin

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class EurogamesAPIClient:
    """Client for interacting with the Eurogames REST API."""

    def __init__(self, base_url: Optional[str] = None, api_key: Optional[str] = None, timeout: int = 10):
        """
        Initialize the API client.

        Args:
            base_url: Base URL of the API (default from EUROGAMES_API_URL env var)
            api_key: API key for authentication (default from EUROGAMES_API_KEY env var)
            timeout: Request timeout in seconds
        """
        self.base_url = base_url or os.environ.get(
            'EUROGAMES_API_URL',
            'https://eurogames.web-c10.workers.dev'
        )
        self.api_key = api_key or os.environ.get('EUROGAMES_API_KEY')
        self.timeout = timeout
        # Remove trailing slash for consistent URL building
        self.base_url = self.base_url.rstrip('/')

        # Log initialization
        logger.debug(f"API Client initialized - URL: {self.base_url}, API Key configured: {bool(self.api_key)}")

    def _get_auth_header(self) -> Dict[str, str]:
        """
        Get authentication headers for API requests.

        Returns:
            Dictionary with Authorization header using Bearer token authentication
        """
        if not self.api_key:
            return {}

        # Bearer token authentication
        return {'Authorization': f'Bearer {self.api_key}'}

    def _get(self, endpoint: str, params: Optional[Dict[str, Any]] = None) -> Any:
        """
        Make a GET request to the API.

        Args:
            endpoint: API endpoint path (e.g., '/games')
            params: Query parameters

        Returns:
            Parsed JSON response

        Raises:
            requests.RequestException: If the request fails
        """
        url = urljoin(self.base_url + '/', endpoint.lstrip('/'))
        headers = self._get_auth_header()

        logger.debug(f"GET request - URL: {url}, Params: {params}, Auth header present: {bool(headers.get('Authorization'))}")

        try:
            response = requests.get(url, params=params, headers=headers, timeout=self.timeout)
            logger.debug(f"Response status: {response.status_code}")
            response.raise_for_status()
            data = response.json()
            logger.debug(f"Response data type: {type(data)}, length: {len(data) if isinstance(data, (list, dict)) else 'N/A'}")
            return data
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {str(e)}")
            raise APIError(f"API request failed: {str(e)}") from e

    def _post(self, endpoint: str, data: Optional[Dict[str, Any]] = None) -> Any:
        """
        Make a POST request to the API.

        Args:
            endpoint: API endpoint path
            data: Request body data

        Returns:
            Parsed JSON response

        Raises:
            requests.RequestException: If the request fails
        """
        url = urljoin(self.base_url + '/', endpoint.lstrip('/'))
        headers = self._get_auth_header()
        try:
            response = requests.post(url, json=data, headers=headers, timeout=self.timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise APIError(f"API request failed: {str(e)}") from e

    def get_games_list(self, status: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Get list of games, optionally filtered by status.

        Args:
            status: Game status filter (default: None for all games, can specify "Playing", "Inbox", "Evaluating", etc.)

        Returns:
            List of game dictionaries with all status values by default, or filtered if status provided
        """
        # Build params - only include status if specified
        params = {'status': status} if status is not None else None
        response = self._get('/v1/games', params=params)

        # API returns wrapped format: {"data": [...], "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            return response['data'] if isinstance(response['data'], list) else []
        # Fallback for unwrapped responses
        return response if isinstance(response, list) else response.get('games', [])

    def get_all_games(self) -> List[Dict[str, Any]]:
        """
        Get all games without status filter.

        Returns:
            List of all games
        """
        response = self._get('/v1/games')
        # API returns wrapped format: {"data": [...], "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            return response['data'] if isinstance(response['data'], list) else []
        # Fallback for unwrapped responses
        return response if isinstance(response, list) else response.get('games', [])

    def get_game_details(self, game_id: int) -> Optional[Dict[str, Any]]:
        """
        Get detailed information for a single game.

        Args:
            game_id: Game ID

        Returns:
            Game details dictionary with bgg and notes data
        """
        response = self._get(f'/v1/games/{game_id}')
        # API might return wrapped format: {"data": {...}, "meta": {...}} or direct object
        if isinstance(response, dict) and 'data' in response:
            data = response['data']
            return data if isinstance(data, dict) else None
        if isinstance(response, dict) and 'game' in response:
            return response['game']
        return response if isinstance(response, dict) and response else None

    def get_game_history(self, game_id: int) -> List[Dict[str, Any]]:
        """
        Get play history for a specific game.

        Args:
            game_id: Game ID

        Returns:
            List of play records for this game
        """
        response = self._get(f'/v1/games/{game_id}/history')
        # API returns wrapped format: {"data": [...], "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            return response['data'] if isinstance(response['data'], list) else []
        return response if isinstance(response, list) else response.get('plays', [])

    def get_played_results(self, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Get game play results/history.

        Args:
            limit: Maximum number of results to return (default: 50)

        Returns:
            List of played games with results (up to limit)
        """
        response = self._get('/v1/plays', params={'limit': limit})
        # API returns wrapped format: {"data": [...], "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            return response['data'] if isinstance(response['data'], list) else []
        return response if isinstance(response, list) else response.get('plays', [])

    def get_recent_plays(self, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Get recent game plays.

        Args:
            limit: Maximum number of plays to return

        Returns:
            List of recent plays
        """
        response = self._get('/v1/stats/recent', params={'limit': limit})
        # API returns wrapped format: {"data": [...], "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            return response['data'] if isinstance(response['data'], list) else []
        return response if isinstance(response, list) else response.get('plays', [])

    def get_last_played(self) -> List[Dict[str, Any]]:
        """
        Get last played dates for games.

        Returns:
            List of games with last played information
        """
        response = self._get('/v1/stats/last-played')
        # API returns wrapped format: {"data": [...], "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            return response['data'] if isinstance(response['data'], list) else []
        return response if isinstance(response, list) else response.get('games', [])

    def get_winner_stats(self) -> List[Dict[str, Any]]:
        """
        Get winner statistics.

        Returns:
            List of games with win statistics
        """
        response = self._get('/v1/stats/winners')
        # API returns wrapped format: {"data": [...], "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            return response['data'] if isinstance(response['data'], list) else []
        return response if isinstance(response, list) else response.get('winners', [])

    def get_totals(self) -> Dict[str, Any]:
        """
        Get aggregated win totals.

        Returns:
            Dictionary with total games, wins by player, and draws
        """
        response = self._get('/v1/stats/totals')
        # API returns wrapped format: {"data": {...}, "meta": {...}}
        if isinstance(response, dict) and 'data' in response:
            data = response['data']
            # data could be a single dict or list with one dict
            if isinstance(data, list) and len(data) > 0:
                return data[0] if isinstance(data[0], dict) else {}
            return data if isinstance(data, dict) else {}
        # Fallback for unwrapped responses
        if isinstance(response, list) and len(response) > 0:
            return response[0]
        return response if isinstance(response, dict) else {}

    def add_game_result(
        self,
        date: str,
        game_id: int,
        winner: str,
        scores: Optional[str] = None,
        comment: Optional[str] = None
    ) -> bool:
        """
        Record a new game result.

        Args:
            date: Date in YYYY-MM-DD format
            game_id: ID of the game
            winner: Name of the winner
            scores: Game scores (optional)
            comment: Additional comment (optional)

        Returns:
            True if successful

        Raises:
            APIError: If the request fails
        """
        data = {
            'date': date,
            'game_id': game_id,
            'winner': winner,
            'scores': scores,
            'comment': comment
        }
        # Remove None values
        data = {k: v for k, v in data.items() if v is not None}

        response = self._post('/v1/plays', data=data)
        return response.get('success', True) if isinstance(response, dict) else True


class APIError(Exception):
    """Exception raised for API-related errors."""
    pass
