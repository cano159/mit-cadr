(DECLARE (SPECIAL *MOUSE-BLINKER*))

(SETQ *MOUSE-BOX-BLINKER* (TV:DEFINE-BLINKER TV:MOUSE-SHEET 'TV:HOLLOW-RECTANGULAR-BLINKER
							    ':VISIBILITY NIL)
      *MOUSE-BLINKER* *MOUSE-CHAR-BLINKER*)


(DEFMETHOD (ZWEI-WITH-TYPEOUT :TURN-OFF-BLINKERS-FOR-TYPEOUT) ()
  (TV:BLINKER-SET-VISIBILITY *MOUSE-BLINKER* NIL)
  (TV:MOUSE-STANDARD-BLINKER))

(DEFMETHOD (ZWEI :HANDLE-MOUSE) ()
  (LET-GLOBALLY ((*MOUSE-P* T))
    (TV:MOUSE-SET-BLINKER-DEFINITION ':CHARACTER *MOUSE-X-OFFSET* *MOUSE-Y-OFFSET* ':ON
				     ':SET-CHARACTER *MOUSE-FONT-CHAR*)
    (TV:MOUSE-DEFAULT-HANDLER SELF (FUNCALL-SELF ':SCROLL-BAR-P))
    (TV:BLINKER-SET-VISIBILITY *MOUSE-BLINKER* NIL)))

(DEFMETHOD (ZWEI :MOUSE-MOVES) (NEW-X NEW-Y &AUX CHAR CHAR-X CHAR-Y LINE INDEX)
  NEW-X NEW-Y
  (TV:MOUSE-SET-BLINKER-CURSORPOS)
  (AND ( NEW-X (TV:SHEET-INSIDE-LEFT)) (< NEW-X (TV:SHEET-INSIDE-RIGHT))
       (MULTIPLE-VALUE (CHAR CHAR-X CHAR-Y LINE INDEX)
	 (MOUSE-CHAR ZWEI-WINDOW)))
  (COND (CHAR
	 ;;There is a timing problem if the editor's process can disable the global blinker
	 ;;handler while we are inside it, it will turn on the blinker after the editor has
	 ;;just turned it off.
	 (WITHOUT-INTERRUPTS
	   (AND *GLOBAL-MOUSE-CHAR-BLINKER-HANDLER*
		(FUNCALL *GLOBAL-MOUSE-CHAR-BLINKER-HANDLER*
			 *GLOBAL-MOUSE-CHAR-BLINKER* ZWEI-WINDOW
			 CHAR CHAR-X CHAR-Y LINE INDEX)))
	 (TV:BLINKER-SET-SHEET *MOUSE-BLINKER* SELF)
	 (LET ((FONT (AREF TV:FONT-MAP (LDB %%CH-FONT CHAR)))
	       (CH (LDB %%CH-CHAR CHAR))
	       WIDTH)
	   (COND ((TYPEP *MOUSE-BLINKER* 'TV:CHARACTER-BLINKER)
		  (SHEET-SET-BLINKER-CURSORPOS SELF *MOUSE-BLINKER* CHAR-X CHAR-Y)
		  (TV:BLINKER-SET-CHARACTER *MOUSE-BLINKER* FONT
					    ;; Non printing characters get blinking underscore
					    (IF (OR (= CH #\SP) ( CH 200)) #/_ CH))
		  (TV:BLINKER-SET-VISIBILITY *MOUSE-BLINKER* ':BLINK))
		 ((COND ((= CH #\CR)
			 (SETQ WIDTH TV:CHAR-WIDTH)
			 (AND (< NEW-Y (+ (TV:SHEET-INSIDE-TOP) CHAR-Y TV:LINE-HEIGHT))
			      (< NEW-X (+ (TV:SHEET-INSIDE-LEFT) CHAR-X WIDTH))))
			(T
			 (SETQ WIDTH (TV:SHEET-CHARACTER-WIDTH SELF CH FONT))
			 T))
		  (SHEET-SET-BLINKER-CURSORPOS SELF *MOUSE-BLINKER* CHAR-X CHAR-Y)
		  (TV:BLINKER-SET-SIZE *MOUSE-BLINKER* WIDTH (FONT-BLINKER-HEIGHT FONT))
		  (TV:BLINKER-SET-VISIBILITY *MOUSE-BLINKER* T))
		 (T
		  (TV:BLINKER-SET-VISIBILITY *MOUSE-BLINKER* NIL)))))
	(T
	 (TV:BLINKER-SET-SHEET *MOUSE-BLINKER* SELF)
	 (TV:BLINKER-SET-VISIBILITY *MOUSE-BLINKER* NIL))))