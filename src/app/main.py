# main.py

from fasthtml.common import *
import fastlite as fl

gamesDB = "../../data/games.db"
db = fl.database(gamesDB)

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
    return [Tr(*[Td(d[k]) for k in keys]) for d in data]

@rt('/')
def get():
    return Titled("Eurogames",
        pageSelector,
        Div("Hello", id='content'))

@rt('/games')
def get():
    view = db.v.game_list2
    query = db.q(f"select * from {view}")
    games = makeRows(query, ['name', 'id', 'status', 'complexity', 'ranking', 'games', 'lastPlayed'])
    return Table(
        Thead(Tr(Th("Name"), Th("ID"), Th("Status"), Th("Complexity"), Th("Ranking"), Th("Played"), Th("Last played"))),
        Tbody(*games))

@rt('/results')
def get():
    view = db.v.played
    query = db.q(f"select * from {view}")
    results = makeRows(query, ['date', 'id', 'name', 'winner', 'scores'])
    return Table(
        Thead(Tr(Th("Date"), Th("ID"), Th("Name"), Th("Winner"), Th("Scores"))),
        Tbody(*results))

@rt('/lastPlayed')
def get():
    view = db.v.last_played
    query = db.q(f"select * from {view}")
    resp = makeRows(query, ['lastPlayed', 'daysSince', 'games', 'name'])
    return Table(
        Thead(Tr(Th("Last played"), Th("Days since"), Th("Played"), Th("Name"))),
        Tbody(*resp))

@rt('/winner')
def get():
    query = db.q("SELECT *, ROUND(100 * CAST(Andrew AS REAL) / Games, 1) AS AndrewRatio FROM winner")
    resp = makeRows(query, ['name', 'Games', 'Andrew', 'Trish', 'Draw', 'AndrewRatio'])
    return Table(
        Thead(Tr(Th("Name"), Th("Played"), Th("Andrew"), Th("Trish"), Th("Draw"), Td("Andrew ratio"))),
        Tbody(*resp))

serve()

# The End
