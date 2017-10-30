all:
	@echo "Targets: "
	@echo "  compile    Compile software packages"
	@echo "  clean      Remove intermediate files"

clean:
	cd hal;            make clean; cd ..
	cd demode1soc;     make clean; cd ..
	cd timerde1soc;    make clean; cd ..
	cd maxmspdemo;     make clean; cd ..
	cd functionaltest; make clean; cd ..

compile:
	cd hal;            make compile; cd ..
	cd demode1soc;     make compile; cd ..
	cd timerde1soc;    make compile; cd ..
	cd maxmspdemo;     make compile; cd ..
	cd functionaltest; make compile; cd ..

