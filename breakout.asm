; * Carles Vilella, 2017 (ENTI-UB)

; *************************************************************************
; Our data section. Here we declare our strings for our console message
; *************************************************************************

SGROUP 		GROUP 	CODE_SEG, DATA_SEG
			ASSUME 	CS:SGROUP, DS:SGROUP, SS:SGROUP

    TRUE  EQU 1
    FALSE EQU 0

; EXTENDED ASCII CODES
    ASCII_SPECIAL_KEY EQU 00
    ASCII_LEFT        EQU 04Bh
    ASCII_RIGHT       EQU 04Dh
    ASCII_UP          EQU 048h
    ASCII_DOWN        EQU 050h
    ASCII_QUIT        EQU 071h ; 'q'
	ASCII_LEFT_A	  EQU 061h 
	ASCII_RIGHT_D	  EQU 064h

; ASCII / ATTR CODES TO DRAW THE SNAKE
    ASCII_PJ     EQU 02Dh
    ATTR_PJ      EQU 070h
	
; ASCII / ATTR CODES TO DRAW THE PJ
    ASCII_BALL     EQU 02Ah
    ATTR_BALL      EQU 007h

; ASCII / ATTR CODES TO DRAW THE FIELD
    ASCII_FIELD			EQU 020h ;espacio
    ATTR_FIELD_WALLS	EQU 060h ;naranja
	ATTR_FIELD_TOP		EQU 060h ;naranja
	ATTR_FIELD_DOWN		EQU	020h ;Verde
	ATTR_FIELD_INSIDE   EQU 000h ;negro
	
; ASCII / ATTR CODES TO DRAW THE BLOCKS
    ASCII_BLOCKS    EQU 023h
    ATTR_BLOCKS     EQU 024h
	
    ASCII_NUMBER_ZERO EQU 030h

; CURSOR
    CURSOR_SIZE_HIDE EQU 02607h  ; BIT 5 OF CH = 1 MEANS HIDE CURSOR
    CURSOR_SIZE_SHOW EQU 00607h

; ASCII
    ASCII_YES_UPPERCASE      EQU 059h
    ASCII_YES_LOWERCASE      EQU 079h
    
; COLOR SCREEN DIMENSIONS IN NUMBER OF CHARACTERS
    SCREEN_MAX_ROWS EQU 25
    SCREEN_MAX_COLS EQU 25

; FIELD DIMENSIONS
    FIELD_R1 EQU 1
    FIELD_R2 EQU SCREEN_MAX_ROWS-2
    FIELD_C1 EQU 1
    FIELD_C2 EQU SCREEN_MAX_COLS-2
	
;	BLOCKS DIMENSIONS
	BLOCKS_T1 EQU 2
	BLOCKS_D1 EQU 2
	BLOCKS_D2 EQU SCREEN_MAX_COLS-3
	
	BLOCKS_ROWS EQU 5
;	Initial position of bar
	INITIAL_POS_ROW_PJ EQU SCREEN_MAX_ROWS-4    
    INITIAL_POS_COL_PJ EQU SCREEN_MAX_COLS/2
	; Initial position ball
	INITIAL_POS_ROW_BALL EQU SCREEN_MAX_ROWS-5    
	INITIAL_POS_COL_BALL EQU SCREEN_MAX_COLS/2
	;Aesthetics of power up
	ATTR_POWER_UP_INC_VEL EQU 0AFh
	ATTR_POWER_UP_DEC_VEL EQU 0CFh
	ASCII_POWER_UP EQU 040h
	;Limits of the spawn range
	P_UP_MIN_X EQU 2
	P_UP_MAX_X EQU SCREEN_MAX_COLS-3
	P_UP_MIN_Y EQU 7
	P_UP_MAX_Y EQU SCREEN_MAX_ROWS-6
; *************************************************************************
; Our executable assembly code starts here in the .code section
; *************************************************************************
CODE_SEG	SEGMENT PUBLIC
	ORG 100h

MAIN 	PROC 	NEAR

MAIN_GO:

	CALL REGISTER_TIMER_INTERRUPT

	CALL INIT_GAME
	CALL INIT_SCREEN
	CALL HIDE_CURSOR
	CALL DRAW_FIELD
	CALL DRAW_BLOCKS

	MOV DH, INITIAL_POS_ROW_PJ
	MOV DL, INITIAL_POS_COL_PJ

	CALL MOVE_CURSOR

MAIN_LOOP:
	CMP [END_GAME], TRUE
	JZ END_PROG

	; Check if a key is available to read
	MOV AH, 0Bh
	INT 21h
	CMP AL, 0
	JZ MAIN_LOOP

	; A key is available -> read
	CALL READ_CHAR      

	; End game?
	CMP AL, ASCII_QUIT
	JZ END_PROG

	; Is it an special key?
	CMP AL, ASCII_SPECIAL_KEY
	JZ READ_ESPECIAL_CHAR
	JMP INPUT_NORMAL_CHAR

READ_ESPECIAL_CHAR:
	CALL READ_CHAR
	
	; The game is on!
	MOV [START_GAME], TRUE

	CMP AL, ASCII_RIGHT
	JZ RIGHT_KEY
	CMP AL, ASCII_LEFT
	JZ LEFT_KEY
	JMP MAIN_LOOP
	
INPUT_NORMAL_CHAR:
	MOV [START_GAME], TRUE
	
	CMP AL, ASCII_RIGHT_D
	JZ RIGHT_KEY
	CMP AL, ASCII_LEFT_A
	JZ LEFT_KEY
	
	JMP MAIN_LOOP

RIGHT_KEY:
	MOV [INC_COL_PJ], 1
	MOV [INC_ROW_PJ], 0
	JMP END_KEY

LEFT_KEY:
	MOV [INC_COL_PJ], -1
	MOV [INC_ROW_PJ], 0
	JMP END_KEY

END_KEY:
	CALL MOVE_PJ
	JMP MAIN_LOOP

END_PROG:
	MOV [POS_COL_BALL], INITIAL_POS_COL_BALL
	MOV [POS_ROW_BALL], INITIAL_POS_ROW_BALL
	MOV [INC_COL_BALL],1
	MOV [INC_ROW_BALL],-1
	
	MOV [POS_COL_PJ], INITIAL_POS_COL_PJ
	MOV [POS_ROW_PJ], INITIAL_POS_ROW_PJ
	MOV[POWER_UP_ON_SCREEN],FALSE
	
	CALL RESTORE_TIMER_INTERRUPT
	CALL SHOW_CURSOR
	CALL PRINT_SCORE_STRING
	CALL PRINT_SCORE
	CALL PRINT_PLAY_AGAIN_STRING
	
	CALL PRINT_CREDITS

	CALL READ_CHAR

	CMP AL, ASCII_YES_UPPERCASE
	JZ MAIN_GO
	CMP AL, ASCII_YES_LOWERCASE
	JZ MAIN_GO
	
	INT 20h		

MAIN	ENDP	

