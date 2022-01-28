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
       (r/select-keys '(ranking complexity yearPublished playingTime minPlayers maxPlayers category))
       (hash-update _ 'complexity (λ (x) (rounded-to x 0.01)))))

;;-----------------------
(define (update-game game)
  ;; Given the Airtable entry, extract data from BGG for a game and update the Airtable record.
  ;; update-game :: JSExpr -> ()
  (define record (hash-ref game 'id))
  (define name (~> game (hash-ref 'fields) (hash-ref 'name)))
  (define bgg-id (~> game (hash-ref 'fields) (hash-ref 'id) number->string))
  (displayln (format "# Update ~a, id ~a, record ~a" name bgg-id record))
  (~> bgg-id
      bgg:lookup-game
      extract-fields
      (air:update-record record _)))

;;-----------------------
(define (game-id id games)
  ;; Get the Airtable game data with the given ID
  (filter (λ (g) (eq? id (~> g (hash-ref 'fields) (hash-ref 'id)))) games))

(define (update-game-id id [games (air:get-all-records)])
  ;; Update a game, given just the BGG ID
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