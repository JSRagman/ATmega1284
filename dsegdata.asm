;
; dsegdata.asm
;
; Created: 15Jul2019
; Updated: 15Jul2019
; Author:  JSRagman

; Description:
;     SRAM data reservations

; SRAM Layout
; -----------------------------------
; 0x0000   General-purpose working registers
;       
; 0x0020   I/O registers
;       
; 0x0060   Extended I/O registers
;       
; 0x0100   Internal SRAM
;          static values
;          heap
;          ...
;          data stack
;          hardware stack
; 0x40FF

.dseg
sr_displaytext:  .byte CHARCOUNT
sr_realtime:     .byte RTCBYTES
sr_rtcset:       .byte RTC_TIMEBYTES
sr_rtimetext:    .byte CHARCOUNT

