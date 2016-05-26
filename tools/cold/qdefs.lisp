; -*-LISP-*-

;	** (c) Copyright 1980 Massachusetts Institute of Technology **

;ELEMENTS IN Q-CORRESPONDING-VARIABLE-LIST ARE SYMBOLS WHOSE VALUES IN MACLISP ARE LISTS
;  ALL OF WHOSE MEMBERS ARE SYSTEM CONTANTS.  THESE SYSTEM CONSTANTS HAVE MACLISP VALUES
;  AND ARE MADE TO HAVE THE IDENTICAL VALUES IN LISP MACHINE LISP.
(cl:defvar Q-CORRESPONDING-VARIABLE-LISTS '(AREA-LIST Q-CDR-CODES Q-DATA-TYPES Q-HEADER-TYPES
   Q-LISP-CONSTANTS
   ;RTB-RTB-BITS RTB-RTS-BITS RTB-RTO-OPS 
   ;RTB-MISC RTM-OPS READTABLE-%%-BITS 
   ARRAY-TYPES HEADER-TYPES HEADER-FIELDS MISC-Q-VARIABLES 
   ARG-DESC-FIELDS NUMERIC-ARG-DESC-FIELDS FEF-NAME-PRESENT FEF-SPECIALNESS
   FEF-ARG-SYNTAX FEF-INIT-OPTION FEFHI-FIELDS FEF-DES-DT FEF-QUOTE-STATUS 
   FEF-FUNCTIONAL 
   ARRAY-FIELDS ARRAY-LEADER-FIELDS ARRAY-MISCS Q-REGION-BITS
   SYSTEM-CONSTANT-LISTS SYSTEM-VARIABLE-LISTS
   SCRATCH-PAD-VARIABLES FASL-GROUP-FIELDS FASL-OPS 
   FASL-TABLE-PARAMETERS FASL-CONSTANTS FASL-CONSTANT-LISTS FEFH-CONSTANTS 
   FEFHI-INDEXES  
   STACK-GROUP-HEAD-LEADER-QS SG-STATES SPECIAL-PDL-LEADER-QS REG-PDL-LEADER-QS 
   SG-STATE-FIELDS SG-INST-DISPATCHES
   SYSTEM-COMMUNICATION-AREA-QS PAGE-HASH-TABLE-FIELDS 
   Q-FIELDS Q-AREA-SWAP-BITS MICRO-STACK-FIELDS M-FLAGS-FIELDS M-ERROR-SUBSTATUS-FIELDS 
   SPECPDL-FIELDS
   LINEAR-PDL-FIELDS LINEAR-PDL-QS HARDWARE-MEMORY-SIZES 
   DISK-RQ-LEADER-QS DISK-RQ-HWDS DISK-HARDWARE-SYMBOLS UNIBUS-CHANNEL-QS
   UNIBUS-CSR-BITS
   CHAOS-BUFFER-LEADER-QS CHAOS-HARDWARE-SYMBOLS
   ETHER-BUFFER-LEADER-QS ETHER-HARDWARE-SYMBOLS ETHER-REGISTER-OFFSETS
   INSTANCE-DESCRIPTOR-OFFSETS
   METER-EVENTS METER-ENABLES
   ADI-KINDS ADI-STORING-OPTIONS ADI-FIELDS))

