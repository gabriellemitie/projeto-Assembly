RS      equ     P1.3    ; Reg Select ligado em P1.3
EN      equ     P1.2    ; Enable ligado em P1.2


org 0000h
LJMP Main


exibeTemporada: ;|pede para escolher a temporada
	MOV A, #40h
	ACALL posicionaCursor
	MOV DPTR, #temporada
	ACALL escreveStringROM

	MOV A, #4Dh ;|na linha de baixo do lcd
	ACALL posicionaCursor
	ACALL mostraTemporada
	
org 0040h
Main:
	ACALL lcdInit
	ACALL Netflix

	SJMP $

mostraNetflix:
	DB "Netflix Assembly"
	DB 0

Netflix: ;|tela inicial 'Netflix Assembly'
	MOV A, #00h
	MOV DPTR, #mostraNetflix
	ACALL escreveStringROM
	ACALL mostraSeries

org 041Ah ;|endereço das series
Friends:
	DB "Friends"
	DB 0

BreakingBad:
	DB "Breaking Bad"
	DB 0

Arcane:
	DB "Arcane"
	DB 0

Supernatural:
	DB "Supernatural"
	DB 0
	
StrangerThings:
	DB "Stranger Things"
	DB 0

FDS: ;|faz a comparacao 
	CJNE A, #'A', BB ;|o A foi recebido pelo tx, se nao for, chama o proximo 
	MOV DPTR, #Friends
	ACALL escreveStringROM
	ACALL exibeTemporada

BB:
	CJNE A, #'B', ARC
	MOV DPTR, #BreakingBad
	ACALL escreveStringROM
	ACALL exibeTemporada

ARC:
	CJNE A, #'C', SN
	MOV DPTR, #Arcane
	ACALL escreveStringROM
	ACALL exibeTemporada

SN:
	CJNE A, #'D', ST
	MOV DPTR, #Supernatural
	ACALL escreveStringROM
	ACALL exibeTemporada

ST:
	CJNE A, #'E', FDS
	MOV DPTR, #StrangerThings
	ACALL escreveStringROM
	ACALL exibeTemporada

temporada:
	DB "Escolha temp"
	DB 0

reproduzindo:
	DB "Reproduzindo.."
	DB 0

exibeSelecao:  ;|começo da 'cascata'
	ACALL clearDisplay

	MOV A, #00h
	ACALL posicionaCursor

	ACALL delay

	MOV A, 68h ;|endereço da escolha
	ACALL FDS ;|chama a primeira funcao Friends para começar as comparações

fim:
	SJMP $

org 0023h ;|endereço exclusivo para trabalhar com Tx e Rx
	CALL delayRx
	CJNE R7, #1, back
	JB opcaoValida, back        
	MOV A, SBUF                   ; |  Reads the bytes received
	CJNE A, #0Dh, storeUserOption ; |  Stores the value if diffent from 0D (padrao para tratar rx)
	CLR RI                        ; |  Resets RI to receive new bytes

	RETI
	

	storeUserOption: ;|guarda a escolha do usuario 
		MOV userOption, A  	; |  Writes the value in the userOption var
		MOV R0, #75h 		; |  Initial array address
		MOV R1, #5			; |  Array size das series
		ACALL checkSerie   ; |  checks if the user's choice is valid
		CLR RI              ; |  Resets RI to receive new bytes
		RETI
	back:
		RETI

org 0060h
posRead EQU 67h    			; guarda posição da string
userOption EQU 68h 			; guarda a serie   
keyAscii EQU 69h         
opcaoValida EQU F0       ;|opcao valida
seriesPrintadas EQU R7	 ;|verifica se as series foram printadas ou nao 

resetar:
	CLR A
	MOV posRead, #0h
	CLR RI

	MOV P2, #255
	MOV 75h, #'A'
	MOV 76h, #'B'	
	MOV 77h, #'C'	
	MOV 78h, #'D'
	MOV 79h, #'E'

	MOV 40H, #'#'
	MOV 41H, #'0'
	MOV 42H, #'*'
	MOV 43H, #'9'
	MOV 44H, #'8'
	MOV 45H, #'7'
	MOV 46H, #'6'
	MOV 47H, #'5'
	MOV 48H, #'4'
	MOV 49H, #'3'
	MOV 4AH, #'2'
	MOV 4BH, #'1'
	
	CLR opcaoValida

	RET
	
