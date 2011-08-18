;;-*- mode: lispm; package: cadr -*-

;Production check out aids.  These are mostly for freshly constructed machines
;  before CC-TEST-MACHINE can even do anything reasonable.


;Check:  dummy in 5A19

;Check both ends of high runs:
;CADR
;   HI1  1F05(3)   4F25(8)
;   HI2  1F05(4)   4A27(7)
;   HI3  1F05(5)   4E24(9)
;   HI4  1F05(6)   4E24(11)
;   HI5  1F05(7)   4E24(12)
;   HI6  1F05(8)   4E24(13)
;   HI7  1F05(9)   4E24(14)
;   HI8  1F05(12)  4E29(7)
;   HI9  1F05(13)  4E29(8)
;   HI10 1F05(14)  4E29(9)
;   HI11 1B05(19)  4E29(11)
;   HI12 1F05(16)  4E29(12)
;ICMEM
;   HI1  1F01(8)   1A18(5)
;   HI2  1F06(3)   1A19(17)


;Verify Reset getting from bus interface to processor

; DEBUGEE RESET L  busint A16(12)
; BUSINT LM RESET L busint C04(11)
; BUSINT J08(13)  --lots of stuff has to work for this to happen --
; -BUSINT.LM.RESET  icmem  5AJ1-11 

;(P-RESET-LOOP)
(DEFUN P-RESET-LOOP NIL 
  (DO () (()) (DBG-RESET)))

(DEFUN P-RESET-MACH ()
  (DO () ((KBD-TYI-NO-HANG))
    (CC-RESET-MACH)
    (CC-NOOP-DEBUG-CLOCK)))

(DEFUN P-START-STOP (&OPTIONAL (SPEED 0))
  
  (DO () ((KBD-TYI-NO-HANG))
    (CC-RESET-MACH)
    (CC-EXECUTE CONS-IR-M-SRC CONS-M-SRC-MD
		CONS-IR-OB CONS-OB-ALU
		CONS-IR-ALUF CONS-ALU-M+1
		CONS-IR-FUNC-DEST CONS-FUNC-DEST-MD)
    (SPY-WRITE SPY-MODE (LOGAND 3 SPEED))	;set speed, clear errstop, etc.
    (SPY-WRITE SPY-CLK 11)			;set run and debug
    (PROCESS-SLEEP 1.)
    (SPY-WRITE SPY-CLK 10)
    (CC-READ-M-MEM CONS-M-SRC-MD)))







;SPY WRITE L    BUSINT J08-10
;-DBWRITE	5F03(6)  SPY0	5AJ1-10  MBCPIN
;-LDBIRH	5F03(15) SPY0	5F15(11) DEBUG
;-LDBIRM	5F03(16) SPY0	5E12(11) DEBUG
;-LDBIRL	5F03(17) SPY0	5E14(11) DEBUG
;DIAG IR (1F15,1E11) (1E12,1E13) (1E14,1E15)  DEBUG print
; clock -LDDBIRL 1E15(11)  
; output enable  -IDEBUG 1E15(1)
;  SPY0 1E15(18)  I0 1E15(19)

;(P-DBG-IR-LOOP)
(DEFUN P-DBG-IR-LOOP (&OPTIONAL (N 0))
  (DO ((NOT-N (LOGXOR N 7777777777777777)))
      ((KBD-TYI-NO-HANG))
    (CC-WRITE-IR N) (CC-WRITE-IR NOT-N)))

;PC 4E04,4E05  NPC print
; CLK4B 4E05(11),  PC0 4E05(19)

(DEFUN P-PC-LOOP (&OPTIONAL (N 0))
  (DO () (()) (CC-WRITE-PC N)))


(DEFUN P-PC-R-LOOP NIL
  (DO () (()) (CC-READ-PC)))

(DEFUN P-IR-LOOP (&OPTIONAL (N 0))
  (DO () (()) (CC-WRITE-IR N)))

