#!/usr/bin/env racket
#lang racket

(require json
         json-pointer
         threading
         rakeda
         (prefix-in bgg: "./bgg.rkt")
         (prefix-in air: "./airtable.rkt"))

;;-----------------------
(define (rounded-to x p)
  ;; Round x to precision p
  (~> x
      (/ p)
      floor
      (* p)))

(define (extract-fields bgg-data)
  ;; Determine updates to Airtable
  ;; extract-fields :: Hash k v -> Hash k v
  (~>> bgg-data
       (r/select-keys '(id ranking complexity yearPublished playingTime minPlayers maxPlayers category))
       (hash-update _ 'complexity (λ (x) (rounded-to x 0.01)))))

;;-----------------------
(define (update-game game)
  ;; Given the Airtable entry, extract data from BGG for a game and update the Airtable record.
  ;; update-game :: Hash k v -> ()
  (define record (hash-ref game 'id))
  (define name (r/get-in '(fields name) game))
  (define bgg-id (number->string (r/get-in '(fields id) game)))
  (displayln (format "# Update ~a, id ~a, record ~a" name bgg-id record))
  (~> bgg-id
      bgg:lookup-game
      extract-fields
      (air:update-record record _)))

;;-----------------------
(define (game-id id games)
  ;; Get the Airtable game data with the given numeric ID
  (filter (λ (g) (eq? id (~> g (hash-ref 'fields) (hash-ref 'id)))) games))

(define/contract (update-game-id id [games (air:get-all-records)])
  ;; Update a game, given just the BGG ID as a number
  (->* (number?) (list?) any)
  (update-game (first (game-id id games))))

;;-----------------------
(define (get-categories game)
  (define bgg-id (~> game (hash-ref 'fields) (hash-ref 'id) number->string))
  (~>> bgg-id
       bgg:lookup-game
       (r/select-keys '(category))))

;;-----------------------
(define (go)
  ;; Do all the games in Airtable
  (map update-game (air:get-all-records)))

;; The End
