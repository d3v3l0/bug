;;;Computation at Compile-Time
;;;===========================
;;;Bill Six
;;;:doctype: book
;;;
;;;

;;;//Copyright 2014-2018 - William Emerison Six
;;;//All rights reserved
;;;//Distributed under LGPL 2.1 or Apache 2.0
;;;
;;;Copyright 2014-2018 -- William Emerison Six

;;;All rights reserved

;;;Distributed under LGPL 2.1 or Apache 2.0

;;;Source code - http://github.com/billsix/bug
;;;
;;;
;;;
;;;
;;;[dedication]
;;;= Dedication
;;;For Mom and Dad.  Thanks for everything.
;;;
;;;
;;;
;;;
;;;[preface]
;;;= Preface
;;;This is a book about compiler design for people who have no interest
;;;in studying compiler design.  ...Umm, then who wants to read this book?
;;;Let me try this again...  This book is the study of
;;;source code which is discarded by the compiler, having no representation in
;;;the generated machine code.
;;;...Ummm, still not right...  This book is about viewing a compiler not only
;;;as a means of translating source code into machine code,
;;;but also viewing it as an interpreter capable of any
;;;general purpose computation.  ...Closer, but who cares?... I think I got it
;;;now. This is a book about "Testing at Compile-Time"!
;;;
;;;What do I mean by that?  Let's say you're looking at source code with which
;;;you are unfamiliar, such as the following:
;;;
;;;[source,Scheme]
;;;----
;;;(define permutations
;;;  (lambda (l)
;;;    (if (null? l)
;;;        '()
;;;        (let permutations ((l l))
;;;          (if (null? (cdr l))
;;;              (list l)
;;;              (flatmap (lambda (x) (map (lambda (y) (cons x y))
;;;                                        (permutations (remove x l))))
;;;                       l))))))
;;;----
;;;
;;;What does the code do?  How did the author intend for it to be used?
;;;In trying to answer those questions, fans of statically-typed programming
;;;languages might lament the lack of types, as types help them to reason about
;;;programs and help them to deduce where to look to find more information.
;;;In trying to answer those questions,
;;;fans of dynamically-typed languages might argue "Look at the tests!",
;;;as tests ensure the code functions in a user-specified way and
;;;they serve as a form of documentation.  But
;;;where are those tests?  Probably in some other file whose file-system path is
;;;similar to the current file's path (e.g., src/com/BigCorp/HugeProject/Foo.java
;;;is tested by test/com/BigCorp/HugeProject/FooTest.java).
;;;You'd have to find the file, open the file, look through it
;;;while ignoring tests which are
;;;for other methods.  Frankly, it's too much work and it interrupts the flow
;;;of coding, at least for me.
;;;
;;;But how else would a programmer organize tests?  Well in this book, which is the
;;;implementation of a library called "libbug",
;;;tests may be specified immediately after the procedure's definition.
;;;Should any test fail the compiler will
;;;exit in error, like a type error in a
;;;statically-typed language.
;;;
;;;[source,Scheme]
;;;----
;;;(unit-test
;;;(satisfies?
;;; permutations
;;; '(
;;;   (() ())
;;;   ((1) ((1)))
;;;   ((1 2) ((1 2)
;;;           (2 1)))
;;;   ((1 2 3) ((1 2 3)
;;;             (1 3 2)
;;;             (2 1 3)
;;;             (2 3 1)
;;;             (3 1 2)
;;;             (3 2 1)))
;;;   )))
;;;----
;;;
;;;Why does the collocation of tests with definitions matter?
;;;Towards answering the questions "what does the code do?" and "how did the author
;;;intend for it to be used?", there is neither searching through files nor guessing
;;;how the code was originally intended to be used.
;;;The fact that the
;;;tests are collocated with the procedure definition means that the reader can
;;;inspect the tests without switching between files, perhaps
;;;before looking at the procedure's definition.  And the reader
;;;may not even read the procedure at all if the tests gave him enough information
;;;to use it successfully.  Should he want to understand the procedure, he
;;;can mentally apply the procedure to the tests to understand it.
;;;
;;;Wait a second. If those tests are defined in the source code itself, won't they
;;;be in the executable?  And won't they run every time I execute the program?
;;;That would be unacceptable as it would both increase the size of the binary and
;;;slow down the program at start up.  Fortunately the
;;;answer to both questions is no, because in chapter <<buglang>> I show how to specify
;;;that certain code should be interpreted by the compiler instead of being
;;;compiled.  Lisp implementations such as Gambit are particularly well
;;;suited for this style of programming because unevaluated Lisp code is
;;;specified using a data structure of Lisp; because the compiler
;;;is an interpreter capable of being augmented.
;;;Upon finishing compilation, the
;;;compiler has _become_ the very program it is compiling.
;;;
;;;== Introduction
;;;
;;;Libbug is Bill's Utilities for Gambit Scheme:  a "standard library" of procedures
;;;which augments Scheme's small set of built-in procedures.
;;;Libbug provides procedures for list processing, streams,
;;;control structures,
;;;general-purpose evaluation at compile-time,
;;;and a
;;;compile-time test framework written in only 7 lines of code!
;;;Programs written using libbug optionally may be
;;;programmed in a relatively unobstructive
;;;"literate programming"
;;;style, so that a program can be read linearly in a book form.
;;;
;;;=== Prerequisites
;;;
;;;The reader is assumed to be somewhat familiar with Scheme, with Common Lisp-style
;;;macros, and with recursive design.  If the book proves too difficult for you,
;;;read "Simply Scheme"footnote:[available on-line for no cost]
;;;or "The Little Schemer".  Since libbug uses Gambit Scheme's
;;;Common Lisp-style macros, the author recommends reading "On Lisp"
;;;<<<onlisp>>> footnote:[available on-line for no cost].
;;;The other books listed in the bibliography, all of which inspired ideas for this
;;;book, are recommended reading but are
;;;not necessary to understand the contents of this book.
;;;
;;;=== Order of Parts
;;;This book is a "literate program", meaning that the source code of libbug is
;;;embedded within this book, and that the book is intended to be able to be
;;;read linearly.
;;;As such, new procedures defined are dependent upon
;;;procedures either defined in standard Gambit Scheme or
;;;which have already been defined earlier in libbug.  In writing the book,
;;;however, it became quite apparent that the foundation upon which libbug is constructed
;;;is by far the most difficult material.  Reading the book in the order which the compiler
;;;compiles the source
;;;would cause the reader to quickly get lost in the "how",
;;;before understanding "why".
;;;
;;;As such, the ordering of the book was rearranged in an effort to keep the reader
;;;engaged and curious.  The book begins with "Part 1, The Implementation of Libbug"
;;;and ends with "Part 2, Foundations Of Libbug".
;;;The Gambit compiler, however, compiles Part 2 first, then Part 1.
;;;
;;;=== Conventions
;;;Code which is part of libbug will be outlined and
;;;will have line numbers on the left.
;;;
;;;[source,Scheme,linenums]
;;;----
;; This is part of libbug.
;;;----
;;;
;;;
;;;Example code which is not part of libbug will not be outlined nor will it have line
;;;numbers.
;;;
;;;[source,Scheme]
;;;----
;;;(+ 1 ("This is NOT part of libbug"))
;;;----
;;;
;;;
;;;Some examples within this book show interaction with "gsi".
;;;Such examples will look like the following:
;;;
;;;[source,Scheme]
;;;----
;;;> (+ 1 2)
;;;3
;;;----
;;;
;;;
;;;The line on which the user entered text begins with a ">".  The result
;;;of evaluating that line appears on the subsequent line. In this case, 1 added to 2
;;;evaluates to 3.
;;;
;;;
;;;=== Getting the Source Code And Building
;;;The Scheme source code is located at http://github.com/billsix/bug.
;;;The Scheme files produce the libbug library, as well as this book.
;;;Currently the code works on various distributions of Linux, on FreeBSD, and on Mac
;;;OS X.  The build currently does not work on Windows.
;;;
;;;The prerequisites for building libbug are a C compiler  footnote:[such as GCC],
;;;Autoconf, Automake, and Gambit
;;;Scheme footnote:[http://gambitscheme.org] version 4.8 or newer.
;;;
;;;To compile the book and library, execute the following on the command line:
;;;
;;;[source,txt]
;;;----
;;;$ ./autogen.sh
;;;$ ./configure --prefix=$BUG_HOME --enable-html
;;;$ make
;;;$ make install
;;;----
;;;
;;;- The argument to "prefix" is the location into which libbug
;;;will be installed when "make install" is executed. "$BUG_HOME" is an
;;;environment variable that I have not defined, so the reader should substitute
;;;"$BUG_HOME" with an actual filesystem path.
;;;- "--enable-html" means to build this book as a HTML via asciidoc.  To disable the creation of the html,
;;;substitute "--enable-html=no".
;;;
;;;After installing libbug, you should set the following environment variables.
;;;
;;;[source,txt]
;;;----
;;;export PATH=$BUG_HOME/bin:$PATH
;;;export PKG_CONFIG_PATH=$BUG_HOME/lib/pkgconfig/
;;;export LD_LIBRARY_PATH=$BUG_HOME/lib:$LD_LIBRARY_PATH
;;;export LIBRARY_PATH=$BUG_HOME/lib:$LIBRARY_PATH
;;;----
;;;
;;;=== Creating Your Own Project
;;;
;;;[source,txt]
;;;----
;;;$ bug-create-project testProject 1.0 "Jane Doe <jane@doe.com>"
;;;$ cd testProject/
;;;$ source env.sh
;;;$ ./autogen.sh
;;;$ ./configure --prefix=$BUILD_DIR
;;;....
;;;....
;;;$ make
;;;.....
;;;"FIRST 10 PRIMES"
;;;(2 3 5 7 11 13 17 19 23 29)
;;;....
;;;....
;;;$ make install
;;;....
;;;$ cd $BUILD_DIR
;;;$ ./bin/testProject
;;;"FIRST 10 PRIMES"
;;;(2 3 5 7 11 13 17 19 23 29)
;;;----
;;;
;;;Of particular note is that a "FIRST 10 PRIMES", and the 10 values, were printed
;;;during the compilation of the source code in the "make" phase.
;;;
;;;=== Comparison of Compile-Time Computations in Other Languages
;;;
;;;What exactly is computation at compile-time?  An introduction
;;;to the topic is provided
;;;in Appendix <<appendix1>>
;;;demonstrated
;;;in languages of more widespread use (C and C++),
;;;along with a comparison
;;;of their expressive power.
;;;
;;;
;;;= The Implementation of Libbug
;;;
;;;== Introductory Procedures
;;;[[beginninglibbug]]
;;;
;;;This chapter begins the definition of libbug's standard library of Scheme procedures and
;;;macros footnote:[The code within chapters <<beginninglibbug>>
;;;through  <<endinglibbug>> (inclusive) is found in
;;;"src/main.bug.scm".], along with tests which are run as part of the
;;;compilation process.  If any test fails, the compiler will exit in error,
;;;much like a type error in a statically-typed language.
;;;
;;;To gain such functionality libbug cannot be defined using Gambit Scheme's
;;;"##define", "##define-macro", and "##define-structure", since
;;;they only define variables and
;;;procedures for use at run-time footnote:[well... that statement is not true
;;;for "##define-macro", but it makes for a simpler explanation upon first reading].
;;;Instead, definitions within
;;;libbug use "libbug-private#define", "libbug-private#define-macro", and
;;;"libbug-private##define-structure" footnote:[Per convention
;;;within libbug, procedures namespaced to "libbug-private" are not compiled into the library;
;;;such procedures are meant for private use within the implementation
;;;of libbug.], which  are implemented in Chapter <<buglang>>.
;;;How they are implemented is not relevant yet, since the use of these
;;;procedure-defining procedures will be explained
;;;incrementally.
;;;
;;;[source,Scheme,linenums]
;;;----
(include "bug-language.scm")
(##namespace ("libbug-private#" define define-macro define-structure))
;;;----
;;;- On line 1, the code which makes computation at compile-time possible
;;;is imported. That code is defined in Chapter <<buglang>>.
;;;- On line 2, Gambit's "##namespace" procedure is invoked, ensuring
;;;that all unnamespaced uses of "define", "define-macro",
;;;and "define-structure" will use libbug's version of those procedures
;;;instead of Gambit's.
;;;- On line 3, all unnamespaced uses of "if" will use libbug's version.
;;;
;;;
;;;
;;;=== noop
;;;indexterm:[noop]
;;;
;;;The first definition is "noop" (meaning "no operation"), a procedure which
;;;takes zero arguments and
;;;which evaluates to the symbol 'noop.
;;;
;;;[source,Scheme,linenums]
;;;----
(define noop
  (lambda () 'noop))
;;;----
;;;
;;;- On line 1, the libbug-private#define macro footnote:[defined in section  <<libbugdefine>>]
;;;is invoked.
;;;- On line 1, the variable name "noop".
;;;- On line 2, the lambda literal to be stored into the variable.
;;;Libbug includes a Scheme preprocessor "bug-gscpp",
;;;which expands lambda literals
;;;into lambdas.  In this case, "bug-gscpp" expands
;;;
;;;[source,Scheme]
;;;----
;;;['noop]
;;;----
;;;
;;;
;;;into
;;;
;;;[source,Scheme]
;;;----
;;;(lambda () 'noop)
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (noop) 'noop))
;;;----
;;;
;;;- On line 1, an invocation of "unit-test". In this case, "unit-test" takes one
;;;parameter, which is a test to be run at compile-time.
;;;- On line 2, an expression which evaluates to a boolean.
;;;This is a
;;;test which will be evaluated at compile-time.  Should the test fail,
;;;the compilation of libbug will fail and neither the shared library nor the document which
;;;you are currently reading will be created.
;;;Tests are not present in the created
;;;library.
;;;
;;;"noop" does not look useful at first glance, but it is used when
;;;a procedure of zero arguments is required but the resulting value of it is not.
;;;For instance, "noop" is used as a default "exception-handler" for many
;;;procedures within libbug.
;;;
;;;
;;;=== identity
;;;"identity" is a procedure of one argument which evaluates to
;;;its argument. <<<calculi>>>
;;;
;;;(((identity)))
;;;
;;;[source,Scheme,linenums]
;;;----
(define identity
  (lambda (x) x))
;;;----
;;;
;;;"unit-test" can take more than one test as parameters.
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? "foo" (identity "foo"))
 (equal? identity (identity identity)))
;;;----
;;;
;;;
;;;
;;;=== all?
;;;Like regular Scheme's "and", but takes a list instead of a variable number of arguments, and
;;;all elements of the list are evaluated before "all?" is applied.
;;;
;;;[[langiffirstuse]]
;;;(((all?)))
;;;[source,Scheme,linenums]
;;;----
(define all?
  (lambda (l)
    (if (null? l)
        #t
        (if (car l)
            (all? (cdr l))
            #f))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (all? '())
 (all? '(1))
 (all? '(#t))
 (all? '(#t #t))
 (not (all? '(#f)))
 (not (all? '(#t #t #t #f))))
;;;----
;;;
;;;Tests in libbug are defined for two purposes.  Firstly, to ensure
;;;that the expected behavior of a procedure does not change when the source code
;;;has changed.  Secondly, as a form of documentation.
;;;Libbug is unique footnote:[as far as the author knows] in that the tests are collocated with
;;;the procedure definitions.  The reader is encouraged to read the tests for a
;;;procedure before reading the implementation; since in many cases, the tests are designed
;;;specifically to guide the reader through the implementation.
;;;
;;;
;;;=== satisfies?
;;;
;;;When writing multiple tests, why explicitly invoke the procedure repeatedly
;;;with varying inputs and outputs, as was done for "all?"?  Instead, provide
;;;the procedure and a list
;;;of input/output pairs footnote:[Within libbug, a parameter named "f" usually means the parameter is
;;;a procedure.].
;;;
;;;(((satisfies?)))
;;;[source,Scheme,linenums]
;;;----
(define satisfies?
  (lambda (f list-of-pairs)
    (all? (map (lambda (pair) (equal? (f (car pair))
                                      (cadr pair)))
               list-of-pairs))))
;;;----
;;;
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (x) (+ x 1))
  '(
    (0 1)
    (1 2)
    (2 3)
    ))
 (satisfies?
  all?
  '(
    (() #t)
    ((1) #t)
    ((#t) #t)
    ((#t #t) #t)
    ((#f) #f)
    ((#t #t #t #f) #f)))
 )
;;;----
;;;
;;;
;;;=== while
;;;
;;;(((while)))
;;;
;;;Programmers who are new to the Scheme language  may be surprised that
;;;the language provides no built-in syntax for looping, such as "for"
;;;or "while".  A better question is why don't other
;;;languages provide primitives from which you can create
;;;those looping constructs yourself?  "Take the red pill."  footnote:[Within libbug,
;;;a parameter named "pred?" or "p?" usually means the parameter
;;;is a predicate, meaning a procedure which returns true or false.]
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(define while
  (lambda (pred? body)
    (let while ((val 'noop))
      (if (pred?)
          (while (body))
          val))))
;;;----
;;;
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (let ((a 0))
   (and (equal? (while (lambda () (< a 5))
                       (lambda () (set! a (+ a 1))))
                #!void)
        (equal? a 5)))
 (let ((a 0))
   (and (equal? (while (lambda () (< a 5))
                       (lambda () (set! a (+ a 1))
                               'foo))
                'foo)
        (equal? a 5))))
;;;----
;;;
;;;
;;;
;;;
;;;=== numeric-if
;;;A conditional expression for numbers, based on their sign. "numeric-if"
;;;uses Gambit's keyword syntax.  "ifPositive", "ifZero", and "ifNegative" are
;;;optional arguments, each with their default value as the value in the "noop"
;;;variable.
;;;
;;;
;;;(((numeric-if)))
;;;[source,Scheme,linenums]
;;;----
(define numeric-if
  (lambda (n #!key (ifPositive noop) (ifZero noop) (ifNegative noop))
    (if (> n 0)
        (ifPositive)
        (if (= n 0)
            (ifZero)
            (ifNegative)))))
;;;----
;;;
;;;<<<onlisp>>>
;;;
;;;Keyword arguments are optionally passed to the procedure, and use the following syntax.
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (n)
    (numeric-if n
                ifPositive: (lambda () 'pos)
                ifZero: (lambda () 'zero)
                ifNegative: (lambda () 'neg)))
  '(
    (5 pos)
    (0 zero)
    (-5 neg)
    ))
 (satisfies?
  (lambda (n)
    (numeric-if n
                ifZero: (lambda () 'zero)))
  '(
    (5 noop)
    (0 zero)
    (-5 noop)
    ))
 )
;;;----
;;;
;;;
;;;
;;;
;;;
;;;=== atom?
;;;(((atom?)))
;;;[source,Scheme,linenums]
;;;----
(define atom?
  (lambda (x)
    (or (number? x)
        (symbol? x)
        (boolean? x)
        (string? x)
        (char? x))))
;;;----
;;;
;;;footnote:[Within libbug, a parameter named "x" usually means the parameter can
;;;be of any type.]
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  atom?
  '(
    (1 #t)
    (1/3 #t)
    (a #t)
    (#t #t)
    (#f #t)
    ("string" #t)
    (#\c #t)
    ((make-vector 3) #f)
    (() #f)
    ((a) #f)
    ))
 )
;;;----
;;;
;;;
;;;
;;;=== complement
;;;
;;;(((complement)))
;;;[source,Scheme,linenums]
;;;----
(define complement
  (lambda (f)
    (lambda (#!rest args)
      (not (apply f args)))))
;;;----
;;;
;;;<<<onlisp>>>
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  pair?
  '(
    (1 #f)
    ((1 2) #t)
    ))
 (satisfies?
  (complement pair?)
  '(
    (1 #t)
    ((1 2) #f)
    ))
 )
;;;----
;;;
;;;
;;;
;;;
;;;
;;;
;;;== Lists
;;;=== copy
;;;Creates a shallow copy of the list footnote:[meaning the list structure itself is copied, but not the data
;;;to which each node points.] footnote:[Within libbug, a parameter named "l" usually means the parameter is
;;;a list.].
;;;
;;;(((copy)))
;;;[source,Scheme,linenums]
;;;----
(define copy
  (lambda (l)
    (map identity l)))
;;;----
;;;
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (let ((a '(1 2 3 4 5)))
   (and (equal? a (copy a))
        (not (eq? a (copy a)))))
 )
;;;----
;;;
;;;For a thorough description of "equal?" vs "eq?", see <<<schemeprogramanguage>>>.
;;;
;;;
;;;=== proper?
;;;Tests that the last element of the list is the sentinel value "'()".
;;;Will not terminate on a circular list.
;;;
;;;(((proper?)))
;;;[source,Scheme,linenums]
;;;----
(define proper?
  (lambda (l)
    (if (null? l)
        #t
        (if (pair? l)
            (proper? (cdr l))
            #f))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  proper?
  '(
    (() #t)
    ((4) #t)
    ((1 2) #t)
    (4 #f)
    ((1 2 . 5) #f)
    )))
;;;----
;;;
;;;
;;;
;;;
;;;
;;;=== first
;;;
;;;
;;;(((first)))
;;;[source,Scheme,linenums]
;;;----
(define first
  (lambda (l #!key (onNull noop))
    (if (null? l)
        (onNull)
        (car l))))
;;;----
;;;
;;;<<<ss>>>
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  first
  '(
    (() noop)
    ((1 2 3) 1)
    ))
 (satisfies?
  (lambda (l) (first l onNull: (lambda () 5)))
  '(
    (() 5)
    ((1 2 3) 1)
    )))
;;;----
;;;
;;;
;;;
;;;
;;;=== but-first
;;;(((but-first)))
;;;[source,Scheme,linenums]
;;;----
(define but-first
  (lambda (l #!key (onNull noop))
    (if (null? l)
        (onNull)
        (cdr l))))
;;;----
;;;
;;;<<<ss>>>
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  but-first
  '(
    (() noop)
    ((1 2 3) (2 3))
    ))
 (satisfies?
  (lambda (l) (but-first l onNull: (lambda () 5)))
  '(
    (() 5)
    ((1 2 3) (2 3))
    )))
;;;----
;;;
;;;
;;;=== last
;;;(((last)))
;;;[source,Scheme,linenums]
;;;----
(define last
  (lambda (l #!key (onNull noop))
    (if (null? l)
        (onNull)
        (let last ((l l))
          (if (null? (cdr l))
              (car l)
              (last (cdr l)))))))
;;;----
;;;
;;;<<<ss>>>
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  last
  '(
    (() noop)
    ((1) 1)
    ((2 1) 1)
    ))
 (satisfies?
  (lambda (l) (last l onNull: (lambda () 5)))
  '(
    (() 5)
    ((2 1) 1)
    )))
;;;----
;;;
;;;
;;;
;;;=== but-last
;;;(((but-last)))
;;;[source,Scheme,linenums]
;;;----
(define but-last
  (lambda (l #!key (onNull noop))
    (if (null? l)
        (onNull)
        (let but-last ((l l))
          (if (null? (cdr l))
              '()
              (cons (car l)
                    (but-last (cdr l))))))))
;;;----
;;;
;;;<<<ss>>>
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  but-last
  '(
    (() noop)
    ((1) ())
    ((2 1) (2))
    ((3 2 1) (3 2))
    ))
 (satisfies?
  (lambda (l) (but-last l onNull: (lambda () 5)))
  '(
    (() 5)
    ((3 2 1) (3 2))
    ))
 )
;;;----
;;;
;;;
;;;
;;;=== filter
;;;(((filter)))
;;;[source,Scheme,linenums]
;;;----
(define filter
  (lambda (p? l)
    (let filter ((l l))
      (if (null? l)
          '()
          (let ((first (car l)))
            (if (p? first)
                (cons first (filter (cdr l)))
                (filter (cdr l))))))))
;;;----
;;;
;;;<<<ss>>> footnote:[Simply Scheme has an excellent discussion on section
;;;on Higher-Order Functions and their combinations <<<ss>>>]. <<<sicp>>>.
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (filter (lambda (x) (not (= 4 x)))
                      l))
  '(
    (() ())
    ((4) ())
    ((1 4) (1))
    ((4 1 4) (1))
    ((2 4 1 4) (2 1))
    )))
;;;----
;;;
;;;
;;;
;;;
;;;
;;;=== remove
;;;(((remove)))
;;;[source,Scheme,linenums]
;;;----
(define remove
  (lambda (x l)
    (filter (lambda (y) (not (equal? x y)))
            l)))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (remove 5 l))
  '(
    ((1 5 2 5 3 5 4 5 5) (1 2 3 4))
    )))
;;;----
;;;
;;;
;;;=== fold-left
;;;Reduce the list to a scalar by applying the reducing procedure repeatedly,
;;;starting from the "left" side of the list footnote:[Within libbug, a
;;;parameter named "acc" usually means the parameter
;;;is an accumulated value.].
;;;
;;;(((fold-left)))
;;;[source,Scheme,linenums]
;;;----
(define fold-left
  (lambda (f acc l)
    (let fold-left ((acc acc) (l l))
      (if (null? l)
          acc
          (fold-left (f acc
                        (car l))
                     (cdr l))))))
;;;----
;;;
;;;
;;;
;;;
;;;<<<sicp>>>
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (fold-left + 5 l))
  '(
    (() 5)
    ((1) 6)
    ((1 2) 8)
    ((1 2 3 4 5 6) 26)
    ))
;;;----
;;;
;;;Understanding the first test may give the reader false confidence in understanding
;;;"fold-left".  To understand how "fold-left" really works, understand
;;;how it works with non-commutative procedures, such as "-".
;;;
;;;[source,Scheme,linenums]
;;;----
 (satisfies?
  (lambda (l) (fold-left - 5 l))
  '(
    (() 5)
    ((1) 4)
    ((1 2) 2)
    ((1 2 3 4 5 6) -16))))
;;;----
;;;
;;;
;;;=== sum
;;;
;;;(((sum)))
;;;[source,Scheme,linenums]
;;;----
(define sum
  (lambda (l)
    (fold-left + 0 l)))
;;;----

;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  sum
  '(( (1)    1)
    ( (1 2)  3)
    ( (1 2 3) 6)))
 )
;;;----
;;;
;;;=== fold-right
;;;Reduces the list to a scalar by applying the reducing
;;;procedure repeatedly,
;;;starting from the "right" side of the list
;;;
;;;(((fold-right)))
;;;[source,Scheme,linenums]
;;;----
(define fold-right
  (lambda (f acc l)
    (let fold-right ((l l))
      (if (null? l)
          acc
          (f (car l)
             (fold-right (cdr l)))))))
;;;----
;;;
;;;<<<sicp>>>
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (fold-right + 5 l))
  '(
    (() 5)
    ((1) 6)
    ((1 2) 8)
    ((1 2 3 4 5 6) 26)
    ))
 (satisfies?
  (lambda (l) (fold-right - 5 l))
  '(
    (() 5)
    ((1) -4)
    ((1 2) 4)
    ((1 2 3 4 5 6) 2)))
 )
;;;----
;;;
;;;
;;;
;;;
;;;=== scan-left
;;;Like "fold-left", but every intermediate value
;;;of "fold-left"s accumulator is an element in the resulting list of "scan-left".
;;;
;;;(((scan-left)))
;;;[source,Scheme,linenums]
;;;----
(define scan-left
  (lambda (f acc l)
    (let ((acc-list (list acc)))
      (let scan-left ((acc acc)
                      (l l)
                      (last-cell acc-list))
        (if (null? l)
            acc-list
            (let ((newacc (f acc
                             (car l))))
              (scan-left newacc
                         (cdr l)
                         (begin
                           (set-cdr! last-cell (list newacc))
                           (cdr last-cell)))))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (scan-left + 5 l))
  '(
    (() (5))
    ((1) (5 6))
    ((1 2) (5 6 8))
    ((1 2 3 4 5 6) (5 6 8 11 15 20 26))
    ))
 (satisfies?
  (lambda (l) (scan-left - 5 l))
  '(
    (() (5))
    ((1) (5 4))
    ((1 2) (5 4 2))
    ((1 2 3 4 5 6) (5 4 2 -1 -5 -10 -16))))
 (satisfies?
  (lambda (l) (scan-left * 1 l))
  '(
    (() (1))
    ((2) (1 2))
    ((2 3) (1 2 6))
    ((2 3 4) (1 2 6 24))
    ((2 3 4 5 ) (1 2 6 24 120))
    ))
 )
;;;----
;;;
;;;
;;;=== append!
;;;Like Scheme's "append", but recycles the last cons cell, so it is a more
;;;efficient computation at the expense of mutating the input.
;;;
;;;(((append"!)))
;;;[source,Scheme,linenums]
;;;----
(define append!
  (lambda (#!rest ls)
    (let ((append! (lambda (second-list first-list)
                     (if (null? first-list)
                         second-list
                         (let ((head first-list))
                           (let append! ((first-list first-list))
                             (if (null? (cdr first-list))
                                 (set-cdr! first-list second-list)
                                 (append! (cdr first-list))))
                           head)))))
      (fold-left append! '() (reverse ls)))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (append! '()
                  '(5))
         '(5))
 (equal? (append! '(1 2 3)
                  '(5))
         '(1 2 3 5))
 (let ((a '(1 2 3))
       (b '(4 5 6)))
   (append! a b '(7))
   (equal? a '(1 2 3 4 5 6 7)))
 (let ((a '(1 2 3))
       (b '(4 5 6)))
   (append! a b '(7) '(8))
   (equal? a '(1 2 3 4 5 6 7 8)))
 )
;;;----
;;;
;;;
;;;
;;;=== flatmap
;;;(((flatmap)))
;;;[source,Scheme,linenums]
;;;----
(define flatmap
  (lambda (f l)
    (fold-left append! '() (map f l))))
;;;----
;;;
;;;<<<sicp>>>
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (flatmap (lambda (x) (list x
                                         (+ x 1)
                                         (+ x 2)))
                       l))
  '(
    ((10 20) (10 11 12 20 21 22))
    ))
 )
;;;----
;;;
;;;
;;;Mutating cons cells which were created in this procedure still
;;;respects referential-transparency
;;;from the caller's point of view.
;;;
;;;
;;;=== take
;;;(((take)))
;;;[source,Scheme,linenums]
;;;----
(define take
  (lambda (n l)
    (if (or (null? l)
            (<= n 0))
        '()
        (cons (car l)
              (take (- n 1)
                    (cdr l))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (n) (take n '(a b)))
  '(
    (-1 ())
    (0 ())
    (1 (a))
    (2 (a b))
    (3 (a b))
    )))
;;;----
;;;
;;;
;;;
;;;=== take-while
;;;(((take-while)))
;;;[source,Scheme,linenums]
;;;----
(define take-while
  (lambda (p? l)
    (let ((not-p? (complement p?)))
      (let take-while ((l l))
        (if (or (null? l)
                (not-p? (car l)))
            '()
            (cons (car l)
                  (take-while (cdr l))))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (x) (take-while (lambda (y) (not (equal? x y)))
                          '(a b c)))
  '(
    (a ())
    (b (a))
    (c (a b))
    (d (a b c))
    )))
;;;----
;;;
;;;
;;;
;;;=== drop
;;;(((drop)))
;;;[source,Scheme,linenums]
;;;----
(define drop
  (lambda (n l)
    (if (or (null? l)
            (<= n 0))
        l
        (drop (- n 1)
              (cdr l)))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (n) (drop n '(a b)))
  '(
    (-1 (a b))
    (0 (a b))
    (1 (b))
    (2 ())
    (3 ())
    )))
;;;----
;;;
;;;
;;;=== drop-while
;;;(((drop-while)))
;;;[source,Scheme,linenums]
;;;----
(define drop-while
  (lambda (p? l)
    (let ((not-p? (complement p?)))
      (let drop-while ((l l))
        (if (or (null? l)
                (not-p? (car l)))
            l
            (drop-while (cdr l)))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (x) (drop-while (lambda (y) (not (equal? x y)))
                          '(a b c)))
  '(
    (a (a b c))
    (b (b c))
    (c (c))
    (d ())
    (e ())
    )))
;;;----
;;;
;;;
;;;
;;;=== enumerate-interval
;;;(((enumerate-interval)))
;;;[source,Scheme,linenums]
;;;----
(define enumerate-interval
  (lambda (low high #!key (step 1))
    (let enumerate-interval ((low low))
      (if (> low high)
          '()
          (cons low
                (enumerate-interval (+ low step)))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (enumerate-interval 1 10)
         '(1 2 3 4 5 6 7 8 9 10))
 (equal? (enumerate-interval 1 10 step: 2)
         '(1 3 5 7 9)))
;;;----
;;;
;;;
;;;=== any?
;;;
;;;(((any?)))
;;;[source,Scheme,linenums]
;;;----
(define any?
  (lambda (l)
    (if (null? l)
        #f
        (if (car l)
            #t
            (any? (cdr l))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  any?
  '(
    (() #f)
    ((1) #t)
    ((#t) #t)
    ((#t #t) #t)
    ((#f) #f)
    ((#t #t #t #f) #t)))
 )
;;;----
;;;
;;;
;;;=== zip
;;;(((zip)))
;;;[source,Scheme,linenums]
;;;----
(define zip
  (lambda (#!rest lsts)
    (let zip ((lsts lsts))
      (if (any? (map null? lsts))
          '()
          (cons (map car lsts)
                (zip (map cdr lsts)))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (zip '() '())
         '())
 (equal? (zip '(1) '(4))
         '((1 4)))
 (equal? (zip '(1 2) '(4 5))
         '((1 4)
           (2 5)))
 (equal? (zip '(1 2 3) '(4 5 6))
         '((1 4)
           (2 5)
           (3 6)))
 (equal? (zip '(1) '())
         '())
 (equal? (zip '() '(1))
         '())
 )
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (zip '() '() '())
         '())
 (equal? (zip '(1 2 3)
              '(4 5 6)
              '(7 8 9))
         '((1 4 7)
           (2 5 8)
           (3 6 9)))
 )
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (zip '() '() '() '())
         '())
 (equal? (zip '(1 2 3)
              '(4 5 6)
              '(7 8 9)
              '(10 11 12))
         '((1 4 7 10)
           (2 5 8 11)
           (3 6 9 12)))
 )
;;;----
;;;
;;;
;;;=== zip-with
;;;(((zip-with)))
;;;[source,Scheme,linenums]
;;;----
(define zip-with
  (lambda (f #!rest lsts)
    (let zip ((lsts lsts))
      (if (any? (map null? lsts))
          '()
          (cons (apply f (map car lsts))
                (zip (map cdr lsts)))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (zip-with +
                   '()
                   '())
         '())
 (equal? (zip-with +
                   '(1)
                   '(4))
         '(5))
 (equal? (zip-with +
                   '(1 2)
                   '(4 5))
         '(5 7))
 (equal? (zip-with +
                   '(1 2 3)
                   '(4 5 6))
         '(5 7 9))
 (equal? (zip-with +
                   '(1)
                   '())
         '())
 (equal? (zip-with +
                   '()
                   '(1))
         '())
 )
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (zip-with +
                   '()
                   '()
                   '())
         '())
 (equal? (zip-with +
                   '(1 2 3)
                   '(4 5 6)
                   '(7 8 9))
         '(12 15 18))
 )
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (zip-with +
                   '()
                   '()
                   '()
                   '())
         '())
 (equal? (zip-with +
                   '(1 2 3)
                   '(4 5 6)
                   '(7 8 9)
                   '(10 11 12))
         '(22 26 30))
 )
;;;----
;;;
;;;
;;;=== permutations
;;;(((permutations)))
;;;[source,Scheme,linenums]
;;;----
(define permutations
  (lambda (l)
    (if (null? l)
        '()
        (let permutations ((l l))
          (if (null? (cdr l))
              (list l)
              (flatmap (lambda (x) (map (lambda (y) (cons x y))
                                        (permutations (remove x l))))
                       l))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  permutations
  '(
    (() ())
    ((1) ((1)))
    ((1 2) ((1 2)
            (2 1)))
    ((1 2 3) ((1 2 3)
              (1 3 2)
              (2 1 3)
              (2 3 1)
              (3 1 2)
              (3 2 1)))
    )))
;;;----
;;;
;;;Inspired by <<<sicp>>>, although I think they have a slight
;;;mistake in their code.  Given their definition (permutations '())
;;;evaluates to '(()), instead of '().
;;;
;;;See also <<<taocp>>>

;;;=== cartesian-product
;;;
;;;(((cartesian-product)))
;;;[source,Scheme,linenums]
;;;----
(define cartesian-product
  (lambda (lol)
    (##define cp
      (lambda (lol)
        (cond
         ((null? (cdr lol))
          (map list (car lol)))
         (#t
          (flatmap (lambda (x) (map (lambda (y) (cons x y))
                                    (cp (cdr lol))))
                   (car lol))))))
    (cond ((null? lol) '())
          (#t (cp lol)))))
;;;----

;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (cartesian-product '())
         '())
 (equal? (cartesian-product '((1 2 3)))
         '((1) (2) (3)))
 (equal? (cartesian-product '((1 2 3)
                              (4 5 6)))
         '((1 4)
           (1 5)
           (1 6)
           (2 4)
           (2 5)
           (2 6)
           (3 4)
           (3 5)
           (3 6)))
;;;----

;;;[source,Scheme,linenums]
;;;----
 (equal? (cartesian-product '((1 2 3)
                              (4 5 6)
                              (7 8 9)))
         '((1 4 7)
           (1 4 8)
           (1 4 9)
           (1 5 7)
           (1 5 8)
           (1 5 9)
           (1 6 7)
           (1 6 8)
           (1 6 9)
           (2 4 7)
           (2 4 8)
           (2 4 9)
           (2 5 7)
           (2 5 8)
           (2 5 9)
           (2 6 7)
           (2 6 8)
           (2 6 9)
           (3 4 7)
           (3 4 8)
           (3 4 9)
           (3 5 7)
           (3 5 8)
           (3 5 9)
           (3 6 7)
           (3 6 8)
           (3 6 9)))
 )
;;;----
;;;
;;;
;;;=== ref-of
;;;The inverse of list-ref.
;;;
;;;(((ref-of)))
;;;[source,Scheme,linenums]
;;;----
(define ref-of
  (lambda (l x #!key (onMissing noop))
    (if (null? l)
        (onMissing)
        (let ref-of ((l l)
                     (index 0))
          (if (equal? (car l) x)
              index
              (if (null? (cdr l))
                  (onMissing)
                  (ref-of (cdr l) (+ index 1))))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (x) (ref-of '(a b c d e f g) x))
  '(
    (z noop)
    (a 0)
    (b 1)
    (g 6)
    ))
 )
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (x) (ref-of '(a b c d e f g)
                      x
                      onMissing: (lambda () 'missing)))
  '(
    (z missing)
    (a 0)
    ))
 )
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (let ((l '(a b c d e f g)))
   (satisfies?
    (lambda (x) (list-ref l (ref-of l x)))
    '(
      (a a)
      (b b)
      (g g)
      )))
 )
;;;----
;;;
;;;
;;;=== list-set!
;;;
;;;(((list-set!)))
;;;[source,Scheme,linenums]
;;;----
;; TODO - handle case where index is too large
;; N.B this is called list-sef! instead of list-ref-set!
;;  to facilitate use by setf!, as setf! drops the -ref suffix
(define list-set!
  (lambda (l index val)
    (if (equal? 0 index)
        (set-car! l val)
        (list-set! (cdr l) (- index 1) val))))
;;;----

;;;[source,Scheme,linenums]
;;;----
(unit-test
 (let ((foo '(bar baz quux)))
   (list-set! foo 0 'blah)
   (equal? foo '(blah baz quux)))
 (let ((foo '(bar baz quux)))
   (list-set! foo 1 'blah)
   (equal? foo '(bar blah quux))
   )
 )
;;;----

;;;
;;;
;;;=== partition
;;;Partitions the input list into two lists, with the criterion being whether or not
;;;the application of the  procedure "p?" to each element of the input list evaluated
;;;to true or false.
;;;
;;;
;;;(((partition)))
;;;[source,Scheme,linenums]
;;;----
(define partition
  (lambda (l p?)
    (let partition ((l l)
                    (trueList '())
                    (falseList '()))
      (if (null? l)
          (list trueList falseList)
          (let ((head (car l)))
            (if (p? head)
                (partition (cdr l)
                           (cons head trueList)
                           falseList)
                (partition (cdr l)
                           trueList
                           (cons head falseList))))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (partition l (lambda (x) (<= x 3))))
  '(
    (() (()
         ()))
    ((3 2 5 4 1) ((1 2 3)
                  (4 5)))
    )))
;;;----
;;;
;;;In section <<dbind>>, "destructuring-bind" allows for a more convenient syntax when
;;;using "partition".
;;;
;;;[source,Scheme]
;;;----
;;;> (destructuring-bind (trueList falseList)
;;;                     (partition '(3 2 5 4 1)
;;;                                (lambda (x) (<= x 3)))
;;;                     trueList)
;;;(1 2 3)
;;;> (destructuring-bind (trueList falseList)
;;;                     (partition '(3 2 5 4 1)
;;;                                (lambda (x) (<= x 3)))
;;;                     falseList)
;;;(4 5)
;;;----
;;;
;;;
;;;=== sort
;;;(((sort)))
;;;[source,Scheme,linenums]
;;;----
(define sort
  (lambda (l comparison?)
    (let sort ((l l))
      (if (null? l)
          '()
          (let* ((current-node (car l))
                 (p (partition (cdr l)
                               (lambda (x) (comparison? x current-node)))))
            (append! (sort (car p))
                     (cons current-node
                           (sort (cadr p)))))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (l) (sort l <))
  '(
    (() ())
    ((1 3 2 5 4 0) (0 1 2 3 4 5))
    )))
;;;----
;;;
;;;
;;;
;;;
;;;=== reverse!
;;;Reverses the list more efficiently by mutating cons cells
;;;
;;;(((reverse"!)))
;;;[source,Scheme,linenums]
;;;----
(define reverse!
  (lambda (l)
    (if (null? l)
        '()
        (let reverse! ((current-cons-cell l)
		       (reversed-list '()))
          (if (null? (cdr current-cons-cell))
              (begin
                (set-cdr! current-cons-cell reversed-list)
                current-cons-cell)
              (let ((rest (cdr current-cons-cell)))
                (set-cdr! current-cons-cell reversed-list)
                (reverse! rest current-cons-cell)))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  reverse!
  '(
    (() ())
    ((1) (1))
    ((2 1) (1 2))
    ((3 2 1) (1 2 3))
    ))
 (let ((x '(1 2 3)))
   (let ((y (reverse! x)))
     (and (equal? y '(3 2 1))
          (equal? x '(1)))))
 )
;;;----
;;;
;;;
;;;
;;;
;;;== Lifting
;;;
;;;From the Haskell wiki footnote:[https://wiki.haskell.org/Lifting]
;;;"lifting is a concept which allows you to transform a function into
;;;a corresponding function within another (usually more general) setting".
;;;
;;;=== string-lift-list
;;;
;;;Strings are sequences of characters, just as lists are
;;;sequences of arbitrary Scheme objects. "string-lift-list"
;;;allows the creation of a context in which strings may
;;;be treated as lists( footnote:[Within libbug, a parameter named
;;;"s" usually means the parameter is of type string.].
;;;
;;;
;;;(((string-lift-list)))
;;;[source,Scheme,linenums]
;;;----
(define string-lift-list
  (lambda (f)
    (lambda (#!rest s)
      (list->string
       (apply f
              (map string->list s))))))
;;;
;;;----
;;;
;;;
;;;
;;;=== string-reverse
;;;
;;;(((string-reverse)))
;;;[source,Scheme,linenums]
;;;----
(define string-reverse
  (string-lift-list reverse!))
;;;
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  string-reverse
  '(
    ("" "")
    ("foo" "oof")
    ("bar" "rab")
    ))
 )
;;;----
;;;
;;;
;;;=== string-take
;;;
;;;(((string-take)))
;;;[source,Scheme,linenums]
;;;----
(define string-take
  (lambda (n s)
    (let ((string-take-n (string-lift-list (lambda (l) (take n l)))))
      (string-take-n s))))
;;;
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (s) (string-take 2 s))
  '(
    ("" "")
    ("foo" "fo")
    ))
 )
;;;----
;;;
;;;=== string-drop
;;;
;;;(((string-drop)))
;;;[source,Scheme,linenums]
;;;----
(define string-drop
  (lambda (n s)
    (let ((string-drop-n (string-lift-list (lambda (l) (drop n l)))))
      (string-drop-n s))))
;;;
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (s) (string-drop 2 s))
  '(
    ("" "")
    ("foo" "o")
    ("foobar" "obar")
    ))
 )
;;;----
;;;
;;;
;;;=== character-lift-integer
;;;
;;;Characters are stored as integer values in computers, but in Scheme
;;;they are not treated as numbers.
;;;"character-lift-integer"
;;;allows the creation of a context in which the characters may
;;;be treated as integers.
;;;
;;;(((character-lift-integer)))
;;;[source,Scheme,linenums]
;;;----
(define character-lift-integer
  (lambda (f)
    (lambda (#!rest c)
      (integer->char
       (apply f
              (map char->integer c))))))
;;;
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (character-lift-integer (lambda (i) (+ i 1)))
  '(
    (#\a #\b)
    (#\b #\c)
    (#\c #\d)
    )))
;;;----
;;;
;;;
;;;=== string-map
;;;
;;;(((string-map)))
;;;[source,Scheme,linenums]
;;;----
(define string-map
  (lambda (f s)
    (let ((string-map-f (string-lift-list (lambda (l) (map f l)))))
      (string-map-f s))))
;;;
;;;----
;;;
;;;
;;;The "Caesar Cipher". <<<crypto>>>.
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (s)
    (string-map (lambda (c) (let ((transform-char
                                   (character-lift-integer
                                    (lambda (base-char c)
                                      (+ base-char
                                         (modulo (+ (- c base-char)
                                                    3)
                                                 26))))))
                              (transform-char #\a c)))
                s))
  '(
    ("" "")
    ("abc" "def")
    ("nop" "qrs")
    ("xyz" "abc")
    ))
 )
;;;----
;;;
;;;
;;;=== symbol-lift-list
;;;
;;;Symbols are sequences of characters, just as lists are
;;;sequences of arbitrary Scheme objects. "symbol-lift-list"
;;;allows the creation of a context in which the symbols may
;;;be treated as lists.
;;;
;;;
;;;(((symbol-lift-list)))
;;;[source,Scheme,linenums]
;;;----
(define symbol-lift-list
  (lambda (f)
    (lambda (#!rest sym)
      (string->symbol
       (apply (string-lift-list f)
              (map symbol->string sym))))))
;;;
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (symbol-lift-list reverse)
  '(
    (foo oof)
    (bar rab)
    ))
 (equal? ((symbol-lift-list append!) 'foo 'bar)
         'foobar)
 )
;;;----
;;;
;;;
;;;== Macros
;;;[[macros]]
;;;
;;;Although many concepts first implemented in Lisp (conditional expressions,
;;;garbage collection, procedures as first-class objects)
;;;have been appropriated into mainstream languages, the one feature of Lisp which
;;;remains difficult for other languages to copy is also Lisp's best:  macros.
;;;A Lisp macro is procedure for application at compile-time which takes unevaluated Lisp
;;;code as a parameter and
;;;transforms it into a new form of unevaluated code before further evaluation.
;;;Essentially, they are a facility
;;;by which a programmer may augment the compiler with new functionality _while
;;;the compiler is compiling_.
;;;
;;;Transforming unevaluated code into new code introduces a few problems of which
;;;the macro writer must be aware.
;;;First, if the macro needs to create a new variable within the expanded code,
;;;the new variable must have a name, which will be generated during macro-expansion.
;;;This new name inserted into the generated code may clash
;;;with a variable name in the input form; resulting in expanded code which does
;;;not function correctly.  Second, if
;;;unevaluated code which causes side-effects is inserted more than once into
;;;the generated code, the expanded code will likely have unintended side-effects
;;;from the caller of the macro's point of view.
;;;
;;;The first problem is solved using "gensym"s.  The second problem is solved
;;;using "once-only".
;;;
;;;For a much fuller explanation of the aforementioned problems, the author
;;;recommends reading
;;;"On Lisp" by Paul Graham <<<onlisp>>>.
;;;
;;;
;;;
;;;=== compose
;;;
;;;(((compose)))
;;;[source,Scheme,linenums]
;;;----
(define-macro compose
  (lambda (#!rest fs)
    (if (null? fs)
        'identity
        (let* ((last-fn-is-lambda-literal
                (and (list? (last fs))
                     (not (null? (last fs)))
                     (equal? 'lambda
                             (car (last fs)))))
               (args (if last-fn-is-lambda-literal
                         (cadr (last fs))
                         (gensym))))
          `(lambda ,(if last-fn-is-lambda-literal
                        args
                        `(#!rest ,args))
             ,(let compose ((fs fs))
                (if (null? (cdr fs))
                    (if last-fn-is-lambda-literal
                        `(begin ,@(cddar fs))
                        `(apply ,(car fs)
                                ,args))
                    `(,(car fs)
                      ,(compose (cdr fs))))))))))
;;;----
;;;
;;;<<<onlisp>>>
;;;
;;;
;;;- On line 1, the "libbug-private#define-macro" macro footnote:[defined in
;;;section  <<libbugdefinemacro>>]
;;;is invoked.  Besides defining the macro, "libbug-private#define-macro"
;;;also exports the
;;;namespace definition and the macro definitions to external files,
;;;for consumption by programs which link against libbug.
;;;
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1 (compose))
         'identity)
 (equal? ((eval (macroexpand-1 (compose))) 5)
         5)
 (equal? ((compose) 5)
         5)
 )
;;;----
;;;
;;;
;;;Macro-expansions occur during compile-time, so how should a programmer
;;;test the resulting form?  Libbug provides "macroexpand-1" which treats the macro
;;;as a procedure which transforms lists into lists, and as such is able
;;;to be tested
;;;footnote:["macroexpand-1" expands the unevaluated code passed to the
;;;macro into a new unevaluated form, which would have been compiled by the compiler
;;;if "macroexpand-1" had been absent.  But, how should "gensym"
;;;evaluate, since by definition it creates symbols which cannot be typed
;;;by the programmer
;;;into a program?  During the expansion of "macroexpand-1", "gensym"
;;;is overridden by a procedure
;;;which expands into typable symbols like "gensymed-var1", "gensymed-var2", etc.  Each
;;;call during a macro-expansion generates a new, unique symbol.  Although the generated symbol
;;;may clash with symbols in the expanded code, this does not break "gensym" for
;;;run-time evaluation, since run-time "gensym" remains not overridden.
;;;Although testing code within libbug "eval"s code generated from "macroexpand-1",
;;;the author advises against doing such in compiled code.
;;;].
;;;
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1 (compose (lambda (x) (* x 2))))
         '(lambda (x) (begin (* x 2))))
 (equal? ((eval (macroexpand-1 (compose (lambda (x) (* x 2)))))
          5)
         10)
 (equal? ((compose (lambda (x) (* x 2)))
          5)
         10)
 )
(unit-test
 (equal? (macroexpand-1 (compose (lambda (x) (+ x 1))
                                 (lambda (y) (* y 2))))
         '(lambda (y)
            ((lambda (x) (+ x 1))
             (begin (* y 2)))))
 (equal? ((compose (lambda (x) (+ x 1))
                   (lambda (y) (* y 2)))
          5)
         11)
 )
(unit-test
 (equal? (macroexpand-1 (compose (lambda (x) (/ x 13))
                                 (lambda (y) (+ y 1))
                                 (lambda (z) (* z 2))))
         '(lambda (z)
            ((lambda (x) (/ x 13))
             ((lambda (y) (+ y 1))
              (begin (* z 2))))))
 (equal? ((compose (lambda (x) (/ x 13))
                   (lambda (y) (+ y 1))
                   (lambda (z) (* z 2)))
          5)
         11/13)
 )
(unit-test
 (equal? (macroexpand-1 (compose not +))
         '(lambda (#!rest gensymed-var1)
            (not (apply + gensymed-var1))))
 (equal? ((compose not +) 1 2)
         #f)
 )
;;;
;;;----
;;;
;;;
;;;=== aif
;;;
;;;(((aif)))
;;;[source,Scheme,linenums]
;;;----
(define-macro aif
  (lambda (bool ifTrue #!rest ifFalse)
    `(let ((bug#it ,bool))
       (if bug#it
           ,ifTrue
           ,@(if (not (null? ifFalse))
                 ifFalse
                 (list #f))))))
;;;----
;;;
;;;Although variable capture <<<onlisp>>> is generally avoided,
;;;there are instances in which variable capture is desirable <<<onlisp>>>.
;;;Within libbug, variables intended for capture are fully qualified with a namespace
;;;to ensure that the variable is captured.
;;;
;;;<<<onlisp>>>
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1 (aif (+ 5 10)
                             (* 2 bug#it)))
         '(let ((bug#it (+ 5 10)))
            (if bug#it
                (* 2 bug#it)
                #f)))
 (equal? (aif (+ 5 10)
              (* 2 bug#it))
         30)
 (equal? (aif #f
              (* 2 bug#it))
         #f)
 (equal? (aif #f
              (* 2 bug#it))
         #f)
 (equal? (macroexpand-1 (aif #f
                             (* 2 bug#it)
                             5))
         '(let ((bug#it #f))
            (if bug#it
                (* 2 bug#it)
                5)))
 (equal? (aif #f
              (* 2 bug#it)
              5)
         5)
 )
;;;----
;;;
;;;
;;;
;;;=== with-gensyms
;;;"with-gensyms" is a macro to be invoked from other macros.  It is a utility
;;;to minimize repetitive calls to "gensym".
;;;
;;;(((with-gensyms)))
;;;[source,Scheme,linenums]
;;;----
(define-macro with-gensyms
  (lambda (symbols #!rest body)
    `(let ,(map (lambda (symbol) `(,symbol (gensym)))
                symbols)
       ,@body)))
;;;----
;;;
;;;<<<onlisp>>>
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1 (with-gensyms (foo bar baz)
                                      `(begin
                                         (pp ,foo)
                                         (pp ,bar)
                                         (pp ,baz))))
         '(let ((foo (gensym))
                (bar (gensym))
                (baz (gensym)))
            `(begin
               (pp ,foo)
               (pp ,bar)
               (pp ,baz))))
 )
;;;----
;;;
;;;
;;;=== once-only
;;;(((once-only)))
;;;
;;;Sometimes macros need to put two or more copies of an argument
;;;into the generated code.
;;;But that can cause that form to be evaluated multiple times,
;;;possibly with side-effects,
;;;which is seldom expected by the caller.
;;;
;;;
;;;[source,Scheme]
;;;----
;;;> (define-macro double (lambda (x) `(+ ,x ,x)))
;;;> (double 5)
;;;10
;;;----
;;;
;;;The caller of "double" should reasonably expect the argument to "double"
;;;only to be evaluated once only, because that's how Scheme usually works.
;;;
;;;[source,Scheme]
;;;----
;;;> (define foo 5)
;;;> (double (begin (set! foo (+ foo 1))
;;;                foo))
;;;13
;;;----
;;;
;;;"once-only" allows a macro-writer to ensure that a variable is evaluated
;;;only once in the generated code.
;;;
;;;[source,Scheme]
;;;----
;;;> (define-macro double (lambda (x) (once-only (x) `(+ ,x ,x))))
;;;> (define foo 5)
;;;> (double (begin (set! foo (+ foo 1))
;;;                foo))
;;;12
;;;----
;;;
;;;
;;;Like "with-gensyms", "once-only" is a macro to be used by other macros.  Code
;;;which generates code which generates code.  Unlike
;;;"with-gensyms", which wraps its argument with a new context to be used for
;;;later macro-expansions, "once-only" needs to defer binding the variable to a
;;;"gensym"-ed variable until the second macro-expansion.  As such, it is the
;;;most difficult macro is this book.
;;;
;;;[source,Scheme,linenums]
;;;----
(define-macro once-only
  (lambda (symbols #!rest body)
    (let ((gensyms (map (lambda (s) (gensym))
                        symbols)))
      `(list 'let
             (append ,@(map (lambda (g s) `(if (atom? ,s)
                                               '()
                                               (list (list (quote ,g)
                                                           ,s))))
                            gensyms
                            symbols))
             ,(append (list 'let
                            (map (lambda (s g) (list s
                                                     `(if (atom? ,s)
                                                          ,s
                                                          (quote ,g))))
                                 symbols
                                 gensyms))
                      body)))))
;;;----
;;;
;;;<<<paip>>>
;;;
;;;"atom"s are handled as a special case to minimize the creation
;;;of "gensym"ed variables since evaluation of "atom"s
;;;causes no side effects, thus causes no problems from multiple evaluation.
;;;
;;;==== First Macro-expansion
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1 (once-only (x y) `(+ ,x ,y ,x)))
         `(list 'let
                (append (if (atom? x)
                            '()
                            (list (list 'gensymed-var1 x)))
                        (if (atom? y)
                            '()
                            (list (list 'gensymed-var2 y))))
                (let ((x (if (atom? x)
                             x
                             'gensymed-var1))
                      (y (if (atom? y)
                             y
                             'gensymed-var2)))
                  `(+ ,x ,y ,x)))))
;;;----
;;;
;;;
;;;==== The Second Macro-expansion
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (eval `(let ((x 5)
                      (y 6))
                  ,(macroexpand-1
                    (once-only (x y)
                               `(+ ,x ,y ,x)))))
         `(let () (+ 5 6 5)))
 (equal? (eval `(let ((x '(car foo))
                      (y 6))
                  ,(macroexpand-1
                    (once-only (x y)
                               `(+ ,x ,y ,x)))))
         '(let ((gensymed-var1 (car foo)))
            (+ gensymed-var1 6 gensymed-var1)))
 (equal? (eval `(let ((x '(car foo))
                      (y '(baz)))
                  ,(macroexpand-1
                    (once-only (x y)
                               `(+ ,x ,y ,x)))))
         '(let ((gensymed-var1 (car foo))
                (gensymed-var2 (baz)))
            (+ gensymed-var1 gensymed-var2 gensymed-var1)))
 )

;;;----
;;;
;;;
;;;==== The Evaluation of the twice-expanded Code
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (eval (eval `(let ((x 5)
                            (y 6))
                        ,(macroexpand-1
                          (once-only (x y)
                                     `(+ ,x ,y ,x))))))
         16)
 )
;;;----
;;;
;;;
;;;
;;;
;;;== Generalized Assignment
;;;
;;[[endinglibbug]]
;;;
;;;=== setf!
;;;"Rather than thinking about two distinct functions that respectively
;;;access and update a storage location somehow deduced from their arguments,
;;;we can instead simply think of a call to the access function with given
;;;arguments as a _name_ for the storage location." <<<cl>>>
;;;
;;;Create a macro named "setf!" which invokes the appropriate
;;;"setting" procedure, based on the given "accessing" procedure footnote:[The
;;;implementation is inspired by <<<setf>>>.].
;;;
;;;(((setf"!)))
;;;[source,Scheme,linenums]
;;;----
(define-macro setf!
  (lambda (exp val)
    (if (not (pair? exp))
        `(set! ,exp ,val)
        (case (car exp)
          ((car)  `(set-car! ,@(cdr exp) ,val))
          ((cdr)  `(set-cdr! ,@(cdr exp) ,val))
          ((caar) `(setf! (car (car ,@(cdr exp))) ,val))
          ((cadr) `(setf! (car (cdr ,@(cdr exp))) ,val))
          ((cdar) `(setf! (cdr (car ,@(cdr exp))) ,val))
          ((cddr) `(setf! (cdr (cdr ,@(cdr exp))) ,val))
          ((caaar) `(setf! (car (caar ,@(cdr exp))) ,val))
          ((caadr) `(setf! (car (cadr ,@(cdr exp))) ,val))
          ((cadar) `(setf! (car (cdar ,@(cdr exp))) ,val))
          ((caddr) `(setf! (car (cddr ,@(cdr exp))) ,val))
          ((cdaar) `(setf! (cdr (caar ,@(cdr exp))) ,val))
          ((cdadr) `(setf! (cdr (cadr ,@(cdr exp))) ,val))
          ((cddar) `(setf! (cdr (cdar ,@(cdr exp))) ,val))
          ((cdddr) `(setf! (cdr (cddr ,@(cdr exp))) ,val))
          ((caaaar) `(setf! (car (caaar ,@(cdr exp))) ,val))
          ((caaadr) `(setf! (car (caadr ,@(cdr exp))) ,val))
          ((caadar) `(setf! (car (cadar ,@(cdr exp))) ,val))
          ((caaddr) `(setf! (car (caddr ,@(cdr exp))) ,val))
          ((cadaar) `(setf! (car (cdaar ,@(cdr exp))) ,val))
          ((cadadr) `(setf! (car (cdadr ,@(cdr exp))) ,val))
          ((caddar) `(setf! (car (cddar ,@(cdr exp))) ,val))
          ((cadddr) `(setf! (car (cdddr ,@(cdr exp))) ,val))
          ((cdaaar) `(setf! (cdr (caaar ,@(cdr exp))) ,val))
          ((cdaadr) `(setf! (cdr (caadr ,@(cdr exp))) ,val))
          ((cdadar) `(setf! (cdr (cadar ,@(cdr exp))) ,val))
          ((cdaddr) `(setf! (cdr (caddr ,@(cdr exp))) ,val))
          ((cddaar) `(setf! (cdr (cdaar ,@(cdr exp))) ,val))
          ((cddadr) `(setf! (cdr (cdadr ,@(cdr exp))) ,val))
          ((cdddar) `(setf! (cdr (cddar ,@(cdr exp))) ,val))
          ((cddddr) `(setf! (cdr (cdddr ,@(cdr exp))) ,val))
          (else `(,(let ((append-set!
                          (symbol-lift-list
                           (lambda (l -set! -ref)
                             (append!
                              (if (equal? (reverse -ref)
                                          (take 4 (reverse l)))
                                  (reverse (drop 4
                                                 (reverse l)))
                                  l)
                              -set!)))))
                     (append-set! (car exp)
                                  '-set!
                                  '-ref))
                  ,@(cdr exp)
                  ,val))))))
;;;----
;;;
;;;==== Updating a Variable Directly
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1
          (setf! foo 10))
         '(set! foo 10))
 (let ((a 5))
   (setf! a 10)
   (equal? a 10))
 )
;;;----
;;;
;;;===== Updating Car, Cdr, ... Through Cddddr
;;;Test updating "car".
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1
          (setf! (car foo) 10))
         '(set-car! foo 10))
 (let ((foo '(1 2)))
   (setf! (car foo) 10)
   (equal? (car foo) 10))
 )
;;;----
;;;
;;;Test updating "cdr".
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1
          (setf! (cdr foo) 10))
         '(set-cdr! foo 10))
 (let ((foo '(1 2)))
   (setf! (cdr foo) 10)
   (equal? (cdr foo) 10))
 (let ((foo '(bar baz quux)))
   (setf! (list-ref foo 2) 'blah)
   (equal? foo '(bar baz blah)))
 )
;;;----
;;;
;;;Testing all of the "car" through "cddddr" procedures would
;;;be quite
;;;repetitive.  Instead, create a list which has an element at each of those
;;;accessor procedures, and test each.
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (eval
  `(and
    ,@(map (lambda (x) `(let ((foo '((((the-caaaar)
                                       the-cadaar)
                                      (the-caadar)
                                      ())
                                     ((the-caaadr) the-cadadr)
                                     (the-caaddr)
                                     ()
                                     )))
                          (setf! (,x foo) 10)
                          (equal? (,x foo) 10)))
           '(car
             cdr
             caar cadr
             cdar cddr
             caaar caadr cadar caddr
             cdaar cdadr cddar cdddr
             caaaar caaadr caadar caaddr
             cadaar cadadr caddar cadddr
             cdaaar cdaadr cdadar cdaddr
             cddaar cddadr cdddar cddddr
             ))))
 )
;;;----
;;;
;;;===== Suffixed By -set!
;;;Test updating procedures where the updating procedure is
;;;the name of the getting procedure, suffixed by '-set!'.
;;;
;;;[source,Scheme,linenums]
;;;----
(at-compile-time
 (##define-structure foo bar))

(unit-test
 (equal? (macroexpand-1
          (setf! (foo-bar f) 10))
         '(foo-bar-set! f 10))
 (begin
   (let ((f (make-foo 1)))
     (setf! (foo-bar f) 10)
     (equal? (make-foo 10)
             f)))
 )
;;;----
;;;
;;;
;;;
;;;===== -ref Replaced By -set!
;;;Test updating procedures where the updating procedure is
;;;the name of the getting procedure, with the "-ref" suffix removed, replaced
;;;with "-set".
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1
          (setf! (string-ref s 0) #\q))
         '(string-set! s 0 #\q))
 (let ((s "foobar"))
   (setf! (string-ref s 0) #\q)
   (equal? s "qoobar"))
 (equal? (macroexpand-1
          (setf! (vector-ref v 2) 4))
         '(vector-set! v 2 4))
 (let ((v (vector 1 2 '() "")))
   (setf! (vector-ref v 2) 4)
   (equal? v
           (vector 1 2 4 "")))
 )
;;;----
;;;
;;;
;;;=== mutate!
;;;Like "setf!", "mutate!" takes a generalized variable
;;;as input, but it additionally takes a procedure to be applied
;;;to the value of the generalized variable; the result of the application
;;;will be stored back into the generalized variable footnote:["mutate!" is
;;;used in similar contexts as Common Lisp's
;;;"define-modify-macro" would be, but it is more general, as
;;;it allows the new procedure to remain anonymous, as compared
;;;to making a new name like "toggle" <<<onlisp>>>.].
;;;
;;;(((mutate"!)))
;;;[source,Scheme,linenums]
;;;----
(define-macro mutate!
  (lambda (exp f)
    (if (symbol? exp)
        `(setf! ,exp (,f ,exp))
        (let* ((atom-or-binding (map (lambda (x) (if (atom? x)
					             x
					             (list (gensym) x)))
				     (cdr exp)))
               (args-of-generalized-var (map (lambda (x) (if (atom? x)
                                                             x
                                                             (car x)))
                                             atom-or-binding)))
          `(let ,(filter (complement atom?) atom-or-binding)
             (setf! (,(car exp) ,@args-of-generalized-var)
                    (,f (,(car exp) ,@args-of-generalized-var))))))))
;;;----
;;;
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1 (mutate! foo not))
         '(setf! foo (not foo)))
 (let ((foo #t))
   (and
    (begin
      (mutate! foo not)
      (equal? foo #f))
    (begin
      (mutate! foo not)
      (equal? foo #t))))
 )
;;;----
;;;
;;;
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1 (mutate! (vector-ref foo 0) (lambda (n) (+ n 1))))
         '(let ()
            (setf! (vector-ref foo 0)
                   ((lambda (n) (+ n 1)) (vector-ref foo 0)))))
 (let ((foo (vector 0 0 0)))
   (mutate! (vector-ref foo 0) (lambda (n) (+ n 1)))
   (equal? foo
           (vector 1 0 0)))
 (let ((foo (vector 0 0 0)))
   (mutate! (vector-ref foo 2) (lambda (n) (+ n 1)))
   (equal? foo
           (vector 0 0 1)))
 )
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1
          (mutate! (vector-ref foo (begin
                                     (setf! index (+ 1 index))
                                     index))
                   (lambda (n) (+ n 1))))
         '(let ((gensymed-var1 (begin
                                 (setf! index (+ 1 index))
                                 index)))
            (setf! (vector-ref foo gensymed-var1)
                   ((lambda (n) (+ n 1)) (vector-ref foo gensymed-var1)))))
 (let ((foo (vector 0 0 0))
       (index 1))
   (mutate! (vector-ref foo (begin
                              (setf! index (+ 1 index))
                              index))
            (lambda (n) (+ n 1)))
   (and (equal? foo
                (vector 0 0 1))
        (equal? index
                2)))
 )
;;;----
;;;
;;;
;;;
;;;=== destructuring-bind
;;;
;;;[[dbind]]
;;;(((destructuring-bind)))
;;;
;;;"destructuring-bind" is a generalization of "let", in which multiple variables
;;;may be bound to values based on their positions within a (possibly nested) list.
;;;Look at the tests
;;;at the end of the section for an example.
;;;
;;;"destructuring-bind" is a complicated macro which can be decomposed into a regular
;;;procedure named "tree-of-accessors", and the macro "destructuring-bind"
;;;footnote:[This poses a small problem.  "tree-of-accessors" is not macroexpanded as it a not a
;;;macro, therefore it does not have access to the compile-time "gensym" procedure
;;;which allows macro-expansions to be tested.  To allow "tree-of-accessors" to
;;;be tested independently, as well as part of "destructuring-bind", "tree-of-accessors"
;;;takes a procedure named "gensym" as an argument, defaulting to whatever value
;;;"gensym" is by default in the environment.].
;;;
;;;[source,Scheme,linenums]
;;;----
(define tree-of-accessors
  (lambda (pat lst #!key (gensym gensym) (n 0))
    (let tree-of-accessors ((pat pat)
                            (lst lst)
                            (n n))
      (cond ((null? pat)                '())
            ((symbol? pat)              `((,pat (drop ,n ,lst))))
            ((equal? (car pat) '#!rest) `((,(cadr pat) (drop ,n
                                                             ,lst))))
            (else
             (cons (let ((p (car pat)))
                     (if (symbol? p)
                         `(,p (list-ref ,lst ,n))
                         (let ((var (gensym)))
                           (cons `(,var (list-ref ,lst ,n))
                                 (tree-of-accessors p
                                                    var
                                                    0)))))
                   (tree-of-accessors (cdr pat)
                                      lst
                                      (+ 1 n))))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (tree-of-accessors '() 'gensym-for-list)
         '())
 (equal? (tree-of-accessors 'a 'gensym-for-list)
         '((a (drop 0 gensym-for-list))))
 (equal? (tree-of-accessors '(#!rest d) 'gensym-for-list)
         '((d (drop 0 gensym-for-list))))
 (equal? (tree-of-accessors '(a) 'gensym-for-list)
         '((a (list-ref gensym-for-list 0))))
 (equal? (tree-of-accessors '(a . b) 'gensym-for-list)
         '((a (list-ref gensym-for-list 0))
           (b (drop 1 gensym-for-list))))
 )
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (tree-of-accessors '(a (b c))
                            'gensym-for-list
                            gensym: (lambda () 'gensymed-var1))
         '((a (list-ref gensym-for-list 0))
           ((gensymed-var1 (list-ref gensym-for-list 1))
            (b (list-ref gensymed-var1 0))
            (c (list-ref gensymed-var1 1)))))
 )
;;;----
;;;
;;;
;;;Although a call to "tree-of-accessors" by a macro could be a victim
;;;of the multiple-evaluation
;;;problem that macros may have, the only caller of "tree-of-accessors" is
;;;"destructuring-bind", which passes
;;;a "gensymed" symbol to "tree-of-accessors".  Therefore "destructuring-bind" does not
;;;fall victim to unintended multiple evaluations footnote:[Although the author would like to inline
;;;"tree-of-accessors" into the definition of "destructuring-bind", thus making it safe,
;;;he could not determine how to write tests for a nested definition.].
;;;
;;;[source,Scheme,linenums]
;;;----
(define-macro destructuring-bind
  (lambda (pat lst #!rest body)
    (let ((glst (gensym)))
      `(let ((,glst ,lst))
         ,(let create-nested-lets ((bindings
                                    (tree-of-accessors pat
                                                       glst
                                                       gensym: gensym)))
            (if (null? bindings)
                `(begin ,@body)
                `(let ,(map (lambda (b) (if (pair? (car b))
                                            (car b)
                                            b))
                            bindings)
                   ,(create-nested-lets (flatmap (lambda (b) (if (pair? (car b))
                                                                 (cdr b)
                                                                 '()))
                                                 bindings)))))))))
;;;----
;;;
;;;<<<onlisp>>>
;;;
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (macroexpand-1
          (destructuring-bind (a (b . c) #!rest d)
                              '(1 (2 3) 4 5)
                              (list a b c d)))
         '(let ((gensymed-var1 '(1 (2 3) 4 5)))
            (let ((a (list-ref gensymed-var1 0))
                  (gensymed-var2 (list-ref gensymed-var1 1))
                  (d (drop 2 gensymed-var1)))
              (let ((b (list-ref gensymed-var2 0))
                    (c (drop 1 gensymed-var2)))
                (begin (list a b c d))))))
 (equal? (destructuring-bind (a (b . c) #!rest d)
                             '(1 (2 3) 4 5)
                             (list a b c d))
         '(1 2 (3) (4 5)))
 (equal? (destructuring-bind (trueList falseList)
                             (partition '(3 2 5 4 1)
                                        (lambda (x) (<= x 3)))
                             trueList)
         '(1 2 3))
 (equal? (destructuring-bind (trueList falseList)
                             (partition '(3 2 5 4 1)
                                        (lambda (x) (<= x 3)))
                             falseList)
         '(4 5))
 )
;;;----
;;;

;;;== Coroutines

;;;https://en.wikipedia.org/wiki/Coroutine

;;;https://en.wikipedia.org/wiki/Generator_(computer_science)

;;;=== end-of-generator

;;;[source,Scheme,linenums]
;;;----
(define end-of-generator
  (lambda ()
    'end-of-generator))
;;;----

;;;=== end-of-generator?

;;;[source,Scheme,linenums]
;;;----
(define end-of-generator?
  (lambda (x) (equal? x (end-of-generator))))
;;;----

;;;=== \_\_make-generator\_\_

;;;[source,Scheme,linenums]
;;;----
(define __make-generator__
  ;; f is a function which takes one argument, the yield procedure,
  ;; which this procedure, __make-generator__, provides
  (lambda (f)
    ;; each instance of a generator needs two continuations.
    ;; one for the generator instance, and one for the callee
    ;; of the generator instance.

    ;; so the definition of yield needs to have references
    ;; to each of those continuations.
    ;; create reference to them in  yield's environment
    ;; even though they will not be bound to useful values
    ;; until after yield is defined.
    (##define return-to-callee-continuation 'ignore)
    (##define continue-with-generator-continuation 'ignore)

    ;; define the implementation "yield" for this generator
    (##define yield-defined-for-this-generator-instance
      ;; when yield is appied within the generator, it must
      ;; return the value to the callee, but must also remember
      ;; where to resume the next time the generator is applied.
      ;;
      ;; though, just like parameter passing in machine code,
      ;; in which values must be passed on the stack/registers
      ;; before control is transferred from the caller to the callee,
      ;; the continuation of the generator must first be captured before
      ;; invoking the callee's continuation with the yielded value.
      (lambda (value-to-be-yielded)
        (call/cc (lambda (yields-continuation)
                   (setf! continue-with-generator-continuation yields-continuation)
                   (return-to-callee-continuation value-to-be-yielded)))))


    (set! continue-with-generator-continuation
          (lambda (#!rest send)
            ;; switch back and forth between the two routines
            (f yield-defined-for-this-generator-instance)
            ;; all instances of yield have been called, inform the callee
            ;; that the generator is done
            (return-to-callee-continuation (end-of-generator))))
    ;; this is the code that is invoked every time the generator is applied.
    ;; if the yield expression is defined in a context in which the evaluation
    ;; of yield must evaluate to a value, then pass that value to "send".
    (lambda (#!rest send)
      ;; get the callee's continuation, for use when "yield" is applied
      ;; within the generator
      (call/cc (lambda (callees-continuation)
                 ;; set the callee's continuation into "yield"'s enviroment,
                 ;; so that it may be called from within yield.
                 (setf! return-to-callee-continuation callees-continuation)
                 ;; evaluate f up until the point that yield is invoked.

                 ;; when that occurs, both return-to-callee-continuation
                 ;; and continue-with-generator-continuation will be
                 ;; defined correctly.
                 (apply continue-with-generator-continuation send))))))
;;;----


;;;[source,Scheme,linenums]
;;;----
(unit-test
 (let ((g (__make-generator__
           (lambda (yield)
               (yield 'yield-value-one)
               (yield 'yield-value-two)
               (yield 'yield-value-three)))))
   (and (equal? 'yield-value-one (g))
        (equal? 'yield-value-two (g))
        (equal? 'yield-value-three (g))
        (end-of-generator? (g)))))
;;;----

;;;Yield may be used in a context in which a value is expected.  Unlike
;;;Python, which distinguishes between these two cases by using either
;;;"next" or "send", in this library, the generator is just a regular
;;;procedure which takes 0 or 1 parameters.

;;;[source,Scheme,linenums]
;;;----
(unit-test
 (let ((g (__make-generator__
           (lambda (yield)
             (let ((time 0))
               (setf! time (+ time (yield 'yield-value-one)))
               (yield 'yield-value-two)
               (setf! time (+ time (yield 'yield-value-three)))
               (yield time))))))
   (and (equal? 'yield-value-one (g)) ;; just like python, nothing to send on first use
        (equal? 'yield-value-two (g 10)) ;; send 10 to be the value of "(yield 'yield-value-one)"
        (equal? 'yield-value-three (g)) ;;
        (equal? 20 (g 10)) ;; send 10 to be the value of "(yield 'yield-value-three)"
        (end-of-generator? (g))))) ;; end of the generator
 ;; the generators are independent
 (let ((g (__make-generator__
           (lambda (yield)
             (let ((time 0))
               (setf! time (+ time (yield 'yield-value-one)))
               (yield 'yield-value-two)
               (setf! time (+ time (yield 'yield-value-three)))
               (yield time)))))
       (g2 (__make-generator__
            (lambda (yield)
              (let ((time 0))
                (setf! time (+ time (yield 'one)))
                (yield 'two)
                (setf! time (+ time (yield 'three)))
                (yield time))))))
   (and (equal? 'yield-value-one (g))
        (equal? 'one (g2))
        (equal? 'yield-value-two (g 10))
        (equal? 'two (g2 1))
        (equal? 'yield-value-three (g))
        (equal? 'three (g2))
        (equal? 20 (g 10))
        (equal? 2 (g2 1))
        (end-of-generator? (g))
        (end-of-generator? (g2))
        ))
;;;----


;;;=== generator
;;;[source,Scheme,linenums]
;;;----
(define-macro generator
  (lambda (#!rest body)
    `(__make-generator__
      (lambda (yield)
        ,@body))))
;;;----


;;;[source,Scheme,linenums]
;;;----
(unit-test
 (begin
   (let ((g (generator
             (let ((time 0))
               (setf! time (+ time (yield 'yield-value-one)))
               (setf! time (+ time (yield 'yield-value-two)))
               (setf! time (+ time (yield 'yield-value-three)))
               (yield time)))))
     (and (equal? 'yield-value-one (g)) ;; just like python, nothing to send on first use
          (equal? 'yield-value-two (g 10)) ;; send 10 to be the value of "(yield 'yield-value-one)"
          (equal? 'yield-value-three (g 10)) ;; send 10 to be the value of "(yield 'yield-value-two)"
          (equal? 30 (g 10)) ;; send 10 to be the value of "(yield 'yield-value-three)"
          (end-of-generator? (g 10)) ;; end of the generator)
          ))))
;;;----


;;;=== yield-from
;;;[source,Scheme,linenums]
;;;----
(define-macro yield-from
  (lambda (g)
    (with-gensyms
     (v loop)
     `(let ,loop ((,v (,g)))
           (if (not (end-of-generator? ,v))
                 (,loop (,g (yield ,v)))
                'noop)))))
;;;----


;;;[source,Scheme,linenums]
;;;----
(unit-test
 (begin
   (let* ((g (generator
               (yield 1)
               (yield 2)
               (yield 3)))
          (g2 (generator
               (yield 'a)
               (yield 'b)
               (yield 'c)))
          (g3 (generator
               (yield-from g)
               (yield-from g2))))
     (and (equal? 1 (g3))
          (equal? 2 (g3))
          (equal? 3 (g3))
          (equal? 'a (g3))
          (equal? 'b (g3))
          (equal? 'c (g3))
          (end-of-generator? (g3))
          )))
 (begin
   (let* ((g (generator
              (yield (+ 3 (yield (+ 2 (yield 1)))))))
          (g2 (generator
               (yield (+ 6 (yield (+ 5 (yield 4)))))))
          (g3 (generator
               (yield-from g)
               (yield-from g2))))
     (and (equal? 1 (g3))
          (equal? 3 (g3 1))
          (equal? 6 (g3 3))
          (equal? 4 (g3))
          (equal? 9 (g3 4))
          (equal? 15 (g3 9))
          (end-of-generator? (g2))
          ))))
;;;----

;;;=== list->stream
;;;Converts a list into a stream.
;;;
;;;(((list->stream)))
;;;[source,Scheme,linenums]
;;;----
(define list->stream
  (lambda (l)
    (generator
     (let loop ((l l))
       (if (not (null? l))
           (begin
             (yield (car l))
             (loop (cdr l)))
           'noop)))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
   (let ((g (list->stream '(1 2 3))))
     (and (equal? 1 (g))
          (equal? 2 (g))
          (equal? 3 (g))
          (end-of-generator? (g)))))
;;;----
;;;
;;;
;;;=== stream->list
;;;Converts a stream into a list.
;;;
;;;(((stream->list)))
;;;[source,Scheme,linenums]
;;;----
(define stream->list
  (lambda (s)
    (let ((next (s)))
      (if (end-of-generator? next)
          '()
          (cons next (stream->list s))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (stream->list
          (list->stream '(1 2 3)))
         '(1 2 3))
 )
;;;----

;;;=== integers-from
;;;(((integers-from)))
;;;
;;;Creates an infinite footnote:[bounded by memory constraints of course. Scheme
;;;isn't a Turing machine.] stream of integers.
;;;
;;;[source,Scheme,linenums]
;;;----
(define integers-from
  (lambda (n)
    (generator
     (let loop ((n n))
       (yield n)
       (loop (+ n 1))))))
;;;----
;;;
;;;<<<sicp>>>.
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (and
   (let ((g (integers-from 0)))
     (and (equal? 0 (g))
          (equal? 1 (g))
          (equal? 2 (g))
          (equal? 3 (g))))
   (let ((g (integers-from 5)))
     (and (equal? 5 (g))
          (equal? 6 (g))
          (equal? 7 (g))
          (equal? 8 (g))))))
;;;----
;;;
;;;
;;;=== stream-map
;;;The analogous procedure of "map".
;;;
;;;(((stream-map)))
;;;[source,Scheme,linenums]
;;;----
(define stream-map
  (lambda (f #!rest list-of-streams)
    (generator
     (let stream-map ()
       (let ((the-values (map (lambda (g) (apply g '()))
                              list-of-streams)))
         (if (any? (map end-of-generator? the-values))
             (end-of-generator)
             (begin
               (yield (apply f the-values))
               (stream-map))))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (stream->list
          (stream-map (lambda (x) (+ x 1))
                      (list->stream '(1 2 3 4 5))))
         '(2 3 4 5 6))
 (equal? (stream->list
          (stream-map (lambda (x y) (+ x y))
                      (list->stream '(1 2 3 4 5))
                      (list->stream '(1 1 1 1 1))))
         '(2 3 4 5 6))
 )
;;;
;;;----
;;;=== stream-filter
;;;The analogous procedure of filter.
;;;
;;;(((stream-filter)))
;;;[source,Scheme,linenums]
;;;----
(define stream-filter
  (lambda (p? s)
    (generator
     (let stream-filter ()
       (let ((the-value (s)))
         (if (end-of-generator? the-value)
             (end-of-generator)
             (begin
               (if (p? the-value)
                   (yield the-value)
                   'noop)
               (stream-filter))))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal?  (stream->list
           (stream-filter (lambda (x) (not (= 4 x)))
                          (list->stream '(1 4 2 4))))
          '(1 2))
 )
;;;----

;;;=== stream-take
;;;(((stream-take)))
;;;[source,Scheme,linenums]
;;;----
(define stream-take
  (lambda (n s)
    (generator
     (let stream-take ((n n))
       (let ((the-value (s)))
         (if (or (end-of-generator? the-value)
                 (<= n 0))
             (end-of-generator)
             (begin
               (yield the-value)
               (stream-take (- n 1)))))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (n) (stream->list
               (stream-take n (integers-from 0))))
  '(
    (0 ())
    (1 (0))
    (2 (0 1))
    (6 (0 1 2 3 4 5))
    )))
;;;----
;;;
;;;
;;;
;;;=== primes
;;;(((primes)))
;;;[source,Scheme,linenums]
;;;----
(define primes
  (lambda ()
    (generator
     (let sieve-of-eratosthenes ((s (integers-from 2)))
       (let ((prime (s)))
         (yield prime)
         (yield-from (sieve-of-eratosthenes
                      (stream-filter (lambda (n)
                                       (not (equal? 0
                                                    (modulo n prime))))
                                     s))))))))
;;;----
;;;
;;;<<<sicp>>>.
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (stream->list
          (stream-take
           10
           (primes)))
         '(2 3 5 7 11 13 17 19 23 29))
 )
;;;----
;;;
;;;=== stream-drop
;;;(((stream-drop)))
;;;[source,Scheme,linenums]
;;;----
(define stream-drop
  (lambda (n s)
    (let stream-drop ((n n))
      (if (<= n 0)
          s
          (begin
            (s)
            (stream-drop (- n 1)))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (n)
    (stream->list
     (stream-drop n (list->stream '(a b)))))
  '(
    (-1 (a b))
    (0 (a b))
    (1 (b))
    (2 ())
    (3 ())
    ))
 (equal? (stream->list
          (stream-take 10 (stream-drop 10
                                       (primes))))
         '(31 37 41 43 47 53 59 61 67 71))
 )
;;;----

;;;=== stream-drop-while
;;;(((stream-drop-while)))
;;;[source,Scheme,linenums]
;;;----
(define stream-drop-while
  (lambda (p? s)
    (let ((not-p? (complement p?)))
      (generator
       (let stream-drop-while ()
         (let ((the-value (s)))
           (if (or (end-of-generator? the-value)
                   (not-p? the-value))
               (begin
                 (yield the-value)
                 (yield-from s))
               (stream-drop-while))))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (x)
    (stream->list
     (stream-drop-while (lambda (y) (not (equal? x y)))
                        (list->stream
                         '(a b c)))))
  '(
    (a (a b c))
    (b (b c))
    (c (c))
    (d ())
    (e ())
    )))
;;;----
;;;

;;;=== stream-enumerate-interval
;;;(((stream-enumerate-interval)))
;;;[source,Scheme,linenums]
;;;----
(define stream-enumerate-interval
  (lambda (low high #!key (step 1))
    (generator
     (let stream-enumerate-interval ((low low))
       (if (> low high)
           (end-of-generator)
           (begin
             (yield low)
             (stream-enumerate-interval (+ low step))))))))
;;;----
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (equal? (stream->list
          (stream-enumerate-interval 1 10))
         '(1 2 3 4 5 6 7 8 9 10))
 (equal? (stream->list
          (stream-enumerate-interval 1 10 step: 2))
         '(1 3 5 7 9)))
;;;----
;;;

;;;
;;;=== stream-take-while
;;;(((stream-take-while)))
;;;[source,Scheme,linenums]
;;;----
(define stream-take-while
  (lambda (p? s)
    (let ((not-p? (complement p?)))
      (generator
       (let stream-take-while ()
         (let ((the-value (s)))
           (if (or (end-of-generator? the-value)
                   (not-p? the-value))
               (end-of-generator)
               (begin
                 (yield the-value)
                 (stream-take-while)))))))))
;;;----
;;;
;;;
;;;[source,Scheme,linenums]
;;;----
(unit-test
 (satisfies?
  (lambda (s)
    (stream->list
     (stream-take-while (lambda (n) (< n 10))
                        s)))
  `((,(integers-from 0)               (0 1 2 3 4 5 6 7 8 9))
    (,(stream-enumerate-interval 1 4) (1 2 3 4))))
 )
;;;----


;;;
;;;=== The End of Compilation
;;;
;;;
;;;At the beginning of the book, in chapter <<beginninglibbug>>, "bug-language.scm"
;;;was imported, so that "libbug-private#define", and "libbug-private#define-macro" could be used.
;;;This chapter is the end of the file "main.bug.scm".  However, as will be shown
;;;in the next chapter, "bug-languge.scm" opened files for writing during compile-time,
;;;and they must be closed, accomplished by executing "at-end-of-compilation".
;;;
;;[[call-end-of-compilation
;;;[source,Scheme,linenums]
;;;----
(at-compile-time
 (at-end-of-compilation))
;;;----
;;;
;;;
;;;
