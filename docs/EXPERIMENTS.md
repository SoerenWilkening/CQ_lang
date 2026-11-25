# Experiments and measurements

What the compiler has been run on, and how long it took. The numbers are dated measurements, not
promises; the user manual is [`MANUAL.md`](MANUAL.md).

## Lowering times

Time spent in the lowering, on one x86-64 Mac:

| What | Functions | Time | Result |
|---|---|---|---|
| The C standard library, all nine root lists | 387 | 3 min | `libqc.a`, 79 MB |
| SoftFloat, `float`, `double`, `_Float16`, `__bf16` | 673 | 4 min | `libqsoftfloat.a`, 57.4 MB |
| SoftFloat, `long double` | 182 | 1 min 15 s | `libqsoftfloat_f80.a`, 17.8 MB |

## Existing C projects

[`experiments/`](../experiments/) lowers existing libraries unchanged (C, and one in C++), as lowered libraries (`cqcc --cq-lib`)
that link against the precompiled C standard library and SoftFloat. Nothing in a project is rewritten
and the standard library is not recompiled per project. Sources, builds and lowered archives are not
in the repository; each project's `build_lib.sh` fetches and builds them.

Every function is also lowered on its own, under every arrangement of classical and quantum arguments
a library exports and with its callees as calls (`experiments/per_function.sh`), so one failure does
not hide another:

