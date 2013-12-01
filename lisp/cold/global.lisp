;;; These are the atoms which belong in the GLOBAL package in the lisp machine.
;;; ** (c) Copyright 1980 Massachusetts Institute of Technology **

;;; EACH SYMBOL NAME MUST BE PRECEDED BY A SPACE!!!

;;; Useful byte-pointers and constants:

 %ARG-DESC-QUOTED-REST
 %%ARG-DESC-QUOTED-REST
 %ARG-DESC-EVALED-REST
 %%ARG-DESC-EVALED-REST
 %ARG-DESC-FEF-QUOTE-HAIR
 %%ARG-DESC-FEF-QUOTE-HAIR
 %ARG-DESC-INTERPRETED
 %%ARG-DESC-INTERPRETED
 %ARG-DESC-FEF-BIND-HAIR
 %%ARG-DESC-FEF-BIND-HAIR
 %%ARG-DESC-MIN-ARGS
 %%ARG-DESC-MAX-ARGS
 %%CH-CHAR
 %%CH-FONT
 %%KBD-CHAR
 %%KBD-CONTROL
 %%KBD-CONTROL-META
 %%KBD-HYPER
 %%KBD-META
 %%KBD-MOUSE
 %%KBD-MOUSE-BUTTON
 %%KBD-MOUSE-N-CLICKS
 %%KBD-SUPER
 %%Q-ALL-BUT-CDR-CODE
 %%Q-ALL-BUT-POINTER
 %%Q-ALL-BUT-TYPED-POINTER
 %%Q-CDR-CODE
 %%Q-DATA-TYPE
 %%Q-FLAG-BIT
 %%Q-HIGH-HALF
 %%Q-LOW-HALF
 %%Q-POINTER
 %%Q-POINTER-WITHIN-PAGE
 %%Q-TYPED-POINTER

;;; Useful unsafe and machine-dependent functions:

 %24-BIT-DIFFERENCE
 %24-BIT-PLUS
 %24-BIT-TIMES
 %ACTIVATE-OPEN-CALL-BLOCK
 %ALLOCATE-AND-INITIALIZE
 %ALLOCATE-AND-INITIALIZE-ARRAY
 %AREA-NUMBER
 %ARGS-INFO
 %ASSURE-PDL-ROOM
 %DATA-TYPE
 %DIVIDE-DOUBLE
 %FIND-STRUCTURE-HEADER
 %FIND-STRUCTURE-LEADER
 %FLOAT-DOUBLE
 %LOGDPB
 %LOGLDB 
 %MAKE-POINTER
 %MAKE-POINTER-OFFSET
 %MAR-HIGH
 %MAR-LOW
 %METHOD-CLASS
 %MICROCODE-VERSION-NUMBER
 %MULTIPLY-FRACTIONS
 %OPEN-CALL-BLOCK 
 %P-CDR-CODE
 %P-CONTENTS-AS-LOCATIVE
 %P-CONTENTS-AS-LOCATIVE-OFFSET
 %P-CONTENTS-OFFSET
 %P-DATA-TYPE
 %P-DEPOSIT-FIELD
 %P-DEPOSIT-FIELD-OFFSET
 %P-DPB
 %P-DPB-OFFSET
 %P-FLAG-BIT
 %P-LDB
 %P-LDB-OFFSET
 %P-MASK-FIELD
 %P-MASK-FIELD-OFFSET
 %P-POINTER
 %P-STORE-CDR-CODE
 %P-STORE-CONTENTS
 %P-STORE-CONTENTS-OFFSET
 %P-STORE-DATA-TYPE
 %P-STORE-FLAG-BIT
 %P-STORE-POINTER
 %P-STORE-TAG-AND-POINTER
 %POINTER
 %POINTER-DIFFERENCE
 %POP
 %PUSH
 %REGION-NUMBER
 %REMAINDER-DOUBLE
 %STACK-FRAME-POINTER
 %STORE-CONDITIONAL
 %STRING-EQUAL
 %STRING-SEARCH-CHAR
 %STRUCTURE-BOXED-SIZE
 %STRUCTURE-TOTAL-SIZE
 %UNIBUS-READ
 %UNIBUS-WRITE
 %XBUS-READ
 %XBUS-WRITE

