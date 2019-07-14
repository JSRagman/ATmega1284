;
; mainfunctions.asm
;
; Created: 14Jul2019
; Updated: 14Jul2019
;  Author: JSRagman
;
;
; Description:
;     Functions to be included below the main loop.



 ; delay                                                               12Jul2019
; -----------------------------------------------------------------------------
; Description:
;     Returns after a specified number of milliseconds has elapsed.
; Initial Conditions:
;     A 1 kHz external clock is connected to T0.  This clock is started
;     and stopped using the PORTD T0EN pin.
; Parameters:
;     milliseconds - Data Stack
;         The top byte of the data stack is expected to hold the
;         delay time, in milliseconds.
delay:
    out    TCNT0,  rZero                    ; Set T/C0 count to zero
    clr    rTimer                           ; Set rTimer to zero
    popd   r16                              ; Retrieve milliseconds into r16
    out    OCR0A,  r16                      ; and set OCR0A with it.
    tst    r16                              ; if (milliseconds == zero)
    breq   delay_exit                       ;     exit

    sbi    PORTD,  T0EN                     ; Start the clock
delay_wait:                                 ;
    cp     rTimer, rZero
    breq   delay_wait

delay_exit:
    cbi    PORTD,  T0EN                     ; Stop the clock
    ret



; display_start                                                       14Jul2019
; -----------------------------------------------------------------------------
; Description:
;     Resets the display and shows a startup message.
; Returns:
;     SREG - The T flag indicates whether the operation was successful
;            (cleared) or if an error was encountered (set)
display_start:
    ldi    r25,    high(display_init)       ; Point to display initialization data.
    ldi    r24,     low(display_init)
    rcall  US2066_Reset                     ; Call the display reset function.
    brts   exit_displaystart

    pushdi  DISPLAY_CLEAR                   ; Clear the display
    rcall   US2066_SendCommand
    brts    exit_displaystart

    pushdi CURSOR_OFF                       ; Cursor off
    pushdi DISPLAY_ON                       ; Display on
    rcall  US2066_SetState
    brts   exit_displaystart

    pushdi MAXSENDBYTES                     ; Maximum number of data bytes
    ldi    r25, high(supmessage)            ; high byte of eeprom address
    ldi    r24,  low(supmessage)            ; low byte of eeprom address
    rcall  US2066_WriteFromEepString        ; Transmit

exit_displaystart:

    ret

