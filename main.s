; Main.s
; Mark Keranen for ECE505 Lab 2

; Drives a buzzer using Port D GPIO pin 1. Continuously generates a stepped, 3 frequency tone.

; Hardware: 
;  - TM4C123GH6PM Tiva C Series Launchpad Evaluation Board
;  - Sparkfun RedBot Buzzer
;  - 2 x Male to Male jumper wires
;  - 2 x Female to Female jumper wires

; Schematic
; TM4C123G GND <-> RedBot JP1 Pin 1
; TM4C123G PD1 <-> RedBot JP1 Pin 3


;________________________________________________________________________________
; Portions adapted from GPIO.S by Daniel Valvano with the following copyright
;
;Copyright 2014 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or distribute this file
;   as long as the above copyright notice remains
;THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
;OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
;MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
;VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
;OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;For more information about my classes, my research, and my books, see
;http://users.ece.utexas.edu/~valvano/
;________________________________________________________________________________

PD1                EQU 0x4000703C   ; access PD1
GPIO_PORTD_DATA_R  EQU 0x400073FC
GPIO_PORTD_DIR_R   EQU 0x40007400
GPIO_PORTD_AFSEL_R EQU 0x40007420
GPIO_PORTD_DR8R_R  EQU 0x40007508
GPIO_PORTD_DEN_R   EQU 0x4000751C
GPIO_PORTD_AMSEL_R EQU 0x40007528
GPIO_PORTD_PCTL_R  EQU 0x4000752C
SYSCTL_RCGCGPIO_R  EQU 0x400FE608
SYSCTL_RCGC2_GPIOD EQU 0x00000008   ; port D Clock Gating Control
	
DELAY200HZ         EQU 150	; Base (Determined via instruction count x clock cycles, tuned via empirical testing)
DELAY500HZ         EQU 375	; 2.5 * Base (Approximately proportional to # of 50us delays called) 50/20 = 2.5
DELAY1000HZ        EQU 750	; 5 * Base  (Approximately proportional to # of 50us delays called) 50/10 = 5
	

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start
			
;************ Start of Main Program ****************
    
Start
    BL  GPIO_Init	; Initialize Port D for output
    LDR R0, =PD1    ; Access port address and move into R0 

; Start of buzzer handling
buzzer_loop

	LDR R2, =DELAY200HZ		; Set tone duration
	MOV R3, #50	; Set tone frequency; For 200Hz -> 1/200 = 5000us / 2 = 2500us toggle / 50us delay = call 50us delay 50 times
	BL	buzzer	; Create tone for specified duration at specified pitch
	
	LDR R2, =DELAY500HZ		; Set tone duration
	MOV R3, #20	; Set tone frequency; For 500Hz -> 1/500 = 2000us / 2 = 1000us toggle / 50us delay = call 50us delay 20 times
	BL	buzzer	; Create tone for specified duration at specified pitch
	
	LDR R2, =DELAY1000HZ	; Set tone duration
	MOV R3, #10	; Set tone frequency; For 1000Hz -> 1/1000 = 1000us / 2 = 500us toggle / 50us delay = call 50us delay 10 times
	BL	buzzer	; Create tone for specified duration at specified pitch

	B	buzzer_loop	; Continuously repeat the tones


;_________________START FUNCTION DEFINITIONS_______________________________________

;------------Port D GPIO_Init------------
; Initializes Pin 1 on Port D as an output.
; Input: none
; Output: none
; Modifies: SYSCTL_RCGCGPIO_R, GPIO_PORTD_AMSEL_R, GPIO_PORTD_PCTL_R, GPIO_PORTD_DIR_R, GPIO_PORTD_AFSEL_R, GPIO_PORTD_DR8R_R, GPIO_PORTD_DEN_R 
GPIO_Init
    ; 1) activate clock for Port D
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = &SYSCTL_RCGCGPIO_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #SYSCTL_RCGC2_GPIOD ; R0 = R0|SYSCTL_RCGC2_GPIOD
    STR R0, [R1]                    ; [R1] = R0
    NOP
    NOP                             ; allow time to finish activating
    ; 2) no need to unlock PD1
    ; 3) disable analog functionality
    LDR R1, =GPIO_PORTD_AMSEL_R     ; R1 = &GPIO_PORTD_AMSEL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #0x02               ; R0 = R0&~0x0F (disable analog functionality on PD3-0)
    STR R0, [R1]                    ; [R1] = R0    
    ; 4) configure as GPIO
    LDR R1, =GPIO_PORTD_PCTL_R      ; R1 = &GPIO_PORTD_PCTL_R
    LDR R0, [R1]                    ; R0 = [R1]
    MOV R2, #0x000000F0             ; R2 = 0x0000000F
    BIC R0, R0, R2                  ; R0 = R0&~0x0000000F (clear port control field for PD0)
    STR R0, [R1]                    ; [R1] = R0

    ; 5) set direction register
    LDR R1, =GPIO_PORTD_DIR_R       ; R1 = &GPIO_PORTD_DIR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x02               ; R0 = R0|0x01 (make PD1 output)
    STR R0, [R1]                    ; [R1] = R0
    ; 6) regular port function
    LDR R1, =GPIO_PORTD_AFSEL_R     ; R1 = &GPIO_PORTD_AFSEL_R
    LDR R0, [R1]                    ; R0 = [R1]
    BIC R0, R0, #0x02               ; R0 = R0&~0x01 (disable alt funct on PD1)
    STR R0, [R1]                    ; [R1] = R0
    ; enable 8mA drive
    LDR R1, =GPIO_PORTD_DR8R_R      ; R1 = &GPIO_PORTD_DR8R_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x02              ; R0 = R0|0x01 (enable 8mA drive on PD1)
    STR R0, [R1]                    ; [R1] = R0
    ; 7) enable digital port
    LDR R1, =GPIO_PORTD_DEN_R       ; R1 = &GPIO_PORTD_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x02               ; R0 = R0|0x0F (enable digital I/O on PD1)
    STR R0, [R1]                    ; [R1] = R0
    BX  LR

