#lang racket/base

(require net/http-client
         racket/port
         ;; net/uri-codec
         )

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
        (displayln (format "Error: ~s" status)
                   (current-error-port))
        (exit 1))
      resp))

(define (http-post host uri data [headers '()])
  #f)

(define (http-patch host uri data [headers '()])
  ;; HTTP PATCH command
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
