# ATmega1284
Functions, Definitions, and Macros for the Atmel ATmega1284 MCU
## Files
- atm1284pDataStackMacros.asm
  - Macros for implementing a data stack using the Y register
- atm1284pDataXferMacros.asm
  - Macros useful for moving bytes about
- atm1284pTWIFuncs.asm
  - Functions and constants for TWI Master operation
- atm1284pmain.asm
  - Interrupt table and common initialization chores
## Status
Work in Progress... Functions are being added ~~daily~~ ~~often~~ every now and then.

Code in this repository has been handled with care but not tested. This message will change when testing is complete.

## Comments
Regarding the use of macros; I use macros heavily when a project is getting started and pushed into shape. As the project matures, macros are gradually eliminated unless they provide a serious readability benefit.
