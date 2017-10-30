#include "omsp_de1soc.h"

unsigned count = 0;

unsigned TimerLap() {
  unsigned lap;
  TACTL &= ~(MC1 | MC0);
  lap = TAR - count;
  count = TAR;
  TACTL |= MC1;
  return lap;
}

void printfstring(char *c) {
  while (*c)
    putchar(*c++);
}

char c16[]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

void printfhex(int k) {
  putchar(c16[((k>>12) & 0xF)]);
  putchar(c16[((k>>8 ) & 0xF)]);
  putchar(c16[((k>>4 ) & 0xF)]);
  putchar(c16[((k    ) & 0xF)]);
}

int main(void) {
  int c1, c2, k=0;
  
  TACTL  |= (TASSEL1 | MC1 | TACLR);
  de1soc_init();
  
  while (1) {
    TimerLap();
    c1 = TimerLap();
    
    TimerLap();
    long_delay(20);
    c2 = TimerLap();
    
    de1soc_hexhi(c1);
    de1soc_hexlo(c2);
    de1soc_ledr(k);
    
    k++;
    long_delay(500);	
  }
  
  LPM0;
  
  return 0;
}
