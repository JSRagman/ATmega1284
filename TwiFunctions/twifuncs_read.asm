;
; twifuncs_read.asm
;
; Created: 25Jul2019
; Updated: 21Sep2019
;  Author: JSRagman
;
;
; Description:
;     TWI Data Read functions for the ATmega1284P.
;
; Depends On:
;     1.  m1284pdef.inc
;     2.  constants.asm
;     3.  TwiFuncs_Basic.asm
;     4.  DataStackMacros.asm
;
; Reference:
;     1.  ATmega1284/1284P datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
; Function List:
;     TwiDr_Receive        Receives one byte from TWI
;     TwiDr_RegByte        Retrieves one byte from a device register
;     TwiDr_RegConnect     Establish connection to read from a device
;     TwiDr_ToSram         Receives data from a device and stores in SRAM.



; TwiDr_Receive                                                        3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Receives one byte from a TWI-connected device.
; Initial Conditions:
;     A read connection has been established
; Parameters:
;     SREG_C  - Respond to received data with ACK (0), or NACK (1)
; General-Purpose Registers:
;     Parameters - 
;     Constants  - 
;     Modified   - Y
; Data Stack:
;     Initial    - empty
;     Final
;         pass   - one byte of data
;         fail   - empty
; I/O Registers Affected:
;     SREG - The T flag is returned from this function to indicate success (0)
;            or failure (1).
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO_ACK   (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
;     TWCR_GO_NACK  (1<<TWINT)|(1<<TWEN)
;     TWSR_DR_ACK   (0x50) - A data byte has been received, ACK returned
;     TWSR_DR_NACK  (0x58) - A data byte has been received, NACK returned
;     TWSR_PREMASK  (0b_1111_1000) - Mask out TWSR prescaler bits
; Functions Called:
;     Twi_Wait()
; Macros Used:
;     pushd  - Push the contents of a register onto the data stack
; Returns:
;     SREG_T      - pass (0) or fail (1)
;     Data Stack
;         pass    - one byte of data
;         fail    - empty
TwiDr_Receive:
    push   r16
    push   r18
    push   r19

   .def    expected = r18
   .def    result   = r19

    ldi    expected,  TWSR_DR_ACK           ; expected = DR_ACK
    ldi    r16,       TWCR_GO_ACK           ; r16 = clear TWINT, set TWEN, set TWEA
    brcc   TwiDr_Receive_begin              ; if (SREG_C == 0)  goto _begin
                                            ; else
    ldi    expected,  TWSR_DR_NACK          ;     expected = DR_NACK
    ldi    r16,       TWCR_GO_NACK          ;     r16 = clear TWINT, set TWEN
                                            ;     fall into _begin
TwiDr_Receive_begin:
    sts    TWCR,   r16                      ; TWCR   = r16
    rcall  Twi_Wait                         ; result = Twi_Wait()
    cp     result, expected                 ; if (result != expected)
    brne   TwiDr_Receive_error              ;     goto error
                                            ; else
    lds    r16,    TWDR                     ;     r16 = data
    pushd  r16                              ;     Data Stack: push r16
    rjmp   TwiDr_Receive_exit               ;     goto exit

TwiDr_Receive_error:
    set                                     ; error: SREG_T = 1
                                            ; fall into exit
TwiDr_Receive_exit:

   .undef  expected
   .undef  result

    pop    r19
    pop    r18
    pop    r16
    ret


; TwiDr_RegByte                                                        3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Retrieves one data byte from a specified device register and returns
;     it on the data stack.
;
;     If this function encounters an error, the SREG_T flag will be set and
;     the data stack will remain empty.
; Parameters:
;     r20 - SLA+W for the targeted device
;     r21 - device register address
; General-Purpose Registers:
;     Parameters - r20, r21
;     Constants  - 
;     Modified   - 
; I/O Registers Affected:
;     SREG   - The C flag is set to indicate that only one byte will be
;              received.
;            - The T flag is returned from this function to indicate success (0)
;              or failure (1).
; Functions Called:
;     TwiDr_Receive(SREG_C)
;     TwiDr_RegConnect(r20, r21)
;     Twi_Stop
; Returns:
;     SREG_T      - pass (0) or fail (1)
;     Data Stack
;         pass    - one byte of data
;         fail    - empty
TwiDr_RegByte:

    rcall  TwiDr_RegConnect                 ; SREG_T = TwiDr_RegConnect(r20, r21)
    brts   TwiDr_RegByte_exit               ; if (SREG_T == 1)  goto exit

    sec                                     ; SREG_C = 1
    rcall  TwiDr_Receive                    ; SREG_T = TwiDr_Receive(SREG_C)
                                            ; fall into exit
TwiDr_RegByte_exit:
    rcall  Twi_Stop                         ; Twi_Stop()

    ret


; TwiDr_RegConnect                                                     3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Prepare to read from one or more registers of a TWI-connected device:
;         a) Establish a TWI write connection
;         b) Write the device register address
;         c) Establish a TWI read connection
; Parameters:
;     r20 - SLA+W for the targeted device
;     r21 - device register address
; Functions Called:
;     Twi_Connect(r20)
;     TwiDw_Send(r21)
; Returns:
;     SREG_T - success (0) or fail (1)
TwiDr_RegConnect:
    push   r20

   .def    slarw   = r20                    ; parameter: SLA+W
   .def    regaddr = r21                    ; parameter: device register address

    rcall  Twi_Connect                      ; SREG_T = Twi_Connect(r20)
    brts   TwiDr_RegConnect_exit            ; if (SREG_T == 1)  goto exit
    rcall  TwiDw_Send                       ; SREG_T = TwiDw_Send(r21)
    brts   TwiDr_RegConnect_exit            ; if (SREG_T == 1)  goto exit
    sbr    slarw,  1                        ; SLA+R/W bit = Read
    rcall  Twi_Connect                      ; SREG_T = Twi_Connect(r20)

