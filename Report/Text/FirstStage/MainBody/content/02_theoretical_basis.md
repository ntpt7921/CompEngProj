# Background

## Introduction to RISC-V

![RISC-V logo](img/RISC-V-logo.svg){width=80%}

### What is RISC-V?

The description within this section is mostly taken from [@spec:riscv-isa-unpriv] and
[@enwiki:riscv].

RISC-V (pronounced "risk-five") is an *open standard* instruction set architecture (ISA) based on
established reduced instruction set computer (RISC) principles. Unlike most other ISA designs,
RISC-V is provided under *royalty-free open-source licenses*. Many companies are offering or have
announced RISC-V hardware; open source operating systems with RISC-V support are available, and the
instruction set is supported in several popular software toolchains.

The instruction set is designed for a wide range of uses. The base instruction set has a fixed
length of 32-bit naturally aligned instructions, and the ISA supports variable length extensions
where each instruction can be any number of 16-bit parcels in length. Optional extensions support
small embedded systems, personal computers, supercomputers with vector processors, and
warehouse-scale parallel computers. 

The project began in 2010 at the University of California, Berkeley, but many current contributors
are not affiliated with the university. With members in over 70 countries contributing and
collaborating to define RISC-V open specifications, RISC-V International, the non-profit managing
RISC-V, is currently headquartered in Switzerland.

The goals in defining the RISC-V, as stated in [@spec:riscv-isa-unpriv], includes:

- A completely open ISA that is freely available to academia and industry.

- A real ISA suitable for direct native hardware implementation, not just simulation or binary
translation.

- An ISA that avoids "over-architecting" for a particular microarchitecture style (e.g., microcoded,
in- order, decoupled, out-of-order) or implementation technology (e.g., full-custom, ASIC, FPGA),
but which allows efficient implementation in any of these.

- An ISA separated into a small base integer ISA, usable by itself as a base for customized
accelerators or for educational purposes, and optional standard extensions, to support general-
purpose software development.

- Support for the revised 2008 IEEE-754 floating-point standard. (ANSI/IEEE Std 754-2008)

- An ISA supporting extensive ISA extensions and specialized variants.

- Both 32-bit and 64-bit address space variants for applications, operating system kernels, and
hardware implementations.

- An ISA with support for highly parallel multicore or manycore implementations, including
heterogeneous multiprocessors.

- Optional variable-length instructions to both expand available instruction encoding space and to
support an optional dense instruction encoding for improved performance, static code size, and
energy efficiency.

- A fully virtualizable ISA to ease hypervisor development.

- An ISA that simplifies experiments with new privileged architecture designs

### Why choose RISC-V?

Given those underlining principles of RISC-V. There are several reasons as to why I choose RISC-V as
the ISA for this project.

- **Commercial ISAs have complicated licensing**: Commercial vendors of processor intellectual
property (IP), charge royalties for the use of their designs, patents and copyrights. They also
often require non-disclosure agreements before releasing documents that describe their designs'
detailed advantages. In many cases, they never describe the reasons for their design choices. Where
as RISC-V was begun with a goal to make a practical ISA that was open-sourced, usable academically,
and deployable in any hardware or software design without royalties. Also, justifying rationales for
each design decision of the project are explained, at least in broad terms. [@enwiki:riscv]

The freedom in usage (RISC-V ISA specifications is licensed under the Creative Commons Attribution
4.0 International License) is one very strong reason for using RISC-V; as appose to MIPS, a ISA very
similar to RISC-V, which only recently goes open-source in 2018 [@news:mips-go-os] - probably as a
reaction to popularity of RISC-V's approach.

- As state in [@spec:riscv-isa-unpriv], **Popular commercial ISAs are complex**: The dominant
commercial ISAs (x86 and ARM) are both very complex to implement in hardware to the level of
supporting common software stacks and operating systems. Worse, nearly all the complexity is due to
bad, or at least outdated, ISA design decisions rather than features that truly improve efficiency.