; ****************************************
; Reset internal variables
; Entry: 
;   
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   INC_COL_PJ memory variable
;   INC_ROW_PJ memory variable
;   DIV_SPEED memory variable
;   NUM_BLOCKS memory variable
;   START_GAME memory variable
;   END_GAME memory variable
; Calls:
;   -
; ****************************************
                  PUBLIC  INIT_GAME
INIT_GAME         PROC    NEAR

    MOV [INC_ROW_PJ], 0
    MOV [INC_COL_PJ], 0

    MOV [DIV_SPEED], 10

    MOV [NUM_BLOCKS], 0
    MOV [SCORE_BLOCKS], 0
	
    MOV [START_GAME], FALSE
    MOV [END_GAME], FALSE

    RET
INIT_GAME	ENDP	

; ****************************************
; Reads char from keyboard
; If char is not available, blocks until a key is pressed
; The char is not output to screen
; Entry: 
;
; Returns:
;   AL: ASCII CODE
;   AH: ATTRIBUTE
; Modifies:
;   
; Uses: 
;   
; Calls:
;   
; ****************************************
PUBLIC  READ_CHAR
READ_CHAR PROC NEAR

    MOV AH, 08h
    INT 21h

    RET
      
READ_CHAR ENDP


; ****************************************
; Read character and attribute at cursor position, page 0
; Entry: 
;
; Returns:
;   AL: ASCII CODE
;   AH: ATTRIBUTE
; Modifies:
;   
; Uses: 
;   
; Calls:
;   int 10h, service AH=8
; ****************************************
PUBLIC READ_SCREEN_CHAR                 
READ_SCREEN_CHAR PROC NEAR

    PUSH BX

    MOV AH, 8
    XOR BH, BH
    INT 10h

    POP BX
    RET
      
READ_SCREEN_CHAR  ENDP

; ****************************************
; Draws the rectangular field of the game
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   Coordinates of the rectangle: 
;    left - top: (FIELD_R1, FIELD_C1) 
;    right - bottom: (FIELD_R2, FIELD_C2)
;   Character: ASCII_FIELD
;   Attribute: ATTR_FIELD_WALLS
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC DRAW_FIELD
DRAW_FIELD PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

	MOV AL, ASCII_FIELD; el char es el mismo para todos
	
    MOV DL, FIELD_C2
  UP_DOWN_SCREEN_LIMIT:
    MOV DH, FIELD_R1
    CALL MOVE_CURSOR	
    MOV BL, ATTR_FIELD_TOP
    CALL PRINT_CHAR_ATTR

    MOV DH, FIELD_R2
    CALL MOVE_CURSOR
	MOV BL, ATTR_FIELD_DOWN
    CALL PRINT_CHAR_ATTR

    DEC DL
    CMP DL, FIELD_C1
    JNS UP_DOWN_SCREEN_LIMIT

    MOV DH, FIELD_R2
	MOV BL, ATTR_FIELD_WALLS; las dos paredes naranjas
  LEFT_RIGHT_SCREEN_LIMIT:
    MOV DL, FIELD_C1
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    MOV DL, FIELD_C2
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    DEC DH
    CMP DH, FIELD_R1
    JNS LEFT_RIGHT_SCREEN_LIMIT
                 
    POP DX
    POP BX
    POP AX
    RET

DRAW_FIELD       ENDP

; ****************************************
; Draws the blocks of the field of the game
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   Coordinates of the blocks: 
;	BLOCKS_T1 
;	BLOCKS_D1 
;	BLOCKS_D2
;    rows of blocks: (BLOCKS_ROWS) 
;   Character: ASCII_BLOCKS
;   Attribute: ATTR_BLOCKS
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC DRAW_BLOCKS
DRAW_BLOCKS PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX
	PUSH CX
	PUSH SI
	
    MOV AL, ASCII_BLOCKS
    MOV BL, ATTR_BLOCKS
	MOV CL, BLOCKS_ROWS
	MOV DH, BLOCKS_T1
	MOV SI,1
  ALL_ROWS:
    MOV DL, BLOCKS_D2
  ONE_ROW:
    CALL MOVE_CURSOR
    CALL PRINT_CHAR_ATTR

    DEC DL
    CMP DL, BLOCKS_D1
    JNS ONE_ROW
	
	INC SI
	INC DH
	CMP SI, BLOCKS_ROWS
	JLE ALL_ROWS
	
	POP SI
	POP CX
    POP DX
    POP BX
    POP AX
    RET

DRAW_BLOCKS       ENDP
; ****************************************
; Moves de cursor to the player Pos and moves it to the next pos
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses:  INC_COL_PJ, INC_ROW_PJ
;	
; Calls:
;   MOVE_CURSOR_TO_PJ, MOVE_CURSOR
; ****************************************
PUBLIC MOVE_CURSOR_FOR_PJ
MOVE_CURSOR_FOR_PJ PROC NEAR

	CALL MOVE_CURSOR_TO_PJ
    ADD DL, [INC_COL_PJ]
    ADD DH, [INC_ROW_PJ]
	
	CALL MOVE_CURSOR
	RET
	
MOVE_CURSOR_FOR_PJ ENDP

; ****************************************
; Moves the cursor to the current position of the pj
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: POS_COL_PJ, POS_ROW_PJ
;
; Calls:
;   MOVE_CURSOR
; ****************************************
PUBLIC MOVE_CURSOR_TO_PJ
MOVE_CURSOR_TO_PJ PROC NEAR
	MOV DL, [POS_COL_PJ]
	MOV DH, [POS_ROW_PJ]
	CALL MOVE_CURSOR
	RET
	
MOVE_CURSOR_TO_PJ ENDP

; ****************************************
; Prints the pj on the cursor position and deletes the previus position
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   character: ASCII_PJ
;   attribute: ATTR_PJ
; Calls:
;   PRINT_CHAR_ATTR, MOVE_CURSOR
; ****************************************
PUBLIC PRINT_PJ
PRINT_PJ PROC NEAR

    PUSH AX
    PUSH BX
    MOV AL, ASCII_PJ
    MOV BL, ATTR_PJ
    CALL PRINT_CHAR_ATTR
	
	PUSH DX ; PALA IZQUIERDA
	ADD DL, -1
	CALL MOVE_CURSOR
	POP DX
	CALL PRINT_CHAR_ATTR
	
	PUSH DX ;PALA DERECHA
	ADD DL, 1
	CALL MOVE_CURSOR
	POP DX
	CALL PRINT_CHAR_ATTR
	;BORREMOS LA PALA 
	CMP	INC_COL_PJ, 1 ; SI SE MUEVE HACIA LA DERECHA
	JZ REMOVE_LEFT
	CMP	INC_COL_PJ, -1 ; SI SE MUEVE HACIA LA DERECHA
	JZ REMOVE_RIGHT
	JMP END_PRINT_PJ
	
REMOVE_LEFT:
	; muevo el cursor hacia la barra que quiero borrar
	PUSH DX
	ADD DL, -2
	CALL MOVE_CURSOR
	POP DX
	;QUITO el char de barra y el fondo blanco
	MOV AL, ASCII_FIELD
    MOV BL, ATTR_FIELD_INSIDE
    CALL PRINT_CHAR_ATTR
	JMP END_PRINT_PJ
