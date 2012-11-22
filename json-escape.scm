#!/usr/local/bin/scsh \
-e main -s
!#

(define (json-escape-quotes s)
  (regexp-substitute/global #f (rx #\") s
                            'pre "\\\"" 'post))

(define (main prog+args)
  (display #\")
  (awk (read-line) (line) ()
       ((set! line (json-escape-quotes line))
        (display line)))
  (display #\"))
