# libqsoftfloat: the CQ float templates from Berkeley SoftFloat

A lowered library (README "Lowered libraries") that defines the floating-point templates of
`BACKEND_ABI.md` §2.6–§2.10 for f16, f32, f64, the bf16 conversions and, in a second archive, f80.
SoftFloat computes IEEE arithmetic with integer operations only; `cqcc --cq-lib` lowers it into
integer templates. A backend that implements integer circuits only (and the bit operations `fneg`,
`fabs`, `copysign`, `select`, `bitcast`) runs float programs by linking this library:

```sh
cqcc prog.c -Lsoftfloat/build -lqsoftfloat -lmybackend
```

## Origin

`upstream/` is Berkeley SoftFloat Release 3e, John R. Hauser, from
<https://github.com/ucb-bar/berkeley-softfloat-3> at commit
`07ebd29db0cfb55723a79fbbffe99103ef38e305` (2026-11-03): the f16, bf16, f32, f64 and extF80 sources
(not f128, not the `M` pointer variants), the `8086-SSE` specialization and the `Linux-x86_64-GCC`
`platform.h`. Licence: BSD-3-Clause, `LICENSE.txt` (upstream `COPYING.txt`). The first commit of
`softfloat/` holds them unmodified; `tools/patch_upstream.py` made every change after it:

- The rounding mode and the exception flags are a context, `struct sf_ctx`, passed as the first
  parameter of every non-primitive function, instead of globals; tininess is detected after rounding
  and the x87 rounding precision is 80, both constants (x86 SSE and x87 PC = extended).
- The 16-entry reciprocal tables are read as selects over packed constants (a table read at a
  quantum index would be a bus load). `SOFTFLOAT_BUILTIN_CLZ`: no leading-zero table.
- `fN_add`/`fN_sub` use upstream's `INLINE_LEVEL >= 2` path: two direct calls, no function pointer.
- Upstream bug fixed: `s_commonNaNToBF16UI.c` shifted the NaN payload by 56 instead of 57, so f32
  `0x7FA00003` became bf16 `0x7FC0`; compiler-rt and CR §2 give `0x7FE0`.

## Layout and build

| path | what |
|---|---|
| `cq/cqsf.h`, `cq/cqsf_f80.h` | the operations on bit patterns with CR §2 semantics, on top of SoftFloat |
| `gen/gen_cqsf.py` | the table: writes the roots, root lists, shims and `build/manifest.json` |
| `cq/cqsf_inner.c` | (generated) integer-only bodies `cqsfi_*`; every SoftFloat function always_inline |
| `cq/cqsf_roots.c` | (generated) the roots `cqsf_*` on the template operand types, one call of the body each |
| `cq/cqsf_shims.c`, `cq/cqsf_shims_f80.c` | (generated) one `cq_template_*` and `_unc` per symbol |
| `cqsf.roots`, `cqsf_f80.roots` | the root lists (369 and 111 roots) |
| `build.sh` | `gen`, `native`, `ir`, `lib [LIST]`, `probe [LIST]` |
| `test/` | the self-tests below |

```sh
# CQ_PLUGIN, CQ_BUILD_DIR and CQ_SPEC_DIR default to this repository's build/ and spec/
softfloat/build.sh gen                       # after editing the table or cq/*.h
softfloat/build.sh lib                       # build/libqsoftfloat.a      (about 1 minute)
softfloat/build.sh lib softfloat/cqsf_f80.roots   # build/libqsoftfloat_f80.a
```

`build.sh lib` compiles the two units with clang -O1 (separately, so that InstCombine never sees a
float type in the bodies and cannot turn their bit tests back into `fcmp`/`fabs`), links them,
internalizes everything but the roots, and lowers the roots in groups of 50 with
`cqcc --cq-lib -S --cq-roots <group>`. The archive holds the lowered groups, the shims and
`bundle/host/cq_host.o` (the lowered modules register their table clones with
`__cq_clone_register`; as an archive member it is linked only when the program has none).

