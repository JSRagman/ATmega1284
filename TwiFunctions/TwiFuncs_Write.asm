;
; TwiFuncs_Write.asm
;
; Created: 25May2019
; Updated: 14Jul2019
;  Author: JSRagman
;
;
; Description:
;     TWI Data Write functions for the ATmega1284P.
;
; Depends On:
;     1.  m1284pdef.inc
;     2.  TwiFuncs_Basic.asm
;     3.  DataStackMacros.asm
;
; Reference:
;     1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
; Function List:
;     TwiDw_FromDataStack        Transmits from the data stack to a designated TWI device.
;     TwiDw_FromEepData          Transmits a block of data from EEPROM to a designated TWI device.
;     TwiDw_FromEepString        Transmits string data from EEPROM to a designated TWI device.
;
; Data Stack:
;     Data stack functionality is implemented using macros found in DataStackMacros.asm.
;
;     All TWI Write functions expect SLA+W for the targeted device to be
;     passed in on the data stack.
;
;     Some functions will expect additional parameters to be passed on the
;     data stack (e.g. byte count). See individual function headings for
;     parameter details.


#ifndef _twifuncs_write
#define _twifuncs_write




; TwiDw_FromDataStack                                                 12Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  12Jul2019
; Description:
;     Transmits one or more bytes from the data stack to a designated TWI device.
;     Returns the SREG T flag to indicate success/failure.
; Parameters:
;     SLA+W      - Data Stack
;                  The top byte on the data stack is expected to be SLA+W
;                  for the targeted device.
;     Byte Count - Data Stack
;                  The second byte on the data stack indicates the subsequent
;                  number of bytes to be popped and transmitted.
;     Data       - Data Stack
;                  Below SLA+W and Byte Count, the data stack is expected
;                  to contain the specified number of bytes to be transmitted.
; General-Purpose Registers:
;     Preserved - r16, r17, r18, r19, r20
;     Changed   - 
; Data Stack:
;     Incoming  - 1 byte SLA+W
;                 1 byte Byte Count
;                 x bytes of data
;     Final     - empty
; I/O Registers Affected:
;     SREG - T flag is used to report function success/failure
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWISTAT_DW_ACK
; Functions Called:
;     TwiConnect   - Transmits TWI START and SLA+R/W, returns SREG T flag
;     TwiStop      - Transmits TWI STOP
;     TwiWait      - Waits for TWINT, returns r19
; Macros Used:
;     popd - Pop from the data stack into a specified register
; Returns:
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encounted (set)
;     TWSR - Will contain a status code from the last TWI operation performed
; Notes:
;     1. SLA+W and Byte Count must be popped from the data stack prior to
;        calling TwiConnect.
;     2. If a connection cannot be established (START or SLA+W fail), all
;        incoming data will be popped from the data stack before returning.
;     3. The data transmission loop will exit when:
;          a) Transmission is complete (count is zero), or
;          b) ACK is not received for any transmitted byte.
TwiDw_FromDataStack:
    push   r16
    push   r17
    push   r18
    push   r19
    push   r20

   .def    count   = r17                    ; byte count
   .def    cmd     = r18                    ; TWCR command byte
   .def    result  = r19                    ; TwiWait return value
   .def    sla_w   = r20                    ; SLA+W parameter

    popd   sla_w                            ; pop SLA+W parameter into r20
    popd   count                            ; pop byte count from data stack
    rcall  TwiConnect                       ; Transmit TWI START and SLA+W
    brts   error_TwiDwFromDataStack         ; if (SREG_T == 1)
                                            ;     goto error
    ldi    cmd, TWCR_GO                     ; load TWCR bits outside the loop
loop_TwiDwFromDataStack:
    cp     count,  rZero                    ; if (count == 0)
    breq   exit_TwiDwFromDataStack          ;     goto exit
    popd   r16                              ; pop one byte from data stack
    sts    TWDR,   r16                      ; place data byte in TWDR
    dec    count                            ; decrement count
    sts    TWCR,   cmd                      ; start transmission
    rcall  TwiWait                          ; wait for TWINT
    cpi    result, TWISTAT_DW_ACK           ; if (result == DW_ACK)
    breq   loop_TwiDwFromDataStack          ;     next byte
                                            ; fall into error
