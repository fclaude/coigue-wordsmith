(define-module wordsmith
  (doc "Rhymes, synonyms and spelling suggestions for the word under the cursor, from api.datamuse.com.

  :rhyme     words that rhyme with it (near rhymes when there are no perfect ones)
  :synonym   words that mean the same
  :spell     words spelled like it, for a word you are not sure of

Each one sends only that word to api.datamuse.com, in the background, and
shows the answers in a list. Enter replaces the word with the one chosen;
Esc leaves the text alone.")
  (requires (net (allow "api.datamuse.com") (methods get))))

;;; Asking Datamuse. All of this runs in a background task: a command cannot
;;; wait on the network, and a task cannot touch the buffer, so it gets the
;;; word and returns a list of words.

(define (lookup relation word)
  (let ((entries (http-get-json
                  (string-append "https://api.datamuse.com/words?max=30&"
                                 relation "=" (url-encode word)))))
    ;; No matches is [], but be kind to anything that is not a list.
    (if (list? entries)
        (map (lambda (entry) (cdr (assoc "word" entry))) entries)
        '())))

(define (without word words)
  (filter (lambda (w) (not (string-ci=? w word))) words))

;; The result of a task is (ok . words) or (error . reason), so a server that
;; is down is a message, not a crash.
(define (ask relations word)
  (guard (e (#t (cons 'error (assoc-ref e 'message))))
    (let loop ((rest relations))
      (let ((found (without word (lookup (car rest) word))))
        (if (or (pair? found) (null? (cdr rest)))
            (cons 'ok found)
            (loop (cdr rest)))))))

;;; Putting the answer back. The word is remembered as a mark, so the text may
;;; change while the request is out; replace-at-mark refuses if the word
;;; itself was edited.

(define (first-letter s) (substring s 0 1))

(define (letter? s)
  (not (string=? (string-upcase s) (string-downcase s))))

;; Rhyme with the word's capitals: Tree -> Free, TREE -> FREE.
(define (like word new)
  (let ((c (first-letter word)))
    (cond ((or (< (string-length word) 1) (not (letter? c))) new)
          ((and (> (string-length word) 1)
                (string=? word (string-upcase word)))
           (string-upcase new))
          ((string=? c (string-upcase c))
           (string-append (string-upcase (first-letter new))
                          (substring new 1 (string-length new))))
          (else new))))

(define (replace here word choice)
  (guard (e (#t (message (string-append "\"" word "\" changed while you were choosing; nothing was replaced"))))
    (replace-at-mark here word (like word choice))))

(define (offer what here word result)
  (cond ((eq? (car result) 'error)
         (message (string-append "Could not reach api.datamuse.com: " (cdr result))))
        ((null? (cdr result))
         (message (string-append "No " what " found for \"" word "\"")))
        (else
         (on-channel (show-list (string-append (string-upcase (first-letter what)) (substring what 1 (string-length what))
                                               " for \"" word "\"")
                                (cdr result))
                     (lambda (choice) (replace here word choice))))))

(define (suggest what relations)
  (let ((range (word-range)))
    (if (not range)
        (message "Put the cursor on a word first")
        (let ((word (word-at-cursor))
              (here (mark-at (car range) (cadr range))))
          (message (string-append "Looking up " what " for \"" word "\"..."))
          (on-done (spawn-detached (lambda () (ask relations word)))
                   (lambda (task) (offer what here word (task-wait task))))))))

(define-command "rhyme" (lambda () (suggest "rhymes" '("rel_rhy" "rel_nry")))
  "Rhymes for the word under the cursor.")
(define-command "synonym" (lambda () (suggest "synonyms" '("rel_syn")))
  "Words that mean the same as the word under the cursor.")
(define-command "spell" (lambda () (suggest "spellings" '("sp")))
  "Words spelled like the word under the cursor.")
