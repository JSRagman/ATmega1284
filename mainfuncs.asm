;
; mainfuncs.asm
;
; Created: 14Jul2019
; Updated: 20Sep2019
;  Author: JSRagman
;
;
; Description:
;     Functions to be included below the main loop.

; Function List:
;     main_EnterTime          Manual entry of time and date.
;     main_LoadStartupText    Transfers startup text from EEPROM to SRAM.
;     main_ResetDisplays      Resets and initializes both displays.
;     main_SetLeds            Sets/Clears one or more Port C indicator LEDs
;     main_SetTime            Sets the real-time clock from SRAM data.
;     main_Wait               Returns after a specified number of milliseconds.



; main_EnterTime                                                      20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Enter time and save to SRAM.
; Parameters:
;     None
; Address Labels:
;     sr_rtcset - SRAM destination for time and configuration data
; Returns:
;     nothing
; Notes:
;     The data constants will be replaced by a UI for manual entry.
main_EnterTime:
    push   r16
    push   XL
    push   XH

    ldi    XH,     high(sr_rtcset)          ; Point X to SRAM destination
    ldi    XL,      low(sr_rtcset)

    ldi    r16, RTSEC                       ; r16 = data
    st     X+,     r16                      ; store r16 to SRAM, increment X
    ldi    r16, RTMIN                       ; ...
    st     X+,     r16
    ldi    r16, RTHOUR
    st     X+,     r16
    ldi    r16, RTDAY
    st     X+,     r16
    ldi    r16, RTDATE
    st     X+,     r16
    ldi    r16, RTMONTH
    st     X+,     r16
    ldi    r16, RTYEAR
    st     X+,     r16

    pop    XH
    pop    XL
    pop    r16
    ret


; main_LoadStartupText                                                20Sep2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 20Sep2019
; Description:
;     Startup text - text that is to be displayed when power is applied.
;     Transfers startup text from EEPROM to SRAM, where it will be noticed
;     by the display.
; Parameters:
;     none
; Address Labels:
;     ee_sutext      - EEPROM address of startup text
;     sr_displaytext - SRAM destination address
; Constants (Non-Standard):
;     CHARCOUNT  - The display's character (byte) count.
;                  Address labels ee_sutext and sr_displaytext are expected to
;                  indicate the first byte of CHARCOUNT bytes of text data.
; General-Purpose Registers:
;     Named      - 
;     Parameters - 
;     Modified   - 
; I/O Registers Affected:
;     EEARH:EEARL - EEPROM Address Registers
;     EECR        - EEPROM Control Register
;     EEDR        - EEPROM Data Register
; Returns:
;     nothing
main_LoadStartupText:
    push   r16
    push   r17
    push   r24
    push   r25
    push   XL
    push   XH

   .def    count   = r17                    ; byte count

    ldi    r25,    high(ee_sutext)          ; Point r25:r24 to EEPROM text
    ldi    r24,     low(ee_sutext)
    ldi    XH,     high(sr_displaytext)     ; Point X to SRAM destination
    ldi    XL,      low(sr_displaytext)

    ldi    count,  CHARCOUNT                ; set the byte count
main_LoadStartupText_loop:
    out    EEARH,  r25                      ; Load EEPROM address
    out    EEARL,  r24
    sbi    EECR,   EERE                     ; set EEPROM Read Enable
    in     r16,    EEDR                     ; r16 = EEPROM data
    st     X+,     r16                      ; store r16 to SRAM, increment X
    adiw   r25:r24, 1                       ; increment the EEPROM address.
    dec    count                            ; decrement count
    brne   main_LoadStartupText_loop        ; if (count > 0)  next character

   .undef  count

    pop    XH
    pop    XL
    pop    r25
    pop    r24
    pop    r17
    pop    r16
    ret