;ELEMENTS IN SYSTEM-CONSTANT-LISTS ARE SYMBOLS WHOSE MACLISP AND LISP MACHINE
;VALUES ARE LISTS OF SYMBOLS WHICH SHOULD GET SYSTEM-CONSTANT PROPERTY FOR THE COMPILER.
;NORMALLY SHOULD BE VERY CLOSE TO Q-CORRESPONDING-VARIABLES-LISTS
(cl:defvar SYSTEM-CONSTANT-LISTS '(AREA-LIST Q-CDR-CODES Q-DATA-TYPES Q-HEADER-TYPES
   Q-LISP-CONSTANTS
   ;RTB-RTB-BITS RTB-RTS-BITS RTB-RTO-OPS
   ;RTB-MISC RTM-OPS READTABLE-%%-BITS
   ARRAY-TYPES HEADER-FIELDS ;NOT HEADER-TYPES
   ARG-DESC-FIELDS NUMERIC-ARG-DESC-FIELDS FEF-NAME-PRESENT FEF-SPECIALNESS
   FEF-ARG-SYNTAX FEF-INIT-OPTION FEFHI-FIELDS FEF-DES-DT FEF-QUOTE-STATUS 
   FEF-FUNCTIONAL 
   ARRAY-FIELDS ARRAY-LEADER-FIELDS Q-REGION-BITS
   ARRAY-MISCS ;ARRAY-MISCS SHOULD BE FLUSHED SOMEDAY
   SYSTEM-CONSTANT-LISTS SYSTEM-VARIABLE-LISTS ;SOME THINGS LOOK AT SUBLISTS OF THESE
   ;NOT SCRATCH-PAD-VARIABLES
   ;NOT SCRATCH-PAD-POINTERS SCRATCH-PAD-PARAMETERS SCRATCH-PAD-TEMPS 
   FASL-GROUP-FIELDS FASL-OPS
   FASL-TABLE-PARAMETERS FASL-CONSTANTS FASL-CONSTANT-LISTS FEFH-CONSTANTS
   FEFHI-INDEXES 
   STACK-GROUP-HEAD-LEADER-QS SG-STATES SPECIAL-PDL-LEADER-QS REG-PDL-LEADER-QS 
   SG-STATE-FIELDS SG-INST-DISPATCHES
   SYSTEM-COMMUNICATION-AREA-QS PAGE-HASH-TABLE-FIELDS
   Q-FIELDS Q-AREA-SWAP-BITS MICRO-STACK-FIELDS M-FLAGS-FIELDS M-ERROR-SUBSTATUS-FIELDS 
   LINEAR-PDL-FIELDS LINEAR-PDL-QS HARDWARE-MEMORY-SIZES 
   DISK-RQ-LEADER-QS DISK-RQ-HWDS DISK-HARDWARE-SYMBOLS UNIBUS-CHANNEL-QS
   UNIBUS-CSR-BITS
   CHAOS-BUFFER-LEADER-QS CHAOS-HARDWARE-SYMBOLS
   ETHER-BUFFER-LEADER-QS ETHER-HARDWARE-SYMBOLS ETHER-REGISTER-OFFSETS
   INSTANCE-DESCRIPTOR-OFFSETS
   METER-EVENTS METER-ENABLES A-MEMORY-ARRAY-SYMBOLS
   ADI-KINDS ADI-STORING-OPTIONS ADI-FIELDS))

;LIKE ABOVE BUT GET DECLARED SPECIAL RATHER THAN SYSTEM-CONSTANT
(cl:defvar SYSTEM-VARIABLE-LISTS '(
	A-MEMORY-LOCATION-NAMES M-MEMORY-LOCATION-NAMES 
	IO-STREAM-NAMES LISP-VARIABLES MISC-Q-VARIABLES
))

(cl:defvar IO-STREAM-NAMES '(
	STANDARD-INPUT STANDARD-OUTPUT ERROR-OUTPUT QUERY-IO TERMINAL-IO TRACE-OUTPUT
))

;These get declared special, and get their Maclisp values shipped over
(cl:defvar MISC-Q-VARIABLES '(SYSTEM-CONSTANT-LISTS SYSTEM-VARIABLE-LISTS PRIN1 FOR-CADR
			 COLD-INITIALIZATION-LIST BEFORE-COLD-INITIALIZATION-LIST
			 WARM-INITIALIZATION-LIST
                         ONCE-ONLY-INITIALIZATION-LIST SYSTEM-INITIALIZATION-LIST))

;These get declared special, but don't get sent over.  They get initialized
; some other way, e.g. from a load-time-setq in some compile list, or from special
; code in COLD, or by LISP-REINITIALIZE when the machine is first started.
(cl:defvar LISP-VARIABLES '(BASE IBASE PRINLENGTH PRINLEVEL *NOPOINT *RSET FASLOAD
		       EVALHOOK PACKAGE READTABLE + - *
		       USER-ID LISP-CRASH-LIST SCHEDULER-STACK-GROUP
		       RUBOUT-HANDLER LOCAL-DECLARATIONS STREAM-INPUT-OPERATIONS
		       STREAM-OUTPUT-OPERATIONS %INITIALLY-DISABLE-TRAPPING))

