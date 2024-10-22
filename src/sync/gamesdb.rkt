#!/usr/bin/env racket
#lang racket

(require db)

(provide (all-defined-out))

(define SQLDB "/Users/andrew/LocalProjects/games/eurogames/data/games.db")
(define games-db (sqlite3-connect #:database SQLDB))

(define (db-get-all-ids)
  (query-list games-db "SELECT id FROM notes ORDER BY id"))

(define (db-update-fields game-data)
  ;; Update selected db fields from the data
  (let ([query (format "UPDATE bgg SET ranking = \"~a\", complexity = \"~a\" WHERE id = \"~a\""
                       (hash-ref game-data 'ranking)
                       (hash-ref game-data 'complexity)
                       (hash-ref game-data 'id))])
    (displayln query)
    (query-exec games-db query)))

(module+ main
  ;; If called from outside, just return a list of all the IDs in the database
  (db-get-all-ids))

;; The End
