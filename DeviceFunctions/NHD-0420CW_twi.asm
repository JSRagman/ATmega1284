;
; NHD-0420CW_twi.asm
;
; Created: 12Jul2019
; Updated: 21Sep2019
; Author:  JSRagman
;
; Hardware:
;           MCU:  ATmega1284, ATmega1284P
;       Display:  Newhaven Display NHD-0420CW
;     Interface:  TWI
;
; Description:
;     Basic functions for interacting with Newhaven Display NHD-0420CW
;     OLED character displays using the ATmega1284 TWI module.


; Function List:
;     Display_Refresh              Refreshes the display from SRAM.
;     Display_SendCommand          Sends a single-byte command to the display.
;     Display_SendData             Sends one or more bytes of data to the display.
;     Display_SetPosition          Sets the display line and column positions.
;     Display_WriteLine            Writes one line of text from SRAM to the display.


; Depends On:
;     1.  m1284pdef.inc
;     2.  constants.asm
;     3.  datastackmacros.asm
;             pushd
;             pushdi
;     4.  twifuncs_write.asm
;             TwiDw_FromDataStack (r17, r20, data stack)
;             TwiDw_FromSram      (r17, r18, r20, X)

; Reference:
;     1.  ATmega1284/1284P datasheet (Atmel-8272G-AVR-01/2015)
;     2.  Atmel AVR 8-bit Instruction Set Manual, Rev. 0856K-AVR-05/2016
;     3.  Newhaven Display NHD-0420CW-AB3 Data Sheet, 4/6/2015
;     4.  US2066 100 x 32 OLED/PLED Segment/Common Driver with Controller Data Sheet

; Notes:
;      1. SLA+W stands for "Slave Address plus Write bit".
;         These display functions all expect a SLA+W parameter, which is passed
;         unchanged to the appropriate TWI function.
;
;         In this configuration, the functions you see here can be used to
;         control two NHD-0420CW displays, using the two available TWI
;         addresses.
;
;         If only one display is to be used, the SLA+W parameter could be
;         replaced by a constant.
;         If a single display is the only device on the TWI bus, TWI functions
;         can be simplified likewise.




; Display_Refresh                                                     14Aug2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 14Aug2019
; Description:
;     Refreshes the display from SRAM.
; Assumptions:
;     1.  Text is stored as 80 contiguous bytes in SRAM, with address label
;         sr_displaytext.
; Parameters:
;     r20  - SLA+W for the targeted display
;            ( 0x78 | 0x7A )
; Address Labels:
;     sr_displaytext
; General-Purpose Registers:
;     Named      - 
;     Parameters - r20
;     Modified   - 
; Constants (Non-Standard):
;     SET_DDRAM
; Functions Called:
;     Display_SendCommand
;     Display_SendData
; Returns:
;     SREG_T - pass (0) or fail (1)
Display_Refresh:
    push   r21
    push   XL
    push   XH

;   Home the display
    ldi    r18,    SET_DDRAM                ; argument: command = SET_DDRAM
    rcall  Display_SendCommand              ; Display_SendCommand(command, SLA+W)
    brts   Display_Refresh_exit             ; if (SREG_T == 1)  goto exit

;   Send the data
    ldi    XH,     high(sr_displaytext)     ; argument: point X to display data
    ldi    XL,      low(sr_displaytext)
    ldi    r18,    80                       ; bytecount = 80
    rcall  Display_SendData                 ; Display_SendData(bytecount, SLA+W, X)

Display_Refresh_exit:

    pop    XH
    pop    XL
    pop    r21
    ret


; Display_SendCommand                                                 13Aug2019
; -----------------------------------------------------------------------------
; Description:
;     Sends a single-byte command to the display.
; Parameters:
;     r18     - expected to contain a command byte for the display
;     r20     - SLA+W for the targeted display
;               ( 0x78 | 0x7A )
; General-Purpose Registers:
;     Parameters - r18, r20
;     Modified   - Y
; Data Stack:
;     Incoming - empty
;     Final    - empty
; Constants (Non-Standard):
;     CTRL_CMD     Control Byte (Command)
; Functions Called:
;     TwiDw_FromDataStack(count, data, SLA+W)
; Macros Used:
;     pushd  - Push the contents of a register onto the data stack
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     SREG_T - pass (0) or fail (1)
Display_SendCommand:
    push   r16
    push   r17

   .def    bytcnt = r17                     ; byte count
   .def    cmdbyt = r18                     ; parameter: command byte
   .def    slarw  = r20                     ; parameter: SLA+W

    pushd  cmdbyt                           ; Data Stack: push the command byte
    pushdi CTRL_CMD                         ; Data Stack: push Control Byte (Command)
    ldi    bytcnt,   2                      ; argument: byte count = 2
    rcall  TwiDw_FromDataStack              ; TwiDw_FromDataStack(r17, r20, data stack)

   .undef  bytcnt
   .undef  cmdbyt
   .undef  slarw

    pop    r17
    pop    r16
    ret


; Display_SendData                                                    14Aug2019
; -----------------------------------------------------------------------------
; Description:
;     Sends one or more bytes of data from SRAM to the display.
; Parameters:
;     r18     - data byte count
;     r20     - SLA+W for the targeted display
;               ( 0x78 | 0x7A )
;     X       - SRAM data address pointer
; General-Purpose Registers:
;     Parameters - r18, r20, X
;     Modified   - Y
; Data Stack:
;     Incoming - empty
;     Final    - empty
; Constants (Non-Standard):
;     CTRL_DAT     Control Byte (Data)
; Functions Called:
;     TwiDw_FromSram(r17, r18, r20, X)
; Macros Used:
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     SREG_T - pass (0) or fail (1)
Display_SendData:
    push r16
    push r17

    pushdi CTRL_DAT                         ; Data Stack: push Control Byte (Data)
    ldi    r17,    1                        ; argument: data stack byte count
    rcall  TwiDw_FromSram                   ; TwiDw_FromSram(r17, r18, r20, X)

    pop    r17
    pop    r16
    ret



