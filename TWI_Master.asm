;  TWI_Master.asm
;
;  Created: 5/3/2019
;  Author: JSRagman
;
;  Description:
;      Functions and definitions for the ATmega1284P MCU to operate as a TWI Master.
;
;  Constants:
;      Uses constants defined in m1284pdef.inc.
;      Additional constant definitions are inserted at the top of this file for
;      clarity - normally I would keep them in a separate file.
;
;  Reference:
;      1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;      2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
;  Notes on using the IN and OUT instructions:
;     STS and LDS are used in many places (instead of OUT and IN) because TWI
;     register addresses are greater than 0x3F.
;     The ATmega1284 datasheet mistakenly uses OUT and IN in the example code.
;     See the AVR Instruction Set documentation for OUT and IN.


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
;        f_twi_start           Generates a TWI START condition
;        f_twi_stop            Generates a STOP condition
;    Master Transmitter Mode
;        f_twi_slaw            Transmits SLA+W
;        f_twi_dataw           Transmits a data byte



; f_twi_start
; -----------------------------------------------------------------------------
; Transmission Mode:
;     Master Transmitter/Master Receiver
; Description:
;     Instructs the TWI to generate a START condition. Waits for the TWINT flag
;     and then returns.
; General-Purpose Registers Used:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register (0xBC)
;     TWSR - TWI Status Register  (0xB9)
; Returns:
;     TWSR - Caller should check the TWSR status bits on return.
f_twi_start:
    ldi  r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
    sts TWCR, r16                 ; clear TWINT, set TWSTA, set TWEN.

    twi_start_wait:               ; wait for TWINT.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_start_wait

    ret


; f_twi_slawr
; -----------------------------------------------------------------------------
; Transmission Mode:
;     Master Transmitter(SLA+W)/Master Receiver(SLA+R)
; Description:
;     Transmits a TWI slave address and R/W bit (SLA+R/W). Waits for the
;     TWINT flag and then returns.
; Parameters:
;     r16 - Must contain a one-byte SLA+R/W (7-bit TWI address followed
;           by 1-bit R/W as bit 0).
;     Note: r16 is used as a parameter here just for simplicity.
; General-Purpose Registers Used:
;     1. Preserved - 
;     2. Changed   - r16, r29:r28(YH:YL)
; I/O Registers Affected:
;     TWCR - TWI Control Register (0xBC)
;     TWDR - TWI Data Register    (0xBB)
;     TWSR - TWI Status Register  (0xB9)
; Returns:
;     TWSR - Caller should check the TWSR status bits on return.
f_twi_slawr:
    sts TWDR, r16                      ; Load SLA+R/W into TWDR.
    ldi  r16, (1<<TWINT)|(1<<TWEN)     ; clear TWINT, set TWEN
    sts TWCR, r16                      ; transmit

    twi_slawr_wait:                     ; Wait for TWINT
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_slawr_wait

    ret



; f_twi_dataw
; -----------------------------------------------------------------------------
; Transmission Mode:
;     Master Transmitter
; Description:
;     Transmits a data byte. Waits for the TWINT flag and then returns.
; Parameters:
;     r16 - must contain the byte to be transmitted.
; General-Purpose Registers Used:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register (0xBC)
;     TWDR - TWI Data Register    (0xBB)
;     TWSR - TWI Status Register  (0xB9)
; Returns:
;     TWSR - Caller should check the TWSR status bits on return.
f_twi_dataw:
    sts TWDR, r16                      ; load TWDR with data.
    ldi  r16, (1<<TWINT)|(1<<TWEN)
    sts TWCR, r16                      ; clear TWINT, set TWEN.

    twi_dataw_wait:                    ; wait for TWINT.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_dataw_wait

    ret


; f_twi_stop
; -----------------------------------------------------------------------------
; Transmission Mode:
;     Master Transmitter/Master Receiver
; Description:
;     Instructs the TWI to generate a STOP condition. Waits for the TWINT flag
;     and then returns.
; General-Purpose Registers Used:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register (0xBC)
; Returns:
;     TWSR - Caller should check the TWSR status bits on return.
f_twi_stop:
    ldi  r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
    sts TWCR, r16                      ; clear TWINT, set TWSTO, set TWEN.

    twi_stop_wait:                     ; wait for TWINT.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_stop_wait

    ret


