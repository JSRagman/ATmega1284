;
; Project: ATmega1284Prototype1
;
; File:    constants.asm
; Created: 29Jun2019
; Updated: 10Aug2019
; Author:  JSRagman
; 

; Depends On:
;     1.  m1284(p)def.inc


.equ HSTACK_MAXSIZE = 128         ; Used to initialize the data stack.



; 8-Bit Timer/Counter 0 Constants:
; -------------------------------------------------------------------------------------
; TCCR0A  Timer/Counter 0 Control Register A

; 1. Waveform Generation Modes  (WGM02*, WGM01, WGM00).
;    * WGM02 is in TCCR0B.
;    WGM02 = 0
.equ TC0_WGM_NORM   =   0                    ; Mode 0: Normal
.equ TC0_WGM_CTC    =  (1<<WGM01)            ; Mode 2: CTC

; TCCR0B
; Timer/Counter 0 Clock Select
.equ TC0_CS_STOP     =  0                             ; No clock source (stopped)
.equ TC0CS_T0_F      = (1<<CS02)|(1<<CS01)            ; Ext. clock on T0, falling edge.

; TIMSK0
; Timer/Counter 0 Interrupt Mask Register
.equ TC0_OVERF = (1<<TOIE0)                 ; Overflow Enable
.equ TC0_CMPA  = (1<<OCIE0A)                ; Compare Match A Enable
.equ TC0_CMPB  = (1<<OCIE0B)                ; Compare Match B Enable



; TWI Constants
; -----------------------------------------------------------------------------

; TWI Bus Device Address
.equ DISPLAY_ADDR1 = 0x78                   ; character display 1
.equ DISPLAY_ADDR2 = 0x7A                   ; character display 2
.equ RTC_ADDR      = 0xDE                   ; real-time clock

; CPU Clock           = 8 MHz
; TWSR Prescaler bits = 0
.equ  TWBR_100KHz = 34
.equ  TWBR_400KHz =  2


