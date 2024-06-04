OUTPUT_ARCH( "riscv" )
ENTRY(entry_point)

SECTIONS
{
  . = 0;
  .text : { 
      start*(.text)
      *(.text)
      *(.text.*) 
  }
  .bss : { *(.bss); *(.bss.*) }
  .data : { *(.data); *(.data.*) }
  .rodata : { *(.rodata); *(.rodata.*) }

  io_output_bytes_avai = 0x80000000;
  io_output_bytes = 0x80000004;
  io_input_bytes_avai = 0x80000008;
  io_input_bytes = 0x8000000c;

  end = .;
}

