#include "omsp_de1soc.h"

// REGISTERS
#define NN        (*(volatile unsigned *)      0x140)
#define DD        (*(volatile unsigned *)      0x142)
#define CIN       (*(volatile unsigned *)      0x144)
#define QQ        (*(volatile unsigned *)      0x146)
#define RR        (*(volatile unsigned *)      0x148)
#define COUT      (*(volatile unsigned *)      0x14A)

// master sync
void SYNC1() {
  CIN   = 1;
  while (COUT != 1) ;
}

void SYNC0() {
  CIN   = 0;
  while (COUT != 0) ;
}

void myintdiv(int _n, int _d, int *_q, int *_r) {

  NN = _n;
  DD = _d;
  
  SYNC1();

  SYNC0();
  
  *_q = QQ;
  *_r = RR;
}

char c16[]={'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

void printfhex(int k) {
  putchar(c16[((k>>12) & 0xF)]);
  putchar(c16[((k>>8 ) & 0xF)]);
  putchar(c16[((k>>4 ) & 0xF)]);
  putchar(c16[((k    ) & 0xF)]);
  long_delay(300);
}

int main(void) {
  int i, q, r;
  
  de1soc_init();
  
  while (1) {
    for (i = 10000; i<10256; i++) {
      myintdiv(i, i+30, &q, &r);

      printfhex(i);
      putchar(' ');
      printfhex(i+30);
      putchar(' ');
      printfhex(q);
      putchar(' ');
      printfhex(r);
      putchar('\n');
      
    }
  }

  return 0;
  
}
 
//int main() {
//  int q, r, d, n;
//  printf(" N D Q R\n");
//  for (n=1000; n<3000; n++) {
//    for (d=n+1; d<=3000; d++) {
//      // make a division
//      intdiv(n, d, &q, &r);
//      // show result
//      printf("# %4x %4x %2x %4x\n", n, d, q, r);
//      // verify result
//      assert((n * 256) == (d * q + r));
//    }
//  }
//  return 0;
//}
