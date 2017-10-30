#ifndef OMSP_DE1SOC_H
#define OMSP_DE1SOC_H

#include "omsp_system.h"
#include "omsp_delay.h"
#include "omsp_uart.h"

void de1soc_init();
void de1soc_ledr(int v);
void de1soc_hexlo(int v);
void de1soc_hexhi(int v);

#endif
