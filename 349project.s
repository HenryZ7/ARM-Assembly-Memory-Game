; Sequence Memory
; This is a game that requires the player to memorize the order LED's light up
; There are 3 levels
		AREA MemoryGame, CODE, READONLY
		EXPORT __main

; Register addresses
GPIO_MODER    EQU 0x40020800
GPIO_IDR      EQU 0x40020810
GPIO_BSRR     EQU 0x40020818
RCC_AHB1ENR   EQU 0x40023830

; LED and Button values
LED1_ON       EQU 0x00000002  ; PC1
LED1_OFF      EQU 0x00020000
LED2_ON       EQU 0x00000004  ; PC2
LED2_OFF      EQU 0x00040000
LED3_ON       EQU 0x00000008  ; PC3
LED3_OFF      EQU 0x00080000
ALL_LEDS_ON   EQU 0x0000000E  ; PC1+PC2+PC3
ALL_LEDS_OFF  EQU 0x000E0000

BTN0          EQU 0x00000001  ; PC0
BTN4          EQU 0x00000010  ; PC4
BTN5          EQU 0x00000020  ; PC5
BTN_MASK      EQU 0x00000031  ; PC0+PC4+PC5

; 3 different Delays
SHORT_DELAY   EQU 0x0003FFFF
MEDIUM_DELAY  EQU 0x000FFFFF
LONG_DELAY    EQU 0x003FFFFF

__main
    ; Enable GPIOC clock
    LDR R0, =RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x00000004  ; GPIOCEN bit to turn on clock
    STR R1, [R0]

    ; Configure PC1-PC3 as outputs
    LDR R0, =GPIO_MODER
    LDR R1, [R0]
    BIC R1, R1, #0x000000FF  ; Clear PC0-PC3 mode bits
    ORR R1, R1, #0x00000054  ; Output mode for PC1-PC3
    STR R1, [R0]

    ; Configure pull-ups for PC0, PC4, PC5
    LDR R0, =GPIO_MODER+0x0C ; PUPDR offset
    LDR R1, [R0]
    
	; Clear PC0, PC4, PC5 PUPDR fields (mask = (3<<0)|(3<<8)|(3<<10) = 0x00000F03)
    LDR R2, =0x00000F03
    BIC R1, R1, R2
    ; Set pull-ups (01) on PC0, PC4, PC5 (mask = (1<<0)|(1<<8)|(1<<10) = 0x00000501)
    LDR R2, =0x00000501
    ORR R1, R1, R2

    STR R1, [R0]

    ; Initialize level counter
    MOV R4, #1              ; Current level (1 2 or 3)

game_loop
    ; Show pattern based on level
    CMP R4, #1
    BEQ level1_pattern
    CMP R4, #2
    BEQ level2_pattern
	CMP R4, #3
	BEQ level3_pattern
	B game_loop
   
level1_pattern
    ; Level 1 pattern (PC1 -> PC2 -> PC3)
    BL show_pattern_forward
    B wait_for_input

level2_pattern
    ; Level 2 pattern (PC3 -> PC2 -> PC1)
    BL show_pattern_backward
	B wait_for_input

level3_pattern
	; Level 3 pattern (PC1 -> PC3 -> PC2)
    BL show_pattern_level3
    B wait_for_input

wait_for_input
    ; Wait for button sequence based on level
    CMP R4, #1
    BEQ level1_input
    CMP R4, #2
    BEQ level2_input
	CMP R4, #3
	BEQ level3_input
  
level1_input
	; Level 1 input (PC0 -> PC4 -> PC5)
	BL wait_for_sequence_forward
	B check_result

level2_input
    ; Level 2 input (PC5 -> PC4 -> PC0)
    BL wait_for_sequence_backward
	B check_result
  
level3_input  
   ; Level 3 input (PC0 -> PC5 -> PC4)
    BL wait_for_sequence_level3
    B check_result

check_result  
    CMP R0, #1 ; r0 set to 1 whenever sequence is correct
    BNE wrong_sequence ; jumps to wrong_sequence

    ; Correct sequence - move onto success_flash and flash all 3 LED's
    MOV R5, #3

success_flash ; will turn on all 3 LED's on if pattern was remembered correctly
    LDR R0, =GPIO_BSRR
    LDR R1, =ALL_LEDS_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =ALL_LEDS_OFF
    STR R1, [R0]
    BL delay_short
    SUBS R5, R5, #1
    BNE success_flash
    
    ; Advance to next level
	ADD R4, R4, #1
	CMP R4, #3
	BLS level_ok
	MOV R4, #1
level_ok
    
    B game_loop ;after success flash, move onto next level, will just reset to level 1 after level 3

wrong_sequence
    ; Wrong sequence - flash all LEDs once quickly
    LDR R0, =GPIO_BSRR
    LDR R1, =ALL_LEDS_ON
    STR R1, [R0]
    BL delay_short
    LDR R1, =ALL_LEDS_OFF
    STR R1, [R0]
    BL delay_short
    
    B game_loop ;resets the level

