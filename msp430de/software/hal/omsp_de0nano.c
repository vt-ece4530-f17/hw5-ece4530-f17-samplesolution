#include "omsp_system.h"
#include "omsp_de0nano.h"

void de0nano_init() {
  WDTCTL = WDTPW | WDTHOLD;  // Disable watchdog timer
  P1DIR = 0xFF;  // P1 is output
  P2DIR = 0xFF;  // P2 is output
  P3DIR = 0xFF;  // P3 is output (HEX 0,1)
  P4DIR = 0xFF;  // P4 is output (HEX 2,3)
  P5DIR = 0xFF;  // P5 is output (HEX 4,5)
  uartinit();
  __no_operation();
  _enable_interrupts();
}

void de0nano_ledg(int v) {
  P1OUT = v;
}