The simplicity in the RISC-V ISA design for the base instruction set is an advantages. By having its
root in academia, RISC-V may serve very well within a undergraduate project. Justifying rationales
provided with the RISC-V ISA specification serve as useful pointer to deeper design problems and
considerations.

- **RISC-V is substantially popular**: Many project has sprung up with RISC-V as its base, both
commercially and academically. To build a large, continuing community of users and thereby
accumulate designs and software, the RISC-V ISA designers intentionally support a wide variety of
practical use cases The requirements of a large base of contributors is part of the reason why
RISC-V was engineered to address many possible uses.

This is one of the biggest reason pushing me into choosing RISC-V as the instruction for this
project. The availability of existing project, coupled with support from popular free and open
source toolchains are very important basis for a inexperienced student project.

## RISC-V ISA overview

This whole section is adapted from [@spec:riscv-isa-unpriv; @spec:riscv-isa-priv].

A RISC-V ISA is defined as a base integer ISA, which must be present in any implementation, plus
optional extensions to the base ISA. The base integer ISAs are very similar to that of the early
RISC processors except with no branch delay slots and with support for optional variable-length
instruction encodings. A base is carefully restricted to a minimal set of instructions sufficient to
provide a reasonable target for compilers, assemblers, linkers, and operating systems (with
additional privileged operations), and so provides a convenient ISA and software toolchain
"skeleton" around which more customized processor ISAs can be built.

`XLEN`

: use to refer to the width in bit of the integer register, and consequently the address space

Although it is convenient to speak of the RISC-V ISA, RISC-V is actually a family of related ISAs,
of which there are currently four base ISAs. Each base integer instruction set is characterized by
the width of the integer registers and the corresponding size of the address space and by the number
of integer registers. Currently, there are 4 ratified base integer ISA: `RV32I`, `RV64I`, `RV32E`,
`RV64E`. Work for the 128-bit address space version is currently being work on.

Table: All the included instruction base and their status [@spec:riscv-isa-unpriv]

| Base     | Version |  Status  |
|----------|:-------:|:--------:|
| `RVWMO`  |   2.0   | Ratified |
| `RV32I`  |   2.1   | Ratified |
| `RV64I`  |   2.1   | Ratified |
| `RV32E`  |   2.0   | Ratified |
| `RV64E`  |   2.0   | Ratified |
| `RV128I` |   1.7   | Draft    |

Table: Address space width and number of register for each currently ratified base

| Base    | Register/address width (`XLEN`) | # of register |
|---------|:-------------------------------:|:-------------:|
| `RV32I` |              32-bit             |       32      |
| `RV64I` |              64-bit             |       32      |
| `RV32E` |              32-bit             |       16      |
| `RV64E` |              64-bit             |       16      |

To support more general software development, a set of standard extensions are defined to provide
integer multiply/divide, atomic operations, and single and double-precision floating-point
arithmetic. The base integer ISA is named "I" (prefixed by RV32 or RV64 depending on integer
register width), and contains integer computational instructions, integer loads, integer stores, and
control-flow instructions. The standard integer multiplication and division extension is named "M",
and adds instructions to multiply and divide values held in the integer registers. The standard
atomic instruction extension, denoted by "A", adds instructions that atomically read, modify, and
write memory for inter-processor synchronization. The standard single-precision floating-point
extension, denoted by "F", adds floating-point registers, single-precision computational
instructions, and single- precision loads and stores. The standard double-precision floating-point
extension, denoted by "D", expands the floating-point registers, and adds double-precision
computational instructions, loads, and stores. 

Table: All the included instruction extensions and their status [@spec:riscv-isa-unpriv]

