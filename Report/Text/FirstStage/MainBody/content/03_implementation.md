# Design and implementation

## Implementation scope

Now with sufficient knowledge about the RISC-V instruction set and its requirements, decision on
what to implement need to be made.

I have settled on the following:

- Implementing the `RV32I` base instruction set, but skip `FENCE`, `ECALL` and `EBREAK` instruction.
- Not implementing the RISC-V machine level privilege level instruction. So only using unprivileged
instruction.
- Exception and trap is not implemented. Except for the invalid instruction exception, which will
halt execution of the processor and activate a signal.
- Memory misaligned access is not allowed (and assumed to never happen).
- Design and test the RTL by simulation, with an abstracted memory disregarding actual FPGA detail.

Reasons for choosing the small base instruction set is due to implementation complexity that comes
with implementing the full machine privilege level requirement (more instructions, registers and
side effect that comes from interacting with said registers). Similar reasoning applies to exclusion
of exception and trap.

And because of time limit, I did not work on figuring out detail of the Zynq SoC platform upon which
the final design will run. That results in me not knowing the details of memory interfacing, IP
block/programmable resource usage related to the design. As such, memory within the design will be a
simple "virtual" register block of sufficient size to hold enough instructions and data, with
rudimentary read/write interface. Such a choice should ease RTL simulation of the design.

```{=latex}
\begin{landscape}
\begin{table}[]
\begin{tabular}{|r|c|c|c|c|c|c|c|c|}
\hline
inst{[}4:2{]} &
  \multirow{2}{*}{000} &
  \multirow{2}{*}{001} &
  \multirow{2}{*}{010} &
  \multirow{2}{*}{011} &
  \multirow{2}{*}{100} &
  \multirow{2}{*}{101} &
  \multirow{2}{*}{110} &
  \multirow{2}{*}{\begin{tabular}[c]{@{}c@{}}111\\ (\textgreater{}32b)\end{tabular}} \\ \cline{1-1}
inst{[}6:5{]} &        &          &          &          &        &                   &                &                    \\[10pt] \hline
00            & LOAD   & LOAD-FP  & custom-0 & MISC-MEM & OP-IMM & AUIPC             & OP-IMM-32      & 48b                \\[10pt] \hline
01            & STORE  & STORE-FP & custom-1 & AMO      & OP     & LUI               & OP-32          & 64b                \\[10pt] \hline
10            & MADD   & MSUB     & NMSUB    & NMADD    & OP-FP  & \textit{reserved} & custom-2/rv128 & 48b                \\[10pt] \hline
11            & BRANCH & JALR     & reserved & JAL      & SYSTEM & \textit{reserved} & custom-3/rv128 & \textgreater{}=80b \\[10pt] \hline
\end{tabular}
\caption{\label{table:opcode-map}Instruction opcode mapping for \texttt{RV32G} and \texttt{RV64G}}
\end{table}
\end{landscape}
```

## RV32I instruction description

This section's content is taken mainly from [@spec:riscv-isa-unpriv]. All image is taken from
[@spec:riscv-isa-unpriv-website].

Table \ref{table:opcode-map} show the mapping of opcode name to binary value. Of importance in our
case are `LOAD`, `STORE`, `BRANCH`, `JAL`, `JALR`, `OP-IMM`, `AUIPC` and `LUI` opcode.

Listings of all instructions implemented is showed in Fig. \ref{fig:instruction-listings}.

### Register set

The unprivileged state for the base integer ISA. For `RV32I`, the 32 `x` registers are each 32 bits
wide, i.e., $\text{XLEN}=32$. Register `x0` is hardwired with all bits equal to 0. General purpose
registers `x1`- `x31` hold values that various instructions interpret as a collection of Boolean
values, or as two’s complement signed binary integers or unsigned binary integers.

There is one additional unprivileged register: the program counter `pc` holds the address of the
current instruction.

### Instruction format

