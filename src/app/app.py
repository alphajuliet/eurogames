from flask import Flask, render_template
from sqlite_utils import Database

app = Flask(__name__)

@app.route("/")
def main():
    return render_template("index.html")

"""
List all the games
"""
@app.route("/games")
def games():
    db = Database("../../data/games.db")
    games = db["game_list"].rows
    return render_template("games.html", games=games)

@app.route("/game/<game_id>")
def game(game_id):
    db = Database("../../data/games.db")
    game = db.query("SELECT * FROM bgg WHERE id = :game", {"game": game_id})
    return render_template("game.html", game=iter(game))

@app.route("/played")
def played():
    db = Database("../../data/games.db")
    results = db["played"].rows
    return render_template("played.html", results=results)