;;; Lambda-list keywords:

 &ALLOW-OTHER-KEYS
 &AUX
 &BODY
 &DT-ATOM
 &DT-DONTCARE
 &DT-FIXNUM
 &DT-FRAME
 &DT-LIST
 &DT-NUMBER
 &DT-SYMBOL
 &EVAL
 &FUNCTION-CELL
 &FUNCTIONAL
 &KEY
 &LIST-OF
 &LOCAL
 &OPTIONAL
 &QUOTE
 &QUOTE-DONTCARE
 &REST
 &SPECIAL

;;; Important variables and functions:

 
 G
 P
 
 
 *
 *$
 **
 ***
 *ALL-FLAVOR-NAMES*
 *ALL-FLAVOR-NAMES-AARRAY*
 *ARRAY
 *CATCH
 *EXPR
 *FEXPR
 *LEXPR
 *LEXPR-ARGLIST*
 *NOPOINT
 *RSET
 *THROW
 *UNWIND-STACK
 *PLUS *DIF *TIMES *QUO ;These for Maclisp compatibility
 +
 +$
 ++
 +++
 -
 -$
 //
 //$
 \
 \\
 ^
 ^$
 1+
 1+$
 1-
 1-$
 <
 <-
 <-AS
 <<--
 <=
 =
 >
 >=
 @DEFINE
 ABS
 ADD1
 ADD-INITIALIZATION
 ADJUST-ARRAY-SIZE
 ADVISE
 ADVISE-WITHIN
 ALL-SPECIAL-SWITCH
 ALLOCATE-RESOURCE
 ALLOW-VARIABLES-IN-FUNCTION-POSITION-SWITCH
 ALOC
 ALPHABETIC-CASE-AFFECTS-STRING-COMPARISON
 ALPHALESSP
 AND
 AP-1
 AP-2
 AP-3
 AP-LEADER
 APPEND
 APPEND-TO-ARRAY
 APPLY
 APROPOS
 AR-1
 AR-2
 AR-3
 AREA-LIST
 AREA-NAME
 AREA-NUMBER
 AREF
 ARG
 ARGLIST
 ARGS
 ARGS-INFO
 ARGS-INFO-FROM-LAMBDA-LIST 
 ARRAY
 ARRAY-/#-DIMS
 ARRAY-ACTIVE-LENGTH
 ARRAY-BITS-PER-ELEMENT
 ARRAY-CLASS
 ARRAY-DIMENSION-N
 ARRAY-DIMENSIONS
 ARRAY-DISPLACED-P
 ARRAY-ELEMENT-SIZE
 ARRAY-ELEMENTS-PER-Q
 ARRAY-GROW
 ARRAY-HAS-LEADER-P
 ARRAY-IN-BOUNDS-P
 ARRAY-INDEXED-P
 ARRAY-INDIRECT-P
 ARRAY-LEADER
 ARRAY-LEADER-LENGTH
 ARRAY-LENGTH
 ARRAY-POP
 ARRAY-PUSH
 ARRAY-PUSH-EXTEND
 ARRAY-TYPE
 ARRAY-TYPES
 ARRAYCALL
 ARRAYDIMS
 ARRAYP
 ART-16B
 ART-1B
 ART-2B
 ART-32B
 ART-4B
 ART-8B
 ART-ERROR
 ART-FAT-STRING
 ART-FLOAT
 ART-FPS-FLOAT
 ART-HALF-FIX
 ART-Q
 ART-Q-LIST
 ART-Q-LIST-ARRAY
 ART-REG-PDL
 ART-SPECIAL-PDL
 ART-STACK-GROUP-HEAD
 ART-STRING
 AS-1
 AS-2
 AS-3
 ASCII
 ASET
 ASH 
 ASS
 ASSIGN-ALTERNATE 
 ASSIGN-VALUES 
 ASSIGN-VALUES-INIT-DELTA
 ASSOC
 ASSQ
 ATAN
 ATAN2
 ATOM
 BASE
 BEEP
 BEGF
 BIGNUM
 BIGP
 BIND
 BITBLT
 BIT-TEST
 BOOLE
 BOUNDP
 BREAK
 BREAKON
 BUG
 BUTLAST
 CAAAAR
 CAAADR
 CAAAR
 CAADAR
 CAADDR
 CAADR
 CAAR
 CADAAR
 CADADR
 CADAR
 CADDAR
 CADDDR
 CADDR
 CADR
 CALL
 CAR
 CAR-LOCATION
 CASEQ
 CATCH
 CATCH-ALL
 CATCH-ERROR
 CDAAAR
 CDAADR
 CDAAR
 CDADAR
 CDADDR
 CDADR
 CDAR
 CDDAAR
 CDDADR
 CDDAR
 CDDDAR
 CDDDDR
 CDDDR
 CDDR
 CDR
 CDR-ERROR
 CDR-NEXT
 CDR-NIL
 CDR-NORMAL
 CERROR
 CHARACTER
 CHAR-DOWNCASE
 CHAR-EQUAL
 CHAR-LESSP
 CHAR-UPCASE
 CHECK-ARG
 CHECK-ARG-TYPE
 CHOOSE-USER-OPTIONS
 CIRCULAR-LIST
 CLASS
 CLASS-CLASS
 CLASS-METHOD-SYMBOL
 CLASS-SYMBOL
 CLASS-SYMBOLP
 CLEAR-MAR
 CLEAR-RESOURCE
 CLOSE
 CLOSURE
 CLOSURE-ALIST
 CLOSURE-FUNCTION
 CLOSUREP
 CLRHASH
 CLRHASH-EQUAL
 COMMENT
 COMPILE
 COMPILE-FILE-ALIST
 COMPILE-FLAVOR-METHODS
 COMPILER-LET
 COMPILER-WARNINGS-BUFFER
 CONCATENATE-COMPILER-WARNINGS-P
 COND
 COND-EVERY
 CONDITION-BIND
 CONS
 CONS-CLASS
 CONS-IN-AREA
 COPY-ARRAY-CONTENTS
 COPY-ARRAY-CONTENTS-AND-LEADER
 COPY-ARRAY-PORTION
 COPY-READTABLE
 COPYALIST
 COPYLIST
 COPYLIST*
 COPYSYMBOL
 COPYTREE
 COS
 COSD
 CURRENT-PROCESS
 CURSORPOS
 DATA-TYPE
 DEALLOCATE-RESOURCE
 DEBUGGING-INFO
 DECF
 DECLARE
 DECLARE-FLAVOR-INSTANCE-VARIABLES
 DEF
 DEF-OPEN-CODED
 DEFAULT-CONS-AREA
 DEFCLASS
 DEFCONST
 DEFF
 DEFFLAVOR
 DEFFUNCTION
 DEFINE-LOOP-MACRO
 DEFINE-LOOP-PATH
 DEFINE-LOOP-SEQUENCE-PATH
 DEFINE-SITE-ALIST-USER-OPTION
 DEFINE-SITE-HOST-LIST
 DEFINE-SITE-USER-OPTION
 DEFINE-SITE-VARIABLE
 DEFINE-USER-OPTION
 DEFINE-USER-OPTION-ALIST
 DEFLAMBDA-MACRO
 DEFLAMBDA-MACRO-DISPLACE
 DEFMACRO
 DEFMACRO-DISPLACE
 DEFMETHOD
 DEFMETHOD-INSTANCE
 DEFPROP
 DEFRESOURCE
 DEFSELECT
 DEFSTRUCT-DEFINE-TYPE
 DEFSTRUCT
 DEFSTRUCTCLASS
 DEFSUBST
 DEFSYSTEM
 DEFUN
 DEFUNP
 DEFVAR
 DEFWINDOW-RESOURCE
 DEFWRAPPER
 DEL-IF
 DEL-IF-NOT
 DEL
 DELETE
 DELETE-INITIALIZATION
 DELETEF
 DELQ
 DEPOSIT-BYTE
 DEPOSIT-FIELD
 DESCRIBE
 DESCRIBE-AREA
 DESCRIBE-DEFSTRUCT
 DESCRIBE-FLAVOR
 DESCRIBE-PACKAGE
 DESTRUCTURING-BIND
 DIFFERENCE
 DIRED
 DISASSEMBLE
 DISK-RESTORE
 DISK-SAVE
 DISPATCH
 DISPLACE
 DO
 DO-NAMED
 DOCUMENTATION
 DOLIST
 DOTIMES
 DPB
 DRIBBLE-END
 DRIBBLE-START
 DTP-ARRAY-HEADER
 DTP-ARRAY-POINTER
 DTP-BODY-FORWARD
 DTP-CLOSURE
 DTP-ENTITY 
 DTP-EXTENDED-NUMBER
 DTP-EXTERNAL-VALUE-CELL-POINTER
 DTP-FEF-POINTER
 DTP-FIX
 DTP-FREE
 DTP-GC-FORWARD
 DTP-HEADER
 DTP-HEADER-FORWARD
 DTP-INSTANCE
 DTP-INSTANCE-HEADER 
 DTP-LIST
 DTP-LOCATIVE
 DTP-NULL
 DTP-ONE-Q-FORWARD
 DTP-SELECT-METHOD
 DTP-SMALL-FLONUM 
 DTP-STACK-GROUP
 DTP-SYMBOL
 DTP-SYMBOL-HEADER
 DTP-TRAP
 DTP-U-ENTRY
 ED
 EH
 ENABLE-TRAPPING
 ENDF
 ENTITY
 ENTITYP 
 EQ
 EQUAL
 ERR
 ERROR
 ERROR-MESSAGE-HOOK
 ERROR-OUTPUT
 ERROR-RESTART
 ERRORP
 ERRSET
 EVAL
 EVAL-WHEN
 EVALHOOK
 EVENP
 EVERY
 EXPLODE
 EXPLODEC
 EXPLODEN
 EXP
 EXPR
 EXPT
 FALSE
 FASD-UPDATE-FILE
 FASL-APPEND
 FASLOAD
 FBOUNDP
 FDEFINE
 FDEFINEDP
 FDEFINITION
 FED
 FERROR
 FEXPR
 FIFTH
 FILL-POINTER
 FILLARRAY
 FIND-POSITION-IN-LIST
 FIND-POSITION-IN-LIST-EQUAL
 FIRST
 FIRSTN
 FIX
 FIXR
 FIXNUM
 FIXNUM-CLASS
 FIXNUMP
 FIXP
 FLATC
 FLATSIZE
 FLAVOR-ALLOWS-INIT-KEYWORD-P
 FLOAT
 FLOATP
 FLONUM
 FLONUMP
 FLONUM-CLASS
 FMAKUNBOUND
 FOLLOW-CELL-FORWARDING
 FOLLOW-STRUCTURE-FORWARDING
 FONT
 FONT-BASELINE
 FONT-BLINKER-HEIGHT
 FONT-BLINKER-WIDTH
 FONT-CHAR-HEIGHT
 FONT-CHAR-WIDTH
 FONT-CHAR-WIDTH-TABLE
 FONT-CHARS-EXIST-TABLE
 FONT-FILL-POINTER
 FONT-INDEXING-TABLE
 FONT-LEFT-KERN-TABLE
 FONT-NAME
 FONT-NEXT-PLANE
 FONT-RASTER-HEIGHT
 FONT-RASTER-WIDTH
 FONT-RASTERS-PER-WORD
 FONT-WORDS-PER-CHAR
 FORMAT
 FORWARD-VALUE-CELL
 FOURTH
 FSET
 FSET-CAREFULLY
 FSYMEVAL
 FUNCALL
 FUNCALL-SELF
 FUNCTION
 FUNCTION-CELL-LOCATION
 FUNCTION-DOCUMENTATION
 FUNCTIONAL-ALIST
 FUNCTIONP
 FQUERY
 G-L-P
 GC-ON
 GC-OFF
 GCD
 GENSYM
 GET
 GET-ALTERNATE 
 GET-FROM-ALTERNATING-LIST 
 GET-HANDLER-FOR
 GET-LIST-POINTER-INTO-ARRAY
 GET-LIST-POINTER-INTO-STRUCT
 GET-LOCATIVE-POINTER-INTO-ARRAY
 GET-PNAME
 GETCHAR
 GETCHARN
 GETF
 GETHASH
 GETHASH-EQUAL
 GETL
 GLOBALIZE
 GO
 GREATERP
 GRIND-TOP-LEVEL
 GRINDEF
 HAIPART
 HAULONG
 HOSTAT 
 IBASE
 IF
 IF-FOR-LISPM
 IF-FOR-MACLISP
 IF-FOR-MACLISP-ELSE-LISPM
 IF-IN-LISPM
 IF-IN-MACLISP
 IGNORE
 IMPLODE
 INCF
 INCLUDE
 INHIBIT-FDEFINE-WARNINGS
 INHIBIT-IDLE-SCAVENGING-FLAG
 INHIBIT-SCAVENGING-FLAG
 INHIBIT-SCHEDULING-FLAG
 INHIBIT-STYLE-WARNINGS
 INHIBIT-STYLE-WARNINGS-SWITCH
 INITIALIZATIONS
 INSPECT
 INSTANTIATE-FLAVOR
 INTERN
 INTERN-LOCAL
 INTERN-LOCAL-SOFT
 INTERN-SOFT
 INTERSECTION
 ISQRT
 KBD-CHAR-AVAILABLE
 KBD-TYI
 KBD-TYI-NO-HANG
 KEYWORD-EXTRACT
 LAMBDA
 LAMBDA-LIST-KEYWORDS
 LAMBDA-MACRO
 LAST
 LDB
 LDB-TEST
 LDIFF
 LENGTH
 LESSP
 LET
 LET-CLOSED
 LET-GLOBALLY
 LET-IF
 LET*
 LEXICAL-CLOSURE
 LEXPR-FUNCALL
 LEXPR-FUNCALL-SELF
 LISP-CRASH-LIST
 LISP-REINITIALIZE
 LIST
 LIST-ARRAY-LEADER
 LIST-IN-AREA
 LIST-PRODUCT
 LIST-SUM
 LIST*
 LIST*-IN-AREA
 LISTARRAY
 LISTIFY
 LISTP
 LOAD
 LOAD-BYTE
 LOAD-FILE-ALIST
 LOAD-FILE-LIST
 LOAD-PATCHES
 LOCAL-DECLARE
 LOCAL-DECLARATIONS
 LOCATE-IN-CLOSURE
 LOCATE-IN-INSTANCE
 LOCATIVE
 LOCATIVE-POINTER
 LOCATIVEP
 LOCF
 LOG
 LOGAND
 LOGIN
 LOGIN-EVAL
 LOGIN-SETQ
 LOGIOR
 LOGNOT
 LOGOUT
 LOGOUT-LIST
 LOGXOR
 LOOP
 LOOP-FINISH
 LSH
 MACRO
 MACRO-COMPILED-PROGRAM
 MACROEXPAND
 MACROEXPAND-1
 MAIL
 MAKE-AREA
 MAKE-ARRAY
 MAKE-ARRAY-INTO-NAMED-STRUCTURE
 MAKE-BROADCAST-STREAM
 MAKE-EQUAL-HASH-TABLE
 MAKE-HASH-TABLE
 MAKE-INSTANCE
 MAKE-LIST
 MAKE-PLANE
 MAKE-PROCESS
 MAKE-STACK-GROUP
 MAKE-SYMBOL
 MAKE-SYN-STREAM
 MAKE-SYSTEM
 MAKNAM
 MAKUNBOUND
 MAP
 MAP-CLASS-HIERARCHY 
 MAPATOMS
 MAPATOMS-ALL
 MAPC
 MAPCAN
 MAPCAR
 MAPCON
 MAPHASH
 MAPHASH-EQUAL
 MAPLIST
 MAR-BREAK
 MAR-MODE 
 MASK-FIELD
 MAX
 MEM
 MEMASS
 MEMBER
 MEMQ
 MEXP
 MIN
 MINUS
 MINUSP
 MONITOR-VARIABLE
 MULTIPLE-VALUE
 MULTIPLE-VALUE-BIND
 MULTIPLE-VALUE-CALL
 MULTIPLE-VALUE-LIST
 MULTIPLE-VALUE-RETURN
 NAMED-LAMBDA
 NAMED-STRUCTURE-INVOKE 
 NAMED-STRUCTURE-P
 NAMED-STRUCTURE-SYMBOL
 NAMED-SUBST
 NBUTLAST
 NCONC
 NCONS
 NCONS-IN-AREA
 NEQ
 NIL
 NLEFT
 NLISTP
 NOT
 NRECONC
 NREVERSE
 NSUBLIS
 NSUBSTRING
 NSUBST
 NSYMBOLP
 NTH
 NTHCDR
 NULL
 NULL-MACRO
 NUMBER-GC-ON
 NUMBER-INTO-ARRAY
 NUMBERP
 NUMBER-CLASS
 OBJECT-CLASS
 OBSOLETE-FUNCTION-WARNING-SWITCH
 ODDP
 ONCE-ONLY
 OPEN
 OPEN-CODE
 OPEN-CODE-MAP-SWITCH
 OR
 OTHERWISE
 PACKAGE
 PACKAGE-CELL-LOCATION
 PACKAGE-DECLARE
 PAIR
 PAIRLIS
 PARSE-NUMBER
 PEEK
 PERMANENT-STORAGE-AREA
 PKG-BIND
 PKG-CONTAINED-IN
 PKG-CREATE-PACKAGE
 PKG-DEBUG-COPY
 PKG-FIND-PACKAGE
 PKG-GLOBAL-PACKAGE
 PKG-GOTO
 PKG-IS-LOADED-P 
 PKG-KILL
 PKG-LOAD
 PKG-LOAD-MAP
 PKG-NAME 
 PKG-REFNAME-ALIST 
 PKG-SUPER-PACKAGE
 PKG-SYSTEM-PACKAGE 
 PLANE-AR-N
 PLANE-AREF
 PLANE-AS-N
 PLANE-ASET
 PLANE-DEFAULT
 PLANE-EXTENSION
 PLANE-ORIGIN
 PLANE-REF
 PLANE-STORE
 PLIST
 PLUS
 PLUSP
 POP
 PRIN1
 PRIN1-THEN-SPACE 
 PRINC
 PRINLENGTH
 PRINLEVEL
 PRINT
 PRINT-DISK-LABEL
 PRINT-ERROR-MODE
 PRINT-LOADED-BAND
 PRINT-NOTIFICATIONS
 PRINT-SENDS
 PRINT-SYSTEM-MODIFICATIONS
 PROBEF
 PROCESS-ALLOW-SCHEDULE
 PROCESS-CLASS
 PROCESS-CREATE
 PROCESS-DISABLE
 PROCESS-ENABLE
 PROCESS-ERROR-STOP-PROCESSES
 PROCESS-INITIAL-FORM
 PROCESS-INITIAL-STACK-GROUP
 PROCESS-LOCK
 PROCESS-NAME
 PROCESS-PLIST
 PROCESS-PRESET
 PROCESS-RESET
 PROCESS-RUN-FUNCTION
 PROCESS-RESET-AND-ENABLE
 PROCESS-RUN-RESTARTABLE-FUNCTION
 PROCESS-RUN-TEMPORARY-FUNCTION
 PROCESS-SLEEP
 PROCESS-STACK-GROUP
 PROCESS-UNLOCK
 PROCESS-WAIT
 PROCESS-WAIT-ARGUMENT-LIST
 PROCESS-WAIT-FUNCTION
 PROCESS-WAIT-WITH-TIMEOUT
 PROCESS-WHOSTATE
 PROG
 PROG*
 PROG1
 PROG2
 PROGN
 PROGV
 PROGW
 PROPERTY-CELL-LOCATION
 PSETQ
 PUSH
 PUT-ON-ALTERNATING-LIST
 PUTHASH
 PUTHASH-EQUAL
 PUTPROP
 Q-DATA-TYPES 
 QC-FILE
 QC-FILE-LOAD
 QUERY-IO
 QUOTE
 QUOTIENT
 QSEND
 RANDOM
 RASS
 RASSOC
 RASSQ
 READ
 READ-FOR-TOP-LEVEL
 READ-FROM-STRING
 READ-METER
 READ-PRESERVE-DELIMITERS
 READCH
 READFILE
 READLINE
 READLIST
 READTABLE
 RECOMPILE-FLAVOR
 REM-IF
 REM-IF-NOT
 REM
 REMAINDER
 REMHASH
 REMHASH-EQUAL
 REMMETHOD
 REMOB
 REMOVE
 REMPROP
 REMQ
 RENAMEF
 RESET-INITIALIZATIONS
 RESET-USER-OPTIONS
 REST1
 REST2
 REST3
 REST4
 RETAIN-VARIABLE-NAMES-SWITCH
 RETURN
 RETURN-ARRAY
 RETURN-LIST
 RETURN-NEXT-VALUE
 RETURN-FROM
 REVERSE
 ROOM
 ROT
 RPLACA
 RPLACD
 RUBOUT-HANDLER
 RUN-IN-MACLISP-SWITCH
 SAMEPNAMEP
 SASSOC
 SASSQ
 SCREEN-XGP-HARDCOPY
 SECOND 
 SELECT
 SELECTOR
 SELECTQ
 SELECTQ-EVERY
 SELF
 SEND
 SET
 SET-CHARACTER-TRANSLATION
 SET-CURRENT-BAND
 SET-CURRENT-MICROLOAD
 SET-ERROR-MODE
 SET-IN-CLOSURE
 SET-IN-INSTANCE
 SET-MAR
 SET-MEMORY-SIZE
 SET-SYNTAX-FROM-CHAR
 SET-SYNTAX-FROM-DESCRIPTION
 SET-SYNTAX-MACRO-CHAR
 SET-SYNTAX-/#-MACRO-CHAR
 SETARG
 SETF
 SETPLIST
 SETQ
 SETSYNTAX
 SETSYNTAX-SHARP-MACRO
 SEVENTH
 SG-AREA
 SG-RETURN-UNSAFE
 SIGNAL
 SIGNP
 SIN
 SIND
 SITE-NAME
 SIXTH
 SMALL-FLOAT
 SMALL-FLOATP
 SMALL-FLONUM
 SOME
 SORT
 SORT-GROUPED-ARRAY
 SORT-GROUPED-ARRAY-GROUP-KEY
 SORTCAR
 SOURCE-FILE-NAME     ;Trying to put this in keywords causes infinite problems
		      ; in FROID.
 SPECIAL
 SQRT
 SSTATUS
 STABLE-SORT
 STABLE-SORTCAR
 STACK-GROUP-PRESET
 STACK-GROUP-RESUME
 STACK-GROUP-RETURN
 STANDARD-INPUT
 STANDARD-OUTPUT
 STATUS
 STEP
 STEP-FORM
 STEP-VALUE
 STEP-VALUES
 STORE
 STORE-ARRAY-LEADER
 STREAM-COPY-UNTIL-EOF
 STREAM-DEFAULT-HANDLER 
 STRING
 STRING-APPEND
 STRING-COMPARE
 STRING-DOWNCASE
 STRING-EQUAL
 STRING-LEFT-TRIM
 STRING-LENGTH
 STRING-LESSP
 STRING-NCONC
 STRING-NREVERSE
 STRING-PLURALIZE
 STRING-REVERSE
 STRING-REVERSE-SEARCH
 STRING-REVERSE-SEARCH-CHAR
 STRING-REVERSE-SEARCH-NOT-CHAR
 STRING-REVERSE-SEARCH-NOT-SET
 STRING-REVERSE-SEARCH-SET
 STRING-RIGHT-TRIM
 STRING-SEARCH
 STRING-SEARCH-CHAR
 STRING-SEARCH-NOT-CHAR
 STRING-SEARCH-NOT-SET
 STRING-SEARCH-SET
 STRING-TRIM
 STRING-UPCASE
 STRINGP
 STRUCTURE-FORWARD
 SUB1
 SUBCLASS-OF-CLASSP
 SUBCLASS-OF-CLASS-SYMBOL-P
 SUBINSTANCE-OF-CLASSP
 SUBINSTANCE-OF-CLASS-SYMBOL-P
 SUBLIS
 SUBRP
 SUBSET
 SUBSET-NOT
 SUBST
 SUBSTRING
 SUPDUP
 SWAP-SV-OF-SG-THAT-CALLS-ME
 SWAP-SV-ON-CALL-OUT
 SWAPF
 SWAPHASH
 SWAPHASH-EQUAL
 SXHASH
 SYMBOL
 SYMBOLP
 SYMBOL-CLASS
 SYMBOL-PACKAGE
 SYMEVAL
 SYMEVAL-IN-CLOSURE
 SYMEVAL-IN-INSTANCE
 SYMEVAL-IN-STACK-GROUP
 T
 TAIL
 TAILP
 TELNET 
 TERMINAL-IO
 TERPRI
 THIRD
 THROW
 TIME
 TIME-DIFFERENCE
 TIME-LESSP
 TIMES
 TRACE
 TRACE-COMPILE-FLAG
 TRACE-OUTPUT 
 TRAP-ENABLE
 TRAPPING-ENABLED-P
 TRUE
 TYI
 TYIPEEK
 TYO
 TYPEP
 UNADVISE
 UNADVISE-WITHIN
 UNBIND
 UNBOUND-FUNCTION  ;for WHO-CALLS
 UNBREAKON
 UNCOMPILE
 UNDEFMETHOD
 UNDEFUN
 UNDELETEF
 UNION
 UNLESS
 UNMONITOR-VARIABLE
 UNSPECIAL
 UNTRACE
 UNWIND-PROTECT
 UNWIND-PROTECT-TAG
 UNWIND-PROTECT-VALUE
 USER-ID
 USING-RESOURCE
 VALUE-CELL-LOCATION
 VALUES
 VALUES-LIST
 WHERE-IS
 WHAT-FILES-CALL
 WHEN
 WHO-CALLS
 WHO-USES
 WITHOUT-INTERRUPTS
 WITH-INPUT-FROM-STRING
 WITH-OPEN-FILE
 WITH-OPEN-STREAM
 WITH-OUTPUT-TO-STRING
 WITH-RESOURCE		;Delete this in June 1981
 WORKING-STORAGE-AREA
 WRITE-METER
 WRITE-USER-OPTIONS
 XCONS
 XCONS-IN-AREA
 XSTORE
 Y-OR-N-P 
 YES-OR-NO-P
 ZED
 ZEROP
 ZDT
 ZMAIL
 ZUNDERFLOW

 ;; EOF.
 
