# Cartesi Machine Benchmarks

This document presents performance benchmarks for the Cartesi Machine Emulator (CM) versions 0.18 and 0.19, compared with native execution and QEMU.

## Design philosophy

Before reading the benchmark results, it is essential to understand the design philosophy of the Cartesi Machine Emulator, it's architected with the following fundamental goals:
 1. **Low complexity**, for simplifying auditing processes and minimize the potential for errors.
 2. **Determinism**, for reproducible computations across different platforms.
 3. **Portability**, for compatibility with various architectures (e.g., zkVMs, RISC-V RV32I).
 4. **Security**, for providing strong guarantees of safe and correct execution of applications.
 5. **Verifiability**, for enabling verification of state transitions during on-chain fraud proofs.

To achieve these objectives, the emulator adopts specific architectural decisions:
- **No Just-In-Time (JIT) compilation**, avoiding complexities and security issues.
- **No floating-point hardware acceleration**, as it can lead to non-deterministic results across different hardware.
- **No multi-core interpretation**, also avoiding complexity and ensuring determinism.

Those architectural decisions impact performance compared to other emulators like QEMU, which employs JIT compilation and non-deterministic optimizations.

## Benchmark results

| Stress Benchmark | CM 0.19 | CM 0.18 | QEMU | `stress-ng` command |
|-|-|-|-|-|
| Heapsort | 12.81 ± 0.12 | 22.66 ± 0.36 | **6.67** ± 0.07 | `--heapsort 1 --heapsort-ops 5` |
| JPEG compression | 50.53 ± 1.89 | 76.74 ± 2.87 | **25.03** ± 0.94 | `--jpeg 1 --jpeg-ops 15` |
| Zlib compression | 7.82 ± 0.26 | 13.60 ± 0.45 | **4.01** ± 0.14 | `--zlib 1 --zlib-ops 30` |
| Quicksort | 18.38 ± 0.24 | 30.54 ± 0.20 | **10.29** ± 0.08 | `--qsort 1 --qsort-ops 8` |
| Hashing functions | 16.35 ± 0.38 | 29.98 ± 0.64 | **6.45** ± 0.14 | `--hash 1 --hash-ops 70000` |
| SHA-256 hashing | 41.48 ± 1.50 | 79.25 ± 3.26 | **19.87** ± 0.92 | `--crypt 1 --crypt-method SHA-256 --crypt-ops 500000` |
| Sieve Eratosthenes | 22.30 ± 0.58 | 41.48 ± 1.15 | **5.59** ± 0.15 | `--cpu 1 --cpu-method sieve --cpu-ops 600` |
| Fibonacci sequence | 15.52 ± 0.16 | 30.27 ± 0.30 | **4.82** ± 0.33 | `--cpu 1 --cpu-method fibonacci --cpu-ops 500` |
| Ackermann function | 26.80 ± 0.42 | 40.00 ± 0.63 | **8.32** ± 0.14 | `--cpu 1 --cpu-method ackermann --cpu-ops 700` |
| Collatz | 27.96 ± 0.63 | 53.12 ± 1.18 | **9.05** ± 0.34 | `--cpu 1 --cpu-method collatz --cpu-ops 700` |
| Queens | 12.37 ± 4.40 | 20.11 ± 0.42 | **4.90** ± 0.10 | `--cpu 1 --cpu-method queens --cpu-ops 1000` |
| Parity | 17.71 ± 0.36 | 31.82 ± 0.65 | **3.83** ± 0.09 | `--cpu 1 --cpu-method parity --cpu-ops 800` |
| Pi digits  | 77.95 ± 4.26 | 93.92 ± 5.14 | **36.36** ± 2.07 | `--cpu 1 --cpu-method pi --cpu-ops 80` |
| Fast Fourier Transform | 55.87 ± 1.34 | 89.72 ± 1.87 | **32.35** ± 0.81 | `--cpu 1 --cpu-method fft --cpu-ops 400` |
| Tree data structures | **6.59** ± 0.10 | 9.48 ± 0.15 | 6.67 ± 0.11 | `--tree 1 --tree-ops 2` |
| Binary trees | 10.07 ± 0.17 | 15.32 ± 0.28 | **6.33** ± 0.93 | `--tsearch 1 --tsearch-ops 20` |
| CPU `int8` arithmetic | 29.95 ± 0.92 | 59.24 ± 1.93 | **14.48** ± 0.45 | `--cpu 1 --cpu-method int8 --cpu-ops 700` |
| CPU `int32` arithmetic | 28.46 ± 0.88 | 54.60 ± 1.64 | **13.95** ± 0.42 | `--cpu 1 --cpu-method int32 --cpu-ops 700` |
| CPU `int64` arithmetic | 27.78 ± 0.36 | 54.35 ± 0.74 | **13.41** ± 0.17 | `--cpu 1 --cpu-method int64 --cpu-ops 700` |
| CPU `int128` arithmetic | 20.34 ± 0.33 | 43.47 ± 0.78 | **6.99** ± 0.11 | `--cpu 1 --cpu-method int128 --cpu-ops 800` |
| CPU `float32` arithmetic | 23.54 ± 0.34 | 35.03 ± 0.50 | **13.69** ± 0.20 | `--cpu 1 --cpu-method float --cpu-ops 600` |
| CPU `float64` arithmetic | 35.81 ± 0.83 | 53.57 ± 1.24 | **19.18** ± 0.46 | `--cpu 1 --cpu-method double --cpu-ops 300` |
| CPU looping | 11.14 ± 0.12 | 24.17 ± 0.28 | **3.08** ± 0.03 | `--cpu 1 --cpu-method loop --cpu-ops 800` |
| CPU NO-OP instruction | 16.77 ± 0.22 | 37.46 ± 0.49 | **2.13** ± 0.04 | `--nop 1 --nop-ops 100000` |
| CPU atomic operations | 4.79 ± 0.22 | 4.90 ± 0.23 | **1.64** ± 0.08 | `--atomic 1 --atomic-ops 500` |
| CPU branch prediction | **2.99** ± 0.01 | 5.40 ± 0.05 | 10.37 ± 0.13 | `--branch 1 --branch-ops 300000` |
| CPU cache trashing | 14.63 ± 0.07 | 21.42 ± 0.08 | **8.42** ± 0.06 | `--cache 1 --cache-ops 150000` |
| CPU cache line | 47.42 ± 2.10 | 79.50 ± 3.53 | **12.22** ± 0.55 | `--cacheline 1 --cacheline-ops 125` |
| CPU read cycle | 96.83 ± 10.5 | 162.35 ± 17.7 | **14.91** ± 1.64 | `--clock 1 --clock-ops 2000` |
| CPU pipeline execution | **18.74** ± 0.32 | 22.23 ± 0.38 | 83.88 ± 2.18 | `--goto 1 --goto-ops 500000` |
| CPU icache trashing | 26.87 ± 0.86 | **22.22** ± 0.70 | 37.19 ± 1.22 | `--icache 1 --icache-ops 200` |
| CPU icache branching | **1.16** ± 0.01 | 1.22 ± 0.03 | 8.23 ± 0.09 | `--far-branch 1 --far-branch-ops 200` |
| CPU registers read/write | 5.34 ± 0.05 | 12.57 ± 0.59 | **1.09** ± 0.01 | `--regs 1 --regs-ops 15000` |
| CPU function call | 24.83 ± 0.50 | 44.69 ± 0.76 | **17.29** ± 0.31 | `--funccall 1 --funccall-ops 400` |
| CPU bitwise arithmetic | 38.40 ± 1.37 | 78.63 ± 2.83 | **15.22** ± 0.55 | `--cpu 1 --cpu-method bitops --cpu-ops 400` |
| CPU page table and TLB | 39.22 ± 0.96 | 39.56 ± 0.98 | **23.72** ± 0.66 | `--pagemove 1 --pagemove-ops 30` |
| CPU TLB shootdown | 18.48 ± 1.36 | 24.40 ± 1.80 | **11.11** ± 0.96 | `--tlb-shootdown 1 --tlb-shootdown-ops 2000` |
| Memory copy | 33.76 ± 0.84 | 64.19 ± 1.59 | **10.77** ± 0.27 | `--memcpy 1 --memcpy-ops 80` |
| Memory read/write | 12.14 ± 1.02 | 21.58 ± 0.79 | **4.19** ± 0.17 | `--memrate 1 --memrate-bytes 2M --memrate-ops 400` |
| Memory mapping | 21.45 ± 0.42 | 23.17 ± 0.49 | **14.35** ± 0.29 | `--mmap 1 --mmap-bytes 96M --mmap-ops 4` |
| Memory and cache thrashing | **6.54** ± 0.13 | 9.55 ± 0.19 | 9.76 ± 0.15 | `--randlist 1 --randlist-ops 250` |
| Virtual memory page fault | 19.76 ± 1.08 | 26.53 ± 1.46 | **19.71** ± 1.08 | `--fault 1 --fault-ops 10000` |
| Virtual memory read/write | 21.46 ± 0.86 | 37.28 ± 1.49 | **12.46** ± 0.50 | `--vm 1 --vm-bytes 96M --vm-ops 20000` |
| Virtual memory addressing | 20.63 ± 0.29 | 37.71 ± 0.50 | **6.67** ± 0.38 | `--vm-addr 1 --vm-addr-ops 20` |
| Process forking | 9.61 ± 0.23 | 11.14 ± 0.21 | **7.99** ± 0.23 | `--fork 1 --fork-ops 2000` |
| Process context switching | 9.42 ± 1.23 | **6.40** ± 0.83 | 12.32 ± 1.61 | `--switch 1 --switch-ops 200000` |
| File read/write | 20.31 ± 0.43 | 34.64 ± 0.73 | **6.14** ± 0.15 | `--hdd 1 --hdd-ops 6000` |
| Threading | 101.03 ± 4.24 | 115.29 ± 4.83 | **19.06** ± 0.82 | `--pthread 1 --pthread-ops 1500` |
| Linux system calls | 14.94 ± 0.95 | 14.30 ± 0.90 | **1.54** ± 0.10 | `--syscall 1 --syscall-ops 4000` |
| Integer vector arithmetic | 118.93 ± 8.70 | 126.12 ± 9.22 | **19.95** ± 1.47 | `--vecmath 1 --vecmath-ops 100` |
| Integer wide vector arithmetic | 165.38 ± 16.0 | 207.88 ± 20.1 | **45.03** ± 4.39 | `--vecwide 1 --vecwide-ops 600` |
| Multi-precision floating-point | 38.58 ± 0.83 | 54.01 ± 1.16 | **13.90** ± 0.33 | `--mpfr 1 --mpfr-ops 200` |
| Floating-point square root | 183.36 ± 29.42 | 348.78 ± 55.96 | **63.78** ± 10.30 | `--cpu 1 --cpu-method sqrt --cpu-ops 20` |
| Floating-point FMA | 101.68 ± 5.88 | 135.14 ± 7.61 | **36.92** ± 2.09 | `--fma 1 --fma-ops 100000` |
| Floating-point math | 110.51 ± 8.23 | 222.73 ± 16.7 | **52.28** ± 3.88 | `--fp 1 --fp-ops 150` |
| Floating-point matmul | 38.12 ± 0.92 | 49.40 ± 1.78 | **15.53** ± 0.38 | `--matrix 1 --matrix-method prod --matrix-ops 150` |
| Floating-point trigonometric | 97.03 ± 8.68 | 122.02 ± 10.9 | **43.83** ± 4.31 | `--trig 1 --trig-ops 80` |
| Floating-point vector math | 61.55 ± 5.05 | 107.38 ± 8.81 | **26.70** ± 2.24 | `--vecfp 1 --vecfp-ops 200` |