| Extension     | Version |  Status  |
|---------------|:-------:|:--------:|
| `M`           |   2.0   | Ratified |
| `A`           |   2.1   | Ratified |
| `F`           |   2.2   | Ratified |
| `D`           |   2.2   | Ratified |
| `Q`           |   2.2   | Ratified |
| `C`           |   2.0   | Ratified |
| `Counters`    |   2.0   | Ratified |
| `P`           |   0.2   | Draft    |
| `V`           |   1.0   | Ratified |
| `Zicsr`       |   2.0   | Ratified |
| `Zifencei`    |   2.0   | Ratified |
| `Zihintpause` |   2.0   | Ratified |
| `Zihintntl`   |   1.0   | Ratified |
| `Zam`         |   0.1   | Draft    |
| `Zfa`         |   1.0   | Ratified |
| `Zfh`         |   1.0   | Ratified |
| `Zfhmin`      |   1.0   | Ratified |
| `Zfinx`       |   1.0   | Ratified |
| `Zdinx`       |   1.0   | Ratified |
| `Zhinx`       |   1.0   | Ratified |
| `Zhinxmin`    |   1.0   | Ratified |
| `Zmmul`       |   1.0   | Ratified |
| `Ztso`        |   1.0   | Ratified |


Beyond the base integer ISA and these standard extensions, it is rare that a new instruction will
provide a significant benefit for all applications, although it may be very beneficial for a certain
domain

### RISC-V software execution environments and harts

Hart 

:   refer to hardware thread

    "A RISC-V- compatible core might support multiple RISC-V-compatible hardware threads, or harts,
    through multithreading." [@spec:riscv-isa-unpriv]

Execution environment (interface)

:  A RISC-V execution environment interface (EEI) defines the initial state of the program, the
number and type of harts in the environment including the privilege modes supported by the harts,
the accessibility and attributes of memory and I/O regions, the behavior of all legal instructions
executed on each hart (i.e., the ISA is one component of the EEI), and the handling of any
interrupts or exceptions raised during execution including environment calls. 

The implementation of a RISC-V execution environment can be pure hardware, pure software, or a
combination of hardware and software. Examples of execution environment implementations include:

- "Bare metal" hardware platforms where harts are directly implemented by physical processor threads
and instructions have full access to the physical address space. The hardware platform defines an
execution environment that begins at power-on reset.

    *For implementation, we utilize a simple bare metal platform, with simple handling of any
    exceptions.*

- RISC-V operating systems that provide multiple user-level execution environments by multiplexing
user-level harts onto available physical processor threads and by controlling access to memory via
virtual memory.

- RISC-V emulators, such as Spike, QEMU or rv8, which emulate RISC-V harts on an underlying x86
system, and which can provide either a user-level or a supervisor-level execution environment.

From the perspective of software running in a given execution environment, a hart is a resource that
autonomously fetches and executes RISC-V instructions within that execution environment. In this
respect, a hart behaves like a hardware thread resource even if time-multiplexed onto real hardware
by the execution environment. Some EEIs support the creation and destruction of additional harts,
for example, via environment calls to fork new harts.

The execution environment is responsible for ensuring the eventual forward progress of each of its
harts. For a given hart, that responsibility is suspended while the hart is exercising a mechanism
that explicitly waits for an event, such as the wait-for-interrupt instruction defined
[@spec:riscv-isa-priv]; and that responsibility ends if the hart is terminated. The following events
constitute forward progress:

- The retirement of an instruction.
- A trap.
- Any other event defined by an extension to constitute forward progress.

### Privileged/unprivileged architecture

At any time, a RISC-V hardware thread (hart) is running at some privilege level encoded as a mode in
one or more CSRs (control and status registers). Three RISC-V privilege levels are currently defined
as shown 

Table: RISC-V privilege levels

| Level | Encoding |       Name       | Abbreviation |
|:-----:|:--------:|:----------------:|:------------:|
|   0   |   `00`   | User/Application |       U      |
|   1   |   `01`   |    Supervisor    |       S      |
|   2   |   `10`   |    *Reserved*    |              |
|   3   |   `11`   |      Machine     |       M      |

Privilege levels are used to provide protection between different components of the software stack,
and attempts to perform operations not permitted by the current privilege mode will cause an
exception to be raised. These exceptions will normally cause traps into an underlying execution
environment.

