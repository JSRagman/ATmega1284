;
;  atm1284pTWIFuncs.asm
;
;  Created: 4/30/2019
;  Author: JSRagman
;
;  Description:
;      Functions and constants for the ATmega1284P MCU to operate as a TWI Master.
;
;  Depends On:
;      1.  m1284pdef.inc
;      2.  atm1284pConstants.asm
;
;  Reference:
;      1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;      2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016

;  Function List:
;      f_twi_dw_csegdata         Transmits a block of data from program memory.
;      f_twi_dw_csegstring       Transmits string data (terminated with \n) from program memory.
;      f_twi_dw_stack            Transmits one or more bytes passed via the data stack.
;      f_twi_start               Generates a START condition, waits for TWINT.
;      f_twi_slawr               Transmits SLA+R/W.
;      f_twi_stop                Generates a STOP condition.
;      f_twint_wait              Waits for TWINT, returns TWSR status bits.


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


; Register Usage:
;     Named Registers (global):
;         r_opstatus
;         r_result
;
;     General-Purpose I/O Registers:
;         GPIOR0 - Expected to hold a TWI slave address plus R/W bit
;                  (SLA+R/W), where required.
;         GPIOR1 - In the event of a TWI communication error, GPIOR1
;                  preserves the TWSR status bits at the time of the
;                  error, with the prescaler bits masked out.



#ifndef _atm1284P_twi_funcs_
#define _atm1284P_twi_funcs_



; f_twi_dw_csegdata                                                   20May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a block of data from program memory.
; Parameters:
;     SLA+W      - GPIOR0 is expected to hold the target TWI slave address
;                  plus a write bit.
;     Address(Z) - Z is expected to point to a program memory location that
;                  contains the data.
;     Byte Count - The low byte of the first data word (pointed to by Z)
;                  indicates the number of subsequent bytes to be read and
;                  transmitted.
;                  The high byte of the first word contains no data and
;                  is discarded.
; General-Purpose Registers:
;     Preserved - r17, r18, SREG
;     Changed   - r16, r19, Z
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstatus, r_result
; I/O Registers Affected:
;     GPIOR1
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
;     TWIP_ERR, TWIP_SLAW, TWIP_START, TWIP_TDATA
;     TWSR_DWACK, TWSR_PREMASK, TWSR_SLAWACK, TWSR_START
; Functions Called:
;     f_twi_start
;     f_twi_slawr
;     f_twint_wait
; Returns:
;     r_opstatus - Bit 7 indicates success/failure (cleared/set).
;                  In case of failure, bits 6:0 indicate the process
;                  where the failure ocurred.
;     GPIOR1     - In case of failure, GPIOR1 will contain the TWSR
;                  Status bits from the offending process.
f_twi_dw_csegdata:
    in   r16, SREG
    push r16
    push r17
    push r18

    .DEF bytecounter = r17
    .DEF twicommand  = r18

    cli                                ; Please, no interruptions.

    ldi   r_opstatus, TWIP_START       ; Op Status = START
    rcall f_twi_start                  ; Generate a TWI START condition.
    cpi   r_result, TWSR_START         ; does twiresult = TWSR_START ?
    brne  twi_dw_csegdata_err          ; If not, goto err

    ldi   r_opstatus, TWIP_SLAW        ; Op Status = SLA+W
    rcall f_twi_slawr                  ; Transmit SLA+W.
    cpi   r_result, TWSR_SLAWACK       ; Is ACK received ?
    brne  twi_dw_csegdata_err          ; If not, goto err

    ldi   r_opstatus, TWIP_TDATA       ; Op Status = Transmit Data
    ldi   twicommand, TWCR_GO          ; Load TWI control bits.
    lpm   bytecounter, Z+              ; Load the data byte count, increment Z.
    lpm   r16, Z+                      ; Toss the high byte, increment Z.
                                       ; Z now points to the first byte of data.
    ; Data transmission loop.
    ; This loop will exit when:
    ;     a) Transmission is complete (bytecounter is zero), or
    ;     b) ACK is not received for any transmitted byte.
    twi_dw_csegdata_loop:
        lpm   r16, Z+                  ; Load one byte, increment Z.
        sts   TWDR, r16                ; Place byte in TWDR.
        sts   TWCR, twicommand         ; Start transmission.
        rcall f_twint_wait             ; Wait for TWINT.
        cpi   r_result, TWSR_DWACK     ; ACK received?
        brne  twi_dw_csegdata_err      ; If not, goto err
        dec   bytecounter              ; Decrement the byte counter.
        brne  twi_dw_csegdata_loop     ; Zero? If not, continue looping.
        rjmp  twi_dw_csegdata_exit

    twi_dw_csegdata_err:
        ori  r_opstatus, TWIP_ERR      ; Set the OpStatus error bit.
        out  GPIOR1, r_result          ; Preserve TWSR status bits.

    twi_dw_csegdata_exit:
        rcall f_twi_stop               ; Generate a STOP condition.

    .UNDEF twicommand
    .UNDEF bytecounter

    pop r18
    pop r17
    pop r16
    out SREG, r16
    ret



