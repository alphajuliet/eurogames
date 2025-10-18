# main.py

from fasthtml.common import *
from api_client import EurogamesAPIClient, APIError
import logging

# Initialize API client
api_client = EurogamesAPIClient()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

style = Link(rel='stylesheet', href='static/style.css')
app, rt = fast_app()

# Page selector header
pageSelector = P(
    A('Games', cls='link', hx_get='/games', hx_target='#content'),
    A('Results', cls='link', hx_get='/results', hx_target='#content'),
    A('Last Played', cls='link', hx_get='/lastPlayed', hx_target='#content'),
    A('Winners', cls='link', hx_get='/winner', hx_target='#content'))

"""Make a table row of data from the given responses"""
def makeRows(data, keys):
    """Create table rows from data, safely handling missing keys"""
    rows = []
    for d in data:
        row_cells = []
        for k in keys:
            value = d.get(k, '') if isinstance(d, dict) else getattr(d, k, '')
            row_cells.append(Td(value))
        rows.append(Tr(*row_cells))
    return rows


@rt('/')
def get():
    return Titled("Eurogames",
        pageSelector,
        Div("Hello", id='content'))


@rt('/games')
def get():
    try:
        games_data = api_client.get_games_list()
        games = makeRows(games_data, ['name', 'id', 'status', 'complexity', 'ranking', 'games', 'lastPlayed'])
        return Table(
            Thead(Tr(Th("Name"), Th("ID"), Th("Status"), Th("Complexity"), Th("Ranking"), Th("Played"), Th("Last played"))),
            Tbody(*games))
    except APIError as e:
        logger.error(f"API error fetching games: {e}")
        return P(f"Error loading games: {str(e)}")


@rt('/results')
def get():
    try:
        results_data = api_client.get_played_results()
        results = makeRows(results_data, ['date', 'id', 'name', 'winner', 'scores'])
        return Table(
            Thead(Tr(Th("Date"), Th("ID"), Th("Name"), Th("Winner"), Th("Scores"))),
            Tbody(*results))
    except APIError as e:
        logger.error(f"API error fetching results: {e}")
        return P(f"Error loading results: {str(e)}")


@rt('/lastPlayed')
def get():
    try:
        games_data = api_client.get_last_played()
        resp = makeRows(games_data, ['lastPlayed', 'daysSince', 'games', 'name'])
        return Table(
            Thead(Tr(Th("Last played"), Th("Days since"), Th("Played"), Th("Name"))),
            Tbody(*resp))
    except APIError as e:
        logger.error(f"API error fetching last played: {e}")
        return P(f"Error loading last played games: {str(e)}")


@rt('/winner')
def get():
    try:
        games_data = api_client.get_winner_stats()
        # Add calculated ratio if not provided by API
        for game in games_data:
            if 'AndrewRatio' not in game and 'Andrew' in game and 'Games' in game:
                if game['Games'] > 0:
                    game['AndrewRatio'] = round(100 * float(game['Andrew']) / game['Games'], 1)
        resp = makeRows(games_data, ['name', 'Games', 'Andrew', 'Trish', 'Draw', 'AndrewRatio'])
        return Table(
            Thead(Tr(Th("Name"), Th("Played"), Th("Andrew"), Th("Trish"), Th("Draw"), Td("Andrew ratio"))),
            Tbody(*resp))
    except APIError as e:
        logger.error(f"API error fetching winner stats: {e}")
        return P(f"Error loading winner statistics: {str(e)}")


serve()

# The End
