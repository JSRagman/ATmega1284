; atm1284pmain.asm
;
; Created: 5/12/2019
; Author : JSRagman
;
; Description:
;     Interrupt table and common initializations.

.cseg

; Interrupt Table
; -----------------------------------------------------------------------------
.org    0x0000      ; 0x0000  Reset Vector
    rjmp reset
.org    INT0addr    ; 0x0002  External Interrupt 0
.org    INT1addr    ; 0x0004  External Interrupt 1
.org    INT2addr    ; 0x0006  External Interrupt 2
.org    PCI0addr    ; 0x0008  Pin Change Interrupt 0
.org    PCI1addr    ; 0x000a  Pin Change Interrupt 1
.org    PCI2addr    ; 0x000c  Pin Change Interrupt 2
.org    PCI3addr    ; 0x000e  Pin Change Interrupt 3
.org    WDTaddr     ; 0x0010  Watchdog Time-out Interrupt
.org    OC2Aaddr    ; 0x0012  Timer/Counter2 Compare Match A
.org    OC2Baddr    ; 0x0014  Timer/Counter2 Compare Match B
.org    OVF2addr    ; 0x0016  Timer/Counter2 Overflow
.org    ICP1addr    ; 0x0018  Timer/Counter1 Capture Event
.org    OC1Aaddr    ; 0x001a  Timer/Counter1 Compare Match A
.org    OC1Baddr    ; 0x001c  Timer/Counter1 Compare Match B
.org    OVF1addr    ; 0x001e  Timer/Counter1 Overflow
.org    OC0Aaddr    ; 0x0020  Timer/Counter0 Compare Match A
.org    OC0Baddr    ; 0x0022  Timer/Counter0 Compare Match B
.org    OVF0addr    ; 0x0024  Timer/Counter0 Overflow
.org    SPIaddr     ; 0x0026  SPI Serial Transfer Complete
.org    URXC0addr   ; 0x0028  USART0, Rx Complete
.org    UDRE0addr   ; 0x002a  USART0, Data register Empty
.org    UTXC0addr   ; 0x002c  USART0, Tx Complete
.org    ACIaddr     ; 0x002e  Analog Comparator
.org    ADCCaddr    ; 0x0030  ADC Conversion Complete
.org    ERDYaddr    ; 0x0032  EEPROM Ready
.org    TWIaddr     ; 0x0034  2-wire Serial Interface
    rjmp twi_interrupt
.org    SPMRaddr    ; 0x0036  Store Program Memory Read
.org    URXC1addr   ; 0x0038  USART1, RX complete
.org    UDRE1addr   ; 0x003a  USART1, Data Register Empty
.org    UTXC1addr   ; 0x003c  USART1, TX complete
.org    ICP3addr    ; 0x003e  Timer/Counter3 Capture Event
.org    OC3Aaddr    ; 0x0040  Timer/Counter3 Compare Match A
.org    OC3Baddr    ; 0x0042  Timer/Counter3 Compare Match B
.org    OVF3addr    ; 0x0044  Timer/Counter3 Overflow

; irqtable_fallout
; -----------
; Description:
;     You shouldn't be here. Set an error signal and
;     wait for rescue.
irqtable_fallout:
    ; TODO: Set an error signal.
    irqtable_fallout_loop:
      rjmp irqtable_fallout_loop



; twi_interrupt
; -------------
; Description:
;     TWI Interrupt handler.
; General-Purpose Registers Used:
;     1. Preserved - r16, SREG
;     2. Changed   - 
; Note:
;     Execution of the interrupt handler does not automatically clear
;     the TWI Interrupt flag. You must explicitly write a 1 to the
;     TWCR TWINT flag.
twi_interrupt:
    push  r16
    in    r16, SREG
    push  r16

    ; do something...

    pop r16
    out SREG, r16
    pop r16

    reti


.EQU HSTACK_MAXSIZE = 64

; reset
; -----------------------------------------------------------------------------
; Sequence:
;     1. Initialize the hardware stack.
;     2. Initialize the data stack.
; Note:
;     HSTACK_MAXSIZE is arbitrarily defined above.
reset:
    ldi  r16,  low(RAMEND)                  ; Init. hardware stack.
    ldi  r17,  high(RAMEND)
    out  SPL,  r16
    out  SPH,  r17

    ldi  YH,   high(RAMEND-HSTACK_MAXSIZE+1)  ; Init. data stack
    ldi  YL,    low(RAMEND-HSTACK_MAXSIZE+1)

mainloop:
    rjmp mainloop

