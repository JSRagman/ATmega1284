;
; TwiFuncs_Basic.asm
;
; Created: 25May2019
; Updated: 14Jul2019
;  Author: JSRagman
;
;
; Description:
;     Basic TWI functions for the ATmega1284P.
;
; Depends On:
;     1.  m1284pdef.inc
;
; Reference:
;     1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
; Function List:
;     TwiConnect          Combines TwiStart and TwiSendAddress
;     TwiStop             Generates a STOP condition.
;     TwiWait             Waits for TWINT, returns TWSR status bits.
;
;
; TWI I/O Registers:
;     TWBR - (0xB8) TWI Bit Rate Register
;     TWCR - (0xBC) TWI Control Register
;                   Bit 7: TWINT    TWI Interrupt Flag
;                   Bit 6: TWEA     TWI Enable Ack
;                   Bit 5: TWSTA    TWI START Condition
;                   Bit 4: TWSTO    TWI STOP Condition
;                   Bit 3: TWWC     TWI Write Collision Flag
;                   Bit 2: TWEN     TWI Enable
;                   Bit 1:  -       Reserved
;                   Bit 0: TWIE     TWI Interrupt Enable
;     TWDR - (0xBB) TWI Data Register
;     TWSR - (0xB9) TWI Status Register
;                   Bits 7:3:  TWS7:TWS3    TWI Status Code
;                   Bit  2:                 Reserved
;                   Bits 1:0   TWPS1:TWPS0  TWI Prescaler Bits



#ifndef _twifuncs_basic
#define _twifuncs_basic




; TwiConnect                                                          14Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  12Jul2019
; Description:
;     Generates a TWI START condition and transmits SLA+R/W.
;     Returns the SREG T flag to indicate success/failure.
; Parameters:
;     r20       - SLA+R/W for the targeted TWI device
; General-Purpose Registers:
;     Preserved - r17, r18, r19, r20
;     Changed   - 
; I/O Registers Affected:
;     SREG - T flag is used to report success/failure
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWCR_START
;     TWISTAT_SLAR_ACK
;     TWISTAT_SLAW_ACK
;     TWISTAT_START
; Functions Called:
;     TwiWait - Waits for TWINT, returns TWSR status bits in r19.
; Returns:
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
TwiConnect:
    push   r17
    push   r18
    push   r19

   .def    expected = r17                   ; expected TWSR status code
   .def    cmd      = r18                   ; TWCR command byte
   .def    result   = r19                   ; TwiWait return value
   .def    slarw    = r20                   ; SLA+R/W parameter

    bclr   SREG_T                           ; clear the SREG T flag

;   Transmit START condition
    ldi    cmd,      TWCR_START
    sts    TWCR,     cmd                    ; Generate START condition.
    rcall  TwiWait                          ; wait for TWINT.
    cpi    result,   TWISTAT_START          ; if (result != TWISTAT_START)
    brne   error_TwiConnect                 ;     goto error

;   Transmit SLA+R/W
    ldi    expected,  TWISTAT_SLAW_ACK      ; expected = SLAW_ACK
    sbrc   slarw,     0                     ; if (RW bit == Read)
    ldi    expected,  TWISTAT_SLAR_ACK      ;     expected = SLAR_ACK
    sts    TWDR,      slarw                 ; load SLA+R/W into TWDR
    ldi    cmd,       TWCR_GO
    sts    TWCR,      cmd                   ; start transmission
    rcall  TwiWait                          ; wait for TWINT
    cp     result,    expected              ; if (result == expected)
    breq   exit_TwiConnect                  ;     goto exit
                                            ; fall into error
error_TwiConnect:
    bset   SREG_T                           ; set SREG T flag

exit_TwiConnect:
   .undef  slarw
   .undef  result
   .undef  cmd
   .undef  expected

    pop    r19
    pop    r18
    pop    r17
    ret



; TwiStop                                                             12Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  12Jul2019
; Description:
;     Generates a TWI STOP condition.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - r16
;     Changed   - 
; I/O Registers Affected:
;     TWCR - TWI Control Register
; Constants (Non-Standard):
;     TWCR_STOP
; Returns:
;     Nothing
TwiStop:
    push  r16

    ldi   r16,     TWCR_STOP
    sts   TWCR,    r16

    pop   r16
    ret


; TwiWait                                                             12Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  12Jul2019
; Description:
;     Waits for the TWINT flag to be set, then returns the TWSR status bits
;     with the prescaler bits masked out.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - r19
; Constants (Non-Standard):
;     TWISTAT_PREMASK
; Returns:
;     r19 - TWSR status bits.
TwiWait:
    lds    r19,    TWCR                     ; read TWCR
    sbrs   r19,    TWINT                    ; if (TWINT == 0)
    rjmp   TwiWait                          ;     continue waiting

    lds    r19,    TWSR                     ; read TWSR and
    andi   r19,    TWISTAT_PREMASK          ; mask out prescaler bits
    ret



#endif
