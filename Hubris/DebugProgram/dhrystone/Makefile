USE_MYSTDLIB = 0
OBJS = dhry_1.o dhry_2.o stdlib.o start.o
CFLAGS = -O3 -mabi=ilp32 -march=rv32i -DTIME -DRISCV -DUSE_MYSTDLIB -ffreestanding -nostdlib
TOOLCHAIN_PREFIX = /opt/riscv/bin/riscv32-unknown-elf-

run: dhry.hex
	../../RunProgram/hubris +bin=$<

all: dhry.elf dhry.hex program_content.h

program_content.h: dhry.bin
	xxd -i $< program_content.h

dhry.hex: dhry.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

dhry.bin: dhry.elf
	riscv32-unknown-elf-objcopy -O binary --only-section='*' $< $@

dhry.elf: $(OBJS) link.ld
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,link.ld,-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc
	chmod -x $@

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

dhry_1.o dhry_2.o: CFLAGS += -Wno-implicit-int -Wno-implicit-function-declaration

clean:
	rm -rf *.o dhry.elf dhry.map dhry.hex dhry.bin program_content.h

.PHONY: clean all

