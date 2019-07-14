;
; nhd0420cwFuncs_twi.asm
;
; Created: 12Jul2019
; Updated: 14Jul2019
; Author:  JSRagman
;
; Hardware:
;           MCU:  ATmega1284p
;       Display:  Newhaven Display NHD-0420CW
;     Interface:  TWI
;
; Description:
;     Basic functions for interacting with Newhaven Display NHD-0420CW
;     OLED character displays using the ATmega1284p TWI module.


; Function List:
;     US2066_Reset                  Resets and initializes the display.
;     US2066_SendCommand          Sends a single-byte command to the display.
;     US2066_SendData             Sends one or more bytes of data to the display.
;     US2066_SetState             Turns the display on or off and sets the cursor state.
;     US2066_WriteFromEepString   Transmits string data from EEPROM to the display.
;     US2066_WriteFromEepData     Reads data from EEPROM and transmits to the display.


#ifndef _us2066_dispfuncs_twi
#define _us2066_dispfuncs_twi




; US2066_Reset                                                        14Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 14Jul2019
; Description:
;     Resets and initializes the display.
;
;     Initialization data must be organized in byte pairs:
;         control byte, command(or data) byte,
;         control byte, command(or data) byte,
;         control byte, command(or data) byte,
;         ...
;
;     The display I2C interface expects to receive a control byte followd by
;     a command(or data) byte.
;
;     There are only two recognized control bytes - 0x00 and 0x40.
;     Transmission ends when a byte that is expected to be a control byte,
;     is not a control byte.
; Parameters:
;     Address - r25:r24
;               r25:r24 are expected to hold the EEPROM address of the
;               initialization data.
;     SLA+W   - GPIOR0
;               GPIOR0 is expected to hold the SLA+W for the targeted display.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - r16
; I/O Registers Affected:
;     DDRD - The DRESET pin direction is set to Output and then back to Input.
US2066_Reset:
    sbi    DDRD, DRESET
    m_delay 100

    cbi    DDRD, DRESET
    m_delay 100

    rcall  US2066_WriteFromEepData
    ret


; US2066_SendCommand                                                  12Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  12Jul2019
; Description:
;     Sends a single-byte command to the display.
; Parameters:
;     SLA+W   - GPIOR0
;               SLA+W for the targeted display.
;     Command - Data Stack
;               The top byte of the data stack is expected to be a command.
; General-Purpose Registers:
;     Preserved - r16
;     Changed   - 
; Data Stack:
;     Incoming      = 1 command byte
;     Push 1 byte   = control byte (command)
;     Push 1 byte   = byte count
;     Push 1 byte   = SLA+W
; Constants (Non-Standard):
;     CTRLBYTE_CMD
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     pushd  - Push the contents of a register onto the data stack
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     Return values are passed unchanged from the TwiDw_FromDataStack function.
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
;     TWSR - Will contain a status code from the last TWI operation performed
US2066_SendCommand:
    push  r16

    pushdi CTRLBYTE_CMD                ; Data Stack: push control byte
    pushdi 2                           ; Data Stack: push bytecount
    in     r16,    GPIOR0              ; Retrieve the display SLA+W
    pushd  r16                         ; Data Stack: push SLA+W
    rcall  TwiDw_FromDataStack         ; Transmit

    pop    r16
    ret