;These get declared SYSTEM-CONSTANT (which is similar to SPECIAL) and get their
; Maclisp values shipped over.
(cl:defvar Q-LISP-CONSTANTS '( PAGE-SIZE SIZE-OF-OB-TBL AREA-LIST Q-DATA-TYPES SITE-NAME
			  SIZE-OF-AREA-ARRAYS LENGTH-OF-ATOM-HEAD 
			  %ADDRESS-SPACE-MAP-BYTE-SIZE %ADDRESS-SPACE-QUANTUM-SIZE
			  ARRAY-ELEMENTS-PER-Q ARRAY-BITS-PER-ELEMENT %FEF-HEADER-LENGTH
			  LAMBDA-LIST-KEYWORDS %LP-CALL-BLOCK-LENGTH 
			  %LP-INITIAL-LOCAL-BLOCK-OFFSET
                          A-MEMORY-VIRTUAL-ADDRESS IO-SPACE-VIRTUAL-ADDRESS
                          UNIBUS-VIRTUAL-ADDRESS A-MEMORY-COUNTER-BLOCK-NAMES))

(cl:defvar HARDWARE-MEMORY-SIZES '(
	SIZE-OF-HARDWARE-CONTROL-MEMORY SIZE-OF-HARDWARE-DISPATCH-MEMORY 
	SIZE-OF-HARDWARE-A-MEMORY SIZE-OF-HARDWARE-M-MEMORY 
	SIZE-OF-HARDWARE-PDL-BUFFER SIZE-OF-HARDWARE-MICRO-STACK 
	SIZE-OF-HARDWARE-LEVEL-1-MAP SIZE-OF-HARDWARE-LEVEL-2-MAP 
	SIZE-OF-HARDWARE-UNIBUS-MAP ))

(cl:defvar LAMBDA-LIST-KEYWORDS '(&OPTIONAL &REST &AUX
			     &SPECIAL &LOCAL
			     &FUNCTIONAL
			     &EVAL &QUOTE &QUOTE-DONTCARE 
			     &DT-DONTCARE &DT-NUMBER &DT-FIXNUM &DT-SYMBOL &DT-ATOM 
			     &DT-LIST &DT-FRAME
			     &FUNCTION-CELL
			     &LIST-OF &BODY	;for DEFMACRO
			     &KEY &ALLOW-OTHER-KEYS
			     ))

;Don't put FUNCTION around the symbols in here -- that means if you
;redefine the function the microcode does not get the new definition,
;which is not what you normally want.  Saying FUNCTION makes it a couple
;microseconds faster to call it.  Not all of these data are actually
;used; check the microcode if you want to know.
(cl:defvar SUPPORT-VECTOR-CONTENTS '((QUOTE PRINT) (QUOTE FEXPR) (QUOTE EXPR) 
				(QUOTE APPLY-LAMBDA) (QUOTE EQUAL) (QUOTE PACKAGE)
				(QUOTE EXPT-HARD) (QUOTE NUMERIC-ONE-ARGUMENT)
				(QUOTE NUMERIC-TWO-ARGUMENTS) (QUOTE "unbound")))

(cl:defvar CONSTANTS-PAGE '(NIL T 0 1 2))		;CONTENTS OF CONSTANTS PAGE

(cl:defvar SCRATCH-PAD-VARIABLES '(SCRATCH-PAD-POINTERS SCRATCH-PAD-PARAMETER-OFFSET 
  SCRATCH-PAD-PARAMETERS SCRATCH-PAD-TEMP-OFFSET SCRATCH-PAD-TEMPS))

(cl:defvar SCRATCH-PAD-POINTERS '(INITIAL-TOP-LEVEL-FUNCTION ERROR-HANDLER-STACK-GROUP 
	CURRENT-STACK-GROUP INITIAL-STACK-GROUP	LAST-ARRAY-ELEMENT-ACCESSED))

