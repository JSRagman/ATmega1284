;
; ButtonFuncs.asm
;
; Created: 19Jul2019
; Updated: 20Sep2019
; Author : JSRagman
;
; Description:
;     Functions that are called in response to a button push.
;     These functions are called from an interrupt handler. Care should
;     be taken to preserve any registers that may be modified.




; button2                                                             20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     First yellow button.
;     Calls the main_SetTime() function.
button2:

    rcall  main_SetTime

    ret


; button3                                                             20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Second yellow button
;     Displays the current time and date.
button3:

    rcall  main_ShowTime

    ret


; button4                                                             20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Green button.
button4:

    ldi    r20,  DISPLAY_ADDR1              ; argument: r20 = SLA+W
    rcall  Display_Refresh

    ret


; button5                                                             20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     Red button
button5:


    ret


; button6                                                             20Sep2019
; -----------------------------------------------------------------------------
; Description:
;     
button6:


button6_error:


button6_exit:

    ret




