;;; -*- Mode: Lisp; Package: User; Base: 8.; Patch-File: T -*-
;;; Patch file for System version 78.13
;;; Reason: Replace irritating "c" blinker with something better
;;; Written 12/12/81 12:25:17 by RMS,
;;; while running on Lisp Machine Six from band 2
;;; with System 78.12, ZMail 38.0, microcode 836.



; From file COMD > ZWEI; AI:
#8R ZWEI:(COMPILER-LET ((PACKAGE (PKG-FIND-PACKAGE "ZWEI")))

(defun turn-on-mini-buffer-completion-blinker (&rest ignore) nil)

(DEFUN COMPLETING-READ-FROM-MINI-BUFFER (PROMPT *COMPLETING-ALIST*
						&OPTIONAL *COMPLETING-IMPOSSIBLE-IS-OK-P*
						INITIAL-COMPLETE
						*COMPLETING-HELP-MESSAGE*
						*COMPLETING-DOCUMENTER*
						&AUX CONTENTS CHAR-POS)
  (AND INITIAL-COMPLETE
       (MULTIPLE-VALUE (CONTENTS NIL NIL NIL CHAR-POS)
	 (COMPLETE-STRING "" *COMPLETING-ALIST* *COMPLETING-DELIMS* T 0)))
  (EDIT-IN-MINI-BUFFER *COMPLETING-READER-COMTAB* CONTENTS CHAR-POS
		       (IF PROMPT `(,PROMPT (:RIGHT-FLUSH " COMPLETION"))
			 '(:RIGHT-FLUSH " COMPLETION"))))
)

; From file FILES > ZWEI; AI:
#8R ZWEI:(COMPILER-LET ((PACKAGE (PKG-FIND-PACKAGE "ZWEI")))

(DEFUN READ-DEFAULTED-PATHNAME (PROMPT *READING-PATHNAME-DEFAULTS*
				&OPTIONAL *READING-PATHNAME-SPECIAL-TYPE*
					  *READING-PATHNAME-SPECIAL-VERSION*
					  (*READING-PATHNAME-DIRECTION* ':READ)
					  (MERGE-IN-SPECIAL-VERSION T)
				&AUX (SPECIAL-VERSION *READING-PATHNAME-SPECIAL-VERSION*))
  (SETQ PROMPT (FORMAT NIL "~A (Default is ~A)" PROMPT
		       (FS:DEFAULT-PATHNAME *READING-PATHNAME-DEFAULTS* NIL
			 *READING-PATHNAME-SPECIAL-TYPE* *READING-PATHNAME-SPECIAL-VERSION*)))
  ;; MERGE-IN-SPECIAL-VERSION is for the case of wanting the default to have :OLDEST, but
  ;; not having pathnames typed in keeping to this.
  (AND (NOT MERGE-IN-SPECIAL-VERSION)
       (SETQ *READING-PATHNAME-SPECIAL-VERSION* NIL))	;Don't complete from this
  (TEMP-KILL-RING *LAST-FILE-NAME-TYPED*
    (MULTIPLE-VALUE-BIND (NIL NIL INTERVAL)
	(EDIT-IN-MINI-BUFFER *PATHNAME-READING-COMTAB* NIL NIL
			     (LIST PROMPT '(:RIGHT-FLUSH " COMPLETION")))
      (MAKE-DEFAULTED-PATHNAME (STRING-INTERVAL INTERVAL) *READING-PATHNAME-DEFAULTS*
			       *READING-PATHNAME-SPECIAL-TYPE* SPECIAL-VERSION
			       MERGE-IN-SPECIAL-VERSION))))

)

; From file MOUSE > ZWEI; AI:
#8R ZWEI:(COMPILER-LET ((PACKAGE (PKG-FIND-PACKAGE "ZWEI")))

;;; This returns the name of a function, either from the buffer with the mouse, or the
;;; mini-buffer.
;;; STRINGP of T means return a string if one is typed, don't intern it now.
;;; STRINGP of ALWAYS-READ means always return a newly read symbol, even if a completion
;;; was typed.
(DEFUN READ-FUNCTION-NAME (PROMPT &OPTIONAL DEFAULT MUST-BE-DEFINED STRINGP
				  &AUX TEM CH STR)
  (AND (EQ MUST-BE-DEFINED T) (SETQ STRINGP 'ALWAYS-READ))
  (SETQ PROMPT (FORMAT NIL "~A~:[:~; (Default: ~S)~]" PROMPT DEFAULT DEFAULT))
  (COND ((OR *MINI-BUFFER-REPEATED-COMMAND* (FUNCALL STANDARD-INPUT ':LISTEN))
	 (SETQ TEM 0 CH NIL))			;C-X , no opportunity for mouse
	(T
	 (LET ((*MODE-LINE-LIST* (LIST PROMPT '(:RIGHT-FLUSH " COMPLETION"))))
	   (REDISPLAY-MODE-LINE))		;Make correct for later
	 (DELETE-INTERVAL (WINDOW-INTERVAL *MINI-BUFFER-WINDOW*))
	 (MUST-REDISPLAY *MINI-BUFFER-WINDOW* DIS-ALL)
	 (SELECT-WINDOW *MINI-BUFFER-WINDOW*)
	 ;;KLUDGE, position blinker
	 (DO L (WINDOW-SPECIAL-BLINKER-LIST *MINI-BUFFER-WINDOW*) (CDR L) (NULL L)
	     (TV:BLINKER-SET-VISIBILITY (CDAR L) NIL))
	 (LET ((BL (WINDOW-POINT-BLINKER *MINI-BUFFER-WINDOW*)))
	   (TV:BLINKER-SET-CURSORPOS BL 0 0)
	   (TV:BLINKER-SET-VISIBILITY BL ':BLINK))
	 (UNWIND-PROTECT
	   (LET-GLOBALLY ((*GLOBAL-MOUSE-CHAR-BLINKER-HANDLER* (IF MUST-BE-DEFINED
								   #'BLINK-FUNCTION
								 #'BLINK-ATOM))
			  (*GLOBAL-MOUSE-CHAR-BLINKER-DOCUMENTATION-STRING*
			    "Click left on highlighted name to select it.")
			  (*MOUSE-FONT-CHAR* 0)
			  (*MOUSE-X-OFFSET* 4)
			  (*MOUSE-Y-OFFSET* 0))
	     (SETQ TV:MOUSE-RECONSIDER T)
	     (WITHOUT-IO-BUFFER-OUTPUT-FUNCTION
	       (MULTIPLE-VALUE (TEM CH)
		 (FUNCALL STANDARD-INPUT ':MOUSE-OR-KBD-TYI))))
	   (TV:BLINKER-SET-VISIBILITY *GLOBAL-MOUSE-CHAR-BLINKER* NIL)
	   (SETQ TV:MOUSE-RECONSIDER T))))
  (COND ((AND (= TEM #\MOUSE-1-1)
	      (MULTIPLE-VALUE-BIND (FCTN LINE START END)
		  (ATOM-UNDER-MOUSE (CADR CH))
		(COND ((OR (FBOUNDP (SETQ TEM FCTN))
			   (STRING-IN-AARRAY-P TEM *ZMACS-COMPLETION-AARRAY*)
			   (GET TEM ':SOURCE-FILE-NAME)
			   (AND (NOT MUST-BE-DEFINED) TEM))
		       (SETQ STR (SUBSTRING LINE START END))
		       T))))
	 (SELECT-WINDOW *WINDOW*)
	 (DISAPPEAR-MINI-BUFFER-WINDOW)	 
	 (OR *MINI-BUFFER-COMMAND*
	     (MINI-BUFFER-RING-PUSH (SETQ *MINI-BUFFER-COMMAND*
					  `((,*CURRENT-COMMAND*
					     ,*NUMERIC-ARG-P* ,*NUMERIC-ARG*)))))
	 (RPLACD (LAST *MINI-BUFFER-COMMAND*) (NCONS STR))
	 TEM)
	(T
	 (FUNCALL STANDARD-INPUT ':UNTYI CH)
	 (LET ((NAME (COMPLETING-READ-FROM-MINI-BUFFER PROMPT *ZMACS-COMPLETION-AARRAY*
						       (OR (NEQ STRINGP 'ALWAYS-READ)
							   'ALWAYS-STRING)))
	       SYM ERROR-P)
	   (COND ((EQUAL NAME "")
		  (OR DEFAULT (BARF))
		  (SETQ SYM DEFAULT NAME (STRING DEFAULT)))
		 ((LISTP NAME)
		  (SETQ SYM (CDR NAME)
			NAME (CAR NAME))
		  (AND (LISTP SYM) (NEQ STRINGP 'MULTIPLE-OK)
		       (SETQ SYM (CAR SYM))))
		 ((EQ STRINGP T)		;If returning a string, don't intern it
		  (SETQ SYM NAME))
		 (T
		  (MULTIPLE-VALUE (SYM NAME ERROR-P)
		    (SYMBOL-FROM-STRING NAME NIL T))
		  (AND (LISTP SYM) (EQ STRINGP 'MULTIPLE-OK)
		       (SETQ SYM (NCONS SYM)))
		  (AND ERROR-P (BARF "Read error"))))
	   (AND (EQ MUST-BE-DEFINED T) (NOT (FDEFINEDP SYM)) (BARF "~S is not defined" SYM))
	   (VALUES SYM NAME)))))

)

; From file SCREEN > ZWEI; AI:
#8R ZWEI:(COMPILER-LET ((PACKAGE (PKG-FIND-PACKAGE "ZWEI")))

;;; Update the mode line if necessary, FORCE says really do it
;;; MODE-LINE-LIST is a list of things to be displayed, whose elements can be:
;;;  a constant string
;;;  a symbol, which is evaluated to either a string or NIL, and printed in the former case
;;;  a list, the CAR of which should be an atom, which is evaluated and the rest of the
;;;    list handled as strings or symbols as above if it is non-NIL (up to any :ELSE), or
;;;    if NIL, anything after a :ELSE in the list.
;;;  eg ("FOOMACS" "(" MODE-NAME ")" (BUFFER-NAMED-P BUFFER-NAME :ELSE "(Null buffer)")
;;;      (FILE-NAME-P FILE-NAME))
;;;  a list starting with the symbol :RIGHT-FLUSH is special:
;;;    the cadr of the list is a string to be displayed flush against the right margin.
;;; As a special hack, if MODE-LINE-LIST is NIL, then the mode line is not changed,
;;;  this is appropriate for things that want to typeout on the prompt-line and then
;;;  invoke the mini-buffer.
;;; PREVIOUS-MODE-LINE is a list of strings that make up the line, since nothing we do
;;;  generates new guys for this, EQness is used to determine if the mode-line has changed
(DEFMETHOD (MODE-LINE-WINDOW-MIXIN :REDISPLAY) (MODE-LINE-LIST &OPTIONAL FORCE)
  (AND FORCE					;If we are going to type things out
       MODE-LINE-LIST				;unless suppressed
       (SETQ PREVIOUS-MODE-LINE NIL))
  (DO ((MODES MODE-LINE-LIST)
       (PREV PREVIOUS-MODE-LINE)
       (L)
       (THING))
      (NIL)
      (COND (L					;Still more to go on a list
	     (POP L THING)
	     (AND (EQ THING ':ELSE)
		  (SETQ L NIL THING NIL)))
	    ((NULL MODES)			;All done with MODE-LINE-LIST
	     (AND PREV (NOT FORCE) (FUNCALL-SELF ':REDISPLAY MODE-LINE-LIST T))
	     (RETURN NIL))
	    (T					;Get next object from MODE-LINE-LIST
	     (POP MODES THING)
	     (COND ((SYMBOLP THING)
		    (SETQ THING (SYMEVAL THING))
		    (AND (LISTP THING)		;If value is a list, dont check CAR
			 (SETQ L THING THING NIL)))
		   ((AND (LISTP THING)		;It's a list,
			 (NEQ (CAR THING) ':RIGHT-FLUSH))
		    (SETQ L THING)
		    (POP L THING)
		    (COND ((NULL (SYMEVAL THING))
			   (DO ()		;Failing conditional, look for :ELSE
			       ((NULL L))
			     (POP L THING)
			     (AND (EQ THING ':ELSE)
				  (RETURN NIL)))))
		    (SETQ THING NIL)))))	;And get stuff next pass
      (AND (SYMBOLP THING) (SETQ THING (SYMEVAL THING)))
      (COND ((NULL THING))
	    ;;THING is now the next string to be put into the mode line
	    (FORCE				;Put it in if consing new one
	     (PUSH THING PREVIOUS-MODE-LINE))
	    ((AND PREV (EQ THING (POP PREV))))	;Still matching?
	    (T					;Different thing,
	     (FUNCALL-SELF ':REDISPLAY MODE-LINE-LIST T)	;do it right this time!
	     (RETURN NIL))))
  (COND (FORCE
	 (SETQ PREVIOUS-MODE-LINE (NREVERSE PREVIOUS-MODE-LINE))
	 (COND (TV:EXPOSED-P
		(TV:SHEET-HOME SELF)
		(TV:SHEET-CLEAR-EOL SELF)
		(*CATCH 'MODE-LINE-OVERFLOW
		  (DOLIST (STR PREVIOUS-MODE-LINE)
		    (AND (STRINGP STR) (FUNCALL-SELF ':STRING-OUT STR))))
		(DOLIST (ELT PREVIOUS-MODE-LINE)
		  (AND (LISTP ELT)
		       (LET* ((STR (CADR ELT))
			      (LEN (TV:SHEET-STRING-LENGTH SELF STR)))
			 (TV:SHEET-SET-CURSORPOS SELF
						 (- (TV:SHEET-INSIDE-RIGHT SELF) LEN 1)
						 (TV:SHEET-INSIDE-TOP SELF))
			 (TV:SHEET-CLEAR-EOL SELF)
			 (*CATCH 'MODE-LINE-OVERFLOW
			   (FUNCALL-SELF ':STRING-OUT STR))
			 (RETURN)))))))))

)

; From file SEARCH > ZWEI; AI:
#8R ZWEI:(COMPILER-LET ((PACKAGE (PKG-FIND-PACKAGE "ZWEI")))

;;; Return a string itself, suitable for printing and reading back
(DEFUN GET-EXTENDED-SEARCH-16B-STRING (*SEARCH-MINI-BUFFER-NAME*)
  (LET ((*MINI-BUFFER-WINDOW* (GET-SEARCH-MINI-BUFFER-WINDOW)))
    (EDIT-IN-MINI-BUFFER *SEARCH-MINI-BUFFER-COMTAB* NIL NIL
			 '(*SEARCH-MINI-BUFFER-NAME*
			   (:RIGHT-FLUSH " EXTENDED SEARCH CHARACTERS"))))
  (SEARCH-MINI-BUFFER-STRING-INTERVAL))

)

; From file SEARCH > ZWEI; AI:
#8R ZWEI:(COMPILER-LET ((PACKAGE (PKG-FIND-PACKAGE "ZWEI")))

(DEFUN GET-EXTENDED-SEARCH-STRINGS (*SEARCH-MINI-BUFFER-NAME*
				    &AUX STR STRINGS EXPR CR-P FUNCTION)
  (DECLARE (RETURN-LIST FUNCTION ARG))
  (LET ((*MINI-BUFFER-WINDOW* (GET-SEARCH-MINI-BUFFER-WINDOW)))
    (EDIT-IN-MINI-BUFFER *SEARCH-MINI-BUFFER-COMTAB* NIL NIL
			 '(*SEARCH-MINI-BUFFER-NAME* (:RIGHT-FLUSH " EXTENDED SEARCH CHARACTERS"))))
  (SETQ STR (SEARCH-MINI-BUFFER-STRING-INTERVAL))
  (MULTIPLE-VALUE (STRINGS EXPR CR-P)
    (PARSE-EXTENDED-SEARCH-STRING STR))
  (IF (OR (LISTP STRINGS) CR-P)
      (SETQ FUNCTION 'FSM-STRING-SEARCH
	    STRINGS (LIST (IF (LISTP STRINGS) STRINGS (NCONS STRINGS)) EXPR CR-P))
      (SETQ FUNCTION 'STRING-SEARCH))
  (VALUES FUNCTION STRINGS STR))

)

; From file SEARCH > ZWEI; AI:
#8R ZWEI:(COMPILER-LET ((PACKAGE (PKG-FIND-PACKAGE "ZWEI")))

;;; Read a string for string search and then return the function to use
(DEFUN GET-EXTENDED-STRING-SEARCH-STRINGS (&OPTIONAL *EXTENDED-STRING-SEARCH-REVERSE-P*
						     (*SEARCH-MINI-BUFFER-NAME* "Search:")
						   (COMTAB *STRING-SEARCH-MINI-BUFFER-COMTAB*)
					   &AUX (*EXTENDED-STRING-SEARCH-BJ-P* NIL)
						(*EXTENDED-STRING-SEARCH-ZJ-P* NIL)
						(*EXTENDED-STRING-SEARCH-TOP-LINE-P* NIL)
						STRINGS EXPR CR-P FUNCTION)
  (DECLARE (RETURN-LIST FUNCTION ARG REVERSE-P BJ-P TOP-LINE-P))
  (LET ((*MINI-BUFFER-WINDOW* (GET-SEARCH-MINI-BUFFER-WINDOW)))
    (EDIT-IN-MINI-BUFFER COMTAB NIL NIL
			 '((*EXTENDED-STRING-SEARCH-BJ-P* "BJ ")
			   (*EXTENDED-STRING-SEARCH-ZJ-P* "ZJ ")
			   (*EXTENDED-STRING-SEARCH-REVERSE-P* "Reverse ")
			   (*EXTENDED-STRING-SEARCH-TOP-LINE-P* "Top line ")
			   *SEARCH-MINI-BUFFER-NAME*
			   (:RIGHT-FLUSH " EXTENDED SEARCH CHARACTERS"))))
  (MULTIPLE-VALUE (STRINGS EXPR CR-P)
    (PARSE-EXTENDED-SEARCH-STRING))
  (IF (LISTP STRINGS)
      (IF EXPR
	  (SETQ FUNCTION 'FSM-SEARCH-WITHIN-LINES
		STRINGS (LIST STRINGS EXPR CR-P))
	  (SETQ FUNCTION 'FSM-SEARCH))
      (SETQ FUNCTION 'SEARCH))
  (VALUES FUNCTION STRINGS
	    *EXTENDED-STRING-SEARCH-REVERSE-P*
	    (OR *EXTENDED-STRING-SEARCH-BJ-P* *EXTENDED-STRING-SEARCH-ZJ-P*)
	    *EXTENDED-STRING-SEARCH-TOP-LINE-P*))

)

