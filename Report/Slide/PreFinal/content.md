# Project statement

Within this project, student perform research and FPGA implementation of a RISC processing core
based on RISC-V ISA. From the results of implementation, student will perform validation and
performance testing for the core.

Objectives:

- Learn about the RISC-V-based processor model.
- Implementation of the processor using Verilog/SystemVerilog
- Propose validation method, perform validation
- Performance testing for the core through benchmarks

# Background

## RISC-V [@spec:riscv-isa-unpriv; @spec:riscv-isa-priv]

:::::::::::::: {.columns align=center .onlytextwidth}

::: {.column width="40%"}

![RISC-V logo](./image/RISC-V-logo.svg){width=100%}

:::

::: {.column width="60%"}

- RISC-V is an *open standard* with *royalty-free open-source licenses* RISC ISA
- A RISC-V ISA is defined as a base integer ISA, which must be present in any implementation, plus
optional extensions to the base ISA.
    - Currently, there are 4 ratified base ISA: `RV32I`, `RV32E`, `RV64I`, `RV64E`
    - Many extensions: multiply/divide, floating point, SIMD, atomic, ...
- RISC-V defines three privileges level: User (U), Supervisor (S), Machine (M)
    - Different modes allow program access to different facilities of the processor

:::

::::::::::::::

## EBAZ4205 - development board

:::::::::::::: {.columns align=center .onlytextwidth}

::: {.column width="55%"}

*EBAZ4205*:

- Attractive pricing (~1mil VND), used as personal tinkering and learning tool
- Zynq 7010 SoC
- PL will be used to implement design
- PS can help in porting the design to hardware

![Simplified model of the Zynq architecture [@book:the-zynq-book] \label{fig:zynq-model}](image/zynq_simple_model.png){height=25%}

:::

::: {.column width="45%"}

![EBAZ4205 front side PCB image [@gh:ebaz4205] \label{fig:ebaz4205-closeup}](image/EBAZ4205_PCB.jpg){height=75%}

:::

::::::::::::::

## Related work

:::::::::::::: {.columns align=top .onlytextwidth}

::: {.column width="33%"}

PicoRV32 [@gh:picorv32]

- Designed to be small with high maximum frequency (not performance)
- Configurable to RV32I\[M\]\[C\]
- With dual port register, 1 cycle memory access
    - 0.516 DMIPS/MHz (908 Dhrystones/Second/MHz)
    - Average CPI is 4.100 (Dhrystone)

:::

::: {.column width="33%"}

NEORV32 [@gh:neorv32]

- "is a customizable microcontroller-like system on chip (SoC) built around the NEORV32 RISC-V CPU
that is written in platform-independent VHDL" - full system
- For "small" configuration (`rv32i_Zicsr_Zifencei`): 0.3389 CoreMarks/MHz, 4.04 CPI

:::

::: {.column width="33%"}

VexRiscv [@gh:VexRiscv]

- a RISC-V implementation written in SpinalHDL, optimized for FPGA
- RV32I\[M\]\[A\]\[F\[D\]\]\[C\]
- VexRiscv small and productive (RV32I, 0.82 DMIPS/Mhz)
- VexRiscv full no cache (RV32IM, 1.21 DMIPS/Mhz 2.30 Coremark/Mhz)

:::

::::::::::::::

# Design

## Design scope

:::::::::::::: {.columns align=top .onlytextwidth}

::: {.column width="50%"}

*ISA scope*:

- `RV32I` base instruction set, but skip `FENCE`, `ECALL` and `EBREAK` instruction
- No privilege level, every thing run in "machine mode"
- No exception or trap. Only exception is the invalid instruction exception, which halt execution
and activate halt signal
- No memory misaligned access (assumed to never happen), simple memory access (in-order, 1 clock
cycle read/write)

:::

::: {.column width="50%"}

*Architectural*:

- 6-stage pipeline architecture
    - instruction fetch (IF1 + IF2), instruction decode (ID), execution (EX), memory operation (MEM)
    and write back (WB)
- Single-issue, in-order execution
- Simple memory hierarchy (no cache, TLB), memory accessed by 2 port (instruction read + data)

:::

::::::::::::::

## Design detail

![&nbsp;](./image/processor_pipeline.png){height=90%}

---