REMOVE_RIGHT:
	; muevo el cursor hacia la barra que quiero borrar
	PUSH DX
	ADD DL, 2
	CALL MOVE_CURSOR
	POP DX
	;QUITO el char de barra y el fondo blanco
	MOV AL, ASCII_FIELD
    MOV BL, ATTR_FIELD_INSIDE
    CALL PRINT_CHAR_ATTR
	JMP END_PRINT_PJ

END_PRINT_PJ:
    POP BX
    POP AX
    RET

PRINT_PJ        ENDP 
; ****************************************
; 
; Entry: 
; 
; Returns:
;   
; Modifies: POS_COL_PJ, POS_ROW_PJ, INC_COL_PJ, INC_ROW_PJ
;   
; Uses: 
;
; Calls:
;   MOVE_CURSOR_FOR_PJ, PRINT_PJ
; ****************************************
PUBLIC MOVE_PJ
MOVE_PJ PROC NEAR
	PUSH AX
	
	CALL MOVE_CURSOR_TO_PJ
	CMP	INC_COL_PJ, 1 ;si se mueve hacia la derecha comprobamos si colisiona por la derecha
	JZ COLL_RIGHT
	CMP	INC_COL_PJ, -1 ;si se mueve hacia la izquierda comprobamos si colisiona por la izquierda
	JZ COLL_LEFT
	JMP END_PRINT

NO_INC_POS_PJ: ; no se cambia la posicion
	MOV [INC_COL_PJ], 0
	MOV [INC_ROW_PJ], 0
	JMP END_PRINT

COLL_RIGHT:
	PUSH DX
	ADD DL, 2 ; para comprobar la colision con la de la pala derecha
	CALL MOVE_CURSOR
	POP DX
	CALL READ_SCREEN_CHAR
	CMP AH, ATTR_FIELD_WALLS
	JZ NO_INC_POS_PJ ; si colisiona 
	JMP END_PRINT; si no colisiona
	
COLL_LEFT:
	PUSH DX
	ADD DL, -2 ; para comprobar la colision con la pala izquierda
	CALL MOVE_CURSOR 
	POP DX
	CALL READ_SCREEN_CHAR
	CMP AH, ATTR_FIELD_WALLS
	JZ NO_INC_POS_PJ; si colisiona
	; sino sigue hasta el final
END_PRINT:
	CALL MOVE_CURSOR_FOR_PJ ; usando el incremento de posicion del pj mueve el cursor a su destino
	CALL PRINT_PJ ; printa al pj 
	; guarda la posicion del pj
	MOV [POS_COL_PJ], DL 
	MOV [POS_ROW_PJ], DH
	
	POP AX
	RET
MOVE_PJ ENDP


; ****************************************
; Prints the ball, at the current cursos position
; Entry: 
; 
; Returns:
;   
; Modifies:
;   
; Uses: 
;   character: ASCII_BALL
;   attribute: ATTR_BALL
; Calls:
;   PRINT_CHAR_ATTR
; ****************************************
PUBLIC PRINT_BALL
PRINT_BALL PROC NEAR

    PUSH AX
    PUSH BX
	
    MOV AL, ASCII_BALL
    MOV BL, ATTR_BALL
    CALL PRINT_CHAR_ATTR
      
    POP BX
    POP AX
    RET

PRINT_BALL        ENDP  

; ****************************************
; Prints character and attribute in the 
; current cursor position, page 0 
; Keeps the cursor position
; Entry: 
;   AL: ASCII to print
;   BL: ATTRIBUTE to print
; Returns:
;   
; Modifies:
;   
; Uses: 
;
; Calls:
;   int 10h, service AH=9
; Nota:
;   Compatibility problem when debugging
; ****************************************
PUBLIC PRINT_CHAR_ATTR
PRINT_CHAR_ATTR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX

    MOV AH, 9
    MOV BH, 0
    MOV CX, 1
    INT 10h

    POP CX
    POP BX
    POP AX
    RET

PRINT_CHAR_ATTR        ENDP     

; ****************************************
; Prints character and attribute in the 
; current cursor position, page 0 
; Cursor moves one position right
; Entry: 
;    AL: ASCII code to print
; Returns:
;   
; Modifies:
;   
; Uses: 
;
; Calls:
;   int 21h, service AH=2
; ****************************************
PUBLIC PRINT_CHAR
PRINT_CHAR PROC NEAR

    PUSH AX
    PUSH DX

    MOV AH, 2
    MOV DL, AL
    INT 21h

    POP DX
    POP AX
    RET

PRINT_CHAR        ENDP     

; ****************************************
; Set screen to mode 3 (80x25, color) and 
; clears the screen
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   Screen size: SCREEN_MAX_ROWS, SCREEN_MAX_COLS
; Calls:
;   int 10h, service AH=0
;   int 10h, service AH=6
; ****************************************
PUBLIC INIT_SCREEN
INIT_SCREEN	PROC NEAR

      PUSH AX
      PUSH BX
      PUSH CX
      PUSH DX

      ; Set screen mode
      MOV AL,3
      MOV AH,0
      INT 10h

      ; Clear screen
      XOR AL, AL
      XOR CX, CX
      MOV DH, SCREEN_MAX_ROWS
      MOV DL, SCREEN_MAX_COLS
      MOV BH, 7
      MOV AH, 6
      INT 10h
      
      POP DX      
      POP CX      
      POP BX      
      POP AX      
	RET

INIT_SCREEN		ENDP

; ****************************************
; Hides the cursor 
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC  HIDE_CURSOR
HIDE_CURSOR PROC NEAR

      PUSH AX
      PUSH CX
      
      MOV AH, 1
      MOV CX, CURSOR_SIZE_HIDE
      INT 10h

      POP CX
      POP AX
      RET

HIDE_CURSOR       ENDP

; ****************************************
; Shows the cursor (standard size)
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=1
; ****************************************
PUBLIC SHOW_CURSOR
SHOW_CURSOR PROC NEAR

    PUSH AX
    PUSH CX
      
    MOV AH, 1
    MOV CX, CURSOR_SIZE_SHOW
    INT 10h

    POP CX
    POP AX
    RET

SHOW_CURSOR       ENDP

; ****************************************
; Get cursor properties: coordinates and size (page 0)
; Entry: 
;   -
; Returns:
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=3
; ****************************************
PUBLIC GET_CURSOR_PROP
GET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 3
      XOR BX, BX
      INT 10h

      POP BX
      POP AX
      RET
      
GET_CURSOR_PROP       ENDP

; ****************************************
; Set cursor properties: coordinates and size (page 0)
; Entry: 
;   (DH, DL): coordinates -> (row, col)
;   (CH, CL): cursor size
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 10h, service AH=2
; ****************************************
PUBLIC SET_CURSOR_PROP
SET_CURSOR_PROP PROC NEAR

      PUSH AX
      PUSH BX

      MOV AH, 2
      XOR BX, BX
      INT 10h

      POP BX
      POP AX
      RET
      
