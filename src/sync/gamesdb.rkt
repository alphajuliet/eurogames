#!/usr/bin/env racket
#lang racket

(require db
         sql 
         threading)

(provide (all-defined-out))

(define gdb (sqlite3-connect #:database "data/games.db"))

(define (db-get-all-ids)
  (query-list gdb "SELECT id FROM games ORDER BY id"))

(module+ main
  (db-get-all-ids))

;; The End