from flask import Flask, render_template, request
from sqlite_utils import Database

app = Flask(__name__)

@app.route("/")
def main():
    return render_template("index.html")

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

@app.route("/winner")
def winner():
    db = Database("../../data/games.db")
    games = db["winner"].rows
    return render_template("winner.html", games=games)

@app.route("/lastPlayed")
def lastPlayed():
    db = Database("../../data/games.db")
    games = db["last_played"].rows
    return render_template("last_played.html", games=games)

@app.route("/addResult", methods=["POST"])
def addResult():
    print(request.form)
    date = request.form.get('date')
    id = int(request.form.get('id'))
    winner = request.form.get('winner')
    scores = request.form.get('score')
    comment = request.form.get('comment')

    db = Database("../../data/games.db")
    rows = db.query("INSERT INTO log (date, id, winner, scores, comment) VALUES (:date, :id, :winner, :scores, :comment)", 
                    {"date": date, "id": id, "winner": winner, "scores": scores, "comment": comment})

    # Update results
    results = db["played"].rows
    return render_template("played.html", results=results)

# The End
