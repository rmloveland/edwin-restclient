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
  (an-request
   "POST"
   "/auth"
   "@auth"))

(define (api-get path+params)
  (api-request
   "GET"
   path+params
   ""))

(define (api-send http-verb path+params payload)
  (api-request
   http-verb
   path+params
   payload))

(define-command api-send-region
  "Send the contents of the current region to the API endpoint."
  (lambda ()
    (list
     (restclient-command-prompt "http verb: ")
     (restclient-command-prompt "path+params: ")
     (current-region)))
  (lambda (http-verb path+params region)
    (let ((payload (region->string region)))
         (api-send http-verb
                   (string-append "/" path+params)
                   payload))))

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
       (lambda (output-mark)
         (shell-command #f output-mark directory #f command))))))

(define (restclient-command-prompt prompt)
  (prompt-for-string prompt #f
		     'DEFAULT-TYPE 'INSERTED-DEFAULT
		     'HISTORY 'SHELL-COMMAND))

(define (shell-command-pop-up-output generate-output)
  (let ((buffer (temporary-buffer "*REST client output*")))
    (let ((start (buffer-start buffer)))
      (generate-output start)
      (set-buffer-point! buffer start)
      (if (mark< start (buffer-end buffer))
	  (pop-up-buffer buffer #f)
	  (message "(Command completed with no output)")))))