; main_ResetDisplays                                                  20Sep2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 20Sep2019
; Description:
;     Resets and initializes both displays.
; Parameters:
;     None
; Address Labels:
;     ee_us2066_initdata - EEPROM: Initialization data. A byte count (n)
;                          followed by n bytes of data.
; General-Purpose Registers:
;     Named      - 
;     Parameters - 
;     Modified   - 
; I/O Registers Affected:
;     DDRC   PCDRESET
; Constants (Non-Standard):
;     DISPLAY_ADDR1 - TWI address for display 1
;     DISPLAY_ADDR2 - TWI address for display 2
;     PCDRESET      - Identifies the Port C pin which is connected to the
;                     display's !RESET line.
; Functions Called:
;     main_Wait         ( milliseconds )
;     TwiDw_FromEepData ( SLA+W, eepAddress )
; Returns:
;     SREG_T - pass (0) or fail (1)
; Note:
;     PCDRESET Pin - Normally configured as an input, with internal pullup
;                    disabled (level = low).
;                    Switching pin direction to Output pulls the !RESET
;                    line low to reset the display.
main_ResetDisplays:
    push   r21
    push   r24
    push   r25

    ldi    r21,    100                      ; argument: delay time = 100 milliseconds
    sbi    DDRC,   PCDRESET                 ; Display !RESET = low
    rcall  main_Wait                        ; wait
    cbi    DDRC,   PCDRESET                 ; Display !RESET = high
    rcall  main_Wait                        ; wait

    ldi    r25,    high(ee_us2066_initdata) ; Point r25:r24 to init data
    ldi    r24,     low(ee_us2066_initdata)

    ldi    r20,  DISPLAY_ADDR1              ; argument: r20 = Display 1 SLA+W
    rcall  TwiDw_FromEepData                ; TwiDw_FromEepData(SLA+W, eepAddress)
    ldi    r20,  DISPLAY_ADDR2              ; argument: r20 = Display 2 SLA+W
    rcall  TwiDw_FromEepData                ; TwiDw_FromEepData(SLA+W, eepAddress)

    pop    r25
    pop    r24
    pop    r21
    ret


; main_SetLeds                                                        20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Sets/Clears one or more Port C indicator LEDs
; Initial Conditions:
;     Port C is used to control local LED indicators.
; Parameters:
;     r17  - leds: specifies the LED(s) to be turned on by a 1 in the
;            appropriate column(s).
;            (1<<PLED2)|(1<<PLED3)|(1<<PLED4)|(1<<PLED5)|(1<<PLED6)
;     SREG - The Carry flag (SREG_C) indicates whether the specified LED is to
;            be lit in addition to LEDs which are already on (SREG_C = 1) or if
;            all other LEDs are to be turned off (SREG_C = 0).
; General-Purpose Registers:
;     Parameters - r17
;     Modified   - 
; I/O Registers Affected:
;     PORTC
; Constants (Non-Standard):
;     LEDMASK    - Used to prevent altering Port C pins that are not
;                  associated with LED control.
main_SetLeds:
    push   r16
    push   r17

   .def    leds = r17                       ; parameter: LEDs

    clr    r16                              ; r16 = 0
    brcc   main_SetLeds_set                 ; if (SREG_C == 0)
                                            ;     goto  main_SetLeds_ons
    in    r16, PINC                         ; r16 = current LED states.

main_SetLeds_set:
    or     r16,    leds
    andi   r16,    LEDMASK                  ; ensure only LED pins are affected
    out    PORTC,  r16

   .undef  leds

    pop    r17
    pop    r16
    ret


