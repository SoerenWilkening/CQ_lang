# Full-Depth "Peel-the-Onion" Blocker Census — ISO C11 `<math.h>` / libm

**bd 3c6m.50 · 2026-07-11 · branch `3c6m.13-qrom-under-control-signpost`**

> Companion to `full_surface/INJECTION-CENSUS.md` (first-blocker census, 3c6m.49)
> and bd memory `libm-full-depth-peel-census-2026-07-11`. This census peels
> *every* decline layer per cell, so the capability-combination → function map is
> exact — fixing the first-blocker mis-routing that flipped 18 cells L5→L6 (3c6m.13).

---

## 1. Headline

Over the **reconciled 123-cell** ISO C11 `<math.h>` surface (real openlibm bodies,
source-injected per Rule 18, at every width f32/f64/f80 + by-ref + int-ret).
**All numbers below are cross-checked by an independent 4-lens adversarial
verification (§10); the honest, verification-adjusted headline is:**

| result | count | note |
|---|---|---|
| **COMPILE today** | **2** | `fdim.f64`, `fdimf.f32` (clang-`-O1` if-converts isnan+ternary to accepted fp-DATA selects, kjd1) |
| **CONTROL lever participates** | **108 / 123 (88%)** measured · **119 / 123** corpus-fixed | the dominant lever, but "CONTROL" bundles tainted branches + classical-condition data-muxes |
| **CONTROL-ALONE** (L6-unlockable) | **8 verified · ≤ 48 projected** | pure-L6 target — *optimistic upper bound*, see §5 |
| **C-physics walls** | **0** | proven by an **independent 241-body corpus scan** (§8), *not* the census self-check |

**Bottom line for sequencing (verification-endorsed):** the tainted-control-flow
lever (3c6m.14 "L6", built on the existing swap-route control emitter) is
empirically the single highest-leverage capability — on the critical path for
**~119 of 123** libm cells, with **no C-physics wall anywhere in the surface**
(every decline is a recognizer/capability gap, achievable — Bennett.jl does it).
The precise L6-unlockable target is **8 individually-IR-verified CONTROL-alone
cells, up to ~48 projected**; the gap is the CONTROL-alone cells the census labels
but cannot fully self-validate (it returns before opcode/cast lowering, is blind to
*accepted* lowerable-Shadow stores, and **under-counts loops** — §5, §9). Build L6
next; before quoting "48 unlocked," individually inspect the projected set.

---

## 2. Method — the peel, generalized

The existing first-blocker census (`full_census_results.json`) records only the
*first* decline per cell. First-blocker bucketing is exactly what mis-routed the
18-cell "unsupported instruction" bucket to L5 when its true lever is L6 (bd
3c6m.13). This census peels every layer via a **throwaway `CQ_PEEL_CENSUS`
instrumentation** of `cq-lowering` (never committed — `git checkout`-reverted
before commit; the committed harness is inert without it):

1. **Non-fatal diagnostic handler.** opt calls `exit(1)` on the first unhandled
   `DS_Error`, which truncates the stack after the first decline. Census mode
   installs a handler that records every diagnostic as `cq-peel: <msg> @ <loc>`
   and returns *handled* — so opt collects the **whole** blocker list in one run.
2. **Taint flood.** The pass halts taint at a store/escape (it does not model the
   store→load Shadow flow), so downstream control behind a store is invisible.
   Census mode runs `censusFloodTaint` — an **over-approximate data-dependence
   closure** through memory (store→load matched by underlying object) and call
   results — so every pure guard sees the whole-body cone. Over-approximation is
   the *safe* census direction: it can only reveal *more* capabilities the body
   needs.
3. **Pure guards only.** Census mode runs the pure analysis/detection guards
   (`detectSpecializations` / `declineTaintEscapes` / `declineStaleRecordOps` /
   `detectControlRegions` / `declineClassicalMuxes`) and returns before any
   mutating stage — no half-lowered-IR cascade crash.

The raw `cq-peel` classes are folded into campaign **LEVERS** and merged with the
normal **first-blocker** run (which *does* execute the mutating stages, covering
the two fused-emit-only classes census mode cannot see). The union is each cell's
capability set (`peel_census_merged.json`).