The machine level has the highest privileges and is the only mandatory privilege level for a RISC-V
hardware platform. Code run in machine-mode (M-mode) is usually inherently trusted, as it has low-
level access to the machine implementation. M-mode can be used to manage secure execution
environments on RISC-V. User-mode (U-mode) and supervisor-mode (S-mode) are intended for
conventional application and operating system usage respectively

Each privilege level has a core set of privileged ISA extensions with optional extensions and
variants. For example, machine-mode supports an optional standard extension for memory protection.

Implementations might provide anywhere from 1 to 3 privilege modes trading off reduced isolation for
lower implementation cost

Table: Supported combination of privilege modes

| Number of levels   | Supported Modes |                Intended Usage               |
|:------------------:|-----------------|:-------------------------------------------:|
|          1         | M               | Simple embedded systems                     |
|          2         | M, U            | Secure embedded systems                     |
|          3         | M, S, U         | Systems running Unix-like operating systems |

A hart normally runs application code in U-mode until some trap (e.g., a supervisor call or a timer
interrupt) forces a switch to a trap handler, which usually runs in a more privileged mode. The hart
will then execute the trap handler, which will eventually resume execution at or after the original
trapped instruction in U-mode. The RISC-V privileged architecture provides flexible routing of traps
to different privilege layers.

### RISC-V memory

A RISC-V hart has a single byte-addressable address space of $2^{\text{XLEN}}$ bytes for all memory
accesses. A *word* of memory is defined as 32 bits (4 bytes). Correspondingly, a *halfword* is 16
bits (2 bytes), a *doubleword* is 64 bits (8 bytes), and a *quadword* is 128 bits (16 bytes). The
memory address space is circular, so that the byte at address $2^{\text{XLEN}} - 1$ is adjacent to
the byte at address zero. Accordingly, memory address computations done by the hardware ignore
overflow and instead wrap around modulo $2^{\text{XLEN}}$.

The execution environment determines the mapping of hardware resources into a hart’s address space.
Different address ranges of a hart’s address space may (1) be vacant, or (2) contain main memory, or
(3) contain one or more I/O devices. Reads and writes of I/O devices may have visible side effects,
but accesses to main memory cannot. Although it is possible for the execution environment to call
everything in a hart’s address space an I/O device, it is usually expected that some portion will be
specified as main memory. *For implementation, we will not have any IO device, so all memory
available will be map as containing main memory.*

Executing each RISC-V machine instruction entails one or more memory accesses, subdivided into
implicit and explicit accesses. For each instruction executed, 

- an implicit memory read (instruction fetch) is done to obtain the encoded instruction to execute.
Many RISC-V instructions perform no further memory accesses beyond instruction fetch. 

- an explicit memory access can be caused by load and store instructions - performing an explicit
read or write of memory at an address determined by the instruction.

The memory accesses (implicit or explicit) made by a hart may appear to occur in a different order
as perceived by another hart or by any other agent that can access the same memory. This perceived
reordering of memory accesses is always constrained, however, by the applicable memory consistency
model. The default memory consistency model for RISC-V is the RISC-V Weak Memory Ordering (RVWMO).
Optionally, an implementation may adopt the stronger model of Total Store Ordering (TSO). Since the
RVWMO model is the weakest model allowed for any RISC-V implementation, software written for this
model is compatible with the actual memory consistency rules of all RISC-V implementations.

While very important for memory consistency and coherence in the context of out-of-order execution,
multi-core, share memory system, RVWMO does not hold that much importance in my implementation
(single-core, in-order execution, no cache). So detail of this model will be omitted.

### Exceptions, Traps, and Interrupts

We use the term exception to refer to an unusual condition occurring at run time associated with an
instruction in the current RISC-V hart. We use the term interrupt to refer to an external
asynchronous event that may cause a RISC-V hart to experience an unexpected transfer of control. We
use the term trap to refer to the transfer of control to a trap handler caused by either an
exception or an interrupt.

