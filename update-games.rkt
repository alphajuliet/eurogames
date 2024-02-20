#!/usr/bin/env racket
#lang racket

(require threading
         rakeda
         (prefix-in bgg: "./bgg.rkt")
         (prefix-in air: "./airtable.rkt"))

(provide go
         update-game-id)

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
       (r/select-keys '(id record-id ranking complexity yearPublished playingTime 
                           minPlayers maxPlayers category mechanic))
       (hash-update _ 'complexity (λ (x) (rounded-to x 0.01)))))

;;-----------------------
(define (transform-game game)
  ;; Given the Airtable entry, extract data from BGG for a game and update the Airtable record.
  ;; update-game :: Hash k v -> ()
  (define record-id (hash-ref game 'id))
  (define name (r/get-in game '(fields name)))
  (define bgg-id (number->string (r/get-in game '(fields id))))
  (displayln (format "# Update ~a, id ~a, record ~a" name bgg-id record-id))
  (~> bgg-id
      bgg:lookup-game
      (hash-set 'record-id record-id)
      extract-fields))

;;-----------------------
(define (game-id id games)
  ;; Get the Airtable game data with the given numeric ID, or #f if not found
  (define data (filter (λ (g) (eq? id (r/get-in g '(fields id)))) games))
  (if (empty? data)
      #f
      data))

(define/contract (update-game-id id [games (air:get-all-records)])
  ;; Update a game, given just the BGG ID as a number
  ;; update-game-id :: Number -> (List a) -> IO ()
  (->* (number?) (list?) any)
  (and~> id
         (game-id games)
         (map transform-game _)
         air:update-records))

;;-----------------------
(define (get-categories game)
  (define bgg-id (~> game (hash-ref 'fields) (hash-ref 'id) number->string))
  (~>> bgg-id
       bgg:lookup-game
       (r/select-keys '(category))))

(define (batch-sizes b n)
  ;; Return the counts in each batch of size b of n elements
  ;; e.g. (batch-sizes 5 12) => '(5 5 2)
  ;; batch-sizes :: Number -> List a -> List Number
  (map length (group-by (λ (x) (quotient x b)) (range n))))

(define (in-batch-of n fn data)
  ;; Apply fn to batches of n data items. Assumes fn has side effects.
  (foldl (λ (batch-size acc)
           (define this-data (take acc batch-size))
           (fn this-data)
           (drop acc batch-size))
         data
         (batch-sizes n (length data))))

;;-----------------------
(define (go)
  ;; Do all the games in Airtable
  (~>> (air:get-all-records)
       (map transform-game)
       (in-batch-of 10 air:update-records)))

;; The End
