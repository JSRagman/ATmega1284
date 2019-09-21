;
; twifuncs_basic.asm
;
; Created: 25May2019
; Updated: 21Sep2019
;  Author: JSRagman
;
;
; Description:
;     Basic TWI functions for the ATmega1284/1284P.
;
; Depends On:
;     1.  m1284pdef.inc
;     2.  constants.asm
;
; Reference:
;     1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
; Function List:
;     Twi_Connect       Combines Twi_Start and Twi_Slarw
;     Twi_Slarw         Transmits SLA+R/W and validates the response.
;     Twi_Start         Generates a TWI START condition.
;     Twi_Stop          Generates a STOP condition.
;     Twi_Wait          Waits for TWINT, returns TWSR status bits.
;
;
; TWI I/O Registers:
;     TWBR  - (0xB8) TWI Bit Rate Register
;     TWCR  - (0xBC) TWI Control Register
;                    Bit 7: TWINT    TWI Interrupt Flag
;                    Bit 6: TWEA     TWI Enable Ack
;                    Bit 5: TWSTA    TWI START Condition
;                    Bit 4: TWSTO    TWI STOP Condition
;                    Bit 3: TWWC     TWI Write Collision Flag
;                    Bit 2: TWEN     TWI Enable
;                    Bit 1:  -       Reserved
;                    Bit 0: TWIE     TWI Interrupt Enable
;     TWDR  - (0xBB) TWI Data Register
;     TWSR  - (0xB9) TWI Status Register
;                    Bits 7:3:  TWS7:TWS3    TWI Status Code
;                    Bit  2:                 Reserved
;                    Bits 1:0   TWPS1:TWPS0  TWI Prescaler Bits
;     TWAR  - (0xBA) TWI (Slave) Address Register
;     TWAMR - (0xBD) TWI (Slave) Address Mask Register
;
;
; Notes:
;      1. SLA+R/W refers to a device TWI Address plus the Read/Write bit.
;         Bit 0 of SLA+R/W is the R/W bit. The other 7 bits constitute the
;         address.
;      2. The Twi_Connect(r20) function is the equivalent of calling
;         Twi_Start(), immediately followed by Twi_Slarw(r20).


; Twi_Connect                                                          4Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a TWI START condition, transmits SLA+R/W, and validates
;     the response.
; Parameters:
;     r20 - SLA+R/W for the targeted TWI device
; General-Purpose Registers:
;     Parameters - r20
;     Constants  - 
;     Modified   - 
; I/O Registers Affected:
;     SREG - The T flag is returned to indicate success (0) or failure (1)
; Constants (Non-Standard):
;     TWSR_SLAW_ACK (0x18) - SLA+W transmitted, ACK received
;     TWSR_SLAR_ACK (0x40) - SLA+R transmitted, ACK received
; Functions Called:
;     Twi_Start()
;     Twi_Send(r18, r21)
; Returns:
;     SREG_T - pass (0) or fail (1)
Twi_Connect:
    push   r18
    push   r21

   .def    expected = r18
   .def    slarw    = r20                   ; parameter: SLA+R/W

;   Transmit START condition
    rcall  Twi_Start                        ; SREG_T = Twi_Start()
    brts   Twi_Connect_exit                 ; if (SREG_T == 1)  goto exit

;   Transmit SLA+R/W
    ldi    expected,  TWSR_SLAW_ACK         ; r18 = SLAW_ACK
    sbrc   slarw,     0                     ; if (R/W bit == Read)
    ldi    expected,  TWSR_SLAR_ACK         ;     r18 = SLAR_ACK
    mov    r21,       slarw                 ; r21 = slarw
    rcall  Twi_Send                         ; SREG_T = Twi_Send(r18, r21)

Twi_Connect_exit:
   .undef  expected
   .undef  slarw

    pop    r21
    pop    r18
    ret


; Twi_Send                                                             4Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits one byte.
; Initial Conditions:
;     A TWI session is in progress with a slave device.
; Parameters:
;     r18 - expected TWSR status code
;     r21 - data byte (or SLA+R/W)
; General-Purpose Registers:
;     Parameters - r18, r21
;     Constants  - 
;     Modified   - 
; I/O Registers Affected:
;     SREG - The T flag is returned to indicate success (0) or failure (1)
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWSR_PREMASK  (0b_1111_1000)  -   Masks out TWSR prescaler bits.
; Returns:
;     SREG_T - pass (0) or fail (1)
Twi_Send:
    push   r16
    push   r19

   .def    expected = r18
   .def    result   = r19
   .def    datbyt   = r21

    sts    TWDR,   datbyt                   ; TWDR = data byte
    ldi    r16,    (1<<TWINT)|(1<<TWEN)     ; TWCR = clear TWINT, set TWEN
    sts    TWCR,   r16
    rcall  Twi_Wait                         ; result = Twi_Wait()
    cp     result, expected                 ; if (result == expected)
    breq   Twi_Send_exit                    ;     goto exit
                                            ; else
    set                                     ;     error: SREG_T = 1
                                            ;     fall into exit
