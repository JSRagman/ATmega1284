;
; ATmega1284Prototype1
;
; main.asm
; Created: 29Jun2019
; Updated: 19Oct2019
;  Author: JSRagman
;
;
; Hardware Configuration:
;     MCU:      ATmega1284P 8-bit Microcontroller with 128K Flash, 16K SRAM, 4K EEPROM
;     RTC:      MCP7940N Battery-Backed I2C Real-Time Clock/Calendar
;     Display:  Two NHD-0420CW Character OLED Display Modules.
;               Note: The final design will have only one display. I'm using two now
;                     because it's convenient for testing.
;
; MCU Connections
;     T0 - 1 kHz clock
;          LTC6992 Voltage-Controlled PWM Clock
;
;     Mechanical Rotary Encoder/Decoder
;          STEP and DIRection inputs on PA0 and PA1.
;
;     Five Illuminated Pushbutton Switches
;          Switch contact inputs on PA2,3,4,5,6
;          Illuminated switch LED outputs on PC2,3,4,5,6
;
;     Display
;         Display !RESET on PC7
;
;     I2C Bus
;         Display
;         Real-Time Clock





; Include File Precedence:
;     1. registers.asm
;     2. constants.asm
;     3. ports.asm
;     4. macros.asm


.include "./MainDefinitions/registers.asm"
.include "./MainDefinitions/constants.asm"
.include "./MainDefinitions/ports.asm"
.include "./Macros/datastackmacros.asm"
.include "./Macros/initmacros.asm"


.include "./DataDefinitions/esegdata.asm"
.include "./DataDefinitions/dsegdata.asm"



.cseg

; Interrupt Table
; -----------------------------------------------------------------------------
.org    0x0000      ; 0x0000  Reset Vector
    rjmp reset
.org    INT0addr    ; 0x0002  External Interrupt 0
.org    INT1addr    ; 0x0004  External Interrupt 1
    rjmp irq_rtc
.org    INT2addr    ; 0x0006  External Interrupt 2
    rjmp irq_button
.org    PCI0addr    ; 0x0008  Pin Change Interrupt 0
    rjmp irq_pci0
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
    rjmp irq_oc0a
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
; -----------------------------------------------------------------------------
; Description:
;     You shouldn't be here. Set an error signal and wait for rescue.
irq_fallout:
;   TODO: Cry for help.

irq_fallout_loop:
    rjmp irq_fallout_loop




; Interrupt Handlers
; -----------------------------------------------------------------------------
.include "irqhandlers.asm"







; reset                                                               19Oct2019
; -----------------------------------------------------------------------------
reset:
;   Initialize Named Registers
    clr    rZero
    clr    rTimer

;   Initialize Status Register
    out    GPIOR0, rZero                    ; clear GPIOR0

;   Initialization Macros
    init_stacks                             ; Init hardware and data stacks
    init_ports                              ; Init Ports
    init_tc0                                ; Init Timer/Counter 0
    init_twi                                ; Init TWI module
    init_extinterrupts                      ; Init External Interrupts

    sei                                     ; Light the fuse


;   Initialize both displays
    rcall  main_ResetDisplays
    brts   reset_error                      ; if (SREG_T == 1)  goto error

;   Show startup text on display 1.
    rcall  main_LoadStartupText             ; Load startup text into SRAM
    ldi    r20,  DISPLAY_ADDR1              ; argument: r20 = Display 1 SLA+W
    rcall  Display_Refresh
    brts   reset_error                      ; if (SREG_T == 1)  goto error

;   Show time and date on display 2
    ldi    r20,    DISPLAY_ADDR2            ; argument: r20 = SLA+W
    rcall  main_ShowTime


reset_success:
    clc                                     ; argument: SREG_C = 0
    ldi    r17, (1<<PSLED4)                  ; argument: PSLED4 = on
    rcall  main_SetLeds                     ; Illuminate Green button (woohoo!)
    rjmp   mainloop

reset_error:                                ; Error Condition
    sec                                     ; argument: SREG_C = 1
    ldi    r17, (1<<PSLED5)                  ; argument: PSLED5 = on
    rcall  main_SetLeds                     ; Illuminate Red button (crap!)


mainloop:
    rjmp mainloop





; Functions
; -----------------------------------------------------------------------------

.include "./TWIFunctions/twifuncs_basic.asm"
.include "./TWIFunctions/twifuncs_write.asm"
.include "./TWIFunctions/twifuncs_read.asm"
.include "./DeviceFunctions/NHD-0420CW_twi.asm"
.include "./DeviceFunctions/MCP7940N.asm"
.include "mainfuncs.asm"
.include "buttonfuncs.asm"


