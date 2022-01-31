#!/usr/bin/env racket
#lang racket

;; Download latest game metadata from Airtable.
;; No error checking yet.
;; Andrew 2018-07-28

(require json
         net/uri-codec
         threading
         rakeda
         (prefix-in h: "http.rkt"))

(provide (all-defined-out))

;;----------------
;; Download track metadata from Airtable

(define (get-record id)
  ;; Get a single record as a JSExpr
  (define host "api.airtable.com")
  (define base-uri "/v0/appawmxJtv4xJYiT3/games/")
  (define api-key (getenv "AIRTABLE_API_KEY"))
  (define headers (list (format "Authorization: Bearer ~a" api-key)))
  (define full-uri (string-append base-uri id))
  ;; (displayln (format "GET ~s" full-uri))
  (read-json (h:https-get host full-uri headers)))

;;----------------
(define (get-page [offset ""])
  ;; Get all records
  (define host "api.airtable.com")
  (define base-uri "/v0/appawmxJtv4xJYiT3/games")
  (define api-key (getenv "AIRTABLE_API_KEY"))
  (define headers (list (format "Authorization: Bearer ~a" api-key)))

  ; Set up page offset if required
  (define full-uri
    (if (string=? offset "")
        base-uri
        ;; else
        (string-append base-uri (~>> offset
                                     uri-encode
                                     string->symbol
                                     (format "?offset=~s")))))

  (read-json (h:https-get host full-uri headers)))

;;----------------
(define (get-all-records [records (list)] [offset ""])
  ;; Aggregate data over multiple paginated calls
  (let* ([resp (get-page offset)]
         [data (append records (hash-ref resp 'records))])
    (if (hash-has-key? resp 'offset)
        (get-all-records data (hash-ref resp 'offset))
        ;;else
        data)))

;;----------------
(define (write-rows lst (fname "./data/airtable.json"))
  ;; Write the data to a fixed name file
  ;; write-rows :: JSExpr -> IO ()
  (define out-file (open-output-file fname #:exists 'replace))
  (displayln (format "# Write rows to ~a" fname))
  (write-json lst out-file))

;;----------------
(define (encode-record data)
  ;; Encode a single record for update
  ;; encode-data :: Hash Symbol v -> Hash Symbol v
  (hash 'id (hash-ref data 'record-id)
        'fields (~> data
                    (hash-remove 'record-id)
                    #;(hash-remove 'category))))

(define/contract (encode-records data)
  ;; Encode a list of records
  ;; encode-records List (Hash Symbol v) -> String
  (-> list? string?)
  (with-output-to-string
    (λ () (write-json (~>> data
                           (map encode-record)
                           (hash 'records)
                           (hash-set _ 'typecast #t))))))

(define (update-records new-data)
  ;; Update Airtable records with the given data
  ;; update-record :: String -> Hash k v -> ()
  (define host "api.airtable.com")
  (define uri "/v0/appawmxJtv4xJYiT3/games")
  (define api-key (getenv "AIRTABLE_API_KEY"))
  (define payload (encode-records new-data))
  (define headers (list (format "Authorization: Bearer ~a" api-key)
                        "Content-Type: application/json"))
  (displayln (format "# Updating ~a~a with ~a" host uri payload))
  (h:https-patch host uri payload headers))

;; The End
