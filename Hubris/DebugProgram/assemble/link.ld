OUTPUT_ARCH( "riscv" )
ENTRY(start)

SECTIONS
{
  . = 0;
  .text : { *(.text); *(.text.*) }
  .bss : { *(.bss); *(.bss.*) }
  .data : { *(.data); *(.data.*) }
  .rodata : { *(.rodata); *(.rodata.*) }

  io_output_bytes_avai = 0x80000000;
  io_output_bytes = 0x80000004;

  end = .;
}