**Honesty caveats (Rule 11):**
- The flood is an over-approximation of *pure-guard-detectable* classes. Two
  classes fire only in mutating stages (straight-line QRAM-cell fp/i128 read;
  `OpcodeSupport` unsupported-opcode) and are covered only by the first-blocker
  run's *first* hit — a fused-emit opcode gap *behind* a control blocker is
  unobservable without actually landing L6. Mitigated by §6.
- `unknown-callee` (INNER-CALL) is largely a **corpus/closure artifact** under
  Rule 18: once the source is injected and inlined there is no call. A surviving
  call means the corpus body was absent, the O2 inliner declined it, or it is a
  hardware keep-set leaf (`sqrt`). See §7.

---

## 3. Step 0 — surface reconciliation (provably complete over ISO C11)

The prior `MATHH_SPEC` had 64 base entries. Reconciled against the full C11 §7.12
roster to **69 base entries / 183 cells / 123 census-runnable**:

- **Added `nexttoward`/`nexttowardf`/`nexttowardl`** (§7.12.11, was genuinely
  missing; 2nd arg is always `long double` → new `ldbl` arg-kind). Injectable.
- **Added `fabs`** (§7.12.7) — pins it explicitly as recognition-keep-set
  (census-skipped, no injectable body).
- **Added the 3 missing comparison macros** `isgreaterequal`/`islessequal`/
  `islessgreater` (§7.12.14) — by-design macros (no body, census-skipped).
- Every entry now pins as exactly one of: **injected** (real openlibm source) ·
  **recognition-keep-set** (14 hardware intrinsics) · **by-design-macro** (12
  classification/comparison macros) · **corpus-gap** (closed, below).

**Corpus-gap closures (Step 0c — harness artifacts, NOT recognizer gaps):**
Three openlibm public names are minted by the build's symbol aliasing, which the
raw `-emit-llvm` corpus build does not reproduce, so they surfaced as spurious
"unknown callee". Closed and folded into the reproduce recipe:
- **`tgamma` double body** (`b_tgamma.c`) — needed the BSD `M_PI`/`M_PI_2`/`M_PI_4`
  constants at compile. **Correction to the 3c6m.49 memory:** tgamma is *not*
  "float-body-only" — the double body exists; it is **recursive** (`tgamma ↔
  large_gam` argument reduction) so it cannot fully inline (a bounded-recursion
  finding, §5).
- **`lgamma`/`lgammaf`/`lgammal`** public non-reentrant wrappers — reconstructed
  the openlibm `lgamma(x)=lgamma_r(x,&signgam)` wrapper (global `signgam`); the
  computational body is the real corpus `lgamma_r`.
- **`ldexp`/`ldexpf`/`ldexpl`** — openlibm `strong_reference(scalbn, ldexp)`;
  shimmed `ldexp=scalbn`.

**Scope boundary (Step 0d):** `complex.h` (csin/cexp/cabs…), `fenv.h`
(fesetround…), and non-ISO extensions (sincos/exp10/Bessel j0/y0/drem/scalb) are
**out of scope** for this pass — named as a follow-on surface.

---

## 4. Capability-combination → function map

Each row = a distinct lever combination and the cells whose real body needs exactly
that set. **CONTROL** = tainted control flow (nested L6 + flat/diamond +
classical-mux + const-table-read-under-control + §3c). **SHADOW** = tainted store
to scratch memory. **LOOP** = classically-bounded tainted loop. **INNER-CALL** =
surviving un-inlined tainted call (mostly corpus artifact). **SPECIALIZE** = fp
quantum arg/return on a surviving call, or an un-inlinable recursive body.
**OPCODE** = a genuinely-unsupported opcode.

> This table is the **raw measured** census (`peel_census_merged.json`). §5 applies
> the verification adjustments: the LOOP re-audit moves `fmodf`/`remainderf`/
> `remquof.f32` from the CONTROL row to CONTROL+LOOP, and the CONTROL+INNER-CALL
> .f64 cells (fmod/remainder/remquo/acos/asin/acosh/asinh/pow/hypot) also carry
> hidden loops. Read the combination as a **lower bound on levers**, exact only for
> the 8 individually-inspected CONTROL-alone cells.