(DEFUN P-TEST-UNIBUS-MAP (&AUX TEM)
  (DOTIMES (A 20)
    (DOLIST (V '(0 177777 125252 052525))
      (DBG-WRITE-UNIBUS-MAP A V)
      (COND ((NOT (= (SETQ TEM (DBG-READ-UNIBUS-MAP A)) V))
	     (FORMAT T "~%Unibus map locn ~s, wrote ~s, read ~s" A V TEM)))))
  (DBG-RESET))   ;let console prgm know it has to remap

(DEFUN P-UBM-LOOP (&OPTIONAL (D -1) (A 0))
  (DO () (())
    (DBG-WRITE-UNIBUS-MAP A D)))

(DEFUN P-UBM-R-LOOP (&OPTIONAL (A 0))
  (DO () (())
    (DBG-READ-UNIBUS-MAP A)))

;XBUS TERMINATOR IN!
;UB TO MD L  BUSINT  D12(11)    BUSINT REQU
;UB MD LOAD  BUSINT  B17(16)	BUSINT REQLM
;-LOADMD     BUSINT  C10(11)	BUSINT REQLM
;-LOADMD	1CJ1-19		BCPINS
;LOADMD		1D18(11)	MD
;MDCLK		1E19(11)	MD
(DEFUN P-MD-LOOP (&OPTIONAL (N 0))
  (DO () (()) (CC-WRITE-MD N)))

(DEFUN P-MD-R-LOOP NIL
  (DO () (()) (CC-READ-MD)))

(DEFUN CC-TEST-MD (&OPTIONAL (N 0) (M -1))
  (DO () ((KBD-TYI-NO-HANG))
    (CC-WRITE-MD N)
    (CC-READ-MD)
    (CC-WRITE-MD M)
    (CC-READ-MD)))

(DEFUN P-MD-SHIFTING-LOOP (&OPTIONAL (N 0))
  (DO () (()) (CC-WRITE-MD-SHIFTING N)))

(DEFUN CC-TEST-VMA (&OPTIONAL (N 0) (M -1))
  (DO () ((KBD-TYI-NO-HANG))
    (CC-WRITE-VMA N)
    (CC-READ-VMA)
    (CC-WRITE-VMA M)
    (CC-READ-VMA)))

(DEFUN P-VMA-LOOP (&OPTIONAL (N 0))
  (DO () (()) (CC-WRITE-VMA N)))

(DEFUN P-OBUS-LOOP NIL
  (DO () (()) (CC-READ-OBUS)))

(defun p-m-rw-m-pass (n &optional (adr 0))
  (CC-WRITE-MD n)		;PUT VALUE INTO THE MRD REGISTER
  (CC-EXECUTE  ;NOTE NO WRITE, JUST PUT IT IN IR
	      CONS-IR-M-SRC CONS-M-SRC-MD
	      CONS-IR-ALUF CONS-ALU-SETM 
	      CONS-IR-OB CONS-OB-ALU
	      CONS-IR-M-MEM-DEST adr)
  (CC-EXECUTE (EXECUTOR CC-EXECUTE-LOAD-DEBUG-IR)
	      CONS-IR-M-SRC ADR	;PUT IT ONTO THE OBUS
	      CONS-IR-ALUF CONS-ALU-SETM
	      CONS-IR-OB CONS-OB-ALU)
  (CC-DEBUG-CLOCK)	;EXECUTE THE WRITE, LOAD IR WITH THE READ
  (CC-READ-OBUS))	;READ BACK THE DATA VIA THE PASS AROUND PATH

(DEFUN P-M-MEM-LOOP (&OPTIONAL (N 0) (ADR 0))
  (DO () (()) (CC-WRITE-M-MEM ADR N)))

(DEFUN P-M-MEM-R-LOOP (&OPTIONAL (ADR 0))
  (DO () (()) (CC-READ-M-MEM ADR)))

(DEFUN P-M-MEM-RW-LOOP (&OPTIONAL (N 0) (ADR 0))
  (DO () (())
    (CC-WRITE-M-MEM ADR N)
    (CC-READ-M-MEM ADR)  ))

(DEFUN P-A-MEM-LOOP (&OPTIONAL (N 0) (ADR 0))
  (DO () (()) (CC-WRITE-A-MEM ADR N)))

(DEFUN P-A-MEM-R-LOOP (&OPTIONAL (ADR 0))
  (DO () (()) (CC-READ-A-MEM ADR)))

(defun p-m-rw-a-pass (n &optional (adr 0))
  (CC-WRITE-MD n)		;PUT VALUE INTO THE MRD REGISTER
  (CC-EXECUTE  ;NOTE NO WRITE, JUST PUT IT IN IR
	      CONS-IR-M-SRC CONS-M-SRC-MD	;MOVE IT TO DESIRED PLACE
	      CONS-IR-ALUF CONS-ALU-SETM 
	      CONS-IR-OB CONS-OB-ALU
	      CONS-IR-A-MEM-DEST (+ CONS-A-MEM-DEST-INDICATOR adr))
  (CC-EXECUTE (EXECUTOR CC-EXECUTE-LOAD-DEBUG-IR)
	      CONS-IR-A-SRC ADR			;PUT IT ONTO THE OBUS
	      CONS-IR-ALUF CONS-ALU-SETA
	      CONS-IR-OB CONS-OB-ALU)
  (CC-DEBUG-CLOCK)	;EXECUTE THE WRITE, LOAD IR WITH THE READ
  (CC-READ-OBUS))	;READ BACK THE DATA VIA THE PASS AROUND PATH

(DEFUN P-C-MEM-LOOP (&OPTIONAL (N 0) (ADR 0))
  (DO () (()) (CC-WRITE-C-MEM ADR N)))

(DEFUN P-C-MEM-R-LOOP (&OPTIONAL (ADR 0))
  (DO () (()) (CC-READ-C-MEM ADR)))

(DEFUN P-LC-LOOP (&OPTIONAL (N 0))
  (DO () (()) (CC-WRITE-FUNC-DEST CONS-FUNC-DEST-LC N)))

(DEFUN P-INTC-LOOP (&OPTIONAL (N 0))
  (DO () (()) (CC-WRITE-FUNC-DEST CONS-FUNC-DEST-INT-CNTRL N)))

(DEFUN P-D-MEM-LOOP (&OPTIONAL (VAL 0) (ADR 0))
  (do () ((KBD-TYI-NO-HANG))
    (P-D-MEM-D VAL ADR)))

(DEFUN P-D-MEM-ADR NIL
  (DO ((I 1 (IF (> I 2000) 1 (LSH I 1))))
      ((KBD-TYI-NO-HANG))
    (P-D-MEM-D 0 (+ RADMO I))
    (P-D-MEM-D -1 (+ RADMO I))))

(DEFUN P-D-MEM-D (VAL ADR)
  (CC-WRITE-A-MEM 0 
       (LOGDPB-INTO-FIXNUM (DO ((COUNT 17. (1- COUNT))
				(X VAL (LOGXOR VAL (LSH X -1))))
			       ((= COUNT 0)
				(LOGXOR 1 X)))	;ODD PARITY
			   CONS-DISP-PARITY-BIT
			   VAL))		;DATA TO BE WRITTEN TO A-LOC 0
     (CC-EXECUTE CONS-IR-OP CONS-OP-DISPATCH
		 CONS-IR-A-SRC 0
		 CONS-IR-DISP-ADDR ADR
		 CONS-IR-MF 2)	;MF2 IS WRITE D-MEM
     ;GENERATE A CLOCK FOLLOWED BY A WRITE PULSE, WITHOUT CHANGING IR
     ;NOTE THAT WRITING D MEM IS DIFFERENT FROM WRITING ANYTHING ELSE
     ;BECAUSE THE WRITE IS NOT DELAYED, BUT DOES USE WP.
     (CC-DEBUG-CLOCK))    ;PUT INSTRUCTION IN DIB AND IR


;Load IR with Dispatch inst.  D-MEM contents should appear statically
; on D-MEM data lines

(DEFUN P-D-EXAM (&OPTIONAL (LOC 0))
  (CC-EXECUTE CONS-IR-OP CONS-OP-DISPATCH	;EXECUTE A DISPATCH WITH BYTE SIZE ZERO
	      CONS-IR-DISP-ADDR LOC))

(DEFUN P-MN-MEM-LOOP (&OPTIONAL (N 0) (ADR 0))
  (DO () (()) (PHYS-MEM-WRITE ADR N)))

(defun p-mn-mem-r-loop (&optional (adr 0))
  (do () (()) (phys-mem-read adr)))

(DEFUN P-MN-MEM-RWC-LOOP (&OPTIONAL (ADR 0) (DATA1 0) (DATA2 37777777777))
  (DO () (())
    (P-MN-MEM-RWC ADR DATA1)
    (P-MN-MEM-RWC ADR DATA2)))

(DEFUN P-MN-MEM-RWC (ADR DATA &AUX READ-BACK)
    (PHYS-MEM-WRITE ADR DATA)
    (COND ((NOT (= DATA (SETQ READ-BACK (PHYS-MEM-READ ADR))))
	   (FORMAT T "~%Addr: ~O      Wrote: ~11O   Read: ~11O"
		   ADR DATA READ-BACK))))

(DEFUN P-MN-MEM-RW-LOOP (&OPTIONAL (ADR 0) (DATA1 0) (DATA2 37777777777))
  (DO () (())
    (PHYS-MEM-WRITE ADR DATA1)
    (PHYS-MEM-READ ADR)
    (PHYS-MEM-WRITE ADR DATA2)
    (PHYS-MEM-READ ADR)))

(DEFUN P-L1-MAP-LOOP (&OPTIONAL (ADR 0) (DATA 0))
  (DO () (())
    (CC-WRITE-LEVEL-1-MAP ADR DATA)))


(DEFUN P-TEST-MICRO-STACK-PTR NIL
  (DO ((COUNT 32. (1- COUNT)))			;UNTIL USP EQUALS THE DESIRED VALUE,
      ((< COUNT 0))
      (PRINT (CC-READ-MICRO-STACK-PTR))
      (CC-EXECUTE (WRITE) CONS-IR-M-SRC CONS-M-SRC-MICRO-STACK-POP))) ;KEEP POPPING IT

(DEFUN P-MICRO-STACK-READ-TEST NIL
       (DO ()
	   (())
	   (CC-READ-MICRO-STACK-PTR)))

(DEFUN P-UNIBUS-W-LOOP (ADR &OPTIONAL (DATA 0))
  (DO ()
      (())
    (DBG-WRITE ADR DATA)))