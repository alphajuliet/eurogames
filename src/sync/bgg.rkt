#!/usr/bin/env racket
#lang racket

;; Download game data from BoardGameGeek
;; Andrew 2022-01

(require sxml
         sxml/sxpath
         threading
         gregor
         json
         csv-writing
         (prefix-in db: "gamesdb.rkt")
         (prefix-in h: "http.rkt"))

(provide (all-defined-out))

(define (to-string x)
  (if (number? x) (number->string x) x))

(define (to-number x)
  (if (string? x) (string->number x) x))
;;----------------
;; Download game data from BGG as XML
;; get-game-data-xml :: String -> SXML
(define (get-game-data id)
  (define host "boardgamegeek.com")
  (define uri (format "/xmlapi2/thing?stats=1&id=~a" (to-string id)))
  (define headers (list (string-append "Authorization: Bearer " (getenv "BGG_API_KEY"))))
  (~> (h:https-get host uri headers)
      (ssax:xml->sxml '())))

(define (get-item xpath data)
  ;; get-item :: String -> SXML -> a
  ;; Get the item at the XPath location
  (let ([item ((sxpath xpath) data)])
    (if (empty? item)
        item
        (first item))))

(define get-number
  (compose string->number get-item))

(define (extract-fields id data)
  ;; Extract the values of interest from the SXML as a hash
  ;; extract-xml-fields : String -> SXML -> Hash Symbol (String | Number)
  (hash 'name (get-item "//items/item/name[@type='primary']/@value/text()" data)
        'id (to-number id)
        'complexity (get-number "//items/item/statistics/ratings/averageweight/@value/text()" data)
        'ranking (get-number "//items/item/statistics/ratings/ranks/rank[@name='boardgame']/@value/text()" data)
        'rating (get-number "//items/item/statistics/ratings/average/@value/text()" data)
        'playingTime (get-number "//items/item/playingtime/@value/text()" data)
        'minPlayers (get-number "//items/item/minplayers/@value/text()" data)
        'maxPlayers (get-number "//items/item/maxplayers/@value/text()" data)
        'yearPublished (get-number "//items/item/yearpublished/@value/text()" data)
        'category ((sxpath "//items/item/link[@type='boardgamecategory']/@value/text()") data)
        'mechanic ((sxpath "//items/item/link[@type='boardgamemechanic']/@value/text()") data)
        'retrieved (date->iso8601 (today))))

(define (lookup-game id)
  ;; Look up selected data for a game id and return as a hash
  ;; lookup-game : String -> Hash Symbol v
  (~>> id
       get-game-data
       (extract-fields id)))

(define (lookup-all-games ids)
  ;; Get data on all the games in the list of IDs
  ;; lookup-all-games :: List String -> List JSExpr
  (for/list ([id (in-list ids)])
    (begin
      (sleep 0.5)
      (~>> id
           get-game-data
           (extract-fields id)))))

(define (to-json h)
  ;; Write a hash to JSON
  (with-output-to-string
    (λ ()
      (write-json h #:indent #f))))

(define (convert-hash-values h)
  (for/list ([v (in-hash-values h)])
    (if (list? v)
        (string-join v ",")
        v)))

;; Write a single hash to CSV
(define (hash-to-csv h)
  (display-table (append (list (hash-keys h) (convert-hash-values h)))))

;; Write a list of hashes to a CSV string
(define (hashes-to-csv lst)
  (define header (hash-keys (first lst)))
  (define vals (map convert-hash-values lst))
  (display-table (append (list header) vals)))

(module+ main
  (define args (current-command-line-arguments))
  (if (= 0 (vector-length args))
      ;; Get game data for all IDs
      (~> (db:db-get-all-ids)
          ; (take 10)
          (lookup-all-games)
          (hashes-to-csv))
      ;; else just the requested one
      (~> args
          (vector-ref 0)
          (lookup-game)
          (hash-to-csv))))

;; The End
