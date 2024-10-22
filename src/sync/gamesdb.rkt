#!/usr/bin/env racket
#lang racket

(require threading
         db)

(provide (all-defined-out))

(define SQLDB "/Users/andrew/LocalProjects/games/eurogames/data/games.db")
(define games-db (sqlite3-connect #:database SQLDB))

;; Get all the game IDs we have
(define (db-get-all-ids)
  (query-list games-db "SELECT id FROM notes ORDER BY id"))

;; Get the IDs for just the games we are currently playing
(define (db-get-all-ids-playing)
  (query-list games-db "SELECT id FROM notes WHERE status = \"Playing\" ORDER BY id"))

;; Update selected db fields from the data
(define (db-update-fields game-data)
  (let ([query (format "UPDATE bgg SET ranking = \"~a\", complexity = \"~a\" WHERE id = \"~a\""
                       (hash-ref game-data 'ranking)
                       (hash-ref game-data 'complexity)
                       (hash-ref game-data 'id))])
    (displayln query)
    (query-exec games-db query)))

;; If called from outside, just return a list of all the IDs in the database
(module+ main
         (~> (db-get-all-ids-playing)
             (map ~a _)
             (string-join)
             (displayln)))
             
;; The End