SET_CURSOR_PROP       ENDP

; ****************************************
; Move cursor to coordinate
; Cursor size if kept
; Entry: 
;   (DH, DL): coordinates -> (row, col)
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
; ****************************************
PUBLIC MOVE_CURSOR
MOVE_CURSOR PROC NEAR

      PUSH DX
      CALL GET_CURSOR_PROP  ; Get cursor size
      POP DX
      CALL SET_CURSOR_PROP
      RET

MOVE_CURSOR       ENDP
; ****************************************
; Print string to screen
; The string end character is '$'
; Entry: 
;   DX: pointer to string
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCREEN_MAX_COLS
; Calls:
;   INT 21h, service AH=9
; ****************************************
PUBLIC PRINT_STRING
PRINT_STRING PROC NEAR

    PUSH DX
      
    MOV AH,9
    INT 21h

    POP DX
    RET

PRINT_STRING       ENDP

; ****************************************
; Print the score string, starting in the cursor
; (FIELD_C1, FIELD_R2) coordinate
; Entry: 
;   DX: pointer to string
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   SCORE_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   GET_CURSOR_PROP
;   SET_CURSOR_PROP
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_SCORE_STRING
PRINT_SCORE_STRING PROC NEAR

    PUSH CX
    PUSH DX

    CALL GET_CURSOR_PROP  ; Get cursor size
    MOV DH, FIELD_R2+1
    MOV DL, FIELD_C1
    CALL SET_CURSOR_PROP

    LEA DX, SCORE_STR
    CALL PRINT_STRING

    POP CX
    POP DX
    RET

PRINT_SCORE_STRING       ENDP

; ****************************************
; Print the score string, starting in the
; current cursor coordinate
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   PLAY_AGAIN_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_PLAY_AGAIN_STRING
PRINT_PLAY_AGAIN_STRING PROC NEAR

    PUSH DX

    LEA DX, PLAY_AGAIN_STR
    CALL PRINT_STRING

    POP DX
    RET

PRINT_PLAY_AGAIN_STRING       ENDP
; ****************************************
; Print the score string, starting in the
; current cursor coordinate
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   PLAY_AGAIN_STR
;   FIELD_C1
;   FIELD_R2
; Calls:
;   PRINT_STRING
; ****************************************
PUBLIC PRINT_CREDITS
PRINT_CREDITS PROC NEAR
	PUSH DX
	PUSH CX
	
	CALL GET_CURSOR_PROP  ; Get cursor size
    MOV DH, SCREEN_MAX_ROWS/2
    MOV DL, SCREEN_MAX_COLS+2
    CALL SET_CURSOR_PROP
	
	LEA DX, CREDITS_STRING
	CALL PRINT_STRING
	
	CALL GET_CURSOR_PROP  ; Get cursor size
    ADD DH, 1
	MOV DL, SCREEN_MAX_COLS+2
    CALL SET_CURSOR_PROP
	
	LEA DX, CREDITS_STRING_ENTI
	CALL PRINT_STRING
	
	CALL GET_CURSOR_PROP  ; Get cursor size
    MOV DH, FIELD_R2+1
    MOV DL, FIELD_C1
    CALL SET_CURSOR_PROP
	
	POP CX
	POP DX
	RET
PRINT_CREDITS ENDP

; ****************************************
; Prints the score of the player in decimal, on the screen, 
; starting in the cursor position
; NUM_BLOCKS range: [0, 9999]
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   NUM_BLOCKS memory variable
; Calls:
;   PRINT_CHAR
; ****************************************
PUBLIC PRINT_SCORE
PRINT_SCORE PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; 1000'
    MOV AX, [SCORE_BLOCKS]
    XOR DX, DX
    MOV BX, 1000
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 100'
    MOV AX, DX        ; Remainder
    XOR DX, DX
    MOV BX, 100
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 10'
    MOV AX, DX          ; Remainder
    XOR DX, DX
    MOV BX, 10
    DIV BX            ; DS:AX / BX -> AX: quotient, DX: remainder
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    ; 1'
    MOV AX, DX
    ADD AL, ASCII_NUMBER_ZERO
    CALL PRINT_CHAR

    POP DX
    POP CX
    POP BX
    POP AX
    RET   
         
PRINT_SCORE        ENDP

; ****************************************
; Move, print and clean the ball of the screen
; Entry: 
;   
; Returns:
;   -
; Modifies:
;   POS_COL_BALL
;	POS_ROW_BALL
; Uses: 
;   POS_COL_BALL
;	POS_ROW_BALL
;	ASCII_FIELD
;	ATTR_FIELD_INSIDE
;	INC_COL_BALL
;	INC_ROW_BALL
; Calls:
;   MOVE_CURSOR
;	PRINT_CHAR_ATTR
;	PRINT_BALL
; ****************************************
PUBLIC MOVE_BALL
MOVE_BALL PROC NEAR
	PUSH DX
	PUSH AX
	PUSH BX
	
; Load BALL coordinates
	MOV DL, [POS_COL_BALL]
    MOV DH, [POS_ROW_BALL]
	CALL MOVE_CURSOR
	MOV AL, ASCII_FIELD
    MOV BL, ATTR_FIELD_INSIDE
	CALL PRINT_CHAR_ATTR
;Comprobamos las colisiones	
;player
	CALL BALL_PLAYER
;Paredes
	CALL BALL_COLISION
;volvemos a comprobar la colision con el player, si no se hace no podria colisionar con el pj y despues con la pared o veceversa de ;forma seguida
	CALL BALL_PLAYER
;Power Ups
	CALL COLISION_POWER_UP
; Añadimos el incremento de posicion
	ADD DL,[INC_COL_BALL]
	ADD DH,[INC_ROW_BALL]
;Actualizamos las variables posición a la nueva
	MOV [POS_COL_BALL],DL
	MOV [POS_ROW_BALL],DH
	
; Move BALL on the screen
    CALL MOVE_CURSOR
; Dibujamos la pelota
	CALL PRINT_BALL
	
	POP BX
	POP AX
	POP DX
    RET

MOVE_BALL       ENDP
; ****************************************
; Comprueba las colisiones de la pelota con el player
; dependiendo de como y con que pala colisione la balL modifica su incremento.
; Tambien comprobomaos las colisiones con el suelo.
; Entry: 
;   -
; Returns:
;   -
; Modifies: INC_COL_BALL, INC_ROW_BALL
; Uses: POS_COL_PJ, POS_ROW_PJ, 
;		INC_COL_BALL, INC_ROW_BALL
; Calls:
;		MOVE_CURSOR, 
;		READ_SCREEN_CHAR,
; ****************************************
PUBLIC BALL_PLAYER
BALL_PLAYER PROC NEAR
	PUSH AX
	PUSH DX
	PUSH CX
	ADD DL, [INC_COL_BALL]
	ADD DH, [INC_ROW_BALL]
	CALL MOVE_CURSOR ; movemos el cursor a la siguiente posicion de la pelota
	
	CALL READ_SCREEN_CHAR
	CMP AH, ATTR_PJ ; si encuentra un attributo de pj
	JZ CHECK_ASCIIPJ
	CMP AH, ATTR_FIELD_DOWN ; si colisiona con el suelo
	JZ END_THE_GAME
	JMP BALL_PJENDP ; sino salta al final y no hace nada
	
