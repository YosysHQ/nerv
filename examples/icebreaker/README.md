# SOC example for iCEBreaker

Instantiates [nervsoc](../../nervsoc.sv).

![iCEBreaker SOC](icebreaker_soc.png)

* [top.v](top.v) Connects clock input and 8 LEDs on the iCEBreaker and provides power on reset
* [sections.lds](sections.lds) sets flash and ram to 4k each.
* [firmware.s](firmware.s) initialises registers, copies data section, initialises bss and starts main
* [firmware.c](firmware.c) flashes the LEDs.
