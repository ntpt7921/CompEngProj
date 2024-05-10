USE_MYSTDLIB = 0
OBJS = main.o stdlib.o start.o
CFLAGS = -O3 -mabi=ilp32 -march=rv32i -DTIME -DRISCV -DUSE_MYSTDLIB -ffreestanding -nostdlib
TOOLCHAIN_PREFIX = /opt/riscv/bin/riscv32-unknown-elf-

run: main.hex
	../../RunProgram/hubris +bin=./main.hex

main.hex: main.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

main.elf: $(OBJS) link.ld
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,link.ld,-Map,main.map,--strip-debug -o $@ $(OBJS) -lgcc

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

clean:
	rm -rf *.o *.elf *.map *.hex

.PHONY: clean

