;
; atm1284pTWIFuncs.asm
;
; Created: 30Apr2019
; Updated: 23May2019
; Author:  JSRagman
;
; Description:
;     Functions for the ATmega1284P MCU to operate as a TWI Master.
;
;     Note - Currently, only TWI Write functions are implemented.
;            Read support is coming soon. I promise.
;
;     These functions do not make use of interrupt handlers.
;     It is assumed that the MCU has nothing better to do than to wait for
;     communication to complete.
;
;
; Depends On:
;     1.  m1284pdef.inc
;     2.  atm1284pConstants.asm
;     3.  atm1284pDataStackMacros.asm
;
; Reference:
;     1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016

; Function List - Data Transfer:
;     f_twi_dw_byte             Transmits one byte, passed in on the data stack.
;     f_twi_dw_csegdata         Transmits a block of data from program memory.
;     f_twi_dw_csegstring       Transmits string data from program memory.
;     f_twi_dw_stack            Transmits one or more bytes passed via the data stack.

; Function List - Utility:
;     f_twi_start               Generates a START condition.
;     f_twi_slarw               Transmits SLA+R/W.
;     f_twi_stop                Generates a STOP condition.
;     f_twint_wait              Waits for TWINT, returns TWSR status bits.


; Data Stack:
;     All Data Transfer functions expect SLA+R/W for the targeted device to be
;     passed in on the data stack.
;
;     Some functions will expect additional parameters to be passed on the
;     data stack (e.g. byte count). See individual function headings for
;     details.

; Register Usage:
;     General-Purpose Registers:
;         r19 - Return value:    TWSR status bits
;         r20 - Parameter:       SLA+R/W

;     Named Registers (global):
;         r_opstat - Used by most functions to indicates success/failure.
;                    The OPSTAT_ERR bit (bit 7) indicates success/failure.
;                    In case of failure, bits 6:0 indicate the process
;                    where the failure ocurred.
;
;     TWI I/O Registers:
;         TWBR - (0xB8) TWI Bit Rate Register
;         TWCR - (0xBC) TWI Control Register
;             Bit 7: TWINT    TWI Interrupt Flag
;             Bit 6: TWEA     TWI Enable Ack Bit
;             Bit 5: TWSTA    TWI START Condition Bit
;             Bit 4: TWSTO    TWI STOP Condition Bit
;             Bit 3: TWWC     TWI Write Collision Flag
;             Bit 2: TWEN     TWI Enable Bit
;             Bit 1:  -       Reserved
;             Bit 0: TWIE     TWI Interrupt Enable
;         TWDR - (0xBB) TWI Data Register
;         TWSR - (0xB9) TWI Status Register
;             Bits 7:3:  TWS7:TWS3    TWI Status Code
;             Bit  2:                 Reserved
;             Bits 1:0   TWPS1:TWPS0  TWI Prescaler Bits


#ifndef _atm1284P_twi_funcs_
#define _atm1284P_twi_funcs_


; f_twi_dw_byte                                                       23May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits one byte, passed in on the data stack.
; Parameters:
;     SLA+W - The top byte on the data stack is expected to be SLA+W
;             for the targeted device.
;     Data  - The second byte on the data stack will be transmitted.
; General-Purpose Registers:
;     Preserved - r16, r17, r20, SREG
;     Changed   - r19
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstat
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     OPSTAT_ERR
;     TWIP_TDATA
;     TWSR_DWACK
; Functions Called:
;     f_twi_start
;     f_twi_slarw
;     f_twint_wait
; Macros Used:
;     m_popd
; Returns:
;     r_opstat - The OPSTAT_ERR bit (bit 7) indicates success/failure.
;                In case of failure, bits 6:0 indicate the process
;                where the failure ocurred.
;     r19      - Will contain the TWSR Status bits from the last process
;                called, not including f_twi_stop, which returns nothing.
f_twi_dw_byte:
    push r16
    in   r16, SREG
    push r16
    push r17
    push r20

   .DEF data   = r17
   .DEF result = r19
   .DEF slaw   = r20

    cli                                ; Please, no interruptions
    m_popd slaw                        ; pop SLA+W from data stack
    m_popd data                        ; pop data byte from data stack

    rcall f_twi_start                  ; generate a START condition
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_byte_exit             ;   goto exit

    rcall f_twi_slarw                  ; transmit SLA+W
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_byte_exit             ;   goto exit

    ldi   r_opstat, TWIP_TDATA         ; Op Status = Transmit Data
    sts   TWDR, data                   ; place data byte in TWDR
    ldi   r16, (1<<TWINT)|(1<<TWEN)    ; set TWEN, clear TWINT
    sts   TWCR, r16                    ; transmit
    rcall f_twint_wait                 ; wait for TWINT.
    cpi   result, TWSR_DWACK           ; if (result == ACK)
    breq  twi_dw_byte_exit             ;   exit
                                       ; else
    sbr  r_opstat, (1<<OPSTAT_ERR)     ;   set the OpStatus error bit

    twi_dw_byte_exit:
        rcall f_twi_stop               ; generate a STOP condition.

   .UNDEF slaw
   .UNDEF result
   .UNDEF data

    pop r20
    pop r17
    pop r16
    out SREG, r16
    pop r16

    ret


