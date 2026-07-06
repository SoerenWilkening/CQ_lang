# PRD — libm coverage honesty (bd `p119`)

> Owner-directed correction, 2026-07-06. Supersedes the *template-recognition*
> coverage strategy for library functions (`fp-data-priority-iw81-4`, `3c6m.2`).
> Backend correctness stays deferred (owner, 2026-06-10).

## Problem

The headline **`math.h` 165/174 (95%)** number is measured by **template
recognition**: the pass recognizes a `math.h` function *by name / intrinsic ID*
(`@llvm.sin`, direct `@cbrt`, …) and emits a per-function frozen `cq_template_<fn>`.

That number is **fiction under the honest compile model**. A library function is
only meaningfully "compiled" when its **source is injected** (an openlibm-style
soft-body llvm-linked + inlined *before* `cq-lowering`, caller built
`-fno-builtin-<fn>` so the named call resolves to the injected body). Once the
source is injected, the named call / intrinsic is **inlined away to stock
opcodes + control flow** — so the name-recognition path *never fires*. The
recognizers measure a compile that does not happen.

The honest measure is **source injection** (`INJECTION-CENSUS.md`): inject the
real body, let taint flow through opcodes. Off-the-shelf openlibm compiles
**~0 transcendentals** today (all blocked by tainted control-flow / scratch
memory), vs the fictional 95%.

## The rule (NEW — project-wide)

1. **Compiling a library function ALWAYS means compiling with its source
   injected.** There is no "recognize the call by name and emit a per-fn
   template" path for a library function.
2. **Library-function coverage is measured ONLY by source injection** — the
   taint pass sees stock opcodes and lowers those. No per-fn frozen
   `cq_template_<fn>` for a library function.
3. **Sole exception: hardware-backed intrinsics.** An intrinsic that **codegens
   to a hardware instruction** (or an inline arithmetic sequence) with **no
   libcall** has *no injectable software body* — injection is meaningless for it.
   These are recognized directly and kept. They are also exactly the leaves an
   injected libm body reduces to, so keeping them is what *lets* source
   injection fully lower.

### The keep/cut criterion (operational, testable)

For each currently-recognized function, compile `T f(T x){return f(x);}` at
`clang -O1` and inspect codegen:

- **KEEP** iff the body lowers with **no external `call`/`jmp` to `_<fn>`**
  (a hardware instruction or an inline opcode sequence). It survives because
  hardware backs it; there is no body to inject.
- **CUT** iff clang emits a **libcall** (`call`/tail-`jmp _<fn>`). It is a
  library function → its recognizer is removed → it must be **source-injected**.

The set is **target-dependent** and must be *measured*, not guessed (Rule 11).
Two asymmetries the experiment caught (x86-64 + SSE4.1, no FMA3):

- `round` **KEEP** (inline `andpd` magic-number trick, no libcall) but `lround`
  **CUT** (round-half-away has no HW fp→int form → libcall).
- `rint`/`lrint` **KEEP** (`roundsd`/`cvtsd2si`) but `lround`/`llround` **CUT**.
- `fma`/`fmuladd` **KEEP** — the explicit must-fuse `fma()` tail-calls a libcall
  on a no-FMA3 box, but the ubiquitous `a*b+c` contraction is `@llvm.fmuladd`
  → `mulsd`+`addsd` (opcodes, no libcall), and it is precisely what injected
  Horner-polynomial bodies bottom out in. Removing it would decline every
  injected polynomial.

## Empirical keep-set (x86-64 + SSE4.1, this box, 2026-07-06)

**KEEP — 14 hardware/opcode survivors:**
`sqrt` · `fabs` · `copysign` · `floor` · `ceil` · `trunc` · `round` · `rint` ·
`nearbyint` · `fmin` (`minnum`) · `fmax` (`maxnum`) · `fma` (`+ fmuladd`) ·
`lrint` · `llrint`.

Plus the (non-`math.h`) **integer bit-intrinsics** — `bswap bitreverse fshl
fshr ctpop ctlz cttz abs smin smax umin umax {u,s}{add,sub}_sat` — untouched
(same hardware/opcode-primitive rationale).

**CUT — every library function (recognizer removed → inject source):**
transcendentals `sin cos tan asin acos atan sinh cosh tanh exp exp2 log log2
log10`; `pow`; direct-libm `cbrt erf erfc tgamma lgamma expm1 log1p logb acosh
asinh atanh hypot atan2 remainder nextafter fdim fmod ilogb ldexp scalbn
scalbln`; by-ref `frexp modf remquo`; `lround llround`.

## Scope of removal (implementation)

- **Delete** `ir-pass/src/LibmLowering.{cpp,h}` (direct `@name` matcher — all
  library functions) and `ir-pass/src/ByRefMath.{cpp,h}` (`frexp/modf/remquo`,
  epic `g387` — all library functions, and coupled to the libm table).
- **Keep** `ByRefInline.{cpp,h}` (table-independent user-fn inliner) and the
  integer bit-intrinsics untouched.
- **Trim** `tools/intrinsic_table.yaml` fp-math block to the 12 fp survivors
  (`sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma`);
  drop `sin cos tan asin acos atan sinh cosh tanh exp exp2 log log2 log10 pow`.
- **Trim** `IntrinsicLowering.cpp isCrossWidthLibmIntrinsic` to `{lrint,
  llrint}`; drop `lround`, `llround`.
- **Reduce** `tools/libm_table.yaml` to only the `lrint`/`llrint` template rows
  (the template surface the kept cross-width intrinsics emit); delete the rest.
- **Regenerate** `runtime/cq_intrinsic_templates.{h,c}` + `cq_libm_templates.{h,c}`;
  update the hardcoded symbol-count asserts in `tools/gen_templates_test.py`.
- **Patch** the external call sites (`OpcodeLowering`, `TaintPropagation`,
  `Specialization`, `SpecializeReject`, `CQLoweringPass`) that reference the
  removed predicates.
- **Add decline fixtures** (Rule 12): a bare tainted `sin(q)` / `cbrt(q)` /
  `frexp(q,&e)` with **no injected source** now **loud-declines** (unknown
  callee), and the census proves the injected form lowers-or-declines through
  opcodes.

## Re-measurement

- Retire `probe.py`'s `math.h` template-recognition claim (README badge,
  `COVERAGE.md`, `coverage/mathh.md`).
- Promote **source injection** (`inject_census.py`) as the authoritative
  `math.h` measure; instrument it to record surviving `@llvm.*` and expand to
  the full ~174 surface. Report: hardware survivors that lower via recognition
  **+** library functions that lower via injection (≈0 today).

## Done-criteria

- The 14-stem keep-set recognizes; every cut function **loud-declines** without
  injection (Rule 12 fixture each family).
- `gen_templates.py --check` + `gen_templates_test.py` + full `ctest` green.
- Coverage claims replaced with honest injection numbers; no dangling
  `cq_template_*` symbol; e2e link clean.
- Rule-13 adversarial clearance: no survivor wrongly dropped, no cut shape
  silently accepted.
