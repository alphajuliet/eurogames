#!/usr/bin/env racket
#lang racket

(require json
         json-pointer
         threading
         rakeda
         (prefix-in bgg: "./bgg.rkt")
         (prefix-in air: "./airtable.rkt"))

(define (roundf x p)
  ;; Round x to precision p
  (~> x
      (/ p)
      floor
      (* p)))

(define (map-pair fn pairs)
  ;; Map a function over the values in the list of pairs
  (map (λ (p) (cons (car p) (fn (cdr p)))) pairs))

(define (extract-fields bgg-data)
  ;; Determine updates to Airtable
  ;; extract-fields :: Hash k v -> Hash k v
  (~>> bgg-data
       (r/select-keys '(ranking complexity yearPublished playingTime minPlayers maxPlayers))
       (hash-update _ 'complexity (λ (x) (roundf x 0.01)))))

(define (update-game game)
  ;; Extract data from BGG for a game and update the record in Airtable
  ;; update-game :: Number -> ()
  (define record (hash-ref game 'id))
  (define name (~> game (hash-ref 'fields) (hash-ref 'name)))
  (define bgg-id (~> game (hash-ref 'fields) (hash-ref 'id) number->string))
  (displayln (format "Update ~a, id ~a, record ~a" name bgg-id record))
  ;; (define bgg-data (bgg:lookup-game (number->string id)))
  ;; (define fields (map-pair number->string (hash->list (extract-fields bgg-data))))
  (define fields
    (~> bgg-id
        bgg:lookup-game
        extract-fields))
  (air:update-record record fields))

(define (go)
  (define games (air:get-all-records))
  (map update-game games))

;; The End
