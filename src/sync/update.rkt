#!/usr/bin/env racket
#lang racket/base
;; Update the BGG table with the latest game data for a list of IDs

(require threading
         (prefix-in bgg: "bgg.rkt")
         (prefix-in db: "gamesdb.rkt"))

(module+ main
  (define args (current-command-line-arguments))
  (if (= 0 (vector-length args))
      ;; Needs arguments
      (begin
        (println "Usage: update.rkt <id>+")
        (exit 1))
      ;; else just the requested ones
      (for ([id (in-vector args)])
        (~> id
            (bgg:lookup-game)
            (db:db-update-fields)))))

;; The End