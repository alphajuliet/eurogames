#!/usr/bin/env racket
#lang racket

(require db
         sql 
         threading)

(provide (all-defined-out))

(define SQLDB "/Users/andrew/Documents/Projects/games/eurogames/data/games.db")
(define gdb (sqlite3-connect #:database SQLDB))

(define (db-get-all-ids)
  (query-list gdb "SELECT id FROM notes ORDER BY id"))

;; Update the table with data from a given CSV file. 
(define (db-update-game-data csvfile)
  #f)

(module+ main
  (db-get-all-ids))

;; The End