| cells | combination | functions |
|---|---|---|
| **2** | **COMPILES** | fdim.f64, fdimf.f32 |
| **51** | **CONTROL** (pure-L6 target) | atan, atan2, atanh, cbrt, cosh, erf, erfc, exp, exp2, expm1, log, log10, log1p, log2, logb, scalbn, scalbln, sinh, tanh (f32/f64) · erff, atan2f, atanf, atanhf, cbrtf, coshf, erfcf, exp2f, expf, expm1f, log10f, log1pf, log2f, logbf, logf, scalblnf, scalbnf, sinhf, tanhf · frexp, frexpf, ldexp, ldexpf, llround, llroundf, lround, lroundf, modf, modff, remainderf, remquof, fmodf |
| **23** | **CONTROL+SHADOW** | (f80/ld80) atanhl, atanl, cbrtl, expl, expm1l, frexpl, ldexpl, llroundl, log10l, log1pl, log2l, logbl, logl, lroundl, modfl, scalblnl, scalbnl, tanhl, fdiml · nextafter, nextafterf, nextafterl, nexttowardf |
| **10** | **CONTROL+INNER-CALL** | acos.f64, acosh.f64, asin.f64, asinf.f32, asinh.f64, fmod.f64, hypot.f64, pow.f64, remainder.f64, remquo.f64 |
| **5** | **CONTROL+LOOP** | acosf.f32, acoshf.f32, asinhf.f32, hypotf.f32, powf.f32 |
| **8** | **CONTROL+INNER-CALL+SHADOW** | acoshl.f80, acosl.f80, asinhl.f80, asinl.f80, erfcl.f80, erfl.f80, hypotl.f80, nexttoward.f64 |
| **4** | **CONTROL+SHADOW+SPECIALIZE** | atan2l.f80, coshl.f80, powl.f80, sinhl.f80 |
| **2** | **CONTROL+SPECIALIZE** | lgamma.f64, lgammaf.f32 |
| **2** | **CONTROL+INNER-CALL+SHADOW+SPECIALIZE** | lgammal.f80, tgammal.f80 |
| **3** | **CONTROL+INNER-CALL+LOOP+OPCODE+SHADOW** | cos.f64, sin.f64, tan.f64 (Payne-Hanek `k_rem_pio2`) |
| **11** | **INNER-CALL** only (corpus-masked, §7) | cosf.f32, cosl.f80, exp2l.f80, fmodl.f80, nexttowardl.f80, remainderl.f80, remquol.f80, sinf.f32, sinl.f80, tanf.f32, tanl.f80 |
| **2** | **SPECIALIZE** only (recursion, §5) | tgamma.f64, tgammaf.f32 |

---

## 5. L6 (3c6m.14) decision support — cells-unlocked-per-lever

| lever | cells (measured) | note (verification-adjusted) |
|---|---|---|
| **CONTROL** | **108** (proj. 119) | bundles tainted branches + classical-condition data-muxes (`declineClassicalMuxes`); do **not** read as "108 have tainted branches" |
| SHADOW | 40 (proj. 47) | genuine tainted stores (§6); two kinds — algorithm-intrinsic vs ABI type-punning |
| INNER-CALL | 34 (proj. 33) | mostly corpus/closure artifacts (§7) |
| SPECIALIZE | 10 | incl. tgamma recursion; lgamma is fp-spec (not recursion) |
| **LOOP** | **≥ 8** (NOT a count) | **systematic LOWER BOUND** — see below |
| OPCODE | 3 | sin/cos/tan.f64 only — O2-**vectorized** vector opcodes + tainted-index `ipio2` reads, not a scalar-arith gap |

**LOOP is a systematic lower bound, not a count (verification, Lens B — refuted the
"complete set" claim).** Census mode returns *before* `lowerLoops`
(CQLoweringPass.cpp:186–190 vs :218), the only stage that emits the loop diagnostic,
so a loop is recorded only when it is the *first* normal-mode blocker; any tainted
loop masked behind an earlier SHADOW/QRAM/escape/spec blocker is invisible. A
direct `print<loops>` re-audit of inlined IR confirms hidden loops the census
missed: **fmod/remainder/remquo.f64 (2 loops each, the bit-reduction loop),
acos/asin.f64 (3–6), acosh/asinh.f64 (6), pow/hypot.f64 (3)** — so LOOP truly
participates in ≳ 20 cells, not 8. (Exact per-cell loop counts are confounded by
corpus-inline non-determinism — `fmodf.f32` showed 2 loops one run, 0 the next.)
Consequence: **`fmodf.f32`/`remainderf.f32`/`remquof.f32` leave CONTROL-alone → they
are CONTROL+LOOP**, reducing the measured CONTROL-alone set 51 → 48.