CHECK_ASCIIPJ:; chekea si es el ascii del pj
	CMP AL, ASCII_PJ
	JZ BALL_COLLPJ ; si el es el pj
	JMP BALL_PJENDP
	
BALL_COLLPJ: ;comprueba cual es la pala que se borrarria si pusiesemos la pelota en esa posicion 
	CMP DL, [POS_COL_PJ] ; es la del centro?
	JZ COLL_PJ_CENTER
	
	MOV CL, [POS_COL_PJ] 
	INC CL ; es la de la derecha?
	CMP DL, CL
	JZ COLL_PJ_RIGHT
	
	MOV CL, [POS_COL_PJ]
	ADD CL,-1 ; es la de la izquierda?
	CMP DL, CL
	JZ COLL_PJ_LEFT
	
COLL_PJ_CENTER:; saldra hacia arriba
	MOV [INC_ROW_BALL], -1
	MOV [INC_COL_BALL], 0
	JMP BALL_PJENDP
COLL_PJ_RIGHT:; hacia la derecha
	MOV [INC_ROW_BALL], -1
	MOV [INC_COL_BALL], 1
	JMP BALL_PJENDP
COLL_PJ_LEFT: ; saldra hacia la izquierda
	MOV [INC_ROW_BALL], -1
	MOV [INC_COL_BALL], -1
	JMP BALL_PJENDP
	
END_THE_GAME: ; se acaba el juego y movemos la pelota hacia arriba para no borrar el campo
	MOV [INC_ROW_BALL], -1
	MOV [INC_COL_BALL], 0
	MOV [END_GAME], TRUE
	
BALL_PJENDP:
	POP CX
	POP DX
	POP AX
	RET
BALL_PLAYER ENDP
; ****************************************
PUBLIC BALL_COLISION
BALL_COLISION PROC NEAR
	PUSH AX
	
START:
	CALL CALCULATE_TOP_LADO
	;CÁLCULO DEL BOOLEANO TOP
	MOV AH, [BALL_TOP_X]
	MOV AL, [BALL_TOP_Y]
	CALL CHECK_COLLISION
	MOV AL, [BALL_CHECK_COLISION]
	MOV [BALL_TOP], AL
	;CÁLCULO DEL BOOLEANO LADO
	MOV AH, [BALL_LADO_X]
	MOV AL, [BALL_LADO_Y]
	CALL CHECK_COLLISION
	MOV AL, [BALL_CHECK_COLISION]
	MOV [BALL_LADO], AL
	;CÁLCULO DEL BOOLEANO NEXT
	MOV AH, [BALL_NEXT_X]
	MOV AL, [BALL_NEXT_Y]
	CALL CHECK_COLLISION
	MOV AL, [BALL_CHECK_COLISION]
	MOV [BALL_NEXT], AL
	;MIRAMOS SI HAY BLOQUE EN LA POSICIÓN SUPERIOR DE LA PELOTA
	CMP [BALL_TOP],TRUE
	JNZ TOP_FALSE
	
TOP_TRUE:
	PUSH AX
	;INVIERTE VELOCIDAD EN Y
	MOV AL,-1
	MUL [INC_ROW_BALL]
	MOV [INC_ROW_BALL],AL
	POP AX
	;IF IS_BLOCK 
	PUSH AX
	MOV AH, [BALL_TOP_X]
	MOV AL, [BALL_TOP_Y]
	CALL CHECK_COLLISION_BLOCK
	POP AX
	CMP [BALL_COLISION_BLOCK],TRUE
	JNZ TOP_TRUE_JUMP
TOP_TRUE_DESTROY:
	;DESTROY_BLOCK
	PUSH AX
	MOV AH,[BALL_TOP_X]
	MOV AL,[BALL_TOP_Y]
	CALL DESTROY_BLOCK
	POP AX
TOP_TRUE_JUMP:
	JMP START
		
TOP_FALSE: 

	;MIRAMOS SI HAY BLOQUE AL LADO DE LA PELOTA	
	CMP [BALL_LADO],TRUE
	JNZ LADO_FALSE
	
LADO_TRUE:
	;Comparamos que la velocidad en Y sea diferente a 0
	CMP [INC_COL_BALL],0
	JZ LADO_FALSE
	
	PUSH AX
	;INVIERTE LA VELOCIDAD EN X
	MOV AL,-1
	MUL [INC_COL_BALL]
	MOV [INC_COL_BALL],AL
	POP AX
	;IF IS_BLOCK
	PUSH AX
	MOV AH, [BALL_LADO_X]
	MOV AL, [BALL_LADO_Y]
	CALL CHECK_COLLISION_BLOCK
	POP AX
	CMP [BALL_COLISION_BLOCK],1
	JNZ LADO_TRUE_JUMP
LADO_TRUE_DESTROY:
	;DESTROY_BLOCK
	PUSH AX
	MOV AH,[BALL_LADO_X]
	MOV AL,[BALL_LADO_Y]
	CALL DESTROY_BLOCK
	POP AX
LADO_TRUE_JUMP:
		JMP START
		
LADO_FALSE:
	
	CMP [BALL_NEXT],TRUE
	JNZ NEXT_FALSE
	
NEXT_TRUE:
	PUSH AX
	;INVIERTE VELOCIDAD EN X E Y
	MOV AL,-1
	MUL [INC_COL_BALL]
	MOV [INC_COL_BALL],AL
	MOV AL,-1
	MUL [INC_ROW_BALL]
	MOV [INC_ROW_BALL],AL
	POP AX
	;IF IS_BLOCK 
	PUSH AX
	MOV AH, [BALL_NEXT_X]
	MOV AL, [BALL_NEXT_Y]
	CALL CHECK_COLLISION_BLOCK
	POP AX
	CMP [BALL_COLISION_BLOCK],TRUE
	JNZ NEXT_TRUE_JUMP
NEXT_TRUE_DESTROY:
	;DESTROY_BLOCK
	PUSH AX
	MOV AH,[BALL_NEXT_X]
	MOV AL,[BALL_NEXT_Y]
	CALL DESTROY_BLOCK
	POP AX
NEXT_TRUE_JUMP:
	JMP START
	
NEXT_FALSE:

	POP AX
	RET
BALL_COLISION ENDP
; ****************************************
; Check if wheter the given position is a limit or block
; Entry: 
;   AH: X coord of the position
;	AL: Y coord of the position
; Returns:
;   -
; Modifies:
;   BALL_CHECK_COLISION
; Uses: 
;	ASCII_FIELD
;	ATTR_FIELD_INSIDE
;   BALL_CHECK_COLISION
; Calls:
;   MOVE_CURSOR
;	READ_SCREEN_CHAR
; ****************************************
PUBLIC 	CHECK_COLLISION
CHECK_COLLISION PROC NEAR
	PUSH AX
	PUSH DX
	
	MOV DL,AH
	MOV DH,AL
    CALL MOVE_CURSOR		; Muevo el cursor a la posicion dada
	
    CALL READ_SCREEN_CHAR	; Leo el char y atributo que hay en la posicion
    CMP AH, ATTR_FIELD_WALLS
    JZ RETURN_TRUE_COLISION
	
