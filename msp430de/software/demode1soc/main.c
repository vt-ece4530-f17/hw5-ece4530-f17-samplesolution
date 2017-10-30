#include "omsp_de1soc.h"

char c16[]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

void myprintf(char *c) {
  while (*c)
    putchar(*c++);
}

int main(void) {
  register unsigned char k;
  int c = 0;
  
  de1soc_init();
  
  while (1) {
    k = 1;
    do {
      putchar(c16[((c>>12) & 0xF)]);
      putchar(c16[((c>>8 ) & 0xF)]);
      putchar(c16[((c>>4 ) & 0xF)]);
      putchar(c16[((c    ) & 0xF)]);
      putchar('\n');
      de1soc_ledr(k);
      de1soc_hexlo(c);
      de1soc_hexhi(c);
      long_delay(100);
      k <<= 1;
      c++;
    } while (k);
  }
  
  myprintf("exit program\n");
  
  dint();
  LPM0;
  
  return 0;
}
 
