# TWI Functions
## Description
Non-Interrupt based TWI functions for the ATmega1284P MCU
## Status
Updated 21Sep2019 - Tested... mostly
## File Contents
### twifuncs_basic.asm
- Twi_Connect
- Twi_Send
- Twi_Slarw
- Twi_Start
- TwiStop
- TwiWait
### twifuncs_write.asm
- TwiDw_FromDataStack
- TwiDw_FromEepData
- TwiDw_FromSram
- TwiDw_Send
- TwiDw_ToRegFromSram
- TwiDw_ToReg
### twifuncs_read.asm
- TwiDr_Receive
- TwiDr_RegByte
- TwiDr_RegConnect
- TwiDr_ToSram