TwiDr_RegConnect_exit:

   .undef  slarw
   .undef  regaddr

    pop    r20
    ret


; TwiDr_ToSram                                                         2Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Receives a specified number of data bytes from a TWI device. Stores the
;     received data in SRAM.
; Parameters:
;     r17  - byte count
;     r20  - SLA+W for the targeted TWI device
;     r21  - device register address
;     X    - SRAM destination address pointer
; General-Purpose Registers:
;     Parameters - r20, r21, X
;     Constants  - 
;     Modified   - Y
; I/O Registers Affected:
;     SREG_C - The C flag identifies the last byte when used as an argument to
;              the TwiDr_Receive function.
;     SREG_T - The T flag is returned from this function to indicate success (0)
;              or failure (1).
; Functions Called:
;     TwiDr_Receive(SREG_C)
;     TwiDr_RegConnect(r20, r21)
;     Twi_Stop()
; Returns:
;     SREG_T - pass (0) or fail (1)
TwiDr_ToSram:
    push   r16
    push   r17
    push   r20
    push   XL
    push   XH

   .def    databyt = r16
   .def    count   = r17                    ; parameter: byte count
   .def    slawr   = r20                    ; parameter: SLA+W
   .def    regaddr = r21                    ; parameter: device register address

    rcall  TwiDr_RegConnect                 ; SREG_T = TwiDr_RegConnect(r20, r21)
    brts   TwiDr_ToSram_exit                ; if (SREG_T == 1)  goto exit

TwiDr_ToSram_loop:
    cpi    count,  2                        ; if (count < 2)  SREG_C = 1
    rcall  TwiDr_Receive                    ; SREG_T = TwiDr_Receive(SREG_C)
    brts   TwiDr_ToSram_exit                ; if (SREG_T == 1)  goto exit
    popd   databyt                          ; Data Stack: pop data byte returned
                                            ; from TwiDr_Receive
    st     X+,     databyt                  ; store data byte to SRAM, increment X
    dec    count                            ; count = count - 1
    brne   TwiDr_ToSram_loop                ; if (count > 0)  continue looping

TwiDr_ToSram_exit:
    rcall  Twi_Stop                         ; Twi_Stop()

   .undef  databyt
   .undef  count
   .undef  slawr
   .undef  regaddr

    pop    XH
    pop    XL
    pop    r20
    pop    r17
    pop    r16
    ret



