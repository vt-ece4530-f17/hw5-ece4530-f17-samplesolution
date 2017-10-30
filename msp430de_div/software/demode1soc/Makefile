# base
MSPBASE=/cygdrive/c/ti/msp430_gcc/bin
# configuration
MSPCC=${MSPBASE}/msp430-elf-gcc
MSPCCFLAGS=-Wall -Os -fdata-sections -ffunction-sections -mmcu=msp430c1111 
MSPLDFLAGS=-mmcu=msp430c1111 -Wl,--gc-sections -minrt -T linker.x 
MSPOBJCOPY=${MSPBASE}/msp430-elf-objcopy
MSPOBJDUMP=${MSPBASE}/msp430-elf-objdump
MSPSIZE=${MSPBASE}/msp430-elf-size

all:
	@echo "Targets: "
	@echo "  compile    Compile software packages"
	@echo "  clean      Remove intermediate files"

compile: led.bin

main.o: main.c
	$(MSPCC) -IC:/ti/msp430_gcc/bin/../include -I../hal $(MSPCCFLAGS) -c $< -o $@ 
	$(MSPSIZE) $@

led.elf: main.o
	$(MSPCC)  $(MSPLDFLAGS) -L../hal  $< -lomsp_de -o $@ 
	$(MSPSIZE) $@
	${MSPOBJDUMP} -dSt led.elf >led.lst

led.bin: led.elf
	$(MSPOBJCOPY) -I elf32-msp430 -O binary led.elf led.bin

clean:
	rm -rf led.elf *.o *~ led.bin 

