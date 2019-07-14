;
; ATmega1284Prototype1
;
; initmacros.asm
; Created: 29Jun2019
; Author : JSRagman
;
; Description:
;     Initialization macros.

#ifndef _init_macros
#define _init_macros



; init_pcinterrupts                                                   14Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Enable pin-change interrupts for pushbutton switches S2, S3, and S4.
; I/O Registers:
;     (0x68) PCICR                     Pin-change interrupt banks
;     (0x6B) PCMSK0  PCINT7:0          Individual pins - PORT A
.macro init_pcinterrupts
    ldi    r16,    (1 << PCIE0)
    sts    PCICR,  r16
    ldi    r16,    (1<<PCINT2)|(1<<PCINT3)|(1<<PCINT4)
    sts    PCMSK0, r16
.endmacro



; init_ports                                                          14Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes I/O ports A, B, C, and D.
; Port Assignments
;     PORT A
;         PA2 - green   pushbutton switch input
;         PA3 - yellow  pushbutton switch input
;         PA4 - red     pushbutton switch input
;     PORT B
;         PB0 - external clock T0
;         PB5, PB6, PB7 - MOSI, MISO, SCK
;     PORT C
;         PC0, PC1 - SCL, SDA
;         PC2 - green   LED
;         PC3 - yellow  LED
;         PC4 - red     LED
;         PC5 - 
;         PC6 - 
;         PC7 - 
;     PORT D
;         PD0 - T0 enable
;         PD1 - !DRESET (display reset)
;         PD7 - !SCLR
.macro init_ports
;   Port A - All inputs, all internal pullups
    out    DDRA,   rZero
    out    PORTA,  rFF
;   Port B - All inputs, internal pullups on 1,2,3, and 4
    out    DDRB,   rZero
    ldi    r16,    (1<<PB1)|(1<<PB2)|(1<<PB3)|(1<<PB4)
    out    PORTB,  r16
;   Port C - SCL, SDA on 0 and 1
;            LED indicator outputs on 2,3,4,5,6, and 7
    out    PORTC,  rZero
    ldi    r16,    (1<<DDC2)|(1<<DDC3)|(1<<DDC4)|(1<<DDC5)|(1<<DDC6)|(1<<DDC7)
    out    DDRC,   r16
;   Port D - T0 Enable output on 0
;            !DRESET input on 1 - external wired pullup
;            2-6 are inputs with internal pullups
;            7 is the !SCLR output
    ldi    r16,    (1<<DDD0)|(1<<DDD7)
    out    DDRD,   r16
    ldi    r16,    0xFC           ; 0b_1111_1100
    out    PORTD,  r16
.endmacro


; init_stacks                                                         14Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes the hardware and data stacks.
; Parameters:
;     None.
.macro init_stacks
;   Hardware Stack
    ldi  r16,  low(RAMEND)
    ldi  r17,  high(RAMEND)
    out  SPL,  r16
    out  SPH,  r17

;   Data Stack
    ldi  YH,   high(RAMEND-HSTACK_MAXSIZE+1)
    ldi  YL,    low(RAMEND-HSTACK_MAXSIZE+1)
.endmacro



; init_tc0                                                            14Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes Timer/Counter 0
; Parameters:
;     None.
; Notes:
;     1. External clock on T0 is 1 kHz.
.macro init_tc0
    ldi    r16,      TC0_WGM_CTC            ; Mode = CTC
    out    TCCR0A,   r16
    ldi    r16,     (1<<OCIE0A)             ; Enable output compare A interrupt
    sts    TIMSK0,   r16
    ldi    r16,      TC0CS_T0_F             ; Clock = external T0, falling edge
    out    TCCR0B,   r16
.endmacro


; init_twi                                                            14Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Initializes the TWI module.
.macro init_twi
    sts    TWSR,   rZero                    ; Zero the TWSR prescaler bits
    ldi    r16,    TWBR_400KHz              ; Set the TWBR value for 400 kHz SCL
    sts    TWBR,   r16
.endmacro


#endif