Twi_Send_exit:
   .undef  expected
   .undef  result
   .undef  datbyt

    pop    r19
    pop    r16
    ret


; Twi_Slarw                                                            4Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Transmits SLA+R/W and validates the response.
; Parameters:
;     r20 - SLA+R/W for the targeted TWI device
; General-Purpose Registers:
;     Parameters - r20
;     Constants  - 
;     Modified   - 
; Constants (Non-Standard):
;     TWSR_SLAW_ACK (0x18) - SLA+W transmitted, ACK received
;     TWSR_SLAR_ACK (0x40) - SLA+R transmitted, ACK received
; I/O Registers Affected:
;     SREG - The T flag is returned to indicate success (0) or failure (1)
;     TWCR - TWI Control Register
;     TWDR - TWI Data Register
; Functions Called:
;     Twi_Wait()
;     Twi_Send(r18, r21)
; Returns:
;     SREG_T - pass (0) or fail (1)
Twi_Slarw:
    push   r18
    push   r19
    push   r21

   .def    expected = r18                   ; expected TWSR status
   .def    result   = r19                   ; r19 returned from Twi_Wait()
   .def    slarw    = r20                   ; parameter: SLA+R/W

    ldi    expected,  TWSR_SLAW_ACK         ; r18 = SLAW_ACK
    sbrc   slarw,     0                     ; if (R/W bit == Read)
    ldi    expected,  TWSR_SLAR_ACK         ;     r18 = SLAR_ACK
    mov    r21,       slarw                 ; r21 = slarw
    rcall  Twi_Send                         ; SREG_T = Twi_Send(r18, r21)

Twi_Slarw_exit:

   .undef  expected
   .undef  result
   .undef  slarw

    pop    r21
    pop    r19
    pop    r18
    ret


; Twi_Start                                                            3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a START condition.
; Parameters:
;     None.
; General-Purpose Registers:
;     Parameters - 
;     Constants  - 
;     Modified   - 
; I/O Registers Affected:
;     SREG - The T flag is returned to indicate success (0) or failure (1)
;     TWCR - TWI Control Register
;     TWSR - TWI Status Register
; Constants (Non-Standard):
;     TWCR_START    (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
;     TWSR_STA      (0x08) - A start condition has been transmitted
;     TWSR_RST      (0x10) - A repeated start condition has been transmitted
; Functions Called:
;     Twi_Wait()
; Returns:
;     SREG_T - pass (0) or fail (1)
Twi_Start:
    push   r19

    clt                                     ; SREG_T = 0
    ldi    r19,    TWCR_START               ; TWCR = clear TWINT, set TWEN, set TWSTA
    sts    TWCR,   r19
    rcall  Twi_Wait                         ; r19 = Twi_Wait()
    cpi    r19,    TWSR_STA                 ; if (r19 == TWSR_STA)
    breq   Twi_Start_exit                   ;     goto exit
    cpi    r19,    TWSR_RST                 ; if (r19 == TWSR_RST)
    breq   Twi_Start_exit                   ;     exit
                                            ; else
    set                                     ;     error: SREG_T = 1
Twi_Start_exit:

    pop    r19
    ret


; Twi_Stop                                                             3Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Generates a STOP condition.
; Parameters:
;     None.
; General-Purpose Registers:
;     Parameters - 
;     Constants  - 
;     Modified   - 
; I/O Registers Affected:
;     TWCR - TWI Control Register
; Constants (Non-Standard):
;     TWCR_STOP    (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)
; Returns:
;     Nothing
Twi_Stop:
    push  r16

    ldi   r16,     TWCR_STOP                ; TWCR = clear TWINT, set TWEN, set TWSTO
    sts   TWCR,    r16

    pop   r16
    ret


; Twi_Wait                                                            21Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Waits for the TWINT flag to be set, then returns the TWSR status bits
;     with the prescaler bits masked out.
; Parameters:
;     None.
; General-Purpose Registers:
;     Parameters - 
;     Constants  - 
;     Modified   - r19
; Constants (Non-Standard):
;     TWSR_PREMASK  (0b_1111_1000)  -   Masks out TWSR prescaler bits.
; Returns:
;     r19 - TWSR status bits.
Twi_Wait:
    lds    r19,    TWCR                     ; r19 = TWCR
    sbrs   r19,    TWINT                    ; if (TWINT == 0)
    rjmp   Twi_Wait                         ;     continue waiting

    lds    r19,    TWSR                     ; r19 = TWSR
    andi   r19,    TWSR_PREMASK             ; mask out prescaler bits
    ret