SECOND_CONDITION:
	CMP AH, ATTR_BLOCKS
    JZ RETURN_TRUE_COLISION
	JMP RETURN_FALSE_COLISION	
	
RETURN_TRUE_COLISION:
	MOV [BALL_CHECK_COLISION],TRUE
	JMP END_FUNCTION
RETURN_FALSE_COLISION:
	MOV [BALL_CHECK_COLISION],FALSE
	
END_FUNCTION:
	POP DX
	POP AX

	RET
CHECK_COLLISION ENDP
; ****************************************
; Check if wheter the given position is a block
; Entry: 
;   AH: X coord of the position
;	AL: Y coord of the position
; Returns:
;   -
; Modifies:
;   BALL_COLISION_BLOCK
; Uses: 
;	BALL_COLISION_BLOCK
;	ATTR_BLOCKS
; Calls:
;   MOVE_CURSOR
;   READ_SCREEN_CHAR
; ****************************************
PUBLIC 	CHECK_COLLISION_BLOCK
CHECK_COLLISION_BLOCK PROC NEAR
	PUSH AX
	PUSH DX
	
	MOV DL,AH
	MOV DH,AL
    CALL MOVE_CURSOR		; Muevo el cursor a la posicion dada
    CALL READ_SCREEN_CHAR	; Leo el char y atributo que hay en la posicion
    CMP AH, ATTR_BLOCKS
    JNZ RETURN_FALSE_BLOCK
	
RETURN_TRUE_BLOCK:
	MOV [BALL_COLISION_BLOCK],TRUE
	JMP END_FUNCTION
RETURN_FALSE_BLOCK:
	MOV [BALL_COLISION_BLOCK],FALSE
	
END_FUNCTION:
	POP DX
	POP AX
	CALL MOVE_CURSOR
	RET
CHECK_COLLISION_BLOCK ENDP
; ****************************************
; Write the 'space' char on the given coordinates
; Entry: 
;   AH: X coord of the position
;	AL: Y coord of the position
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;	ASCII_FIELD
;   ATTR_FIELD_INSIDE
; Calls:
;   MOVE_CURSOR
;	PRINT_CHAR_ATTR
; ****************************************
PUBLIC 	DESTROY_BLOCK
DESTROY_BLOCK PROC NEAR
	PUSH AX
	PUSH DX
	PUSH BX
	
	MOV DL,AH
	MOV DH,AL
    CALL MOVE_CURSOR		; Muevo el cursor a la posicion dada
    MOV AL, ASCII_FIELD
	MOV BL, ATTR_FIELD_INSIDE
	CALL PRINT_CHAR_ATTR
	ADD [NUM_BLOCKS], 1
	ADD [NUM_OF_BLOCK], -1
	CMP [NUM_OF_BLOCK], 0
	ADD [SCORE_BLOCKS],1	
	JZ YOU_WIN
	JMP END_DESTRY

YOU_WIN:
	MOV [END_GAME], TRUE
	JMP END_DESTRY

END_DESTRY:	
	POP BX
	POP DX
	POP AX
	
	CALL MOVE_CURSOR ; DEVUELVO EL CURSOR A SU POSICION INICIAL
	RET
DESTROY_BLOCK ENDP
; ****************************************
; Calculate the coordinates of the actual top, side and next position of the ball, it depens of the velocity(INC_COL_BALL,INC_ROW_BALL)
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;	BALL_TOP_X
;	BALL_TOP_Y
;   BALL_LADO_X
;	BALL_LADO_Y
;   BALL_NEXT_X
;	BALL_NEXT_Y
; Uses: 
;	POS_COL_BALL
;	POS_ROW_BALL
;	INC_ROW_BALL
;	INC_COL_BALL
; Calls:
;   -
; ****************************************
PUBLIC 	CALCULATE_TOP_LADO
CALCULATE_TOP_LADO PROC NEAR
	PUSH AX
	;CÁLCULO DE LA NEXT POSITION DE LA BALL
	MOV AL, [POS_COL_BALL]
	MOV AH, [POS_ROW_BALL]
	ADD AL, [INC_COL_BALL]
	ADD AH, [INC_ROW_BALL]
	MOV [BALL_NEXT_X], AL
	MOV [BALL_NEXT_Y], AH
	;CÁLCULO DE TOP Y NEXT POSITION
	CMP[INC_ROW_BALL],0	; Comparo si la velocidad en Y en positiva o negativa
	JNS VEL_Y_POS
	JMP VEL_Y_NEG
	