mostraSeries: ;|quer receber algo do usuario pelo tx, por isso precisa de interrupções
	CALL resetar

	MOV SCON, #50h  ;  |  Enable Serial Mode 1 and the port receiver
	MOV PCON, #80h  ;  |  SMOD bit = 1
	MOV TMOD, #20h  ;  |  CT1 mode 2
	MOV TH1, #243   ;  |  Initial value for count
	MOV TL1, #243   
	SETB TR1
	MOV IE, #90h	
	MOV seriesPrintadas, #0 ;|como resetou, entao nao foram printadas

escreveSeries: ;|no tx
	MOV DPTR, #listaSeries ; |  Stores movies in the DPTR register
	MOV A, posRead        ; |  like the variable i in a For to print the whole string
	MOVC A, @A+DPTR       ; |  Reads the current string letter
	JZ break              ; |  Breaks if the movies are printed
	MOV SBUF, A           ; |  Transmits the content in A
	JNB TI, $             ; |  Waits the end of the transmission
	CLR TI                ; |  Cleans the end of transmission indicator
	INC posRead           ; |  Increments the string position
	SJMP escreveSeries    ; |  Repeats to print next line

break:
	CLR A
	MOV seriesPrintadas, #1	;|series printadas, seta pra 1
	RET 

checkSerie: 
	CJNE R1, #0, passar			
	CLR opcaoValida								
	CLR RI
				
	RET		

passar:		
	MOV A, @R0																		
	INC R0																			
	DEC R1																			
	CJNE A, userOption, checkSerie						
	SETB opcaoValida
	ACALL delay
	ACALL delay
	ACALL delay
	ACALL exibeSelecao		
																		
	RET


mostraTemporada: ;| escolhe o numero da temporada pelo keypad, entao mostra no lcd o que foi apertado
	ACALL leituraTeclado ;|vai chamar a leitura do teclado
	JNB F0, mostraTemporada 

	MOV A, #4Dh
	ACALL posicionaCursor
	MOV A, #40h
	ADD A, R0
	MOV R0, A
	MOV A, @R0 
	ACALL sendCharacter
	CLR F0
	
	JMP mostraTemporada
	
reproduzir:
	ACALL clearDisplay
	MOV DPTR, #reproduzindo
	ACALL escreveStringROM
	
listaSeries:
	DB "A -> Friends" 
	DB '\n'
	DB "B -> Breaking Bad"
	DB '\n'
	DB "C -> Arcane"
	DB '\n'
	DB "D -> Supernatural"
	DB '\n'
	DB "E -> Stranger Things"
	DB 0
;| funções para leitura de teclado
seletor:
	SETB EA  ; habilita as interrupções
	SETB EX0 ; habilita a interrupção 0
	SETB EX1 ; habilita a interrupção 2
	SETB IT0 ; trabalhando com borda de descida
	SETB IT1 ; trabalhando com borda de descida

	SJMP $ ; laço de repetição

memoria:
	MOV 40H, #'#'
	MOV 41H, #'0'
	MOV 42H, #'*'
	MOV 43H, #'9'
	MOV 44H, #'8'
	MOV 45H, #'7'
	MOV 46H, #'6'
	MOV 47H, #'5'
	MOV 48H, #'4'
	MOV 49H, #'3'
	MOV 4AH, #'2'
	MOV 4BH, #'1'

inicio:
	MOV A, #00h

	MOV P0, #11111110b
	CALL columVerify

	MOV P0, #11111101b
	CALL columVerify

	MOV P0, #11111011b
	CALL columVerify

	MOV P0, #11110111b
	CALL columVerify

	JMP inicio

resetLoop:
	MOV A, #00h
	ACALL posicionaCursor

	MOV A, B

continue:
	JNB P0.4, $
	JNB P0.5, $
	JNB P0.6, $

	CLR F0
	ACALL clearDisplay

	JMP inicio

