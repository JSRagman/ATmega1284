;
; nhd0420cwFuncs_twi.asm
;
; Created: 12Jul2019
; Updated: 15Jul2019
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
;     US2066_Reset                Resets and initializes the display.
;     US2066_SendCommand          Sends a single-byte command to the display.
;     US2066_SendData             Sends one or more bytes of data to the display.
;     US2066_SetPosition          Sets the display line and column positions.
;     US2066_SetState             Turns the display on or off and sets the cursor state.
;     US2066_WriteFromEepString   Transmits string data from EEPROM to the display.


#ifndef _us2066_dispfuncs_twi
#define _us2066_dispfuncs_twi




; US2066_Reset                                                        15Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  15Jul2019
; Description:
;     Resets and initializes the display.
; Parameters:
;     Address - display_init
;               The display_init label is expected to be the EEPROM
;               address of the initialization data.
;     SLA+W   - Global Constant
;               DISPLAY_ADDR is expected to hold the SLA+W for the display.
; General-Purpose Registers:
;     Preserved - 
;     Changed   - r16
; I/O Registers Affected:
;     DDRD - The DRESET pin direction is set to Output and then back to Input.
US2066_Reset:
    push   r24
    push   r25

    sbi    DDRD, DRESET
    m_delay 100
    cbi    DDRD, DRESET
    m_delay 100

    ldi    r25,    high(display_init)   ; Point to initialization data.
    ldi    r24,     low(display_init)
    pushdi DISPLAY_ADDR

    rcall  TwiDw_FromEepData

    pop    r25
    pop    r24
    ret


; US2066_SendCommand                                                  15Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  15Jul2019
; Description:
;     Sends a single-byte command to the display.
; Parameters:
;     SLA+W   - Global Constant
;               DISPLAY_ADDR is expected to hold the SLA+W for the display.
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
;     DISPLAY_ADDR
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     Return values are passed unchanged from the TwiDw_FromDataStack function.
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
;     TWSR - Will contain a status code from the last TWI operation performed
US2066_SendCommand:
    push     r16

    pushdi   CTRLBYTE_CMD                   ; Data Stack: push control byte
    pushdi   2                              ; Data Stack: push bytecount
    pushdi   DISPLAY_ADDR                   ; Data Stack: push SLA+W
    rcall    TwiDw_FromDataStack            ; Transmit

    pop      r16
    ret


; US2066_SendData                                                     15Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  15Jul2019
; Description:
;     Sends one or more bytes of data to the display.
; Parameters:
;     SLA+W  - Global Constant
;              DISPLAY_ADDR is expected to hold the SLA+W for the display.
;     Count  - Data Stack
;              The top byte of the data stack is expected to indicate the
;              number of data bytes that follow.
;     Data   - Data Stack
;              Below the byte count, the data stack is expected to contain
;              one or more bytes of data.
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
;     DISPLAY_ADDR
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     popd   - Pop from the data stack into a register
;     pushd  - Push the contents of a register onto the data stack
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     SREG - The T flag indicates whether the operation was successful
;            (cleared) or if an error was encountered (set)
US2066_SendData:
    push r16
    push r17

   .def     count = r17

    popd    count                           ; Data Stack: pop bytecount
    inc     count                           ; increment bytecount
    pushdi  CTRLBYTE_DATA                   ; Data Stack: push Control Byte - Data
    pushd   count                           ; Data Stack: push incremented bytecount
    pushdi  DISPLAY_ADDR                    ; Data Stack: push SLA+W
    rcall   TwiDw_FromDataStack             ; Transmit

   .undef   count

    pop    r17
    pop    r16
    ret


