#include "omsp_de1soc.h"

// REGISTERS
//      Din  16-bit  write-only  address A0 (= byte address 140)
//      Cin  1-bit   write-only  address A1 (= byte address 142)
//      Dout 16-bit  read-only   address A2 (= byte address 144)
//      Cout 1-bit   read-only   address A3 (= byte address 146)
#define DIN       (*(volatile unsigned *)      0x140)
#define CIN       (*(volatile unsigned *)      0x142)
#define DOUT      (*(volatile unsigned *)      0x144)
#define COUT      (*(volatile unsigned *)      0x146)

// master sync
void SYNC1() {
    CIN   = 1;
    while (COUT != 1) ;
}

void SYNC0() {
    CIN   = 0;
    while (COUT != 0) ;
}

unsigned mymax(unsigned a, unsigned b) {
    unsigned r;

    DIN = a;
    SYNC1();

    DIN = b;
    SYNC0();

    SYNC1();
    r = DOUT;
    
    SYNC0();

    return r;
}

int main(void) {
  unsigned i, j;
  
  de1soc_init();
  
  while (1) {
    for (i = 0; i< 128; i++) {
      j = mymax(i, 64);
      //     j = i;
      de1soc_hexlo(j);
      de1soc_hexhi(i);
      long_delay(500);
    }
  }

  return 0;
}
 
