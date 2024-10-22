#!/usr/bin/env racket
#lang racket/base
;; Update the BGG table with the latest game data for a list of IDs

(require threading
         data/collection
         (prefix-in bgg: "bgg.rkt")
         (prefix-in db: "gamesdb.rkt"))

(define (update-id-block ids)
  (for ([id (in ids)])
       (~> id
           (bgg:lookup-game)
           (db:db-update-fields))))

;; Throttle the requests if we have a few
(define (update-ids ids)
  (define block-size 12)
  (if (> (length ids) block-size)
    (for ([block (in (chunk block-size ids))])
         (begin
           (update-id-block block)
           (sleep 10)))
    (update-id-block ids)))

(module+ main
         (define args (current-command-line-arguments))
         (if (= 0 (vector-length args))
           (begin
             (println "Usage: update.rkt <id>+")
             (exit 1))
           (update-ids (vector->list args))))

;; The End