; f_twi_dw_csegstring                                                 20May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits string data from program memory. String data must be
;     terminated by an ASCII newline character ('\n').
; Parameters:
;     SLA+W      - GPIOR0 is expected to hold the target TWI slave address
;                  plus a write bit.
;     Address(Z) - Z is expected to point to a program memory location that
;                  contains the string data. The data must be terminated
;                  with an ASCII newline character ('\n').
; General-Purpose Registers:
;     Preserved - r17, SREG
;     Changed   - r16, Z
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstatus, r_result
; I/O Registers Affected:
;     GPIOR1
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Functions Called:
;     f_twi_start
;     f_twi_slawr
;     f_twint_wait
; Returns:
;     r_opstatus - Bit 7 indicates success/failure (cleared/set).
;                  In case of failure, bits 6:0 indicate the process
;                  where the failure ocurred.
;     r_result
f_twi_dw_csegstring:
    in   r16, SREG
    push r16
    push r17

    .DEF twicommand  = r17

    cli                                ; Please, no interruptions.
    ldi   r_opstatus, TWIP_START       ; Op Status = START
    rcall f_twi_start                  ; Generate a TWI START condition.
    cpi   r_result, TWSR_START         ; if result != TWSR_START
    brne  twi_dw_csegstring_err        ;   goto err

    ldi   r_opstatus, TWIP_SLAW        ; Op Status = SLA+W
    rcall f_twi_slawr                  ; Transmit SLA+W.
    cpi   r_result, TWSR_SLAWACK       ; if result != ACK
    brne  twi_dw_csegstring_err        ;   goto err

    ldi   r_opstatus, TWIP_TDATA       ; Op Status = Transmit Data.
    ldi   twicommand, TWCR_GO          ; Prepare TWCR command.

    ; Data transmission loop.
    ; This loop will exit when:
    ;     a) Transmission is complete ('\n' is encountered), or
    ;     b) ACK is not received for any transmitted byte.
    twi_dw_csegstring_loop:
        lpm   r16, Z+                  ; Load one byte, increment Z.
        cpi   r16, '\n'                ; if byte == '\n'
        breq  twi_dw_csegstring_exit   ;   exit

        sts   TWDR, r16                ;   Place byte in TWDR.
        sts   TWCR, twicommand         ;   Start transmission.
        rcall f_twint_wait             ;   Wait for TWINT.
        cpi   r_result, TWSR_DWACK     ;   if result == ACK
        breq  twi_dw_csegstring_loop   ;     next byte
                                       ;   else
                                       ;     fall into error
    twi_dw_csegstring_err:
        ori  r_opstatus, TWIP_ERR      ; Set the OpStatus error bit.
        out  GPIOR1, r_result          ; Preserve TWSR status bits.

    twi_dw_csegstring_exit:
        rcall f_twi_stop               ; Generate a STOP condition.

    .UNDEF twicommand
    pop r17
    pop r16
    out SREG, r16

    ret



; f_twi_dw_stack                                                      20May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits one or more bytes passed via the data stack.
; Parameters:
;     SLA+W      - GPIOR0 is expected to hold the target TWI slave address
;                  plus a write bit.
;     Byte Count - The top byte on the data stack indicates the subsequent
;                  number of bytes to be popped and transmitted.
;     Data       - The data stack is expected to contain, below the byte count,
;                  one or more bytes of data to be transmitted.
; General-Purpose Registers:
;     Preserved - r17, r18, SREG
;     Changed   - r16
; Named Registers (global):
;     Preserved - 
;     Changed   - r_opstatus, r_result
; I/O Registers Affected:
;     GPIOR1
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Functions Called:
;     f_twi_start
;     f_twi_slawr
;     f_twint_wait
; Macros Used:
;     m_popd
; Returns:
;     r_opstatus - Bit 7 indicates success/failure (cleared/set).
;                  In case of failure, bits 6:0 indicate the process
;                  where the failure ocurred.

