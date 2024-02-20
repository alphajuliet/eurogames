#lang racket/base

(require net/http-client
         racket/port)

(provide (all-defined-out))

;;----------------
(define (https-get host uri [headers '()])
  ;; https-get :: String -> String -> List String -> Port | error
  ;; Does an HTTPS GET and returns the output port for reading
  (define-values (status _ resp)
    (http-sendrecv host
                   uri
                   #:method #"GET"
                   #:ssl? #t
                   #:headers headers))

  (if (not (regexp-match #rx".+200.+" status))
      (begin
        (displayln (format "Error ~s in GET from ~a/~a" status host uri)
                   (current-error-port))
        (exit 1))
      resp))

(define (https-post host uri data [headers '()])
  ;; @@TODO
  #f)

(define (https-patch host uri data [headers '()])
  ;; HTTP PATCH command
  ;; https-patch :: String -> String -> List String -> Port | error
  (define-values (status _ resp)
    (http-sendrecv host
                   uri
                   #:method #"PATCH"
                   #:data data
                   #:ssl? #t
                   #:headers headers))

  (if (not (regexp-match #rx".+200.+" status))
      (begin
        (displayln (format "Error: ~s" status)
                   (current-error-port))
        (exit 1))
      ;; else
      resp))

;; The End