**CONTROL-alone (the L6-unlockable set): 8 verified, ≤ 48 projected.** The census
labels 48 cells (after the LOOP re-audit) as having only control-flow blockers over
their whole flooded cone. **Only 8 are individually IR-verified** (exp, log, atan,
cbrt, tanh, scalbn, erf, lround — Lens A: 0 allocas / 0 stores / 0 loops after -O2,
blockers exclusively control-family, only const-global/fixed-address loads). The
other ~40 are an **optimistic upper bound** with three census blind spots (§9):
census returns before `lowerOps`/`castInScope` (cannot see an unsupported opcode/
cast decline); an *accepted* lowerable alloca-Shadow store emits no diagnostic and
the flood over-taints past it; masked loops. **Opcode-surface evidence** for the
verified 8: the **branchless-authored substitutes** (`branchless/`) compile through
the current pass (Lens A confirmed slice_branchless_{exp,cbrt,atan,tanh,log,scalbn,
erf}.c → exit 0, fully lowered), and for the no-substitute bit-manip functions Lens A
verified every opcode in the real `lround` body (bitcast f64↔i64, shifts, `fptosi`,
…) is in `opcode_table.yaml` + `castInScope` — so that residual risk is **closed for
lround**, open-but-low for frexp/modf/ldexp/llround/remquof.

**Marginal cells per additional lever (on top of CONTROL):**
- **+SHADOW → 23** cells (almost all f80/ld80 + nextafter at all widths — §6).
- **+INNER-CALL → 10** cells (acos/asin/asinh/acosh/fmod/remainder/remquo/hypot/pow .f64) — but these ALSO have hidden loops (above), so really CONTROL+INNER-CALL+LOOP.
- **+LOOP → 5** cells recorded (acosf/acoshf/asinhf/hypotf/powf .f32) — lower bound.
- **+SPECIALIZE → 2** cells (lgamma.f64/f32 — fp-specialization, NOT recursion).
- **CONTROL+INNER-CALL+LOOP+OPCODE+SHADOW → 3** cells (sin/cos/tan.f64) — the
  Payne-Hanek argument reduction (`k_rem_pio2`): bounded loop over a stack int
  array `iq[]` + O2-vectorized vector opcodes + tainted-index `ipio2` table reads.
  The deepest libm cells; need every lever.

**tgamma** (f64/f32) is genuinely **recursive** (`tgamma ↔ neg_gam` SCC in
`b_tgamma.c`) — its measured SPECIALIZE-alone *under-counts*; behind the recursion
barrier it also needs bounded-recursion + LOOP + CONTROL + aggregate (struct-Double)
handling. **lgamma is NOT recursive** (the "lgamma(1+s)=…" lines are algorithm
comments; the code uses a reduction loop) — it is CONTROL+SPECIALIZE (fp-spec).

---

## 6. Width-specific findings (the denominator/variant expansion)

The double-only census could never see these. Injecting real bodies at f32/f80
surfaces genuine per-width capability differences (verification Lens D — all
IR-confirmed in *precise/flood-off* mode, i.e. **not** flood artifacts; the store
is the *first* blocker in normal mode). **Two distinct KINDS of width-SHADOW:**

- **ABI type-punning SHADOW (f80/ld80 + fdim).** 23 CONTROL+SHADOW cells, 20/23
  f80 (`expl`, `logl`, `cbrtl`, `tanhl`, `scalbnl`, …). The `x86_fp80` `isnan`/
  exponent extraction is routed through a `union.ieee_extended` that SROA cannot
  promote, so the theta seed is genuinely `store`d to a stack cell — where the f64
  sibling (CONTROL-alone) does the same test via a register `bitcast double to
  i64`. This is **codegen/ABI-induced**, *not* evidence the ld80 algorithm is
  inherently more stateful. Confirmed: `expl.f80` `store x86_fp80 %theta, ptr
  %union`. The **`fdim` width split** (fdim.f64/f32 COMPILE, `fdiml.f80` declines
  on SHADOW) is the same effect on one shared macro body.
