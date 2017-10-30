# base
MSPBASE=/cygdrive/c/ti/msp430_gcc/bin
# configuration
MSPCC=${MSPBASE}/msp430-elf-gcc
MSPCCFLAGS=-Wall -Os -fdata-sections -ffunction-sections -mmcu=msp430c1111 -IC:/ti/msp430_gcc/bin/../include
MSPAR=${MSPBASE}/msp430-elf-ar
MSPSIZE=${MSPBASE}/msp430-elf-size

all:
	@echo "Targets: "
	@echo "  compile    Compile software packages"
	@echo "  clean      Remove intermediate files"

compile: libomsp_de.a

omsp_de1soc.o: omsp_de1soc.c
	$(MSPCC) $(MSPCCFLAGS)  -c -o omsp_de1soc.o omsp_de1soc.c

omsp_de0nano.o: omsp_de0nano.c
	$(MSPCC) $(MSPCCFLAGS) -c -o omsp_de0nano.o omsp_de0nano.c

omsp_delay.o: omsp_delay.c
	$(MSPCC) $(MSPCCFLAGS) -c -o omsp_delay.o omsp_delay.c

omsp_uart.o: omsp_uart.c
	$(MSPCC) $(MSPCCFLAGS)  -c -o omsp_uart.o omsp_uart.c

libomsp_de.a: omsp_de0nano.o omsp_de1soc.o omsp_delay.o omsp_uart.o
	$(MSPAR) r libomsp_de.a omsp_de0nano.o omsp_de1soc.o omsp_delay.o omsp_uart.o
	$(MSPSIZE) *.o

clean:
	rm -f *~ *.o *.a