; f_twi_dw_csegdata                                                   22May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a block of data from program memory.
; Parameters:
;     SLA+W - The top byte on the data stack is expected to be SLA+W
;             for the targeted device.
;     Data  - Z is expected to point to a program memory location that
;             contains the data.
;     Byte Count - The low byte of the first data word (pointed to by Z)
;             indicates the number of subsequent bytes to be read and
;             transmitted.
;             The high byte of the first word contains no data and
;             should be discarded.
; General-Purpose Registers:
;     Preserved - r16, r17, r18, r20, SREG
;     Changed   - r19, Z
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstat
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     OPSTAT_ERR
;     TWIP_TDATA
;     TWSR_DWACK
; Functions Called:
;     f_twi_start
;     f_twi_slarw
;     f_twi_stop
;     f_twint_wait
; Macros Used:
;     m_popd   - Pop from the data stack into a specified register.
; Returns:
;     r_opstat - The OPSTAT_ERR bit (bit 7) indicates success/failure.
;                In case of failure, bits 6:0 indicate the process
;                where the failure ocurred.
;     r19      - Will contain the TWSR Status bits from the last process
;                called, not including f_twi_stop, which returns nothing.
;     Z        - If an error occurs during data transmission, Z will point
;                to the byte after the one that was being transmitted.
f_twi_dw_csegdata:
    push r16
    in   r16, SREG
    push r16
    push r17
    push r18
    push r20

    .DEF counter = r17
    .DEF twicmd  = r18
    .DEF result  = r19
    .DEF slaw    = r20

    cli                                ; Please, no interruptions
    m_popd slaw                        ; pop SLA+W from data stack

    rcall f_twi_start                  ; generate a START condition
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_csegdata_exit         ;   goto exit

    rcall f_twi_slarw                  ; transmit SLA+W
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_csegdata_exit         ;   goto exit

    ldi   r_opstat, TWIP_TDATA         ; Op Status = Transmit Data
    ldi   twicmd, (1<<TWINT)|(1<<TWEN) ; load TWI control bits outside loop
    lpm   counter, Z+                  ; load the byte count, increment Z
    lpm   r16, Z+                      ; toss the high byte, increment Z
                                       ; Z now points to the first byte of data
    twi_dw_csegdata_loop:
        tst   counter                  ; if (counter == 0)
        breq  twi_dw_csegdata_exit     ;   goto exit
                                       ; else
        lpm   r16, Z+                  ;   load one byte, increment Z
        dec   counter                  ;   decrement counter
        sts   TWDR, r16                ;   place byte in TWDR
        sts   TWCR, twicmd             ;   start transmission
        rcall f_twint_wait             ;   wait for TWINT
        cpi   result, TWSR_DWACK       ;   if (result == ACK)
        breq  twi_dw_csegdata_loop     ;     next byte
                                       ;   else
        sbr  r_opstat, (1<<OPSTAT_ERR) ;     set the OpStatus error bit
                                       ;     exit
    twi_dw_csegdata_exit:
        rcall f_twi_stop               ; generate a STOP condition.

    .UNDEF slaw
    .UNDEF result
    .UNDEF twicmd
    .UNDEF counter

    pop r20
    pop r18
    pop r17
    pop r16
    out SREG, r16
    pop r16
    ret


