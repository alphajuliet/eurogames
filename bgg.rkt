#!/usr/bin/env racket
#lang racket

;; Download game data from BGG
;; Andrew 2022-01

(require sxml
         sxml/sxpath
         json
         json-pointer
         net/uri-codec
         threading
         gregor
         "http.rkt")

(provide (all-defined-out))

(define (xml-to-json uri)
  ;; Take an XML endpoint and return as JSExpr
  ;; See https://github.com/factmaven/xml-to-json
  (~>> uri
       uri-encode
       (string-append "/xml-to-json/?xml=")
       (https-get "api.factmaven.com" _ '())
       port->string
       (with-input-from-string _
         (λ () (read-json)))))

(define test-xml "https://boardgamegeek.com/xmlapi2/thing?stats=1&id=50")

;;----------------
(define (get-args)
  ;; get-args :: List String
  (define args (current-command-line-arguments))
  (define usage-string 
    (format "Usage: ~s <id>"
            (path->string (find-system-path 'run-file))))

  (unless (= 1 (vector-length args))
      (begin 
        (displayln usage-string)
        null))

  args)

;;----------------
(define (get-game-data-xml id)
  ;; Download game data from BGG
  ;; get-game-data-xml :: String -> SXML
  (define host "boardgamegeek.com")
  (define uri (format "/xmlapi2/thing?stats=1&id=~s" (string->number id)))
  (define headers '())
  (~> (https-get host uri headers)
      (ssax:xml->sxml '())))

(define (get-game-data id)
  ;; Return game data as JSON
  ;; get-game-data :: String -> JSExpr
  (~>> id
       (format "https://boardgamegeek.com/xmlapi2/thing?stats=1&id=~a")
       xml-to-json))

;;----------------
(define (hash-filter key value lst)
  ;; hash-filter :: k -> v -> List (Hash k v) -> List (Hash k v)
  ;; Filter a list of hashes based on a key-value match
  (filter (λ (e) (string=? (hash-ref e key) value)) lst))

(define (hash-vals key lst)
  ;; hash-vals :: k -> List (Hash k v) -> List v
  ;; Return a list of values for a given key from a list of hashes
  ;; This is lifting hash-ref over lists
  (map (λ (e) (hash-ref e key)) lst))

(define (extract-fields id data)
  (hash 'name (with-handlers
                  ([exn:fail?
                    (λ (exn) (json-pointer-value "/items/item/name/value" data))])
                (json-pointer-value "/items/item/name/0/value" data))
        'id (string->number id)
        'complexity (string->number (json-pointer-value "/items/item/statistics/ratings/averageweight/value" data))
        'ranking (with-handlers
                     ([exn:fail?
                       (λ (exn) (string->number (json-pointer-value "/items/item/statistics/ratings/ranks/rank/value" data)))])
                   (string->number (json-pointer-value "/items/item/statistics/ratings/ranks/rank/0/value" data)))
        'playingTime (string->number (json-pointer-value "/items/item/playingtime/value" data))
        'minPlayers (string->number (json-pointer-value "/items/item/minplayers/value" data))
        'maxPlayers (string->number (json-pointer-value "/items/item/maxplayers/value" data))
        'maxPlayers (string->number (json-pointer-value "/items/item/maxplayers/value" data))
        'yearPublished (string->number (json-pointer-value "/items/item/yearpublished/value" data))
        'category (hash-vals 'value (hash-filter 'type "boardgamecategory" (json-pointer-value "/items/item/link" data)))
        'retrieved (date->iso8601 (today))
        ))

(define (get-item xpath data)
  ;; get-item :: String -> SXML -> a
  ;; Get the item at the XPath location
  (let ([item ((sxpath xpath) data)])
    (if (empty? item)
        item
        (first item))))

(define (extract-xml-fields id data)
  ;; extract-xml-fields : String -> SXML -> Hash Symbol (String | Number)
  ;; Extract the values of interest from the SXML as a hash
  (hash 'name (get-item "//items/item/name[@type='primary']/@value/text()" data)
        'id (string->number id)
        'complexity (string->number (get-item "//items/item/statistics/ratings/averageweight/@value/text()" data))
        'ranking (string->number (get-item "//items/item/statistics/ratings/ranks/rank[@name='boardgame']/@value/text()" data))
        'rating (string->number (get-item "//items/item/statistics/ratings/average/@value/text()" data))
        'playingTime (string->number (get-item "//items/item/playingtime/@value/text()" data))
        'minPlayers (string->number (get-item "//items/item/minplayers/@value/text()" data))
        'maxPlayers (string->number (get-item "//items/item/maxplayers/@value/text()" data))
        'category ((sxpath "//items/item/link[@type='boardgamecategory']/@value/text()") data)
        'retrieved (date->iso8601 (today))))

(define (get-ids [fname "./data/game-ids.txt"])
  ;; Return all the IDs as a list
  (with-input-from-file fname
    (λ ()
      (for/list ([line (in-lines)])
        (~> line
            (string-split ",")
            second)))))

(define (lookup-game id)
  ;; lookup-game : String -> JSExpr
  ;; Look up data for a game id and return as JSON
  (~>> id
       get-game-data
       (extract-fields id)))

(define (lookup-all-games ids)
  ;; lookup-all-games :: List String -> List JSExpr
  (for/list ([id (in-list ids)])
    (begin
      (sleep 0.1) ; rate-limit the API calls to prevent error
      (~>> id
           get-game-data
           (extract-fields id)))))

;;----------------
#;(module+ main
  (lookup-all-games (get-ids))
  #;(let ([id (first (vector->list (get-args)))])
    (when (not (null? id))
      (display (jsexpr->string (lookup-game id))))))

;; The End
