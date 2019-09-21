;
; Project: ATmega1284Prototype1
;
; File:    registers.asm
; Created: 20Jul2019
; Updated: 20Jul2019
; Author:  JSRagman
;
; MCU:     ATmega1284/1284P
;
; Description:
;     General-Purpose Register definitions and usage.



; Named Registers:
; -----------------------------------------------------------------------------

; r0 - r15: Low Registers
.def  rZero   = r3                ; Constant: A big fat zero.

.def  rTimer  = r10               ; Incremented by Timer/Counter 0


; r16 - r31: Working Registers



; GPIO Registers:
; -----------------------------------------------------------------------------
; 0x1E  GPIOR0

; 0x2A  GPIOR1
; 0x2B  GPIOR2

; Register Usage:
; -----------------------------------------------------------------------------

; Named Registers:
; ----------------------------
; rZero -
;
; rTimer -
;
; rSlarw -
; 

; Parameters:
; ----------------------------
; Data Stack - 
;        TwiDw_FromDataStack
;
; r16 - 
;
; r17 -  count, dscount
;        TwiDw_FromDataStack
;        TwiDw_FromSram
;
; r18 -  srcount
;        TwiDw_FromSram
;
; r19 - 
;
; r20 -  SLA+R/W
;        Twi_Connect
;        Twi_Slawr
;        TwiDr_OneByte
;        TwiDr_RegConnect
;        TwiDw_FromDataStack
;        TwiDw_FromEepData
;        TwiDw_FromSram
;
; r21 - databyt, regaddress
;        TwiDr_OneByte
;        TwiDr_RegConnect
;        TwiDw_Send
;
; r22 -  
;
; r23 - 
;
; r25:r24 - EEPROM address pointer
;        TwiDw_FromEepData
;
; X
;        TwiDw_FromSram
;
; Y
;
; Z
;

; Return Values:
; ----------------------------
; Data Stack -
;        TwiDr_OneByte
;
; r19 - 
;       Twi_Wait
;
;


; r0 - r15: Low Registers
; ----------------------------
; rZero
;     main_Wait
;     reset
;     TwiDw_FromDataStack
; rTimer
;     main_Wait
;     irq_oc0a


; r16 - r31: Working Registers
; ----------------------------


; Pointers
; ----------------------------
; r25:r24
; X
; Y
; Z