```{=latex}
\begin{table}[]
\centering
\begin{tabular}{|ccc|c|}
\hline
\multicolumn{1}{|c|}{\textbf{next\_inst}} & \multicolumn{1}{c|}{\textbf{curr\_inst}} & \textbf{prev\_inst} & \textbf{Action} \\ \hline
\multicolumn{1}{|c|}{x} & \multicolumn{1}{c|}{LOAD} & x & Stall \\ \hline
\multicolumn{1}{|c|}{x} & \multicolumn{1}{c|}{BRANCH} & x & Stall \\ \hline
\multicolumn{1}{|c|}{x} & \multicolumn{1}{c|}{JUMP} & x & Stall \\ \hline
\multicolumn{1}{|c|}{x} & \multicolumn{1}{c|}{x} & LOAD & Stall \\ \hline
\multicolumn{1}{|c|}{x} & \multicolumn{1}{c|}{x} & BRANCH & Stall \\ \hline
\multicolumn{1}{|c|}{x} & \multicolumn{1}{c|}{x} & JUMP & Stall \\ \hline
\multicolumn{1}{|c|}{\begin{tabular}[c]{@{}c@{}}rs1/rs2\\ dependent\end{tabular}} & \multicolumn{1}{c|}{Change rd} & x & Stall \\ \hline
\multicolumn{1}{|c|}{\begin{tabular}[c]{@{}c@{}}rs1/rs2\\ dependent\end{tabular}} & \multicolumn{1}{c|}{x} & Change rd & Stall \\ \hline
\multicolumn{3}{|c|}{Other} & No stall \\ \hline
\end{tabular}
\caption{Condition table showing specific conditions on previous, current and next instruction that lead to stall. "x" here denote don't care condition.}
\label{table:stall-condition}
\end{table}
```

---

```{=latex}
\begin{table}[]
\centering
\begin{tabular}{cccccc}
\textbf{IF1} & \textbf{IF2} & \textbf{ID} & \textbf{EX} & \textbf{M} & \textbf{WB} \\ \hline
\multicolumn{1}{c|}{J} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{J} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{x + 4} & \multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{J} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{x + 4} & \multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{J} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{n + 4} & \multicolumn{1}{c|}{n} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{J} &  \\
\multicolumn{1}{c|}{n + 8} & \multicolumn{1}{c|}{n + 4} & \multicolumn{1}{c|}{n} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & J
\end{tabular}
\caption{Evolution of the content of each pipeline stage when encountering JUMP instruction with "n" as the destination. "x" denotes the PC of the next instruction after JUMP that will not cause additional stall.}
\label{table:pipeline-stall-jump}
\end{table}
```

---

```{=latex}
\begin{table}[]
\centering
\begin{tabular}{cccccc|c}
\textbf{IF1} & \textbf{IF2} & \textbf{ID} & \textbf{EX} & \textbf{M} & \textbf{WB} &  \\ \cline{1-6}
\multicolumn{1}{c|}{B} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  &  \\
\multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{B} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  &  \\
\multicolumn{1}{c|}{x + 4} & \multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{B} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  &  \\
\multicolumn{1}{c|}{x + 4} & \multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{B} & \multicolumn{1}{c|}{} &  &  \\ \hline
\multicolumn{1}{c|}{x + 4} & \multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{B} &  & \multirow{2}{*}{\begin{tabular}[c]{@{}c@{}}Condition false\\ (don't branch)\end{tabular}} \\
\multicolumn{1}{c|}{x + 8} & \multicolumn{1}{c|}{x + 4} & \multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & B &  \\ \hline
\multicolumn{1}{c|}{n + 4} & \multicolumn{1}{c|}{n} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{B} &  & \multirow{2}{*}{\begin{tabular}[c]{@{}c@{}}Condition true\\ (branch)\end{tabular}} \\
\multicolumn{1}{c|}{n + 8} & \multicolumn{1}{c|}{n + 4} & \multicolumn{1}{c|}{n} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & B & 
\end{tabular}
\caption{Evolution of the content of each pipeline stage when encountering BRANCH instruction with "n" as the destination. "x" denotes the PC of the next instruction after BRANCH that will not cause additional stall.}
\label{table:pipeline-stall-branch}
\end{table}
```

---

```{=latex}
\begin{table}[]
\centering
\begin{tabular}{cccccc}
\textbf{IF1} & \textbf{IF2} & \textbf{ID} & \textbf{EX} & \textbf{M} & \textbf{WB} \\ \hline
\multicolumn{1}{c|}{R} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{D} & \multicolumn{1}{c|}{R} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{D} & \multicolumn{1}{c|}{R} & \multicolumn{1}{c|}{} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{D} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{R} & \multicolumn{1}{c|}{} &  \\
\multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{D} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{R} &  \\
\multicolumn{1}{c|}{x + 4} & \multicolumn{1}{c|}{x} & \multicolumn{1}{c|}{D} & \multicolumn{1}{c|}{NOP} & \multicolumn{1}{c|}{NOP} & R
\end{tabular}
\caption{Evolution of the content of each pipeline stage when encountering rd and rs1/rs2 dependent instructions. "R" denotes instruction that changes rd. "D" denotes dependent instruction.}
\label{table:pipeline-stall-dep}
\end{table}
```

# Validation and benchmark

:::::::::::::: {.columns align=top .onlytextwidth}

::: {.column width="50%"}

*Validation*:

- Hand-written test, manual checking
    - Do on an as-needed basis. Test inputs and results are not saved
    - Only done for some buggy module during debug

- Small program test
    - Do on an as-needed basis. Test inputs and results are not saved
    - For example adding number, jumping/branching
    - Testing general integration of the system

- RISCOF
    - Main test for design
    - Run test program and compare result to golden model (Spike or SAIL)
    - Passed the RV32I with no un-aligned memory access test suite (see Fig. \ref{fig:riscof-result})

:::

::: {.column width="50%"}

*Benchmark*:

