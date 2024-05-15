#!/usr/bin/env bash

# assemble and extract content for loading
riscv32-unknown-elf-gcc -T link.ld assembly.s -o assembly.o \
	-march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g &&
	riscv32-unknown-elf-objcopy -O verilog \
		--only-section='*' assembly.o assembly.mem &&
	riscv32-unknown-elf-objcopy -O binary \
		--only-section='*' assembly.o assembly.bin &&
	xxd -i assembly.bin >program_content.h