; TWCR Constants
.equ  TWCR_GO_ACK   = (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
.equ  TWCR_GO_NACK  = (1<<TWINT)|(1<<TWEN)
.equ  TWCR_START    = (1<<TWINT)|(1<<TWEN)|(1<<TWSTA)
.equ  TWCR_STOP     = (1<<TWINT)|(1<<TWEN)|(1<<TWSTO)

; TWSR Constants
; TWSR: Prescaler Bits Mask
.equ  TWSR_PREMASK   = 0b_1111_1000    ; Masks out TWSR prescaler bits.

; TWSR: TWI Master Status Codes
.equ  TWSR_STA       = 0x08            ; START has been transmitted.
.equ  TWSR_RST       = 0x10            ; Repeated START has been transmitted.

; TWSR: Master Transmitter Status Codes
.equ  TWSR_SLAW_ACK   = 0x18           ; SLA+W transmitted, ACK received.
.equ  TWSR_SLAW_NACK  = 0x20           ; SLA+W transmitted, NACK received.
.equ  TWSR_DW_ACK     = 0x28           ; Data transmitted, ACK received.
.equ  TWSR_DW_NACK    = 0x30           ; Data transmitted, NACK received.

; TWSR: Master Receiver Status Codes
.equ  TWSR_SLAR_ACK   = 0x40           ; SLA+R transmitted, ACK received.
.equ  TWSR_SLAR_NACK  = 0x48           ; SLA+R transmitted, NACK received.
.equ  TWSR_DR_ACK     = 0x50           ; Data byte received, ACK returned.
.equ  TWSR_DR_NACK    = 0x58           ; Data byte received, NACK returned.



; NHD-0420CW Display Constants:
; -----------------------------------------------------------------------------

; Control Bytes
.equ CTRL_CMD     = 0x00          ; Control Byte (Command)
.equ CTRL_CMD_CO  = 0x80          ; Control Byte (Command) + Continue
.equ CTRL_DAT     = 0x40          ; Control Byte (Data)
.equ CTRL_DAT_CO  = 0xC0          ; Control Byte (Data)    + Continue

; Commands
.equ DISPLAY_CLEAR = 0x01
.equ DISPLAY_HOME  = 0x02
.equ DISPLAY_OFF   = 0x08
.equ DISPLAY_ON    = 0x0C
.equ SET_DDRAM     = 0b_1000_0000

; Cursor State Bit Patterns
.equ CURSOR_ON     = 0b_0000_0010
.equ CURSOR_BLINK  = 0b_0000_0011
.equ CURSOR_OFF    = 0

; Display Position Constants
.equ CHARCOUNT     = 80           ; Total number of display characters
.equ LINECOUNT     =  4           ; Number of display lines
.equ LINELENGTH    = 20           ; Length (characters) of one display line

.equ DDRAM_INCR = 0x20                    ; DDRAM Increment from one line to the next
.equ LINE_1     = 0x00    ; Line 1, Column 0
.equ LINE_2     = 0x20    ; Line 2, Column 0
.equ LINE_3     = 0x40    ; Line 3, Column 0
.equ LINE_4     = 0x60    ; Line 4, Column 0

; Digit Conversion
.equ DIGIT_ASC  = 0x30    ; Convert digit to ASCII character

; ASCII Characters
.equ ASC_COLON  = 0x3A
.equ ASC_DASH   = 0x2D
.equ ASC_FSLASH = 0x2F
.equ ASC_SPACE  = 0x20

; MCP7940N Real-Time Clock Constants:
; -----------------------------------------------------------------------------

.equ RTCBYTES = 30
.equ RTC_TIMEBYTES = 9

; Timekeeping Registers
.equ RTC_SEC        = 0x00
.equ RTC_MIN        = 0x01
.equ RTC_HOUR       = 0x02
.equ RTC_WKDAY      = 0x03
.equ RTC_DATE       = 0x04
.equ RTC_MTH        = 0x05
.equ RTC_YEAR       = 0x06
.equ RTC_CTRL       = 0x07
.equ RTC_TRIM       = 0x08

; Alarm Registers
.equ RTC_ALM0_SEC   = 0x0A
.equ RTC_ALM0_MIN   = 0x0B
.equ RTC_ALM0_HOUR  = 0x0C
.equ RTC_ALM0_WKDAY = 0x0D
.equ RTC_ALM0_DATE  = 0x0E
.equ RTC_ALM0_MTH   = 0x0F

.equ RTC_ALM1_SEC   = 0x11
.equ RTC_ALM1_MIN   = 0x12
.equ RTC_ALM1_HOUR  = 0x13
.equ RTC_ALM1_WKDAY = 0x14
.equ RTC_ALM1_DATE  = 0x15
.equ RTC_ALM1_MTH   = 0x16

.equ RTC_PWRDN_MIN  = 0x18
.equ RTC_PWRDN_HOUR = 0x18
.equ RTC_PWRDN_DATE = 0x18
.equ RTC_PWRDN_MTH  = 0x18

.equ RTC_PWRUP_MIN  = 0x1C
.equ RTC_PWRUP_HOUR = 0x1D
.equ RTC_PWRUP_DATE = 0x1E
.equ RTC_PWRUP_MTH  = 0x1F


; Register Bits
; ------------------------
; RTC_SEC
.equ   RTC_ST        = 7               ; RW  Oscillator Start bit
; RTC_HOUR
.equ   RTCHOUR_12    = 6               ; RW  Time Format bit
.equ   RTCHOUR_PM    = 5
; RTC_WKDAY
.equ   RTC_OSCRUN    = 5               ; R   Oscillator Status bit
.equ   RTC_PWRFAIL   = 4               ; RW  Power Failure bit
.equ   RTC_VBATEN    = 3               ; RW  Enable Battery bit
; RTC_CTRL
.equ   RTC_OUT       = 7               ; RW  General-Purpose Output logic
.equ   RTC_SQWEN     = 6               ; RW  Square Wave Output enable
.equ   RTC_ALM1EN    = 5               ; RW  Alarm 1 enable
.equ   RTC_ALM0EN    = 4               ; RW  Alarm 0 enable
.equ   RTC_EXTOSC    = 3               ; RW  External Oscillator enable
.equ   RTC_CRSTRIM   = 2               ; RW  Coarse Trim Mode enable
.equ   RTC_SQWFS1    = 1               ; RW  Square Wave Output Frequency Select 1
.equ   RTC_SQWFS0    = 0               ; RW  Square Wave Output Frequency Select 0
; RTC_ALM0_WKDAY
.equ   RTCALM0_POL   = 7               ; RW  Alarm Polarity for both Alarm 0 and Alarm 1
.equ   RTCALM0_MSK2  = 6               ; RW  Alarm 0 Mask Bits
.equ   RTCALM0_MSK1  = 5
.equ   RTCALM0_MSK0  = 4
.equ   RTCALM0_IF    = 3               ; RW  Alarm 0 Interrupt Flag
; RTC_ALM1_WKDAY
;      RTCALM1_POL   = 7               ; R   Set by the ALM0WKDAY register ALMPOL bit
.equ   RTCALM1_MSK2  = 6               ; Alarm 1 Mask Bits
.equ   RTCALM1_MSK1  = 5
.equ   RTCALM1_MSK0  = 4
.equ   RTCALM1_IF    = 3               ; Alarm 1 Interrupt Flag


; Square Wave Output
; RTC_CTRL SQWFS1:SQWFS0 Bits
;   00  1 Hz
;   01  4.096 kHz
;   10  8.192 kHz
;   11  32.768 kHz
.equ RTCSQW_1  = 0
.equ RTCSQW_4  = (1<<RTC_SQWFS0)
.equ RTCSQW_8  =                 (1<<RTC_SQWFS1)
.equ RTCSQW_32 = (1<<RTC_SQWFS0)|(1<<RTC_SQWFS1)


; RTCWKDAY Register Constants
.equ MONDAY    = 1
.equ TUESDAY   = 2
.equ WEDNESDAY = 3
.equ THURSDAY  = 4
.equ FRIDAY    = 5
.equ SATURDAY  = 6
.equ SUNDAY    = 7

; RTCMTH Register Constants
.equ JANUARY   = 1
.equ FEBRUARY  = 2
.equ MARCH     = 3
.equ APRIL     = 4
.equ MAY       = 5
.equ JUNE      = 6
.equ JULY      = 7
.equ AUGUST    = 8
.equ SEPTEMBER = 9
.equ OCTOBER   = 0x10
.equ NOVEMBER  = 0x11
.equ DECEMBER  = 0x12


; Startup Configuration and Time

.equ RTSEC   = 0
.equ RTMIN   = 0x5
.equ RTHOUR  = 0x18
.equ RTDAY   = (1<<RTC_VBATEN)|(FRIDAY)
.equ RTDATE  = 0x20
.equ RTMONTH = SEPTEMBER
.equ RTYEAR  = 0x19