**How a template is defined.** Each root `f` lowers to its table clone `__cq_q_f_1…1_t(handles…, K)`
and twin (CR §1.4). The shim of a template calls the clone, copies its result rail into the
template's result `o` (`cqrt_copy_<W>`), and calls the twin, which uncomputes the clone and frees
its result: `o ^= f(args)` with every operand and ancilla unchanged, which is the forward and the
`_unc` contract of BACKEND_ABI §2.1 alike. A literal operand and a `_rm` mode become seed rails
(`cqrt_alloc_<W>`) for the call and are freed after it. Each root variant: plain (round to nearest
even), `_m` (the x86 `FE_*` mode as an `i32` rail: `_rm`, `_rmq`), `_x` (the x86 exception word:
`_exc`, with the mode as an operand where the operation has one; the plain `_exc` passes mode 0).

**K.** Only the frem roots have loops (SoftFloat's remainder loop, 29 quotient bits per trip, and a
short do/while). The shims pass K = 8 (f16), 16 (f32), 80 (f64), 1200 (f80); every other root gets
K = 1 (no loop). `test/run_ktest.sh` lowers fmod(largest finite, smallest subnormal) and its
neighbours at every K: the smallest K that is right is 1, 9 and 72 for f16, f32, f64. f80: the
largest exponent difference is 32,828, so 1,131 trips (from the code; not run at the extreme, the f80
link test runs an fmod with an exponent difference near 26,600 at K = 1200).

## What it provides

Generated from the CR §1.2 grammar, restricted to what CQ's pass can emit (`pass/lib/eff/fenv/Fenv.cpp`):
a mode only on operations whose constrained intrinsic has one, `_exc` on every operation with a
constrained form, every binary op `_hl` and `_lh` (`_lh` is the NaN-literal spelling of a commutative
op), compares `_hl` only, `_ll` / `_l` / `lll` only with `_rmq`. 1,314 forward symbols (each with its
`_unc`) for the default archive, 375 for f80. All 82 float templates the CQ_spec corpus declares
are among them (`gen_cqsf.py --check-corpus`).

| operations | widths | forms |
|---|---|---|
| `fadd fsub fmul fdiv frem` | f16 f32 f64 (f80) | bare `hl` `lh` `ll`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `fma` | f16 f32 f64 | bare and the 6 mixed shapes, `lll`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `sqrt rint` | f16 f32 f64 (f80) | bare, `l`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `floor ceil trunc round` | f16 f32 f64 (f80) | bare, `_exc` |
| `fmax fmin` | f16 f32 f64 (f80) | bare `hl` `lh`, `_exc` |
| `fcmp_<pred>` `fcmps_<pred>` (14 predicates: o/u eq gt ge lt le, one, ord, une, uno) | f16 f32 f64 (f80) | bare `hl`, `_exc` |
| `is_fpclass` | f16 bf16 f32 f64 (f80) | `hl` |
| `fpext` | f16→f32, f16→f64, f32→f64, bf16→f32, bf16→f64 (f16/f32/f64→f80) | bare, `_exc` |
| `fptrunc` | f32→f16, f64→f16, f64→f32, f32→bf16, f64→bf16 (f80→f16/f32/f64) | bare, `l`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `sitofp uitofp` | i1 i8 i16 i32 i64 → f16 bf16 f32 f64 (f80) | as fptrunc |
| `fptosi fptoui` | f16 bf16 f32 f64 (f80) → i8 i16 i32 i64 | bare, `_exc` |

Not provided:
- bf16 arithmetic, compares, rounding ops and `fmax`/`fmin` (only the bf16 conversions and
  `is_fpclass`); `fma` at f80 (SoftFloat has no `extF80_mulAdd`).
- `fcmp_false`, `fcmp_true` (folded by LLVM, never emitted).
- `sitofp`/`uitofp` from widths other than 1, 8, 16, 32, 64 and `fptosi`/`fptoui` to widths other
  than 8, 16, 32, 64 (an `i7` or an `i128`); the generator takes them as `INT_FROM`/`INT_TO` entries
  for widths up to 64; above 64 bits the CR §2 rows need their own code.
- `fneg`, `fabs`, `copysign`, `select`, `bitcast`: bit operations, the backend's integer side.

## Semantics and the classical self-test

