;
; twifuncs_write.asm
;
; Created: 25May2019
; Updated: 21Sep2019
;  Author: JSRagman
;
;
; Description:
;     TWI Data Write functions for the ATmega1284P.
;
; Depends On:
;     1.  m1284pdef.inc
;     2.  constants.asm
;     3.  twifuncs_basic.asm
;     4.  datastackmacros.asm
;
; Reference:
;     1.  ATmega1284/1284P datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
; Function List:
;     TwiDw_FromDataStack        Transmits from the data stack to a designated TWI device.
;     TwiDw_FromEepData          Transmits a block of data from EEPROM to a designated TWI device.
;     TwiDw_FromSram             Transmits a block of data from SRAM to a designated TWI device.
;     TwiDw_Send                 Transmits a data byte over TWI and waits for response.
;     TwiDw_ToRegFromSram        Transmits one or more bytes of data from SRAM to a TWI device,
;                                starting at a specified (device) register address.
;     TwiDw_ToReg                Transmits one byte of data to a targeted device register.
;
; Data Stack:
;     Data stack functionality is implemented using macros found in DataStackMacros.asm.
;     Keep in mind that use of the data stack affects the Y register.




; TwiDw_FromDataStack                                                  4Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits one or more bytes from the Data Stack to a TWI device.
; Parameters:
;     r17        - data stack byte count
;     r20        - SLA+W for the targeted device
;     Data Stack - data
; General-Purpose Registers:
;     Parameters - r17, r20
;     Constants  - 
;     Modified   - Y
; Data Stack:
;     Incoming - x bytes of data
;     Final    - empty
; I/O Registers Affected:
;     SREG - The T flag is returned to indicate success (0) or failure (1)
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Functions Called:
;     Twi_Connect(r20)
;     Twi_Stop()
;     TwiDw_Send(r21)
; Macros Used:
;     popd - Pop from the data stack into a register
; Returns:
;     SREG_T - pass (0) or fail (1)
; Notes:
;     1. If a connection cannot be established, all incoming data will be
;        popped from the data stack before the function returns.
;     2. The data transmission loop will exit when:
;          a) Transmission is complete (count is zero), or
;          b) TwiDw_Send returns with the SREG_T flag set, which indicates
;             that ACK was not received for the transmitted byte.
TwiDw_FromDataStack:
    push   r16
    push   r17
    push   r21

   .def    count   = r17                    ; parameter: byte count
   .def    slaw    = r20                    ; parameter: SLA+W
   .def    databyt = r21

    rcall  Twi_Connect                      ; SREG_T = Twi_Connect(r20)
    brts   TwiDw_FromDataStack_error        ; if (SREG_T == 1)  goto error

    cpi    count,  0                        ; compare ( count, zero )
TwiDw_FromDataStack_loop:
    breq   TwiDw_FromDataStack_exit         ; if (count == 0)  goto exit
    popd   databyt                          ; Data Stack: r21 = data byte
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    dec    count                            ; count = count - 1
    brtc   TwiDw_FromDataStack_loop         ; if (SREG_T == 0)  next byte
                                            ; else  fall into error
TwiDw_FromDataStack_error:
    cpi    count,  0                        ; compare ( count, zero )
TwiDw_FromDataStack_popall:
    breq   TwiDw_FromDataStack_exit         ; if (count == 0) goto exit
    popd   databyt                          ; pop one data byte
    dec    count                            ; count = count - 1
    rjmp   TwiDw_FromDataStack_popall       ; next byte

TwiDw_FromDataStack_exit:
    rcall  Twi_Stop                         ; Twi_Stop()

   .undef  count
   .undef  slaw
   .undef  databyt

    pop    r21
    pop    r17
    pop    r16
    ret


; TwiDw_FromEepData                                                    3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a block of data from EEPROM to a TWI device.
; Parameters:
;     r20     - SLA+W for the targeted TWI device
;     r25:r24 - Points to EEPROM data
;     Count   - The first byte of EEPROM data is expected to be the byte count.
; General-Purpose Registers:
;     Parameters - r20, r24, r25
;     Constants  - 
;     Modified   - 
; I/O Registers Affected:
;     EEARH:EEARL - EEPROM Address Registers
;     EECR - EEPROM Control Register
;     SREG - T flag is used to report function success/failure
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Functions Called:
;     Twi_Connect(r20)
;     Twi_Stop()
;     TwiDw_Send(r21)
; Returns:
;     SREG_T - pass (0) or fail (1)
TwiDw_FromEepData:
    push   r17
    push   r21
    push   r24
    push   r25

   .def    count   = r17
   .def    slaw    = r20                    ; parameter: SLA+W
   .def    databyt = r21
   .def    eepl    = r24                    ; parameter: EEPROM data address, low byte
   .def    eeph    = r25                    ; parameter: EEPROM data address, high byte

    rcall  Twi_Connect                      ; SREG_T = Twi_Connect(r20)
    brts   TwiDw_FromEepData_exit           ; if (SREG_T == 1) goto exit

    out    EEARH,     eeph                  ; Load EEPROM address
    out    EEARL,     eepl
    sbi    EECR,      EERE                  ; EEPROM: Read Enable = 1
    in     count,     EEDR                  ; EEPROM: count = first byte
    cpi    count,     0                     ; compare (count, zero)