; f_twi_dw_csegstring                                                 23May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits string data from program memory. String data must be
;     terminated by an ASCII newline character ('\n').
; Parameters:
;     SLA+W - The top byte on the data stack is expected to be SLA+W
;             for the targeted device.
;     Data  - Z is expected to point to a program memory location that
;             contains the string data. The data must be terminated
;             with an ASCII newline character ('\n').
; General-Purpose Registers:
;     Preserved - r16, r17, r20, SREG
;     Changed   - r19, Z
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstat
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     OPSTAT_ERR
;     TWIP_TDATA
;     TWSR_DWACK
; Functions Called:
;     f_twi_start
;     f_twi_slarw
;     f_twi_stop
;     f_twint_wait
; Macros Used:
;     m_popd   - Pop from the data stack into a specified register.
; Returns:
;     r_opstat - The OPSTAT_ERR bit (bit 7) indicates success/failure.
;                In case of failure, bits 6:0 indicate the process
;                where the failure ocurred.
;     r19      - Will contain the TWSR Status bits from the last process
;                called, not including f_twi_stop, which returns nothing.
;     Z        - If an error occurs during data transmission, Z will point
;                to the byte after the one that was being transmitted.
f_twi_dw_csegstring:
    push r16
    in   r16, SREG
    push r16
    push r17
    push r20

   .DEF twicmd = r17
   .DEF result = r19
   .DEF slaw   = r20

    cli                                ; Please, no interruptions
    m_popd slaw                        ; pop SLA+W from data stack

    rcall f_twi_start                  ; generate a START condition
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_csegstring_exit       ;   goto exit

    rcall f_twi_slarw                  ; transmit SLA+W
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_csegstring_exit       ;   goto exit

    ldi   r_opstat, TWIP_TDATA         ; Op Status = Transmit Data
    ldi   twicmd, (1<<TWINT)|(1<<TWEN) ; load TWI control bits outside loop
    twi_dw_csegstring_loop:
        lpm   r16, Z+                  ; load one byte, increment Z
        cpi   r16, '\n'                ; if (byte == '\n')
        breq  twi_dw_csegstring_exit   ;   goto exit

        sts   TWDR, r16                ; place byte in TWDR
        sts   TWCR, twicmd             ; start transmission
        rcall f_twint_wait             ; wait for TWINT
        cpi   result, TWSR_DWACK       ; if (result == ACK)
        breq  twi_dw_csegstring_loop   ;   next byte
                                       ; else
        sbr  r_opstat, (1<<OPSTAT_ERR) ;   set the OpStatus error bit

    twi_dw_csegstring_exit:
        rcall f_twi_stop               ; generate a STOP condition.

   .UNDEF slaw
   .UNDEF result
   .UNDEF twicmd

    pop r20
    pop r17
    pop r16
    out SREG, r16
    pop r16

    ret


; f_twi_dw_stack                                                      23May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits one or more bytes to a specified TWI device.
; Parameters:
;     SLA+W      - The top byte on the data stack is expected to be SLA+W
;                  for the targeted device.
;     Byte Count - The second byte on the data stack indicates the subsequent
;                  number of bytes to be popped and transmitted.
;     Data       - Below SLA+W and the Byte Count, the data stack is expected
;                  to contain one or more bytes to be transmitted.
; General-Purpose Registers:
;     Preserved - r16, r17, r18, r20, SREG
;     Changed   - r19
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstat
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     OPSTAT_ERR
;     TWIP_TDATA
;     TWSR_DWACK
; Functions Called:
;     f_twi_start
;     f_twi_slarw
;     f_twi_stop
;     f_twint_wait
; Macros Used:
;     m_popd   - Pop from the data stack into a specified register.
; Returns:
;     r_opstat - The OPSTAT_ERR bit (bit 7) indicates success/failure.
;                In case of failure, bits 6:0 indicate the process
;                where the failure ocurred.
;     r19      - Will contain the TWSR Status bits from the last process
;                called, not including f_twi_stop, which returns nothing.
; Notes:
;     1. SLA+W and Byte Count must be popped from the data stack prior to
;        calling f_twi_start.
;     2. If a connection cannot be established (START or SLA+W fail), all
;        incoming data will be popped from the data stack before returning.
;     3. The data transmission loop will exit when:
;          a) Transmission is complete (counter is zero), or
;          b) ACK is not received for any transmitted byte.
f_twi_dw_stack:
    push r16
    in   r16, SREG
    push r16
    push r17
    push r18
    push r20

   .DEF counter = r17
   .DEF twicmd  = r18
   .DEF result  = r19
   .DEF slaw    = r20

    cli                                ; Please, no interruptions.
    m_popd slaw                        ; pop SLA+W from data stack
    m_popd counter                     ; pop byte count from data stack

    rcall f_twi_start                  ; generate a START condition
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_stack_popoff          ;   goto popoff

    rcall f_twi_slarw                  ; transmit SLA+W
    sbrc  r_opstat, OPSTAT_ERR         ; if (result == error)
    rjmp  twi_dw_stack_popoff          ;   goto popoff

    ldi   r_opstat, TWIP_TDATA         ; Op Status = Transmit Data
    ldi   twicmd, (1<<TWINT)|(1<<TWEN) ; Load TWI control bits outside loop.
    twi_dw_stack_loop:
        tst   counter                  ; if (counter == 0)
        breq  twi_dw_stack_exit        ;     goto exit
                                       ; else
        m_popd r16                     ;   pop one data byte
        dec   counter                  ;   decrement counter
        sts   TWDR, r16                ;   place byte in TWDR
        sts   TWCR, twicmd             ;   start transmission
        rcall f_twint_wait             ;   wait for TWINT
        cpi   result, TWSR_DWACK       ;   if (result == ACK)
        breq  twi_dw_stack_loop        ;     next byte
                                       ;   else
        sbr  r_opstat, (1<<OPSTAT_ERR) ;     set the OpStatus error bit
    twi_dw_stack_popoff:               ;     pop any leftover bytes
        tst  counter                   ;     if (counter == 0)
        breq twi_dw_stack_exit         ;       goto exit
        m_popd r16                     ;     pop one data byte
        dec   counter                  ;     decrement counter
        rjmp  twi_dw_stack_popoff      ;     next byte

    twi_dw_stack_exit:
        rcall f_twi_stop               ; Generate a STOP condition.

   .UNDEF slaw
   .UNDEF result
   .UNDEF twicmd
   .UNDEF counter

    pop r20
    pop r18
    pop r17
    pop r16
    out SREG, r16
    pop r16

    ret



