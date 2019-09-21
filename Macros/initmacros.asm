;
; ATmega1284Prototype1
;
; initmacros.asm
; Created: 29Jun2019
; Updated: 19Sep2019
;  Author: JSRagman
;
; Description:
;     Initialization macros.

#ifndef _init_macros
#define _init_macros



; init_extinterrupts                                                  17Sep2019
; -----------------------------------------------------------------------------
; Function:
;     Configure external interrupts.
;
;     INT1 (PD3) - Real-time clock multifunction pin
;     INT2 (PB2) - Rotary encoder QSTEP signal
; General-Purpose Registers:
;     Modified    - r16
; I/O Registers:
;     (0x69) EICRA   External Interrupt Control Register A
;     (0x1D) EIMSK   External Interrupt Mask Register
;     (0x68) PCICR                     Pin-change interrupt banks
;     (0x6B) PCMSK0  PCINT7:0          Individual pins - PORT A
.macro init_extinterrupts
    ldi    r16,    (1<<ISC21)|(1<<ISC11)    ; INT2, INT1 sense = falling-edge
    sts    EICRA,  r16
    ldi    r16,    (1<<INT2)|(1<<INT1)      ; Enable INT2, INT1
    out    EIMSK,  r16

    ldi    r16,    (1<<PCIE0)               ; Enable Port A pin-change bank
    sts    PCICR,  r16
    ldi    r16,    0xFF                     ; Enable PA7:PA0 pin-change
    sts    PCMSK0, r16
.endmacro



; init_ports                                                          19Sep2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes I/O ports A, B, C, and D.
; General-Purpose Registers:
;     Constants  - 
;     Modified   - r16
; I/O Registers Affected:
;     DDRA, DDRB, DDRC, DDRD
;     PORTA, PORTB, PORTC, PORTD
.macro init_ports
    out    DDRA,    rZero                   ; Port A - all inputs
    ldi    r16,     (1<<PA0)|(1<<PA1)|(1<<PA6)|(1<<PA7)
    out    PORTA,   r16

    out    DDRB,    rZero                   ; Port B - all inputs
    ldi    r16,    (1<<PB1)|(1<<PB2)|(1<<PB3)|(1<<PB4)
    out    PORTB,   r16

    out    PORTC,   rZero                   ; Port C - PC6:PC2 outputs
    ldi    r16,    (1<<DDC2)|(1<<DDC3)|(1<<DDC4)|(1<<DDC5)|(1<<DDC6)
    out    DDRC,    r16

    out    DDRD,    rZero                   ; Port D - all inputs
    ldi    r16,     0x7F                    ;        - PD6:PD0 pullups
    out    PORTD,   r16                     ;        - PD7 has a wired pullup
.endmacro


; init_stacks                                                         17Sep2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes the hardware and data stacks.
; Parameters:
;     None.
; General-Purpose Registers:
;     Modified   - r16, r17, Y
; I/O Registers Affected:
;     SPH:SPL
; Constants (Non-Standard):
;     HSTACK_MAXSIZE
.macro init_stacks
;   Hardware Stack
    ldi  r16,  low(RAMEND)
    ldi  r17,  high(RAMEND)
    out  SPH,  r17
    out  SPL,  r16

;   Data Stack
    ldi  YH,   high(RAMEND-HSTACK_MAXSIZE+1)
    ldi  YL,    low(RAMEND-HSTACK_MAXSIZE+1)
.endmacro



; init_tc0                                                            11Aug2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes Timer/Counter 0.
;     Mode = CTC, Clock = No clock source (stopped).
;
;     T/C0 is used by the main_Wait function to while away milliseconds.
; Parameters:
;     None.
; General-Purpose Registers:
;     Named      - 
;     Parameters - 
;     Modified   - r16
; I/O Registers Affected:
;     TCCR0A, TCCR0B
;     TCNT0
;     TIMSK0
; Constants (Non-Standard):
;     TC0_CS_STOP
;     TC0_WGM_CTC
.macro init_tc0
    ldi    r16,      TC0_WGM_CTC            ; Mode = CTC
    out    TCCR0A,   r16
    ldi    r16,      TC0_CS_STOP            ; Clock source = stopped
    out    TCCR0B,   r16
.endmacro


; init_twi                                                            28Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes the TWI module.
; Parameters:
;     None.
; General-Purpose Registers:
;     Constants  - rZero
;     Modified   - r16
; I/O Registers Affected:
;     TWBR
;     TWSR
.macro init_twi
    sts    TWSR,   rZero                    ; Zero the TWSR prescaler bits
    ldi    r16,    TWBR_400KHz              ; Set the TWBR value for 400 kHz SCL
    sts    TWBR,   r16
.endmacro


#endif

