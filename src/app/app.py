from flask import Flask, render_template, request, flash, redirect, url_for, jsonify
from api_client import EurogamesAPIClient, APIError
import os
import logging
import sys

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY')

# Configure logging to show DEBUG level
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)
logger.info("Flask app starting up")

# Initialize API client
logger.info(f"EUROGAMES_API_URL: {os.environ.get('EUROGAMES_API_URL')}")
logger.info(f"EUROGAMES_API_KEY configured: {bool(os.environ.get('EUROGAMES_API_KEY'))}")
api_client = EurogamesAPIClient()
logger.info("API client initialized")


@app.route("/")
def main():
    return render_template("index.html")


@app.route("/games")
def games():
    logger.info("GET /games - route handler called")
    try:
        logger.debug("Calling get_games_list()")
        games_list = api_client.get_games_list()
        logger.info(f"Successfully fetched {len(games_list)} games")
        return render_template("games.html", games=games_list)
    except APIError as e:
        logger.error(f"API error fetching games: {e}", exc_info=True)
        flash("Error fetching games from API", "error")
        return render_template("games.html", games=[])
    except Exception as e:
        logger.error(f"Unexpected error in /games: {e}", exc_info=True)
        flash("Unexpected error fetching games", "error")
        return render_template("games.html", games=[])


@app.route("/game/<game_id>")
def game(game_id):
    try:
        game_data = api_client.get_game_details(game_id)
        if game_data:
            return render_template("game.html", game=iter([game_data]))
        else:
            flash("Game not found", "error")
            return redirect(url_for('games'))
    except APIError as e:
        logger.error(f"API error fetching game {game_id}: {e}")
        flash("Error fetching game details", "error")
        return redirect(url_for('games'))


@app.route("/results")
def played():
    logger.info("GET /results - route handler called")
    try:
        logger.debug("Calling get_played_results()")
        results = api_client.get_played_results()
        logger.debug(f"Got {len(results)} results")
        logger.debug("Calling get_all_games()")
        games_list = api_client.get_all_games()
        logger.debug(f"Got {len(games_list)} games")
        # Extract just id and name from games
        games = [{'id': g.get('id'), 'name': g.get('name')} for g in games_list]
        logger.info(f"Successfully fetched {len(results)} results and {len(games)} games")
        return render_template("results.html", results=results, games=games)
    except APIError as e:
        logger.error(f"API error fetching results: {e}", exc_info=True)
        flash("Error fetching results from API", "error")
        return render_template("results.html", results=[], games=[])
    except Exception as e:
        logger.error(f"Unexpected error in /results: {e}", exc_info=True)
        flash("Unexpected error fetching results", "error")
        return render_template("results.html", results=[], games=[])


@app.route("/lastPlayed")
def lastPlayed():
    try:
        games_list = api_client.get_last_played()
        return render_template("last_played.html", games=games_list)
    except APIError as e:
        logger.error(f"API error fetching last played: {e}")
        flash("Error fetching last played games", "error")
        return render_template("last_played.html", games=[])


@app.route("/winner")
def winner():
    logger.info("GET /winner - route handler called")
    try:
        logger.debug("Calling get_winner_stats()")
        games_list = api_client.get_winner_stats()
        logger.debug(f"Got {len(games_list)} winner stats")

        # Transform API response to match template expectations
        # API returns: gameId, gameName, totalGames, andrew, trish, draw
        # Template expects: id, name, Games, Andrew, Trish, Draw, AndrewRatio
        transformed = []
        for game in games_list:
            transformed_game = {
                'id': game.get('gameId'),
                'name': game.get('gameName'),
                'Games': game.get('totalGames'),
                'Andrew': game.get('andrew'),
                'Trish': game.get('trish'),
                'Draw': game.get('draw')
            }
            # Calculate Andrew's win ratio
            total = transformed_game.get('Games', 0)
            andrew_wins = transformed_game.get('Andrew', 0)
            if total > 0:
                transformed_game['AndrewRatio'] = round(100 * float(andrew_wins) / total, 1)
            else:
                transformed_game['AndrewRatio'] = 0

            transformed.append(transformed_game)

        logger.info(f"Successfully transformed {len(transformed)} winner stats")
        return render_template("winner.html", games=transformed)
    except APIError as e:
        logger.error(f"API error fetching winner stats: {e}", exc_info=True)
        flash("Error fetching winner statistics", "error")
        return render_template("winner.html", games=[])
    except Exception as e:
        logger.error(f"Unexpected error in /winner: {e}", exc_info=True)
        flash("Unexpected error fetching winner statistics", "error")
        return render_template("winner.html", games=[])


# API response for just the winner totals
@app.route("/totals")
def totals():
    try:
        total_data = api_client.get_totals()
        return jsonify([total_data] if isinstance(total_data, dict) else total_data)
    except APIError as e:
        logger.error(f"API error fetching totals: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/addResult", methods=["POST"])
def addResult():
    try:
        date = request.form.get('date')
        game_id = int(request.form.get('id'))
        winner = request.form.get('winner')
        scores = request.form.get('scores')
        comment = request.form.get('comment')

        # Add result via API
        success = api_client.add_game_result(
            date=date,
            game_id=int(game_id),
            winner=winner,
            scores=scores,
            comment=comment
        )

        if success:
            flash('Result added successfully!', 'success')
        else:
            flash('Failed to add result', 'error')

        return redirect(url_for('played'))

    except ValueError as e:
        logger.error(f"Validation error when adding result: {e}")
        flash('Invalid input provided', 'error')
        return redirect(url_for('played'))
    except APIError as e:
        logger.error(f"API error adding result: {e}")
        flash(f'Error adding result: {str(e)}', 'error')
        return redirect(url_for('played'))
    except Exception as e:
        logger.error(f"Unexpected error adding result: {e}")
        flash('An unexpected error occurred', 'error')
        return redirect(url_for('played'))


# The End