; f_twi_start                                                         23May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a TWI START condition.
;     Waits for TWINT to be set and then returns.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - r16
;     Changed   - r19
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstat
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     OPSTAT_ERR
;     TWIP_START
;     TWSR_START
; Functions Called:
;     f_twint_wait
; Returns:
;     r_opstat - The OPSTAT_ERR bit (bit 7) indicates success/failure.
;                Bits 6:0 contain the START process code.
;     r19      - TWSR status bits.
f_twi_start:
    push  r16
   .DEF  result = r19

    ldi   r_opstat, TWIP_START         ; Op Status = START
    ldi   r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
    sts   TWCR, r16                    ; Generate START condition.
    rcall f_twint_wait                 ; Wait for TWINT.
    cpi   result, TWSR_START           ; if (result == START)
    breq  twi_start_exit               ;   exit
                                       ; else
    sbr  r_opstat, (1<<OPSTAT_ERR)     ;   set the OpStatus error bit

    twi_start_exit:

   .UNDEF result
    pop  r16
    ret



; f_twi_slarw                                                         23May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a TWI SLA+R/W and waits for the TWINT flag to be set.
; Parameters:
;     SLA+R/W - r20 is expected to contain the SLA+R/W.
; General-Purpose Registers:
;     Preserved - r16, r17, r20
;     Changed   - r19
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstat
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     OPSTAT_ERR
;     TWIP_SLARW
;     TWSR_SLAWACK, TWSR_SLARACK
; Functions Called:
;     f_twint_wait
; Returns:
;     r_opstat - The OPSTAT_ERR bit (bit 7) indicates success/failure.
;                Bits 6:0 contain the SLARW process code.
;     r19      - TWSR status bits.
f_twi_slarw:
    push r16
    push r17

   .DEF  expected = r17
   .DEF  result   = r19
   .DEF  slarw    = r20

    ldi   r_opstat, TWIP_SLARW         ; Op Status = SLA+R/W
    ldi   expected, TWSR_SLAWACK       ; expected result = SLAWACK
    sbrc  slarw, 0                     ; if (RW bit == Read)
    ldi   expected, TWSR_SLARACK       ;   expected result = SLARACK

    sts   TWDR, slarw                  ; load SLA+R/W into TWDR
    ldi   r16,  (1<<TWINT)|(1<<TWEN)   ; set TWEN, clear TWINT
    sts   TWCR, r16                    ; start transmission
    rcall f_twint_wait                 ; wait for TWINT
    cp    result, expected             ; if (result == expected)
    breq  twi_slawr_exit               ;   goto exit
                                       ; else
    sbr  r_opstat, (1<<OPSTAT_ERR)     ;   set the OpStatus error bit

    twi_slawr_exit:

   .UNDEF slarw
   .UNDEF result
   .UNDEF expected

    pop r17
    pop r16
    ret


; f_twi_stop                                                          22May2019
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
; Returns:
;     Nothing
f_twi_stop:
    push r16

    ldi   r16, (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
    sts   TWCR, r16               ; generate STOP condition
    twi_stop_wait:
        lds  r16, TWCR            ; read the TWCR
        sbrs r16, TWINT           ; if (TWINT == 0)
        rjmp twi_stop_wait        ;   continue waiting

    pop r16
    ret


; f_twint_wait                                                        22May2019
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
;     TWSR_PREMASK
; Returns:
;     r19 - TWSR status bits.
f_twint_wait:
    lds  r19, TWCR           ; Read the TWCR
    sbrs r19, TWINT          ; if (TWINT == 0)
    rjmp f_twint_wait        ;   continue waiting
                             ; else
    lds   r19, TWSR          ;   read the TWSR and
    andi  r19, TWSR_PREMASK  ;   mask out prescaler bits
    ret



#endif


