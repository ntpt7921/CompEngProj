#!/usr/bin/env bash

# assemble and extract text section
riscv32-unknown-elf-as assembly.s -o assembly.o && riscv32-unknown-elf-objcopy -O verilog --only-section='.text*' assembly.o assembly.text

# run command
hubris +bin=assembly.text +regstat=regstat.json +memdump=mem.bin +sigdebug