| Project | Functions | Lower on their own | Time | Notes |
|---|---|---|---|---|
| C standard library (musl) | 387 | 387, as the lowered library | 3 min | 1,524 exported versions |
| SoftFloat (the float templates) | 855 | 855, as two lowered libraries | 5 min | |
| GSL 2.8 | 55 sub-libraries | all 55 as lowered libraries | 35 min | 2.1 GB of archives; `specfunc` takes 6 min 54 s |
| SQLite 3 (core) | 1,542 | 1,542 | 12 min | 4 exceed the sweep's 2-minute limit and lower on their own in 86 to 192 s (`sqlite3BtreeInsert`, `sqlite3EndTable`, `sqlite3Pragma`, `sqlite3VdbeExec`, the bytecode interpreter) |
| GLPK 5.0 (without the two minisat files) | 1,256 | 1,256 | 4 min | `_glp_zlib_inflate` takes 19 s |
| GMP 6.3.0 (generic C) | 650 | 650, and as one lowered library | 2 min; the library 16 min | the library has 571 exported roots, 617 MB; `__gmpn_div_q` takes 10 s |
| [ABC](https://github.com/maksimKorzh/abc), a chess engine | 37 | 37 | 2 s | |
| [Game of Life](https://github.com/bluekeybo/GameOfLife) | 7 | 7 | 1 s | |
| [TinyEMU](https://github.com/dearchap/tinyemu) 2018-09-23, a RISC-V system emulator | 581 | 581, as four lowered libraries | 4 min | the 128-bit RISC-V interpreter takes 44 s on its own |
| [TinyCC](https://github.com/TinyCC/tinycc) 0.9.28rc, a C compiler | 276 | 276, as one lowered library | 3 min | `tcc_relocate_ex` takes 25 s on its own; `decl_initializer_alloc` exceeds the sweep's limit and takes 111 s on its own |
| [Stockfish](https://github.com/official-stockfish/Stockfish) 17, a chess engine in C++ | 707 | 707, as one lowered library | 2 min 30 s | the library build takes 2 min 8 s |

The times are for the whole project on one x86-64 Mac with the current pass: the libraries as built, the
other projects as the sweep over their functions, six at a time with a limit of 2 minutes per function.
The five functions over that limit were lowered on their own with a limit of 20 minutes. Counts are from
2026-11-25, with rule 6's in-place update.

"Lowers" means the pass produced a module that passes its structural verifier. The lowered
libraries are not checked against the C programs: the checker runs programs, and the reduced cases
under `experiments/repro-round*/` are what it has run. Two of them are known faults:
`repro-round8/asrt5.c` (a wrong result: an assert on a classical condition in the body of a loop with
a quantum exit tested at its header) and `repro-round8/exitdead_leak.c` (a rail left live at exit).
A third is in SoftFloat: `fma` with only some operands quantum lowers to a version that reads an
invalid register (`experiments/arrangements/partial/fma_q1.linked.ll`); no float template calls it.

TinyEMU (`experiments/tinyemu/`: `build.sh`, then `build_lib.sh`) is the whole emulator without SDL and
the network filesystem: the RISC-V CPU at 32, 64 and 128 bits, its software floating point, the PC and
virtio devices and the SLIRP network stack. Its sources are unchanged; `compat/` supplies the Linux
headers macOS lacks. It is lowered as four libraries, one per RISC-V CPU width and one for the rest,
which call each other through `--cq-ext-roots`; a program (`drv.c`, one `add_sf64` on a quantum operand)
links them with TinyEMU's ordinary build, the lowered C library and the backend, and runs. Three softfp
functions (`add_sf64` in every rounding mode, `mul_sf32`, `sqrt_sf32`) pass the checker against the C
program on about 2,300 samples each (`spot.c`). The POSIX functions and system calls TinyEMU calls
outside the C library are effect entries (rule 16), classical calls the backend performs; with a
quantum argument the backend defers them and the program reads 0 as their result. `POSIX.md` has the
details.

TinyCC (`experiments/tinycc/`: `build.sh`, then `build_lib.sh`) is the compiler as its Makefile's one-file build
(`ONE_SOURCE`) for the native x86-64 Mach-O target, without its runtime library `lib/` (assembly). Its 276
functions lower on their own, and it lowers as one library (37 exported roots, 80 MB, 3 to 6 minutes, 1.7 GB at
most). A program (`drv.c`, `tcc_basename` on an 8-character path with one quantum character) links it with
TinyCC's ordinary build, the lowered C library and the backend. Its run does not get through the function: at
the default cutoff K = 4 the `strlen` loop over the path is cut after 4 trips and the shot ends there (52
gates), and at K = 16 the pointer walking back from the end is a quantum address of 46 bits, above the
backend's limit of 16. Three functions pass the checker against the C program (`spot.c`, about 2,300 samples
each): `btype_size`, `pstrcat` and `tcc_basename`, the last with one character of the path quantum and never the
terminator. `tcc_basename` first returned 0 where C returns 6: a pointer read after a loop with a quantum exit
kept the last trip's address, a fault older than this experiment and fixed with it. The other 273 functions are
only shown to lower, and compiling a program whose source text is quantum (`tcc_compile_string`) was not run.

Stockfish (`experiments/stockfish/`: `build.sh`, then `build_lib.sh`) is the engine at tag `sf_17` with the
flags of its Makefile's `general-64` target: no SIMD, `-fno-exceptions`, the network files not embedded. Its
sources are unchanged. The one module has 707 functions and no instruction a C program does not also produce.
All 707 lower on their own under every arrangement a library exports, and it lowers as one library (214
exported roots, 109 MB, 2 min 8 s). One function, `Tablebases::rank_root_moves`, first hit an internal error:
its `{ i64, i32 }` result packs several fields into the `i64`; that is fixed.
Five programs (`spot.cpp`: queen attacks from a quantum square, `Position::pseudo_legal`, `see_ge`,
`attackers_to` and `UCIEngine::to_cp` on a quantum argument) link with the lowered library, Stockfish's
ordinary build, the lowered C library and the replay backend. The classical setup (`Bitboards::init`,
`Position::init`, `Position::set`) is a native object: in the lowered program, rule 27 has no flow, so once
`main` passes a rail to a library function every library call in the module is a declared clone, the setup
before `cq_theta` included, and it ran as lowered code without finishing. With the setup native, `to_cp`
returns the C++ program's value for all three inputs (10 s each). The other four stop at once: the replay
backend aborts a bus access whose address has more than 16 quantum bits (the magic-bitboard lookups, whose
address comes from a pointer loaded at a quantum index), and `pseudo_legal`'s lowered code calls templates of
widths `i10` and `i26`, which BACKEND_ABI does not list yet.

A function whose body is in the program is lowered once per mix of classical and quantum arguments
it is called with. ABC and Game of Life were also lowered that way, one generated program per mix
except all-classical (`experiments/mask_sweep.sh`, run before the library arrangements existed): ABC
171 of 171 (`encode_move`, 7 arguments, 127 of them), Game of Life 79 of 79. Each needed one source
change. ABC's argument-less functions are declared `f()`,
which C17 reads as unprototyped; they now say `(void)`. Game of Life's display loop `while (1)` has no
exit; it is now a loop of 1000 generations.

Gate counts come from the recommended backend's counting gate backend (`-lcq_gates_count`, results
in the file named by `CQ_COUNT`), which counts gates, depth and qubits without building a circuit.
The drivers in `experiments/gsl/easy/` call one GSL function from precompiled, all-quantum GSL with
one `double` built from two qubits, at the default loop cutoff 4. These numbers are preliminary:
they were taken on intermediate builds of the pass, before the argument arrangements (every argument
was passed as a quantum register), and are not validated.

| GSL call | Gates |
|---|---|
| `gsl_stats_max` | 0.86 M |
| `gsl_sort` (4 elements) | 3.6 M |
| `gsl_fft_complex_radix2_forward` (4 points) | 6.0 M |
| `cblas_ddot` | 9.3 M |
| `cblas_dgemm` | 10.9 M |
| `cblas_dgemv` | 15.6 M |
| `gsl_poly_solve_quadratic` | 16.7 M |
| `gsl_poly_eval` | 20.5 M |
| `gsl_hypot` | 22.0 M |
| `gsl_stats_mean` | 25.6 M |
| `gsl_pow_int` | 25.8 M |
| `gsl_fit_linear` | 65.4 M |
| `gsl_stats_correlation` | 113.3 M |
| `gsl_linalg_HH_svx` (2x2 solve) | 128.2 M |
| `gsl_stats_variance` | 130.3 M |
| `gsl_complex_mul`, then `gsl_complex_abs` | 159.8 M |
| `gsl_cdf_ugaussian_P` | 369.5 M |

Game of Life is counted from its kernel (`addPadding`, then `nextGen`) on a torus with the
sizes and the two arrays' addresses classical and the cells in superposition (`experiments/gol/life.c`):

| Board | Cells in superposition | Generations | Gates | of them CCX | Depth | Qubits |
|---|---|---|---|---|---|---|
| 3 x 3 | 1 | 1 | 2,161 | 294 | 819 | 83 |
| 3 x 3 | 9 | 1 | 7,471 | 2,016 | 1,795 | 315 |
| 3 x 3 | 9 | 2 | 14,847 | 4,032 | 3,587 | 473 |
| 8 x 8 | 64 | 1 | 52,941 | 14,336 | 12,730 | 1,675 |
| 8 x 8 | 64 | 10 | 523,605 | 143,360 | 127,273 | 10,387 |
| 8 x 8 | 64 | 100 | 5,230,245 | 1,433,600 | 1,272,703 | 97,507 |
| 8 x 8 | 64 | 1,000 | 52,296,645 | 14,336,000 | 12,727,003 | 968,707 |
| 32 x 32 | 1,024 | 100 | 83,595,045 | 22,937,600 | 20,371,903 | 1,470,307 |

Every cell costs 224 CCX per generation. The qubit count grows with the generations (about 15 per cell
and generation) because nothing uncomputes a generation's overwritten cells.

Not counted yet: LU, Cholesky, Jacobi, the symmetric eigensolver and interpolation stop in the
backend, because a memory read inside a loop with a quantum exit gets an address the backend treats
as 61 to 64 quantum bits (its limit is 16). Gauss-Legendre integration and GMP's `mpn_fib2_ui`
lower and run but did not finish counting in 10 minutes.

`cqcc -cq-no-output` replaces calls to the `printf` family, `puts`, `fwrite` and `perror` on declared
streams by their error return, so a library's error reporting does not enter the count. It is meant
for building such a library, not the C standard library.