; Display_SetPosition                                                 13Aug2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 13Aug2019 1545
; Description:
;     Sets the display line and column position.
; Assumptions:
;     1. DDRAM address 0 corresponds to Line 1, Column 1 of the display.
;     2. Line and Column parameters are zero-based:
;          a. Line Number will be 0, 1, 2, or 3.
;          b. Column Number will be in the range (0, 1, 2, ..., 19).
;     3. The DDRAM_INCR constant is the DDRAM address increment required
;        to pass from one display line to the next.
; Parameters:
;     r20     - SLA+W for the targeted display
;               ( 0x78 | 0x7A )
;     r21     - line number (0, 1, 2, or 3).
;     r22     - column number (0, 1, 2, ..., 19).
; General-Purpose Registers:
;     Parameters - r20, r21, r22
;     Modified   - Y
; Constants (Non-Standard):
;     CTRL_CMD     Control Byte (Command)
;     DDRAM_INCR   DDRAM increment to move from one display line to the next
;     SET_DDRAM    Set DDRAM Address command
; Functions Called:
;     TwiDw_FromDataStack(count, data, SLA+W)
; Macros Used:
;     pushd  - Push a register onto the data stack
;     pushdi - Push an immediate value onto the data stack
; Returns:
;     SREG_T - pass (0) or fail (1)
Display_SetPosition:
    push   r0
    push   r16
    push   r17
    push   r18

   .def     count  = r17                    ; byte count
   .def     ddram  = r18                    ; DDRAM address
   .def     slarw  = r20
   .def     linndx = r21                    ; parameter: line index
   .def     colndx = r22                    ; parameter: column index

;   Calculate the DDRAM address.
    ldi     r16,     DDRAM_INCR             ;   r16 = ddram line increment value
    mul     linndx,  r16                    ;    r0 = linndx * r16
    mov     ddram,   r0                     ; ddram = r0
    add     ddram,   colndx                 ; ddram = ddram + colndx

;   Set the display DDRAM address
    ori     ddram,   SET_DDRAM              ; ddram |= SET_DDRAM
    pushd   ddram                           ; Data Stack: push Set DDRAM Address command
    pushdi  CTRL_CMD                        ; Data Stack: push Control Byte (Command)
    ldi     count,   2                      ; argument: count = 2
    rcall   TwiDw_FromDataStack             ; TwiDw_FromDataStack(count, data, SLA+W)

   .undef   count
   .undef   ddram
   .undef   slarw
   .undef   linndx
   .undef   colndx

    pop     r18
    pop     r17
    pop     r16
    pop     r0
    ret



; Display_WriteLine                                                   13Aug2019
; -----------------------------------------------------------------------------
; Status:
;     Tested 13Aug2019
; Description:
;     Writes one line of text from SRAM to the display.
; Assumptions:
;     1.  SRAM text is stored in pages, each page representing one full
;         screen of characters. In this instance, that would be 80 characters,
;         4 lines of 20 characters each.
;     2.  X will point to the top of one of these pages.
;     3.  Line and Column indices are zero-based, and are used to calculate
;         offset values.
;     4.  DDRAM address offset and SRAM page offset are calculated differently.
;         The Display_SetPosition function handles DDRAM calculations while
;         the SRAM page offset is determined here.
; Parameters:
;     r20  - SLA+W for the targeted display
;            ( 0x78 | 0x7A )
;     r21  - line index (0, 1, 2, or 3)
;     X    - Points to a page of text in SRAM
; General-Purpose Registers:
;     Parameters - r20, r21, X
;     Constants  - rZero
;     Modified   - Y
; Constants (Non-Standard):
;     CTRL_DAT
;     LINELENGTH
; Functions Called:
;     Display_SetPosition  ( SLA+W, linndx, colndx )
;     TwiDw_FromSram       ( SLA+W, X, dscount, srcount )
; Macros Used:
;     pushdi - Pushes an immediate value onto the data stack
; Returns:
;     SREG_T - pass (0) or fail (1)
Display_WriteLine:
    push   r0
    push   r16
    push   r17
    push   r18
    push   r22
    push   XL
    push   XH

   .def    offset  = r0                     ; SRAM text page offset
   .def    dscount = r17                    ; Data Stack byte count
   .def    srcount = r18                    ; SRAM address byte count
   .def    linndx  = r21                    ; parameter: line index
   .def    colndx  = r22                    ; column index

    clr    colndx                           ; column index = 0
    rcall  Display_SetPosition              ; Display_SetPosition(SLA+W, linndx, colndx)
    brts   Display_WriteLine_exit           ; if (error) goto exit

    ldi    r16,    LINELENGTH               ; r16 = display line length
    mul    r16,    linndx                   ; offset = r16 x linndx
    add    XL,     offset                   ; X = X + offset
    adc    XH,     rZero

    pushdi CTRL_DAT                         ; Data Stack: push Control Byte (Data)
    ldi    dscount,  1                      ; data stack byte count = 1
    ldi    srcount,  LINELENGTH             ; SRAM byte count = LINELENGTH
    rcall  TwiDw_FromSram                   ; TwiDw_FromSram(SLA+W, X, dscount, srcount)

Display_WriteLine_exit:

   .undef  offset
   .undef  dscount
   .undef  srcount
   .undef  linndx
   .undef  colndx

    pop    XH
    pop    XL
    pop    r22
    pop    r18
    pop    r17
    pop    r16
    pop    r0
    ret


