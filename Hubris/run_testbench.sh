#!/usr/bin/env bash

# assume this is run within the directory containing the source for Hubris
# this will compile the testbench with given name, store result into Compilation,
# run and print out the simulation result

# param:
#   $1 the testbench file name

tb_file=$(basename "$1")
tb_file_name="${tb_file%.*}"
compile_file="./Compilation/${tb_file_name}"

iverilog -o "$compile_file" $1 -c ./iverilog.cf &&
	vvp "$compile_file"