columVerify:
	JNB P0.4, longReset
	INC A

	JNB P0.5, longReset
	INC A

	JNB P0.6, longReset
	INC A

	RET

longReset:
	LJMP resetLoop

escreveStringROM:
 	MOV R1, #00h 	; inicia a escrita da String no Display LCD

loop:
 	MOV A, R1
	MOVC A, @A+DPTR 	 	; lê da memória de programa
	JZ finish					; if A is 0, then end of data has been reached - jump out of loop
	ACALL sendCharacter	; send data in A to LCD module
	INC R1						; point to next piece of data
 	MOV A, R1
	JMP loop		; repeat

leituraTeclado:
	MOV R0, #0			; clear R0 - the first key is key0

	; scan row0
	MOV P0, #0FFh	
	CLR P0.0			; clear row0
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)
	; scan row1
	SETB P0.0			; set row0
	CLR P0.1			; clear row1
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)
	; scan row2
	SETB P0.1			; set row1
	CLR P0.2			; clear row2
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)
	; scan row3
	SETB P0.2			; set row2
	CLR P0.3			; clear row3
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)

leituraDirecao:
	MOV A, #75h
	ADD A, R0
	MOV R0, A
	MOV A, @R0

	RET				; return from subroutine

finish:
	RET

; column-scan subroutine
colScan:
	JNB P0.4, gotKey	; if col0 is cleared - key found
	INC R0					; otherwise move to next key
	JNB P0.5, gotKey	; if col1 is cleared - key found
	INC R0					; otherwise move to next key
	JNB P0.6, gotKey	; if col2 is cleared - key found
	INC R0					; otherwise move to next key

	RET						; return from subroutine - key not found

gotKey:
	SETB F0				; key found - set F0

	RET					; and return from subroutine

; initialise the display
; see instruction set for details
lcdInit:
	CLR RS		; clear RS - indicates that instructions are being sent to the module

; function set	
	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear	
					; function set sent for first time - tells module to go into 4-bit mode
; Why is function set high nibble sent twice? See 4-bit operation on pages 39 and 42 of HD44780.pdf.

	SETB EN		; |
	CLR EN		; | negative edge on E
					; same function set high nibble sent a second time

	SETB P1.7		; low nibble set (only P1.7 needed to be changed)

	SETB EN		; |
	CLR EN		; | negative edge on E
				; function set low nibble sent
	CALL delay		; wait for BF to clear

; entry mode set
; set to increment with no shift
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.6		; |
	SETB P1.5		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear

; display on/off control
; the display is turned on, the cursor is turned on and blinking is turned on
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.7		; |
	SETB P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear

	RET

sendCharacter:
	SETB RS  			; setb RS - indicates that data is being sent to module
	MOV C, ACC.7		; |
	MOV P1.7, C			; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay			; wait for BF to clear
	CALL delay			; wait for BF to clear

	RET

posicionaCursor:
	CLR RS	          ; clear RS - indicates that instruction is being sent to module
	SETB P1.7		 	   	; |
	MOV C, ACC.6			; |
	MOV P1.6, C				; |
	MOV C, ACC.5			; |
	MOV P1.5, C				; |
	MOV C, ACC.4			; |
	MOV P1.4, C				; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3			; |
	MOV P1.7, C				; |
	MOV C, ACC.2			; |
	MOV P1.6, C				; |
	MOV C, ACC.1			; |
	MOV P1.5, C				; |
	MOV C, ACC.0	 		; |
	MOV P1.4, C				; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay			; wait for BF to clear

	RET

; Retorna o cursor para primeira posição sem limpar o display
retornaCursor:
	CLR RS	   ; clear RS - indicates that instruction is being sent to module
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear

	RET

; Limpa o display
clearDisplay:
	CLR RS	   ; clear RS - indicates that instruction is being sent to module
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delayRx		; wait for BF to clear
	CALL delayRx
	CALL delayRx

	RET

delayRx: ;|delay maior pro tx
	MOV R3, #0FFh
	DJNZ R3, $
	RET

delay:
	MOV R5, #50
	DJNZ R5, $

	RET