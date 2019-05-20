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
.DEF  r_zero     = r0

.DEF  r_result   = r19
.DEF  r_opstatus = r20




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


; TWI Operation Status Codes
; --------------------------
; Used with r_opstatus to localize TWI failure, when necessary.
; These codes are assigned arbitrarily here, and have no meaning
; outside this program.
.equ TWIP_ERR   = 0b_1000_0000    ; Bit 7 is the Error flag.
.equ TWIP_IDLE  = 0
.equ TWIP_START = 0b_0000_0001
.equ TWIP_SLAW  = 0b_0000_0010
.equ TWIP_SLAR  = 0b_0000_0011
.equ TWIP_TDATA = 0b_0000_0100
.equ TWIP_RDATA = 0b_0000_0101
.equ TWIP_STOP  = 0b_0000_0110



; I/O Register Usage:
; -----------------------------------------------------------------------------
; GPIOR0
;     For any TWI communication, GPIOR0 is expected to hold the TWI address of
;     the targeted slave along with a R/W bit (SLA+R/W).
; GPIOR1
;     In the event of a TWI communication failure, GPIOR1 preserves the state
;     of the TWI Status Register (TWSR) at the time of the failure.


; General-Purpose Register Usage:
; -----------------------------------------------------------------------------
; r_Zero
; r_opstatus
;     f_twi_dw_csegdata
;     f_twi_dw_csegstring
;     f_twi_dw_stack
; r_result
;     f_twi_dw_csegdata
;     f_twi_dw_csegstring
;     f_twi_dw_stack

; r0 (r_zero)
; r1
; r2
; r3
; r4
; r5
; r6
; r7
; r8
; r9
; r10
; r11
; r12
; r13
; r14
; r15

; r16
;     scratch
; r17
;     main
;     f_twi_dw_csegdata
;     f_twi_dw_csegstring
;     f_twi_dw_stack
; r18
;     f_twi_dw_csegdata
;     f_twi_dw_stack
; r19 (r_result)
; r20 (r_opstatus)
; r21
; r22
; r23
; r24
; r25

; X
; Y
;     main
;     data stack macros
;         m_peekd
;         m_peekdd
;         m_popd
;         m_pushd
;         m_pushdi
; Z
;     f_twi_dw_csegdata
;     f_twi_dw_csegstring




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

