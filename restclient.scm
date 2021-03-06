#| -*-Scheme-*-

Copyright (C) 2012 Rich Loveland <loveland.richard@gmail.com>

This file is NOT part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

|#

;;;; REST client integration for Edwin.

(define api-urls '((console-prod . "http://api.appnexus.com")
                   (console-sand . "http://sand.api.appnexus.com")))

(define current-api-url (cdr (assv 'console-sand api-urls)))

(define (build-scurl-args verb base-url path+params payload)
  (string-append "echo '(\""
                 verb
                 "\" \""
                 base-url
                 "\" \""
                 path+params
                 "\" "
                 payload
                 ")'"
                 " | "
                 "scurl"))

(define (api-request http-verb path+params payload)
  (let ((command (build-scurl-args http-verb current-api-url path+params payload)))
    ((ref-command simplified-shell-command) command)))

(define (an-auth)
  (api-request
   "POST"
   "/auth"
   "@auth"))

(define (api-get path+params)
  (api-request
   "GET"
   (string-append "/" path+params)
   "*")) ;; Quick hack to avoid a Scurl error.

(define (api-send http-verb path+params payload)
  (api-request
   http-verb
   (string-append "/" path+params)
   payload))

(define (api-send-region http-verb path+params region)
  (let ((payload (region->string region)))
    (api-send http-verb
              (string-append "/" path+params)
              payload)))

(define-command api-send-region
  "Send the contents of the current region to the API endpoint."
  (lambda ()
    (list
     (restclient-command-prompt "http verb: ")
     (restclient-command-prompt "path+params: ")
     (current-region)))
  (lambda (http-verb path+params region)
    (api-send-region http-verb path+params region)))

(define-command api-get
  "Make a GET request to the API endpoint at PATH+PARAMS."
  (lambda ()
    (list
     (restclient-command-prompt "path+params: ")))
  (lambda (path+params)
    (api-get path+params)))

(define-command api-auth
  "Authenticate with the current API endpoint."
  ()
  (lambda ()
    (an-auth)))

(define-command api-toggle-endpoint
  "Toggle the current API endpoint."
  (lambda () ())
  (lambda ()
    (cond ((string=? current-api-url (cdr (assoc 'console-prod api-urls)))
           (set! current-api-url (cdr (assoc 'console-sand api-urls))))
          ((string=? current-api-url (cdr (assoc 'console-sand api-urls)))
           (set! current-api-url (cdr (assoc 'console-prod api-urls))))
          (else (begin (set! current-api-url (cdr (assoc 'console-sand api-urls)))
                       (message "Setting the current API URL to http://sand.api.appnexus.com"))))))

(define-command api-display-current-url
  "Display the current API endpoint."
  (lambda () ())
  (lambda ()
    (message (string-append "Current API endpoint is " current-api-url))))

(define-command simplified-shell-command
  "Execute string COMMAND in inferior shell; display output, if any.
Optional second arg true (prefix arg, if interactive) means
insert output in current buffer after point (leave mark after it)."
  (lambda ()
    (list (rest-client-command-prompt "Shell command")
	  (command-argument)))
  (lambda (command)
    (let ((directory (buffer-default-directory (current-buffer))))
      (shell-command-pop-up-output
       command
       (lambda (output-mark)
         (shell-command #f output-mark directory #f command))))))

(define (restclient-command-prompt prompt)
  (prompt-for-string prompt #f
		     'DEFAULT-TYPE 'INSERTED-DEFAULT
		     'HISTORY 'SHELL-COMMAND))

(define (shell-command-pop-up-output command generate-output)
  (let ((buffer (temporary-buffer
                 (string-append "* REST client: " command " *"))))
    (let ((start (buffer-start buffer)))
      (generate-output start)
      (set-buffer-point! buffer start)
      (if (mark< start (buffer-end buffer))
	  (pop-up-buffer buffer #f)
	  (message "(Command completed with no output)")))))

;;;; Keybindings

(define-key 'fundamental '(#\C-c #\C-p) 'api-send-region)
(define-key 'fundamental '(#\C-c #\C-g) 'api-get)
