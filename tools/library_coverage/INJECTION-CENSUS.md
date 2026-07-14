# Source-Injection Census — math.h via openlibm + authored branchless bodies (opcode-lowering path)

> **⚠️ p119 (2026-07-06): source injection is now the AUTHORITATIVE way to compile a
> library function (Rule 18).** The old "template-recognition" strategy (recognize
> `@llvm.<fn>` / `@<fn>` by name → per-fn `cq_template_<fn>`) has been RETIRED for
> library functions — it measured a compile that never happens once the real source
> is injected. Recognition now survives ONLY for **hardware-backed intrinsics** (no
> injectable body): `sqrt fabs copysign floor ceil trunc round rint nearbyint fmin
> fmax fma/fmuladd lrint llrint`. Every transcendental / direct-libm / by-ref
> function now **declines loudly** without injection. This census is therefore no
> longer a "separate baseline" — it is THE measure of library-function coverage.
> See `docs/prd/phase-07-expressiveness/p119-libm-coverage-honesty/PRD.md` and bd
> [`libm-coverage-source-injection-rule`]. **The authoritative live figure is
> `injection_summary.json`: **32/32 injection-covered — the COMPLETE injection surface**
> (`declines_by_lever` is now empty): `exp`, `log`, `log2`, `log10`, `cbrt`, `log1p`,
> `expm1`, `atan`, `tanh`, `atanh`, `acosh`, `asinh`, `atan2`, `sinh`, `cosh`, `erf`,
> `erfc`, `sin`, `cos`, `tan`, `exp2`, `asin`, `acos`, `logb`, `scalbn`, `scalbln`,
> `fdim`, `fmod`, `remainder`, `hypot`, `pow`, `nextafter`, all authored-branchless,
> disjoint from the recognition floor** (the 3 remaining math.h doubles `ldexp`/
> `lgamma`/`tgamma` are a separate HARNESS-GAP bucket — a census link-closure/self-
> reference limitation, NOT injection body work — see `HARNESS_GAP` below)
> (0/32 → 2/32 `exp`/`log` first landing, → 5/32 `cbrt`/`log1p`/`expm1`, → 7/32
> `atan`/`tanh`, → 9/32 `log2`/`log10` (all bd `3c6m.10` L1), → 15/32
> `atanh`/`acosh`/`asinh`/`atan2`/`sinh`/`cosh`, → 17/32 `erf`/`erfc` (bd `3c6m.10`
> **L2-closure**: compound bodies that call an L1 leaf), → 19/32 `sin`/`cos` (bd
> `3c6m.44`/`.25` **L1**: branchless Cody–Waite range reduction + fp-quadrant
> const-selects, replacing openlibm's Payne–Hanek scratch-store), → 23/32
> `tan`/`exp2`/`asin`/`acos` (bd `3c6m.46`/`.30`/`.19`/`.17`: `tan` **L1** reuses the
> sin/cos reduction as a k_sin/k_cos ratio, `exp2`/`asin`/`acos` **L2-closure** to the
> `exp`/`atan` leaves), → 30/32 `logb`/`scalbn`/`scalbln`/`fdim`/`fmod`/`remainder`/
> `hypot` (bd `3c6m.10` **Batch A**, `.38`/`.43`/`.42`/`.16`/`.32`/`.41`/`.33`:
> keep-set identities + bit-field extracts that dissolve openlibm's special-case
> control flow with ZERO selects — each 2-arg fn certified on all qc/cq/qq masks),
> → 31/32 `pow` (bd `3c6m.10` **Batch B**, `.40`: **L2-closure** `pow(x,y) =
> exp2(y·log2(x))` [x>0] — dissolves e_pow.c's sign/parity/overflow ladder + table
> log/exp into the authored `log2`/`exp2`(→`exp`) leaves, single fp round-bias flag),
> → **32/32** `nextafter` (bd `3c6m.10` **Batch C**, `.39`: the L5-shadow wildcard —
> the one-ULP bit step rendered FULLY ARITHMETIC, `step = ((y>x)-(y<x))·(1-2·sign(x))`,
> `bitcast(bits(x)+step)`; qc/qq lower with zero flags, cq materializes one integer
> const-select over the tainted direction — **the injection surface is now complete**)).
> The dated sections below are kept as HISTORY (each frozen at its landing's number,
> not updated in place). Re-run `inject_census.py` over a fresh openlibm corpus to
> refresh.

## ⚡ SCOREBOARD UPDATE 2026-07-14 (bd `3c6m.14` Inc 4 — L6 CONTROL landed): real openlibm **2 → 48** injection-covered

The L6 CONTROL lever (PredMux — general acyclic tainted control, 3c6m.14 Inc 1–3)
shipped. Re-running the full-surface census over a freshly-rebuilt 241-body corpus
with the committed HEAD plugin (`full_surface/peel_census.py`, normal/first-blocker
mode; deterministic 48/48/48 across 3 runs; census-mode flood cross-checks §4/§5's
levers exactly — bd `FULL_DEPTH_CENSUS.md` §11):

> **The authoritative full-surface real-openlibm scoreboard (two DISJOINT numbers,
> bd `libm-scoreboard-two-numbers`):**
> - **Injection-covered (COMPILES under real-body source injection): 48 / 123** (was
>   **2**). 24 f64 + 24 f32 (the same 24 functions at both widths); f80 all still held
>   by SHADOW (bd `3c6m.51`). The number the campaign moves — DISJOINT from the
>   recognition floor (14 hardware intrinsics).
> - **Verified (committed e2e golden trace, Rule 2): 8** — `atan cbrt erf exp log
>   lround scalbn tanh` (`.f64`, `slice_libm_real_*`). A compile is not a proof of the
>   unitary; the other **40** (38 new + 2 fdim) compile+link+run (10/10 e2e-spot-
>   checked) but need goldens before they count as verified.
>
> Do **not** quote "48 verified" — quote **48 injection-covered, 8 verified**. The 38
> new-compile cells (23 f32 siblings + 15 additional f64) are the follow-up
> verification ticket. Full delta + per-lever follow-ups: `FULL_DEPTH_CENSUS.md` §11.

The 3c6m.49 "2/120" and 3c6m.50 "8 verified / ≤48 projected" below are the frozen
pre-L6 baseline this update supersedes; §11 of `FULL_DEPTH_CENSUS.md` reconciles them
(`48 = 46 CONTROL-flips + 2 fdim`, exact).

## ⚠️ Read the 32/32 precisely — FULL-SURFACE CENSUS 2026-07-11 (bd `3c6m.49`): real openlibm = **2/120**

The **32/32** headline above is honest **but narrow in two ways**, and it is easy to
misread as "math.h is done":

1. **Authored substitutes, not off-the-shelf source.** All 32 bodies are
   **hand-authored branchless** soft-bodies (`branchless/`, bd `3c6m.10` L1)
   deliberately written to **bypass** every open lowering lever (zero selects, zero
   nested control, no scratch store, no QROM). They are real Rule-18 injection — but
   they are *our* code, not openlibm's.
2. **Double-only.** `inject_census.py`'s probe generator is hard-wired to `double`
   (`arg0` is always a `cq_theta_f64`), so the **float / long-double / by-ref /
   integer-return** variants of the ~174-cell `math.h` surface were **never probed**.

Injecting the **real off-the-shelf openlibm** body at **every width**
([`full_surface/`](full_surface/), the width-parametric widening of this census) gives
the honest picture: of **120 injectable cells**, **2 COMPILE** (`fdim.f64`, `fdimf.f32`
— genuinely branchless) and **118 DECLINE**. The declines map cleanly onto the **already-open
lever tickets** — there is *no large novel capability gap*, only the scoreboard was
misleading:

| Decline bucket | Cells | Lever |
|---|---|---|
| memory-store / Shadow at scale (mostly f80 `ld80` tables) | 34 | `3c6m.13` · `iw81.13` · `u9pl` |
| L6 nested control (`atan`/`log*`/`cbrt`/`expm1`/`tanh`/`modf`/`lround`…) | 27 | `3c6m.14` (reprioritized P2) |
| inner-reduction / unknown-callee (trig kernels + `pow`/`hypot`/`lgamma`…) | 25 | `3c6m.11` L2 ⚠ *partly harness closure/inlining — triage per-case* |
| const-global QROM reads under tainted control, first-surfacing as "unsupported instruction" (`e_exp.c:138` `ln2HI[xsb]`, `e_fmod.c:48` `Zero[sx]`, `s_exp2.c:376` `tbl[i0]`) | 18 | **`3c6m.14` (L6)** — corrected below |
| flat control · loops · fp-copy/specialization · §3c clobber | 14 | 4.x · 7.3 · `5po2` |

> **CORRECTION 2026-07-11 (bd `3c6m.13`, empirically re-scoped).** The 18-cell "unsupported
> instruction" bucket was mapped to **L5-QROM (`3c6m.13`)** on the theory that the tainted-index
> const-table read is an accept-shape gap. Measured (throwaway probe accepting the under-control
> read, run on the real openlibm bodies) it is **not**: the read is the *first-tripped* instruction
> only because `declineTaintEscapes` runs before `detectControlRegions`; the reads are all **under
> tainted control** (not straight-line — straight-line const reads already lower), and accepting
> them yields **0 new compiles** — every cell reclassifies to `nested control flow` (L6), `unknown
> callee`, or `loop`. **So this bucket maps to L6 (`3c6m.14`), not L5.** `3c6m.13` shipped a precise
> decline **signpost** for the shape (`const-global table read under tainted control`) replacing the
> misleading "unsupported instruction" (which is exactly what mis-routed this bucket to L5); it does
> **not** widen the accept-shape (a non-win + over-accept trap). Evidence:
> `docs/prd/phase-07-expressiveness/PRD-3c6m.13-EVIDENCE.md`; memory `qrom-under-control-signpost-3c6m13`.

**Takeaway (scoreboard honesty, bd `libm-scoreboard-two-numbers`):** the campaign number
moves on **real-body injection**, not authored substitutes. `3c6m.49` owns productionizing
this full-surface census as the authoritative scoreboard (superseding the double-only one).
Reproduce: [`full_surface/README.md`](full_surface/README.md). Details: bd memory
`libm-full-surface-empirical-decline-2026-07-11`.

## Methodology 2026-07-10 (3c6m.48 — multi-arg taint-combination honesty; scoreboard unchanged 23/32)

`inject_census.py` previously tainted only **arg0** (the rest classical consts), so a
multi-arg fn's `COMPILES` certified exactly ONE of its `2^k-1` non-empty tainted-double
combinations — and the *weakest*, because the classical constants **const-fold body
logic** (e.g. `atan2(q,0.5)` folds the whole `(x<0)?±PI:0` quadrant offset to `+0.0`).
Taint is **per-operand**: each combination is a DISTINCT lowering path (distinct
`_hl`/`_lh`/`_qq` templates, distinct taint propagation) that emits a DIFFERENT unitary.
The census now **enumerates every non-empty tainted-double mask** per fn (`run_fn` →
`run_one(mask=…)`, distinct `cq_theta` per tainted arg) and counts a fn `COMPILES`
**only if EVERY mask COMPILES** (else it reports the first declining mask — Prime
Directive; never a silent `COMPILES` hiding an unlowered mask). Per-combination verdicts
are recorded in `inject_results.json` under a `combinations` field (multi-arg fns only;
single-double-arg entries keep their lone mask and stay byte-identical).

The only **live** multi-arg fn that COMPILES is `atan2` — re-measured across all three
masks: `qc` (y tainted, x const — the already-golden `x>0` half-plane), `cq` (y const,
x tainted — exercises the `fdiv_lh` literal/handle division + an x-tainted quadrant
merge), `qq` (both tainted, two qubits — handle/handle `fdiv` + a NESTED tainted-condition
quadrant select). **All three COMPILE** and each is a **pure value-embedding** (0
controlled rotations, balanced flag frees; the `off`/quadrant DATA rails left allocated,
never dirty-freed) — so `atan2` stays honestly `COMPILES`, now with all masks certified
and each accepted mask carrying its own linked e2e golden
(`slice_branchless_atan2{,_cq,_qq}.c`, Rule-13 cleared).

**Committed-snapshot scope (surgical splice, per the corpus-churn discipline of bd
`branchless-sin-cos-3c6m10`).** `inject_results.json`'s `combinations` field is spliced
for **`atan2` only** — the sole COMPILES multi-arg fn, re-measured on this box. The other
multi-double surfaces stay declines on every mask (`pow`/`hypot`/`fmod`/`fdim`/`remainder`/
`nextafter` — injection decliners; `copysign`/`fma`/`fmax`/`fmin` — hardware-kept) and
retain their **pre-3c6m.48 single-line formatting**; a full `inject_census.py` run under
the new code will additionally give each of them a `combinations` breakdown and a
`[mask qc]` detail prefix, but that requires the openlibm bitcode corpus (absent here) and
would churn ~27 unrelated entries — so it is deferred to the next full corpus run. This is
a formatting lag on entries that **remain declines**, with **no scoreboard-number impact**
(all stay declines; `injection_compiles`/`injection_candidates`/`declines_by_lever` are
byte-stable). The one fn whose `COMPILES` actually needed multi-mask certification —
`atan2` — is certified here (per-mask `combinations` + three linked e2e goldens). Scoreboard
unchanged at **23/32**; what changed is that the multi-arg number is now HONESTLY measured
(bd `libm-scoreboard-two-numbers`).

## Re-measurement 2026-07-10 (3c6m.46/.30/.19/.17 — tan L1 + exp2/asin/acos L2-closure; 19/32 → 23/32)

> HISTORY, frozen at 23/32. Live number: `injection_summary.json`.

**`tan` (3c6m.46), `exp2` (3c6m.30), `asin` (3c6m.19), `acos` (3c6m.17)** flip
decline→`COMPILES` via authored branchless bodies (`branchless/{tan,exp2,asin,acos}.c`;
e2e twins `tests/e2e/slice_branchless_{tan,exp2,asin,acos}.c`). All four are single-arg,
so the multi-arg combination gap (`atan2`-class) does not apply.

**`tan` (L1, blocker L5-shadow)** shares sin/cos's blocker — openlibm's Payne–Hanek
scratch-store (`e_rem_pio2.c:174`) — and its fix: **reuse** the register-only branchless
Cody–Waite reduction of `branchless/sin.c` and reconstruct `tan` from the **same**
`k_sin`/`k_cos` kernels as a **ratio** (no `k_tan` table, no scratch). `tan` is
**π-periodic**, so only the **parity** of `fn = rint(x·2/π)` matters: `fn` even → `S/C`,
`fn` odd → `−C/S` (`S=sin(y)`, `C=cos(y)`, `y∈[-π/4,π/4]`). `par = fn − 2·floor(fn/2)` is
derived in fp (keep-set `floor`, no `fptosi`), and the ratio operands are built by **one
constant-operand fp select** feeding two **unconditional weighted sums** with **one**
division — `num = useT·S + (1−useT)·(−C)`, `den = useT·C + (1−useT)·S`, `tan = num/den`
(the sin/atan/erf const-select-weight pattern; a libm body mints no `Rz`/`Ry`, so the kjd1
fp-DATA select accept shape applies). `den = 0` occurs **only** at the true poles (odd
multiples of `π/2`, `y=0`, odd parity) where `num = −1 ≠ 0`, so `tan → ±∞` (the correct
pole limit) — never `0/0`, so **no in-domain NaN**; the `fmax`/`fmin` clamp keeps `S`,`C`
finite for every double.

**`exp2` (L2-closure, blocker L5-qrom)** — openlibm's `s_exp2.c` reads a 256-entry accuracy
table `tbl[i0]` with a data-dependent index (`s_exp2.c:376`, the QROM surface). Dissolved
with `exp2(x) = 2^x = exp(x·ln2)`, calling the branchless `exp` leaf (closure-resolved to
`branchless/exp.c`, inlined). No table.

**`asin` (L2-closure, blocker L6-nested-ctrl)** — openlibm's `e_asin.c` branches on `|x|`
with a nested `if` ladder (`e_asin.c:77`). Dissolved with `asin(x) = atan(x/√(1−x²))`,
calling the branchless `atan` leaf. **The `fmax` clamp kills the `|x|→1` NaN**: `s =
√(fmax(1−x², 1e-300))`, so at `x=1` the argument is `1e150` — a large **finite** value in
atan's big segment (`atan(1e150) ≈ π/2`), never the `+∞` that would make the branchless
atan return NaN. So `asin` is finite and NaN-free across `[−1,1]`. atan is odd and carries
the sign, so no extra copysign.

**`acos` (L2-closure)** — `acos(x) = π/2 − asin(x)`, a two-level closure (asin → atan). All
range/NaN care lives in asin's clamp; acos is one subtraction on top.

Accuracy is a **sanity check, not a gate** (trace-only runtime; bd
`libm-accuracy-is-sanity-not-gate`): spot-checked at `x=0.5` — `tan=0.5463`, `exp2=√2`,
`asin=π/6`, `acos=π/3`, each matching host libm. Every lowered trace is a **pure
value-embedding** — 1 `ry`, 1 `measure`, **0 controlled rotations**
(`cqrt_rz`/`cnot`/`toffoli`/`cswap`), balanced fp-select flag mint/strip/free pairs (`tan`
1 / `exp2` 1 / `asin` 5 / `acos` 5, matching each body's select count). Surviving `@llvm.*`
are keep-set leaves only. Census diff is surgical: only these 4 flip. ZERO
core-pass/runtime-YAML change; pure additive corpus + e2e + docs.

## Re-measurement 2026-07-10 (3c6m.44/.25 — sin/cos L1; 17/32 → 19/32)

> HISTORY, frozen at 19/32. Live number: `injection_summary.json`.

**`sin` (3c6m.44), `cos` (3c6m.25)** flip decline→`COMPILES` via authored branchless
bodies (`branchless/{sin,cos}.c`; e2e twins `tests/e2e/slice_branchless_{sin,cos}.c`).
The blocker was **L5-shadow**: openlibm reduces an arbitrary argument to `[-π/4,π/4]`
with **Payne–Hanek**, storing the split product into a multi-word scratch array
`double tx[3]` and reading it back (`e_rem_pio2.c:174` — `tainted value stored to
memory`), which is the Phase-7.5 QRAM/Shadow surface, not yet lowerable. The branchless
rendering replaces Payne–Hanek with a fully **register-only, branchless Cody–Waite**
reduction — `fn = rint(x·2/π)`, `y = (x − fn·pio2_1) − fn·pio2_1t` (two-term, ≈66-bit
`π/2`; faithful for `|x| ≲ 2^20·(π/2) ≈ 1.65e6`, fdlibm's own medium-path threshold) —
then fdlibm's degree-6 `k_sin`/`k_cos` minimax kernels, with the **quadrant** (`fn mod 4`)
selecting `±sin(y)`/`±cos(y)`. The quadrant is derived **entirely in fp** (`qf = fn −
4·floor(fn/4)`, `par`, `half` via the keep-set `floor` — no `fptosi`/integer mask) and the
answer is the **atan pattern**: CONSTANT-operand fp selects (`useS=(par<0.5)?1:0`,
`sgn=(half<0.5)?1:-1`) feeding the **unconditional** weighted expression
`sgn·(useS·S + (1−useS)·C)`, so clang -O1 keeps them speculatable `select`s (never
branches). `cos = sin(x+π/2)` reuses the same sin-weight code on `(fn+1)` — every
comparison a `<`-against-a-constant, since the equality form `par==half` **is**
branch-ified by SimplifyCFG (verified: it declined `control flow under quantum control`).
The reduced arg is clamped `yc = fmax(-π/4, fmin(y, π/4))` with the NaN-suppressing
keep-set `fmin`/`fmax`, a no-op on the faithful range and a finite bound beyond it — so the
body is **finite for every double** (±∞/NaN → finite): **0 in-domain NaN/Inf**; the
branchless range-reduction limit surfaces only as reduced ACCURACY for `|x| ≳ 1.65e6`,
never as a non-finite result (the Payne–Hanek path this body deliberately omits).
Accuracy is a **sanity check, not a gate** (trace-only runtime; bd
`libm-accuracy-is-sanity-not-gate`): spot-checked to ≈1 ulp vs host libm across all four
quadrants (exact at `1e6`), sub-ulp absolute (~1e-26) at the transcendental zeros. The
lowered trace is a pure value-embedding — 1 `ry`, 1 `measure`, 0 controlled rotations
(`cqrt_rz`/`cnot`/`toffoli`/`cswap`), 2 balanced fp-select flag mint/strip/free pairs (4
`cqrt_copy_f64_controlled`); tainted `floor`/`rint` lower as reversible templates.
Surviving `@llvm.*` are keep-set leaves only (`floor`/`fmuladd`/`maxnum`/`minnum`/`rint`).
Census diff is surgical: only these 2 flip. ZERO core-pass/runtime-YAML change; pure
additive corpus + e2e + docs.

## Re-measurement 2026-07-10 (3c6m.27/.28 — erf/erfc L2-closure; 15/32 → 17/32)

> HISTORY, frozen at 17/32. Live number: `injection_summary.json`.

**`erf` (3c6m.27), `erfc` (3c6m.28)** flip decline→`COMPILES` via authored branchless
bodies (`branchless/{erf,erfc}.c`; e2e twins `tests/e2e/slice_branchless_{erf,erfc}.c`).
These were the **deepest** branchy libm body — openlibm `s_erf.c` dispatches FIVE `|x|`
segments in a nested `if`-ladder plus an exp-based asymptotic (the L2/L6 blocker at
`s_erf.c:238`, the `__ieee754_exp` call). The branchless rendering keeps openlibm's OWN
minimax coefficients but replaces the range ladder with the **atan pattern**:
CONSTANT-operand fp selects producing 0/1 regime **weights** that feed an
**unconditional weighted sum** (`w1*R1 + w2*R2 + w3*Rexp`, exactly one weight = 1), so
every regime formula is evaluated on a **clamped** (finite) argument and clang -O1
**cannot branch-ify** the expensive exp regime onto one arm — the tainted-control decline
this body exists to avoid. `0*finite = 0` keeps the blend bit-exact. The exp asymptotic
rides the **L2-closure spine**: `exp(y) = 2^n*(expm1(r)+1)` with `r` reduced near 0 (where
`expm1` is ≤2 ulp and the `+1` never cancels) and the `2^n` scale **split** into two
half-exponents so a large-negative `y` underflows cleanly to 0 (the `erfc` tail) — it
CALLS `expm1`, resolved by the census closure-link to `branchless/expm1.c` and inlined
(mirrors `sinh`/`cosh`→`expm1`). Both are faithful branchless renderings over openlibm's
own coefficients, spot-checked to a few ulp (the runtime is trace-only, so classical ulp
is a sanity check on the injected body, NOT a coverage gate — the gate is `decline→COMPILES`
+ the e2e link/diff). 0 in-domain NaN/Inf. `te` is clamped to `[1.25,30]` so `z²` never
overflows: `erf=±1` for all `|x|∈[6,DBL_MAX]`, `erfc=0` in the underflow tail (≥~27.23);
inf/NaN UNSPECIFIED (te-clamp gives the correct ±1 / 0,2 limits, NOT NaN). Surviving
`@llvm.*` are keep-set leaves only
(`fmuladd`/`fabs`/`copysign`/`minnum`/`maxnum`). Census diff is surgical: only these 2
flip. ZERO core-pass/runtime-YAML change; pure additive corpus + e2e + docs.

## Re-measurement 2026-07-10 (3c6m.23/.18/.20/.22/.45/.26 — L2-closure batch; 9/32 → 15/32)

> HISTORY, frozen at 15/32. Live number: `injection_summary.json`.

**`atanh` (3c6m.23), `acosh` (3c6m.18), `asinh` (3c6m.20), `atan2` (3c6m.22), `sinh`
(3c6m.45), `cosh` (3c6m.26)** flip decline→`COMPILES` via authored branchless bodies
(`branchless/{atanh,acosh,asinh,atan2,sinh,cosh}.c`; e2e twins
`tests/e2e/slice_branchless_*.c`). These are the **L2-closure** shape: each is a compound
transcendental that reduces to an L1 leaf already in the corpus and CALLS that leaf by its
libm name — `atanh`/`acosh`/`asinh` → `log1p`, `atan2` → `atan`, `sinh`/`cosh` → `expm1` —
resolved by the census closure-link to the authored `branchless/<leaf>.c` (indexed first)
and inlined, so the whole body injects as straight-line opcodes (mirrors `tanh`→`expm1`).
All renderings are **overflow-safe and cancellation-free** (per-file headers): `atanh` on
`|x|` (log1p well-conditioned; a signed-`x` form is 52782 ulp near ∓1), `acosh` via
`sqrt(x-1)*sqrt(x+1)` (product split → no `x*x` overflow, no near-1 cancellation), `asinh`
via `fmin` of the naive and reciprocal `sqrt(x*x+1)` (IEEE fmin drops the NaN/inf arm) +
the div-first `ax*(ax/(1+s))` correction (overflow-safe AND keeps the near-0 `x²/2`),
`atan2` via constant-operand quadrant selects (the probe's constant `x=0.5` folds them to
the `x>0` half-plane), `sinh`/`cosh` via the bounded `t/(t+1)` / `1/e` reconstructions
(no `t²`/`e²` overflow). Accuracy (worst **true**-ulp `|g-ref|/ulp(ref)` vs host
long-double, with the **branchless leaf composed** — a host-leaf sweep understates it,
since the ≤2-ulp branchless `log1p`/`expm1`/`atan` leaf dominates): `acosh` ≤4.0
(observed ~3.97), `sinh` ≤2.7 (~2.64), `atanh` ≤2.5 (~2.45), `asinh` ≤2.1 (~2.05),
`cosh` ≤1.7 (~1.59), `atan2` ≤1.35 (interior ~1.18). Per-body
UNSPECIFIED edges documented honestly (poles → NaN; `x<1`; the last overflow octave
`x > DBL_MAX/2` where `acosh`/`asinh` → NaN; the `x=0` atan2 axis). **Harness note (3c6m.10 L2-closure):** the census now builds the authored
corpus AND the probe with blanket `-fno-builtin` — required because clang -O1 rewrites an
errno-FREE transcendental leaf call (`atan`) into the `@llvm.atan.f64` intrinsic, which
closure-link cannot resolve to `branchless/atan.c`; blanket `-fno-builtin` keeps every
libm-named leaf a resolvable named call, and matching it on both sides keeps the O2
inliner's no-builtin superset check satisfied (revises the old "bodies compile plain"
rule — see `inject_census.py`). Surviving `@llvm.*` are keep-set leaves only
(`fmuladd`/`fabs`/`copysign`/`sqrt`/`minnum`). Census diff is surgical: only these 6 flip.

## Re-measurement 2026-07-10 (3c6m.37/3c6m.35 — L1 log2/log10; 7/32 → 9/32)

> HISTORY, frozen at 9/32. Live number: `injection_summary.json`.

**`log2` (bd 3c6m.37) and `log10` (bd 3c6m.35)** flip decline→`COMPILES` via authored
branchless bodies (`branchless/log2.c`, `branchless/log10.c`; e2e twins
`tests/e2e/slice_branchless_log{2,10}.c`). openlibm's `e_log2.c`/`e_log10.c` are
**already branchless in their core** — the *only* control flow was the leading
special-case ladder (`x` subnormal / `x<=0` / inf / NaN / `x==1`, `src/e_log{2,10}.c:50`,
the `L6-nested-ctrl` blocker). The bodies drop exactly those data-dependent branches, do
the `{k,1+f}` reduction with the proven full-64-bit boundary-shift bit trick (== `log.c`,
ZERO selects), then run openlibm's **verbatim** extra-precision combining: `log(m)=hi+lo`
(`SET_LOW_WORD(hi,0)` as a bitcast+`and`+bitcast round-trip) scaled by `1/ln2` resp.
`1/ln10` with `k` (resp. `k*log10(2)`) added by a Dekker two-sum. `log2` is **exact at
powers of two** (`k` integer-exact, `m==1 ⇒ log2(m)==0`); ~1 ulp on finite normal `x>0`;
`x<=0`/inf/NaN/subnormal UNSPECIFIED (the omitted branches). Surviving `@llvm.*`:
`llvm.fmuladd.f64` only (keep-set leaf). This closes the `L6-nested-ctrl` census tickets
for `log2`/`log10` (the leaf was never truly "nested control flow" — it was a removable
special-case ladder around an already-branchless core).

## Re-measurement 2026-07-10 (3c6m.10 — L1 authored branchless bodies; FIRST landing snapshot)

> HISTORY, frozen at the first landing (2/32). Superseded by later L1 batches
> (→5/32 `cbrt`/`log1p`/`expm1`, →7/32 `atan`/`tanh`). Live number: `injection_summary.json`.

**First scoreboard movement: 0/32 → 2/32.** The L1 spine (bd `3c6m.10`) landed its first
authored body — a **branchless double `log`** — and promoted the proven 3c6m.7 branchless
`exp` into the same corpus. Both flips are **injection merit** (real C bodies inlined to
stock opcodes + lowered, Rule 18), **zero pass change**.

| Scoreboard | Number | What it means |
|---|---:|---|
| **Injection-covered** (the campaign number) | **2 / 32** | `exp`, `log` — both **authored-branchless** bodies |
| **Recognition-covered** (fixed hardware floor) | 12 stems here (probe.py's full number is separate) | the hardware keep-set — disjoint, **not** injection progress |

1. **Authored-body corpus** (`branchless/<fn>.c`): the census now injects a hand-authored
   BRANCHLESS soft-body when one exists, **shadowing** the branchy openlibm one (indexed
   first in the symbol index; `closure_link` resolves to the first definer). Provenance is
   recorded per fn as `body_source` (`authored-branchless` vs `openlibm`) in
   `inject_results.json` and as `authored_branchless_fns` in `injection_summary.json`, so
   the injection number can never silently morph into an "openlibm compiles" claim.
   Authored bodies compile with the **same flags as the corpus** (`clang -g -O1`, no
   `-fno-builtin` — a `"no-builtins"` definition attribute would make the probe caller's
   `no-builtin-<fn>` set a non-superset and the O2 inliner then *refuses to inline*:
   `TLI areInlineCompatible` / `InlineCallerSupersetNoBuiltin`).
2. **`log` (authored)** — musl's core algorithm, branch-free: the canonical boundary-shift
   bit trick on the full 64-bit word (pure `i64 add/ashr/and`, **zero selects**) centers
   `m ∈ [√2/2, √2)` *exactly* for every finite normal `x > 0`, then musl's `Lg1..Lg7`
   minimax on `s = f/(2+f)` + two-constant `ln2` split. Classically validated against host
   libm: **worst case 1 ulp** across the full normal exponent range (~82k samples + exact
   boundary probes). e2e golden twin: `tests/e2e/slice_branchless_log.c`.
3. **`exp` (authored)** — the proven 3c6m.7 body (`tests/e2e/slice_branchless_exp.c`),
   verbatim: one kjd1 fp-data select (round bias) + Horner + INSERT_WORDS 2^n scale.
4. **Surviving-call regex fix** — `call[^@]*@` could match from a `"call"` inside an
   attribute comment **across the newline** into the next line's dead `declare @llvm.*`
   (the scalarizer leaves dead declares; `dce` does not remove declarations), false-reporting
   call-free declares as survivors. Now `call[^@\n]*@`. Reporting-only; the COMPILES
   criterion (fully inlined + `cq-lowering` exit 0) is unchanged.
5. **Blocking source lines populated** — this run's corpus was built with `-g` (the 3c6m.9
   REPRODUCE recipe), so all 30 remaining declines now carry a real openlibm
   `<file>:<line>:<col>` in `blocking_loc` (was empty in the 3c6m.8 snapshot).

The 30 remaining genuine-injection declines are **byte-identical in status + lever** to the
3c6m.8 snapshot (re-verified by diff): L6 `acos asin atan atanh cbrt expm1 hypot log10 log1p
log2 logb pow remainder tanh` (14), L2 `acosh asinh atan2 cosh erf erfc sinh` (7), L5-shadow
`cos nextafter sin tan` (4), L5-qrom `exp2 fmod` (2), L4 `fdim scalbn scalbln` (3). The
census→tickets bridge closes `3c6m.34` (`log`) and `3c6m.29` (`exp`) and refreshes the rest
with their now-real blocking source lines.

## Re-measurement 2026-07-10 (3c6m.8 — census honesty)

The `inject_census.py` harness was hardened (bd `3c6m.8`, mechanizing the p119
blocker-audit's own recommendations — harness-only, **zero pass change**):

1. **Scalarizer** in the inline pipeline (`…default<O2>,scalarizer,instcombine,dce`) — a
   surviving SLP `<2 x double>` op (`fmuladd.v2f64` / `vector.reduce.or`) was **masking**
   the real blocker as a bogus "unsupported instruction". De-vectorizing **reclassifies**:
   `log2`/`log10` → *nested control flow*, `erf`/`erfc` → *nested `exp()` unknown-callee*.
   It compiles **0** extra functions — it only makes the categorization honest.
2. **Per-arg int types** — `scalbn`/`scalbln` take an **int** 2nd arg; probing it as a
   `double` left the openlibm body unresolvable (signature mismatch → a *false* "unknown
   callee"). Fixed, they now link and reclassify to their real **control-flow** blocker.
   (`ldexp` is an asm-level alias `.set ldexp, scalbn`, invisible to `llvm-link` — a harness
   gap, annotated; its true result == `scalbn`.)
3. **Hardware-kept exclusion** — the recognition keep-set (`sqrt fma floor trunc round ceil
   rint nearbyint fmax fmin` **and** `fabs`/`copysign`) is partitioned out of the injection
   tally: those lower by **recognition**, so their soft-body injection decline (or fold-to-
   `@llvm.*` "compile") is **moot**. `fabs`/`copysign` "COMPILE" in the raw census only
   because `clang -O1` folds their bit-tricks to `@llvm.fabs`/`@llvm.copysign` — they never
   exercise a raw injected opcode, so they are **recognition wins, not injection wins**.

### The TWO DISJOINT scoreboards (owner rule, bd `libm-scoreboard-two-numbers`)

| Scoreboard | Number | What it means |
|---|---:|---|
| **Injection-covered** (the campaign number) | **0 / 32** | genuine `math.h` library bodies that inline to opcodes + lower — an **honest floor** |
| **Recognition-covered** (fixed hardware floor) | 12 stems here (probe.py's full number is separate) | the hardware keep-set — disjoint, **not** injection progress |

**Never merged.** A library function that declines under injection stays declined (and is
ticketed, bd `3c6m.9`) until its *injected body* lowers; recognition is never a fallback.

### The 32 genuine-injection declines, by campaign lever (the `3c6m.9` ticket feed)

| Lever | Count | Functions |
|---|---:|---|
| **L6** nested tainted control flow | 15 | `acos asin atan atanh cbrt expm1 hypot log log10 log1p log2 logb pow remainder tanh` |
| **L2** nested-transcendental closure | 7 | `acosh asinh atan2 cosh erf erfc sinh` |
| **L5** tainted scratch memory (Shadow) | 4 | `cos nextafter sin tan` |
| **L5** dynamic-index const-table read (QROM) | 3 | `exp exp2 fmod` |
| **L4** fp-select chain / compound cond | 3 | `fdim scalbn scalbln` |

Harness link-gaps (not real blockers): `ldexp` (asm alias), `lgamma` (wrapper closure),
`tgamma` (no double body in openlibm). *Not one* decline is a missing opcode. Raw per-fn
results: `inject_results.json`; machine-readable scoreboard: `injection_summary.json`.

### The census→tickets bridge (`3c6m.9` — a decline is a bug ticket, never terminal)

The owner operating rule (2026-07-09, bd `libm-campaign-pivot`) is: **accept needs
proof, but a DECLINE BECOMES A BUG TICKET.** `census_to_tickets.py` mechanizes it —
an **idempotent reconciler** that burns every genuine-injection decline above into one
bd issue under the campaign epic (`test_C_libtooling-3c6m`), keyed by metadata
`census_fn` (marker label `libm-census-decline`):

```
python3 tools/library_coverage/census_to_tickets.py            # DRY-RUN: print the plan
python3 tools/library_coverage/census_to_tickets.py --apply    # file/refresh the bd tickets
python3 tools/library_coverage/inject_census.py --file-tickets  # census + bridge in one shot
```

Each ticket is a `bug` carrying the **decline diagnostic string**, the **blocking source
line** (the diagnostic's `!dbg` `<file>:<line>:<col>` — real only when the openlibm corpus
was built with `-g`; otherwise stated as unavailable), the **lever** classification
(`lever-*` label + `census_lever` metadata), and a **depends-on edge to the lever ticket**
(L2→`3c6m.11`, L4→`3c6m.12`, L5-qrom→`3c6m.13`, L6→`3c6m.14`; L5-shadow has no dedicated
child yet) so the decline is `bd ready`-blocked until that lever lands. Re-runs **update in
place, never duplicate**; a fn that flips decline→`COMPILES` **closes** its ticket, a
re-decline **reopens** it, and a lever **reclassification** re-labels + re-points the edge.
Only `bucket=="injection"` declines are ticketed — the moot hardware-kept (recognition wins)
and harness-gap fns are deliberately excluded.

---

> **Point-in-time findings, 2026-07-02** (this box: x86_64 darwin, Homebrew LLVM 19,
> real `cq-lowering` pass). A naïve off-the-shelf-libm baseline, deliberately
> measured to learn requirements.

## What this measures

The [`COVERAGE.md`](COVERAGE.md) census measures the **template-recognition** strategy:
`cq-lowering` recognizes a `math.h` intrinsic/libcall by name and emits a *per-function
frozen reversible template* (`cq_template_<fn>`). This census measures the **opcode-lowering**
strategy instead: inject an existing libm's **source** so LLVM inlines it to stock **opcodes**
*before* `cq-lowering`, and let taint propagate through those opcodes — **no per-function
template, no hand-written quantum routine.**

Pipeline, per function (all pre-IR-pass except the last step):

```
clang -O1 -fno-builtin-<fn>   # the call becomes a NAMED @fn (not @llvm.<fn>)
llvm-link probe.bc openlibm-<fn>-closure.bc   # inject openlibm's real body + its kernels
opt internalize, always-inline, globaldce, O2 # decompose the body to opcodes
opt -passes=cq-lowering                        # <-- accept or loud-decline (measured here)
```

Source = **openlibm** (JuliaMath/openlibm), compiled to bitcode with the installed clang.
It is **not on the machine by default** (system libm is native machine code, uninlinable);
the census clones it to scratch. `alwaysinline` is forced on the openlibm bodies (mirrors how
a vendored soft-lib would be marked); dependency-closure linking pulls each function's kernels.

A function counts **COMPILES** only when its body is **fully inlined** (no surviving `@fn`
call) **and** `cq-lowering` exits zero. A surviving `@fn` call is *not* a compile (exit-zero
on an un-inlined call is meaningless — see "Over-accept" below).

## Headline result

**44 `math.h` double functions censused · 3 COMPILE · 41 decline — and not one decline is on a
missing opcode.**

| Outcome | Count | Functions |
|---|---:|---|
| ✅ **COMPILES** (straight-line bit-ops) | **3** | `fabs`, `nearbyint`, `copysign` |
| ❌ tainted **control flow** (nested range-reduction branches) | 23 | `asin acos atan sinh cosh tanh asinh acosh atanh expm1 log log1p logb cbrt floor trunc round ceil atan2 pow remainder fdim scalbn` |
| ❌ tainted **memory** (multi-word scratch buffers → Phase-7.5 Shadow) | 14 | `sin cos tan exp exp2 log2 log10 rint hypot fmod fmax fmin nextafter erf` |
| ❌ taint-escape / other | 2 | `sqrt`, `fma` (openlibm's software `fma` is a large multi-precision body) |
| ❌ not separately re-injected (harness link gap; polynomial+branch family) | 2 | `erfc`, `lgamma` |

`copysign` compiles for the `(quantum, classical)` mixture; the `(quantum, quantum)` mixture
surfaced the **only opcode-ish gap** in the whole census — a missing template for that shape.

## The requirement map (what we learn)

1. **Opcodes are not the blocker — they are essentially complete.** Every transcendental
   inlines to `fadd/fmul/fsub/fdiv/fcmp` + casts, all of which `cq-lowering` already lowers
   (the `opcode_table.yaml` fp-arith family, f16–f80). Zero declines were "no opcode." The
   opcode-lowering premise is **sound**.
2. **Blocker #1 — tainted control flow at scale (23 functions).** Off-the-shelf libm does
   argument range-reduction and special-casing with data-dependent branches (e.g. `sin`/`cos`
   carry 126+ branches). `cq-lowering` routes only specific diamond/switch shapes and declines
   the rest ("control flow under quantum control").
3. **Blocker #2 — tainted memory / Shadow (14 functions).** Multi-word range reduction writes
   the reduced value into a scratch `double[]` and reads it back — a tainted store→load that is
   Phase-7.5 QRAM/Shadow territory ("tainted value stored to memory").
4. **Consequence.** Injecting *off-the-shelf* libm is blocked almost entirely by control flow +
   scratch memory. Two ways forward, both compatible with the opcode-lowering premise:
   - build tainted-control-flow-at-scale + Shadow support (large core work), **or**
   - inject **branchless, register-only** implementations (the reason Bennett.jl's `soft_*` are
     branchless integer bodies — branchlessness, not integer-ness, is what keeps them lowerable;
     see the `math-source-injection-opcode-lowering` bd memory).
5. **Only pure straight-line bit-functions compile today** (`fabs`, `nearbyint`, `copysign`) —
   exactly the functions with no control flow and no scratch memory.

## One strategy for library functions (p119)

Under Rule 18 these are **no longer two coexisting strategies**. Recognition is
retired for library functions; source injection is the only way to compile them.
Recognition survives only for the hardware-backed intrinsics (the leaves an
injected body reduces to).

| | Hardware-backed recognition | Source-injection (library functions) |
|---|---|---|
| Applies to | `sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma lrint llrint` | all transcendentals + direct-libm + by-ref |
| Mechanism | `@llvm.<fn>` (HW instr, no body) → `cq_template_<fn>` | inject source → inline to opcodes → taint |
| Per-fn frozen ABI symbol | yes (the 14 survivors) | **no** |
| Without injection | lowers | **loud decline** (kMsgUnknownCallee) |
| math.h reach | 14 hardware stems (+ opcode-macros) | off-the-shelf openlibm: ~0 fully compile (control-flow / scratch-memory blocked) |

## Caveats (honest)

- **Naïve baseline.** These numbers are *off-the-shelf openlibm*, which is branchy and
  memory-heavy by design. Branchless/register-only implementations would compile far more — the
  3/44 is the floor, not the ceiling of the injection approach.
- **Harness gaps.** `erf`/`erfc`/`lgamma`/`ceil` initially mis-reported as "no impl" due to a
  greedy dedup/link gap; re-injected individually, `ceil`→control-flow and `erf`→memory. `erfc`
  and `lgamma` were not separately re-injected (link closure gap) — they belong to the
  polynomial+branch family.
- **Potential over-accept (needs a fix, not part of the count).** A tainted value passed to an
  *undefined* `memory(none)` libm declare (e.g. `@erf` when its body is not linked) made
  `cq-lowering` **exit-0** instead of declining — it neither lowered nor loud-declined the
  tainted arg into an unknown pure callee. This looks like a silent-accept gap in the
  taint-escape guard for `memory(none)` externals and should be investigated independently of
  this census (Prime Directive).

## Re-measurement 2026-07-06 (p119 — live, with surviving-`@llvm.*` instrumentation)

Re-ran on the p119 pass (recognizers removed; only hardware-backed intrinsics kept)
over a freshly cloned openlibm corpus (217/242 `.c` → bitcode). `inject_census.py` now
records, per function, the `@llvm.*` intrinsics that **survive** the injection+inline.

| Outcome | Count | Functions |
|---|---:|---|
| ✅ **COMPILES** (fully inlined + lowers) | **2** | `fabs`, `copysign` |
| ⚠️ exit0-but-uninlined (harness `fegetenv`/lifetime gap) | 1 | `nearbyint` |
| ❌ decline (nested control flow · tainted memory · nested transcendental · vector) | 41 | everything else |

**The surviving-`@llvm.*` report is the empirical validation of the p119 keep-set.** Every
injected libm body bottoms out in exactly the kept hardware leaves — `llvm.fmuladd.f64`
appears in **nearly every function** (the Horner-polynomial workhorse — this is precisely
why `fma`/`fmuladd` MUST be kept; drop it and *nothing* inject-compiles), alongside
`llvm.fabs` / `llvm.sqrt` / `llvm.copysign` / `llvm.floor` / `llvm.rint` (all kept) and the
kept integer intrinsics (`ctlz` / `fshl` / `smax` / `umin` / `umax`). The **blockers** are, as
before, not missing opcodes: (1) nested/tainted **control flow** (the range-reduction
branches), (2) tainted **scratch memory**, (3) **nested transcendentals** — openlibm's
`sinh`/`cosh`/`erf` call `exp()`, `asinh`/`acosh` call `log()`, `atan2` calls `atan()`, and
those nested `@llvm.exp`/`@llvm.log`/`@llvm.atan` now **correctly decline** (they are library
functions needing their own injection; pre-p119 the recognizer would have *falsely* lowered
them via a per-fn template — p119 makes this HONEST), and (4) **vectorized** range reduction
(`llvm.vector.reduce.or`, `llvm.fmuladd.v2f64`). The COMPILE count (2) is unchanged from the
prior baseline — the honest floor holds; branchless-authored bodies remain the way up.

## Re-measurement 2026-07-03 (post kjd1 + 9ymx fp-select/loop work) — NET ZERO movement

The fp-DATA select un-staging (kjd1) and in-loop select accept (9ymx) landed on
`injection-census` 2026-07-03. Both target **blocker #1** (control flow). Re-ran this
census on the current pass via the now-**reproducible** harness `inject_census.py`
(the original was manual — that gap is now closed):

| Outcome | Count | vs 2026-07-02 baseline |
|---|---:|---|
| ✅ **COMPILES** (fully inlined + lowers) | **2** (`fabs`, `copysign`) | 3 → 2–3 (`nearbyint` now gated only by a `fegetenv` link-gap in the harness) — **no net change** |
| ❌ **nested** control flow under quantum control | 24 | the transcendentals (`asin acos atan sinh…atan2 pow hypot fmax fmin log`) |
| ❌ tainted store to memory (Shadow) | 4 | `sin cos tan nextafter` |
| ❌ unsupported instruction | 8 | `exp exp2 log2 log10 rint fmod erf erfc` |
| ❌ uninlined kernel / self-ref (harness gap) | 4 | `sqrt scalbn lgamma nearbyint` |

**The fp-select unlock moved 0 functions into COMPILES.** Verified the bodies genuinely
inline and taint reaches the internals (e.g. `atan` fully inlines to 21 fp-arith opcodes +
10 branches, then declines at a **nested** tainted branch). kjd1 unlocked *single-level*
tainted fp `select` (clang -O1 flattens a lone `?:`); openlibm's real range reduction is
*multi-level* `if/br` (decline reason is literally "**nested** control flow under quantum
control"), which the 4.4/4.5 single-diamond/switch shapes don't match. **Consequence
(unchanged): off-the-shelf branchy libm is still blocked by nested control flow + scratch
memory; the unlock only pays off with BRANCHLESS-authored bodies** (the
`math-source-injection-opcode-lowering` bd memory's thesis). Raw per-fn results:
`inject_results.json`.

## Reproduce

Requires cloning openlibm (not a runtime dependency — a one-time source fetch; the shipped
compiler would vendor its own injectable soft-lib and never download). The
`inject_census.py` harness automates the per-function pipeline; its module docstring has the
exact bitcode-corpus build commands:

```
git clone --depth 1 https://github.com/JuliaMath/openlibm <scratch>/openlibm
# build src/*.c + bsdsrc/*.c to bitcode (-I include -I src -I amd64 -I bsdsrc) into <scratch>/bc,
# then: BC=<scratch>/bc python3 tools/library_coverage/inject_census.py
# (per-function: clang -fno-builtin-<fn> -> iterative closure llvm-link ->
#  opt 'internalize,always-inline,globaldce,default<O2>' -> opt -passes=cq-lowering)
```