; US2066_SendData                                                     12Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  12Jul2019
; Description:
;     Sends one or more bytes of data to the display.
; Parameters:
;     SLA+W      - GPIOR0
;                  SLA+W for the targeted display.
;     Byte Count - Data Stack
;                  The top byte of the data stack is expected to indicate the
;                  number of data bytes that follow.
;     Data       - Data Stack
;                  Below the byte count, the data stack is expected to contain
;                  one or more bytes of data.
; General-Purpose Registers:
;     Preserved - r16, r17
;     Changed   - 
; Data Stack:
;     Incoming      = byte count + data
;     Pop 1 byte    = byte count
;     Push 1 byte   = control byte (data)
;     Push 1 byte   = incremented byte count
;     Push 1 byte   = SLA+W
; Constants (Non-Standard):
;     CTRLBYTE_DATA
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     popd  - Pop from the data stack into a specified register
;     pushd - Push the contents of a register onto the data stack
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     SREG - The T flag indicates whether the operation was successful
;            (cleared) or if an error was encountered (set)
US2066_SendData:
    push r16
    push r17

   .def    bytecount = r17

    popd    bytecount                         ; Data Stack: pop bytecount
    inc     bytecount                         ; increment bytecount
    pushdi  CTRLBYTE_DATA                     ; Data Stack: push Control Byte - Data
    pushd   bytecount                         ; Data Stack: push incremented bytecount
    in      r16,    GPIOR0                    ; Retrieve the display SLA+W
    pushd   r16                               ; Data Stack: push SLA+W
    rcall   TwiDw_FromDataStack               ; Transmit

   .undef  bytecount

    pop    r17
    pop    r16
    ret


; US2066_SetState                                                     12Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  12Jul2019
; Description:
;     Turns the display on or off and sets the cursor state.
; Parameters:
;     SLA+W  - GPIOR0
;              SLA+W for the targeted display.
;     State  - Data Stack
;              The top byte on the data stack is expected to be a command
;              byte to turn the display on or off.
;     Cursor - Data Stack
;              The second byte on the data stack is expected to contain the
;              cursor bit pattern for On, Off, or Blink.
; General-Purpose Registers:
;     Preserved - r16, r17, r18
;     Changed   - 
; Data Stack:
;     Incoming     = 2 bytes
;     Pop 1 byte   = display state
;     Pop 1 byte   = cursor state
;     Push 1 byte  = display + cursor
;     Push 1 byte  = control byte
;     Push 1 byte  = byte count
;     Push 1 byte  = SLA+W
; Constants (Non-Standard):
;     CTRLBYTE_CMD
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     popd  - Pop from the data stack into a specified register
;     pushd - Push the contents of a register onto the data stack
; Returns:
;     Return values are passed unchanged from the TwiDw_FromDataStack function.
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
;     TWSR - Will contain a status code from the last TWI operation performed
US2066_SetState:
    push   r16
    push   r17
    push   r18

   .def    displaystate = r17
   .def    cursorstate  = r18

    popd   displaystate                     ; Data Stack: pop display state
    popd   cursorstate                      ; Data Stack: pop cursor state
    or     displaystate, cursorstate        ; displaystate |= cursorstate
    pushd  displaystate                     ; Data Stack: push displaystate
    ldi    r16,    CTRLBYTE_CMD
    pushd  r16                              ; Data Stack: push control byte
    ldi    r16,    2                        ; bytecount = 2
    pushd  r16                              ; Data Stack: push bytecount
    in     r16,    GPIOR0
    pushd  r16                              ; Data Stack: push SLA+W
    rcall  TwiDw_FromDataStack              ; TWI transmit

   .undef  cursorstate
   .undef  displaystate

    pop    r18
    pop    r17
    pop    r16
    ret


; US2066_WriteFromEepString                                           14Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 14Jul2019
; Description:
;     Transmits string data from EEPROM to the display.
;     Transmission ends when an ASCII newline character ('\n') is encountered
;     or when the number of characters read reaches a specified count.
; Parameters:
;     SLA+W      - GPIOR0
;                  SLA+W for the targeted display.
;     EEPROM     - Data Stack
;                  The top byte on the data stack is expected to be the
;                  low byte of the EEPROM address where the string data
;                  is to be found.
;     Max Bytes  - Data Stack
;                  The second byte on the data stack indicates the maximum
;                  number of bytes that can be transmitted.
;                  This will terminate the loop in the event that the
;                  EEPROM string data does not contain a newline character.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - 
; Data Stack:
;     Incoming    1 byte EEPROM address (low byte)
;                 1 byte maximum byte count
;     Final     - empty
; Functions Called:
;     TwiDw_FromEepString
; Macros Used:
;     popd  - Pop from the data stack
;     pushd - Push to the data stack
; Returns:
;     SREG - The T flag indicates whether the operation was successful
;            (cleared) or if an error was encountered (set)
US2066_WriteFromEepString:
   push   r16
   push   r17
   push   r18

   in      r16,    GPIOR0                   ; load SLA+W for the targeted display
   pushd   r16                              ; push SLA+W

   rcall   TwiDw_FromEepString              ; TWI transmit

   pop    r18
   pop    r17
   pop    r16
   ret


