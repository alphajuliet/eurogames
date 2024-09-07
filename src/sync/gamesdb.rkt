#!/usr/bin/env racket
#lang racket

(require db)

(provide (all-defined-out))

(define SQLDB "/Users/andrew/LocalProjects/games/eurogames/data/games.db")
(define games-db (sqlite3-connect #:database SQLDB))

(define (db-get-all-ids)
  (query-list games-db "SELECT id FROM notes ORDER BY id"))

(module+ main
  ;; If called from outside, just return a list of all the IDs in the database
  (db-get-all-ids))

;; The End