`test/run_selftest.sh` builds the roots natively and compares every one against the host's x86-64
floats (clang 19 -O1 with FENV_ACCESS: SSE, F16C, FMA instructions, x87 for f80), bit for bit, in all
four rounding modes, with the exception word: specials (±0, subnormals, extremes, ±Inf, quiet and
signalling NaNs with payloads, and for f80 the non-canonical encodings) and random operands.
Default: 2,222,732 cases over 227 operations, 0 mismatches. f80 (`run_selftest.sh f80`): 406,184
cases over 54 operations, 0 mismatches. Where CR §2 fixes what the host leaves to a library, the
reference is the CR row (the report names each):

- `frem` is C `fmod`, computed from SoftFloat's IEEE remainder r: when r ≠ 0 has the other sign than
  x, fmod = r + copysign(|y|, x), an exact sum. Flags: INVALID for x = ±Inf or y = ±0 (IEEE, CR §2);
  macOS libm's `fmod(0, 0)` raises nothing. NaN: the first NaN operand quieted.
- `fma`: a NaN operand gives the first NaN quieted and INVALID only for an sNaN, as x86 `vfmadd`
  does for 0 × Inf + qNaN (SoftFloat would give the default NaN with INVALID).
- `fptosi`/`fptoui`: the CR §2 rows on c32/c64 (8086-SSE's indefinite INT_MIN). The `_exc` word of
  `fptoui` to i64 is that of LLVM's strict code (one cvtt of x − (x ≥ 2^63 ? 2^63 : 0)), not of the
  −O1 formula's two conversions.
- `fmax`/`fmin`: the CR row; INVALID for an sNaN (IEEE). `is_fpclass`: a field test, no flag.
- bf16: `fpext` from bf16 is the bare shift; `fptrunc` to bf16 and `sitofp`/`uitofp` to bf16 (via f32,
  two roundings) are compiler-rt calls on the host, which ignore the mode and raise no flags: they
  are compared in round-to-nearest, values only. Their `_rm` forms round in the mode and their
  `_exc` forms give IEEE flags (not compared with hardware).
- f80: a non-canonical operand is the real indefinite with INVALID (a compare: unordered); a
  pseudo-denormal reads as a denormal; a NaN result is the first NaN operand (x87 picks the larger
  significand). f80 → f16 has no x87 instruction: the reference rounds the exact value in the test.

## Evidence that it lowers and links

- `build.sh lib`: the 369 default roots lower with no pass error in 8 groups, about 55 s in all
  (17 MB of lowered IR, a 8.6 MB archive).
  The lowered modules call no float template (only `bitcast` between fN and iN) and no `cqrt_qram_*`;
  the mode and the flags never touch memory. Their templates: integer add, sub, mul, udiv, and, or,
  xor, shl, lshr, ashr, icmp, select, zext, sext, trunc, abs, smax, umax, usub_sat, ctlz, fshl,
  bitreverse, at widths i1 to i128.
- `test/run_link_test.sh`: `test/prog_double.c` (double and float arithmetic, sqrt, fmod, floor,
  fma, fmax, conversions, compares, isinf) through `cqcc`, linked with `-lqsoftfloat` and a toy
  backend that defines integer templates only (`test/gen_toy_backend.py`, which refuses to generate a
  float template), prints the same line as the program built natively.
- f80 (`cqsf_f80.roots`, kept out of the default list because extF80 arithmetic used to crash the
  pass): with the plugin of 2026-11-17 all 111 roots lower one by one (`build.sh probe`, at most 3 s
  each) and as `build.sh lib cqsf_f80.roots` (2 groups, 26 s, 4.1 MB), again with no float
  template and no bus access; `CQSF_EXTRA_LIBS=-lqsoftfloat_f80 test/run_link_test.sh
  test/prog_f80.c` matches the native program. The f80 shims are not in `run_shimtest.sh`.
- `test/run_shimtest.sh [N]`: every template symbol through its shim, the lowered library and the toy
  backend against the native root; each `_unc` must return its rail to 0 and the backend counts dirty
  frees. 1,314 symbols × 16 samples: 0 mismatches, 0 dirty frees.
