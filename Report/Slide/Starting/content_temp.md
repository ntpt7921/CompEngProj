# Self-introduction

:::::::::::::: {.columns}

::: {.column}

![My goofy face (ignore the messy room)](./image/goofy_face.png){width=50%}

:::

::: {.column}

- Like technology (computers are very cool)

- Making a "computer" has been my longest dream

- This project connects several parts that I enjoy
    - FPGA
    - Peeling back the veil - seeing how things work
    - Interaction between hardware and software (i.e. how to make computer go *fast*)
    - A nice opportunity to use what I have learn at Uni

:::

::::::::::::::


# Goals

Trying to make an as-complete-as-possible processor with all its components

\ 

:::::::::::::: {.columns align=top .onlytextwidth}

::: {.column}

**First part**:

- RISC-V as a ISA (standard, tool-chain, pre-existing implementations)

- Decide on the processor architecture
    - Main block/module
    - Implementation of those module

- Decide on performance evaluation method (benchmark)

:::

::: {.column}

**Second part**:

- Complete simulation, confirm design correctness

- Design optimization (what to improve?)

- Synthesis and test on Xilinx FPGA

:::

::::::::::::::

# Current progress

## Finding existing implementations

Promising project with good documentation, tool-chain and support:

- Rocket core

- BOOM core

Question: Scala?

Current plan: Generate example design and use it as reference.

## RISC-V Standard

- Known:
    - Base integer instruction set 32/64 bit

- Unknown:
    - Unprivileged vs. Privileged
    - Atomic extension
    - Compressed instruction extension
    - many more...

- Difficulties:
    - Current knowledge extent to the design of the ALU, don't know much about the memory subsystem
      (catching, TLB,...)
    - Multi core design (memory coherence, synchronization) is totally new
