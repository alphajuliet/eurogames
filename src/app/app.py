from flask import Flask, render_template, request, flash, redirect, url_for, jsonify
from sqlite_utils import Database
import os

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY')

@app.route("/")
def main():
    return render_template("index.html")

@app.route("/games")
def games():
    db = Database("../../data/games.db")
    games = db["game_list2"].rows
    return render_template("games.html", games=games)

@app.route("/game/<game_id>")
def game(game_id):
    db = Database("../../data/games.db")
    game = db.query("SELECT * FROM bgg LEFT JOIN notes ON bgg.id = notes.id WHERE bgg.id = :game", {"game": game_id})
    return render_template("game.html", game=iter(game))

@app.route("/results")
def played():
    db = Database("../../data/games.db")
    results = db["played"].rows
    return render_template("results.html", results=results)

@app.route("/lastPlayed")
def lastPlayed():
    db = Database("../../data/games.db")
    games = db["last_played"].rows
    return render_template("last_played.html", games=list(games))

@app.route("/winner")
def winner():
    db = Database("../../data/games.db")
    games = db.query("SELECT *, ROUND(100 * CAST(Andrew AS REAL) / Games, 1) AS AndrewRatio FROM winner")
    return render_template("winner.html", games=list(games))

# API response for just the winner totals
@app.route("/totals")
def totals():
    db = Database("../../data/games.db")
    sums = db.query("SELECT SUM(Games) as Games, SUM(Andrew) AS Andrew, SUM(Trish) AS Trish, Sum(Draw) AS Draw FROM winner")
    return jsonify(list(sums))

@app.route("/addResult", methods=["POST"])
def addResult():
    try:
        date = request.form.get('date')
        game_id = int(request.form.get('id'))  # Renamed variable to 'game_id' to avoid shadowing built-in 'id'
        winner = request.form.get('winner')
        scores = request.form.get('scores')  # Ensure this matches the database column name
        comment = request.form.get('comment')

        db = Database("../../data/games.db")
        # Make sure table name and column names match your schema
        db.execute("INSERT INTO log (date, id, winner, scores, comment) VALUES (?, ?, ?, ?, ?)",
                   [date, game_id, winner, scores, comment])
        db.conn.commit()  # Commit the transaction to save changes to the database

        flash('Result added successfully!', 'success')  # Flash a success message
        return redirect(url_for('played'))  # Redirect to the 'played' route to show updated results

    except Exception as e:
        # For security reasons, don't use str(e) in production as it can expose underlying details
        # Use a generic message instead, such as 'An error occurred. Please try again.'
        flash(f'An error occurred: {str(e)}', 'error')  # Flash an error message
        return redirect(url_for('played'))  # Optionally, redirect back to the results page

# The End