; main_SetTime                                                        20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Sets the real-time clock from SRAM data.
; Parameters:
;     None
; General-Purpose Registers:
;     Parameters - 
;     Constants  - 
;     Modified   - 
; Constants (Non-Standard):
;     PLEDYEL1   - First yellow pushbutton LED
;     PLEDYEL2   - Second yellow pushbutton LED
;     PLEDRED    - Red pushbutton LED
; Functions Called:
;     main_SetLeds(r17, SREG_C)
;     RTC_SetTime(X)
; Returns:
;     SREG_T - pass (0) or fail (1)
main_SetTime:
    push   r17
    push   XL
    push   XH


    rcall main_EnterTime

    ldi    r17, (1<<PLEDYEL1)               ; argument: PLEDYEL1 = on
    clc                                     ; argument: SREG_C   = 0
    rcall  main_SetLeds                     ; main_SetLeds(r17, SREG_C)

    ldi    XH,     high(sr_rtcset)          ; Point X to SRAM time data source
    ldi    XL,      low(sr_rtcset)
    rcall  RTC_SetTime                      ; RTC_SetTime(X)
    brts   main_SetTime_error               ; if (SREG_T == 1)  goto error

    ldi    r17, (1<<PLEDYEL2)               ; argument: PLEDYEL2 = on
    rjmp   main_SetTime_exit

main_SetTime_error:
    ldi    r17, (1<<PLEDRED)                ; argument: PLEDRED = on

main_SetTime_exit:
    sec                                     ; argument: SREG_C   = 1
    rcall  main_SetLeds                     ; main_SetLeds(r17, SREG_C)

    pop    XH
    pop    XL
    pop    r17
    ret


; main_ShowTime                                                       20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Displays the current time and date.
; Parameters:
;     None
; General-Purpose Registers:
;     Parameters - 
;     Constants  - 
;     Modified   - 
; Functions Called:
;     RTC_GetTime(X)
; Notes:
;     Z+0 = rtcsec
;     Z+1 = rtcmin
;     Z+2 = rtchour
;     Z+3 = rtcwkday
;     Z+4 = rtcdate
;     Z+5 = rtcmonth
;     Z+6 = rtcyear
main_ShowTime:
    push   r16
    push   r17
    push   r18
    push   r19
    push   r23

   .def    cnvrt = r23                      ; convert digit to ascii

    ldi    r17, (1<<PLEDYEL1)               ; argument: PLEDYEL1 = on
    clc                                     ; argument: SREG_C   = 0
    rcall  main_SetLeds                     ; main_SetLeds(r17, SREG_C)

;   Get time data frome real-time clock
    ldi    XH,     high(sr_realtime)        ; Point X to SRAM time data
    ldi    XL,      low(sr_realtime)
    rcall  RTC_GetTime                      ; RTC_GetTime(X)
;    brts   main_ShowTime_error              ; if (SREG_T == 1)  goto error

;   Prepare for time-to-text conversion
    ldi    cnvrt,  DIGIT_ASC                ; digit + 0x30 = ascii

    ldi    ZH,     high(sr_realtime)        ; Point Z to time data source
    ldi    ZL,      low(sr_realtime)
    ldi    XH,     high(sr_rtimetext)       ; Point X to destination for time
    ldi    XL,      low(sr_rtimetext)       ; data converted to ascii text


;   Month
    ldd    r16,    Z+5                      ; r16 = Month
    ldi    r17,    0x30                     ; r17 (month tens digit) = 0
    sbrc   r16,    4                        ; if (r16[4] == 1)
    ldi    r17,    0x31                     ;     r17 (month tens digit) = 1

;    ldd    r16,    Z+5                      ; r16 = Month
;    mov    r17,    r16                      ; r17 = Month
;    swap   r17                              ; swap r17 high and low nybbles
;    andi   r17,    0x01                     ; zero all but bit 0 of r17
                                            ; now r17 = the tens digit of month (0 or 1)
;    add    r17,    cnvrt                    ; r17 = r17 + 48 (digit to ascii)
    st     X+,     r17                      ; store the month tens digit

    andi   r16,    0x0F                     ; zero r16 high nybble
    add    r16,    cnvrt                    ; r16 = r16 + 48 (digit to ascii)
    st     X+,     r16                      ; store the month ones digit
    ldi    r16,    ASC_FSLASH               ; r16 = ASCII forward slash
    st     X+,     r16                      ; insert a forward slash

