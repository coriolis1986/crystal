objs = *.o
roms = *.nes

CA65 = ca65
LD65 = ld65
OUTPUT_ROM = output.nes
EMULATOR = /Applications/fceux.app/Contents/MacOS/fceux

clean:
	rm -f `find . -name '$(objs)'`
	rm -f `find . -name '$(roms)'`

asm:
	$(CA65) src/main.asm
	$(CA65) src/interrupts.asm

link:
	$(LD65) src/main.o src/interrupts.o -C nes.cfg -o $(OUTPUT_ROM)

execute:
	$(EMULATOR) output.nes

all: clean asm link execute