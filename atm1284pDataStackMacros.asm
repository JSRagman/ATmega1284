;
;atm1284pDataStackMacros.asm
;
; Created: 5/12/2019 8:23:10 AM
; Author: JSRagman
;
; Description:
;     Macros for implementing a data stack using the Y register.
;
; Depends On:
;     1.  m1284pdef.inc
;
; Reference:
;     1.  ATmega1284 datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;
; Macro List:
;     m_peekd      Peeks the top byte on the data stack.
;     m_peekdd     Peeks one byte from a given displacement into the data stack.
;     m_popd       Pops the top byte from the data stack into a register.
;     m_pushd      Pushes a register onto the data stack.
;     m_pushdi     Pushes an immediate value onto the data stack.


; m_peekd                                                             12May2019
; -----------------------------------------------------------------------------
; Description:
;     Retrieves the next value from the data stack without popping it.
;     The data stack pointer is not changed.
; Parameters:
;     @0   A general-purpose working register (r0-r31).
; General-Purpose Registers:
;     Preserved - Y
;     Changed   - 
; Returns:
;     Returns the top byte from the data stack via the general-purpose
;     register specified by the @0 parameter.
; Usage:
;     m_peekd r16
.MACRO m_peekd
    ld @0, Y
.ENDMACRO


; m_peekdd                                                            12May2019
; -----------------------------------------------------------------------------
; Description:
;     Peeks one byte from a given displacement into the data stack.
;     The data stack pointer is not changed.
; Parameters:
;     @0   A general-purpose working register (r0-r31).
;     @1   An immediate value displacement (0 to 63).
; General-Purpose Registers:
;     Preserved - Y
;     Changed   - 
; Returns:
;     Returns one byte from a given displacement into the data stack.
;     The register specified by @0 will contain the return value.
; Usage:
;     m_peekdd r16, 2
.MACRO m_peekdd
    ldd @0, Y+@1
.ENDMACRO


; m_popd                                                              12May2019
; -----------------------------------------------------------------------------
; Description:
;     Pops a value from the data stack into a specified register.
; Parameters:
;     @0   A general-purpose working register (r0-r31).
; General-Purpose Registers:
;     Preserved - 
;     Changed   - Y
; Returns:
;     Returns the top byte from the data stack via the general-purpose
;     register specified by the @0 parameter.
; Usage:
;     m_popd r16
.MACRO m_popd
    ld @0, Y+
.ENDMACRO


; m_pushd                                                             12May2019
; -----------------------------------------------------------------------------
; Description:
;     Pushes a general-purpose register onto the data stack.
; Parameters:
;     @0   A general-purpose working register (r0-r31).
; General-Purpose Registers Used:
;     Preserved - 
;     Changed   - Y
; Returns:
;     Nothing.
; Usage:
;     m_pushd r16
.MACRO m_pushd
    st -Y, @0
.ENDMACRO


; m_pushdi                                                            12May2019
; -----------------------------------------------------------------------------
; Function:
;     Push an immediate value onto the data stack.
; Parameters:
;     @0   A one-byte immediate value.
; General-Purpose Registers Used:
;     Preserved - 
;     Changed   - r16, Y
; Returns:
;     Nothing.
; Usage:
;     m_pushdi 0xFF
.MACRO m_pushdi
    ldi r16, @0
    st -Y, r16
.ENDMACRO