f_twi_dw_stack:
    in   r16, SREG
    push r16
    push r17
    push r18

    .DEF bytecounter = r17
    .DEF twicommand  = r18

    cli                                ; Please, no interruptions.
    ldi   r_opstatus, TWIP_START       ; Op Status = START
    rcall f_twi_start                  ; Generate a TWI START condition.
    cpi   r_result, TWSR_START         ; does r_result = TWSR_START ?
    brne  twi_dw_stack_err             ; If not, goto err

    ldi   r_opstatus, TWIP_SLAW        ; Op Status = SLA+W
    rcall f_twi_slawr                  ; Transmit SLA+W.
    cpi   r_result, TWSR_SLAWACK       ; Is ACK received ?
    brne  twi_dw_stack_err             ; If not, goto err

    ldi   r_opstatus, TWIP_TDATA       ; Op Status = Transmit Data
    ldi   twicommand, TWCR_GO          ; Load TWI control bits.
    m_popd bytecounter                 ; Pop the byte count.


    ; Data transmission loop.
    ; This loop will exit when:
    ;     a) Transmission is complete (bytecounter is zero), or
    ;     b) ACK is not received for any transmitted byte.
    twi_dw_stack_loop:
        m_popd r16                     ; Pop one data byte.
        sts   TWDR, r16                ; Place byte in TWDR.
        sts   TWCR, twicommand         ; Start transmission.
        rcall f_twint_wait             ; Wait for TWINT.
        cpi   r_result, TWSR_DWACK     ; ACK received?
        brne  twi_dw_stack_err         ; If not, goto err
        dec   bytecounter              ; Decrement the byte counter.
        brne  twi_dw_stack_loop        ; Zero? If not, continue looping.
        rjmp  twi_dw_stack_exit

    twi_dw_stack_err:
        ori  r_opstatus, TWIP_ERR      ; Set the OpStatus error bit.
        out  GPIOR1, r_result          ; Preserve TWSR status bits.

    twi_dw_stack_exit:
        rcall f_twi_stop               ; Generate a STOP condition.

    .UNDEF twicommand
    .UNDEF bytecounter

    pop r18
    pop r17
    pop r16
    out SREG, r16

    ret



; f_twi_start                                                         20May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a TWI START condition. Waits for TWINT to be set and then
;     returns the TWSR status bits in r_result.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - r16
; Named Registers (global):
;     Preserved - 
;     Changed   - r_result
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_START
; Functions Called:
;     f_twint_wait - Waits for TWINT, returns TWSR status bits in r_result.
; Returns:
;     r_result - TWSR status bits.
f_twi_start:
    ldi   r16, TWCR_START         ; TWCR: generate start condition.
    sts   TWCR, r16
    rcall f_twint_wait            ; Wait for TWINT.
    ret


; f_twi_slawr                                                         20May2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits a TWI SLA+R/W.
;     Waits for the TWINT flag to be set and then returns the TWSR status
;     bits in r_result.
; Parameters:
;     SLA+R/W - GPIOR0 is expected to contain the SLA+R/W.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - r16
; Named Registers (global):
;     Preserved - 
;     Changed   - r_result
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_GO
; Functions Called:
;     f_twint_wait - Waits for TWINT, returns TWSR status bits in r_result.
; Returns:
;     r_result - TWSR status bits.
f_twi_slawr:
    in    r16,  GPIOR0            ; Load SLA+R/W from GPIOR0
    sts   TWDR, r16               ; into TWDR.
    ldi   r16,  TWCR_GO
    sts   TWCR, r16               ; Start transmission.
    rcall f_twint_wait            ; Wait for TWINT.
    ret


; f_twi_stop                                                          20May2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a TWI STOP condition.
;     Waits for the TWINT flag before returning.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - r16
; Named Registers (global):
;     Preserved - 
;     Changed   - r_result
; I/O Registers Affected:
;     TWCR - TWI Control Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_STOP
; Functions Called:
;     f_twint_wait - Waits for TWINT, then returns TWSR status bits in r19.
; Returns:
;     r_result - TWSR status bits.
f_twi_stop:
    ldi   r16, TWCR_STOP
    sts   TWCR, r16               ; Generate TWI STOP.
    rcall f_twint_wait            ; Wait for TWINT.

    ret


; f_twint_wait                                                        20May2019
; -----------------------------------------------------------------------------
; Description:
;     Waits for the TWINT flag to be set, then returns the TWSR status bits,
;     with the prescaler bits masked out.
; Parameters:
;     None.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - r16
; Named Registers (global):
;     Preserved - 
;     Changed   - r_result
; Constants (Non-Standard):
;     TWSR_PREMASK
; Returns:
;     r_result - TWSR status bits.
f_twint_wait:
    lds  r16, TWCR
    sbrs r16, TWINT
    rjmp f_twint_wait

    lds   r_result, TWSR          ; Read the TWSR.
    andi  r_result, TWSR_PREMASK  ; Mask out prescaler bits.
    ret



#endif


