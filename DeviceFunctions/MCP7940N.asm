;
; MCP7940N.asm
;
; Created: 14Aug2019
; Updated: 21Sep2019
;  Author: JSRagman
;
; Hardware:
;     MCU:              ATmega1284, ATmega1284P
;     Real-Time Clock:  Microchip MCP7940N
;     Interface:        TWI
;
; Description:
;     Basic functions for interacting with the MCP7940
;
;
; Function List:
;     RTC_GetTime       Reads the RTC timekeeping registers into SRAM.
;     RTC_SetTime       Sets the RTC timekeeping registers from SRAM data.
;
; Depends On:
;     1.  m1284pdef.inc
;     2.  constants.asm
;     3.  mainfuncs.asm
;             main_Wait           (r21)
;     3.  twifuncs_read.asm
;             TwiDr_ToSram        (r17, r20, r21, X)
;     4.  twifuncs_write.asm
;             TwiDw_ToReg         (r20, r21, r22)
;             TwiDw_ToRegFromSram (r17, r20, r21, X)
;
; Reference:
;     1.  ATmega1284/1284P datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;     3.  Microchip MCP7940N datasheet DS20005010G



; RTC_GetTime                                                         21Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Reads the Real-Time Clock (RTC) timekeeping registers into SRAM.
; Parameters:
;     X - SRAM destination address pointer
; General-Purpose Registers:
;     Parameters - X
;     Constants  - 
;     Modified   - 
; Constants (Non-Standard):
;     RTC_ADDR      - RTC TWI address
;     RTC_SEC       - RTC device register address
;     RTC_TIMEBYTES - Number of RTC registers to be read
; Functions Called:
;     TwiDr_ToSram(r17, r20, r21, X)
; Returns:
;     SREG_T - pass (0) or fail (1)
RTC_GetTime:
    push   r17
    push   r20
    push   r21

    ldi    r17,    RTC_TIMEBYTES            ; argument:  r17 = byte count
    ldi    r20,    RTC_ADDR                 ; argument:  r20 = SLA+W
    ldi    r21,    RTC_SEC                  ; argument:  r21 = first register address
    rcall  TwiDr_ToSram                     ; SREG_T = TwiDr_ToSram(r17, r20, r21, X)

    pop    r21
    pop    r20
    pop    r17
    ret



; RTC_SetTime                                                         21Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Sets the RTC timekeeping registers from SRAM data.
; Parameters:
;     X   - SRAM data pointer
; General-Purpose Registers:
;     Parameters - X
;     Constants  - 
;     Modified   - 
; Constants (Non-Standard):
;     RTC_ADDR      - RTC TWI address
;     RTC_SEC       - RTC device register address
;     RTC_TIMEBYTES - Number of RTC registers to be read
; Functions Called:
;     main_Wait(r21)
;     TwiDw_ToRegFromSram(r17, r20, r21, X)
; Returns:
;     SREG_T - pass (0) or fail (1)
RTC_SetTime:
    push   r17
    push   r20
    push   r21

    ldi    r21,    RTC_SEC                  ; argument:  r21 = RTC_SEC register address
    ldi    r22,    0                        ; argument:  r22 = 0 (stop the clock)
    rcall  TwiDw_ToReg                      ; TwiDw_ToReg(r20, r21, r22)

    ldi    r21,  100                        ; delay time = 100 milliseconds
    rcall  main_Wait                        ; main_Wait(r21)

    ldi    r17,    RTC_TIMEBYTES            ; argument:  r17 = byte count
    ldi    r20,    RTC_ADDR                 ; argument:  r20 = SLA+W
    ldi    r21,    RTC_SEC                  ; argument:  r21 = destination register address
    rcall  TwiDw_ToRegFromSram              ; TwiDw_ToRegFromSram(r17, r20, r21, X)

    ldi    r21,    RTC_SEC                  ; argument:  r21 = destination register address
    ldi    r22,    (1<<RTC_ST)              ; argument:  set the oscillator Start bit
    rcall  TwiDw_ToReg                      ; TwiDw_ToReg(r20, r21, r22)

    pop    r21
    pop    r20
    pop    r17
    ret