In the base `RV32I` ISA, there are four core instruction formats (R/I/S/U), as shown in Fig.
\ref{fig:instruction-format}. All are a fixed 32 bits in length and must be aligned on a four-byte
boundary in memory. An instruction-address-misaligned exception is generated on a taken branch or
unconditional jump if the target address is not four-byte aligned. *But such this exception trapping
will not be implemented*.

![RISC-V base instruction formats. Each immediate subfield is labeled with the bit position (`imm[x]`) in the immediate value being produced \label{fig:instruction-format}](img/rv32_instruction_formats.png)

There are a further two variants of the instruction formats (B/J) based on the handling of
immediates. The only difference between the S and B formats is that the 12-bit immediate field is
used to encode branch offsets in multiples of 2 in the B format. Instead of shifting all bits in the
instruction-encoded immediate left by one in hardware as is conventionally done, the middle bits
(`imm[10:1]`) and sign bit stay in fixed positions, while the lowest bit in S format (`inst[7]`)
encodes a high-order bit in B format.

![Types of immediate produced by RISC-V instructions. The fields are labeled with the instruction bits used to construct their value. Sign extension always uses `inst[31]`](img/rv32_immediate_produced.png)

### Integer computational instructions 

Most integer computational instructions operate on XLEN bits of values held in the integer register
file. Integer computational instructions are either encoded as register-immediate operations using
the I-type format or as register-register operations using the R-type format. The destination is
register rd for both register-immediate and register-register instructions. 

#### Integer Register-Immediate Instructions

![Format for the register-immediate arithmetic `RV32I`
instruction](img/rv32_compute_imme_arithmetic.png)

`ADDI` adds the sign-extended 12-bit immediate to register `rs1`. Arithmetic overflow is ignored and
the result is simply the low XLEN bits of the result.

`SLTI` (set less than immediate) places the value 1 in register `rd` if register `rs1` is less than
the sign-extended immediate when both are treated as signed numbers, else 0 is written to `rd`.
`SLTIU` is similar but compares the values as unsigned numbers (i.e., the immediate is first
sign-extended to `XLEN` bits then treated as an unsigned number)

`ANDI`, `ORI`, `XORI` are logical operations that perform bitwise AND, OR, and XOR on register `rs1`
and the sign-extended 12-bit immediate and place the result in `rd`.

![Format for the register-immediate shift `RV32I` instruction](img/rv32_compute_imme_shift.png)

Shifts by a constant are encoded as a specialization of the I-type format. The operand to be shifted
is in `rs1`, and the shift amount is encoded in the lower 5 bits of the I-immediate field. `SLLI` is
a logical left shift (zeros are shifted into the lower bits); `SRLI` is a logical right shift (zeros
are shifted into the upper bits); and `SRAI` is an arithmetic right shift (the original sign bit is
copied into the vacated upper bits).

![Format for the register-immediate load `RV32I` instruction](img/rv32_compute_imme_load.png)

`LUI` (load upper immediate) is used to build 32-bit constants and uses the U-type format. `LUI` places
the 32-bit U-immediate value into the destination register `rd`, filling in the lowest 12 bits with zeros.

`AUIPC` (add upper immediate to `pc`) is used to build `pc`-relative addresses and uses the U-type format.
`AUIPC` forms a 32-bit offset from the U-immediate, filling in the lowest 12 bits with zeros, adds this
offset to the address of the `AUIPC` instruction, then places the result in register rd.

#### Integer Register-Register Operations

RV32I defines several arithmetic R-type operations. All operations read the rs1 and rs2 registers as
source operands and write the result into register rd. The `funct7` and `funct3` fields select the type
of operation.

![Format for the register-register `RV32I` instruction](img/rv32_compute_reg_all.png)

