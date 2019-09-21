# ATmega1284
Functions, Definitions, and Macros for the Atmel ATmega1284 MCU.
## Mission Creep
### Newhaven Display NHD-0420CW OLED Character Display
Basic functions and definitions
### Microchip MCP7940N Real-Time Clock/Calendar
Basic functions and definitions (in progress)
## Purpose
If you see a function here that you like, take it, it's yours. This is not really meant to be an installable software package, even though all of it has been built and tested.

Note: The word "tested" means that a function was built, run, and behaved as expected. Nothing exhaustive.
## Tools
- Atmel Studio 7
- AVR Assembler
- AVR Dragon
## Status
- Re-organizing and applying polish. Well, re-organizing is something of an understatement. TWI and Display functions have changed quite a lot. Be patient.
- So. I became all wrapped around the axle with switch debouncing - there is more than one way of doing it. Who knew?
- But. Back on track. A real-time clock has been added - writing the code for it now.
## Pending
Schematic and board layout - this is still in flux.
## Comments
- Struggling with assembly language style and organization. I'll let you know when I reach enlightenment.
- There are no namespaces here. Every constant definition is global. Every function name, every address label, is global. This requires a serious coping mechanism.
- Deep breath. Count to 8.
