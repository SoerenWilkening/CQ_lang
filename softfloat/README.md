# libqsoftfloat: the CQ float templates from Berkeley SoftFloat

A lowered library (README "Lowered libraries") that defines every floating-point template of
`BACKEND_ABI.md` §2.6–§2.11 for f16, bf16, f32, f64 and, in a second archive, f80: no
`cq_template_*` symbol with a float width is left to the backend. SoftFloat computes IEEE arithmetic
with integer operations only; `cqcc --cq-lib` lowers it into integer templates. A backend that
implements integer circuits only runs float programs by linking this library:

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
| `cq/cqsf_int.h` | the conversions from and to the other integer widths (`INT_X`), CR §2 rows |
| `cq/cqsf_roots_x.ll` | (generated) the `INT_X` roots as LLVM IR, with native test entries `cqsft_*` |
| `cq/cqsf_shims.c`, `cq/cqsf_shims_f80.c` | (generated) one `cq_template_*` and `_unc` per symbol |
| `cqsf.roots`, `cqsf_f80.roots` | the root lists (673 and 182 roots) |
| `tools/backend_needs.py` | what the built archives leave undefined (llvm-nm), grouped by operation and width |
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
neighbours at every K from the shims' K down to the first wrong one: the smallest K that is right is
1, 9, 72 and 1,131 for f16, f32, f64, f80 (`run_ktest.sh f80`, 14 s). f80: the largest exponent
difference is 32,828, 1,131 trips of the 29-bit loop, as the code says. Below that the result is not
monotone in K: with y of 3 or 5 ulps the cut remainder is periodic in the trip count, and K = 50, 200,
410, 500 and 800 happen to be right; the scan stops at the first wrong K (1,130).

## What it provides

Generated from the CR §1.2 grammar, restricted to what CQ's pass can emit (`pass/lib/eff/fenv/Fenv.cpp`):
a mode only on operations whose constrained intrinsic has one, `_exc` on every operation with a
constrained form, every binary op `_hl` and `_lh` (`_lh` is the NaN-literal spelling of a commutative
op), compares `_hl` only, `_ll` / `_l` / `lll` only with `_rmq`. 2,086 forward symbols (each with its
`_unc`) for the default archive, 560 for f80. All 82 float templates the CQ_spec corpus declares
are among them (`gen_cqsf.py --check-corpus`).

| operations | widths | forms |
|---|---|---|
| `fadd fsub fmul fdiv frem` | f16 bf16 f32 f64 (f80) | bare `hl` `lh` `ll`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `fma` | f16 bf16 f32 f64 (f80) | bare and the 6 mixed shapes, `lll`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `sqrt rint` | f16 bf16 f32 f64 (f80) | bare, `l`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `floor ceil trunc round` | f16 bf16 f32 f64 (f80) | bare, `_exc` |
| `fmax fmin` | f16 bf16 f32 f64 (f80) | bare `hl` `lh`, `_exc` |
| `fcmp_<pred>` `fcmps_<pred>` (14 predicates: o/u eq gt ge lt le, one, ord, une, uno) | f16 bf16 f32 f64 (f80) | bare `hl`, `_exc` |
| `is_fpclass` | f16 bf16 f32 f64 (f80) | `hl` |
| `fpext` | f16→f32, f16→f64, f32→f64, bf16→f32, bf16→f64 (f16/bf16/f32/f64→f80) | bare, `_exc` |
| `fptrunc` | f32→f16, f64→f16, f64→f32, f32→bf16, f64→bf16 (f80→f16/bf16/f32/f64) | bare, `l`(rmq) × plain `_rm` `_rmq` × `_exc` |
| `sitofp uitofp` | i1 i8 i16 i32 i64, i7 i24 i48 i100 i128 i200 → f16 bf16 f32 f64 (f80) | as fptrunc |
| `fptosi fptoui` | f16 bf16 f32 f64 (f80) → i8 i16 i32 i64, i7 i24 i48 i100 i128 i200 | bare, `_exc` |
| `fneg fabs` | f16 bf16 f32 f64 (f80) | bare (no mode, no flags: no `_exc` form) |
| `copysign` | f16 bf16 f32 f64 (f80) | bare `hl` `lh` |
| `select` | f16 bf16 f32 f64 (f80) | bare `hl` `lh` `ll`: a shim onto `select_i16/i32/i64/i80` (a float literal arm as its bit pattern), no root |
| `bitcast` | f16↔i16, bf16↔i16, f16↔bf16, f32↔i32, f64↔i64, (f80↔i80) | bare: `cqrt_alloc_iN(0)` and `cqrt_copy_iN`, no root |

