;
; atm1284pConstants.asm
;
; Created: 4/30/2019
; Author: JSRagman
;
; Description:
;     Constant definitions and notes on register usage.



#ifndef _atm1284P_constant_defs_
#define _atm1284P_constant_defs_


; Named Registers:
; -----------------------------------------------------------------------------

.DEF  r_opstat = r25


; Named Register Bits
.equ  OPSTAT_ERR = 7


; System Constants:
; -----------------------------------------------------------------------------
.equ HSTACK_MAXSIZE = 64     ; Used to initialize the data stack.



; TWI Constants:
; -----------------------------------------------------------------------------

; TWCR
.equ  TWCR_GO    = (1<<TWINT)|(1<<TWEN)
.equ  TWCR_START = (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
.equ  TWCR_STOP  = (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)

; TWSR: Prescaler Bits Mask
.equ TWSR_PREMASK   = 0b_1111_1000  ; Masks out TWSR prescaler bits.

; TWSR: TWI Master Status Codes
.equ TWSR_START     = 0x08   ; START has been transmitted.
.equ TWSR_REPSTART  = 0x10   ; Repeated START has been transmitted.

; TWSR: Master Transmitter Status Codes
.equ TWSR_SLAWACK   = 0x18   ; SLA+W transmitted, ACK received.
.equ TWSR_SLAWNACK  = 0x20   ; SLA+W transmitted, NACK received.
.equ TWSR_DWACK     = 0x28   ; Data transmitted, ACK received.
.equ TWSR_DWNACK    = 0x30   ; Data transmitted, NACK received.

; TWSR: Master Receiver Status Codes
.equ TWSR_SLARACK   = 0x40   ; SLA+R transmitted, ACK received.
.equ TWSR_SLARNACK  = 0x48   ; SLA+R transmitted, NACK received.
.equ TWSR_DRACK     = 0x50   ; Data byte received, ACK returned.
.equ TWSR_DRNACK    = 0x58   ; Data byte received, NACK returned.


; TWI Process Codes                                                   23May2019
; -----------------------------------------------------------------------------
; Used with r_opstat to localize TWI failure, when necessary.
; These codes are assigned arbitrarily here, and have no meaning
; outside this program.
.equ TWIP_IDLE  = 0
.equ TWIP_START = 0b_0000_0001
.equ TWIP_SLARW = 0b_0000_0010
.equ TWIP_TDATA = 0b_0000_0011
.equ TWIP_RDATA = 0b_0000_0100
.equ TWIP_STOP  = 0b_0000_0101



; NHD-0420CW Display Constants:
; -----------------------------------------------------------------------------

; Control Bytes
.equ DISP_CMD   = 0x00  ; D/C# = 0, Control Byte - the next byte is a command.
.equ DISP_DATA  = 0x40  ; D/C# = 1, Control Byte - the next byte is data.

; Commands
.equ DISP_OFF = 0x08
.equ DISP_ON  = 0x0C

.equ DISP_CLEAR     = 0x01
.equ DISP_HOME      = 0x02
.equ DISP_SET_DDRAM = 0x80


; Cursor State Constants
.equ DISP_CURS_OFF   = 0
.equ DISP_CURS_ON    = 0b_0000_0010
.equ DISP_CURS_BLINK = 0b_0000_0011


; Display Position Constants
.equ DISP_LINE_1   = 0x00       ; DDRAM Line 1, Column 0
.equ DISP_LINE_INC = 0x20       ; DDRAM Increment to next line
.equ DISP_LINE_2   = 0x20       ; DDRAM Line 1, Column 0
.equ DISP_LINE_3   = 0x40       ; DDRAM Line 1, Column 0
.equ DISP_LINE_4   = 0x60       ; DDRAM Line 1, Column 0



; Local Register Aliases:
; -----------------------------------------------------------------------------
;
;   column      f_disp_setposition
;   counter     f_twi_dw_csegdata
;               f_twi_dw_stack
;   data        f_twi_dw_byte
;   expected    f_twi_slarw
;   line        f_disp_setposition
;   lineinc     f_disp_setposition
;   position    f_disp_setposition
;   result      f_twi_dw_byte
;               f_twi_dw_csegdata
;               f_twi_dw_csegstring
;               f_twi_dw_stack
;               f_twi_start
;               f_twi_slarw
;   slarw       f_twi_slarw
;   slaw        f_twi_dw_byte
;               f_twi_dw_csegdata
;               f_twi_dw_csegstring
;               f_twi_dw_stack
;   twicmd      f_twi_dw_csegdata
;               f_twi_dw_csegstring
;               f_twi_dw_stack





; PORT Definitions (40-DIP Package)
; -------------------------------------------------------------------------------------

; PORTA
;   PA0    PCINT0, ADC0
;   PA1    PCINT1, ADC1
;   PA2    PCINT2, ADC2
;   PA3    PCINT3, ADC3
;   PA4    PCINT4, ADC4
;   PA5    PCINT5, ADC5
;   PA6    PCINT6, ADC6
;   PA7    PCINT7, ADC7

; PORTB
;   PB0    PCINT8,  XCK0, T0
;   PB1    PCINT9,  CLK0, T1
;   PB2    PCINT10, AIN0, INT2
;   PB3    PCINT11, AIN1, OC0A
;   PB4    PCINT12,       OC0B, !SS
;   PB5    PCINT13, ICP3,       MOSI
;   PB6    PCINT14,       OC3A, MISO
;   PB7    PCINT15,       OC3B, SCK

; PORTC
;   PC0    PCINT16, SCL
;   PC1    PCINT17, SDA
;   PC2    PCINT18, TCK
;   PC3    PCINT19, TMS
;   PC4    PCINT20, TDO
;   PC5    PCINT21, TDI
;   PC6    PCINT22, TOSC1
;   PC7    PCINT23, TOSC2

; PORTD
;   PD0    PCINT24, RXD0, T3
;   PD1    PCINT25, TXD0
;   PD2    PCINT26, RXD1, INT0
;   PD3    PCINT27, TXD1, INT1
;   PD4    PCINT28, XCK1, OC1B
;   PD5    PCINT29,       OC1A
;   PD6    PCINT30,       OC2B, ICP
;   PD7    PCINT31,       OC2A



#endif

