#!/usr/bin/env bash

# assemble and extract content for loading
riscv32-unknown-elf-gcc -T link.ld assembly.s -o assembly.o \
	-march=rv32i -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -g &&
	riscv32-unknown-elf-objcopy -O verilog \
		--only-section='.text*' --only-section='.data*' assembly.o assembly.load
