;
; Project: ATmega1284Prototype1
;
; File:    constants.asm
; Created: 29Jun2019
; Updated: 14Jul2019
; Author:  JSRagman
; 


#ifndef _m1284P_constants
#define _m1284P_constants


; Named Registers:
; -----------------------------------------------------------------------------
.def  rZero   = r3                ; Always holds a big fat zero.
.def  rFF     = r4                ; Always holds 0xFF
.def  rTimer  = r5                ; Used with Timer/Counter 0



; Port Assignments:
; -----------------------------------------------------------------------------
.equ PORTSWINS = PORTA            ; Pushbutton switch inputs
.equ PSW2 = PA2
.equ PSW3 = PA3
.equ PSW4 = PA4
.equ PSW5 = PA5
.equ PSW6 = PA6
.equ PSW7 = PA7

.equ PINSWINS = PINA
.equ PINSW2 = PINA2
.equ PINSW3 = PINA3
.equ PINSW4 = PINA4
.equ PINSW5 = PINA5
.equ PINSW6 = PINA6
.equ PINSW7 = PINA7

.equ PORTLEDS = PORTC             ; LED indicator outputs
.equ PLEDGRN = PC2
.equ PLEDYEL = PC3
.equ PLEDRED = PC4
.equ PLED5   = PC5
.equ PLED6   = PC6
.equ PLED7   = PC7

.equ PINLEDS = PINC
.equ PINLED2 = PINC2
.equ PINLED3 = PINC3
.equ PINLED4 = PINC4
.equ PINLED5 = PINC5
.equ PINLED6 = PINC6
.equ PINLED7 = PINC7

.equ T0EN   = PD0                 ; Enable/Disable the external clock on T0
.equ DRESET = PD1                 ; Pull low to reset the display
.equ SCLR   = PD7                 ; Pull low to reset latched button inputs


.equ HSTACK_MAXSIZE = 128     ; Used to initialize the data stack.


; External Interrupt Sense Constants
; EICRA - External Interrupt Control Register A
; -------------------------------------------------------------------------------------
.equ INT0_FALLING  =  (1<<ISC01)|(0<<ISC00)
.equ INT1_FALLING  =  (1<<ISC11)|(0<<ISC10)
.equ INT2_FALLING  =  (1<<ISC21)|(0<<ISC20)


; Timer/Counter 0:
; -------------------------------------------------------------------------------------

; TCCR0A - Mode
.equ TC0_WGM_NORM  =  (0<<WGM01)|(0<<WGM00) ; Mode 0: Normal
.equ TC0_WGM_CTC   =  (1<<WGM01)|(0<<WGM00) ; Mode 2: CTC

; TCCR0B - Clock Source
.equ TC0CS_STOP    = (0<<CS02)|(0<<CS01)|(0<<CS00)  ; No clock source (stopped)
.equ TC0CS_T0_F    = (1<<CS02)|(1<<CS01)|(0<<CS00)  ; Ext. clock on T0, falling edge.

; TIMSK0 - Interrupt Mask
.equ TC0_OVERF     = (1<<TOIE0)                 ; Overflow
.equ TC0_CMPA      = (1<<OCIE0A)                ; Output Compare Match A
.equ TC0_CMPB      = (1<<OCIE0B)                ; Output Compare Match B


; TWI Constants
; -----------------------------------------------------------------------------

; CPU Clock           = 8 MHz
; TWSR Prescaler bits = 0
.EQU  TWBR_100KHz = 34
.equ  TWBR_400KHz =  2


; TWCR Constants
.EQU  TWCR_GO    = (1<<TWINT)|(1<<TWEN)               ; set TWEN, clear TWINT
.EQU  TWCR_START = (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)    ; generate START
.EQU  TWCR_STOP  = (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)    ; generate STOP


; TWSR Constants

; TWSR: Prescaler Bits Mask
.EQU  TWISTAT_PREMASK   = 0b_1111_1000    ; Masks out TWSR prescaler bits.

; TWSR: TWI Master Status Codes
.EQU  TWISTAT_START     = 0x08            ; START has been transmitted.
.EQU  TWISTAT_REPSTART  = 0x10            ; Repeated START has been transmitted.

; TWSR: Master Transmitter Status Codes
.EQU  TWISTAT_SLAW_ACK   = 0x18           ; SLA+W transmitted, ACK received.
.EQU  TWISTAT_SLAW_NACK  = 0x20           ; SLA+W transmitted, NACK received.
.EQU  TWISTAT_DW_ACK     = 0x28           ; Data transmitted, ACK received.
.EQU  TWISTAT_DW_NACK    = 0x30           ; Data transmitted, NACK received.

; TWSR: Master Receiver Status Codes
.EQU  TWISTAT_SLAR_ACK   = 0x40           ; SLA+R transmitted, ACK received.
.EQU  TWISTAT_SLAR_NACK  = 0x48           ; SLA+R transmitted, NACK received.
.EQU  TWISTAT_DR_ACK     = 0x50           ; Data byte received, ACK returned.
.EQU  TWISTAT_DR_NACK    = 0x58           ; Data byte received, NACK returned.


; NHD-0420CW Display Constants:
; -----------------------------------------------------------------------------

.equ MAXSENDBYTES = 22

; Control Bytes
.equ CTRLBYTE_CMD   = 0x00  ; D/C# = 0, Control Byte - the next byte is a command.
.equ CTRLBYTE_DATA  = 0x40  ; D/C# = 1, Control Byte - the next byte is data.
.equ CTRLBYTE_MASK  = 0b_1011_1111

; Commands
.equ DISPLAY_CLEAR  = 0x01
.equ DISPLAY_HOME   = 0x02
.equ DISPLAY_OFF    = 0x08
.equ DISPLAY_ON     = 0x0C

.equ SET_DDRAM = 0x80  ; 0b_1000_0000

; Cursor State Constants
.equ CURSOR_OFF   = 0
.equ CURSOR_ON    = 0b_0000_0010
.equ CURSOR_BLINK = 0b_0000_0011

; Display Position Constants
.equ DISPLAY_LINE_1   = 0x00       ; DDRAM Line 1, Column 0
.equ DISPLAY_LINE_INC = 0x20       ; DDRAM Increment to next line
.equ DISPLAY_LINE_2   = 0x20       ; DDRAM Line 1, Column 0
.equ DISPLAY_LINE_3   = 0x40       ; DDRAM Line 1, Column 0
.equ DISPLAY_LINE_4   = 0x60       ; DDRAM Line 1, Column 0


#endif

