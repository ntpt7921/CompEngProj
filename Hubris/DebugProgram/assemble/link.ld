OUTPUT_ARCH( "riscv" )
ENTRY(entry_point)

SECTIONS
{
  . = 0;
  .text : { *(.text) }

  . = ALIGN(2M);
  .data : { *(.data) }

  io_output_bytes_avai = 0x80000000;
  io_output_bytes = 0x80000004;

  _end = .;
}

