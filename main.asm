;
; ATmega1284Prototype1
;
; main.asm
; Created: 29Jun2019
; Updated: 14Jul2019
; Author : JSRagman
;
;
; Hardware Configuration:
;     MCU:      ATmega1284P
;     Display:  NHD-0420CW
;
;     1 kHz external clock on T0
;

.include "constants.asm"
.include "./Macros/DataStackMacros.asm"
.include "./Macros/macros.asm"
.include "./Macros/initmacros.asm"

.equ DISPLAY_ADDR = 0x7A

; eseg data
; ---------------------
.include "esegdata.asm"

.cseg

; Interrupt Table
; -----------------------------------------------------------------------------
.org    0x0000      ; 0x0000  Reset Vector
    rjmp reset
.org    INT0addr    ; 0x0002  External Interrupt 0
.org    INT1addr    ; 0x0004  External Interrupt 1
.org    INT2addr    ; 0x0006  External Interrupt 2
.org    PCI0addr    ; 0x0008  Pin Change Interrupt 0
    rjmp pci0_handler
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
    rjmp oc0a_handler
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
.org    SPMRaddr    ; 0x0036  Store Program Memory Read
.org    URXC1addr   ; 0x0038  USART1, RX complete
.org    UDRE1addr   ; 0x003a  USART1, Data Register Empty
.org    UTXC1addr   ; 0x003c  USART1, TX complete
.org    ICP3addr    ; 0x003e  Timer/Counter3 Capture Event
.org    OC3Aaddr    ; 0x0040  Timer/Counter3 Compare Match A
.org    OC3Baddr    ; 0x0042  Timer/Counter3 Compare Match B
.org    OVF3addr    ; 0x0044  Timer/Counter3 Overflow


; irq_fallout
; -----------
; Description:
;     You shouldn't be here. Set an error signal and
;     wait for rescue.
irq_fallout:
;   TODO: Set an error signal.

irq_fallout_loop:
    rjmp irq_fallout_loop




; Interrupt Handlers
; -----------------------------------------------------------------------------



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






; reset
; -----------------------------------------------------------------------------
reset:
;   Register Constants
    clr    rZero                            ; rZero = 0
    ldi    r16,    0xFF                     ; rFF   = 0xFF
    mov    rFF,    r16

    init_stacks                           ; Init hardware and data stacks
    init_ports                            ; Init Ports
    init_pcinterrupts                     ; Init Pin-Change Interrupts
    init_tc0                              ; Init Timer/Counter 0
    init_twi                              ; Init TWI module

;   Set the Display TWI Address
    ldi    r16,    DISPLAY_ADDR             ; Place display TWI address in GPIOR0
    out    GPIOR0, r16

    sei                                     ; Light the fuse

;   Initialize the display
    rcall display_start
    brts  error_reset                       ; if (error)  goto error
    m_indicator_set  PLEDGRN                ; Illuminate Green button (woohoo!)
    rjmp mainloop

error_reset:                                ; Error Condition
    m_indicator_set    PLEDRED              ; Illuminate Red button (crap!)

mainloop:
    rjmp mainloop





; Functions
; -----------------------------------------------------------------------------

.include "./TWIFunctions/TwiFuncs_Basic.asm"
.include "./TWIFunctions/TwiFuncs_Write.asm"
.include "./DisplayFunctions/nhd0420cwFuncs_twi.asm"
.include "mainfunctions.asm"


; greenbutton_push                                                    13Jul2019
; -----------------------------------------------------------------------------
; Description:
;     
greenbutton_push:


greenbutton_err:

greenbutton_exit:

    ret



; yellowbutton_push                                                   14Jul2019
; -----------------------------------------------------------------------------
; Description:
;     
yellowbutton_push:


error_yellowbutton:


exit_yellowbutton:

    ret



; redbutton_push                                                      14Jul2019
; -----------------------------------------------------------------------------
; Description:
;     
redbutton_push:


error_redbutton:


exit_redbutton:

    ret



