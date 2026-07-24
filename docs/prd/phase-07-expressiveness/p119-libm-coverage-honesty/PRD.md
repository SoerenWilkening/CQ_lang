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

### Amendment 2026-07-24 (bd `3c6m.56`) — the criterion is "in-grid IR construct **that Bennett backs**," NOT "no libcall in final asm"

The `2026-07-06` "no external `call`/`jmp _<fn>`" formulation above is **too
narrow at both ends** and is superseded (measured, Rule 11). The operative
keep/cut test has **two** conditions, **both** required:

1. **Recognizer** — `clang -O1` folds the call to an **in-grid IR construct CQ
   recognizes before codegen** (a hardware instruction, an inline opcode
   sequence, OR a recognized `@llvm.<fn>` intrinsic). The test is the *IR the
   pass sees*, **not** the final asm. The `floor.f80` precedent generalizes: the
   **l-suffix rounders** `rintl`/`nearbyintl`/`truncl` emit `callq _<fn>l` at f80
   codegen (a libcall in the asm!) yet are **keeps**, because CQ intercepts
   `@llvm.{rint,nearbyint,trunc}.f80` *before* codegen. So a libcall in the final
   asm does **not** by itself cut a cell.
2. **Backend-realizable** — Bennett.jl ships a **reversible gate sequence** for
   that construct, so a real Phase-9 backend has a source. If (1) holds but (2)
   fails, the cell is a recognizer **parity-inversion** we cannot realize; it is
   **not** a keep and stays declined. This gates recognizer over-reach.

The 14-stem keep-set below all clear **both**: the rounders map to Bennett
`soft_round` (round-to-nearest-even = `rint`/`nearbyint` under the default FP
env) / `soft_round_away` (`round`) / `soft_trunc` / `soft_floor` / `soft_ceil`
(`src/softfloat/fround.jl`); `sqrt`→`soft_fsqrt`; `fmin`/`fmax`→`soft_fminimum`/
`soft_fmaximum`; `fma`→`soft_fma`; `fabs`/`copysign` are sign-bit permutations.

**`fmod`/`fmodf`/`fmodl` are NOT keeps.** They fold to the in-grid **`frem`
opcode** (condition 1 holds) — but Bennett ships **no** `frem`/`fmod` gate
sequence (condition 2 **fails**; its sole `frem` token is an error-string entry
in `src/extract/errors.jl`). Native `frem` is a CQ recognizer parity-*inversion*
(the pass recognizes an opcode Bennett declines), tracked as a separate
follow-up; `fmod` therefore stays a **declining** library cell, NOT added to the
keep-set. This is the correction to the 2026-07-24 "fmod frem-keep" finding: the
`floor.f80` analogy fails for `fmod` because `floor` **is** Bennett-backed and
`frem` is **not**.

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