The instruction descriptions in following chapters describe conditions that can raise an exception
during execution. The general behavior of most RISC-V EEIs is that a trap to some handler occurs
when an exception is signaled on an instruction (except for floating-point exceptions, which, in the
standard floating-point extensions, do not cause traps). The manner in which interrupts are
generated, routed to, and enabled by a hart depends on the EEI.

How traps are handled and made visible to software running on the hart depends on the enclosing
execution environment. From the perspective of software running inside an execution environment,
traps encountered by a hart at runtime can have four different effects:

- Contained trap: The trap is visible to, and handled by, software running inside the execution
environment. For example, in an EEI providing both supervisor and user mode on harts, an ECALL by a
user-mode hart will generally result in a transfer of control to a supervisor-mode handler running
on the same hart. Similarly, in the same environment, when a hart is interrupted, an interrupt
handler will be run in supervisor mode on the hart.

- Requested trap: The trap is a synchronous exception that is an explicit call to the execution
environment requesting an action on behalf of software inside the execution environment. An example
is a system call. In this case, execution may or may not resume on the hart after the requested
action is taken by the execution environment. For example, a system call could remove the hart or
cause an orderly termination of the entire execution environment.

- Invisible trap: The trap is handled transparently by the execution environment and execution
resumes normally after the trap is handled. Examples include emulating missing instructions,
handling non-resident page faults in a demand-paged virtual-memory system, or handling device
interrupts for a different job in a multiprogrammed machine. In these cases, the software running
inside the execution environment is not aware of the trap (we ignore timing effects in these
definitions).

- Fatal trap: The trap represents a fatal failure and causes the execution environment to terminate
execution. Examples include failing a virtual-memory page-protection check or allowing a watchdog
timer to expire. Each EEI should define how execution is terminated and reported to an external
environment.

## Hardware

For now, I will provide my own hardware FPGA board. If any problem occurred in the future, I would
switch to using the school provided board.

### EBAZ4205

Information about the board within this section is taken from [@gh:ebaz4205].

EBAZ4205 (Fig. \ref{fig:ebaz4205-closeup}) is mining board used in Ebang Ebit E9+ Bitcoin miner machine. The
specifics of the manufacturer and its previous usage before being bought by me is unknown. Due to
extremely attractive pricing (50$ USD) and acceptable hardware specification, I use this board as a
personal tinkering and learning tool.

This board features 

- Zynq 7010 SoC (XC7Z010CLG400, dual-core Cortex A9 and Artix-7 FPGA). See Fig. \ref{fig:zynq-7010-closeup}
- 256MB DDR3 memory
- 128MB NAND Flash memory
- 10/100MBit Ethernet 

![EBAZ4205 front side PCB image \label{fig:ebaz4205-closeup}](img/EBAZ4205_PCB.jpg)

![Close up of Zynq-7010 on EBAZ4205 \label{fig:zynq-7010-closeup}](img/EBAZ4205_Zynq.jpg){width=80%}

### The Zynq-7000 SoC family

Content of this section is taken from [@spec:zynq-7000-overview] and [@book:the-zynq-book].

Zynq comprises two main parts: a Processing System (PS) formed around a dual-core ARM Cortex-A9
processor, and Programmable Logic (PL), which is equivalent to that of an FPGA. It also features
integrated memory, a variety of peripherals, and high-speed communications interfaces.

The PL section is ideal for implementing high-speed logic, arithmetic and data flow subsystems,
while the PS supports software routines and/or operating systems, meaning that the overall
functionality of any designed system can be appropriately partitioned between hardware and software.
Links between the PL and PS are made using industry standard Advanced eXtensible Interface (AXI)
connections (see Fig. \ref{fig:zynq-model}).

![Simplified model of the Zynq architecture [@book:the-zynq-book] \label{fig:zynq-model}](img/zynq_simple_model.png){width=80%}

The Zynq-7000 family offers the flexibility and scalability of an FPGA, while providing performance,
power, and ease of use typically associated with ASIC and ASSPs.

Since this project stage is not focused on running my design on EBAZ4205, I will not go into more
detail for this device.

