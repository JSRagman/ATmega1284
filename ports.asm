;
; Project: ATmega1284Prototype1
;
; File:    ports.asm
; Created: 20Jul2019
; Updated: 31Jul2019
; Author:  JSRagman
;
; MCU:     ATmega1284/1284P
;
; Description:
;     Port Name/Function Assignments


; Depends On:
;     1.  m1284(p)def.inc


; Port Name Assignments:                                              31Jul2019
; -----------------------------------------------------------------------------
; Port A: Pushbutton switch inputs with internal pullups
;
.equ PORTSW = PORTA
.equ PSW0 = PA0
.equ PSW1 = PA1
.equ PSW2 = PA2
.equ PSW3 = PA3
.equ PSW4 = PA4
.equ PSW5 = PA5
.equ PSW6 = PA6
.equ PSW7 = PA7

.equ PINSW  = PINA
.equ PINSW0 = PINA0         ; Button 0
.equ PINSW1 = PINA1         ; Button 1
.equ PINSW2 = PINA2         ; Button 2
.equ PINSW3 = PINA3         ; Button 3
.equ PINSW4 = PINA4         ; Button 4
.equ PINSW5 = PINA5         ; Button 5
.equ PINSW6 = PINA6         ; Button 6
.equ PINSW7 = PINA7         ; Button 7


; Port B
;
; PB0, PB1 = T0, T1 external clock inputs
; PB2,3,4  = Rotary encoder inputs/output
; PB5,6,7  = MOSI, MISO, SCK with wired pullups
.equ T0IN  = PB0                  ; 1 kHz external clock input for T0
.equ T1IN  = PB1                  ; external clock input for T1
.equ QSTEP = PB2                  ; Rotary encoder STEP input (INT2)
.equ QDIR  = PB3                  ; Rotary encoder DIRection input
.equ QRST  = PB4                  ; !RESET output for rotary encoder MCU, wired pullup
; PB5,6,7  = MOSI, MISO, SCK


; Port C
;
; PC0,PC1   = SCL, SDA inputs, wired pullups
;     Controlled by the TWI module
; PC2 - PC6 = Illuminated button LED outputs
; PC7       = !DRESET
;     PC7 is normally configured as an input, with internal pullups disabled (PC7 = 0).
;     Momentarily setting DDC7 pulls PC7 low to reset the display.
.equ PORTLED = PORTC             ; Illuminated pushbutton LED indicator outputs
; PC0 = SCL
; PC1 = SDA
.equ PLED2 = PC2
.equ PLED3 = PC3
.equ PLED4 = PC4
.equ PLED5 = PC5
.equ PLED6 = PC6
.equ PCDRESET = PC7                  ; Display !RESET output(input)

.equ PLEDYEL1 = PC2
.equ PLEDYEL2 = PC3
.equ PLEDGRN  = PC4
.equ PLEDRED  = PC5


.equ LEDMASK = (1<<PLED2)|(1<<PLED3)|(1<<PLED4)|(1<<PLED5)|(1<<PLED6)

; Port D
.equ T3IN   = PD0                  ; External clock input for T3
.equ RTCMFP = PD3                  ; Input from Real-Time clock MFP
.equ BSWCLR = PD7                  ; Pushbutton !CLEAR output