- *Results are presented as **mean ± standard deviation**, representing the slowdown factor **relative to native execution**, meaning that **lower is better**.*
- *Bold entries indicate the best performance among the compared emulators.*
- *More information about each benchmark can be found at [stress-ng manpage](https://manpages.ubuntu.com/manpages/noble/en/man1/stress-ng.1).*

## Benchmark methodology

- Benchmarks were conducted using the `stress-ng` tool, a stress workload generator designed to exercise various system components.
- Results are normalized against native host execution; lower values indicate better performance relative to native execution.
- Benchmarks compare CM versions 0.18, 0.19, and QEMU, providing insights into performance evolution and relative standing.
- Single-core limitation enforced on both host and guest environments.
- Identical guest kernel and root filesystem images were used.
- Each test includes the overhead of booting and shutting down the guest Linux OS.
- Benchmarks were repeated for statistical significance.

## Performance analysis

### 1. **Areas where CM outperforms QEMU**
Despite generally slower performance due to its design philosophy, CM 0.19 notably outperforms QEMU in certain benchmarks:
- Tree data structures
- CPU branch prediction
- CPU pipeline execution
- CPU icache branching
- Memory and cache thrashing

These benchmarks are related to CPU branch prediction and CPU caching.
The emulator's simpler execution model may lead to more predictable branch behavior and consistent memory access patterns, giving it an advantage over QEMU's more complex and dynamic optimizations.

### 2. **Floating-point operations**
Higher latency is observed in all floating-point benchmarks, especially in the square root benchmark due to the iterative nature of its implementation.
This is a necessary trade-off to ensure determinism and portability through software-based emulation.

### 3. **Vector and SIMD operations**
Notable performance degradation is observed in benchmarks involving vector arithmetic and SIMD operations.
This is a necessary trade-off to favor portability and simplicity over platform-specific optimizations.

### 4. **Threading and parallelism**
Higher overhead in threading benchmarks indicates less efficient context switching and thread management, and the single-core interpretation design impacts the ability to leverage multi-threaded workloads.
This is a necessary trade-off due to the prioritized deterministic execution model.

## Comparative insights

### 1. **CM 0.19 vs. CM 0.18**
CM 0.19 shows significant performance improvements over CM 0.18 across most benchmarks, reflecting advancements in the emulator's interpreter optimizations.

### 2. **CM vs. QEMU**
While QEMU generally outperforms CM due to its use of JIT compilation and allowance for non-deterministic optimizations, CM maintains respectable performance, often within a 2x slowdown factor relative to QEMU, despite its stricter design constraints.

## Test environment

### Hardware configuration

- Host CPU: Intel Core i9-14900K (x86_64)
- Host RAM: 64GB
- Guest CPU: rv64imafdc_zicntr_zicsr_zifencei_zihpm
- Guest RAM: 128MB (guest machine)

### Software stack

- Host OS: Linux 6.6.65-1-lts
- Guest OS: Linux 6.5.13-ctsi-1
- QEMU: 9.1.2
- Cartesi Machine Emulator: 0.18.1 and 0.19.0 (pre-release)
- Compiler: GCC 14.2.1 20240910
- Benchmark tool: `stress-ng` 0.17.06
- Test date: 19/December/2024

## Recommendations

- Developers should profile their applications to identify performance-critical sections that may be impacted by the emulator's limitations.
- Optimization strategies should include minimizing heavy floating-point computations where possible and exploring algorithmic optimizations that reduce reliance on vector operations.
- Given the single-core execution model, applications designed for parallel execution may need adjustments to align with the emulator's capabilities.

By aligning application design with the strengths of the Cartesi Machine Emulator, developers can effectively leverage its secure and deterministic environment for a wide range of computational tasks.
