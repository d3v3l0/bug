;; Copyright 2014 - William Emerison Six
;;  All rights reserved
;;  Distributed under LGPL 2.0 or Apache 2.0

(include "lang#.scm")
(include "lang-macros.scm")

;; uncomment this to see how they work when interpreting/compiling
;;(at-compile-time (pp "defined in 'at-compile-time'"))
;;(at-both-times (pp "defined in 'at-both-time'"))

(with-test
 (define (identity x) x)
 (equal? "foo" (identity "foo")))
;; thish should be defined somewhere else too
(with-test
 (define (noop ) 'noop)
 (equal? (noop) 'noop))