;   Date (day of month)
    ldd    r16, Z+4                         ; r16 = Date
    mov    r17, r16                         ; r17 = Date
    swap   r17                              ; swap r17 high and low nybbles
    andi   r17, 0x03                        ; mask all but bits 0 and 1 of r17
                                            ; now r17 = the tens digit of date (0, 1, 2, or 3)
    add    r17, cnvrt                       ; r17 = r17 + 48 (digit to ascii)
    st     X+,  r17                         ; store the date tens digit, X=X+1
    andi   r16, 0x0F                        ; zero r16 high nybble
    add    r16, cnvrt                       ; r16 = r16 + 48 (digit to ascii)
    st     X+,  r16                         ; store the date ones digit
    ldi    r16,    ASC_FSLASH               ; r16 = ASCII forward slash
    st     X+,     r16                      ; insert a forward slash

;   Year
    ldd    r16,    Z+6                      ; r16 = Year (2-digit)
    mov    r17,    r16                      ; r17 = Year
    swap   r17                              ; swap r17 high and low nybbles
    andi   r17,    0x0F                     ; zero the high nybble of r17
                                            ; now r17 = the tens digit of year
    add    r17,    cnvrt                    ; r17 = r17 + 48 (digit to ascii)
    st     X+,     r17                      ; store the year tens digit

    andi   r16,    0x0F                     ; zero r16 high nybble
    add    r16,    cnvrt                    ; r16 = r16 + 48 (digit to ascii)
    st     X+,     r16                      ; store the year ones digit

;   Date - Time separator
    ldi    r16,    ASC_SPACE                ; r16 = ASCII space
    ldi    r17,    ASC_DASH                 ; r17 = ASCII dash
    st     X+,     r16                      ; insert a space
    st     X+,     r17                      ; insert a dash
    st     X+,     r16                      ; insert a space

;   Time - Hours
    ldd    r16,    Z+2                      ; r16 = Hour
    mov    r17,    r16                      ; r17 = Hour
    swap   r17                              ; swap r17 high and low nybbles
    andi   r17,    0x03                     ; mask all but bits 0 and 1 of r17
                                            ; now r17 = the tens digit of hour (0, 1, or 2)
    add    r17,    cnvrt                    ; r17 = r17 + 48 (digit to ascii)
    st     X+,     r17                      ; store the hour tens digit

    andi   r16,    0x0F                     ; mask r16 high nybble
    add    r16,    cnvrt                    ; r16 = r16 + 48 (digit to ascii)
    st     X+,     r16                      ; store the hour ones digit

;   Hours:Minutes separator
    ldi    r16,    ASC_COLON                ; r16 = ASCII colon
    st     X+,     r16

;   Time - Minutes
    ldd    r16,    Z+1                      ; r16 = Minutes
    mov    r17,    r16                      ; r17 = Minutes
    swap   r17                              ; swap r17 high and low nybbles
    andi   r17,    0x07                     ; mask all but bits 0, 1, and 2 of r17
                                            ; now r17 = the tens digit of minutes (0 thru 5)
    add    r17,    cnvrt                    ; r17 = r17 + 48 (digit to ascii)
    st     X+,     r17                      ; store the minutes tens digit

    andi   r16,    0x0F                     ; mask r16 high nybble
    add    r16,    cnvrt                    ; r16 = r16 + 48 (digit to ascii)
    st     X+,     r16                      ; store the minutes ones digit


    ldi    r20,    DISPLAY_ADDR2            ; argument: r20 = SLA+W

;   Clear the display
    ldi    r18,    DISPLAY_CLEAR            ; argument: command = DISPLAY_CLEAR
    rcall  Display_SendCommand              ; Display_SendCommand(command, SLA+W)
    brts   main_ShowTime_error              ; if (SREG_T == 1)  goto error

