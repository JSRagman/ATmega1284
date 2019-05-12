;
;  atm1284pTWI.asm
;
;  Created: 4/30/2019 11:14:40 AM
;  Author: JSRagman
;
;  Description:
;      Functions and constants for the ATmega1284P MCU to operate as a TWI Master.
;
;  Depends On:
;      1.  m1284pdef.inc
;      2.  atm1284pDataStackMacros.asm
;
;  Reference:
;      1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;      2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016

;  Function List:
;      f_twi_dataw           Transmits a data byte
;      f_twi_slawr           Transmits SLA+W/R
;      f_twi_start           Generates START condition
;      f_twi_stop            Generates STOP condition
;
;  Macros Used:
;      Data Stack Macros
;          m_pushd
;          m_popd

;  TWI I/O Registers:
;      TWBR - (0xB8) TWI Bit Rate Register
;      TWCR - (0xBC) TWI Control Register
;          Bit 7: TWINT    TWI Interrupt Flag
;          Bit 6: TWEA     TWI Enable Ack Bit
;          Bit 5: TWSTA    TWI START Condition Bit
;          Bit 4: TWSTO    TWI STOP Condition Bit
;          Bit 3: TWWC     TWI Write Collision Flag
;          Bit 2: TWEN     TWI Enable Bit
;          Bit 1:  -       Reserved
;          Bit 0: TWIE     TWI Interrupt Enable
;      TWDR - (0xBB) TWI Data Register
;      TWSR - (0xB9) TWI Status Register
;          Bits 7:3:  TWS7:TWS3    TWI Status Code
;          Bit  2:                 Reserved
;          Bits 1:0   TWPS1:TWPS0  TWI Prescaler Bits


#ifndef _atm1284P_twi_funcs_
#define _atm1284P_twi_funcs_

;  Register Usage:
;      GPIOR0 - Expected to hold a TWI slave address plus R/W bit
;               (SLA+R/W), where required.
;      Data Stack
;          A data stack is required for function parameters and return values.
;          All data stack interactions are accomplished through macros
;          m_pushd and m_popd.




; TWCR Constants:
.equ  TWCR_GO    = (1<<TWINT)|(1<<TWEN)
.equ  TWCR_START = (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
.equ  TWCR_STOP  = (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)

; TWSR: Prescaler Bits Mask
.equ TWSR_PREMASK    = 0xF8

; TWSR: TWI Master Status Codes
.equ TWISTAT_START      = 0x08
.equ TWISTAT_REPSTART   = 0x10
.equ TWISTAT_ARBLOST    = 0x38
; TWSR: Master Transmitter Status Codes
.equ TWISTAT_SLAW_ACK   = 0x18
.equ TWISTAT_SLAW_NACK  = 0x20
.equ TWISTAT_DATAW_ACK  = 0x28
.equ TWISTAT_DATAW_NACK = 0x30
; TWSR: Master Receiver Status Codes
.equ TWISTAT_SLAR_ACK   = 0x40
.equ TWISTAT_SLAR_NACK  = 0x48
.equ TWISTAT_DATAR_ACK  = 0x50
.equ TWISTAT_DATAR_NACK = 0x58



; f_twi_dataw                                                         12May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a data byte.
;     Waits for the TWINT flag before returning.
; Parameters:
;     data byte - The data stack must contain one byte to be transmitted.
; Data Stack:
;     Pops one byte.
;     Pushes one byte.
; General-Purpose Registers:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWSR_PREMASK
; Macros:
;     m_popd  - pops one byte from the data stack.
;     m_pushd - pushes one byte onto the data stack.
; Returns:
;     TWI Status - Returns the TWSR contents (with bits 2:0 masked out)
;                  on the data stack.
f_twi_dataw:
    m_popd r16                    ; Pop data from the data stack
    sts TWDR, r16                 ; and load into TWDR.
    ldi  r16, TWCR_GO
    sts TWCR, r16                 ; transmit

    twi_dataw_wait:               ; wait for TWINT.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_dataw_wait

    lds  r16, TWSR                ; Read the TWSR.
    andi r16, TWSR_PREMASK        ; Mask out prescaler bits.
    m_pushd r16                   ; Push the result onto the data stack.

    ret


; f_twi_start                                                         12May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a START condition.
;     Waits for the TWINT flag before returning.
; Parameters:
;     None.
; Data Stack:
;     Pushes one byte.
; General-Purpose Registers:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWSR_PREMASK
;     TWCR_START
; Macros:
;     m_pushd - pushes one byte onto the data stack.
; Returns:
;     TWI Status - Returns the TWSR contents (with bits 2:0 masked out)
;                  on the data stack.
f_twi_start:
    ldi  r16, TWCR_START
    sts TWCR, r16                 ; TWCR: generate start condition.

    twi_start_wait:               ; Wait until TWINT is set.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_start_wait

    lds  r16, TWSR                ; Read the TWSR.
    andi r16, TWSR_PREMASK        ; Mask out prescaler bits.
    m_pushd r16                   ; Push the result onto the data stack.

    ret


; f_twi_slawr                                                         12May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a TWI slave address and R/W bit (SLA+R/W).
;     Waits for the TWINT flag before returning.
; Parameters:
;     SLA+R/W - GPIOR0
; Data Stack:
;     Pushes one byte.
; General-Purpose Registers:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWSR_PREMASK
; Macros:
;     m_pushd - pushes one byte onto the data stack.
; Returns:
;     TWI Status - Returns the TWSR contents (with bits 2:0 masked out)
;                  on the data stack.
f_twi_slawr:
    in  r16,  GPIOR0              ; get SLA+R/W from GPIOR0
    sts TWDR, r16                 ; and load into TWDR.
    ldi  r16, TWCR_GO
    sts TWCR, r16                 ; transmit

    twi_slawr_wait:               ; Wait for TWINT
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_slawr_wait

    lds  r16, TWSR                ; Read the TWSR.
    andi r16, TWSR_PREMASK        ; Mask out prescaler bits.
    m_pushd r16                   ; Push the result onto the data stack.

    ret


; f_twi_stop                                                          12May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a STOP condition.
;     Waits for the TWINT flag before returning.
; Parameters:
;     None.
; Data Stack:
;     Pushes one byte.
; General-Purpose Registers:
;     1. Preserved - 
;     2. Changed   - r16
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWSR_PREMASK
;     TWCR_STOP
; Macros:
;     m_pushd - pushes one byte onto the data stack.
; Returns:
;     TWI Status - Returns the TWSR contents (with bits 2:0 masked out)
;                  on the data stack.
f_twi_stop:
    ldi  r16, TWCR_STOP
    sts TWCR, r16                 ; clear TWINT, set TWSTO, set TWEN.

    twi_stop_wait:                ; wait for TWINT.
      lds  r16, TWCR
      sbrs r16, TWINT
      rjmp twi_stop_wait

    lds  r16, TWSR                ; Read the TWSR.
    andi r16, TWSR_PREMASK        ; Mask out prescaler bits.
    m_pushd r16                   ; Push the result onto the data stack.

    ret



#endif


