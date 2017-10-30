#include "omsp_system.h"
#include "omsp_delay.h"

void short_delay(register unsigned int n) {
  // delay without using timer
  __asm__ __volatile__ (
       "1: \n"
       " dec %[n] \n"
       " jne 1b \n"
   : [n] "+r"(n));
}

void long_delay(register unsigned n) {
  while (n--) 
    short_delay(10000);
}