TwiDw_FromEepData_loop:
    breq   TwiDw_FromEepData_exit           ; if (count == 0)  goto exit
    adiw   eeph:eepl, 1                     ; Increment the EEPROM address.
    out    EEARH,     eeph                  ; Load EEPROM address
    out    EEARL,     eepl
    sbi    EECR,      EERE                  ; EEPROM: Read Enable = 1
    in     databyt,   EEDR                  ; EEPROM: databyt = addressed byte
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    dec    count                            ; count = count - 1
    brtc   TwiDw_FromEepData_loop           ; if (SREG_T == 0)  continue looping
                                            ; else  fall into exit
TwiDw_FromEepData_exit:
    rcall  Twi_Stop                         ; Twi_Stop()

   .undef  count
   .undef  slaw
   .undef  databyt
   .undef  eepl
   .undef  eeph

    pop    r25
    pop    r24
    pop    r21
    pop    r17
    ret



; TwiDw_FromSram                                                       3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a block of data from SRAM to a TWI device.
;     Data can be sourced from the Data Stack, an SRAM address, or both.
;     The Data Stack is transmitted first, followed by SRAM data.
;
;     This is useful if you have some nice clean data in SRAM but need to
;     preface it with some commands before sending it off.
; Parameters:
;     r17    - Data Stack Byte Count
;              Indicates the number of bytes to be retrieved from the Data
;              Stack. This parameter can be zero.
;     r18    - SRAM Data Byte Count
;              Indicates the number of bytes to be retrieved from an SRAM
;              address. This parameter can be zero.
;     r20    - SLA+W for the targeted TWI device
;     X      - SRAM data address pointer
; General-Purpose Registers:
;     Parameters - r17, r18, r20, X
;     Constants  - rZero
;     Modified   - Y
; Data Stack:
;     Incoming - zero to x bytes of data
;     Final    - empty
; Functions Called:
;     Twi_Connect(r20)
;     Twi_Stop()
;     TwiDw_Send(r21)
; Macros Used:
;     popd - Pop from the data stack into a register
; Returns:
;     SREG_T - pass (0) or fail (1)
; Notes:
;     1. If an error occurs, the Data Stack will be emptied
;        before the function returns.
TwiDw_FromSram:
    push   r16
    push   r17
    push   r18
    push   r21
    push   XL
    push   XH

   .def    dscount = r17                    ; parameter: Data Stack byte count
   .def    srcount = r18                    ; parameter: SRAM data byte count
   .def    slaw    = r20                    ; parameter: SLA+W
   .def    databyt = r21                    ; argument:  TwiDw_Send(r21)

    rcall  Twi_Connect                      ; SREG_T = Twi_Connect(r20)
    brts   TwiDw_FromSram_error

;   Data Stack Section
    cpi    dscount, 0                       ; if (dscount == 0)
    breq   TwiDw_FromSram_addr              ;     goto SRAM Address Section
TwiDw_FromSram_dstack:
    popd   databyt                          ; Data Stack: r21 = data
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    dec    dscount                          ; dscount = dscount - 1
    brts   TwiDw_FromSram_error             ; if (SREG_T == 1)  goto error
    brne   TwiDw_FromSram_dstack            ; if (count > 0)  next Data Stack byte
                                            ; else fall into:
;   SRAM Address Section
TwiDw_FromSram_addr:
    cpi    srcount, 0                       ; compare (srcount, zero)
TwiDw_FromSram_addr_loop:
    breq   TwiDw_FromSram_exit              ; if (srcount == 0) goto exit
    ld     databyt, X+                      ; SRAM: r21 = data
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    dec    srcount                          ; srcount = srcount - 1
    brts   TwiDw_FromSram_exit              ; if (SREG_T == 1)  goto exit
    rjmp   TwiDw_FromSram_addr_loop         ; next SRAM data byte
;   xxxxxxxxxxxxxxx No fall-through xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

TwiDw_FromSram_error:
    cpi    dscount, 0                       ; compare (dscount, zero)
TwiDw_FromSram_popall:
    breq   TwiDw_FromSram_exit              ; if (dscount == 0)  goto exit
    popd   databyt                          ; Data Stack: r21 = data
    dec    dscount                          ; dscount = dscount - 1
    rjmp   TwiDw_FromSram_popall            ; next Data Stack byte
