;
; Project: ATmega1284Prototype1
;
; File:    interrupts.asm
; Created: 29Jun2019
; Updated: 29Jun2019
; Author : JSRagman
;
; Description:
;     Interrupt handlers.




; pcint0_handler             Pin-Change Interrupt 0                   14Jul2019
; -----------------------------------------------------------------------------
; Triggered By:
;     Pin-change from PA2, PA3, or PA4 (pushbutton S2, S3, or S4).
;     The pushbutton inputs latch and must be reset prior to returning.
; Function:
;     Responds to local pushbutton input.
pci0_handler:
    push   r16
    in     r16, SREG
    push   r16

    in     r16,    PINA
    sts    PCICR,  rZero               ; Disable pin-change interrupts
    sei                                ; Enable global interrupts

pci0_greenbutton:
    sbrs   r16,    PINSW2
    rjmp   pci0_yellowbutton
    rcall  greenbutton_push
    rjmp   pci0_exit

pci0_yellowbutton:
    sbrs   r16,    PINSW3
    rjmp   pci0_redbutton
    rcall  yellowbutton_push
    rjmp   pci0_exit
    
pci0_redbutton:
    sbrs   r16,    PINSW4
    rjmp   pci0_exit
    rcall  redbutton_push

pci0_exit:
    cbi    PORTD,  SCLR                ; Reset the latched button inputs
    m_delay 10
    sbi    PORTD,  SCLR
    m_delay 10

    ldi    r16,    (1<<PCIF0)          ; Ensure pin-change flag is cleared
    out    PCIFR,  r16
    ldi    r16,    (1 << PCIE0)        ; Enable pin-change interrupts
    sts    PCICR,  r16

    pop    r16
    out    SREG, r16
    pop    r16
    reti



; oc0a_handler          Timer/Counter 0 Output Compare Match A        14Jul2019
; -----------------------------------------------------------------------------
; Triggered By:
;     Timer/Counter 0 Output Compare Match A
; Function:
;     Increments the rTimer register.
oc0a_handler:
    push   r16
    in     r16, SREG
    push   r16

    inc    rTimer

    pop    r16
    out    SREG, r16
    pop    r16
    reti