; US2066_SetPosition                                                  15Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  15Jul2019
; Description:
;     Sets the display line and column positions.
; Parameters:
;     SLA+W  - Global Constant
;              DISPLAY_ADDR is expected to hold the SLA+W for the display.
;     Line   - Data Stack
;              The top byte on the data stack is expected to indicate
;              the line number (1, 2, 3, or 4).
;     Column - Data Stack
;              The second byte on the data stack is expected to indicate
;              the column number (1 to 20).
; General-Purpose Registers:
;     Preserved - r0, r16, r17, r18, r19, r20, r21
;     Changed   - 
; Data Stack:
;     Incoming     = 2 bytes
;     Pop 1 byte   = line number
;     Pop 1 byte   = column number
;     Push 1 byte  = set_ddram command
;     Push 1 byte  = control byte - command
;     Push 1 byte  = byte count
;     Push 1 byte  = SLA+W
; Constants (Non-Standard):
;     CTRLBYTE_CMD
;     DISPLAY_ADDR
;     LINE_INCREMENT
;     SET_DDRAM
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     popd   - Pop from the data stack into a register
;     pushd  - Push the contents of a register onto the data stack
;     pushdi - Push an immediate value onto the data stack
; Returns:
;     Return values are passed unchanged from the TwiDw_FromDataStack function.
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
; Notes:
;     1. The Set DDRAM Address command has the format:
;          Bit    7 = 1
;          Bits 6:0 = DDRAM address value
US2066_SetPosition:
    push    r0
    push    r16
    push    r17
    push    r18
    push    r19
    push    r20

   .def     line    = r17                   ; Line number
   .def     column  = r18                   ; Column number
   .def     ddram   = r19                   ; Display position (DDRAM address)
   .def     lineinc = r20                   ; DDRAM line increment value

    ldi     lineinc, LINE_INCREMENT         ; load ddram line increment value

    popd    line                            ; Data Stack: pop line number
    dec     line                            ; decrement linenumber
    mul     line, lineinc                   ; ddram = linenumber * increment
    mov     ddram, r0

    popd    column                          ; Data Stack: pop column number
    dec     column                          ; decrement column number
    add     ddram, column                   ; ddram += column number
    ori     ddram, SET_DDRAM                ; Complete the Set DDRAM command

    pushd   ddram                           ; Data Stack: push ddram command
    pushdi  CTRLBYTE_CMD                    ; Data Stack: push control byte
    pushdi  2                               ; Data Stack: push bytecount
    pushdi  DISPLAY_ADDR                    ; Data Stack: push SLA+W
    rcall   TwiDw_FromDataStack             ; Transmit

   .undef   lineinc
   .undef   ddram
   .undef   column
   .undef   line

    pop     r20
    pop     r19
    pop     r18
    pop     r17
    pop     r16
    pop     r0
    ret


; US2066_SetState                                                     15Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  15Jul2019
; Description:
;     Turns the display on or off and sets the cursor state.
; Parameters:
;     SLA+W  - Global Constant
;              DISPLAY_ADDR is expected to hold the SLA+W for the display.
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
;     DISPLAY_ADDR
; Functions Called:
;     TwiDw_FromDataStack
; Macros Used:
;     popd   - Pop from the data stack into a register
;     pushd  - Push the contents of a register onto the data stack
;     pushdi - Push an immediate value onto the data stack
; Returns:
;     Return values are passed unchanged from the TwiDw_FromDataStack function.
;     SREG - The T flag indicates whether the TWI operation was successful
;            (cleared) or if an error was encountered (set)
US2066_SetState:
    push    r16
    push    r17
    push    r18

   .def     displaystate = r17
   .def     cursorstate  = r18

    popd    displaystate                    ; Data Stack: pop display state
    popd    cursorstate                     ; Data Stack: pop cursor state
    or      displaystate, cursorstate       ; displaystate |= cursorstate
    pushd   displaystate                    ; Data Stack: push displaystate
    pushdi  CTRLBYTE_CMD                    ; Data Stack: push control byte
    pushdi  2                               ; Data Stack: push bytecount
    pushdi  DISPLAY_ADDR                    ; Data Stack: push SLA+W
    rcall   TwiDw_FromDataStack             ; Transmit

   .undef   cursorstate
   .undef   displaystate

    pop     r18
    pop     r17
    pop     r16
    ret


; US2066_WriteFromEepString                                           15Jul2019
; -----------------------------------------------------------------------------
; Status:
;     Tested  15Jul2019
; Description:
;     Transmits string data from EEPROM to the display.
;
;     The first byte of EEPROM data must be a Control Byte - Data (0x40).
;
;     Transmission ends when an ASCII newline character ('\n') is encountered
;     or when the number of characters read reaches a specified count.
; Parameters:
;     r25:r24    - EEPROM address of the first data byte.
;     SLA+W      - Global Constant
;                  DISPLAY_ADDR is expected to hold the SLA+W for the display.
;     Max Bytes  - Data Stack
;                  The top byte on the data stack indicates the maximum
;                  number of bytes that can be transmitted.
;                  This will terminate the loop in the event that the
;                  EEPROM string data does not contain a newline character.
; General-Purpose Registers:
;     Preserved - r16
;     Changed   - 
; Data Stack:
;     Incoming    1 byte maximum byte count
;     Final     - empty
; Constants (Non-Standard):
;     DISPLAY_ADDR
; Functions Called:
;     TwiDw_FromEepString
; Macros Used:
;     pushdi - Push an immediate value onto the data stack
; Returns:
;     SREG - The T flag indicates whether the operation was successful
;            (cleared) or if an error was encountered (set)
US2066_WriteFromEepString:
    push   r16

    pushdi  DISPLAY_ADDR                    ; Data Stack: push SLA+W
    rcall   TwiDw_FromEepString             ; Transmit

    pop    r16
    ret





#endif