;   xxxxxxxxxxxxxxx No fall-through xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

TwiDw_FromSram_exit:
    rcall  Twi_Stop                         ; Twi_Stop()

   .undef  dscount
   .undef  srcount
   .undef  slaw
   .undef  databyt

    pop    XH
    pop    XL
    pop    r21
    pop    r18
    pop    r17
    pop    r16
    ret


; TwiDw_Send                                                           3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a data byte and validates the response.
; Initial Conditions:
;     A TWI session is in progress with a slave device.
; Parameters:
;     r21 - a data byte
; General-Purpose Registers:
;     Parameters - r21
;     Constants  - 
;     Modified   - 
; I/O Registers Affected:
;     SREG - The T flag is returned to indicate success (0) or failure (1)
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO_NACK  (1<<TWINT)|(1<<TWEN)
;     TWSR_DW_ACK   (0x28) - A data byte has been transmitted, ACK received
; Functions Called:
;     Twi_Wait()
; Returns:
;     SREG_T - pass (0) or fail (1)
TwiDw_Send:
    push   r19

    sts    TWDR,   r21                      ; TWDR = r21
    ldi    r19,    TWCR_GO_NACK             ; TWCR = clear TWINT, set TWEN
    sts    TWCR,   r19
    rcall  Twi_Wait                         ; r19 = Twi_Wait()
    cpi    r19,     TWSR_DW_ACK             ; if (r19 == DW_ACK)
    breq   TwiDw_Send_exit                  ;     goto exit
                                            ; else
    set                                     ;     error: SREG_T = 1
                                            ;     fall into exit
TwiDw_Send_exit:

    pop    r19
    ret


; TwiDw_ToRegFromSram                                                  3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits one or more bytes of data from SRAM to a TWI device, starting
;     at a specified (device) register address.
; Parameters:
;     r17    - Byte Count
;              Indicates the number of bytes to be transferred from SRAM.
;     r20    - SLA+W for the targeted TWI device
;     r21    - Device Register Address
;              Specifies the register destination for the first data byte.
;              Many I2C devices will auto-increment this address when multiple
;              bytes of data are transmitted (rtfm).
;     X      - SRAM data address pointer
; General-Purpose Registers:
;     Parameters - r17, r20, r21, X
;     Constants  - 
;     Modified   - 
; Functions Called:
;     Twi_Connect(r20)
;     Twi_Stop()
;     TwiDw_Send(r21)
; Returns:
;     SREG_T - pass (0) or fail (1)
TwiDw_ToRegFromSram:
    push   r17
    push   r21
    push   XL
    push   XH

   .def    count   = r17                    ; parameter: SRAM data byte count
   .def    slaw    = r20                    ; parameter: SLA+W
   .def    databyt = r21                    ; parameter: device register address

    rcall  Twi_Connect                      ; SREG_T = Twi_Connect(r20)
    brts   TwiDw_ToRegFromSram_exit         ; if (SREG_T == 1)  goto exit
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    brts   TwiDw_ToRegFromSram_exit         ; if (SREG_T == 1)  goto exit

    cpi    count,  0                        ; compare (count, zero)
TwiDw_ToRegFromSram_loop:
    breq   TwiDw_ToRegFromSram_exit         ; if (count == 0) goto exit
    ld     databyt, X+                      ; SRAM: r21 = data
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    dec    count                            ; count = count - 1
    brts   TwiDw_ToRegFromSram_exit         ; if (SREG_T == 1)  goto exit
    rjmp   TwiDw_ToRegFromSram_loop         ; next SRAM data byte

TwiDw_ToRegFromSram_exit:
    rcall  Twi_Stop                         ; Twi_Stop()

   .undef  count
   .undef  slaw
   .undef  databyt

    pop    XH
    pop    XL
    pop    r21
    pop    r17
    ret


; TwiDw_ToReg                                                         20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits one byte of data to a targeted device register.
; Parameters:
;     r20    - SLA+W for the targeted TWI device
;     r21    - target device register address
;     r22    - data byte
; General-Purpose Registers:
;     Parameters - r20, r21, r22
;     Constants  - 
;     Modified   - 
; Functions Called:
;     Twi_Connect(r20)
;     Twi_Stop()
;     TwiDw_Send(r21)
; Returns:
;     SREG_T - pass (0) or fail (1)
TwiDw_ToReg:
    push   r21

    rcall  Twi_Connect                      ; SREG_T = Twi_Connect(r20)
    brts   TwiDw_ToReg_exit                 ; if (SREG_T == 1)  goto exit

    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    mov    r21,    r22                      ; r21 = data for the targeted register
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)

TwiDw_ToReg_exit:
    rcall  Twi_Stop                         ; Twi_Stop()

    pop    r21
    ret
