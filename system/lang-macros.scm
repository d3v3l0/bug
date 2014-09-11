;; Copyright 2014 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.0 or Apache 2.0

(include "lang#.scm")


;; at-compile-time
;;  Evaluate the form in the compiler's address space.  When the program is
;;  executed, form will not be evaluated.

(define-macro (at-compile-time form)
  (eval form)
  `(quote noop))
 
;; at-both-times
;;  Evaluate the form in the compiler's address space, and also when the 
;;  resulting program is executed. 

(define-macro (at-both-times form)
  (eval form)
  form)

;;  lang#if
;;    A Smalltalk-like if.  
;;    Sample use:
;;      (if #t 
;;        (lambda () 4)
;;        (lambda () 5))
;;    I want to make a preprocessor so I can do something like
;;    Sample use:
;;      (if #t 
;;        [4]
;;        [5])

(at-both-times
 (define-macro (if pred ifTrue ifFalse)
   `(##if ,pred
	  ,(caddr ifTrue)
	  ,(caddr ifFalse))))

;; with-test
;;   Collocates a definiton with a test.  The test is run at compile-time
;;   only.
(define-macro (with-test definition test)
  (eval
   `(begin
      ,definition
      (if (eval ,test)
	  (lambda () 'no-op)
	  (lambda ()
	    (begin
	    (pp "Test Failed")
	    (pp (quote ,test))
	    (pp (quote ,definition))
	    (error "Test Failed"))))))
  ;;the actual macro expansion is just the definition
  definition)

;; all?
;;   all? is defined at compile-time only, so that the subsequent
;;   macro "with-tests" can verify that a list of tests
;;   all pass
(at-compile-time
 (define (all? lst)
   (cond ((null? lst) #t)
	 ((not (car lst)) #f)
	 (else (all? (cdr lst))))))

;; with-tests
;;   Collocates a definition with a collection of tests.  Tests are
;;   run sequentially, and are expected to return true or false
(define-macro (with-tests definition #!rest test)
  `(with-test ,definition (all? (list ,@test))))

;; ;; showing off the unit test framework
;; (with-tests
;;  ;; this definition happens at compile-time and runtime
;;  (define foobarbaz 5)
;;  ;; the following lines only happen at compile time.
;;  ;; therefore, any mutations to foobarbaz are not reflected in runtime
;;  (equal? (* 2 foobarbaz) 10)
;;  (begin
;;    (set! foobarbaz 20)
;;    (equal? (* 2 foobarbaz) 40))
;;  (equal? foobarbaz 20))
;; ;; if the following line were uncommented, it would print 5
;; ;;(pp foobarbaz)



;; when
;;   when the bool value is non-false, return the value of statement.
;;   when the bool value is false, return false
;; TODO - statement needs to be wrapped in a begin
(with-tests
 (define-macro (when bool statement)
   `(if ,bool
	(lambda () ,statement)
	(lambda () #f)))
 (equal? (when 5 3) 3)
 (equal? (when #f 3) #f))

;; aif
;;   anaphoric-if evaluates bool, binds it to the variable "it",
;;   which is accessible in body.
(with-tests
 (define-macro (aif bool body)
   `(let ((it ,bool))
      (when it
	    ,body)))
 (equal? (aif (+ 5 10) (* 2 it))
	 30)
 (equal? (aif #f (* 2 it))
	 #f))