;------------delay50us------------
; Delay function, which delays for 50us.
; Input: delay length (clock cycles)
; Output: none
; Modifies: R0

FIFTYUS			   EQU 262			; 262 clock cycles & 3 instructions = ~50us
delay50us
	LDR R0, =FIFTYUS
delay50us_loop
    SUBS R0, R0, #1                 ; R0 = R0 - 1 (count = count - 1)
    BNE delay50us_loop              ; if count (R0) != 0, skip to 'delay'
    BX  LR              

;------------delaymultipleof50us------------
; Delay function that calls the 'delay50us' function for specified number of times.
; Input: Number of times to call 'delay50us', accessed via R0
; Output: none
; Modifies: R3

delaymultipleof50us
	PUSH	{LR}

delay_loop
	PUSH	{R0}		; Save R0 since delay50us modifies R0
	BL		delay50us	; Delay by 50us
	POP		{R0}
	SUBS	R3, R3, #1	; Check if we've met our delay target
	BNE		delay_loop	; If delay duration is not met, keep delaying
	
	POP		{LR}
	
	BX LR


	
;-------buzzer_pin_toggle------
; Toggles the state of the pin driving the buzzer.
; Input: Pin address
; Output: Port D Pin 1 status
; Modifies: R0, R1, Port D Pin 1
buzzer_pin_toggle

	LDR		R0, =PD1			; Load Port D address into R0
	LDR		R1, [R0]			; Read Port D data into R1
	EOR		R1, R1, #0x02		; Toggle only PD1 with exclusive or
	STR		R1, [R0]			; Update PD status
	BX 		LR

;-----------buzzer--------------------
; Drives the buzzer at a specified tone and for a specified duration
; Input: Target frequency (R3) and Target Duration (R2)
; Output: PD1 status
; Modifies: R2, PD1
buzzer
	PUSH {LR}				; Push LR to stack because it is modified by additional function calls in the coming LOC
buzzer_fcn_loop

	BL  buzzer_pin_toggle	; Toggle PD1
	
	PUSH {R3}				; PUSH R3 to save target frequency for use in next delay function
	BL  delaymultipleof50us
	POP {R3}				; Reset R3 with target frequency
	
	BL  buzzer_pin_toggle	; Toggle PD1
	
	PUSH {R3}				; PUSH R3 to save target frequency for use in next delay function
	BL  delaymultipleof50us
	POP {R3}				; Reset R3 with target frequency
	
	SUBS R2, R2, #1			; Check if tone duration target has been met
	BNE buzzer_fcn_loop		; Keep toggling PD1 at current frequency if duration of tone has not been met
	
	POP {LR}				; Restore LR to branch back to main program
	BX	LR
	

    ALIGN                   ; make sure the end of this section is aligned
    END                     ; end of file
		
