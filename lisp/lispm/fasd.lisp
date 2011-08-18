;FAST DUMPER (MACLISP MODEL)		-*-LISP-*-

;	** (c) Copyright 1980 Massachusetts Institute of Technology **

;READ LISPM;MACROS > IN BEFORE TRYING TO RUN THIS INTERPRETIVELY

(DECLARE (COND ((STATUS FEATURE LISPM))
	       ((NULL (MEMQ 'NEWIO (STATUS FEATURES)))
		(BREAK 'YOU-HAVE-TO-COMPILE-THIS-WITH-QCOMPL T))
	       ((NULL (GET 'IF-FOR-MACLISP 'MACRO))
		(LOAD '(MACROS > DSK LISPM))
		(LOAD '(DEFMAC FASL DSK LISPM2))
		(LOAD '(LMMAC > DSK LISPM2))
		(MACROS T))))	;SEND OVER THE REST OF THE MACROS IN THIS FILE

(DECLARE (FIXNUM (Q-CHAR-LENGTH NOTYPE)
		 (Q-CHAR-CHOMP NOTYPE)))

(DECLARE (SPECIAL ARRAY-ELEMENTS-PER-Q ARRAY-DIM-MULT ARRAY-TYPES 
	ARRAY-TYPE-SHIFT ARRAY-DISPLACED-BIT ARRAY-LEADER-BIT ARRAY-LONG-LENGTH-FLAG 
	%ARRAY-MAX-SHORT-INDEX-LENGTH))

(DECLARE (SPECIAL FASD-BUFFER-ARRAY FASD-FILE))

(DECLARE (SPECIAL FASD-TABLE FASD-GROUP-LENGTH FASL-TABLE-PARAMETERS))

(DECLARE (SPECIAL %FASL-GROUP-CHECK 
   %FASL-GROUP-FLAG %FASL-GROUP-LENGTH 
   FASL-GROUP-LENGTH-SHIFT %FASL-GROUP-TYPE 
  FASL-OP-ERR FASL-OP-INDEX FASL-OP-SYMBOL FASL-OP-PACKAGE-SYMBOL FASL-OP-LIST 
  FASL-OP-TEMP-LIST FASL-OP-FIXED FASL-OP-FLOAT 
  FASL-OP-ARRAY FASL-OP-EVAL FASL-OP-MOVE 
  FASL-OP-FRAME FASL-OP-ARRAY-PUSH FASL-OP-STOREIN-SYMBOL-VALUE 
  FASL-OP-STOREIN-FUNCTION-CELL FASL-OP-STOREIN-PROPERTY-CELL 
  FASL-OP-STOREIN-ARRAY-LEADER
  FASL-OP-FETCH-SYMBOL-VALUE FASL-OP-FETCH-FUNCTION-CELL 
  FASL-OP-FETCH-PROPERTY-CELL FASL-OP-APPLY FASL-OP-END-OF-WHACK 
  FASL-OP-END-OF-FILE FASL-OP-SOAK FASL-OP-FUNCTION-HEADER FASL-OP-FUNCTION-END 
  FASL-OP-MAKE-MICRO-CODE-ENTRY FASL-OP-SAVE-ENTRY-POINT FASL-OP-MICRO-CODE-SYMBOL 
  FASL-OP-MICRO-TO-MICRO-LINK FASL-OP-MISC-ENTRY FASL-OP-QUOTE-POINTER FASL-OP-S-V-CELL 
  FASL-OP-FUNCELL FASL-OP-CONST-PAGE FASL-OP-SET-PARAMETER 
  FASL-OP-INITIALIZE-ARRAY FASL-OP-UNUSED FASL-OP-UNUSED1 
    FASL-OP-UNUSED2 FASL-OP-UNUSED3 FASL-OP-UNUSED4
  FASL-OP-UNUSED5 FASL-OP-UNUSED6 
  FASL-OP-STRING FASL-OP-EVAL1 
  FASL-NIL FASL-EVALED-VALUE FASL-TEM1 FASL-TEM2 FASL-TEM3 
    FASL-SYMBOL-HEAD-AREA 
    FASL-SYMBOL-STRING-AREA FASL-OBARRAY-POINTER FASL-ARRAY-AREA 
    FASL-FRAME-AREA FASL-LIST-AREA FASL-TEMP-LIST-AREA 
    FASL-MICRO-CODE-EXIT-AREA 
  FASL-TABLE-WORKING-OFFSET ))

(DECLARE (FIXNUM (FASD-TABLE-ENTER NOTYPE NOTYPE))
	 (NOTYPE (FASD-START-GROUP NOTYPE FIXNUM FIXNUM)
		 (FASD-FIXED FIXNUM)
		 (FASD-INITIALIZE-ARRAY FIXNUM NOTYPE)
		 (FASD-INDEX FIXNUM)
		 (FASD-EVAL FIXNUM)
		 (FASD-NIBBLE FIXNUM)))

(DEFUN FASD-START-GROUP (FLAG LENGTH TYPE)
  (PROG (OUT-LEN)
	(SETQ FASD-GROUP-LENGTH LENGTH)
        (SETQ OUT-LEN (LSH (COND ((>= LENGTH 377) 377)
                                 (T LENGTH))
                           (- FASL-GROUP-LENGTH-SHIFT)))                           
	(FASD-NIBBLE (+ %FASL-GROUP-CHECK 
			(+ (COND (FLAG %FASL-GROUP-FLAG) (T 0))
			   (+ OUT-LEN
			      TYPE))))
	(AND (>= LENGTH 377)
	     (FASD-NIBBLE LENGTH))
	(RETURN NIL)))

(DEFUN FASD-SYMBOL (SYM)
  (COND ((GET SYM 'MAGIC-PACKAGE-FLAG)
	 (FASD-PACKAGE-SYMBOL (GET SYM 'MAGIC-PACKAGE-FLAG)))
	(T (FASD-WRITE-SYMBOL SYM FASL-OP-SYMBOL))))

(DEFUN FASD-STRING (STRING) (FASD-WRITE-SYMBOL STRING FASL-OP-STRING))

(DEFUN FASD-WRITE-SYMBOL (SYM GROUP-TYPE)
  (PROG (FASD-GROUP-LENGTH CHLIST C0 C1)
	(DECLARE (FIXNUM C0 C1))
	(SETQ CHLIST (EXPLODEN SYM))
	(FASD-START-GROUP NIL (// (1+ (Q-CHAR-LENGTH CHLIST)) 2) GROUP-TYPE)
 L	(COND ((NULL CHLIST)
		(RETURN NIL)))
;	(SETQ C0 (CAR CHLIST))
;	(SETQ C1 (COND ((CDR CHLIST) (CADR CHLIST))
;				     (T 200)))
;	(COND ((AND (> C0 7)
;		    (< C0 16))
;		(SETQ C0 (+ 200 C0))))
;	(COND ((AND (> C1 7)
;		    (< C1 16))
;		(SETQ C1 (+ 200 C1))))
	(SETQ C0 (Q-CHAR-CHOMP CHLIST))
	(SETQ C1 (COND ((NULL (SETQ CHLIST (Q-CHAR-ADVANCE CHLIST)))
			  200)
		       (T (Q-CHAR-CHOMP CHLIST))))
	(FASD-NIBBLE (+ C0 (LSH C1 8)))
	(SETQ CHLIST (Q-CHAR-ADVANCE CHLIST))
	(GO L)))

;; For A:B:C, we are given the list (A B C).
(DEFUN FASD-PACKAGE-SYMBOL (LIST)
    (FASD-START-GROUP NIL 1 FASL-OP-PACKAGE-SYMBOL)
    (FASD-NIBBLE (LENGTH LIST))
    (DO L LIST (CDR L) (NULL L)
      (FASD-STRING (CAR L))
      (FASD-TABLE-ENTER 'LIST (CAR L))))

(DEFUN FASD-CONSTANT (S-EXP)
  (PROG (FASD-GROUP-LENGTH TEM BSIZE DOTP)
	(COND ((SETQ TEM (FASD-TABLE-SEARCH 'LIST S-EXP))
		(FASD-START-GROUP NIL 1 FASL-OP-INDEX)
		(FASD-NIBBLE TEM)
		(RETURN TEM))
	      ((FIXP S-EXP) (FASD-FIXED S-EXP) (GO X))
	      ((FLOATP S-EXP) (FASD-FLOAT S-EXP) (GO X))
	      ((ATOM S-EXP) (FASD-SYMBOL S-EXP) (GO X))
	      ((EQ (CAR S-EXP) '**PACKAGE**)
	       (FASD-PACKAGE-SYMBOL (CDR S-EXP)) (GO X))
	      ((EQ (CAR S-EXP) '**STRING**)
		(FASD-STRING (CADR S-EXP)) (GO X))
	      ((EQ (CAR S-EXP) '**EXECUTION-CONTEXT-EVAL**)
	        (FASD-EVAL1 (CDR S-EXP))))
	(SETQ BSIZE (LENGTH-TERM-BY-ATOM S-EXP))
	(SETQ TEM S-EXP)
	(COND ((CDR (LAST-TERM-BY-ATOM S-EXP)) 
		(SETQ BSIZE (1+ BSIZE))
		(SETQ DOTP T)
		(SETQ TEM (UNDOTIFY S-EXP))))
	(FASD-START-GROUP DOTP 1 FASL-OP-LIST)
	(FASD-NIBBLE BSIZE)
  L	(COND ((NULL TEM) (GO X)))
	(FASD-CONSTANT (CAR TEM))
	(SETQ TEM (CDR TEM))
	(GO L)
  X	(RETURN (FASD-TABLE-ENTER 'LIST S-EXP))
))

(DEFUN FASD-FIXED (N)
 (PROG (FASD-GROUP-LENGTH NMAG NLENGTH)
	(SETQ NMAG (ABS N)
	      NLENGTH (// (+ (HAULONG NMAG) 15.) 16.))
	(COND ((> (HAULONG NMAG) 64.)
	       (BARF N 'BIGNUM-TOO-LONG-FOR-FASD-FIXED 'WARN)))  ;UNTIL NEW BYTE SPEC.
	(FASD-START-GROUP (< N 0) NLENGTH FASL-OP-FIXED)
	(DO ((POS (* 20 (1- NLENGTH)) (- POS 20))
	     (C NLENGTH (1- C)))
	    ((ZEROP C))
	    (FASD-NIBBLE (LOGLDB (+ (LSH POS 6) 20) NMAG)))))

(DEFUN FASD-FLOAT (N)
 (DECLARE (FLONUM N))
 (PROG (FASD-GROUP-LENGTH EXP MANTISSA)
        (SETQ MANTISSA (LOGAND (LSH N 0) 777777777)
	      EXP (LSH N -27.))
	(COND ((MINUSP N)
	       (SETQ EXP (LOGAND (1- (- EXP)) 377)
		     MANTISSA (+ 1_28. MANTISSA))
	       ;; THIS IS TO TAKE CARE OF THE -1/2 CASE WHICH IS DIFFERENT IN 10
	       (COND ((= MANTISSA 3_28.)
		      (SETQ EXP (1- EXP) MANTISSA 1_28.)))))
	(COND ((NOT (ZEROP N))
	       (SETQ EXP (+ EXP 1600))))		;CONVERSION FROM EXCESS 200 TO 2000
	(FASD-START-GROUP NIL 3 FASL-OP-FLOAT)
	(FASD-NIBBLE EXP)
	(FASD-NIBBLE (LSH MANTISSA -12.))
	(FASD-NIBBLE (LOGAND (LSH MANTISSA 3) 177777))))

(DEFUN FASD-MICRO-CODE-SYMBOL (SYM)
 (PROG (FASD-GROUP-LENGTH TEM)
	(FASD-START-GROUP NIL 1 FASL-OP-MICRO-CODE-SYMBOL)
	(BREAK OBSOLETE T)))

(DEFUN FASD-MISC-ENTRY (SYM)
  (PROG (FASD-GROUP-LENGTH TEM)
	(FASD-START-GROUP NIL 1 FASL-OP-MICRO-CODE-SYMBOL)
	(COND ((NULL (SETQ TEM (GET SYM 'QLVAL)))
		(BARF SYM 'UNDEFINED-MISC-ENTRY 'BARF)))
	(FASD-NIBBLE (- TEM 200))))	;AREA STARTS WITH MISC-ENTRY 200

(DEFUN FASD-QUOTE-POINTER (S-EXP)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-QUOTE-POINTER)
	(FASD-CONSTANT S-EXP)))

(DEFUN FASD-S-V-CELL (SYM)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-S-V-CELL)
	(FASD-CONSTANT SYM)))

(DEFUN FASD-FUNCELL (SYM)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-FUNCELL)
	(FASD-CONSTANT SYM)))

(DEFUN FASD-CONST-PAGE (CONST-PAGE-INDEX)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 1 FASL-OP-CONST-PAGE)
	(FASD-NIBBLE CONST-PAGE-INDEX)))

(DEFUN FASD-MICRO-TO-MICRO-LINK (SYM)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-MICRO-TO-MICRO-LINK)
	(FASD-CONSTANT SYM)))

(DEFUN FASD-FUNCTION-HEADER (FCTN-NAME)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-FUNCTION-HEADER)
	(FASD-CONSTANT FCTN-NAME)
	(FASD-CONSTANT '0)))

(DEFUN FASD-SAVE-ENTRY-POINT (FCTN-NAME) 
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-SAVE-ENTRY-POINT)
	(RETURN (FASD-TABLE-ENTER 'ENTRY-POINT FCTN-NAME))))

(DEFUN FASD-MAKE-MICRO-CODE-ENTRY (FCTN-NAME ARGDESC-ATOM ENTRY-FASL-INDEX)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 1 FASL-OP-MAKE-MICRO-CODE-ENTRY)
	(FASD-CONSTANT FCTN-NAME)
	(FASD-CONSTANT ARGDESC-ATOM)
	(FASD-NIBBLE ENTRY-FASL-INDEX)
	(RETURN (FASD-TABLE-ENTER 'UENTRY-INDEX FCTN-NAME)) ))

(DEFUN FASD-FUNCTION-END NIL 
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-FUNCTION-END)))

(DEFUN FASD-END-WHACK NIL 
  (PROG ()			;STARTING NEW WHACK SO LET FASD-GROUP-LENGTH GET
				;SET TO 0
	(FASD-START-GROUP NIL 0 FASL-OP-END-OF-WHACK)
	(FASD-TABLE-INITIALIZE)))

(DEFUN FASD-END-OF-FILE NIL
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-END-OF-FILE)))

(DEFUN FASD-END-FILE NIL
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-END-OF-FILE)))

(DEFUN FASD-SET-PARAMETER (PARAM VAL)
  (PROG (FASD-GROUP-LENGTH C-VAL)
	(COND ((NULL (SETQ C-VAL (ASSQ PARAM FASD-TABLE)))
		(BARF PARAM 'UNKNOWN-FASL-PARAMETER 'BARF)))
	(COND ((EQUAL VAL (CDR C-VAL))(RETURN NIL)))
	(FASD-START-GROUP NIL 0 FASL-OP-SET-PARAMETER)
	(FASD-CONSTANT PARAM)
	(FASD-CONSTANT VAL)
))

(DEFUN FASD-STOREIN-ARRAY-LEADER (ARRAY SUBSCR VALUE)
   (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 3 FASL-OP-STOREIN-ARRAY-LEADER)
	(FASD-NIBBLE ARRAY)
	(FASD-NIBBLE SUBSCR)
	(FASD-NIBBLE VALUE)
	(RETURN 0)))

(DEFUN FASD-STOREIN-FUNCTION-CELL (SYM IDX)	;IDX AN FASD-TABLE INDEX THAT HAS
   (PROG (FASD-GROUP-LENGTH)			;STUFF DESIRED TO STORE.
	(FASD-START-GROUP NIL 1 FASL-OP-STOREIN-FUNCTION-CELL)
	(FASD-NIBBLE IDX)
	(FASD-CONSTANT SYM)
	(RETURN 0)))

(DEFUN FASD-STOREIN-SYMBOL-VALUE (SYM IDX)
   (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 1 FASL-OP-STOREIN-SYMBOL-VALUE)
	(FASD-NIBBLE IDX)
	(FASD-CONSTANT SYM)
	(RETURN 0)))

(DEFUN FASD-STOREIN-PROPERTY-CELL (SYM IDX)
   (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 1 FASL-OP-STOREIN-PROPERTY-CELL)
	(FASD-NIBBLE IDX)
	(FASD-CONSTANT SYM)
	(RETURN 0)))

(DEFUN FASD-INITIALIZE-ARRAY (IDX INIT)
   (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-INITIALIZE-ARRAY)
	(FASD-INDEX IDX)
	(FASD-CONSTANT (LENGTH INIT))
   L	(COND ((NULL INIT) (RETURN 0)))
	(FASD-CONSTANT (CAR INIT))
	(SETQ INIT (CDR INIT))
	(GO L)))

(DEFUN FASD-INDEX (IDX)
  (FASD-START-GROUP NIL 1 FASL-OP-INDEX)
  (FASD-NIBBLE IDX))

;(DEFUN FASD-MESA-FEF (STORAGE-LENGTH MAX-EXIT-VECTOR-USAGE MAX-IP-PDL-USAGE 
;			 FCTN-NAME FAST-OPTION-Q)
;  (PROG (FASD-GROUP-LENGTH)
;	(FASD-START-GROUP NIL 3 FASL-OP-MESA-FEF)
;	(FASD-NIBBLE STORAGE-LENGTH)
;	(FASD-NIBBLE MAX-EXIT-VECTOR-USAGE)
;	(FASD-NIBBLE MAX-IP-PDL-USAGE)
;	(FASD-CONSTANT FCTN-NAME)
;	(FASD-CONSTANT FAST-OPTION-Q)))
;
;(DEFUN FASD-MESA-INSTRUCTION (WD)
;  (PROG (FASD-GROUP-LENGTH)
;	(FASD-START-GROUP NIL 1 FASL-OP-MESA-INSTRUCTION)
;	(FASD-NIBBLE WD)))
;
;(DEFUN FASD-MESA-FUNCELL-PLUGIN (SYM ARG-Q)
;  (PROG (FASD-GROUP-LENGTH)
;	(FASD-START-GROUP ARG-Q 0 FASL-OP-MESA-FUNCELL-PLUGIN)
;	(FASD-CONSTANT SYM)
;	(COND (ARG-Q (FASD-CONSTANT ARG-Q))) ))
;
;(DEFUN FASD-MESA-S-V-CELL-PLUGIN (SYM)
;  (PROG (FASD-GROUP-LENGTH)
;	(FASD-START-GROUP NIL 0 FASL-OP-MESA-S-V-CELL-PLUGIN)
;	(FASD-CONSTANT SYM)))
;
;(DEFUN FASD-MESA-QUOTE-PLUGIN (S-EXP)
;  (PROG (FASD-GROUP-LENGTH)
;	(FASD-START-GROUP NIL 0 FASL-OP-MESA-QUOTE-PLUGIN)
;	(FASD-CONSTANT S-EXP)))
;
;(DEFUN FASD-MESA-CONST-PAGE-PLUGIN (CONST-PAGE-INDEX)
;  (PROG (FASD-GROUP-LENGTH)
;	(FASD-START-GROUP NIL 1 FASL-OP-MESA-CONST-PAGE-PLUGIN)
;	(FASD-NIBBLE CONST-PAGE-INDEX)))
;
;(DEFUN FASD-MESA-FUNCTION-END NIL
;  (PROG (FASD-GROUP-LENGTH)
;	(FASD-START-GROUP NIL 0 FASL-OP-MESA-FUNCTION-END)))

(DEFUN FASD-EVAL (IDX) 
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 1 FASL-OP-EVAL)
	(FASD-NIBBLE IDX)
	(RETURN FASL-EVALED-VALUE)))

(DEFUN FASD-EVAL1 (SEXP)
  (PROG (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 0 FASL-OP-EVAL1)
	(FASD-CONSTANT SEXP)
	(RETURN (FASD-TABLE-ENTER 'EVALED-VALUE SEXP))))
;--

(DEFUN FASD-STORE-VALUE-IN-FUNCTION-CELL (SYM VAL)
	(FASD-STOREIN-FUNCTION-CELL SYM (FASD-CONSTANT VAL)))

(DEFUN FASD-MAKE-ARRAY N
    (COND ((OR (< N 5) (> N 6))
	   (ERROR '|Wrong number of arguments to FASD-MAKE-ARRAY| N)))
    (LET ((FASD-GROUP-LENGTH 0))
      (FASD-START-GROUP (> N 5) 0 FASL-OP-ARRAY)
      (FASD-CONSTANT (ARG 1))
      (FASD-CONSTANT (ARG 2))
      (FASD-CONSTANT (ARG 3))
      (FASD-CONSTANT (ARG 4))
      (FASD-CONSTANT (ARG 5))
      (FASD-CONSTANT NIL) ;INDEX OFFSET
      (AND (> N 5) (FASD-CONSTANT (ARG 6)))
      (FASD-TABLE-ENTER 'ARRAY-POINTER (GENSYM))))

(DEFUN UNDOTIFY (X)
	(COND ((OR (ATOM X) (NULL (CDR X))) X)
	      ((ATOM (CDR X)) (LIST (CAR X) (CDR X)))
	      (T (CONS (CAR X) (UNDOTIFY (CDR X))))))

(DEFUN FASD-TABLE-ENTER (TYPE DATA)
  (PROG NIL 
	(NCONC FASD-TABLE (LIST (CONS TYPE DATA)))
	(RETURN (1- (LENGTH FASD-TABLE)))))

(DEFUN FASD-TABLE-LENGTH () (LENGTH FASD-TABLE))

(DEFUN FASD-TABLE-SET (TYPE DATA)
 (PROG (TEM)
	(SETQ TEM FASD-TABLE)
  L	(COND ((NULL TEM) (BARF TYPE 'BAD-FASD-PARAMETER 'BARF))
	      ((EQ (CAAR TEM) TYPE)
		 (RPLACD (CAR TEM) DATA)
		 (RETURN NIL)))
	(SETQ TEM (CDR TEM))
	(GO L)))

(DEFUN FASD-TABLE-LOOKUP (DATA) (FASD-TABLE-SEARCH 'LIST DATA))

(DEFUN FASD-TABLE-SEARCH (TYPE DATA)
 (PROG (C TEM)
       (AND (EQ TYPE 'LIST)
	    (NUMBERP DATA)
	    (RETURN NIL))
	(SETQ C 0)
	(SETQ TEM FASD-TABLE)
  L	(COND ((NULL TEM) (RETURN NIL))
	      ((AND (EQ (CAAR TEM) TYPE)
		    (EQ (CDAR TEM) DATA))
		(RETURN C)))
	(SETQ C (1+ C))
	(SETQ TEM (CDR TEM))
	(GO L)))

(DEFUN FASD-INITIALIZE NIL
	(FASD-TABLE-INITIALIZE))

(DEFUN FASD-TABLE-INITIALIZE NIL 
  (PROG (TEM)
	(SETQ FASD-GROUP-LENGTH 0)
	(SETQ FASD-TABLE NIL)
	(SETQ TEM (REVERSE FASL-TABLE-PARAMETERS))
  L1	(COND ((NOT (= (LENGTH TEM) FASL-TABLE-WORKING-OFFSET))
		(SETQ TEM (CONS 'UNUSED TEM))
		(GO L1)))
  L	(COND ((NULL TEM) (GO X)))
	(SETQ FASD-TABLE (CONS (LIST (CAR TEM))
			       FASD-TABLE))
	(SETQ TEM (CDR TEM))
	(GO L)
  X	(FASD-TABLE-SET 'FASL-SYMBOL-HEAD-AREA 'NRSYM) ;SET THINGS UP LIKE 
						;INITIALIZE-FASL-TABLE DOES AT FASL TIME
	(FASD-TABLE-SET 'FASL-SYMBOL-STRING-AREA 'P-N-STRING)
	(FASD-TABLE-SET 'FASL-ARRAY-AREA 'USER-ARRAY-AREA)
	(FASD-TABLE-SET 'FASL-FRAME-AREA 'MACRO-COMPILED-PROGRAM)
	(FASD-TABLE-SET 'FASL-LIST-AREA 'USER-INITIAL-LIST-AREA)
	(FASD-TABLE-SET 'FASL-TEMP-LIST-AREA 'FASL-TEMP-AREA)
	(FASD-TABLE-SET 'FASL-MICRO-CODE-EXIT-AREA 'MICRO-CODE-EXIT-AREA)
	(RETURN T)))

;DUMP A GROUP TO EVALUATE A GIVEN FORM AND RETURN ITS VALUE.
;IF OPTIMIZE IS SET, SETQ AND DEFUN ARE HANDLED SPECIALLY,
;IN A WAY APPROPRIATE FOR THE TOP LEVEL OF FASDUMP OR QC-FILE.
(DEFUN FASD-FORM (FORM OPTIMIZE)
   (COND ((OR (MEMQ FORM '(T NIL))
	      (AND (NOT (ATOM FORM))
		   (MEMQ (CAR FORM) '(**PACKAGE** **STRING**)))
	      (NUMBERP FORM))
	  (FASD-CONSTANT FORM))
	 ((ATOM FORM) (FASD-RANDOM-FORM FORM))
	 ((EQ (CAR FORM) 'QUOTE)
	  (FASD-CONSTANT (CADR FORM)))
	 ((NOT OPTIMIZE)
	  (FASD-RANDOM-FORM FORM))
	 ((EQ (CAR FORM) 'SETQ)
	  (FASD-SETQ FORM))
         ((EQ (CAR FORM) 'DECLARE)
          (MAPC (FUNCTION FASD-DECLARATION) (CDR FORM)))
	 (T (FASD-RANDOM-FORM FORM))))

(DEFUN FASD-DECLARATION (DCL)
    (AND (MEMQ (CAR DCL) '(SPECIAL UNSPECIAL))
         (FASD-FORM DCL NIL)))

;DUMP SOMETHING TO EVAL SOME RANDOM FORM (WHICH IS THE ARGUMENT).
(DEFUN FASD-RANDOM-FORM (FRM)
    (FASD-EVAL (FASD-CONSTANT FRM)))

;This is an old name for the same thing as FASD-RANDOM-FORM.
(DEFUN FASDUMP-EVAL (LST)
  (PROG (IDX)
	(SETQ IDX (FASD-CONSTANT LST))
	(RETURN (FASD-EVAL IDX))))
	
(DEFUN FASD-SETQ (FORM) (FASDUMP-SETQ (CDR FORM)))

(DEFUN FASDUMP-SETQ (PAIR-LIST)
  (PROG (IDX)
   L	(COND ((NULL PAIR-LIST) (RETURN NIL))
	      ((NOT (ATOM (CAR PAIR-LIST)))
		(BARF (CAR PAIR-LIST) 'FASDUMP-SETQ 'DATA)
		(GO E))
	      (T (SETQ IDX (FASD-FORM (CADR PAIR-LIST) NIL))))
	(FASD-STOREIN-SYMBOL-VALUE (CAR PAIR-LIST) IDX)
  E	(SETQ PAIR-LIST (CDDR PAIR-LIST))
	(GO L)))

;(DEFUN FASD-NIBBLE (X) (PRINT X))

(DEFUN FASD-NIBBLE (X)
  (SETQ X (LOGAND 177777 X))
  (LET ((TEM 0))
    (DECLARE (FIXNUM TEM))
    (STORE (ARRAYCALL FIXNUM FASD-BUFFER-ARRAY 0)
	   (COND ((MINUSP (SETQ TEM (ARRAYCALL FIXNUM FASD-BUFFER-ARRAY 0)))	;FIRST HALFWORD
		  X)
		 (T (OUT FASD-FILE	;SECOND HALFWORD
			 (LSH (+ (LSH TEM 16.) X) 4))
		    -1))))
  NIL)
			 
(DEFUN FASD-CLOSE (FINAL-NAME)
  (AND (PLUSP (ARRAYCALL FIXNUM FASD-BUFFER-ARRAY 0))
       (FASD-NIBBLE 0))		;FORCE
  (AND FINAL-NAME (RENAMEF FASD-FILE FINAL-NAME))
  (CLOSE FASD-FILE))

(DEFUN FASD-OPEN (FILE)
  (SETQ FILE (MERGEF '((* *) _QCMP_ OUTPUT) FILE))
  (SETQ FASD-FILE (OPEN FILE '(OUT FIXNUM BLOCK)))
  (OR (BOUNDP 'FASD-BUFFER-ARRAY)
      (SETQ FASD-BUFFER-ARRAY (*ARRAY NIL 'FIXNUM 1)))	;TO AVOID NUMBER CONSING
  (STORE (ARRAYCALL FIXNUM FASD-BUFFER-ARRAY 0) -1)	;RESET BUFFERED BACK HALFWORD
  (FASD-NIBBLE 143150)					;MAGIC
  (FASD-NIBBLE 71660)					;MORE MAGIC - SIXBIT/QFASL/
  T)

(DEFUN FASDUMP-ARRAY (NAME AREA ARRAY-TYPE DIMLIST DISPLACED-P LEADER INITIALIZATION)
  (PROG (IDX)
	(COND ((EQUAL DIMLIST '(**)) (SETQ DIMLIST (LIST (LENGTH INITIALIZATION)))))
	(SETQ IDX (FASD-MAKE-ARRAY AREA ARRAY-TYPE DIMLIST DISPLACED-P LEADER))
	(COND ((ATOM NAME) (FASD-STOREIN-FUNCTION-CELL NAME IDX))
	      ((AND (EQ (CAR NAME) 'VALUE-CELL)
		    (ATOM (CADR NAME)))
		(FASD-STOREIN-SYMBOL-VALUE (CADR NAME) IDX))
	      (T (BARF NAME 'BAD-ARRAY-NAME 'WARN)))
	(COND (INITIALIZATION (FASD-INITIALIZE-ARRAY IDX INITIALIZATION)))
	))