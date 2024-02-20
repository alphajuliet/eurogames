#!/usr/bin/env racket
#lang racket

;; Download game data from BoardGameGeek
;; Andrew 2022-01

(require sxml
         sxml/sxpath
         threading
         gregor
         (prefix-in h: "http.rkt"))

(provide (all-defined-out))

(define test-xml "https://boardgamegeek.com/xmlapi2/thing?stats=1&id=50")

;;----------------
;; Download game data from BGG as XML
;; get-game-data-xml :: String -> SXML
(define (get-game-data id)
  (define host "boardgamegeek.com")
  (define uri (format "/xmlapi2/thing?stats=1&id=~a" id))
  (define headers '())
  (~> (h:https-get host uri headers)
      (ssax:xml->sxml '())))

;; get-item :: String -> SXML -> a
;; Get the item at the XPath location
(define (get-item xpath data)
  (let ([item ((sxpath xpath) data)])
    (if (empty? item)
      item
      (first item))))

(define get-number
  (compose string->number get-item))

;; Extract the values of interest from the SXML as a hash
;; extract-xml-fields : String -> SXML -> Hash Symbol (String | Number)
(define (extract-fields id data)
  (hash 'name (get-item "//items/item/name[@type='primary']/@value/text()" data)
        'id (string->number id)
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

;; Return all the IDs as a list
(define (get-ids [fname "./data/game-ids.txt"])
  (with-input-from-file fname
                        (λ ()
                           (for/list ([line (in-lines)])
                                     (~> line
                                         (string-split ",")
                                         second)))))

;; Look up selected data for a game id and return as a hash
;; lookup-game : String -> Hash Symbol v
(define (lookup-game id)
  (~>> id
       get-game-data
       (extract-fields id)))

;; Get data on all the games in the list of IDs
;; lookup-all-games :: List String -> List JSExpr
(define (lookup-all-games ids)
  (for/list ([id (in-list ids)])
            (begin
              (sleep 0.15)
              (~>> id
                   get-game-data
                   (extract-fields id)))))

(module+ main
         (lookup-game "62219"))
         

;; The End