error_TwiDwFromDataStack: 
    bset   SREG_T                           ; set the SREG T flag
                                            ; fall into popoff
popoff_TwiDwFromDataStack:                  ; pop any leftover data stack bytes
    cp     count,  rZero                    ; if (count == 0)
    breq   exit_TwiDwFromDataStack          ;     goto exit
    popd   r16                              ; pop one data byte
    dec    count                          ; decrement count
    rjmp   popoff_TwiDwFromDataStack        ; next byte

exit_TwiDwFromDataStack:
    rcall  TwiStop                          ; Generate a STOP condition.

   .undef  sla_w
   .undef  result
   .undef  cmd
   .undef  count

    pop    r20
    pop    r19
    pop    r18
    pop    r17
    pop    r16
    ret


; TwiDw_FromEepData                                                   13Jul2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a block of data from EEPROM to a designated TWI device.
;     Returns the SREG T flag to indicate success/failure.
; Parameters:
;     r25:r24    - Address where the EEPROM data is to be found.
;     Byte Count - The first byte of EEPROM data is expected to indicate the
;                  number of subsequent bytes to be read and transmitted.
;     SLA+W      - Data Stack
;                  The top byte on the data stack is expected to be SLA+W
;                  for the targeted device.
; General-Purpose Registers:
;     Preserved - r16, r17, r18, r19, r20
;     Changed   - r25:r24
; Data Stack:
;     Incoming  - 1 byte SLA+W
;     Final     - empty
; I/O Registers Affected:
;     EEARH:EEARL - EEPROM Address Registers
;     EECR - EEPROM Control Register
;     SREG - T flag is used to report function success/failure
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWISTAT_DW_ACK
; Functions Called:
;     TwiConnect   - Transmits TWI START and SLA+R/W, returns SREG T flag
;     TwiStop      - Transmits TWI STOP
;     TwiWait      - Waits for TWINT, returns r19
; Macros Used:
;     popd - Pop from the data stack into a specified register
; Returns:
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
; Notes:
;     1. If the TwiConnect function sets the SREG T flag, execution branches
;        to the error routine, where the T flag is set again. The intention
;        here is that all error paths should converge on the same spot before
;        the function returns.
TwiDw_FromEepData:
    push   r16
    push   r17
    push   r18
    push   r19
    push   r20

   .def    count   = r17                    ; byte count
   .def    cmd     = r18                    ; TWCR command byte
   .def    result  = r19                    ; TwiWait return value
   .def    sla_w   = r20                    ; SLA+W parameter

    popd   sla_w                            ; pop SLA+W parameter
    rcall  TwiConnect                       ; Transmit TWI START and SLA+W
    brts   error_TwiDwFromEepData

    out    EEARH,  r25                      ; Set EEPROM read address
    out    EEARL,  r24
    sbi    EECR,   EERE                     ; Read byte count from EEPROM
    in     count,  EEDR                     ; and place it in count.
    cp     count,  rZero                    ; if (count == 0)
    breq   error_TwiDwFromEepData           ;     goto error

    ldi    cmd,    TWCR_GO                  ; load TWCR bits outside the loop
loop_TwiDwFromEepData:
    adiw   r25:r24, 1                       ; Increment the EEPROM address.
    out    EEARH,  r25                      ; Load EEPROM address
    out    EEARL,  r24
    sbi    EECR,   EERE                     ; Read EEPROM
    in     r16,    EEDR                     ; and place in r16.
    sts    TWDR,   r16                      ; then Load r16 into TWDR
    sts    TWCR,   cmd                      ; and start transmission
    rcall  TwiWait                          ; wait for TWINT
    cpi    result, TWISTAT_DW_ACK           ; if (result != DW_ACK)
    brne   error_TwiDwFromEepData           ;     goto error
    dec    count                            ; Decrement count
    brne   loop_TwiDwFromEepData            ; if (count > 0) then loop
                                            ; else
    rjmp   exit_TwiDwFromEepData            ;     exit
    
