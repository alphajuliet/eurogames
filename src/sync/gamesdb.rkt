#!/usr/bin/env racket
#lang racket

(require db
         sql 
         threading)

(provide (all-defined-out))

(define gdb (sqlite3-connect
             #:database "/Users/andrew/Documents/Projects/games/eurogames/data/games.db"))

(define (db-get-all-ids)
  (query-list gdb "SELECT id FROM games ORDER BY id"))

(module+ main
  (db-get-all-ids))

;; The End