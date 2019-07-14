;
; Project: ATmega1284Prototype1
;
; File:    macros.asm
; Created:  1Jul2019
; Updated: 14Jul2019
; Author:  JSRagman
; 


; m_delay                                                             12Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Returns after a set time delay
; Parameters:
;     @0 - delay time, in milliseconds
; Usage:
;     m_delay 10
.macro m_delay
    ldi    r16,    @0
    pushd  r16
    rcall  delay
.endmacro


; m_display_reset                                                     12Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Resets the display.
; Parameters:
;     None
; Usage:
;     m_display_reset
.macro m_display_reset
    sbi    DDRD, DRESET
    m_delay 100
    cbi    DDRD, DRESET
    m_delay 100
.endmacro


; m_indicator_set                                                     12Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Illuminates one specified indicator, extinguishing all others.
; Parameters:
;     @0 - PORTC pin number (2 - 7)
; Usage:
;     m_set_indicator PORTLED2
.macro m_indicator_set
    cbi    PORTC,  PLEDGRN
    cbi    PORTC,  PLEDYEL
    cbi    PORTC,  PLEDRED
    sbi    PORTC,  @0
.endmacro


; m_indicator_add                                                     12Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Illuminates a specified indicator.
; Parameters:
;     @0 - PORTC pin number (2 - 7)
; Usage:
;     m_add_indicator PORTLED2
.macro m_indicator_add
    sbi    PORTC,  @0
.endmacro


; m_indicator_clear                                                   12Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Clears a specified indicator.
; Parameters:
;     @0 - PORTC pin number (2 - 7)
; Usage:
;     m_clear_indicator PLEDRED
.macro m_clear_indicator
    cbi    PORTC, @0
.endmacro



; m_start_t0                                                          12Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Starts Timer/Counter 0 by enabling the external clock (T0).
; Parameters:
;     None
; Usage:
;     m_start_t0
.macro m_start_t0
    sbi    PORTD,  T0EN
.endmacro


; m_stop_t0                                                           12Jul2019
; -----------------------------------------------------------------------------
; Function:
;     Stops Timer/Counter 0 by disabling the external clock (T0).
; Parameters:
;     None
; Usage:
;     m_stop_t0
.macro m_stop_t0
    cbi    PORTD,  T0EN
.endmacro