`ADD` performs the addition of `rs1` and `rs2`. SUB performs the subtraction of `rs2` from `rs1`.
Overflows are ignored and the low XLEN bits of results are written to the destination `rd`. `SLT`
and `SLTU` perform signed and unsigned compares respectively, writing 1 to rd if `rs1` < `rs2`, 0
otherwise

`AND`, `OR`, and `XOR` perform bitwise logical operations.

`SLL`, `SRL`, and `SRA` perform logical left, logical right, and arithmetic right shifts on the
value in register `rs1` by the shift amount held in the lower 5 bits of register `rs2`.

#### NOP Instruction

The NOP instruction does not change any architecturally visible state, except for advancing the pc
and incrementing any applicable performance counters. `NOP` is encoded as `ADDI x0, x0, 0`.

### Control transfer instructions

#### Unconditional jumps

The jump and link (`JAL`) instruction uses the J-type format, where the J-immediate encodes a signed
offset in multiples of 2 bytes. The offset is sign-extended and added to the address of the jump
instruction to form the jump target address. Jumps can therefore target a ±1 MiB range. `JAL` stores
the address of the instruction following the jump (`pc`+4) into register `rd`.

![Format for the unconditional jumps `RV32I` instruction](img/rv32_uncond_jump.png)

The indirect jump instruction `JALR` (jump and link register) uses the I-type encoding. The target
address is obtained by adding the sign-extended 12-bit I-immediate to the register `rs1`, then
setting the least-significant bit of the result to zero. The address of the instruction following
the jump (`pc`+4) is written to register `rd`. Note that the `JALR` instruction does not treat the
12-bit immediate as multiples of 2 bytes, unlike the conditional branch instructions.

#### Conditional branches

All branch instructions use the B-type instruction format. The 12-bit B-immediate encodes signed offsets in multiples of 2 bytes. The offset is sign-extended and added to the address of the branch instruction to give the target address. The conditional branch range is ±4 KiB.

![Format for the conditional branches `RV32I` instruction](img/rv32_cond_branch.png)

Branch instructions compare two registers. `BEQ` and `BNE` take the branch if registers rs1 and rs2
are equal or unequal respectively. `BLT` and `BLTU` take the branch if `rs1` is less than `rs2`,
using signed and unsigned comparison respectively. `BGE` and `BGEU` take the branch if `rs1` is
greater than or equal to `rs2`, using signed and unsigned comparison respectively. Note, `BGT`,
`BGTU`, `BLE`, and `BLEU` can be synthesized by reversing the operands to `BLT`, `BLTU`, `BGE`, and
`BGEU`, respectively.

### Load and store instructions

`RV32I` is a load-store architecture, where only load and store instructions access memory and
arithmetic instructions only operate on CPU registers. `RV32I` provides a 32-bit address space that
is byte-addressed.

The EEI will define whether the memory system is little-endian or big-endian. In RISC-V, endianness
is byte-address invariant.

Byte-address invariant 

: In a system for which endianness is byte-address invariant, the following property holds: if a
byte is stored to memory at some address in some endianness, then a byte-sized load from that
address in any endianness returns the stored value.

![Format for the load and store `RV32I` instruction](img/rv32_load_store.png){width=100%}

Load and store instructions transfer a value between the registers and memory. Loads are encoded in
the I-type format and stores are S-type. The effective address is obtained by adding register `rs1`
to the sign-extended 12-bit offset. Loads copy a value from memory to register rd. Stores copy the
value in register `rs2` to memory.

The `LW` instruction loads a 32-bit value from memory into `rd`. `LH` loads a 16-bit value from
memory, then sign-extends to 32-bits before storing in `rd`. `LHU` loads a 16-bit value from memory
but then zero extends to 32-bits before storing in `rd`. `LB` and `LBU` are defined analogously for
8-bit values. The `SW`, `SH`, and `SB` instructions store 32-bit, 16-bit, and 8-bit values from the
low bits of register `rs2` to memory.

![Listings of all implemented instructions
\label{fig:instruction-listings}](img/rv32_detail_all.png){width=100%}