- **Algorithm-intrinsic SHADOW (nextafter, all widths).** `nextafter`/`nexttoward`
  store through a `volatile double t` (`s_nextafter.c`: `t = x*x`) at *every* width
  — an algorithm-level side effect, present at f32/f64/f80. **Correction:** this is
  exact for `nextafter`; for `nexttoward` it is loose — `nexttowardl.f80` is
  measured INNER-CALL-only (non-inlined, SHADOW unmeasurable) and `nexttoward.f64`'s
  precise first blocker is the un-inlined call.

---

## 7. Harness-artifact quick-wins (no pass change)

26 cells carry a surviving un-inlined tainted call. Under Rule 18 every injected
libm body should inline to opcodes + hardware keep-set leaves, so a surviving call
is an artifact, not a recognizer gap. **Sibling inference** confirms it: every
corpus-masked cell (except recursive tgamma) has an *inlined* sibling width whose
real capability set is CONTROL(+…). Fixing the closure/inlining reclassifies them
into the CONTROL buckets — which is why the corpus-fixed CONTROL projection is
119/123, not 108/123.

- **f32 kernel non-inline:** cosf/sinf/tanf.f32 — `__kernel_{sin,cos}f` / `k_rem_pio2f`
  not folded; inlined sibling (sin/cos/tan.f64) = the full deep set.
- **f80/ld80 non-inline:** cosl/sinl/tanl/exp2l/fmodl/remainderl/remquol/nexttowardl
  .f80 — ld80 helpers survive; siblings show CONTROL(+…).
- **Keep-set leaf:** pow's surviving `sqrt` is a hardware keep-set intrinsic (recognized).
- **True recursion (NOT a quick-win):** tgamma.f64/f32 — recursive `b_tgamma.c`;
  needs a bounded-recursion lever.

A harness fix (complete corpus + a forced high-threshold inline pass, or switching
the census's *global* `-fno-builtin` to per-fn `-fno-builtin-<target>` so it stops
pulling soft-`sqrtl`/`feholdexcept`) compiles the corpus-masked cells' bodies to the
point where their real (CONTROL+…) blockers surface — the census under-counts
CONTROL by ~11 cells purely from this artifact.

**Split the "26" honestly (verification Lens C):** ~20 are **true corpus/closure
quick-wins** (missing wrapper `.bc` + a soft-`sqrtl` `feholdexcept` body pulled only
by the *global* `-fno-builtin`; the real target is the hardware keep-set `fsqrt`).
The other **6 are the gamma family** (tgamma/lgamma × f64/f32/f80) — **not** corpus
fixes: tgamma is recursion, lgamma is fp-specialization. `projected_levers` in
`peel_census_merged.json` already separates these; only the flat "26 quick-win"
framing is corrected here.

---

## 8. C-physics wall check — zero walls

**0 cells hit a C-physics wall** — but the *evidence* is an **independent
full-corpus scan, NOT the census's own check** (verification Lens C caught that the
census self-check is **vacuous**: `synth_census.py` tests `class ∈ {6 wall strings}`,
but the pass never emits those strings — `SpecializeReject` surfaces an
inttoptr/atomic/inline-asm as "specialization"/"unsupported instruction", tagged
SPECIALIZE/OPCODE — so `cphys=[]` is guaranteed regardless of reality). The real
evidence: Lens C **disassembled all 241 openlibm bodies (68k IR lines)** and grepped
each wall opcode → **0 `inttoptr`/`ptrtoint`, 0 `atomicrmw`/`cmpxchg`, 0 `invoke`/
`landingpad`, 0 `indirectbr`/`callbr`/`blockaddress`, 0 heap, 0 `va_arg`, 0
inline-asm in any inlined cell body**; every pointer is provenance-rooted (all 585
GEPs are stack/const-global math). This **confirms the Bennett-parity thesis for the
entire libm surface**: every libm decline is a temporary recognizer capability gap,
none is a physics wall.

