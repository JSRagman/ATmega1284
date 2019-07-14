; TwiConstants.asm
; 14Jul2019
; JSRagman

; Description:
;     TWI-related constant definitions


; CPU Clock           = 8 MHz
; TWSR Prescaler bits = 0
.equ  TWBR_100KHz = 34
.equ  TWBR_400KHz =  2


; TWCR Constants
.equ  TWCR_GO    = (1<<TWINT)|(1<<TWEN)               ; set TWEN, clear TWINT
.equ  TWCR_START = (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)    ; generate START
.equ  TWCR_STOP  = (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)    ; generate STOP


; TWSR Constants

; TWSR: Prescaler Bits Mask
.equ  TWISTAT_PREMASK   = 0b_1111_1000    ; Masks out TWSR prescaler bits.

; TWSR: TWI Master Status Codes
.equ  TWISTAT_START     = 0x08            ; START has been transmitted.
.equ  TWISTAT_REPSTART  = 0x10            ; Repeated START has been transmitted.

; TWSR: Master Transmitter Status Codes
.equ  TWISTAT_SLAW_ACK   = 0x18           ; SLA+W transmitted, ACK received.
.equ  TWISTAT_SLAW_NACK  = 0x20           ; SLA+W transmitted, NACK received.
.equ  TWISTAT_DW_ACK     = 0x28           ; Data transmitted, ACK received.
.equ  TWISTAT_DW_NACK    = 0x30           ; Data transmitted, NACK received.

; TWSR: Master Receiver Status Codes
.equ  TWISTAT_SLAR_ACK   = 0x40           ; SLA+R transmitted, ACK received.
.equ  TWISTAT_SLAR_NACK  = 0x48           ; SLA+R transmitted, NACK received.
.equ  TWISTAT_DR_ACK     = 0x50           ; Data byte received, ACK returned.
.equ  TWISTAT_DR_NACK    = 0x58           ; Data byte received, NACK returned.