## Processor core

While there are many possible architectural decision that can affect performance metrics. Most of
those decision involves complicated implementation that is very unlikely to be completed in time.

There are various questions that to each I provided answer, leading to the choice of current design:

1. Should the core be single-cycle, or multi-cycle, or pipelined?

    At first glance, single-cycle seems very suitable, with straight forward design and easy
    implementation. But I think that the design is too simple for the project.

    Multi-cycle design is comparatively more complex than single cycle. But it comes with strict
    constraint on timing of each step (how many clock cycle should each step take), which is tool
    and device dependent. Such constraint creates challenge in verification of the design. I
    estimate that the amount of effort to design and implement multi-cycle design will be equivalent
    to doing the same for pipeline architecture.
    
    So in the end, I chose the 5-stage pipeline approach. With each stage corresponding to
    instruction fetch (IF), instruction decode (ID), execution (EX), memory operation (MEM) and
    write back (WB). Such a design can be found in the Rocket Core [@report:rocket-chip-generator].
    A very simple version has been design for educational purpose in [@book:comparch-riscv].

2. What about multiple-issue, out-of-order execution?

    These architectures are too complicated for me within the project's time constraint, so these
    design can not be done.

3. What about the memory subsystem (caching, TLB, prefetch,...)?

    Similarly to the previous question. These are too complex and most likely will not be done in
    time.

4. Relation with the ISA implemented?

    In practice, my processor architecture design is also affected by the ISA choice. ISA and
    architecture decision are made in tandem with each other.

    Some ISA features will become easier to implement with certain architecture design mentioned
    above. But the added hardware complexity means that most ISA features can not be implemented
    easily without enormous and involved architecture.

### Architectural design

Detail work on architecture is currently not finished, I will include parts that are done at the
moment.

Refer to Fig. \ref{fig:5stage-pipeline-arch}, showing the simplified block diagram and important
connection (data flow and control) between smaller functional block of my proposed processor
architecture. Some important properties are:

- Control hazard will be resolved by stalling the pipeline for the IF/ID pipeline registers.
Stalling implies freezing the current PC and inserting NOP into the pipeline from IF/ID pipeline
register.

- Data hazard will be resolved by stalling the pipeline for the IF/ID pipeline registers. Stalling
implies freezing the current PC and inserting NOP into the pipeline from IF/ID pipeline register.
Orchestrator will read the current and last 2 command from within the pipeline to determine whether
a stall is necessary. Effectively, there will always be enough inserted NOP between dependent
instruction to not cause hazard.

- Only the invalid instruction exception will be detected. On detection of a invalid instruction,
the processor will halt execution and pull halt signal high.

I will now elaborate on detail of each the main block:

- `Instruction Memory`: A large virtual set of register for now, read is performed asynchronously.
Synchronous write interface is provided but only used in loading new program and starting (e.g. only
use in testbench for simulation purpose). Instruction read ignore the 2 least-significant bit of the
provided address.

- `Data Memory`: Similar to `Instruction Memory`, but an addtional data write width input is added.
That signal is needed for sub-word (byte, half) write into the memory.

- `Register File`: Just a simple collection of register. It supports asynchronous dual port read,
synchronous single-port write. Write width input help in sub-word writting.

- `ControlSigGen`: Generate all the control signal (write enable, ALU source register choosing, ALU
control) for later pipeline stage of an instruction.

- `ImmGen`: Generate the appropriate immediate value corresponding to the current instruction. Take
part of the current instructions (taken from IF/ID pipeline register) to decide the correct
immediate.

- `Jump Branch Calculate`: Take in the instruction type and other value, calculate jump/branch
target address and whether branch condition is true.

- `ALU`: Perform arithmetic, comparison, logical operation and shift on provided value.

Currently, RTL implementation of this design is only half completed. So further detail is not
available. 

