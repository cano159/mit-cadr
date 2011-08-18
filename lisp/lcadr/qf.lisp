;;; PHONEY -*-LISP-*- MACHINE MICROCODE -- CADR VERSION
;	** (c) Copyright 1980 Massachusetts Institute of Technology **

;2/4/79 MODIFIED FOR CHANGES TO MAP-STATUS-CODE IN PAGE MAP 

;LISP MACHINE Q'S ARE REPRESENTED AS MACLISP FIXNUMS, CONTAINING
;THE SAME FIELDS.  EXCEPT, -1 MEANS PAGE INACCESSIBLE, AND AT SOME
;LEVELS -2 MEANS IN PDL BUFFER.

(DECLARE (FIXNUM ADR VADR PADR HASH LEN HASH1 DATA I J K M N Q MUM PHT-ADR SIZE-OF-PAGE-TABLE))
(DECLARE (SETQ RUN-IN-MACLISP-SWITCH T))	;Inhibit some error messages

(INCLUDE |LMDOC;.COMPL PRELUD|);DEFINE DEFMACRO, `, LET, ETC.
(IF-FOR-MACLISP
 (INCLUDE |LMCONS;QFMAC >|) )

;Really wants to be a bignum LSH.  On LISPM, LSH doesnt win for bignums, ASH does.
; In MACLISP, LSH wins sufficiently.
(DEFMACRO CC-SHIFT (QUAN AMT)
  `(#Q ASH #M LSH ,QUAN ,AMT))

;ALSO SEE FIXNUM DECLARATIONS BELOW WHEN THESE ARE CHANGED.
;(DEFMACRO PHYS-MEM-READ (ADR)     ;THESE ARE NOW FUNCTIONS IN CC
;	  `(DBG-READ-XBUS ,ADR))

;(DEFMACRO PHYS-MEM-WRITE (ADR DATA)
;	  `(DBG-WRITE-XBUS ,ADR ,DATA))

;ROUTINES FROM CC FOR HACKING MICRO MACHINE

;(DECLARE (FIXNUM (CC-REGISTER-EXAMINE FIXNUM))	;NOT DECLARED FIXNUM WHEN COMPILED
;	 (FIXNUM (CC-REGISTER-DEPOSIT FIXNUM FIXNUM))
;	 (FIXNUM (CC-SYMBOLIC-EXAMINE-REGISTER NOTYPE)))

;;; MEMORY INTERFACE AND PAGING STUFF

(DECLARE (FIXNUM (PHYS-MEM-READ FIXNUM))	;PHYSICAL MEMORY READ
	 (NOTYPE (PHYS-MEM-WRITE FIXNUM FIXNUM)) ;PHYSICAL MEMORY WRITE
	 (FIXNUM (QF-VIRTUAL-MEM-READ FIXNUM))
	 (FIXNUM (QF-VIRTUAL-MEM-WRITE FIXNUM FIXNUM))
	 (FIXNUM (QF-VIRTUAL-MEM-MAP FIXNUM NOTYPE)) ;GIVEN VMA RETURNS PMA 
						;OR -1 FOR INACCESSIBLE 
						;OR -2 FOR IN PDL BUFFER.
						;SECOND ARG IS T IF WRITE CYCLE IS INTENDED
	 (FIXNUM (QF-PAGE-HASH-TABLE-LOOKUP FIXNUM))  ;GIVEN VMA, RETURNS PHYS ADR OF PHT1
						      ; ENTRY OR -1 FOR NOT FOUND.
	 (NOTYPE (QF-VIRT-ADR-OF-PHYS-ADR))	;linearly searches PHT for phys adr.
	 (NOTYPE (QF-PAGE-HASH-TABLE-DELETE FIXNUM FIXNUM))  ;GIVEN VMA, DELETE IT FROM HASH
						;TABLE, READJUSTING THINGS AS NECC.
						;RETURN T IF DELETED, NIL IF NOT FOUND
	 (FIXNUM (QF-COMPUTE-PAGE-HASH FIXNUM)) ;GIVEN VMA, RETURN INITIAL HASH ADR RELATIVE
						;TO HASH TABLE ORIGIN.
	 (FIXNUM (QF-FINDCORE))			;CALL TO OBTAIN A FREE CORE PAGE IN CONS.
						; SWAPS ONE OUT IF NECC, ADJUSTING HASH
						; TBL, REAL MACHINE'S MAP, ETC.  RETURNS
						; PHYSICAL PAGE NUMBER.
	 (FIXNUM (QF-GET-DISK-ADR FIXNUM))
	 (NOTYPE (QF-SWAP-IN FIXNUM))		;DO EVERYTHING NEEDED TO BE SWAPPED IN
	 (FIXNUM (QF-VIRTUAL-MEM-PDL-BUF-ADR FIXNUM))
	 (FIXNUM (QF-MEM-READ FIXNUM))		;BARF IF INACCESSIBLE
	 (FIXNUM (QF-MEM-READ-DISK-COPY FIXNUM));  Read Virt Adr from disk even if swapped in.
	 (FIXNUM (QF-MEM-WRITE FIXNUM FIXNUM)))	;..

(DECLARE (SPECIAL 
;		  QF-VIRTUAL-ADDR-KNOWN-ADDR QF-VIRTUAL-ADDR-KNOWN-MAP
;		  QF-VIRTUAL-ADDR-KNOWN-PHT1 QF-VIRTUAL-ADDR-KNOWN-PHT2 
		  QF-AREA-ORIGIN-CACHE QF-PAGE-PARTITION-CACHE QF-FINDCORE-TRACE-SWITCH
		  QF-SWAP-IN-LOOP-CHECK QF-PAGE-HASH-TABLE-EXTRA-CHECKING-FLAG))
(SETQ QF-PAGE-HASH-TABLE-EXTRA-CHECKING-FLAG NIL
      QF-FINDCORE-TRACE-SWITCH NIL)

(DEFUN QF-CLEAR-CACHE (EVERYTHINGP)	;CALL ON START UP AND WHENEVER MACHINE HAS BEEN RUN
					;ARG IS T ON START UP AND AFTER COLD LOAD
  (COND (EVERYTHINGP
	 (SETQ QF-AREA-ORIGIN-CACHE NIL)
	 (REMPROP 'QF-HASH-RELOAD-POINTER 'QF-HASH-RELOAD-POINTER)
	 (ALLREMPROP 'REAL-MACHINE-ATOM-HEADER-POINTER)
	 (ALLREMPROP 'REAL-MACHINE-PACKAGE-POINTER)))
   (SETQ QF-PAGE-PARTITION-CACHE NIL)
)

(DECLARE (SPECIAL PHT-ADDR SIZE-OF-PAGE-TABLE))
(SETQ PHT-ADDR (* 5 400))

(DEFUN QF-VIRTUAL-MEM-READ (VADR)
  ((LAMBDA (PADR)
	(COND ((= PADR -1) PADR)	;INACCESSIBLE
	      ((= PADR -2)		;IN PDL BUFFER
	       (CC-REGISTER-EXAMINE (QF-VIRTUAL-MEM-PDL-BUF-ADR VADR)))
	      ((PHYS-MEM-READ PADR))))
   (QF-VIRTUAL-MEM-MAP VADR NIL)))

(DEFUN QF-VIRTUAL-MEM-WRITE (VADR DATA)		;NOTE DOESN'T RESPECT READ ONLY, RWF
  ((LAMBDA (PADR)
	(COND ((= PADR -1) PADR)	;INACCESSIBLE
	      ((= PADR -2)		;IN PDL BUFFER
	       (CC-REGISTER-DEPOSIT (QF-VIRTUAL-MEM-PDL-BUF-ADR VADR) DATA))
	      (T (PHYS-MEM-WRITE PADR DATA)
		 DATA)))
   (QF-VIRTUAL-MEM-MAP VADR T)))

(DEFUN QF-VIRTUAL-MEM-PDL-BUF-ADR (ADR)
  (+ RAPBO
     (LOGAND 1777
	     (+ (- ADR (CC-SYMBOLIC-EXAMINE-REGISTER 'A-PDL-BUFFER-VIRTUAL-ADDRESS))
	        (CC-SYMBOLIC-EXAMINE-REGISTER 'A-PDL-BUFFER-HEAD)))))

(DEFUN QF-PAGE-HASH-TABLE-LOOKUP (ADR)	;RETURNS -1 OR PHYSICAL MEM ADR OF PHT1 WD
 (SETQ ADR (QF-POINTER ADR))		; OF HASH-TBL ENTRY FOR ADR
 (DO ((PHT-MASK (- SIZE-OF-PAGE-TABLE 2))
      (HASH (LOGXOR (LOGLDB 1612 ADR) (LOGAND 777774 (LOGLDB 0622 ADR))) (+ HASH 2))
      (PHT1)
      (COUNT (LSH SIZE-OF-PAGE-TABLE -1) (1- COUNT)))
     ((= COUNT 0) -1)     ;INACESSIBLE (SHOULD NEVER HAPPEN, BUT AT LEAST DONT GET
			  ; INTO INFINITE LOOP IF HASH TABLE GETS OVER-FULL)
   (DECLARE (FIXNUM PHT-MASK HASH PHT1 PHT2 COUNT))
   (SETQ HASH (LOGAND HASH PHT-MASK))
   (SETQ PHT1 (PHYS-MEM-READ (+ PHT-ADDR HASH)))
   (COND ((= 0 (LOGAND 100 PHT1))	;NO VALID BIT
	    (RETURN -1))		;NOT FOUND
         ((= 0 (LOGAND 77777400 (LOGXOR ADR PHT1)))  ;ADDRESS MATCH
	    (RETURN (+ PHT-ADDR HASH))))))	;FOUND IT

;Linearly scan page hash table looking for info on given phys-adr.
(DEFUN QF-VIRT-ADR-OF-PHYS-ADR (PHYS-ADR)
  (DO ((PHYS-PAGE (LDB 1020 PHYS-ADR))
       (HASH-LOCN 0 (+ HASH-LOCN 2))
       (PHT1) (PHT2)
       (COUNT (LSH SIZE-OF-PAGE-TABLE -1) (1- COUNT)))
      ((= COUNT 0) NIL)
    (COND ((AND (BIT-TEST 100 (SETQ PHT1 (PHYS-MEM-READ (+ PHT-ADDR HASH-LOCN))))
		(= PHYS-PAGE (LDB %%PHT2-PHYSICAL-PAGE-NUMBER
				  (SETQ PHT2 (PHYS-MEM-READ
					       (1+ (+ PHT-ADDR HASH-LOCN)))))))
	   (RETURN (DPB (LDB %%PHT1-VIRTUAL-PAGE-NUMBER PHT1) 1020 PHYS-ADR))))))
	   
(DEFUN QF-PAGE-HASH-TABLE-DELETE (ADR HOLE-POINTER)
  (PROG (LEAD-POINTER LEAD-POINTER-HASH-ADR LEAD-POINTER-VIRT-ADR
	 LIM PHT1 PHT2 PPDP MOVED-POINTER)
	(DECLARE (FIXNUM LEAD-POINTER LEAD-POINTER-HASH-ADR LEAD-POINTER-VIRT-ADR 
			 LIM PHT1 PHT2 MOVED-POINTER PPDP))
	(SETQ LIM (+ PHT-ADDR SIZE-OF-PAGE-TABLE -2))		;POINTS TO LAST VALID ENTRY
   L1	(PHYS-MEM-WRITE HOLE-POINTER (QF-MAKE-Q 0 DTP-FIX))	;FLUSH GUY FROM TABLE
	(SETQ LEAD-POINTER HOLE-POINTER)
   L2	(SETQ LEAD-POINTER (COND ((< LEAD-POINTER LIM) (+ LEAD-POINTER 2))
	 			 (T PHT-ADDR)))
	(SETQ PHT1 (PHYS-MEM-READ LEAD-POINTER))
	(COND ((= 0 (LOGAND 100 PHT1))
	       (OR QF-PAGE-HASH-TABLE-EXTRA-CHECKING-FLAG (RETURN T))
	       (AND (= 0 (CC-CHECK-PAGE-HASH-TABLE-ACCESSIBILITY)) (RETURN T))
	       (PRINT (LIST 'QF-PAGE-HASH-TABLE-DELETE-SCREW ADR LEAD-POINTER HOLE-POINTER
			    MOVED-POINTER))
	       (BREAK 'QF-PAGE-HASH-TABLE-DELETE-SCREW T)
	       (RETURN T)))				;BLANK ENTRY, THROUGH
	(SETQ LEAD-POINTER-VIRT-ADR (LOGAND PHT1 77777400))
	(SETQ LEAD-POINTER-HASH-ADR
	      (COND ((NOT (= LEAD-POINTER-VIRT-ADR 77777400))
		     (+ PHT-ADDR (QF-COMPUTE-PAGE-HASH LEAD-POINTER-VIRT-ADR)))
		    (T HOLE-POINTER)))			;DUMMY ALWAYS HASHES TO HOLE ADDR
	(COND ((< LEAD-POINTER LEAD-POINTER-HASH-ADR) (GO L4))) ;WRAPAROUND CASE
	(COND ((OR (> LEAD-POINTER-HASH-ADR HOLE-POINTER)
		   (< LEAD-POINTER HOLE-POINTER))
	       (GO L2)))				;JUMP IF SHOULDN'T BE WHERE HOLE IS
   L6	(PHYS-MEM-WRITE HOLE-POINTER PHT1)		;SHOULD BE WHERE HOLE IS, MOVE IT 
	(PHYS-MEM-WRITE (1+ HOLE-POINTER) (SETQ PHT2 (PHYS-MEM-READ (1+ LEAD-POINTER))))
	(SETQ PPDP (+ (LOGLDB-FROM-FIXNUM %%PHT2-PHYSICAL-PAGE-NUMBER PHT2)
		      (QF-INITIAL-AREA-ORIGIN 'PHYSICAL-PAGE-DATA)))
	(PHYS-MEM-WRITE PPDP (LOGDPB-INTO-FIXNUM (- HOLE-POINTER PHT-ADDR) 0020
						 (PHYS-MEM-READ PPDP)))
	(SETQ MOVED-POINTER HOLE-POINTER)		;FOR DEBUGGING, WHERE THING MOVED TO
	(SETQ HOLE-POINTER LEAD-POINTER)
	(GO L1)
   L4	(COND ((OR (<= LEAD-POINTER-HASH-ADR HOLE-POINTER)
		   (>= LEAD-POINTER HOLE-POINTER))
	       (GO L6)))				;JUMP IF SHOULD BE WHERE HOLE IS
	(GO L2)
))

(DEFUN QF-COMPUTE-PAGE-HASH (ADR)
    (LOGAND (- SIZE-OF-PAGE-TABLE 2)
	    (LOGXOR (LOGLDB 1612 ADR) (LOGAND 777774 (LOGLDB 0622 ADR)))))

(DEFUN QF-VIRTUAL-MEM-MAP (ADR WRITE-CYCLE)
 (SETQ ADR (QF-POINTER ADR))		;FLUSH DATA TYPE ETC.
 (DO ((PHT-MASK (- SIZE-OF-PAGE-TABLE 2))
      (HASH (LOGXOR (LOGLDB 1612 ADR) (LOGAND 777774 (LOGLDB 0622 ADR))) (+ HASH 2))
      (PHT1)
      (PHT2)
      (TEM)(STS)
      (COUNT (LSH SIZE-OF-PAGE-TABLE -1) (1- COUNT)))
     ((= COUNT 0) -1)					;INACCESSIBLE
     (DECLARE (FIXNUM PHT-MASK HASH PHT1 PHT2 COUNT TEM STS))
     (SETQ HASH (LOGAND HASH PHT-MASK))
     (SETQ PHT1 (PHYS-MEM-READ (+ PHT-ADDR HASH)))
     (COND ((= 0 (LOGAND 100 PHT1))			;NO VALID BIT
	    (RETURN -1))				;INACCESSIBLE
	   ((= 0 (LOGAND 77777400 (LOGXOR ADR PHT1)))	;ADDRESS MATCH
	    (SETQ STS (LOGAND 7 PHT1))			;ISOLATE SWAP STATUS CODE
	    (COND ((OR (= STS 0)			;UNUSED ENTRY
		       (= STS 3)			;UNUSED CODES
		       (= STS 6)
		       (= STS 7))
		   (ERROR 'BAD-PAGE-HASH-ENTRY-AT-ADR HASH 'FAIL-ACT)))
	    (SETQ PHT2 (PHYS-MEM-READ (+ PHT-ADDR HASH 1)))	;IN CORE, GET ADDRESS
	    (COND ((AND (= 5 (LOGLDB-FROM-FIXNUM
			       %%PHT2-MAP-STATUS-CODE PHT2))  ;MAY BE IN PDL-BUFFER
			(NOT (< ADR (SETQ TEM (QF-POINTER
					       (CC-SYMBOLIC-EXAMINE-REGISTER 
						'A-PDL-BUFFER-VIRTUAL-ADDRESS)))))
			(<= ADR (+ TEM (CC-SYMBOLIC-EXAMINE-REGISTER 'PP))))
		   (RETURN -2)))			;IN PDL-BUFFER
;IF DOING A WRITE-CYCLE INTO A PAGE, SET PHT1-MODIFIED BIT
;THIS HOPEFULLY ASSURES PAGE WILL GET WRITTEN ON DISK IF IT GETS SWAPPED OUT
;EVEN IF THE ACCESS IS NOT READ/WRITE.
	    (COND (WRITE-CYCLE
		   (PHYS-MEM-WRITE (+ PHT-ADDR HASH)
				   (LOGDPB-INTO-FIXNUM 1 %%PHT1-MODIFIED-BIT PHT1))))
	    (RETURN (+ (LSH (LOGLDB-FROM-FIXNUM %%PHT2-PHYSICAL-PAGE-NUMBER PHT2) 8)
		       (LOGAND 377 ADR))))))  
)

(DEFUN QF-FINDCORE NIL	;CALL TO OBTAIN FREE PAGE OF CONS MEMORY. SWAP ONE OUT IF NECC, ETC.
  (DECLARE (FIXNUM PTR LIM PHT1 PHT2 TEM))
  (PROG (PTR LIM PHT1 PHT2 TEM FLAG)
	(SETQ LIM (+ PHT-ADDR SIZE-OF-PAGE-TABLE -2))	;POINTS AT HIGHEST ENTRY
	(SETQ PTR PHT-ADDR)		;LOOK FOR FLUSHABLE FROB FIRST
   L1	(SETQ PHT1 (PHYS-MEM-READ PTR))
	(SETQ TEM (LOGLDB-FROM-FIXNUM %%PHT1-SWAP-STATUS-CODE PHT1))	;SWAP STATUS
	(COND ((= TEM %PHT-SWAP-STATUS-FLUSHABLE) (GO CF)))	;FLUSHABLE
	(COND ((NOT (= PTR LIM)) (SETQ PTR (+ 2 PTR)) (GO L1)))
	(SETQ PTR (COND ((GET 'QF-HASH-RELOAD-POINTER 'QF-HASH-RELOAD-POINTER))
		        (T PHT-ADDR)))	;FLUSH SOMETHING RANDOM
   L2	(SETQ PHT1 (PHYS-MEM-READ PTR))
	(SETQ TEM (LOGLDB-FROM-FIXNUM %%PHT1-SWAP-STATUS-CODE PHT1))
	(COND ((OR (= TEM %PHT-SWAP-STATUS-NORMAL)
		   (= TEM %PHT-SWAP-STATUS-AGE-TRAP))
	       (GO CF)))
	(COND ((= PTR LIM)
	       (COND (FLAG (ERROR 'QF-FINDCORE 'NOTHING-TO-SWAP-OUT 'FAIL-ACT))
		     (T (SETQ FLAG T)
			(SETQ PTR PHT-ADDR))))
	      (T (SETQ PTR (+ 2 PTR))))
	(GO L2)
   CF	(PUTPROP 'QF-HASH-RELOAD-POINTER PTR 'QF-HASH-RELOAD-POINTER)
	(SETQ PHT2 (PHYS-MEM-READ (1+ PTR)))
	(AND QF-FINDCORE-TRACE-SWITCH
	     (PRINT (LIST 'QF-FINDCORE 'PTR PTR 'PHT1 PHT1 'PHT2 PHT2)))
	(SETQ TEM (LOGLDB-FROM-FIXNUM %%PHT2-MAP-STATUS-CODE PHT2))
	(COND ((OR (= TEM %PHT-MAP-STATUS-READ-WRITE)
		   (NOT (ZEROP (LOGLDB %%PHT1-MODIFIED-BIT PHT1))))
	       (CC-DISK-WRITE (QF-GET-DISK-ADR
			       (LOGLDB-FROM-FIXNUM %%PHT1-VIRTUAL-PAGE-NUMBER PHT1))
			      (LOGLDB-FROM-FIXNUM %%PHT2-PHYSICAL-PAGE-NUMBER PHT2)
			      1)))	;NUMBER PAGES
	(COND ((NULL (QF-PAGE-HASH-TABLE-DELETE (LOGAND 77777400 PHT1) PTR))
	       (ERROR 'QF-FINDCORE 'HASH-SCREWUP 'FAIL-ACT)))	
	;DELETE FROM REAL MACHINE'S MAP
	(COND ((= (SETQ TEM (CC-REGISTER-EXAMINE (+ RAM1O (LOGLDB-FROM-FIXNUM 1513 PHT1))))
		   37)
		(GO X)))	;LVL 1 MAP NOT SET, OK
	(SETQ TEM (+ (CC-SHIFT TEM 5)
		     (LOGLDB-FROM-FIXNUM 0805 PHT1)
		     RAM2O))
	(CC-REGISTER-DEPOSIT TEM 0)		; CHANGE TO MAP NOT SET UP (ZERO)
    X	(RETURN (LOGLDB-FROM-FIXNUM %%PHT2-PHYSICAL-PAGE-NUMBER PHT2))
))

(SETQ QF-SWAP-IN-LOOP-CHECK NIL)

;SWAP IN PAGE AT ADR
(DEFUN QF-SWAP-IN (ADR)
  (SETQ ADR (QF-POINTER ADR))				;FLUSH DATA TYPE ETC.
  (AND QF-SWAP-IN-LOOP-CHECK
       (ERROR ADR '|QF-SWAP-IN INVOKED RECURSIVELY| 'FAIL-ACT))
  (OR (< (QF-PAGE-HASH-TABLE-LOOKUP ADR) 0)
      (ERROR ADR '|ALREADY SWAPPED IN - QF-SWAP-IN| 'FAIL-ACT))
  (PROG (PHYS-PAGE REGION-NUMBER ACCESS-STATUS-AND-META-BITS QF-SWAP-IN-LOOP-CHECK)
    (DECLARE (FIXNUM PHYS-PAGE REGION-NUMBER ACCESS-STATUS-AND-META-BITS))
    (SETQ QF-SWAP-IN-LOOP-CHECK T)
    (SETQ REGION-NUMBER (QF-REGION-NUMBER-OF-POINTER ADR))
    (SETQ ACCESS-STATUS-AND-META-BITS
	  (LOGLDB-FROM-FIXNUM %%REGION-MAP-BITS
			      (PHYS-MEM-READ (+ REGION-NUMBER
						(QF-INITIAL-AREA-ORIGIN 
						 'REGION-BITS)))))
    (SETQ PHYS-PAGE (QF-FINDCORE))
    (CC-DISK-READ (QF-GET-DISK-ADR (LOGLDB-FROM-FIXNUM %%PHT1-VIRTUAL-PAGE-NUMBER ADR))
		  PHYS-PAGE
		  1)
    (DO ((PHT-MASK (- SIZE-OF-PAGE-TABLE 2))
	 (HASH (LOGXOR (LOGLDB 1612 ADR) (LOGAND 777774 (LOGLDB 0622 ADR))) (+ HASH 2))
	 (PHT1)
	 (COUNT (LSH SIZE-OF-PAGE-TABLE -1) (1- COUNT)))
	((= COUNT 0)
	 (ERROR 'QF-SWAP-IN 'PAGE-HASH-TABLE-FULL 'FAIL-ACT)) ;UGH FINDCORE SHOULD HAVE DELETED
      (DECLARE (FIXNUM PHT-MASK HASH PHT1 PHT2 COUNT))
      (SETQ HASH (LOGAND HASH PHT-MASK))
      (SETQ PHT1 (PHYS-MEM-READ (+ PHT-ADDR HASH)))
      (COND ((= 0 (LOGAND 100 PHT1))			;FOUND HOLE TO PUT NEW PHTE IN
	     (PHYS-MEM-WRITE (+ PHT-ADDR HASH)
		     (QF-MAKE-Q (+ 101 (LOGAND ADR 77777400)) DTP-FIX))
	     (PHYS-MEM-WRITE (+ PHT-ADDR HASH 1)
		     (QF-MAKE-Q (LOGDPB-INTO-FIXNUM ACCESS-STATUS-AND-META-BITS 
					%%PHT2-ACCESS-STATUS-AND-META-BITS 
				  (LOGDPB-INTO-FIXNUM PHYS-PAGE %%PHT2-PHYSICAL-PAGE-NUMBER
				        0))
				DTP-FIX))
	     (PHYS-MEM-WRITE (+ PHYS-PAGE (QF-INITIAL-AREA-ORIGIN 'PHYSICAL-PAGE-DATA))
			     (+ (CC-SHIFT REGION-NUMBER 16.) HASH))
	     (OR QF-PAGE-HASH-TABLE-EXTRA-CHECKING-FLAG (RETURN T))
	     (AND (= 0 (CC-CHECK-PAGE-HASH-TABLE-ACCESSIBILITY)) (RETURN T))
	     (PRINT (LIST 'QF-SWAP-IN-SCREW ADR HASH COUNT))
	     (BREAK 'QF-SWAP-IN-SCREW T)
	     (RETURN T)))))
;  (SETQ QF-VIRTUAL-ADDR-KNOWN-ADDR -1)			;FORGET OUR COPY OF THE MAP
)

(DEFUN QF-GET-DISK-ADR (VIRTUAL-PAGE-NUMBER)
  (OR QF-PAGE-PARTITION-CACHE
      (LET ((A-DISK-OFFSET (CC-SYMBOLIC-EXAMINE-REGISTER 'A-DISK-OFFSET)) ;UCODE SHOULD HAVE SET THIS UP
	    (A-VERSION (QF-POINTER (CC-SYMBOLIC-EXAMINE-REGISTER 'A-VERSION)))
	    (SYMBOL-VERSION (CC-LOOKUP-NAME 'VERSION-NUMBER)))
	(COND ((NOT (= A-VERSION SYMBOL-VERSION))
	       (FORMAT T "~&Microcode ~D is running but you have the symbols for ~D;
   proceeding will probably destroy the core image.  Proceed anyway? "
		       A-VERSION SYMBOL-VERSION)
	       (OR (Y-OR-N-P) (BREAK COUGH-AND-DIE))))
	(AND (< A-VERSION 627.) (SETQ A-DISK-OFFSET (// A-DISK-OFFSET 400)))
	(SETQ QF-PAGE-PARTITION-CACHE A-DISK-OFFSET)))
  (+ VIRTUAL-PAGE-NUMBER QF-PAGE-PARTITION-CACHE))

;THIS READS ANY KIND OF MEMORY WHETHER OR NOT IT IS SWAPPED OUT
(DEFUN QF-MEM-READ (ADR)
  (PROG (DATA)
    (DECLARE (FIXNUM DATA))
    (SETQ DATA (QF-VIRTUAL-MEM-READ ADR))
    (COND ((< DATA 0)
	   (QF-SWAP-IN ADR)
	   (SETQ DATA (QF-VIRTUAL-MEM-READ ADR))))
    (AND (< DATA 0)
	 (ERROR 'QF-MEM-READ-INACCESSIBLE ADR 'FAIL-ACT))
    (RETURN DATA)))

;return disk contents whether swapped in or not.
(DEFUN QF-MEM-READ-DISK-COPY (ADR)
  (PROG (DATA)
	(DECLARE (FIXNUM DATA))
	(CC-DISK-INIT)
	(CC-DISK-WRITE 1 CC-DISK-LOWCORE 1)		;Save on block 1
	(CC-DISK-READ (QF-GET-DISK-ADR (LOGLDB-FROM-FIXNUM %%PHT1-VIRTUAL-PAGE-NUMBER ADR))
		      CC-DISK-LOWCORE
		      1)
	(SETQ DATA (PHYS-MEM-READ (DPB CC-DISK-LOWCORE %%PHT1-VIRTUAL-PAGE-NUMBER ADR)))
	(CC-DISK-READ 1 CC-DISK-LOWCORE 1)		;Restore saved core
	(RETURN DATA)
	))

(DEFUN QF-MEM-WRITE (ADR DATA)
  (COND ((< (QF-VIRTUAL-MEM-WRITE ADR DATA) 0)
	 (QF-SWAP-IN ADR)
	 (AND (< (QF-VIRTUAL-MEM-WRITE ADR DATA) 0)
	      (ERROR 'QF-MEM-WRITE-INACCESSIBLE ADR 'FAIL-ACT)))))

(DEFUN QF-AREA-NUMBER-OF-POINTER (PNTR)
  (DO ((REGION (QF-REGION-NUMBER-OF-POINTER PNTR)
	       (QF-POINTER (QF-MEM-READ (+ REGION-LIST-THREAD REGION))))
       (REGION-LIST-THREAD (QF-INITIAL-AREA-ORIGIN 'REGION-LIST-THREAD)))
      ((NOT (ZEROP (LOGLDB 2701 REGION)))
       (LOGLDB 0027 REGION))
    (DECLARE (FIXNUM REGION REGION-LIST-THREAD))))

;GIVEN A POINTER RETURN THE NUMBER OF THE REGION IT IS IN
;LIKE %REGION-NUMBER ON THE REAL MACHINE

(DEFUN QF-REGION-NUMBER-OF-POINTER (PNTR)
  (SETQ PNTR (QF-POINTER PNTR))
  (PROG (BOTLIM TOPLIM LBOUND HRANGE LOC LEN REGION REGION-ORIGIN TEM)
    (DECLARE (FIXNUM BOTLIM TOPLIM LBOUND HRANGE LOC LEN REGION REGION-ORIGIN TEM))
    (SETQ BOTLIM (QF-INITIAL-AREA-ORIGIN 'REGION-SORTED-BY-ORIGIN)
	  TOPLIM (+ BOTLIM SIZE-OF-AREA-ARRAYS)
	  LBOUND BOTLIM
	  HRANGE SIZE-OF-AREA-ARRAYS
	  REGION-ORIGIN (QF-INITIAL-AREA-ORIGIN 'REGION-ORIGIN))
 T0 (AND (= HRANGE 1) (GO T2))				;MOVING DOWN AND RANGE = 1 => DONE
 T1 (SETQ HRANGE (// (1+ HRANGE) 2))			;HALVE THE RANGE
    (SETQ TEM (+ LBOUND HRANGE))			;ADDRESS TO PROBE
    (OR (< TEM TOPLIM) (GO T0))				;RUNNING OFF TOP MOVE DOWN
    (SETQ LOC (QF-POINTER (PHYS-MEM-READ (+ REGION-ORIGIN (QF-POINTER (PHYS-MEM-READ TEM)))))) ;ORIGIN OF POSSIBLE REGION
    (AND (< PNTR LOC) (GO T0))				;MOVE DOWN
    (SETQ LBOUND TEM)
    (GO T1)						;MOVE UP

 T2 (SETQ REGION (QF-POINTER (PHYS-MEM-READ LBOUND)))	;GET PROPER REGION NUMBER
    (SETQ LOC (QF-POINTER (PHYS-MEM-READ (+ REGION-ORIGIN REGION))))	;GET ITS ORIGIN
    (AND (> LOC PNTR) (GO LOS))
    (SETQ LEN (QF-POINTER (PHYS-MEM-READ (+ (QF-INITIAL-AREA-ORIGIN 'REGION-LENGTH) REGION))))
    (AND (< PNTR (+ LOC LEN))
	 (RETURN REGION))
    (OR (= LEN 0) (GO LOS))
    (SETQ LBOUND (1+ LBOUND))				;ZERO LENGTH REGION TRY NEXT
    (GO T1)

LOS (ERROR PNTR '|NOT IN ANY REGION - QF-REGION-NUMBER-OF-POINTER| 'FAIL-ACT) ))

;;; OBARRAY STUFF

;MACLISP SYMBOL IN, LISP MACHINE SYMBOL (Q AS FIXNUM) OUT
;RETURNS -1 IF SYMBOL NOT ON OBARRAY
(DEFUN QF-SYMBOL (MACLISP-SYMBOL)
  (LET ((TEM NIL) (EXP NIL))
    (COND ((GET MACLISP-SYMBOL 'REAL-MACHINE-ATOM-HEADER-POINTER))
	  ((SETQ TEM (MEMQ '/: (SETQ EXP (EXPLODE MACLISP-SYMBOL))))
	   (QF-SYMBOL-INTERNAL (IMPLODE (CDR TEM))
			       (QF-FIND-PACKAGE (IMPLODE (LDIFF EXP TEM)))
			       MACLISP-SYMBOL))
	  (T (QF-SYMBOL-INTERNAL MACLISP-SYMBOL
				 (PHYS-MEM-READ (+ 400 %SYS-COM-OBARRAY-PNTR))
				 MACLISP-SYMBOL)))))

(IF-FOR-MACLISP 
(DEFUN LDIFF (A B)
    (DO ((A A (CDR A))
	 (ANS))
	((EQ A B) (NREVERSE ANS))
      (SETQ ANS (CONS (CAR A) ANS)))))

(DEFUN QF-SYMBOL1 (MACLISP-SYMBOL PACK)
    (COND ((GET MACLISP-SYMBOL 'REAL-MACHINE-ATOM-HEADER-POINTER))
	  (T (QF-SYMBOL-INTERNAL MACLISP-SYMBOL PACK MACLISP-SYMBOL))))

(DEFUN QF-SYMBOL-INTERNAL (PNAME PACK MACLISP-SYMBOL)
  (DECLARE (FIXNUM PACK))
  (COND ((= (QF-DATA-TYPE PACK) DTP-SYMBOL)
	 (SETQ PACK (QF-VALUE-CELL-CONTENTS PACK))))
  (COND ((QF-OBARRAY-NEW-P PACK)
	 (QF-SYMBOL-SEARCH PNAME PACK MACLISP-SYMBOL))
	(T (QF-SYMBOL-OLD PNAME PACK))))

(DEFUN QF-OBARRAY-NEW-P (PACK)
  (QF-ARRAY-SETUP PACK)
  (= QF-ARRAY-NUMBER-DIMS 2))

(DEFMACRO QF-PKG-SUPER-PACKAGE (PACK)
    `(QF-ARRAY-LEADER ,PACK 4))

(DEFMACRO QF-PKG-REFNAME-ALIST (PACK)
    `(QF-ARRAY-LEADER ,PACK 0))

;SEARCH A SPECIFIED PACKAGE AND ITS SUPERIORS FOR A SYMBOL.
(DEFUN QF-SYMBOL-SEARCH (SYM PACK MACLISP-SYMBOL)
    (DO ((PKG PACK (QF-PKG-SUPER-PACKAGE PKG))
	 (TEM))
	((QF-NULL PKG) -1)
       (SETQ TEM (QF-SYMBOL-PKG SYM PKG MACLISP-SYMBOL))
       (OR (= TEM -1) (RETURN TEM))))

;LOOK A SYMBOL UP IN A NEW-STYLE OBARRAY.
(DEFUN QF-SYMBOL-PKG (SYM PACK MACLISP-SYMBOL)
    (DECLARE (FIXNUM PACK))
    (LET ((HASH (QF-PKG-HASH-STRING SYM))
	  (LEN (// (QF-ARRAY-LENGTH PACK)
		   (QF-ARRAY-DIMENSION-N 1 PACK)))
	  (HASH1 0))
	 (DO I (\ HASH LEN) (\ (1+ I) LEN) NIL
	     (SETQ HASH1 (QF-AR-2 PACK 0 I))
	     (AND (QF-NULL HASH1) (RETURN -1))
	     (AND (= HASH (QF-POINTER HASH1))
		  (QF-SAMEPNAMEP SYM (QF-AR-2 PACK 1 I))
		  (RETURN
		   (PUTPROP
		    MACLISP-SYMBOL
		    (QF-AR-2 PACK 1 I)
		    'REAL-MACHINE-ATOM-HEADER-POINTER))))))

(DEFUN QF-FIND-PACKAGE (MSYMBOL)
    (COND ((GET MSYMBOL 'REAL-MACHINE-PACKAGE-POINTER))
	  (T
	   (LET ((PACK (PHYS-MEM-READ (+ 400 %SYS-COM-OBARRAY-PNTR))))
	     (COND ((= (QF-DATA-TYPE PACK) DTP-SYMBOL)
		    (SETQ PACK (QF-VALUE-CELL-CONTENTS PACK))))
	     (DO ((P (QF-PKG-SUPER-PACKAGE PACK) (QF-PKG-SUPER-PACKAGE P)))
		 ((NOT (= (QF-DATA-TYPE P) DTP-ARRAY-POINTER)))
	       (SETQ PACK P))
	     (DO ((R-ALIST (QF-PKG-REFNAME-ALIST PACK) (QF-CDR R-ALIST))
		  (THIS-CONS))
		 ((QF-NULL R-ALIST) -1)
	       (SETQ THIS-CONS (QF-CAR R-ALIST))
	       (COND ((QF-LMSTRING-MSYMBOL-EQUAL (QF-CAR THIS-CONS) MSYMBOL)
		      (LET ((ANSWER (QF-CAR (QF-CDR THIS-CONS))))
			(PUTPROP MSYMBOL ANSWER 'REAL-MACHINE-PACKAGE-POINTER)
			(RETURN ANSWER)))))))))

;24-BIT ROTATE FUNCTION
(IF-FOR-MACLISP
(DEFUN QF-ROT-24-BIT (WORD AMT)
  (LOGIOR (LOGLDB-FROM-FIXNUM (+ AMT (LSH (- 24. AMT) 6)) WORD)
	  (LSH (LOGLDB-FROM-FIXNUM (- 24. AMT) WORD) AMT))))
(IF-FOR-LISPM
(DEFMACRO QF-ROT-24-BIT (WORD AMT)	;WANT FIXNUM IN, FIXNUM OUT
  `(ROT ,WORD ,AMT)))

;TAKE A MACLISP SYMBOL AND FIGURE OUT WHAT PKG-HASH-STRING WOULD DO
;WITH A SYMBOL OF THAT NAME.
(DEFUN QF-PKG-HASH-STRING (SYM)
    (DECLARE (FIXNUM CHAR HASH I))
    (QF-POINTER (DO ((I 1 (1+ I))
		     (HASH 0)
		     (CHAR 0))
		    ((= 0 (SETQ CHAR (GETCHARN SYM I)))
		     (COND ((NOT (ZEROP (LOGLDB 2701 HASH)))
			#M  (LOGXOR HASH 40000001)      ;-37777777 = 40000001
                        #Q  (LOGXOR 1 (%LOGDPB 0 2701 HASH)))
			   (T HASH)))
		  (SETQ HASH (QF-ROT-24-BIT (LOGXOR HASH CHAR) 7)))))

;SEARCH OLD-STYLE BUCKET-LIST OBARRAY
(DEFUN QF-SYMBOL-OLD (TEM OBARRAYP)
    (DECLARE (FIXNUM OBARRAYP HASH))
    (LET ((HASH (QF-PKG-HASH-STRING TEM))
	  (OBSCURE NIL))
       (SETQ OBSCURE (LOGLDB-FROM-FIXNUM %%ARRAY-INDEX-LENGTH-IF-SHORT (QF-MEM-READ OBARRAYP)))
       (SETQ OBARRAYP (+ 1 (\ HASH OBSCURE) OBARRAYP))	 ;ASSUME 1 DIMENSIONAL, SHORT, ETC.
       (DO ((BUCKET (QF-MEM-READ OBARRAYP) (QF-CDR BUCKET)))
	   ((NOT (= (QF-DATA-TYPE BUCKET) DTP-LIST))
	    (RETURN -1))
	 (DECLARE (FIXNUM BUCKET))
	 (AND (QF-SAMEPNAMEP TEM
		   (SETQ OBSCURE (QF-MEM-READ BUCKET))) ;CAR
	      (RETURN (PUTPROP TEM 
			      (QF-TYPED-POINTER OBSCURE) 
			      'REAL-MACHINE-ATOM-HEADER-POINTER))) ) ))

;DOESN'T TRY TO WIN FOR HAIRY FONT CHANGES ETC.
(DEFUN QF-LM-STRING-EQUAL (STRING1 STRING2 LEN2)
  (DECLARE (FIXNUM STRING1 LEN1 STRING2 LEN2 WD1 WD2 IDX CHNUM))
  ((LAMBDA (LEN1)
    (COND ((NOT (= LEN1 LEN2))
	   NIL)
	  ((DO ((IDX 0 (1+ IDX))
		(CHNUM)
		(WD1)
		(WD2))
	       ((NOT (< IDX LEN1))
		T)
	     (COND ((= 0 (SETQ CHNUM (LOGAND 3 IDX)))
		    (SETQ WD1 (QF-MEM-READ (SETQ STRING1 (1+ STRING1))))
		    (SETQ WD2 (QF-MEM-READ (SETQ STRING2 (1+ STRING2))))))
	     (OR (= (LOGAND 377 (LSH WD1 (SETQ CHNUM (* -8 CHNUM))))
		    (LOGAND 377 (LSH WD2 CHNUM)))
		 (RETURN NIL)) ))))
   (QF-ARRAY-ACTIVE-LENGTH STRING1)))

(DEFUN QF-SAMEPNAMEP (LISPSYMB QSYMBPTR)
 (DECLARE (FIXNUM QSYMBPTR))
 (QF-LMSTRING-MSYMBOL-EQUAL (QF-MEM-READ QSYMBPTR) LISPSYMB))

(DEFUN QF-LMSTRING-MSYMBOL-EQUAL (CONS-PNAME-PNTR LISPSYMB)
 (DECLARE (FIXNUM CONS-PNAME-PNTR))
 (PROG (LEN ARRAY-HEAD)
  (DECLARE (FIXNUM LEN ARRAY-HEAD))
  (SETQ ARRAY-HEAD (QF-MEM-READ CONS-PNAME-PNTR))
  (COND ((NOT (= 0 (LOGLDB-FROM-FIXNUM %%ARRAY-LEADER-BIT ARRAY-HEAD)))
	 (SETQ LEN (QF-POINTER (QF-MEM-READ (- CONS-PNAME-PNTR 2)))))
	((= 0 (LOGLDB-FROM-FIXNUM %%ARRAY-LONG-LENGTH-FLAG ARRAY-HEAD))
	 (SETQ LEN (LOGLDB-FROM-FIXNUM %%ARRAY-INDEX-LENGTH-IF-SHORT ARRAY-HEAD)))
	((SETQ LEN (QF-POINTER (QF-MEM-READ (SETQ CONS-PNAME-PNTR (1+ CONS-PNAME-PNTR)))))))
  (RETURN
   (COND ((OR (= 0 (GETCHARN LISPSYMB LEN))
	      (NOT (= 0 (GETCHARN LISPSYMB (1+ LEN)))))
	   NIL)  ;WRONG LENGTH
	(T 
   (DO ((COUNT 1 (1+ COUNT)) ;BECAUSE GETCHARN USES 1-ORIGIN INDEXING
	(WD-NUM 0)
	(WD)
	(CH)
	(LCH)
	(PORTION 0 (1+ PORTION)))
       ((> COUNT LEN) T)
    (DECLARE (FIXNUM COUNT WD-NUM WD CH PORTION))
    (AND (= 0 PORTION)
	 (SETQ WD (QF-MEM-READ (+ (SETQ WD-NUM (1+ WD-NUM))
				  CONS-PNAME-PNTR))))
    (SETQ CH (LOGAND 377 WD))
    (SETQ WD (CC-SHIFT WD -8))
    (AND (= 0 (SETQ LCH (GETCHARN LISPSYMB COUNT)))
	 (RETURN NIL))
    (COND ((NOT (= LCH CH))
	   (RETURN NIL))
	  ((= 3 PORTION)
	   (SETQ PORTION -1))) ) )) )))

;;;BASIC OPERATIONS
;;; Note that if we have a pointer to old-space, either it has not been copied
;;; out of oldspace yet and that is OK, or there is a GC-forwarding pointer there
;;; which we will end up chasing.  EQ, however, is not well-defined in QF
;;; because of not really grokking old-space.  At least NIL is in a static area.

(DEFUN QF-CAR (LMOB)
    (LET ((TYPE (QF-DATA-TYPE LMOB)))
      (OR (= TYPE DTP-LIST)
	  (= TYPE DTP-LOCATIVE)
	  (= TYPE DTP-CLOSURE)
	  (= TYPE DTP-ENTITY)
	  (ERROR '|Neither a cons nor a locative -- QF-CAR| LMOB)))
    (DO ((X (QF-MEM-READ LMOB) (QF-MEM-READ X))
	 (ADR LMOB X))
	(NIL)
      (SELECTN (QF-DATA-TYPE X)
	 ((DTP-HEADER-FORWARD DTP-ONE-Q-FORWARD
	   DTP-EXTERNAL-VALUE-CELL-POINTER DTP-GC-FORWARD) NIL)
	 (DTP-BODY-FORWARD
	     (LET ((OFFSET (- (QF-POINTER ADR) (QF-POINTER X))))
	       (SETQ X (+ (QF-MEM-READ X) OFFSET))))
	 (OTHERWISE (RETURN (QF-TYPED-POINTER X))))))

(DEFUN QF-CDR (LMOB)
   (LET ((TYPE (QF-DATA-TYPE LMOB))(L LMOB))
     (SELECTN TYPE
	(DTP-LOCATIVE
	 (QF-CAR LMOB))
	((DTP-LIST DTP-CLOSURE DTP-ENTITY)
	 (LET ((CDRC (QF-CDR-CODE
		      (DO ((X (QF-MEM-READ LMOB) (QF-MEM-READ L)))
			  (NIL)
			(SELECTN (QF-DATA-TYPE X)
			   ((DTP-HEADER-FORWARD DTP-GC-FORWARD)
			    (SETQ L X))
			   (OTHERWISE (RETURN X)))))))
	   (LET ((X (SELECTN CDRC
		       (0 (QF-MEM-READ (1+ L)))	;FULL CONS
		       (1 (ERROR '|CDR-ERROR encountered - QF-CDR| LMOB 'FAIL-ACT))
		       (2 QF-NIL)			;CDR NIL
		       (3 (1+ L))
		       (OTHERWISE (ERROR '|Lose big -- QF-CDR|)))))
	     (DO ((X X (QF-MEM-READ X))
		  (ADR L X))
		 (NIL)
	       (SELECTN (QF-DATA-TYPE X)
		  ((DTP-HEADER-FORWARD DTP-GC-FORWARD
		    DTP-ONE-Q-FORWARD DTP-EXTERNAL-VALUE-CELL-POINTER) NIL)
		  (DTP-BODY-FORWARD
		    (LET ((OFFSET (- (QF-POINTER ADR) (QF-POINTER X))))
		      (SETQ X (+ (QF-MEM-READ X) OFFSET))))
		  (OTHERWISE (RETURN (QF-TYPED-POINTER X))))))))
	(OTHERWISE
	 (ERROR '|Neither a cons nor a locative -- QF-CDR| LMOB)))))

(DEFUN QF-VALUE-CELL-LOCATION (Q)
  (OR (= (QF-DATA-TYPE Q) DTP-SYMBOL) (ERROR '|NOT SYMBOL - QF-VALUE-CELL-LOCATION| Q 'FAIL-ACT))
  (QF-MAKE-Q (1+ Q) DTP-LOCATIVE))

(DEFUN QF-FUNCTION-CELL-LOCATION (Q)
  (OR (= (QF-DATA-TYPE Q) DTP-SYMBOL) (ERROR '|NOT SYMBOL - QF-FUNCTION-CELL-LOCATION| Q 'FAIL-ACT))
  (QF-MAKE-Q (+ 2 Q) DTP-LOCATIVE))

(DEFUN QF-PROPERTY-CELL-LOCATION (Q)
  (OR (= (QF-DATA-TYPE Q) DTP-SYMBOL) (ERROR '|NOT SYMBOL - QF-PROPERTY-CELL-LOCATION| Q 'FAIL-ACT))
  (QF-MAKE-Q (+ 3 Q) DTP-LOCATIVE))

(DEFUN QF-FUNCTION-CELL-CONTENTS (QQ)
  (AND (EQ (TYPEP QQ) 'SYMBOL) (SETQ QQ (QF-SYMBOL QQ)))
  (OR (= (QF-DATA-TYPE QQ) DTP-SYMBOL) (ERROR 'WTA-QF-FUNCTION-CELL-CONTENTS QQ 'FAIL-ACT))
  (QF-CAR (QF-FUNCTION-CELL-LOCATION QQ)))

(DEFUN QF-VALUE-CELL-CONTENTS (QQ)
  (AND (EQ (TYPEP QQ) 'SYMBOL) (SETQ QQ (QF-SYMBOL QQ)))
  (OR (= (QF-DATA-TYPE QQ) DTP-SYMBOL) (ERROR 'WTA-QF-VALUE-CELL-CONTENTS QQ 'FAIL-ACT))
  (QF-CAR (QF-VALUE-CELL-LOCATION QQ)))

;RETURN BASE ADDRSS OF AREA WHICH WAS PRESENT IN COLD-LOAD.  FASTER THAN QF-AREA-ORIGIN,
; AND MORE IMPORTANTLY, GUARANTEED NOT TO CAUSE ANY SWAPPING ACTIVITY.
(DEFUN QF-INITIAL-AREA-ORIGIN (NAME)
  (PROG (TEM)
	(COND
         ((SETQ TEM (ASSQ NAME QF-AREA-ORIGIN-CACHE)) (RETURN (CDR TEM)))
         ((SETQ TEM (FIND-POSITION-IN-LIST NAME AREA-LIST))
          (SETQ TEM 
                (QF-POINTER
                 (PHYS-MEM-READ (QF-POINTER (+ TEM (PHYS-MEM-READ
                                                    (+ 400 %SYS-COM-AREA-ORIGIN-PNTR)))))))
		(SETQ QF-AREA-ORIGIN-CACHE 
			(CONS (CONS NAME TEM) QF-AREA-ORIGIN-CACHE))
		(RETURN TEM))
	      (T (ERROR NAME 'QF-INITIAL-AREA-ORIGIN 'FAIL-ACT)))))

;RETURN AREA NUMBER OF AREA - BETTER BE AN INITIAL AREA
(DEFUN QF-AREA-NUMBER (NAME)
  (OR (FIND-POSITION-IN-LIST NAME AREA-LIST)
      (ERROR NAME '|NOT KNOWN - QF-AREA-NUMBER|)))

;;; ARRAYS.  ONLY 1-DIMENSIONAL FOR NOW.

;FUNCTION TO SET UP FOR AN ARRAY REFERENCE
;CORRESPONDS TO GAHDR IN MICRO CODE.
;ARGUMENT IS ARRAY-POINTER-Q
;SETS THE FOLLOWING SPECIAL VARIABLES:
;  QF-ARRAY-HEADER
;  QF-ARRAY-DISPLACED-P
;  QF-ARRAY-HAS-LEADER-P
;  QF-ARRAY-NUMBER-DIMS
;  QF-ARRAY-HEADER-ADDRESS
;  QF-ARRAY-DATA-ORIGIN
;  QF-ARRAY-LENGTH

(DEFUN QF-ARRAY-SETUP (Q)
  (PROG (N)
    (OR (= (QF-DATA-TYPE Q) DTP-ARRAY-POINTER) (ERROR '|NOT AN ARRAY-POINTER - QF-ARRAY-SETUP|
						  Q 'FAIL-ACT))
A   (SETQ QF-ARRAY-HEADER-ADDRESS (QF-POINTER Q))
    (SETQ QF-ARRAY-HEADER (QF-MEM-READ QF-ARRAY-HEADER-ADDRESS))
    (SETQ N (QF-DATA-TYPE QF-ARRAY-HEADER))
    (COND ((= N DTP-ARRAY-HEADER))
	  ((OR (= N DTP-HEADER-FORWARD) (= N DTP-GC-FORWARD))
	   (SETQ Q QF-ARRAY-HEADER)
	   (GO A))
	  ((ERROR '|ARRAY HEADER NOT DTP-ARRAY-HEADER - QF-ARRAY-SETUP| Q 'FAIL-ACT)))
    (SETQ QF-ARRAY-DISPLACED-P (= 1 (LOGLDB-FROM-FIXNUM %%ARRAY-DISPLACED-BIT
							QF-ARRAY-HEADER)))
    (SETQ QF-ARRAY-HAS-LEADER-P (= 1 (LOGLDB-FROM-FIXNUM %%ARRAY-LEADER-BIT QF-ARRAY-HEADER)))
    (SETQ QF-ARRAY-NUMBER-DIMS (LOGLDB-FROM-FIXNUM %%ARRAY-NUMBER-DIMENSIONS QF-ARRAY-HEADER))
    (SETQ QF-ARRAY-DATA-ORIGIN (+ QF-ARRAY-NUMBER-DIMS QF-ARRAY-HEADER-ADDRESS))
    (COND ((= 0 (LOGLDB-FROM-FIXNUM %%ARRAY-LONG-LENGTH-FLAG QF-ARRAY-HEADER))
	   (SETQ QF-ARRAY-LENGTH (LOGLDB-FROM-FIXNUM %%ARRAY-INDEX-LENGTH-IF-SHORT
						     QF-ARRAY-HEADER)))
	  (T
	   (SETQ QF-ARRAY-DATA-ORIGIN (1+ QF-ARRAY-DATA-ORIGIN))
	   (SETQ QF-ARRAY-LENGTH (QF-POINTER (QF-MEM-READ (1+ QF-ARRAY-HEADER-ADDRESS))))))
  ))

;FUNCTION THAT CORRESPONDS TO DSP-ARRAY-SETUP IN MICRO CODE.
;ARGUMENT IS COMPUTED INDEX, RESULT IS NEW, POSSIBLY-OFFSET INDEX.
;HANDLES DISPLACED AND INDIRECT ARRAYS.  BARFS IF INDEX OUT OF BOUNDS.
;MAY MODIFY SPECIAL VARIABLE QF-ARRAY-DATA-ORIGIN.
(DEFUN QF-ARRAY-DISPLACE (I)
 (COND (QF-ARRAY-DISPLACED-P
	(SETQ QF-ARRAY-LENGTH (QF-POINTER (QF-MEM-READ (1+ QF-ARRAY-DATA-ORIGIN))))
	(PROG (K)
	  (SETQ K (QF-MEM-READ QF-ARRAY-DATA-ORIGIN))
	  (OR (= (QF-DATA-TYPE K) DTP-ARRAY-POINTER) (RETURN (SETQ QF-ARRAY-DATA-ORIGIN K)))
	  ;INDIRECT ARRAY
	  (ERROR '|I REALLY DON'T FEEL LIKE HACKING INDIRECT ARRAYS, SORRY - QF-ARRAY-DISPLACE|
		 NIL 'FAIL-ACT))))
 (OR (< I QF-ARRAY-LENGTH)
     (ERROR '|ARRAY INDEX OUT OF BOUNDS - QF-ARRAY-DISPLACE| I 'FAIL-ACT))
 I)

;FUNCTION TO READ OUT CONTENTS OF THE SET UP ARRAY.  ARG IS INDEX.
(DEFUN QF-ARRAY-READ (I)
  (PROG (N TYPE K M Q J)
    (SETQ TYPE (NTH (LOGLDB-FROM-FIXNUM %%ARRAY-TYPE-FIELD QF-ARRAY-HEADER) ARRAY-TYPES))
    (SETQ K (CDR (ASSQ TYPE ARRAY-ELEMENTS-PER-Q)))	;K ELEMENTS PER Q
;**KNOWS ABOUT LENGTH OF POINTER**
    (SETQ N (CDR (OR (ASSQ TYPE '((ART-1B . 1) (ART-2B . 2) (ART-4B . 4) (ART-8B . 8.)
				  (ART-16B . 16.) (ART-32B . 32.) (ART-Q . 32.)
				  (ART-Q-LIST . 29.) (ART-STRING . 8)
				  (ART-STACK-GROUP-HEAD . 32.) (ART-SPECIAL-PDL . 32.)
				  (ART-TVB . 20) (ART-REG-PDL . 32.)
				  ))			;N BITS PER ELEMENT
		     (ERROR '|ARRAY TYPE NOT KNOWN ABOUT - QF-ARRAY-READ| TYPE 'FAIL-ACT))))
    (SETQ M (1- (CC-SHIFT 1 N)))			;M MASK FOR 1 ELEMENT
    (SETQ Q (// I K) J (* (\ I K) N))			;Q WD INDEX, J BIT INDEX
    (SETQ Q (QF-MEM-READ (+ Q QF-ARRAY-DATA-ORIGIN)))
    (RETURN (LOGAND M (CC-SHIFT Q (- J))))))

;SIMILAR FUNCTION TO WRITE INTO SET UP ARRAY.
(DEFUN QF-ARRAY-WRITE (I DATA)
  (PROG (N TYPE K M Q J ADR)
    (SETQ TYPE (NTH (LOGLDB-FROM-FIXNUM %%ARRAY-TYPE-FIELD QF-ARRAY-HEADER) ARRAY-TYPES))
    (SETQ K (CDR (ASSQ TYPE ARRAY-ELEMENTS-PER-Q)))
;**KNOWS ABOUT NUMBER OF BITS IN POINTER**
    (SETQ N (CDR (OR (ASSQ TYPE '((ART-1B . 1) (ART-2B . 2) (ART-4B . 4) (ART-8B . 8.)
				  (ART-16B . 16.) (ART-32B . 32.) (ART-Q . 32.)
				  (ART-Q-LIST . 29.) (ART-STRING . 8)
				  (ART-STACK-GROUP-HEAD . 32.) (ART-SPECIAL-PDL . 32.)
				  (ART-TVB . 20.) (ART-REG-PDL . 32.)
				  ))			;N BITS PER ELEMENT
		     (ERROR '|ARRAY TYPE NOT KNOWN ABOUT - QF-ARRAY-WRITE| TYPE 'FAIL-ACT))))
    (SETQ M (1- (LSH 1 N)))
    (SETQ Q (// I K) J (* (\ I K) N))
    (SETQ Q (QF-MEM-READ (SETQ ADR (+ Q QF-ARRAY-DATA-ORIGIN))))
    (RETURN (QF-MEM-WRITE ADR
			  (LOGIOR (CC-SHIFT (LOGAND M DATA) J)
				  (LOGAND (LOGXOR -1 (CC-SHIFT M J))
					  Q))))))

(DEFUN QF-ARRAY-DIMENSION-N (I Q)
 (QF-ARRAY-SETUP Q)
 (COND ((= I QF-ARRAY-NUMBER-DIMS)
	(ERROR '|QF-ARRAY-DIMENSION-N ON LAST DIMENSION|)))
 (QF-POINTER (QF-MEM-READ (+ I (- QF-ARRAY-DATA-ORIGIN QF-ARRAY-NUMBER-DIMS)))))

(DEFUN QF-AR-1 (Q I)
  (QF-ARRAY-SETUP Q)
  (QF-TYPED-POINTER (QF-ARRAY-READ (QF-ARRAY-DISPLACE I))))

(DEFUN QF-AR-2 (Q I J)
  (QF-ARRAY-SETUP Q)
  (QF-TYPED-POINTER (QF-ARRAY-READ 
     (QF-ARRAY-DISPLACE
        (+ (* J (QF-P-POINTER (1+ (- QF-ARRAY-DATA-ORIGIN QF-ARRAY-NUMBER-DIMS))))
	   I)))))

(DEFUN QF-ARRAY-LEADER (Q I)
  (QF-ARRAY-SETUP Q)
  (OR QF-ARRAY-HAS-LEADER-P (ERROR '|NO ARRAY LEADER - QF-ARRAY-LEADER| Q 'FAIL-ACT))
  (OR (< I (QF-POINTER (QF-MEM-READ (- QF-ARRAY-HEADER-ADDRESS 1))))
      (ERROR '|ARRAY LEADER INDEX OUT OF BOUNDS - QF-ARRAY-LEADER| Q 'FAIL-ACT))
  (QF-TYPED-POINTER (QF-MEM-READ (- QF-ARRAY-HEADER-ADDRESS I 2))))

(DEFUN QF-ARRAY-LENGTH (Q)
  (QF-ARRAY-SETUP Q)
  QF-ARRAY-LENGTH)

(DEFUN QF-ARRAY-ACTIVE-LENGTH (Q)
  (QF-ARRAY-SETUP Q)
  (COND ((NOT QF-ARRAY-HAS-LEADER-P)
	 QF-ARRAY-LENGTH)
	((QF-POINTER (QF-MEM-READ (- QF-ARRAY-HEADER-ADDRESS 2))))))

;INITIALIZE ON FIRST LOADING
(OR (BOUNDP 'QF-AREA-ORIGIN-CACHE)
    (QF-CLEAR-CACHE T))