Not provided:
- `fcmp_false`, `fcmp_true` (folded by LLVM, never emitted).
- `sitofp`/`uitofp`/`fptosi`/`fptoui` at integer widths not in the table. `INT_X` in the generator
  lists one width of each CR §2 class (7, 24 at most 32 bits; 48 up to 64; 100, 128 up to 128; 200
  above); another width is one more entry there (up to 256 bits, the four limbs of `cq/cqsf_int.h`).

What a backend still provides (`python3 tools/backend_needs.py` over both archives: 497 symbols,
`_unc` forms included). At a float width only the core calls `cqrt_alloc_<W>` and `cqrt_copy_<W>`
for f16, bf16, f32, f64, f80 (the shims' seeds and results); the backend treats them as the
same-width bit registers (a rail is untyped). A program's own `cq_theta`/`cq_measure` on a float
still reach the backend as `cqrt_ry_<W>`/`cqrt_measure_<W>` (§1), not through this library.
Everything else is integer: `add sub mul udiv and or xor shl lshr ashr icmp select zext sext trunc
abs smax umax umin usub_sat ctlz fshl bitreverse` at widths i1 to i200 (i6, i7, i17, i24, i31, i48,
i80, i100 and i200 among them; the list per width is the tool's output), and `cqrt_free`,
`cqrt_not/and/or/xor_i1`, `cqrt_xorc_i32`, `cqrt_push`, `cqrt_pop`, `cqrt_qram_alloc_i8` (the bundle
host's `__cq_mem`; no lowered root touches the bus), `cqrt_alloc_<iN>`, `cqrt_copy_<iN>`.

## Semantics and the classical self-test

`test/run_selftest.sh` builds the roots natively and compares every one against the host's x86-64
floats (clang 19 -O1 with FENV_ACCESS: SSE, F16C, FMA instructions, x87 for f80), bit for bit, in all
four rounding modes, with the exception word: specials (±0, subnormals, extremes, ±Inf, quiet and
signalling NaNs with payloads, and for f80 the non-canonical encodings) and random operands.
Default: 2,420,156 cases over 236 operations, 0 mismatches. f80 (`run_selftest.sh f80`): 2,841,832
cases over 62 operations, 0 mismatches. Where CR §2 fixes what the host leaves to a library, the
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
- `fneg`, `fabs`, `copysign`: the sign bit alone, as integer bit operations on the pattern (f80: bit 79),
  also of a NaN: no quieting, no flag; against the host's `-x`, `fabs*`, `copysign*` on specials with
  signalling NaNs and payloads (f16, f32, f64, f80) and all 65,536 bf16 patterns, 0 mismatches. The
  reference for `-x` on `_Float16` is the host's -O1 code: its strict code (FENV_ACCESS) negates through
  `float` and quiets an sNaN with INVALID, which CR §2 does not.
- bf16 ↔ f80 (clang emits `fpext bfloat to x86_fp80` and back): to f80 the shift and the exact f32 → f80;
  to bf16 one rounding through f32 rounded to odd (IEEE: compiler-rt's `__truncxfbf2`, which LLVM 19's
  compiler-rt for x86 macOS lacks, so the test's reference is the x87 conversion to f32 rounded to odd
  and the bf16 rounding in the test).
- `fma` at f80: SoftFloat has no `extF80_mulAdd`, so `cqsf_f80.h` has one, `cqsf_extF80_mulAdd`: the
  128-bit product of the significands, c aligned in a 192-bit frame with a sticky jam (exact under
  any cancellation), one `softfloat_roundPackToExtF80` at precision 80 in the mode; NaN and
  non-canonical operands by the CR rows. Reference: a*b + c computed exactly with `_BitInt(1024)` in
  the test and rounded there (subnormals, overflow, tininess after rounding): 110,592 special triples
  and 250,000 random and hard ones (cancellation, the subnormal boundary, ties, overflow), × 4 modes,
  0 mismatches. The host's `fmal` (macOS libm) is not that reference: against it, 109,582 of 1,157,208
  values differ (1,447 the sign of an exact zero, e.g. +0·+0 + +0 in round-down gives −0; 28,497
  subnormal or zero results; 71,153 in the directed modes; 8,485 ties in nearest-even near 2^-16382:
  min subnormal × 1.5 + (2^63 − 1)·2^-16445 is the tie (2^63 + ½)·2^-16445, even is
  `0x8000000000000000:0001`, `fmal` gives `…0001:0001`) and 333,576 flag words; CR §2 (IEEE) decides.
- bf16: `fpext` from bf16 is the bare shift; `fptrunc` to bf16 and `sitofp`/`uitofp` to bf16 (via f32,
  two roundings) are compiler-rt calls on the host, which ignore the mode and raise no flags: they
  are compared in round-to-nearest, values only. Their `_rm` forms round in the mode and their
  `_exc` forms give IEEE flags (not compared with hardware).
- bf16 arithmetic, compares and rounding ops (`run_selftest.sh bf16`: 4,150,384 cases over 41
  operations with the sign ops, 0 mismatches). CR §1.1 gives bf16 the rounding and NaN rules of the IEEE widths, so each
  operation is one correct rounding in the mode. `cqsf.h` computes + − × ÷ √ fma in f32 rounded to odd
  (toward zero, the last bit set when inexact), then rounds to bf16 in the mode: exact, as 24 ≥ 8 + 2;
  upstream's `bf16_add` (f32 in the mode, then f32 → bf16) gets the UNDERFLOW flag wrong near 2^-126.
  Compares, `frem`, the rounding ops and `fmax`/`fmin` are exact through f32. clang -O1 on x86-64
  computes `__bf16` arithmetic as the f32 operation then `__truncsfbf2` (nearest even, no flags): for
  + − × ÷ √ that is the same value in round-to-nearest (two roundings that agree), and the 709,200
  nearest-even values compared with the host's own code agree bit for bit. `fma` is not: the host's
  f32 `fma` then truncation rounds twice, and differs from the one rounding in 117 of 68,000 cases
  (0x3f81 × 0xbfc0 + 0x0001: host 0xbfc2, one rounding 0xbfc1); CR §1.1 decides. In the modes and for
  the flags the reference is the x87 result rounded to odd at 64 then 24 bits and rounded to bf16 in the
  test. Reachable from C at -O1: + − × ÷, compares and `llvm.floor/ceil/trunc/rint/round.bf16`; clang
  promotes `sqrt`, `fma` and `fmod` on `__bf16` to f32 itself, so those templates serve IR only.
- Integer widths other than 1, 8, 16, 32, 64 (`cq/cqsf_int.h`, `INT_X`; `run_selftest.sh int`:
  3,804,864 cases over 180 operations, 0 mismatches; 324,000 nearest-even values compared with the host's
  own -O1 conversion, 0 differ). iN → fp: up to 64 bits the 64-bit conversion of the extension; 65 to
  128 bits one IEEE rounding in the mode (compiler-rt computes it on the host, RNE only); above 128 bits
  LLVM 19's `ExpandLargeFpConvert` value, the mode ignored, with its exponent wrap (i200 2^150 → f32
  `0x8a800000`) and for f80 its two roundings (fp128, then `__trunctfxf2`); f16/bf16 through that f32,
  the second step in the mode; uitofp to f80 the IEEE value (CR §2). fp → iN: up to 64 bits cvtt at the
  width LLVM promotes to (c32/c64; f80 fist16/32/64); 65 to 128 bits compiler-rt's `__fix*ti` value
  (`__fixxfti` saturates by the x87 compare `a > 0`: a NaN or a non-canonical operand gives MIN); above
  128 bits the expansion (f16: its own case, the conversion to i32 extended). Flags above 64 bits: the CR
  row. References: the host value bit for bit where the host links one; f16 ↔ 65..128 bits (no
  `__floattihf`, `__fixhfti` in LLVM 19's compiler-rt for x86 macOS) and f80 ↔ i200 (fp128 libcalls)
  from integer arithmetic in the test (`ref_round`, compiler-rt's formula); IEEE results in the modes
  and their flags from `ref_round`; fp → iN flags up to 64 bits from the host's strict conversion.
  The roots are LLVM IR (`cq/cqsf_roots_x.ll`), since C passes `__int128` as two `i64` and
  `_BitInt(200)` in memory; the IR declarations repeat the C bodies' signatures exactly (a mismatched
  call links silently, works natively by register luck and stopped the pass: `spine:
  cq_template_bitcast_i16_to_f16 argument 0 has the wrong type`, the generator's bug, fixed).
- f80: a non-canonical operand is the real indefinite with INVALID (a compare: unordered); a
  pseudo-denormal reads as a denormal; a NaN result is the first NaN operand (x87 picks the larger
  significand). f80 → f16 has no x87 instruction: the reference rounds the exact value in the test.

## Evidence that it lowers and links

- The repo's checker (`cqcheck user`, light mode, 16 samples) on 24 lowered roots, each called from an
  entry that makes its operands quantum with `cq_theta` and measures the result (`test/checker/`:
  `entries.c`, `build.sh default|f80`, `check.sh`): fadd f64 and its `_x`, fmul f32, fdiv f16, sqrt
  f64, frem f16, fma f64, fcmp olt f64, rint f32 `_m`, floor f16, fptosi f64 → i32, sitofp i64 → f32
  and i7 → f64, fpext f16 → f64, fptrunc f64 → bf16, fadd bf16, fmul bf16 `_m`, fcmp ueq bf16, fneg
  f32; fadd, fma, sqrt, fptoui → i64, fcmp ogt at f80: 24 PASS (§6-equal to the C program on 16
  compared samples each), about 45 s a root. `_Float16` and `__bf16` operands enter as quantum 16-bit
  patterns (CQ.h has no forms for them).

- `build.sh lib`: the 673 default roots lower with no pass error in 17 groups, 1 min 40 s in all
  (a 15.2 MB archive); `build.sh lib cqsf_f80.roots`: 171 roots in 5 groups,
  182 roots, 36 s (5.2 MB).
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
  test/prog_f80.c` matches the native program.
- `test/run_shimtest.sh [N [default|f80|all]]`: every template symbol of both archives through its
  shim, the lowered library and the toy backend against the native root; each `_unc` must return its
  rail to 0 and the backend counts dirty frees. 2,692 symbols (2,132 default, 560 f80) × 16 samples:
  43,072 calls, 0 mismatches, 0 dirty frees. `select` and `bitcast` at float widths (no root) are
  checked against c ? a : b and the same bits. The toy backend defines no float-width template. The toy backend holds 256-bit rails and takes an
  iN literal above 128 bits as LLVM passes it: N/64 integer registers when all fit, else all on the
  stack with the remaining integer registers skipped (measured; `select_i200_ll` has two).