```{=latex}
\begin{sidewaysfigure}
\centering
\includegraphics{img/processor_5stage_pipeline.drawio.png}
\caption{Diagram for architectural design. Important signal is showed for each functional block.}
\label{fig:5stage-pipeline-arch}
\end{sidewaysfigure}
```

## Plan for verification

This section will describe my proposed plan for testing (verification) of my processor design. These
testing step will be performed each time the base design is change. Refer to Fig.
\ref{fig:test-procedure} for sequence of testing steps proposed.
 
![Proposed future test procedure \label{fig:test-procedure}](img/test_stages.png)

FPGA implementation is still unplanned for now. But I expect some changes to the design will be need
to make use of the device IP block for memory subsystem.

### Verification by custom Verilog/SystemVerilog testbench

Testbenches consist of non-synthesizable Verilog code which generates inputs to the design and
checks that the outputs are correct. Refer to Fig. \ref{fig:testbench-diagram}.

![Typical structure of testbenches
\label{fig:testbench-diagram}](img/testbench_diagram.svg){width=70%}

For smaller module, these input and output checker will be provided by me. That is because only I
know the functionality and purpose of those module. This is considered a *sanity check* to confirm
module behavior follow my intention.

For the final completed processing core, a more elaborate testing scheme will be required. Main step
involves:

1. Writting a test program exercising specific part of the design in assembly.
2. Run that program on a golden model simulator (Spike for example) and record the result.
3. Run RTL simulation for the testing program and record the result.
4. Compare result between golden model and my implementation.

### Verification by RISCOF - The RISC-V Compatibility Framework

RISCOF is a highly integrated testframe work for comformance testing of the RISC-V specification.
Its stated use case fit my project need. And the running procedure is not too complicated. 

With care full system interface design, I think this same framework can be used to test my design
both on the RTL simulation level and on the FPGA hardware level.

As my design implementation is not yet finished, there are no specific details on running RISCOF on
my design. For now, I will introduce the RISCOF and its execution flow.

Content of from the reset of this section is taken from [@doc:riscof].

#### About RISCOF

RISCOF - The RISC-V Compatibility Framework is a python based framework which enables testing of a
RISC-V target (hard or soft implementations) against a standard RISC-V golden reference model using
a suite of RISC-V architectural assembly tests.

The RISC-V Architectural Tests are an evolving set of tests that are created to help ensure that
software written for a given RISC-V Profile/Specification will run on all implementations that
comply with that profile.

These tests also help ensure that the implementer has both understood and implemented the
specification correctly.

The result that the architecture tests provide to the user is an assurance that the specification
has been interpreted correctly and the implementation under test (DUT) can be declared as RISC-V
Architecture Test compliant.

#### Execution flow

![Execution flow for RISCOF](img/riscof.png)

The input YAML is first validated using the RISCV-CONFIG tool to confirm the implementation choices
adhere to the those defined by the RISC-V ISA spec. The output of this is the
standardized/normalized YAML spec containing all the information of the implementation.

The normalized YAML is then fed to the Test Selector utility to filter and select tests from the
test-pool which are applicable to the implementation of the user. These selected tests are written
out in a YAML file and represent the test-list.

The normalized YAML is also fed into the reference model’s python plugin to configure the model to
mimic the implementation as close as possible.

The test-list is next forwarded to both, the user and reference defined python plugins, to initiate
compilation and execution of the tests on the respective platforms.

RISCOF, thus declares a test to have passed on the implementation only when the its signature
matches the signature produced by the reference model executing the same test.


## Plan for performance assessment

I plan to take a similar approach with the PicoRV32 project: writing a custom starting code, custom
library implementing needed function for the Dhrystone test.

To stop the execution, an invalid instruction will be added at the end of the test. Halting
execution and activate the halt signal. We will count the number of clock signal, coupled with
current clock speed to calculate the execution time of the benchmark program.

This method can be adapted to use both in RTL simulation and FPGA hardware implementation.