;   Send text to display
    ldi    XH,     high(sr_rtimetext)       ; argument: Point X to time text
    ldi    XL,      low(sr_rtimetext)
    ldi    r18,    16                        ; argument: byte count = 20
    rcall  Display_SendData                 ; Display_SendData(bytecount, SLA+W, X)
    brtc   main_ShowTime_exit               ; if (SREG_T == 0)  goto exit

main_ShowTime_error:
    ldi    r17, (1<<PLEDRED)                ; argument: PLEDRED = on

main_ShowTime_exit:

   .undef  cnvrt

    pop    r23
    pop    r19
    pop    r18
    pop    r17
    pop    r16
    ret



; main_Wait                                                           11Aug2019
; -----------------------------------------------------------------------------
; Description:
;     Returns after a specified number of milliseconds has elapsed.
; Initial Conditions:
;     - T/C0 is stopped.
;     - T0 is driven by a 1 kHz external clock.
;     - The global interrupt enable bit (SREG_I) must be set.
;     - T/C0 Compare Match A interrupt is configured to increment the
;       rTimer register each time it is called.
; Parameters:
;     r21 - delay time, in milliseconds
; General-Purpose Registers:
;     Named      - rTimer, rZero
;     Parameters - r21
;     Modified   - rTimer
; I/O Registers Affected:
;     OCR0A
;     TCCR0B
;     TCNT0
;     TIMSK0
; Constants (Non-Standard):
;     TC0_CMPA
;     TC0_CS_STOP
;     TC0CS_T0_F
main_Wait:
    push   r16

   .def    dtime = r21                      ; parameter: delay time, milliseconds

    out    TCNT0,    rZero                  ; TCNT0  = 0
    clr    rTimer                           ; rTimer = 0
    out    OCR0A,    dtime                  ; OCR0A  = dtime
    ldi    r16,      TC0_CMPA               ; Enable output compare A interrupt
    sts    TIMSK0,   r16
    ldi    r16,      TC0CS_T0_F             ; Clock source = T0 (external)
    out    TCCR0B,   r16                    ; Start T/C0
main_Wait_loop:                             ; Wait
    cp     rTimer, rZero                    ; if (rTimer == 0)
    breq   main_Wait_loop                   ;     keep waiting

main_Wait_exit:                             ; wait over
    ldi    r16,      TC0_CS_STOP             ; Clock source = stopped
    out    TCCR0B,   r16
    sts    TIMSK0,   rZero                  ; Disable output compare A interrupt

   .undef  dtime
    pop    r16
    ret


; main_TimeOut                                                        21Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Returns after a specified time delay.
; Initial Conditions:
;     - T/C0 is stopped.
;     - T0 is driven by a 1 kHz external clock.
;     - The global interrupt enable bit (SREG_I) must be set.
;     - T/C0 Compare Match A interrupt is configured to increment the
;       rTimer register each time it is called.
; Parameters:
;     r21 - delay time, in milliseconds (1 to 255)
;     r22 - delay time multiplier
; General-Purpose Registers:
;     Named      - rTimer
;     Parameters - r21, r22
;     Modified   - rTimer
main_TimeOut:

   .def    dtime = r21                      ; parameter: delay time, milliseconds
   .def    dmult = r22

    out    TCNT0,    rZero                  ; TCNT0  = 0
    clr    rTimer                           ; rTimer = 0
    out    OCR0A,    dtime                  ; OCR0A  = dtime
    ldi    r16,      TC0_CMPA               ; Enable output compare A interrupt
    sts    TIMSK0,   r16
    ldi    r16,      TC0CS_T0_F             ; Clock source = T0 (external)
    out    TCCR0B,   r16                    ; Start T/C0
main_Wait_loop:                             ; Wait
    cp     rTimer, rZero                    ; if (rTimer == 0)
    breq   main_Wait_loop                   ;     keep waiting

    ret