; US2066_WriteFromEepData                                             14Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 14Jul2019
; Description:
;     Reads data from EEPROM and transmits to the display.
;
;     EEPROM data must be organized in byte pairs:
;         control byte, command(or data) byte,
;         control byte, command(or data) byte,
;         control byte, command(or data) byte,
;         ...
;
;     The display I2C interface expects to receive a control byte followd by
;     a command(or data) byte.
;
;     There are only two recognized control bytes - 0x00 and 0x40.
;     Transmission ends when a byte that is expected to be a control byte,
;     is not a control byte.
; Parameters:
;     Address - r25:r24
;               r25:r24 are expected to hold the EEPROM address of the first
;               control byte.
;     SLA+W   - GPIOR0
;               GPIOR0 is expected to hold the SLA+W for the targeted display.
; General-Purpose Registers:
;     Preserved - r16, r17, r18, r20
;     Changed   - r25:r24
; Data Stack:
;     Incoming  - empty
;     Final     - empty
; I/O Registers Affected:
;     SREG        - T flag is used to report function success/failure
;     EEARH:EEARL - EEPROM Address Registers
;     EECR        - EEPROM Control Register
; Constants (Non-Standard):
;     CTRLBYTE_MASK
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     pushd  - Pushes the contents of a register onto the data stack
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     SREG - The T flag indicates whether the operation was successful
;            (cleared) or if an error was encounted (set)
; Notes:
;     1.  A control byte will be either 0x00 or 0x40.
;         Any control byte ANDed with 0b_1011_1111 will yield a zero.
;
US2066_WriteFromEepData:
    push   r16
    push   r17
    push   r18
    push   r20

   .def    ctrlbyt = r17                    ; control byte
   .def    databyt = r18                    ; data(or command) byte
   .def    sla_w   = r20                    ; SLA+W parameter

    in     sla_w,  GPIOR0                   ; retrieve the display address
loop_WriteFromEepData:
    out    EEARH,    r25                    ; Load EEPROM address
    out    EEARL,    r24
    sbi    EECR,     EERE                   ; Read the first byte
    in     ctrlbyt,  EEDR                   ; and place in ctrlbyt
    adiw   r25:r24, 1                       ; Increment the EEPROM address.

    ldi    r16,    CTRLBYTE_MASK            ; Test for control byte
    and    r16,    ctrlbyt                  ; if (ctrlbyte != control byte)
    brne   exit_WriteFromEepData            ;     exit

    out    EEARH,    r25                    ; Load EEPROM address
    out    EEARL,    r24
    sbi    EECR,     EERE                   ; Read the data byte
    in     databyt,  EEDR                   ; and place in databyt
    adiw   r25:r24, 1                       ; Increment the EEPROM address.

    pushd  databyt                          ; push the data byte
    pushd  ctrlbyt                          ; push the control byte
    pushdi 2                                ; push the byte count
    pushd  sla_w                            ; push the display address
    rcall  TwiDw_FromDataStack              ; Transmit
    brtc   loop_WriteFromEepData

exit_WriteFromEepData:

   .undef  sla_w
   .undef  databyt
   .undef  ctrlbyt

    pop    r20
    pop    r18
    pop    r17
    pop    r16
    ret





#endif