; Level 1 pattern (PC1 -> PC2 -> PC3)
show_pattern_forward
    PUSH {LR}
    LDR R0, =GPIO_BSRR
    
    ; PC1 on/off
    LDR R1, =LED1_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED1_OFF
    STR R1, [R0]
    BL delay_short
    
    ; PC2 on/off
    LDR R1, =LED2_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED2_OFF
    STR R1, [R0]
    BL delay_short
    
    ; PC3 on/off
    LDR R1, =LED3_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED3_OFF
    STR R1, [R0]
    BL delay_short
    
    POP {PC}

; Level 2 pattern (PC3 -> PC2 -> PC1)
show_pattern_backward
    PUSH {LR}
    LDR R0, =GPIO_BSRR
    
    ; PC3 on/off
    LDR R1, =LED3_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED3_OFF
    STR R1, [R0]
    BL delay_short
    
    ; PC2 on/off
    LDR R1, =LED2_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED2_OFF
    STR R1, [R0]
    BL delay_short
    
    ; PC1 on/off
    LDR R1, =LED1_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED1_OFF
    STR R1, [R0]
    BL delay_short
    
    POP {PC}
	
; Level 3 pattern (PC1 -> PC3 -> PC2)
show_pattern_level3
    PUSH {LR}
    LDR R0, =GPIO_BSRR
    
    ; PC1 on/off
    LDR R1, =LED1_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED1_OFF
    STR R1, [R0]
    BL delay_short
    
    ; PC3 on/off
    LDR R1, =LED3_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED3_OFF
    STR R1, [R0]
    BL delay_short
    
    ; PC2 on/off
    LDR R1, =LED2_ON
    STR R1, [R0]
    BL delay_medium
    LDR R1, =LED2_OFF
    STR R1, [R0]
    BL delay_short
    
    POP {PC}

; Level 1 input (PC0 -> PC4 -> PC5)
wait_for_sequence_forward
    PUSH {R4-R5, LR}
    
    ; Wait for PC0
    BL wait_for_button
    CMP R0, #BTN0
    BNE seq_fail
    
    ; Wait for PC4
    BL wait_for_button
    CMP R0, #BTN4
    BNE seq_fail
    
    ; Wait for PC5
    BL wait_for_button
    CMP R0, #BTN5
    BNE seq_fail
    
    ; Sequence correct
    MOV R0, #1
    B seq_exit

; Level 2 input (PC5 -> PC4 -> PC0)
wait_for_sequence_backward
    PUSH {R4-R5, LR}
    
    ; Wait for PC5
    BL wait_for_button
    CMP R0, #BTN5
    BNE seq_fail
    
    ; Wait for PC4
    BL wait_for_button
    CMP R0, #BTN4
    BNE seq_fail
    
    ; Wait for PC0
    BL wait_for_button
    CMP R0, #BTN0
    BNE seq_fail
    
    ; Sequence correct
    MOV R0, #1
    B seq_exit
	

; Level 3 input (PC0 -> PC5 -> PC4)
wait_for_sequence_level3
    PUSH {R4-R5, LR}
    
    ; Wait for PC0
    BL wait_for_button
    CMP R0, #BTN0
    BNE seq_fail
    
    ; Wait for PC5
    BL wait_for_button
    CMP R0, #BTN5
    BNE seq_fail
    
    ; Wait for PC4
    BL wait_for_button
    CMP R0, #BTN4
    BNE seq_fail
    
    ; Sequence correct
    MOV R0, #1
    B seq_exit

seq_fail ; If you press the wrong button, R0 will be set to 0
    MOV R0, #0

seq_exit ; Resets values in registers R4 and R5
    POP {R4-R5, PC}

wait_for_button ; waits for a button to be pressed
    PUSH {R1-R3, LR}
    LDR R0, =GPIO_IDR
    
wait_press
    LDR R1, [R0] ; Read GPIO input register value
    AND R1, R1, #BTN_MASK ; Isolates button bits
    CMP R1, #BTN_MASK      ; All buttons released?
    BEQ wait_press ; If all buttons are released, loop back until one is pressed
    
    ; Debounce
    BL delay_short ; Filters out potential noise with button presses
    
    ; Verify button still pressed
	; After the short delay above, will check one more time press
    LDR R1, [R0]
    AND R1, R1, #BTN_MASK
    CMP R1, #BTN_MASK
    BEQ wait_press         ; False press
    
    ; Get pressed button (active-low to active-high)
	; Inversion because buttons are active low
    MVN R1, R1
    AND R1, R1, #BTN_MASK ; Once again only isolate bits for buttons
    
    ; Wait for release
wait_release
    LDR R2, [R0]
    AND R2, R2, #BTN_MASK
    CMP R2, #BTN_MASK
    BNE wait_release
    
    MOV R0, R1             ; Return button mask
    POP {R1-R3, PC}

delay_short
    PUSH {R4, LR}
    LDR R4, =SHORT_DELAY
delay_short_loop
    SUBS R4, R4, #1
    BNE delay_short_loop
    POP {R4, PC}

delay_medium
    PUSH {R4, LR}
    LDR R4, =MEDIUM_DELAY
delay_medium_loop
    SUBS R4, R4, #1
    BNE delay_medium_loop
    POP {R4, PC}

delay_long
    PUSH {R4, LR}
    LDR R4, =LONG_DELAY
delay_long_loop
    SUBS R4, R4, #1
    BNE delay_long_loop
    POP {R4, PC}

    END
		
		