**fp-environment near-wall (a 7th, non-taxonomy category — Lens C).** The corpus
*does* contain side-effecting inline asm on the x87/SSE control-status registers
(`fnstenv`/`fldenv`/`stmxcsr`/`ldmxcsr`/`fnstcw`) and `fenv` calls
(`feholdexcept`/`feupdateenv`) — in `e_sqrtl` and the keep-set `fma`/`lrint`/
`nearbyint` bodies. These are **confined to files no census cell needs** (soft-`sqrtl`
is pulled only by the census's *global* `-fno-builtin`; the real target is hardware
`fsqrt`). If ever reached they would **DECLINE loudly** (INNER-CALL / unsupported) —
not a silent miscompile. The 6-wall taxonomy omits fp-environment as a category;
noted for completeness.

---

## 9. Limitations (all surfaced by the §10 adversarial verification, Rule 11)

1. **LOOP is a systematic LOWER BOUND (≥8), not a count.** Census mode returns
   before `lowerLoops`, so a loop is caught only when it is the first normal-mode
   blocker; masked loops are invisible. A `print<loops>` re-audit found hidden loops
   in fmod/remainder/remquo/acos/asin/acosh/asinh/pow/hypot (§5). LOOP truly
   participates in ≳ 20 cells.
2. **CONTROL-alone (48) is an optimistic upper bound; verified floor = 8.** Three
   census blind spots can each demote a cell below CONTROL-alone: (a) census returns
   before `lowerOps`/`castInScope`, so it never sees an unsupported-opcode/cast
   decline (its OPCODE lever fires only on the `declineTaintEscapes` "unsupported
   instruction" path, never on a `castInScope` fp↔int/i128 decline); (b) an
   *accepted* lowerable alloca-Shadow store emits no diagnostic and the flood
   over-taints past it, so a CONTROL+lowerable-shadow cell mislabels as
   CONTROL-alone; (c) masked loops (limitation 1). Only the 8 individually-inspected
   cells are certain.
3. **The C-physics "0 walls" method is vacuous; the conclusion holds via the
   independent 241-body scan** (§8), not the census's own check.
4. **CONTROL count composition.** "108 CONTROL" bundles tainted-branch control with
   classical-condition data-muxes (`declineClassicalMuxes`); not "108 tainted branches."
5. **Flood over-approximation.** Per-class *magnitudes* are inflated by the flood
   tainting merge phis; the per-cell lever *set* is robust (cross-checked vs the
   exact first-blocker run + raw IR + the §10 lenses), but counts are upper bounds.
6. **Corpus/inline non-determinism.** The closure-link set varies run to run
   (~27-fn churn); per-cell loop/inline counts are noisy (`fmodf.f32`: 2 loops one
   run, 0 the next). Lever *sets* are stable; exact magnitudes are not.

---

## 10. Adversarial verification (4 opus lenses + adjudication)

An independent 4-lens `libm-census-adversarial-verify` workflow stress-tested every
headline against raw inlined IR. **All 4 lenses: CONFIRMED_WITH_CAVEATS** — no
numeric headline falsified; two structural problems surfaced (caught by adversarial
reasoning, never a green run — the Rule-10/11 pattern) and are folded in above:

- **CONFIRMED intact:** 2 COMPILE (fdim, if-converted selects); **zero C-physics
  walls** (independent 241-body scan); every decline is B-recognition; 26 un-inlined
  = corpus/closure/keep-set artifacts; 23 CONTROL+SHADOW genuine & width-gated (not
  flood artifacts — fire as first blocker in flood-off mode); the flood introduces
  no *false* CONTROL; the 8 inspected CONTROL-alone cells (0 stores/allocas/loops);
  tgamma genuinely recursive.
- **REFUTED (surfaced prominently):** (1) LOOP "= 8" as a complete count → it is a
  lower bound (fmod.f64 counter-example); (2) the census's built-in C-physics check
  is vacuous (a real wall would be mislabeled achievable).
- **CAVEATED (folded into §5/§6/§8/§9):** CONTROL-alone 51 is an optimistic upper
  bound (floor 8); CONTROL bundles muxes; OPCODE is O2-vector opcodes not scalar
  arith; nexttoward SHADOW loose; lgamma is fp-spec not recursion; tgamma under-counts;
  the two kinds of width-SHADOW; the fp-environment near-wall.

**Adjudicator bottom line:** *"Build L6/CONTROL next (highest leverage, no wall), but
the honest headline is **8 verified, up to 48 projected**, and the LOOP tally must be
published as ≥8, not 8."* This census endorses CONTROL/3c6m.14 as the next build
lever — with an honest target count, not an inflated one.
