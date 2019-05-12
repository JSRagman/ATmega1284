;
; atm1284pDataXferMacros.asm
;
; Created: 5/12/2019 10:22:08 AM
; Author: JSRagman
;
; Description:
;    Macros useful for moving bytes about.
;
; Depends On:
;     1.  m1284pdef.inc
;
; Reference:
;     1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
; NOTES:
;    1.  For register addresses greater than 0x3F, the sts and lds instructions
;        must be used instead of the out and in instructions.
;    2.  16-Bit Register I/O
;          16-bit Write
;            a. Write the High byte.
;            b. Write the Low byte.
;          16-bit Read
;            a. Read the Low byte.
;            b. Read the High byte.


#ifndef _atm1284P_dxfer_macro_defs_
#define _atm1284P_dxfer_macro_defs_

; Macro List:
; -----------
; m_ldli           18Feb2019   Load an immediate value into a low register (r0 - r15).
; m_outi           18Feb2019   Store an 8-bit immediate value to I/O space.
; m_sti            18Feb2019   Store Indirect (ST) for an immediate value.


; m_ldli
; ------
; Description:
;     Loads an immediate value into a low general-purpose working
;     register (r0 to r15).
; Parameters:
;     @0  A low register (r0 - r15)
;     @1  An 8-bit immediate value
; General-Purpose Registers:
;     1. Preserved - 
;     2. Changed   - r16
; Usage:
;     m_ldli  r0, 0xFF
.MACRO m_ldli
    ldi  r16,  @1
    mov   @0, r16
.ENDMACRO


; m_outi
; ------
; Description:
;     Stores an 8-bit immediate value to I/O space.
;     The out instruction is used for I/O addresses 0x00 to 0x3F.
;     The sts instruction is used for I/O addresses 0x5F to 0xCE.
; Parameters:
;     @0  An I/O space address in the range
;            0x00 to 0x3F, or
;            0x60 to 0xCE
;     @1  An 8-bit immediate value
; General-Purpose Registers:
;     1. Preserved - 
;     2. Changed   - r16
; Usage:
;     m_outi  OCR0A, 2
; Note:
;     @0 > 0xCE   Nothing up here but reserved space.
;     @0 > 0x5F   (0x60 to 0xCE) extended I/O space.
;     @0 > 0x3F   (0x40 to 0x5F) don't use, overlaps 0x20 to 0x3F.
;     @0 to 0x3F  Standard I/O address space.
.MACRO m_outi
    ldi  r16, @1

   .IF @0 > 0xCE
       .ERROR "m_outi: I/O address" + @0 + " is reserved. "
   .ELIF @0 > 0x5F
       sts @0, r16
   .ELIF @0 > 0x3F
       .ERROR "m_outi: I/O address" + @0 + " is invalid. "
   .ELSE
       out @0, r16
   .ENDIF
.ENDMACRO


; m_sti
; -----
; Description:
;     Stores Indirect an 8-bit immediate value to data space.
; Parameters:
;     @0  A Pointer Register X, Y, or Z
;     @1  An 8-bit immediate value
; General-Purpose Registers:
;     1. Preserved - 
;     2. Changed   - r16
; Usage:
;     m_sti  Y+, 0b_0010_0000
;     m_sti  X,  0x68
.MACRO m_sti
    ldi r16,   @1
    st   @0,  r16
.ENDMACRO



#endif


