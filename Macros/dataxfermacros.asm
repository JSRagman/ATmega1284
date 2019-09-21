;
; dataxfermacros.asm
;
; Created: 27Jul2019
; Updated: 27Jul2019
; Author:  JSRagman
;
; Description:
;     Data transfer macros.
;
; Depends On:
;     1.  m1284pdef.inc
;
; Reference:
;     1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;


; Macro List:
;     ldli      Loads an immediate value into a low register (r0 to r15).
;     outi      Stores an 8-bit immediate value to I/O space.




; ldli                                                                27Jul2019
; -----------------------------------------------------------------------------
; Description:
;     Loads an immediate value into a low register (r0 to r15).
; Parameters:
;     @0  A low register (r0 - r15)
;     @1  An 8-bit immediate value
; General-Purpose Registers:
;     Modified  - r16
; Usage:
;     m_ldli  r0, 0xFF
.macro ldli
    ldi    r16,    @1
    mov    @0,     r16
.endmacro



; inn                                                                 27Jul2019
; -----------------------------------------------------------------------------
; Description:
;     Loads an 8-bit value from I/O space into a register.
; Parameters:
;     @0  A General-Purpose register (r0 - r31)
;     @1  An I/O space address
; Usage:
;     inn  r16, TWCR
.macro inn
   .IF @1 > 0xCE
       .ERROR "inn: I/O address" + @1 + " is reserved. "
   .ELIF @1 > 0x5F
       lds @0, @1
   .ELIF @1 > 0x3F
       .ERROR "inn: I/O address" + @1 + " is invalid. "
   .ELSE
       in @0, @1
   .ENDIF
.endmacro


; outi                                                                27Jul2019
; -----------------------------------------------------------------------------
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
;     Modified  - r16
; Usage:
;     outi  OCR0A, 2
; Note:
;     @0 > 0xCE   Nothing up here but reserved space.
;     @0 > 0x5F   (0x60 to 0xCE) extended I/O space, use the sts instruction.
;     @0 > 0x3F   (0x40 to 0x5F) don't use, overlaps 0x20 to 0x3F.
;     @0 to 0x3F  Standard I/O address space, use the out instruction.
.MACRO outi
    ldi  r16, @1

   .IF @0 > 0xCE
       .ERROR "outi: I/O address" + @0 + " is reserved. "
   .ELIF @0 > 0x5F
       sts @0, r16
   .ELIF @0 > 0x3F
       .ERROR "outi: I/O address" + @0 + " is invalid. "
   .ELSE
       out @0, r16
   .ENDIF
.ENDMACRO


; outr                                                                30Jul2019
; -----------------------------------------------------------------------------
; Description:
;     Stores the contents of a register to I/O space.
;     The out instruction is used for I/O addresses 0x00 to 0x3F.
;     The sts instruction is used for I/O addresses 0x5F to 0xCE.
; Parameters:
;     @0  An I/O space address in the range
;            0x00 to 0x3F, or
;            0x60 to 0xCE
;     @1  A general-purpose working register (r0 - r31).
; Usage:
;     outr  OCR0A, r16
; I/O Address:
;     @0 > 0xCE   Nothing up here but reserved space.
;     @0 > 0x5F   (0x60 to 0xCE) extended I/O space, use the sts instruction.
;     @0 > 0x3F   (0x40 to 0x5F) don't use, overlaps 0x20 to 0x3F.
;     @0 to 0x3F  Standard I/O address space, use the out instruction.
.macro outr
   .IF @0 > 0xCE
       .ERROR "outr: I/O address" + @0 + " is reserved. "
   .ELIF @0 > 0x5F
       sts @0, @1
   .ELIF @0 > 0x3F
       .ERROR "outr: I/O address" + @0 + " is invalid. "
   .ELSE
       out @0, @1
   .ENDIF
.endmacro
