;
; Project: ATmega1284Prototype1
;
; File:    interrupts.asm
; Created: 29Jun2019
; Updated: 17Sep2019
; Author:  JSRagman
;
; Description:
;     Interrupt handlers.



; irq_rtc              External Interrupt 1                           17Sep2019
; -----------------------------------------------------------------------------
; Triggered By:
;     INT1 (PD3) - falling-edge, real-time clock MFP signal.
; Function:
;     
irq_rtc:


   reti


; irq_rotary           External Interrupt 2                           17Sep2019
; -----------------------------------------------------------------------------
; Triggered By:
;     INT2 (PB2) - falling-edge, rotary-encoder QSTEP signal
; Function:
;     
irq_rotary:


   reti


; irq_pci0             Pin-Change Interrupt 0                         17Sep2019
; -----------------------------------------------------------------------------
; Triggered By:
;     Port A pin-change.
;     Pushbuttons are numbered 0 through 7.
; Function:
;     Retrieves Port A state and then disables further Port A pin-change
;     interrupts.
;
;     Determines which button has been pushed and then takes the
;     appropriate action.
irq_pci0:
    push   r16
    in     r16, SREG
    push   r16
    push   r17
    push   r21

;   Retrieve button state into r16
    in     r16,    PINA                     ; r16 = PINA

;   Disable pin-change interrupt 0
    lds    r17,    PCICR                    ; r17         = PCICR
    cbr    r17,    (1<<PCIE0)               ; r17[PCIE0]  = 0
    sts    PCICR,  r17                      ; PCICR       = r17

    sei                                     ; enable interrupts

irq_pci0_pa2:                               ; Button 2 (yellow 1)
    sbrs   r16,    PSW2
    rjmp   irq_pci0_pa3
    rcall  button2
    rjmp   irq_pci0_exit

irq_pci0_pa3:                               ; Button 3 (yellow 2)
    sbrs   r16,    PSW3
    rjmp   irq_pci0_pa4
    rcall  button3
    rjmp   irq_pci0_exit
    
irq_pci0_pa4:                               ; Button 4 (green)
    sbrs   r16,    PSW4
    rjmp   irq_pci0_pa5
    rcall  button4
    rjmp   irq_pci0_exit
    
irq_pci0_pa5:                               ; Button 5 (red)
    sbrs   r16,    PSW5
    rjmp   irq_pci0_pa6
    rcall  button5
    rjmp   irq_pci0_exit
    
irq_pci0_pa6:                               ; Button 6
    sbrs   r16,    PSW6
    rjmp   irq_pci0_pa7
;    rcall  button6
    rjmp   irq_pci0_exit
    
irq_pci0_pa7:                               ; Button 7
    sbrs   r16,    PSW7
    rjmp   irq_pci0_exit
;    rcall  button7

irq_pci0_exit:

;   Reset all latched buttons
    ldi    r21,    100                      ; argument: delay time = 100 milliseconds
    sbi    DDRD,   BSWCLR                   ; !SCLR = 0
    rcall  main_Wait                        ; wait
    cbi    DDRD,   BSWCLR                   ; !SCLR = 1

    ldi    r16,    (1<<PCIF0)               ; Ensure the pin-change flag is cleared
    out    PCIFR,  r16
    lds    r17,    PCICR                    ; Enable pin-change interrupt 0
    sbr    r17,    (1<<PCIE0)
    sts    PCICR,  r17

    pop    r21
    pop    r17
    pop    r16
    out    SREG, r16
    pop    r16
    reti



; irq_oc0a          Timer/Counter 0 Output Compare Match A            14Jul2019
; -----------------------------------------------------------------------------
; Triggered By:
;     Timer/Counter 0 Output Compare Match A
; Description:
;     Increments the rTimer register.
irq_oc0a:
    push   r16
    in     r16, SREG
    push   r16

    inc    rTimer

    pop    r16
    out    SREG, r16
    pop    r16
    reti



