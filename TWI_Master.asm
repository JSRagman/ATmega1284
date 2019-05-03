;  TWI_Master.asm
;
;  Created: 5/3/2019
;  Author: JSRagman
;
;  Description:
;      Functions and definitions for the ATmega1284P MCU to operate as a TWI Master.
;
;  Notes on using the IN and OUT instructions:
;     STS and LDS are used in many places (instead of OUT and IN) because TWI
;     register addresses are greater than 0x3F.
;     The ATmega1284 datasheet mistakenly uses OUT and IN in the example code.
;     See the AVR Instruction Set documentation for OUT and IN.
;
;  Constants:
;      Uses constants defined in m1284pdef.inc.
;      Additional constant definitions are inserted at the top of this file for clarity - normally I would keep them in a separate file.
;
;  Reference:
;      1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;      2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016


;  TWI Registers
;  -------------

;  TWCR - TWI Control Register (0xBC)
;      Bit 7: TWINT    TWI Interrupt Flag
;      Bit 6: TWEA     TWI Enable Ack Bit
;      Bit 5: TWSTA    TWI START Condition Bit
;      Bit 4: TWSTO    TWI STOP Condition Bit
;      Bit 3: TWWC     TWI Write Collision Flag
;      Bit 2: TWEN     TWI Enable Bit
;      Bit 1:  -       Reserved
;      Bit 0: TWIE     TWI Interrupt Enable
;
;  TWSR - TWI Status Register (0xB9)
;      Bits 7:3:  TWS7:TWS3    TWI Status Code
;      Bit  2:                 Reserved
;      Bits 1:0   TWPS1:TWPS0  TWI Prescaler Bits


.equ TWSR_PREMASK = 0xF8           ; TWSR Prescaler bits mask

; TWSR: TWI Master Status Codes
.equ TWISTAT_START      = 0x08
.equ TWISTAT_REPSTART   = 0x10
.equ TWISTAT_ARBLOST    = 0x38

; Master Transmitter Status Codes
.equ TWISTAT_SLAW_ACK   = 0x18
.equ TWISTAT_SLAW_NACK  = 0x20
.equ TWISTAT_DATAW_ACK  = 0x28
.equ TWISTAT_DATAW_NACK = 0x30

; Master Receiver Status Codes
.equ TWISTAT_SLAR_ACK   = 0x40
.equ TWISTAT_SLAR_NACK  = 0x48
.equ TWISTAT_DATAR_ACK  = 0x50
.equ TWISTAT_DATAR_NACK = 0x58


;  Function List:
;  -------------
;    All Master Transmission Modes
;        f_twi_start           Generates a TWI START condition and returns the
;                              resulting status code
;        f_twi_stop            Generates a STOP condition, returns status code
;    Master Transmitter Mode
;        f_twi_slaw            Transmits SLA+W, returns status code
;        f_twi_dataw           Transmits a data byte, returns status code
;    Master Receiver Mode



; f_twi_start
; -----------------------------------------------------------------------------
; Transmission Mode:
;     Master Transmitter/Master Receiver
; Description:
;     Instructs the TWI to generate a START condition. Waits for the TWINT flag
;     and then returns the TWI status code.
; General-Purpose Registers Used:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register (0xBC)
;     TWSR - TWI Status Register  (0xB9)
; Returns:
;     r16 - Returns the TWI status code in r16.
f_twi_start:
    ldi  r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
    sts TWCR, r16                 ; TWCR: Clear TWINT, set TWSTA, set TWEN.

    twi_start_wait:               ; Wait for TWINT.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_start_wait

    lds  r16, TWSR                ; Read TWSR into r16, mask out prescaler bits.
    andi r16, 0xF8

    ret


; f_twi_slaw
; -----------------------------------------------------------------------------
; Transmission Mode:
;     Master Transmitter
; Description:
;     Transmits a TWI slave address and Write bit (SLA+W).
; Parameters:
;     r16 - must contain a TWI slave address to be transmitted. Bit 0 is the
;           R/W bit, and should be cleared for a write operation.
; General-Purpose Registers Used:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register (0xBC)
;     TWDR - TWI Data Register    (0xBB)
;     TWSR - TWI Status Register  (0xB9)
; Returns:
;     r16 - Returns the TWI status code in r16.
f_twi_slaw:
    cbr  r16, (1<<TWD0)                ; You can't be too careful.
    sts TWDR, r16                      ; Load TWDR with SLA+W.
    ldi  r16, (1<<TWINT)|(1<<TWEN)
    sts TWCR, r16                      ; TWCR: Clear TWINT, set TWEN.

    twi_slaw_wait:                     ; Wait for TWINT.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_slaw_wait

    lds  r16, TWSR                     ; Read TWSR, mask out prescaler bits.
    andi r16, 0xF8

    ret