error_TwiDwFromEepData:
    bset   SREG_T                           ; set the SREG T flag

exit_TwiDwFromEepData:
    rcall  TwiStop                          ; generate a STOP condition.

   .undef  sla_w
   .undef  result
   .undef  cmd
   .undef  count

    pop    r20
    pop    r19
    pop    r18
    pop    r17
    pop    r16
    ret


; TwiDw_FromEepString                                                 13Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  13Jul2019
; Description:
;     Transmits string data from EEPROM to a designated TWI device.
;     Transmission ends when an ASCII newline character ('\n') is encounted
;     or when the number of characters read reaches a specified count.
; Parameters:
;     r25:r24    - EEPROM address of the first data byte.
;     SLA+W      - Data Stack
;                  The top byte on the data stack is expected to be SLA+W
;                  for the targeted device.
;     Max Bytes  - Data Stack
;                  The second byte on the data stack indicates the maximum
;                  number of bytes that can be transmitted.
;                  This will terminate the loop in the event that the
;                  EEPROM string data does not contain a newline character.
; General-Purpose Registers:
;     Preserved - r16, r17, r18, r19, r20, r21
;     Changed   - r25:r24
; Data Stack:
;     Incoming  - 1 byte SLA+W
;                 1 byte maximum byte count
;     Final     - empty
; I/O Registers Affected:
;     SREG - T flag is used to report function success/failure
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
;     EEARH:EEARL - EEPROM Address Registers
;     EECR - EEPROM Control Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWISTAT_DW_ACK
; Functions Called:
;     TwiConnect   - Transmits TWI START and SLA+R/W, returns SREG T flag
;     TwiStop      - Transmits TWI STOP
;     TwiWait      - Waits for TWINT, returns r19
; Macros Used:
;     popd - Pop from the data stack
; Returns:
;     SREG - The T flag indicates whether the operation was successful
;            (cleared) or if an error was encounted (set)
TwiDw_FromEepString:
    push   r16
    push   r17
    push   r18
    push   r19
    push   r20

   .def    count   = r17
   .def    cmd     = r18                    ; TWCR command byte
   .def    result  = r19                    ; TwiWait return value
   .def    sla_w   = r20                    ; SLA+W parameter

    popd   sla_w                            ; pop SLA+W parameter
    popd   count                            ; pop the maximum bytes count
    rcall  TwiConnect                       ; Transmit TWI START and SLA+W
    brts   error_TwiDwFromEepString         ; if (SREG_T == 1)  goto error

    ldi    cmd,    TWCR_GO                  ; load TWCR bits outside the loop
loop_TwiDwFromEepString:
    out    EEARH,  r25                      ; Set EEPROM read address
    out    EEARL,  r24
    sbi    EECR,   EERE                     ; Read EEPROM
    in     r16,    EEDR                     ; and place in r16
    cpi    r16,    '\n'                     ; if (r16 == '\n')
    breq   exit_TwiDwFromEepString          ;     goto exit

    adiw   r25:r24, 1                       ; Increment the EEPROM address.
    dec    count                            ; Decrement count
    breq   error_TwiDwFromEepString         ; if (count == 0)  goto error

    sts    TWDR,   r16                      ; place byte in TWDR
    sts    TWCR,   cmd                      ; start transmission
    rcall  TwiWait                          ; wait for TWINT
    cpi    result, TWISTAT_DW_ACK           ; if (result == DW_ACK)
    breq   loop_TwiDwFromEepString          ;     next byte
                                            ; fall into error
error_TwiDwFromEepString:
    bset   SREG_T                           ; set the SREG T flag

exit_TwiDwFromEepString:
    rcall  TwiStop                          ; generate a STOP condition.

   .undef  sla_w
   .undef  result
   .undef  cmd
   .undef  count

    pop    r20
    pop    r19
    pop    r18
    pop    r17
    pop    r16
    ret




#endif
