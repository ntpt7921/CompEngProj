# Introduction

## Project description and requirements [^project-desc-note]

[^project-desc-note]: translated from the Vietnamese description of my assigned project

Within this project, student perform research and FPGA implementation of a RISC processing core
based on RISC-V ISA. From the results of implementation, student will perform validation and
performance testing for the core.

Objectives:

- Learn about the RISC-V-based processor model.
- Implementation of the processor using Verilog/SystemVerilog
- Propose validation method, perform validation
- Performance testing for the core through benchmarks

Requirements:

- First stage (*current*):
    - Report on the RISC-V processor model
    - Architectural design and implementation of main module
    - Report general method for application/performance benchmark
- Second stage:
    - Complete simulation/validation of implementation
    - Design optimization, other architectural changes/comparisons
    - Compilation and running on Xilinx FPGA
    - Write project report

## Specific goals for the first stage

### RISC-V processor model

To serve the purpose of implementing the processor core, knowing about the processor model proposed
by RISC-V specification is crucial. I aim to explore the following topic:

1. RISC-V processor model

    - Privileged/unprivileged architecture: Overview of privilege levels
    - Memory model
    - Exception, trap and interrupt

2. Within the scope of the unprivileged instruction [@spec:riscv-isa-unpriv], various extensions
   comprising `RV32G`

    - `RV32I`` base instruction
    - Multiplication/division extension (`M`)
    - Floating point extension (`F` and `D`)
    - Atomic memory operation extension (`A`)
    - Instruction memory write to instruction fetch synchronization extension (`Zfencei`)
    - Control status register instruction (`Zicsr`)

I will then assess and choose an appropriate set of instruction and supported privilege level
that my implementation will try to support (or what mode/instruction will be omitted).

### Architecture design and implementation

After choosing the scope of instruction to be implemented. The next step is design and
implementation.

There are many decision involved in implementing a processor core, affected by the requirement
imposed by the instruction set, or by other metrics such as performance, energy consumption,
resources used within the FPGA,... Ease of implementation (implementation complexity) must also be
considered, since I am inexperienced with this type of work and process.

Of all the listed metrics above, I will concentrate on the performance metric and the implementation
complexity metric. Both of these will have an impact on my available design space.

For this phase, I plan to finish selecting the design of the processor core. RTL implementation will
be done for some main module of the design. Some preliminary verification is also done on
constituent modules.

Detail of FPGA implementation will be left to the second part of this project.

### Validation and benchmark strategy

The design and implementation of the processor core can be completed, but there are no guarantees
that it is correct. We need to have some method to ascertain that our implementation conform with
the RISC-V specification. Such is the need for a validation method.

For this phase, I aim to explore available methods of verification. And to propose verification
strategy for my processor design.

## Structure of this report

This report will closely match the goals stated in [previous
section](#specific-goals-for-the-first-stage-goals-specific). Each following section will describe
either: background knowledge I gather during researching about topics related to any of the goals,
or detail of my work in designing and implementing the processor core.

Since one of many objectives for this project is to run the design on a FPGA. I added a small
section introducing the hardware that I will use.

At the end, there will be a chapter dedicated to discussing my current progress and future plan for
the next phase of this project.
