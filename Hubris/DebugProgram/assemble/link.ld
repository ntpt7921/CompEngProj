OUTPUT_ARCH( "riscv" )
ENTRY(entry_point)

SECTIONS
{
  . = 0;
  .text : { *(.text) }

  . = ALIGN(2M);
  .data : { *(.data) }
  _end = .;
}

