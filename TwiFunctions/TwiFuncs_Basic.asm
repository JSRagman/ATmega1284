;
; TwiFuncs_Basic.asm
;
; Created: 25May2019
; Updated: 27May2019
;  Author: JSRagman
;
;
; Description:
;     Basic TWI functions and constants for the ATmega1284P.
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
;     TwiSendAddress      Transmits SLA+R/W.
;     TwiStart            Generates START condition.
;     TwiStop             Generates STOP condition.
;     TwiWait             Waits for TWINT, returns TWSR status bits.



#ifndef _twi_funcs_basic
#define _twi_funcs_basic



; TWCR Constants
; -----------------------------------------------------------------------------
.EQU  TWCR_GO    = (1<<TWINT)|(1<<TWEN)               ; set TWEN, clear TWINT
.EQU  TWCR_START = (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)    ; generate START
.EQU  TWCR_STOP  = (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)    ; generate STOP


; TWSR Constants
; -----------------------------------------------------------------------------

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



; TwiConnect                                                          27May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a TWI START condition and transmits SLA+R/W.
;     Returns the SREG T flag to indicate success/failure.
; Parameters:
;     r20       - SLA+R/W for the targeted TWI device
; General-Purpose Registers:
;     Preserved - r17, r18, r19, r20
;     Changed   - 
; I/O Registers Affected:
;     SREG - T flag is used to report function success/failure
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
;     TwiWait - Waits for TWINT, returns TWSR status bits.
; Returns:
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
TwiConnect:
    push   r17
    push   r18
    push   r19

   .DEF    expected = r17              ; expected TWSR status code
   .DEF    twcr_cmd = r18              ; TWCR command byte
   .DEF    result   = r19              ; TwiWait return value
   .DEF    sla_rw   = r20              ; SLA+R/W parameter

    bclr   SREG_T                      ; clear the SREG T flag

;   Transmit START condition
    ldi    expected,  TWISTAT_START    ; expected = START
    ldi    twcr_cmd,  TWCR_START
    sts    TWCR,      twcr_cmd         ; Generate START condition.
    rcall  TwiWait                     ; wait for TWINT.
    cp     result,    expected         ; if (result != expected)
    brne   TwiConnect_error            ;     goto error

;   Transmit SLA+R/W
    ldi    expected,  TWISTAT_SLAW_ACK ; expected = SLAW_ACK
    sbrc   sla_rw,    0                ; if (RW bit == Read)
    ldi    expected,  TWISTAT_SLAR_ACK ;     expected = SLAR_ACK
    sts    TWDR,      sla_rw           ; load SLA+R/W into TWDR
    ldi    twcr_cmd,  TWCR_GO
    sts    TWCR,      twcr_cmd         ; start transmission
    rcall  TwiWait                     ; wait for TWINT
    cp     result,    expected         ; if (result == expected)
    breq   TwiConnect_exit             ;     goto exit
                                       ; fall into error
TwiConnect_error:
    bset   SREG_T                      ; set SREG T flag

TwiConnect_exit:
   .UNDEF  sla_rw
   .UNDEF  result
   .UNDEF  twcr_cmd
   .UNDEF  expected

    pop    r19
    pop    r18
    pop    r17
    ret


; TwiSendAddress                                                      27May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a TWI SLA+R/W and waits for the TWINT flag to be set.
;     Returns the SREG T flag to indicate success/failure.
; Parameters:
;     r20       - SLA+R/W for the targeted TWI device
; General-Purpose Registers:
;     Preserved - r16, r17, r19, r20
;     Changed   - 
; I/O Registers Affected:
;     SREG - T flag is used to report function success/failure
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWISTAT_SLAR_ACK
;     TWISTAT_SLAW_ACK
; Functions Called:
;     TwiWait
; Returns:
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
;     TWSR - Will contain a status code from the last TWI operation performed
TwiSendAddress:
    push   r16
    push   r17
    push   r19

   .DEF    expected = r17                   ; expected TWSR status code
   .DEF    result   = r19                   ; TwiWait return value
   .DEF    sla_rw   = r20                   ; SLA+R/W parameter

    bclr   SREG_T                           ; clear the SREG T flag
    ldi    expected,  TWISTAT_SLAW_ACK      ; expected result = SLAW_ACK
    sbrc   sla_rw,    0                     ; if (RW bit == Read)
    ldi    expected,  TWISTAT_SLAR_ACK      ;     expected result = SLAR_ACK

    sts    TWDR,      sla_rw                ; load SLA+R/W into TWDR
    ldi    r16,       TWCR_GO               ; start transmission
    sts    TWCR,      r16
    rcall  TwiWait                          ; wait for TWINT
    cp     result,    expected              ; if (result == expected)
    breq   TwiSendAddressExit               ;     goto exit
                                            ; else
    bset   SREG_T                           ;     error - set the SREG T flag

TwiSendAddressExit:
   .UNDEF  sla_rw
   .UNDEF  result
   .UNDEF  expected

    pop    r19
    pop    r17
    pop    r16
    ret

; TwiStart                                                            27May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a TWI START condition and waits for TWINT to be set.
;     Returns the SREG T flag to indicate success/failure.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - r16, r19
;     Changed   - 
; I/O Registers Affected:
;     SREG - T flag is used to report function success/failure
;     TWCR - TWI Control Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_START
;     TWISTAT_START
; Functions Called:
;     TwiWait
; Returns:
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
;     TWSR - Will contain a status code from the last TWI operation performed
TwiStart:
    push   r16
    push   r19

   .DEF    result = r19                ; TwiWait return value

    bclr   SREG_T                      ; clear the SREG T flag
    ldi    r16,    TWCR_START          ; Generate START condition.
    sts    TWCR,   r16
    rcall  TwiWait                     ; Wait for TWINT.
    cpi    result, TWISTAT_START       ; if (result == START)
    breq   TwiStartExit                ;     exit
                                       ; else
    bset   SREG_T                      ;     set SREG T flag
                                       ;     and exit
TwiStartExit:
   .UNDEF  result

    pop    r19
    pop    r16
    ret



; TwiStop                                                             27May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a TWI STOP condition.
;     Waits for the TWINT flag to be set, then returns.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - r16
;     Changed   - 
; I/O Registers Affected:
;     TWCR - TWI Control Register
; Constants (Non-Standard)
;     TWCR_STOP
; Returns:
;     Nothing
TwiStop:
    push  r16
    ldi   r16, TWCR_STOP
    sts   TWCR, r16               ; generate STOP condition
TwiStopWait:
    lds   r16, TWCR               ; read the TWCR
    sbrs  r16, TWINT              ; if (TWINT == 0)
    rjmp  TwiStopWait             ;   continue waiting

    pop   r16
    ret


; TwiWait                                                             27May2019
; -----------------------------------------------------------------------------
; Description:
;     Waits for the TWINT flag to be set, then returns the TWSR status bits,
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
    lds   r19, TWCR               ; read TWCR
    sbrs  r19, TWINT              ; if (TWINT == 0)
    rjmp  TwiWait                 ;   continue waiting
                                  ; else
    lds   r19, TWSR               ;   read TWSR and
    andi  r19, TWISTAT_PREMASK    ;   mask out prescaler bits
    ret



#endif