(cl:defvar SCRATCH-PAD-PARAMETER-OFFSET 20)

;(COND ((> (LENGTH SCRATCH-PAD-POINTERS) SCRATCH-PAD-PARAMETER-OFFSET) 
;	(BARF 'BARF 'SCRACH-PAD-PARAMETER-OFFSET 'BARF)))

(cl:defvar SCRATCH-PAD-PARAMETERS '(ERROR-TRAP-IN-PROGRESS DEFAULT-CONS-AREA 
	BIND-CONS-AREA LAST-ARRAY-ACCESSED-TYPE LAST-ARRAY-ACCESSED-INDEX 
	INVOKE-MODE INVISIBLE-MODE 
	CDR-ATOM-MODE CAR-ATOM-MODE ACTIVE-MICRO-CODE-ENTRIES))

(cl:defvar SCRATCH-PAD-TEMP-OFFSET 20)

;(COND ((> (LENGTH SCRATCH-PAD-PARAMETERS) SCRATCH-PAD-TEMP-OFFSET)
;	(BARF 'BARF 'SCRATCH-PAD-TEMP-OFFSET 'BARF)))

(cl:defvar SCRATCH-PAD-TEMPS '(LAST-INSTRUCTION TEMP-TRAP-CODE LOCAL-BLOCK-OFFSET 
	SCRATCH-/#-ARGS-LOADED TEMP-PC SPECIALS-IN-LAST-BLOCK-SLOW-ENTERED))


;(DEFUN TTYPRINT (X)
;  (PROG (^R ^W)
;	(PRINT X)))

;FUNCTIONS FOR HAND-TESTING THINGS
;(DEFUN TML NIL (MSLAP 'MESA-CODE-AREA MS-PROG 'COLD))

;(DEFUN TUL NIL (ULAP 'MICRO-COMPILED-PROGRAM MC-PROG 'COLD))

;(DEFUN TL (MODE) (COND ((EQ MODE 'QFASL)
;			(FASD-INITIALIZE)
;			(SETQ LAP-DEBUG NIL)))
;		 (QLAPP QCMP-OUTPUT MODE))

;#M (COND ((NULL (GETL 'SPECIAL '(FEXPR FSUBR)))
;(DEFUN SPECIAL FEXPR (L) 
;       (MAPCAR (FUNCTION (LAMBDA (X) (PUTPROP X T 'SPECIAL)))
;	       L))
;))

;(DEFUN SPECIAL-LIST (X) (EVAL (CONS 'SPECIAL (SYMEVAL X))))

;; No initial initializations
(cl:defvar COLD-INITIALIZATION-LIST cl:NIL)
(cl:defvar BEFORE-COLD-INITIALIZATION-LIST cl:NIL)
(cl:defvar WARM-INITIALIZATION-LIST cl:NIL)
(cl:defvar ONCE-ONLY-INITIALIZATION-LIST cl:NIL)
(cl:defvar SYSTEM-INITIALIZATION-LIST cl:NIL)

;--Q--
;Q FCTN SPECIALS
;(cl:defun LOADUP-FINALIZE NIL
;   (MAPC (FUNCTION SPECIAL-LIST) SYSTEM-CONSTANT-LISTS)
;   (MAPC (FUNCTION SPECIAL-LIST) SYSTEM-VARIABLE-LISTS))

;;; The documentation that used to be here has been moved to LMDOC;FASLD >

(cl:declaim (cl:SPECIAL FASL-TABLE FASL-GROUP-LENGTH FASL-GROUP-FLAG FASL-RETURN-FLAG))

(cl:defvar FASL-GROUP-FIELD-VALUES '(%FASL-GROUP-CHECK 100000 
   %FASL-GROUP-FLAG 40000 %FASL-GROUP-LENGTH 37700 
   FASL-GROUP-LENGTH-SHIFT -6 %FASL-GROUP-TYPE 77 
  %%FASL-GROUP-CHECK 2001 %%FASL-GROUP-FLAG 1701 %%FASL-GROUP-LENGTH 0610 
  %%FASL-GROUP-TYPE 0006))

(cl:defvar FASL-GROUP-FIELDS (GET-ALTERNATE FASL-GROUP-FIELD-VALUES))
(ASSIGN-ALTERNATE FASL-GROUP-FIELD-VALUES)

(cl:defvar FASL-OPS '(FASL-OP-ERR FASL-OP-NOOP FASL-OP-INDEX FASL-OP-SYMBOL FASL-OP-LIST 
  FASL-OP-TEMP-LIST FASL-OP-FIXED FASL-OP-FLOAT 
  FASL-OP-ARRAY FASL-OP-EVAL FASL-OP-MOVE 
  FASL-OP-FRAME FASL-OP-LIST-COMPONENT FASL-OP-ARRAY-PUSH FASL-OP-STOREIN-SYMBOL-VALUE 
  FASL-OP-STOREIN-FUNCTION-CELL FASL-OP-STOREIN-PROPERTY-CELL 
  FASL-OP-FETCH-SYMBOL-VALUE FASL-OP-FETCH-FUNCTION-CELL 
  FASL-OP-FETCH-PROPERTY-CELL FASL-OP-APPLY FASL-OP-END-OF-WHACK 
  FASL-OP-END-OF-FILE FASL-OP-SOAK FASL-OP-FUNCTION-HEADER FASL-OP-FUNCTION-END 
  FASL-OP-UNUSED8 FASL-OP-UNUSED9 FASL-OP-UNUSED10 
  FASL-OP-UNUSED11 FASL-OP-UNUSED12 FASL-OP-QUOTE-POINTER FASL-OP-S-V-CELL 
  FASL-OP-FUNCELL FASL-OP-CONST-PAGE FASL-OP-SET-PARAMETER FASL-OP-INITIALIZE-ARRAY 
  FASL-OP-UNUSED FASL-OP-UNUSED1 FASL-OP-UNUSED2 
  FASL-OP-UNUSED3 FASL-OP-UNUSED4 FASL-OP-UNUSED5  
  FASL-OP-UNUSED6 FASL-OP-STRING FASL-OP-STOREIN-ARRAY-LEADER 
  FASL-OP-INITIALIZE-NUMERIC-ARRAY FASL-OP-REMOTE-VARIABLE FASL-OP-PACKAGE-SYMBOL
  FASL-OP-EVAL1 FASL-OP-FILE-PROPERTY-LIST FASL-OP-REL-FILE FASL-OP-RATIONAL
))
(ASSIGN-VALUES FASL-OPS 0)

(cl:defvar FASL-TABLE-PARAMETERS '(FASL-NIL FASL-EVALED-VALUE FASL-TEM1 FASL-TEM2 FASL-TEM3 
    FASL-SYMBOL-HEAD-AREA 
    FASL-SYMBOL-STRING-AREA FASL-OBARRAY-POINTER FASL-ARRAY-AREA 
    FASL-FRAME-AREA FASL-LIST-AREA FASL-TEMP-LIST-AREA 
    FASL-UNUSED FASL-UNUSED2 FASL-UNUSED3 
    FASL-UNUSED6 FASL-UNUSED4 FASL-UNUSED5))
(ASSIGN-VALUES FASL-TABLE-PARAMETERS 0)

(cl:defvar FASL-CONSTANTS '(LENGTH-OF-FASL-TABLE FASL-TABLE-WORKING-OFFSET))

(cl:defvar FASL-CONSTANT-LISTS '(FASL-GROUP-FIELDS FASL-OPS FASL-TABLE-PARAMETERS 
    FASL-CONSTANTS))

(cl:defvar FASL-TABLE-WORKING-OFFSET 40)

;(COND ((> (LENGTH FASL-TABLE-PARAMETERS) FASL-TABLE-WORKING-OFFSET)
;	(IOC V)
;	(PRINT 'FASL-TABLE-PARAMETER-OVERFLOW)))

;PEOPLE CALL THIS YOU KNOW, DON'T GO RANDOMLY DELETING IT!
(cl:defun FASL-ASSIGN-VARIABLE-VALUES ()
 ())  ;I GUESS WHAT THIS USED TO DO IS DONE AT TOP LEVEL IN THIS FILE