- Aim to use Dhrystone
- The source is taken from PicoRV32[@gh:picorv32]. Some modification is added for
    - Printing with simple IO system
    - Triggering halt at the end by adding `unimp`
- Current Dhrystone result from simulation (see Fig.\ref{fig:dhrystone-result}) showed a CPI of
2.159, with Dhrystone per second per MHz value being 1192 (0.678 DMIPS).

:::

::::::::::::::

---

:::::::::::::: {.columns align=center .onlytextwidth}

::: {.column width="45%"}

![Browser report of running RISCOF, all test for RV32I without unaligned access had passed. \label{fig:riscof-result}](./image/riscof-verification-result.png) 

:::

::: {.column width="45%"}

![Excerpt from the output of running Dhrystone \label{fig:dhrystone-result}](./image/dhrystone-result-sim.png){height=80%}

:::

::::::::::::::

# Porting to Zynq

## System organization

:::::::::::::: {.columns align=center .onlytextwidth}

::: {.column width="45%"}

![Simplified system block diagram showing the PS/PL interconnect and main block. \label{fig:simplified-block-zynq}](./image/simplified-zynq-system.png) 

:::

::: {.column width="50%"}

The step for running Hubris with test program is as followed:

1. System initialization, Hubris reset is asserted.

2. PS take control of BRAM port B. The program content is loaded into BRAM by PS. PS return control
   of BRAM port B to Hubris. Reset to Hubris is deasserted. Hubris is set to run.

3. PS will wait for halt signal from Hubris, read through AXI GPIO module. Any IO signal from Hubris
   during the running process is also read.

4. On halt assertion, reset is assert - stopping Hubris. PS take control of BRAM port B. It can now
   read the resulting memory content from running the program on Hubris.

:::

::::::::::::::

## Result - calculating Fibonacci and sorting array

![Result of the Fibonacci-sort program. From left to right: memory symbols within the program and their addresses, BRAM content before running the program, BRAM content after running the program. \label{fig:fib-sort-board-result}](./image/fib-sort-board-result.png) 

## Result - Dhrystone

![Result from running the Dhrystone program. From left to right: memory symbols within the program and their addresses, BRAM content after running the program. \label{fig:dhrystone-board-result}](./image/dhrystone-board-result.png) 

---

- Two value that we need to read is `User_Inst` and `User_Time`, storing the number of instruction
and the number of clock cycle required to run those instruction respectively.

- Refer to Fig.\ref{fig:dhrystone-board-result}, we see that `User_Inst` have the value 0x000097a7
(38823 in decimal). And `User_Time` have the value 0x0001477a (83834 in decimal). 

- Compare the result with Fig.\ref{fig:dhrystone-result}, we see that both the simulation and the
hardware run return the same result. We can conclude that the performance metric between simulation
and hardware run will also be identical.

# Conclusion

```{=latex}
\begin{table}[]
\centering
\begin{tabular}{c|c|c|c|}
\cline{2-4}
\textbf{} & \textbf{Dhrystone} & \textbf{CoreMark} & \textbf{CPI} \\ \hline
\multicolumn{1}{|c|}{\textbf{PicoRV32}} & 0.516 DMIPS/MHz & x & 4.1 (Dhrystone) \\ \hline
\multicolumn{1}{|c|}{\textbf{NEORV32}} & x & 0.3389 CoreMarks/MHz & 4.04 (CoreMark) \\ \hline
\multicolumn{1}{|c|}{\textbf{\begin{tabular}[c]{@{}c@{}}VexRiscv small\\ and productive\end{tabular}}} & 0.82 DMIPS/MHz & x & x \\ \hline
\multicolumn{1}{|c|}{\textbf{\begin{tabular}[c]{@{}c@{}}VexRiscv full \\ no cache\end{tabular}}} & 1.21 DMIPS/MHz & 2.30 CoreMarks/MHz & x \\ \hline
\multicolumn{1}{|c|}{\textbf{Hubris}} & 0.678 DMIPS/MHz & x & 2.159 (Dhrystone) \\ \hline
\end{tabular}
\caption{Performance comparison of my design (Hubris) to other related work.}
\label{table:compare-perf}
\end{table}
```

---

:::::::::::::: {.columns align=center .onlytextwidth}

::: {.column width="45%"}

*Closing words*:

- With the completion of this project, I have develop a simple RISC-V-based processor with
implementation on FPGA. Testing application and their execution method has also been developed to
run within simulation and on hardware.

- While the core can not compete performance-wise when compared to existing projects, results show
promise for further improvements down the line.

:::

::: {.column width="45%"}

*Recommendation for future work*:

- Improving the current design with forwarding, sooner branch resolution and branch prediction.

- Add support for the Zicsr extension and the full machine level mode.

- Interrupt/exception handling.

- Implementing the multiply/divide extension (M extension). Adding support for floating point
arithmetic (F/D extension). Adding support for the atomic instruction (A extension). 

- Figure out memory hierarchy with more than one level. Add cache into the design. Design a more
general memory interface for the core (Wishbone, AXI).

- Moving to a more modern testbench - CoreMark.

:::

::::::::::::::

# References
