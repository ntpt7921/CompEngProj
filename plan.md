# Plan for Computer Engineering Project

MDT-98: Develop a RISC-V-based processor on FPGA and testing applications

Instructor: Phạm Quốc Cường - cuongpham@hcmut.edu.vn 

Description: Within this project, student perform research and FPGA implementation of a RISC
processing core based on RISC-V ISA. From the results of implementation, student will perform
validation and performance testing for the core.

Objectives:
- Learn about the RISC-V-based processor model.
- Implementation of the processor using Verilog/SystemVerilog
- Propose validation method, perform validation
- Performance testing for the core through benchmarks

Requirements:
- First stage:
    - Report on the RISC-V processor model
    - Architectural design and implementation of main module
    - Report general direction for validation/benchmarks
- Second stage:
    - Complete simulation/validation of design
    - Design optimization, other architectural changes/comparisons
    - Compilation and running on Xilinx FPGA
    - Write project report

## Tentative plan

- Read through the specs
    - All important extensions, memory model, privileges model (focus on base extension)
    - Compile all command to implement
- Design 
    - Take ideas from existing design (Pico, Sordor, Rocket)
    - Make some decision
        - Single cycle, multi cycle, pipeline?
        - Multiple issue, out-of-order execution? (maybe later)
        - Memory subsystem? (maybe later)
- Implement 
    - Do each block (detail available after design)
    - Learn about the software stack (compiler, linker, assembler,...) for RISC-V
- Validation
    - Do each block (detail available after design)
    - Do integration test (detail available after design)
- Benchmark
    - Detail available after design

## Work done

- [ ] Read through the specs
    - [x] Unprivileged architecture (Vol.1)
        - [x] RV32IMAFD_Zicsr_Zifence_Zicntr_Zihpm as final target
        - [x] RV32I for now, AMFD_Zicsr_Zifence_Zicntr_Zihpm extension later
    - [ ] Privileged architecture (Vol.2)
- [ ] Design 
    - [ ] Take ideas from existing design (Pico, Sordor, Rocket)
    - [x] Make some decision
        - Pipeline 
        - Single issue, in-order for now (need it quick)
        - Complete the core first, memory subsystem for later
- [ ] Implement 
    - Do each block (detail available after design)
- [ ] Validation
    - Do each block (detail available after design)
    - Do integration test (detail available after design)
- [ ] Benchmark
    - Detail available after design