VEL_Y_POS:
	CMP [INC_COL_BALL],0 ; Comparo si la velocidad en X en positiva o negativa
	JS VEL_X_NEG
	
	VEL_X_POS:	;La velocidad es +1/+1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL	;TopX = BallX
		
		MOV AL,[POS_ROW_BALL]
		PUSH AX
		INC AL
		MOV [BALL_TOP_Y],AL	;TopY = BallY + 1
		POP AX
		
		MOV AL,[POS_COL_BALL]
		PUSH AX
		INC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX + 1
		POP AX
		
		MOV AL, [POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
	VEL_X_NEG:	;La velocidad es -1/+1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL	;TopX = BallX
		
		MOV AL,[POS_ROW_BALL]
		PUSH AX
		INC AL
		MOV [BALL_TOP_Y],AL	;TopY = BallY + 1
		POP AX
		
		MOV AL,[POS_COL_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX - 1
		POP AX
		
		MOV AL,[POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
VEL_Y_NEG:
	CMP [INC_COL_BALL],0
	JS VEL_X_NEG_Y_NEG
	
	VEL_X_POS_Y_NEG:	;La velocidad es +1/-1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL	;TopX = BallX
		
		MOV AL,[POS_ROW_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_TOP_Y],AL ;TopY = BallY - 1
		POP AX
		
		MOV AL,[POS_COL_BALL]
		PUSH AX
		INC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX + 1
		POP AX
		
		MOV AL,[POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
	VEL_X_NEG_Y_NEG:	;La velocidad es -1/-1
		MOV AL,[POS_COL_BALL]
		MOV [BALL_TOP_X],AL ;TopX = BallX
		
		MOV AL, [POS_ROW_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_TOP_Y],AL ;TopY = BallY - 1
		POP AX
		
		MOV AL, [POS_COL_BALL]
		PUSH AX
		DEC AL
		MOV [BALL_LADO_X],AL ;LadoX = BallX - 1
		POP AX
		
		MOV AL,[POS_ROW_BALL]
		MOV [BALL_LADO_Y],AL ;LadoY = BallY
		JMP FUNCTION_END
	
FUNCTION_END:
	POP AX
	RET
	
CALCULATE_TOP_LADO ENDP
; ****************************************
; Generate random number between two numbers
; Entry:
;   BL: the range of the random number will be [[MIN_RANDOM], BL)
;       the maximum value of BL is 0FFh
;   MIN_RANDOM:  the minim of the random
; Returns:
;   AH: random number
; Modifies:
;   -
; Uses: 
;   -
; Calls:
;   int 1ah, service 00
; ****************************************
            PUBLIC  RANDOM_NUM
RANDOM_NUM 	PROC    NEAR

   push bx
   push cx
   push dx

   SUB BL,[MIN_RANDOM]
   INC BL
   
   mov bh, al   ; backup al
   mov ah, 00
   int 1ah      ; CX:DX : timer ticks
   xor ah, ah 
   mov al, dl
   div bl       ; ah: remainder of the division
   mov al, bh   ; restore al
   
   ADD AH,[MIN_RANDOM]
   
   pop dx
   pop cx
   pop bx
   
	RET

RANDOM_NUM	ENDP
; ****************************************
; Spawns the power up
; Entry:
;  -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   POWER_UP_TYPE
;	P_UP_MIN_X
;	P_UP_MAX_X
;	P_UP_MIN_Y
;	P_UP_MAX_Y
;	ASCII_POWER_UP
;	ATTR_POWER_UP_DEC_VEL
;	ATTR_POWER_UP_INC_VEL
; Calls:
;   RANDOM_NUM
;	MOVE_CURSOR
;	PRINT_CHAR_ATTR
; ****************************************
	PUBLIC  GENERATE_POWER_UP
GENERATE_POWER_UP 	PROC    NEAR
	
	PUSH BX
	PUSH AX
	PUSH DX
	
	CMP [DIV_SPEED],1	; Si la velocidad es maxima spawnearemos de tipo decremento
	JZ SECOND_TYPE
	
	MOV [MIN_RANDOM],0
	MOV BL,2
	CALL RANDOM_NUM
	CMP AH,0
	JNZ SECOND_TYPE
	
FIRST_TYPE:	
	MOV [POWER_UP_TYPE],0	;Power up tipo 0
	JMP POSITIONING
	
SECOND_TYPE:
	MOV [POWER_UP_TYPE],1	;Power up tipo 1
	
POSITIONING:
	
	MOV [MIN_RANDOM], P_UP_MIN_X
	MOV BL, P_UP_MAX_X
	
	CALL RANDOM_NUM
	MOV AL, AH 				;POSITION ON X(COL)
	
	MOV [MIN_RANDOM], P_UP_MIN_Y
	MOV BL, P_UP_MAX_Y
	CALL RANDOM_NUM 		;POSITION ON Y(ROW)
	;(DH, DL): coordinates -> (row, col)
	MOV DL, AL
    MOV DH, AH
	
	CALL MOVE_CURSOR
	
	CMP [POWER_UP_TYPE], 0	;Comprobamos el tipo de power up spawneado
	JNZ	POWER_UP_TYPE_DEC 	;Si es tipo 1 = decremento de velocidad
	JMP POWER_UP_TYPE_INC	;Si el tipo 0 = incremento de velocidad
	
POWER_UP_TYPE_DEC:
	MOV AL,ASCII_POWER_UP
	MOV BL,ATTR_POWER_UP_DEC_VEL
	CALL PRINT_CHAR_ATTR	;PRINT POWER UP
	JMP END_GENERATE_POWER_UP
POWER_UP_TYPE_INC:
	MOV AL,ASCII_POWER_UP
	MOV BL,ATTR_POWER_UP_INC_VEL
	CALL PRINT_CHAR_ATTR	;PRINT POWER UP
END_GENERATE_POWER_UP:	
	MOV [POWER_UP_ON_SCREEN],TRUE
	
	POP DX
	POP AX
	POP BX

	RET

GENERATE_POWER_UP	ENDP
; ****************************************
; Check if it's time to spawn a power up
; Entry:
;  -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   NUM_BLOCKS
; Calls:
;   GENERATE_POWER_UP
; ****************************************
	PUBLIC  CHECK_TO_SPAWN_POWER_UP
CHECK_TO_SPAWN_POWER_UP 	PROC    NEAR
	
	CMP [NUM_BLOCKS], 4
	JL END_CHECK_POWER_UP ; 
	
	CMP [POWER_UP_ON_SCREEN],TRUE
	JZ END_CHECK_POWER_UP
	
	CALL GENERATE_POWER_UP
	
END_CHECK_POWER_UP:
	RET

CHECK_TO_SPAWN_POWER_UP	ENDP
; ****************************************
; Check if ball collides with a power up and take action
; Entry:
;  -
; Returns:
;   -
; Modifies:
;   DIV_SPEED
;	POWER_UP_ON_SCREEN
; Uses: 
;   INC_ROW_BALL
;	INC_COL_BALL
; Calls:
;   MOVE_CURSOR
;   READ_SCREEN_CHAR
; ****************************************
PUBLIC  COLISION_POWER_UP
COLISION_POWER_UP 	PROC    NEAR
	PUSH DX
	PUSH AX
	
	ADD DL, [INC_COL_BALL]
	ADD DH, [INC_ROW_BALL]
	
	CALL MOVE_CURSOR
	
	CALL READ_SCREEN_CHAR
	CMP AL, ASCII_POWER_UP ;hdp que nos hizo perder un dia
	JNZ END_COLISIONING
	
	MOV [POWER_UP_ON_SCREEN],FALSE
	
	CMP [POWER_UP_TYPE], 0
	JNZ TYPE_DEC_CHECK
	
TYPE_INC_CHECK:
	ADD [DIV_SPEED], 1
	JMP END_COLISIONING
	
TYPE_DEC_CHECK:
	ADD [DIV_SPEED], -1

END_COLISIONING:
	POP AX
	POP DX

	RET

COLISION_POWER_UP	ENDP
; ****************************************
; Game timer interrupt service routine
; Called 18.2 times per second by the operating system
; Calls previous ISR
; Manages the movement of the PJ: 
;   position, direction, speed, length, display, collisions
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   START_GAME memory variable
;   END_GAME memory variable
;   INT_COUNT memory variable
;   DIV_SPEED memory variable
;   INC_COL_PJ memory variable
;   INC_ROW_PJ memory variable
;   ATTR_PJ constant
;   NUM_BLOCKS memory variable
;   NUM_BLOCKS_INC_SPEED
; Calls:
;   MOVE_CURSOR
;   READ_SCREEN_CHAR
;   PRINT_PJ
; ****************************************

PUBLIC NEW_TIMER_INTERRUPT
NEW_TIMER_INTERRUPT PROC NEAR
;
    ; Call previous interrupt
    PUSHF
    CALL DWORD PTR [OLD_INTERRUPT_BASE]

    PUSH AX
    ; Do nothing if game is stopped
    CMP [START_GAME], TRUE
    JNZ END_ISR

    ; Increment INC_COUNT and check if worm position must be updated (INT_COUNT == DIV_COUNT)
    INC [INT_COUNT]
    MOV AL, [INT_COUNT]
    CMP [DIV_SPEED], AL
    JNZ END_ISR
    MOV [INT_COUNT], 0
	
	
	CALL MOVE_BALL
	CALL CHECK_TO_SPAWN_POWER_UP
	
    ; Check if it is time to increase the speed of the ball
    CMP [DIV_SPEED], 1
    JZ END_ISR
	MOV AX, [NUM_BLOCKS]
	CMP [NUM_BLOCKS_INC_SPEED],AL
    JGE END_ISR
	MOV [NUM_BLOCKS],0
    DEC [DIV_SPEED]
	
    JMP END_ISR
	  
END_ISR:
      POP AX
      IRET

NEW_TIMER_INTERRUPT ENDP
                 
; ****************************************
; Replaces current timer ISR with the game timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
;   NEW_TIMER_INTERRUPT memory variable
; Calls:
;   int 21h, service AH=35 (system interrupt 08)
; ****************************************
PUBLIC REGISTER_TIMER_INTERRUPT
REGISTER_TIMER_INTERRUPT PROC NEAR

        PUSH AX
        PUSH BX
        PUSH DS
        PUSH ES 

        CLI                                 ;Disable Ints
        
        ;Get current 01CH ISR segment:offset
        MOV  AX, 3508h                      ;Select MS-DOS service 35h, interrupt 08h
        INT  21h                            ;Get the existing ISR entry for 08h
        MOV  WORD PTR OLD_INTERRUPT_BASE+02h, ES  ;Store Segment 
        MOV  WORD PTR OLD_INTERRUPT_BASE, BX  ;Store Offset

        ;Set new 01Ch ISR segment:offset
        MOV  AX, 2508h                      ;MS-DOS serivce 25h, IVT entry 01Ch
        MOV  DX, offset NEW_TIMER_INTERRUPT ;Set the offset where the new IVT entry should point to
        INT  21h                            ;Define the new vector

        STI                                 ;Re-enable interrupts

        POP  ES                             ;Restore interrupts
        POP  DS
        POP  BX
        POP  AX
        RET      

REGISTER_TIMER_INTERRUPT ENDP

; ****************************************
; Restore timer ISR
; Entry: 
;   -
; Returns:
;   -
; Modifies:
;   -
; Uses: 
;   OLD_INTERRUPT_BASE memory variable
; Calls:
;   int 21h, service AH=25 (system interrupt 08)
; ****************************************
PUBLIC RESTORE_TIMER_INTERRUPT
RESTORE_TIMER_INTERRUPT PROC NEAR

      PUSH AX                             
      PUSH DS
      PUSH DX 

      CLI                                 ;Disable Ints
        
      ;Restore 08h ISR
      MOV  AX, 2508h                      ;MS-DOS service 25h, ISR 08h
      MOV  DX, WORD PTR OLD_INTERRUPT_BASE
      MOV  DS, WORD PTR OLD_INTERRUPT_BASE+02h
      INT  21h                            ;Define the new vector

      STI                                 ;Re-enable interrupts

      POP  DX                             
      POP  DS
      POP  AX
      RET    
      
RESTORE_TIMER_INTERRUPT ENDP

CODE_SEG 	ENDS

DATA_SEG	SEGMENT	PUBLIC
			
    OLD_INTERRUPT_BASE    DW  0, 0  ; Stores the current (system) timer ISR address
	
	; Position of the PJ initialized to the intial position
    POS_ROW_PJ DB INITIAL_POS_ROW_PJ    
    POS_COL_PJ DB INITIAL_POS_COL_PJ
	
	; Position of the ball initialized to the initial position
    POS_ROW_BALL DB INITIAL_POS_ROW_BALL    
    POS_COL_BALL DB INITIAL_POS_COL_BALL
	
    ; (INC_COL_PJ. INC_COL_PJ) may be (-1, 0, 1), and determine the direction of movement of the snake
    INC_ROW_PJ DB 0    
    INC_COL_PJ DB 0

	; (INC_ROW_BALL. INC_COL_BALL) may be (-1, 0, 1), and determine the direction of movement of the ball
    INC_ROW_BALL DB -1    
    INC_COL_BALL DB -1
	
    NUM_BLOCKS DW 0             ;numeros de bloques destruidos antes del incremento de velocidad
    NUM_BLOCKS_INC_SPEED DB 4   ;THE SPEED IS INCREASED EVERY 'NUM_BLOCKS_INC_SPEED'
	
    ; control de juego
    DIV_SPEED DB 10            ; THE SNAKE SPEED IS THE (INTERRUPT FREQUENCY) / DIV_SPEED
    INT_COUNT DB 0              ; 'INT_COUNT' IS INCREASED EVERY INTERRUPT CALL, AND RESET WHEN IT ACHIEVES 'DIV_SPEED'

    START_GAME DB 0             ; 'MAIN' sets START_GAME to '1' when a key is pressed
    END_GAME DB 0               ; 'NEW_TIMER_INTERRUPT' sets END_GAME to '1' when a condition to end the game happens
	
	;String de impresion
    SCORE_STR           DB "Your score is $"
    PLAY_AGAIN_STR      DB ". Do you want to play again? (Y/N)$"
	CREDITS_STRING		DB "Abraham Armas Cordero y Marc Baques Sabat.$"
	CREDITS_STRING_ENTI DB "Fonaments de Computadors ENTI-UB 2018.$"
	BALL_CHECK_COLISION DB 0			;	Wheter the given position colision or not 	
    BALL_COLISION_BLOCK DB 0	;	Wheter the given position colision is a block or not	
	; variables de control de la pelota
	
	BALL_TOP DB 0				;	Wheter the ball top position colision or not 
	BALL_TOP_X DB 0				;	Ball top position, coordinate x
	BALL_TOP_Y DB 0				;	Ball top position, coordinate y
	BALL_LADO DB 0				;	Wheter the ball side position colision or not 
	BALL_LADO_X DB 0			;	Ball lado position, coordinate x
	BALL_LADO_Y DB 0			;	Ball lado position, coordinate y	
	BALL_NEXT DB 0				;	Wheter the ball next movement position colision or not 	
	BALL_NEXT_X DB 0			;	Ball NEXT position, coordinate x
	BALL_NEXT_Y DB 0			;	Ball NEXT position, coordinate y	
	; puntuacion
	SCORE_BLOCKS DW 0			; Score of the player
	NUM_OF_BLOCK DB 105         ; BLOCKS_ROWS*21 ; sirve para saber cuantos bloques 
								; hay como maximo esto es hardcoded y no se puede variar
	POWER_UP_ON_SCREEN DB 0     ;	Wheter if there is a power up on the screen to avoid spawning more than 1
	POWER_UP_TYPE DB 0     		;	What type of power up is
	POWER_UP_INC_VEL DB 0		;	Wheter if is this type of power up
	POWER_UP_DEC_VEL DB 1		;	Wheter if is this type of power up	
	
	MIN_RANDOM DB 0				;	Stores the minimum value of the random
	
DATA_SEG	ENDS

		END MAIN