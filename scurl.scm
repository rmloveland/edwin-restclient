#!/usr/local/bin/scsh \
-o defrec-package -e main -s
!#

;;;; User serviceable parts. Edit these variables to set curl's
;;;; working directory and cookies file, respectively.

(define preferred-working-directory
  (string-append home-directory
                 "/work/code/api"))

(define cookie-file "cookies")

;;;; Data munging

(define http-verbs
  '("GET"
    "PUT"
    "POST"
    "DELETE"))

(define (http-verb? v)
  (if (member v http-verbs)
      #t
      #f))

(define-record api-request
  http-verb
  base-url
  path+params
  payload)

;;; The curl wrapper function takes one argument, a record of type
;;; `api-request', which is defined above.
;;; The request protocol understood by this script is an s-expression
;;; (a string coming from stdin, actually) of the form
;;; '(HTTP-VERB API-URL PATH+PARAMS PAYLOAD).

(define (curl-wrapper r)
  "Returns the name of a temporary filename storing the request results."
  (if (api-request? r)
      (with-cwd preferred-working-directory
          (run/string
           (curl --silent --show-error
            -b ,cookie-file -c ,cookie-file -X ,(api-request:http-verb r)
                 ,(string-append (api-request:base-url r)
                                  (api-request:path+params r))
                 -d ,(api-request:payload r))))
      #f))

(define (main prog+args)
  (awk (read) (input) ()
       ((make-api-request (first input)   ; verb
                          (second input)  ; url
                          (third input)   ; path+params
                          (fourth input)) ; payload
        (let ((r (make-api-request (first input)   ; verb
                                  (second input)   ; url
                                  (third input)    ; path+params
                                  (fourth input)))); payload
          (display (curl-wrapper r))))))
