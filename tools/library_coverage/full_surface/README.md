# Full-surface libm injection census (bd 3c6m.49 / 3c6m.50)

**⚡ PredMux L6 INCREMENT 6 — 92 → 95/123 injection-covered, 91 → 94 VERIFIED,
0 REGRESSIONS (2026-07-26, bd `oudq`).** The direct `q2wk` successor, and a
claim-gate widening again — the flatten was not touched. PredMux's **W anti-overlap
witness** gains **W6**: claim a `br`-rooted region when its MERGE ends in a
**tainted** conditional branch whose condition tree is supported *exactly when* a
phi of that merge counts as convertible. That is the fdlibm `__isnanl` early-exit
(`src/s_isnan.c:63`) inlined — a sole 2-incoming `i1` merge phi OR-ed into the
merge block's own branch — and before W6 BOTH claims were lost: the DOWNSTREAM
region rooted at that merge left at `E6-condtree` (q2wk rule (A) condition 2: a
phi in the region ENTRY is never converted, and nothing else in the pipeline
removes one), while the UPSTREAM diamond that DEFINES the phi left at
`W-witness`. Claiming the upstream one makes it a MERGE phi, `convertPhis`
rewrites it to the Inc-2 boolean algebra, and the downstream region claims
normally on the next fixpoint round. Design of record: `../../../docs/prd/
phase-07-expressiveness/3c6m.14-L6-control-predication/PRD.md` §4.4c.
**THE 3 THAT FLIP** — `log1pl.f80` `logl.f80` `log2l.f80` — were all GOLDENED
BEFORE this number was published, and all three hold at the true `clang -O1` ship
floor (`e2e-slice-libm-real-<fn>`, `opt` exit 0, deterministic byte-identical
trace), so **injection-covered and verified moved together** (95 / 94; the single
remaining gap is still `hypotl.f80`, bd `3c6m.61`). The **L6 nested control**
decline bucket is now EMPTY.
**THE WITNESS IS WRITTEN AS TWO CALLS TO THE GATE IT PREDICTS**
(`isSupportedCondTree` with and without the entry fence over `{merge}`), not as a
hand-rolled walk. The first draft WAS such a walk, and two Rule-13 lenses
independently measured it firing ~7:1 against the one stranding it exists to
unblock — nothing unsound (the E-ladder is the soundness gate), but pure
claim-order churn on already-verified cells. **A witness that predicts another
gate's answer should CALL that gate.**
**DISCLOSED EMISSION CHANGE (deliberate, verified equivalent):** three committed
ld80 goldens moved — `acoshl` 3934 → 3297, `asinhl` 3887 → 3282, `atanhl`
1626 → 1223 trace lines, all strictly SHORTER, no arithmetic-template and no
`cqrt_copy_*` count changed. A validated symbolic trace-equivalence checker
(MTBDD over compare atoms, 13 known-answer mutants) reports EQUIVALENT for all
three, with identical controlled-copy record sequences and identical residual
garbage; a basis-state differential harness agrees over 120k inputs each. The
shortening is the bd `8dwo` claim-order effect in the FAVOURABLE direction: the
old order derived both halves of a complementary compare pair, the new one
derives the merge predicate once at BP = ⊤.

**⚡ PredMux L6 INCREMENT 5 — 80 → 92/123 injection-covered, 79 → 91 VERIFIED,
0 REGRESSIONS (2026-07-26, bd `q2wk`).** The first COMPILER move since `3c6m.60`
(which was harness-only). PredMux's E6 claim gate now admits **path-predicated
branch conditions** — (A) an `i1` PHI used as a conditional-branch condition
inside a claimed region, which the flatten converts to boolean algebra, and (B) a
branch condition that is currently *untainted* but that the flatten itself will
taint (region-internal, phi-derived; the shared Inc-3 `valueWillTaintAfterFlatten`
predicate). That is `clang -O1`'s CFG-level lowering of a short-circuit `a || b`
it did not if-convert, and it is the sole blocker on the whole **fdlibm
exponent-word classification chain** (`s_log1p.c`'s
`if (hx > 0 || hx <= 0xbfd2bec4)` and every body that inlines it). Design of
record: `docs/prd/phase-07-expressiveness/3c6m.14-L6-control-predication/PRD.md`
§4.4b.
**THE 12 THAT FLIP** — `acosh{,f,l}` `asinh{,f,l}` `atanh{,f,l}` `hypotf.f32`
`log1p{,f}` — were **ALL GOLDENED BEFORE THE 92 WAS PUBLISHED**, and this time all
12 held at the true `clang -O1` ship floor (`e2e-slice-libm-real-<fn>`, `opt`
exit 0, deterministic byte-identical trace). Census-COMPILES is still only an upper
bound for anything not yet goldened (Rule 2). `REGRESSIONS: NONE` over the full
123-cell O1 re-census; full `ctest` green.
**TWO TAXONOMY CORRECTIONS this lever forced, both MEASURED:**
1. `log1pl.f80` / `log2l.f80` / `logl.f80` keep their **L6 nested control** label,
   but NOT for the reason the loops make obvious. They inline `__polevll`, whose
   Horner loops survive `clang -O1` — yet the pass's own `LoopUnrollPrepass` (trips
   2/3/5/6, all under `kMaxUnrollTrip = 8`) unrolls them between the two PredMux
   fixpoints. The ordered `CQ_PREDMUX_DBG` trace shows it: the LAST,
   outcome-deciding leave is `E6-condtree`, with no `E2-cycle` after it. (The
   trace shows leave ORDER, not fixpoint round — it cannot establish that every
   `E2-cycle` leave sits in the first round, and an earlier draft of this note
   claimed exactly that.) `acoshl.f80` inlines the SAME loops and verifies
   end-to-end by exactly that route. So the residual is a CONTROL shape and these
   are a successor-increment L6 target — **not** a bd `8h7d` loop target. The exact
   residual condition is NOT yet diagnosed: the debug names a value in the
   post-unroll module, whose numbering no longer matches stage-1, so it needs a
   fresh dump at that point (an earlier draft of this note named it from the stale
   mapping and was wrong — Rule 11).
2. `hypotl.f80` (bd `3c6m.61`) is **not** unblocked by this lever, and its gate is
   now precisely known: `E4-dataflow` on `icmp eq i80 …` — an fp80-union bit-pattern
   compare at a non-template width. That is a width/union issue, not a control shape.
   So the two numbers remain **1 apart, for that same one cell**: 92 covered / 91
   verified.
**A FAITHFULNESS DEFECT the golden round caught (bd `tkju`, filed):** 47 committed
`slice_libm_real_*.c` vendor openlibm's **software `copysign`/`copysignl` body** for
a Rule-18 **hardware keep**. Measured live, not dead code — fixing the spelling on
`acoshl` moved its trace 3954 → 3934 lines and turned 0 `cq_template_copysign_*`
into 4. `acoshl` is fixed here as the worked model; the other 47 are their own batch.
This is the slice-level twin of the census-level bug `3c6m.60` fixed.

**⚡ KEEP-SET HARNESS FIX — 68 → 80/123, 0 REGRESSIONS (2026-07-25, bd `3c6m.60`).**
The census was measuring a program the ship floor never compiles. The corpus recipe
(Reproduce step 1) builds every openlibm `.c` with a **blanket `-fno-builtin`**, so an
**inner** call to a Rule-18 **hardware keep** (`sqrt`/`fabs`/`floor`/…) resolved to
openlibm's *software* body and the closure linked it in — dragging that body's loops and
control into the cell. At the real ship floor (`tests/e2e/run_slice.sh`, plain
`clang -O1`, builtins ON) those names are **not** library functions: clang folds each to
`@llvm.<fn>.f<W>` *before* codegen and `cq-lowering` rewrites it to
`cq_template_<fn>_f<W>`. The census was self-inconsistent — `probe.py` already **skips**
the keep-set as census *cells* ("recognition-covered, no injectable body") while the
corpus injected their bodies *inside* every other cell — and Rule 18 itself specifies a
per-function `-fno-builtin-<fn>` **on the caller**, never a blanket flag on the corpus.
The cost was concrete: `e_acos.c`, `e_asin.c` and `e_hypot.c` contain **zero loops**, yet
`acos`/`asin`/`hypot` all censused as `loop-carried` declines — the loop was the injected
software `__ieee754_sqrt`'s subnormal normalize loop (`src/e_sqrt.c:118`).
**FIX** (harness only; no compiler change): `wprobe.py::keep_shims()` synthesizes one
forwarding shim per keep name and `build_defmap` registers it at the **front** of the
defmap, so `closure_link` resolves an inner keep call to the intrinsic instead of the soft
body. See **CENSUS METHODOLOGY — the hardware keep-set** below for the rules that keep this
from silently regressing.
**MEASURED (full 123-cell O1 re-census, same corpus + same HEAD plugin): 68 → 80
non-declining, `REGRESSIONS: NONE`.** The 12 that flip are
`acos{,f,l}` `asin{,f,l}` `hypot{,l}` `pow{,f}` (→ `COMPILES`) and `lgamma{,f}`
(→ `COMPILES (spec-clone)`). Counter-check that must keep holding: **`fmod.f64` still
declines** — its loop is its own (`loop under quantum control`), so the fix is not a
blanket "everything compiles now". The direction of the old error was **safe** (it made
the census UNDER-report), so no published coverage number was ever inflated — but the
*lever ranking* built on it was wrong: 7 further cells (`acosh{,f,l}` `asinh{,f,l}`
`hypotf`) re-attribute from `loop-carried` to `L6 nested control`, which makes L6/PredMux
(bd `q2wk`) the largest remaining lever at **15** cells and shrinks the "bounded loops"
bucket (bd `8h7d`) from a claimed 24 to a measured **7**.
**THE 12 WERE THEN GOLDENED BEFORE THE 80 WAS PUBLISHED — and 1 of them did NOT hold.**
Census-COMPILES is not verified (Rule 2, bd `libm-scoreboard-two-numbers`), and this time the
distinction paid for itself: 11 of the 12 mint a `slice_libm_real_*` golden that links, runs
and byte-matches at the true ship floor (each: `opt` exit 0, 0 residual `@cq_*`, 0 non-`cq`
callees, exactly 1 `cqrt_ry` + 1 `cqrt_measure`, all `cqrt_free` operands distinct, measured
handle never freed, byte-deterministic over two runs), but **`hypotl.f80` census-COMPILES and
then DECLINES at plain `clang -O1`** — `cq controlled lowering: nested control flow under
quantum control`, its five early returns forming a multi-exit funnel with a condition re-used
below its merge. That is a *ship-floor* L6 cell, i.e. bd `q2wk`'s lever, and it is the **first
measured census-pipeline-only cell** since the `3c6m.58` sweep closed the gap. Its faithful
vendoring is parked, unwired, at `tests/e2e/slice_libm_real_hypotl.c.DECLINED` as the
ready-made re-test (bd `3c6m.61`).
**SO THE SCOREBOARD IS `80` INJECTION-COVERED / `79` VERIFIED** — deliberately *not* merged.
The `3c6m.58` "the two numbers coincide" property held for that baseline and is now
re-opened by exactly one cell; do not quote 80 as verified.
**Faithfulness of the 11 new goldens was cleared by an independent 11-lens adversarial audit**
(mechanical reverse-rename diff of every vendored body, every fp literal re-encoded and compared
in order, qualifier/signedness/comparison-operator checks, keep-set legitimacy per Rule 18, and a
trace re-run): **0 silent-miscompile risks, 0 faithfulness defects in the vendored code**; every
finding was header prose, and all were corrected (the recurring lesson holds — on this class of
work the code is right and the prose drifts).
**TWO SCOPE NOTES the audit surfaced (bd `3c6m.62`), because they make two cells verify less than
their names suggest:** (1) the 2-arg cell convention pins `arg1` to the classical literal `0.5`,
which is exactly `pow`/`powf`'s `y == 0.5` fast path — clang -O1 proves the log/exp core
*unreachable*, so **zero** of `bp`/`dp_h`/`dp_l`/`L1..L6`/`P1..P5`/`cp`/`ivln2`/`lg2` survive and
those goldens verify the tainted classification prologue plus the `sqrt`/`fabs` keep routes, not
pow's numeric core; (2) `lgamma`/`lgammaf`'s `signgam` side effect is **dead-stripped** — openlibm's
`signgam` is externally linked, but the census reaches the body through `lgamma_public_shim` and
then `internalize`+DSE removes the `*signgamp = ±1` stores, which the goldens reproduce with
`static`. A measured A/B on the f32 slice (sole change: dropping `static`) gives 0 stores → `opt`
exit 0 versus 3 stores → **exit 1**, so the store-under-tainted-control is never exercised and the
externally-linked spelling declines today. Same family as the already-recorded by-ref
`frexp`/`modf` note below. Both caveats are stated in the slice headers.

**⚡ VERIFY-FIRST SWEEP — THE TWO NUMBERS COINCIDED AT 68 (2026-07-25, bd `3c6m.58`).**
⚠ *Historical: true of the 68-cell baseline this banner describes. The `3c6m.60` banner ABOVE
supersedes it — the scoreboard is now `80` injection-covered / `79` verified, because
`hypotl.f80` census-COMPILES and declines at the ship floor.*
The standing caveat below — *"injection-covered is an UPPER BOUND; verified is its own
separate, LOWER number"* — has been **closed by measurement, not by assertion**. At the
start of this sweep the O1 baseline was **68/123 injection-covered but only 53 verified**
(53 committed `slice_libm_real_*` goldens, re-measured green, superseding the stale
"~42–47" in the next-session prompt). The 15-cell gap was
`expm1l` `fdim` `fdimf` `frexp` `frexpf` `frexpl` `llroundl` `lroundl` `modfl`
`nextafter` `nextafterf` `nextafterl` `nexttoward` `sinhl` `tanhl`.
**All 15 were goldened and ALL 15 HELD at the true `clang -O1 → cq-lowering → link → run`
ship floor → verified 53 → 68 = injection-covered.** Full ctest **210/210**.
This answers the next-session prompt's open question §4.2 (*"which of the 68 are
census-pipeline-only?"*) with a measured **NONE** — for this O1 baseline the census
`default<O1>` cleanup pre-flattened nothing the ship floor could not also handle. (Contrast
the older **O2** baseline, where 4 of 48 — `log1p{,f}`/`atanh{,f}` — genuinely did NOT hold;
they are honest declines in `full_census_O1.json`.) **The upper-bound caveat is discharged
for THIS baseline only and still applies to any future census-COMPILES cell until its golden
is minted.** VERIFICATION-ONLY: no compiler change; the sole code edit was
`probe.py::_full_surface_scoreboard`, which read `compiles` from the stale **O2**
`first_blocker_refreshed.json` while globbing `verified` live — emitting the incoherent
"48 injection-covered, 68 verified". It now reads the committed all-widths **O1**
`full_census_O1.json` and counts `status != "decline"` (the older `== "COMPILES"` test
undercounted the `exit0-spec:[...]` Phase-6 spec-clone survivors — `atan2l`, `coshl`,
`sinhl`). Two measured scope notes worth carrying: (1) the by-ref cells
(`frexp{,f,l}`, `modf{,f,l}`) are probed exactly as `wprobe.make_src` builds them — out-param
declared, NEVER read — so clang -O1 DCEs every `*eptr`/`*iptr` store and those goldens verify
the **return-value half only**; a live-out-param `frexp` variant was measured separately and
ALSO compiles clean, so this is a probe-convention artifact, not a capability gap;
(2) `sinhl.f80` is `exit0-spec:['expl']` under the census harness (inner `expl` stays outlined
as a Phase-6 spec clone) but force-inlines to one straight-line body at the plain -O1 ship
floor — both routes reach `opt` exit 0; the golden pins the ship-floor route.

**⚡ MODULE-ASM `.set` ALIAS RESOLUTION (2026-07-25, bd vuy6).** `build_defmap` now
resolves openlibm `strong_reference` aliases that survive in the bitcode ONLY as
module asm (`module asm ".set ldexpl, scalbnl"` and nothing else — llvm-link/opt
treat module asm as opaque, so the alias never got an IR body and a caller's
`call @ldexpl` survived inlining as a FAKE "unknown callee" that MASKED the cell's
real first blocker). For each `.set alias, definer` pair where `definer` is a
defined function, it synthesizes the exact forwarding thunk clang emits for
`T alias(...){ return definer(...); }`, assembles it (`llvm-as`), and registers
`alias -> shim` — the durable, reclone-proof replacement for the README Step-1b
hand shims (which had to be rebuilt on every corpus wipe). This retires the
`ldexp`/`ldexpf`/`ldexpl`/`isinff`/`isnanf` corpus-gap "unknown callee" cells.
**Measured effect (O1 A/B, same corpus+plugin, fix vs. fix-stashed): 0 regressions**
(no COMPILES cell flips to decline); the 5 aliases now resolve, so `ldexpl`/`erfcl`/
`erfl`/`expm1l`/`tanhl` advance to census-COMPILES (injection-covered, NOT verified
at the time — bd `3c6m.58` has since goldened `expm1l`/`tanhl`/`sinhl`; `erfl`/`erfcl`
were already goldened by `20xt.2` and `ldexpl` by `3c6m.51` Inc 3, so ALL of these are
now verified) and `coshl`/`sinhl` to `COMPILES (spec-clone)`, while `log10l`/`expl`
(→ `__isnanl` early-exit value region), `acoshl`/`asinhl` (→ loop-carried), and
`log2l`/`logl` (→ L6 nested control) unmask to their honest DEEPER blockers. The
gates are conservative (Prime-Directive analog): a non-scalar/vararg definer
signature makes it DECLINE to synthesize (leaving the alias unresolved as before —
no wrong-signature shim can distort the census). `log10l.f80` remains a DEFERRED
multi-blocker cell — this only unblocks the honest first-blocker READING (bd zco4).

**⚡ O1 RECONCILED BASELINE (2026-07-25, bd vuy6 follow-on).** With the `.set`-alias
resolution above plus the accumulated zco4 (volatile-scalar + fp80-union promotion)
and vyqi (W5 PredMux) plugin work all landed at HEAD, the committed **O1** census
baselines were DELIBERATELY regenerated (Rule 12; the prior committed snapshots
predated this drift and a since-wiped corpus that still carried the README Step-1b
hand shims). Both use the `WP.probe` `default<O1>` pipeline, so their ld80 subsets
are byte-consistent (verified: 0 mismatches).
- **All-widths O1 first-blocker — `full_census_O1.json` (NEW, `full_census.py` @ O1):
  68/123 injection-covered COMPILES (24 f32 + 25 f64 + 19 f80), 55 decline.**
- **ld80 O1 — `ld80_census_O1.json` (refreshed, `ld80_census.py` @ O1): 15 → 19
  COMPILES/spec of 41, 0 REGRESSIONS.**

CAVEATS (the standing two-numbers discipline — Rule 2): these are **injection-covered,
NOT verified** (no goldens minted here; "verified" stays its own separate, lower
number — never quote 68 as verified) — ⚠ **THAT LAST CLAUSE IS NOW SUPERSEDED: it was
true of THIS session (vuy6 minted no goldens), but bd `3c6m.58` later goldened the
15-cell gap and ALL 15 held, so verified == 68 == injection-covered. See the
verify-first banner at the top of this file. The two numbers are still MEASURED
separately — they simply now coincide.** — and measured under the census `default<O1>`
cleanup whose SimplifyCFG pre-flattens some control the true `clang -O1 → cq-lowering`
ship floor leaves — so a census-COMPILES is an UPPER BOUND on the ship-floor count
(the standing O1/O2 methodology note). ATTRIBUTION (kept honest — the committed→refreshed
movement is NOT all this fix): the alias fix's ISOLATED effect (clean A/B, SAME plugin,
fix vs. git-stashed fix) is ldexpl/erfcl/erfl/expm1l/tanhl → COMPILES, coshl/sinhl →
spec-clone, and log10l/expl/acoshl/asinhl/log2l/logl unmasked to honest DEEPER blockers
(0 regressions); the remaining committed→refreshed ld80 movement (atan2l/nextafterl →
COMPILES, the Shadow "memory-store" cells → loop-carried/nested-control) is the cumulative
zco4+vyqi HEAD drift, NOT this fix. The **O2 files are INTENTIONALLY left unchanged**
(`first_blocker_refreshed.json` = the 48/123 O2 headline; `full_census_results.json`;
`ld80_census_O2.json`) — refreshing the O2 methodology is a separate deliberate re-census.
Note O1 (68) > the O2 headline (48): O2 threads the ld80 control nests into declines, so
O1 is the authoritative floor (bd 3c6m.51). `log10l.f80` stays DEFERRED (unmasked to its
honest `__isnanl` early-exit value region; still declines).

**⚡ DATA-SYMBOL CLOSURE + corpus completion (2026-07-18, bd 20xt).** The census
was UNDER-MEASURING: `closure_link` chased undefined *functions* only, so
data-only TUs never linked — ld80 atanl/asinl/acosl keep their coefficient
tables in `ld80/invtrig.c` (`_ItL_atanhi`/`_ItL_atanlo`/`_ItL_aT`), which also
silently failed to *build* (the corpus loop lacked `-I "$OLA"`; five ld80 files
affected, see the Reproduce section). Tables stayed `external [0 x x86_fp80]`
with no initializer: constant-address coefficient reads could not const-fold
and tainted-index reads could not classify (`matchQramAccess` needs
isConstant+hasInitializer+N>0) → fake first blockers. `wprobe.py` now closes
over data symbols (build_defmap indexes global definitions; undefined_syms
includes `@sym = external`); corpus recipe fixed. **ld80 @O1: COMPILES 11/41 →
13/41** — `atanl` (the "L6 nested control" bucket was the measurement artifact;
hand-verified LINK+RUN, 619-line trace, 2 QROM tables via the E4' claim, 0
double-frees) and `exp2l` (s_exp2l.bc was one of the silent build failures)
both flip; coshl/sinhl stay `COMPILES (spec-clone)`. Re-buckets to REAL
blockers: cosl/sinl/tanl → the shared `rem_pio2l` Shadow store
(e_rem_pio2l.h:141); erfl/erfcl → `@llvm.fshl.i32` consumption (the harness
instcombine fuses `(ix<<16)|(i0>>16)` into a funnel shift the pass has no
template for — a 7.1 opcode-surface axis, possibly census-model-only; measure
at plain -O1 before scoping); atan2l → clone-control (its inner atanl's fp
selects + table reads under spec, see bd 20xt); lgammal → now declines on the
newly-linked `sinl` body. Remaining "unknown callee" cells are the accepted
BSD-header corpus gaps (fmodl/remquol/remainderl/nexttowardl).**

**⚡ ld80 RE-CENSUS at the -O1 ship floor (2026-07-16, bd 3c6m.51 epic).** The
deferred re-census finally ran, at BOTH opt levels (`ld80_census.py` — the
focused f80 runner; `CENSUS_OPTLEVEL=O1|O2` toggle added to `wprobe.py`; JSON in
`ld80_census_{O1,O2}.json`). The methodology point is now MEASURED, not asserted:

| opt level | ld80 COMPILES | note |
|---|---|---|
| **-O1 (ship floor)** | **5 / 41** | cbrtl, fdiml, ldexpl, scalblnl, scalbnl |
| -O2 (probe default)  | 4 / 41 | fdiml drops → `L6 nested control` (instcombine threads its isnan nest) |

So the ld80 half is **-O1-favored** (O2 UNDER-counts by 1: fdiml, and log10l
re-buckets store↔spec). **-O1 is the authoritative floor.** The 41-cell f80
surface is the epic's 37 target cells + 4 extras (exp2l, fmodl, remainderl,
remquol — all corpus-gap "unknown callee"). Of the epic's **37: 5 compile, 32
decline**, bucketed at -O1:

| # | bucket | lever | cells (epic-37) |
|---|---|---|---|
| 13 | memory-store (Shadow) | mixed — off-pattern union / by-ref / volatile-runtime / integer-seeded | acoshl, acosl, asinhl, asinl, expl, expm1l, hypotl, **llroundl, lroundl** (int-seeded packs), **modfl** (by-ref), **nextafterl** (volatile runtime), log2l, tanhl |
| 6 | unknown callee | **corpus/closure gap, NOT a compiler wall** — an inner reduction call the injection didn't resolve | cosl, erfcl, erfl, nexttowardl, sinl, tanl |
| 7 | fp-copy/specialization | fp80 quantum-ARG to a specialized callee (vqlq handled the int-sig+internal-union case) — **CLEARED by `3c6m.54`; these 7 re-bucket to `control (flat/diamond)` / `5po2`, see the POST-3c6m.54 banner** | atan2l, coshl, lgammal, log10l, powl, sinhl, tgammal |
| 4 | loop-carried | Phase 7.3 (`799w`/`8h7d`) | atanhl, log1pl, logbl, logl |
| 1 | L6 nested control | PredMux accept-shape (`q2wk`) | atanl |
| 1 | control (flat/diamond) | frexp by-ref family (`3c6m.52`) | frexpl |

Reading: only **~26 of the 37 sit behind genuine compiler levers** (13 store + 7
spec + 4 loop + 1 nested + 1 control); **6 are corpus-completeness** (would need
the missing reduction bodies just to measure their real blocker). The single
biggest lever is the **memory-store (Shadow) 13** — but it is a MIX, not one
capability: the 3c6m.51 fp80-union promotion already cleared the fp80-SEEDED RMW
shape (the 5 that compile), and what remains is integer-seeded reload packs
(`lroundl`/`llroundl`, PRD §"Later"), by-ref (`modfl`, `3c6m.52`/7.5),
volatile-runtime (`nextafterl`, needs real volatile handling — NOT the etiq
const-fold), and transcendentals whose store shape needs per-cell inspection
(SHADOW is measured by decline fragment only). No C-physics walls (3c6m.50
holds). REPRODUCE: `BC=/private/tmp/bc OPENLIBM=/private/tmp/openlibm
CENSUS_OPTLEVEL=O1 python3 ld80_census.py`.

**⚡ POST-etiq (2026-07-16):** the volatile-const-LOCAL fold shipped
(`foldVolatileConstAllocaLoads` — the alloca sibling of the 3c6m.14
volatile-const-global fold: single-`Constant`-store + dominated exact-type
volatile loads on an entry-block alloca fold to the constant; loads/store/
lifetime-markers/alloca erased, so no volatile access survives into the tainted
region). **`cbrtl.f80` COMPILES + VERIFIES at the -O1 floor** (real-openlibm e2e
golden `slice_libm_real_cbrtl`, 539-line deterministic trace: both unions u/v
promote, both tainted switches route, the `vd2`/`vd1` rounding constants ride as
classical fp literals): **verified 46 → 47**; ld80 -O1 measure **4/37 → 5/37**.
NO full re-census (the -O2 injection-covered headline 48/123 is UNCHANGED).
`nextafterl` stays declined — its `t = x*x` volatile idiom stores a RUNTIME
value, excluded by the same single-`Constant`-store gate that makes the fold
sound (that cell needs real volatile handling, not a fold).

**⚡ POST-3c6m.51 Inc 3 (2026-07-16):** the MULTI-BLOCK fp80 union RMW promotion
shipped (canonicalize + PromoteMemToReg + the §4.1 per-bit padding-taint walk, bd
`3vdz`) — the Inc-1 read-only peephole is now the general fp80-seeded promotion
(live field-inserts, fp80 re-seeds, reload packs, multi-union bodies).
**`scalbnl.f80` / `ldexpl.f80` / `scalblnl.f80` COMPILE + VERIFY at the -O1 floor**
(real-openlibm e2e goldens `slice_libm_real_{scalbnl,ldexpl,scalblnl}`, byte-identical
traces by construction): **verified 43 → 46**; ld80 -O1 measure **1/37 → 4/37**. NO
full re-census (the -O2 injection-covered headline 48/123 is UNCHANGED — ld80 stays
-O1-favored). `cbrtl.f80`'s union axis now CLEARS (both unions promote, no kMsgStore);
it still declines on the ORTHOGONAL volatile-const-LOCAL rounding idiom
(`volatile double vd2/vd1` inside the tainted region — the alloca sibling of the
3c6m.14 volatile-const-global fold; proven: the same body with those two locals
non-volatile compiles end-to-end). The Inc-1 §4.1 `everyUserMasksPadding` fence is
REPLACED by the forward per-bit walk, so trunc/add-then-mask chains (coshl-style)
no longer over-decline on the fence — the remaining ld80 holds are RMW-loop/by-ref/
control shapes, not the mask idiom.

**⚡ POST-3c6m.54 (2026-07-16):** the **fp-ABI specialization gate is LIFTED** — a
Phase-6 clone now admits an fp {f16,f32,f64,f80} quantum ARG and RETURN (rewriting
the fp slots to i32 handles, Rule 15; copy-out via `cqrt_copy_f<W>`). The
re-census (`ld80_census_O1.json`, same command) shows the **fp-copy/specialization
bucket EMPTIED**: all 7 cells (`atan2l, coshl, lgammal, log10l, powl, sinhl,
tgammal`) **advance one layer** to **control (flat/diamond)** — the census
"working" (a masking gate peeled, the next blocker revealed). Their new decline is
`InBodyControl` on the inner transcendental reduction the spec candidate calls
(e.g. `coshl` → `expl x86_fp80(x86_fp80): callee contains tainted control flow
under quantum lift` — `expl`'s overflow/underflow branches are multi-block, which
`scanBody`'s single-block gate rejects). That deeper blocker is **in-clone control
flow**, tracked by **`5po2`** (Phase-6 clone declines tainted control in the
callee), NOT the fp-ABI gate. **COMPILES is UNCHANGED at 5/41** (no cell newly
compiles from fp-ABI alone; no regression). The bucket table above re-buckets:
`fp-copy/specialization 7 → 0`, `control (flat/diamond) 1 → 8` (the 7 + `frexpl`).
The fp-ABI capability itself is proven end-to-end by the synthetic full-pipeline
golden `e2e-spec-fp-arg` (a straight-line fp80 helper clones + links + runs — the
Rule-2/16 link proof, since no real ld80 cell is straight-line enough to clear
`5po2` yet). So the epic's ld80 "sits behind genuine levers" count shifts: the
7-cell fp-copy lever is now a 7-cell **`5po2` in-clone-control** lever.

**⚡ POST-3c6m.51 Inc 1 (2026-07-15):** the SHADOW lever (fp80 `union IEEEl2bits`
bit-pattern memory) shipped for the READ-ONLY idiom — the `i80` intermediate width +
`promoteFp80Union` peephole (bd 3c6m.51, memory `fp80-ld80-i80-minimal-3c6m51`).
**`fdiml.f80` is the FIRST ld80 cell to COMPILE + VERIFY at the -O1 floor** (real-
openlibm e2e golden `slice_libm_real_fdiml`): **verified 42 → 43**. NO full re-census
run yet (deferred per the ticket); the **-O2 injection-covered headline (48/123) is
UNCHANGED**. Measured directly over the 37 ld80 cells: **-O1 = 1/37 (fdiml), -O2 =
0/37** — fdiml is **-O1-ONLY**, the REVERSE of `q2wk`'s O2-only log1p family: at -O2
instcombine jump-threads the isnan nest into a control shape PredMux declines
(`nested control flow`), while the -O1 shape (after the peephole's classical
`isnan(const)`→dead-branch fold) lowers. **CENSUS METHODOLOGY:** because ld80 cells
are -O1-favored (O2 threads their control), a re-census should measure ld80 at **-O1**,
not the probe default -O2. Post-Inc-1 the 36 remaining ld80 cells re-bucket (from
"all SHADOW/kMsgStore"): **padding-fence 16, off-pattern-union kMsgStore 14 (a union
shape the peephole does not match yet — live RMW store-back = Inc 2), unknown-callee
4 (corpus gaps), fp-quantum-arg specialization 2.** The §4.1 padding fence
(`Fp80Union.cpp` `everyUserMasksPadding`) is CONSERVATIVE — it accepts only a DIRECT
`and`-mask on a padding-straddle load, so a cell that masks the padding after an
intermediate `trunc` (e.g. coshl: `load i64 → trunc i32 → and 0x7fff`) is SAFELY
over-declined (Prime Directive; those cells have deeper RMW/loop/control blockers
anyway). Widening it to a forward "padding-cleared-before-any-observable" walk is
Inc 2 (bd 3c6m.51.1, soundness-critical).


The width/by-ref/int-ret widening of `../inject_census.py` (which is hardcoded to
`double`). Injects the **real openlibm** body per cell across every width variant
(f32/f64/f80), runs `cq-lowering`, and records the actual blocking capability.

**⚡ POST-L6 headline (3c6m.14 Inc 4, 2026-07-14):** the L6 CONTROL lever (PredMux)
shipped. Re-running this census with the committed HEAD plugin: real openlibm
math.h = **48/123 injectable cells compile** (was 2), **24 f64 + 24 f32**; f80 all
still held by SHADOW. Two DISJOINT numbers (Rule 2, bd `libm-scoreboard-two-numbers`):
**injection-covered 48/123 (39%), verified 42/123 (34%)** — never quote "48 verified".
Deterministic 48/48/48 across 3 runs; census-mode flood reproduces the §4/§5 lever
map exactly. Full delta + per-lever follow-ups: `../FULL_DEPTH_CENSUS.md` §11.

**⚡ POST-3c6m.53 update (2026-07-14):** the 40 compile-but-ungoldened cells were
worked. **34 promoted to VERIFIED** (committed real-openlibm `slice_libm_real_*`
e2e goldens: the 8 originals + 23 f32 siblings + 11 f64 — `atan2 cosh erfc exp2
expm1 ldexp llround log10 log2 logb modf scalbln sinh` and the f32 set). Verified
went **8 → 42**. The remaining **4 (`log1p{,f}`, `atanh{,f}`) DECLINE at the -O1
verified floor** (`run_slice.sh`, Rule 9): their fdlibm reduction diamonds exceed
PredMux's -O1 accept shape. They are injection-covered ONLY because THIS census
measures lowerability under an **O2** pipeline (`default<O2>,scalarizer,instcombine`,
inline-threshold 2M in `wprobe.probe`) whose SimplifyCFG pre-flattens the nest into
accepted selects. So of the 48 injection-covered, **44 hold at -O1** (42 real-openlibm
goldens + 2 fdim branchless); **4 are O2-only**. The 4 correctly have NO fabricated
golden (Rule 2). O1/O2 gap + PredMux-widening follow-up: bd `q2wk`.

**First-blocker headline (3c6m.49, 2026-07-11 — pre-L6 baseline):** real openlibm
math.h = **2/120 injectable cells compile** (only `fdim` — genuinely branchless);
118 decline. The `inject_census.py` "32/32 COMPLETE" is the **authored branchless
substitutes** (`../branchless/`) that bypass every lever.

**Full-DEPTH peel headline (3c6m.50, 2026-07-11):** the first-blocker bucketing
hid the true capability combinations. The `CQ_PEEL_CENSUS` census-mode plugin
(see below) surfaces the COMPLETE per-cell blocker stack in one run. Over the
reconciled **123-cell** ISO C11 surface: **CONTROL (tainted control flow, L6
3c6m.14 + the swap-route emitter) participates in 108/123 measured, 119/123 after
corpus-masking is inferred away; 51 cells are CONTROL-ALONE; ZERO cells hit a
C-physics wall.** See `FULL_DEPTH_CENSUS.md` and bd memory
`libm-full-depth-peel-census-2026-07-11`.

## Harness files
- `wprobe.py` — width-parametric probe (build + closure-link + inline pipeline).
- `full_census.py` — first-blocker census (imports `probe.py` MATHH_SPEC, one
  blocker/cell). Writes `full_census_results.json`.
- `peel_census.py` — **full-depth** census. In normal mode = first-blocker
  (`first_blocker_refreshed.json`); with `CQ_PEEL_CENSUS=1` + the census-mode
  plugin = the complete blocker stack per cell (`peel_census_results.json`).
  Parallel over cells (defmap built once).
- `synth_census.py` — merges both runs, folds raw blocker classes into campaign
  LEVERS, emits the capability-combination -> function table + the
  cells-unlocked-per-lever ranking (`peel_census_merged.json`).
- `dump_ir.py` / `batch_dump.py` — cache one cell's inlined IR + its diagnostic.

## Census-mode plugin (THROWAWAY — never committed)
The full-depth run needs a throwaway instrumentation of the pass (bd 3c6m.50):
a `CQ_PEEL_CENSUS` env gate in `CQLoweringPass::run` that (1) installs a
non-fatal diagnostic handler — opt normally `exit(1)`s on the first `DS_Error`,
truncating the stack; the handler records every decline as a `cq-peel: <msg> @
<loc>` line and returns *handled*; (2) calls `censusFloodTaint` (an
over-approximate data-dependence closure through memory store->load and call
results) so guards see the whole body; (3) runs only the pure analysis/detection
guards and returns before any mutating stage. The instrumentation lives on a
scratch branch and is `git checkout`-reverted before commit — the committed
harness (`peel_census.py` etc.) is inert without it (falls back to first-blocker).

## CENSUS METHODOLOGY — the hardware keep-set (bd `3c6m.60`, do not undo)

**The rule.** A census cell must be lowered from the same IR the **ship floor** produces.
The ship floor is `tests/e2e/run_slice.sh`: plain `clang -O1`, **builtins ON**, one
`-fno-builtin-<fn>` on the caller so the *named* call resolves to the injected body
(Rule 18). Therefore, inside a cell, a call to a name in the **hardware keep-set** —

> `sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma lrint llrint`
> (× `f` / none / `l`; `probe.py::HARDWARE_KEEP_SET`)

— must appear as the `@llvm.<fn>.f<W>` intrinsic, **never** as openlibm's software body.
Those names have **no injectable body** by definition (Rule 18: clang folds them to an
in-grid construct before codegen, and Bennett.jl backs each one), which is exactly why
`probe.py` skips them as census *cells*.

**Why the corpus flag cannot do this.** The corpus build must keep its blanket
`-fno-builtin`: without it clang recognizes e.g. `s_floor.c`'s body as `floor` and
rewrites it into a self-call. So the keep-set correction is applied **at the defmap**,
where inner calls actually resolve, not at the corpus compile.

**How it is applied** (`wprobe.py`): `keep_shims()` compiles, per keep name,
`T s(T x){ return <name>(x); }` at `clang -O1` with **builtins ON** — i.e. under ship-floor
conditions — and renames the resulting definition to `<name>`. `build_defmap()` then
front-inserts that shim, and `closure_link` (which takes the first not-yet-linked definer)
picks it over the soft body. Three properties make this safe:

1. **The shim body is measured, not authored.** It is whatever clang emits. If the output
   still contains a non-intrinsic call — i.e. clang emits a *libcall* for that name/width
   on this target, so it is not a keep here — `_synth_keep_shim` returns `None`, no shim is
   registered, and the software body keeps winning exactly as before. Over-shimming would
   make the census **over-report**, which is the one unforgivable direction.
   (Measured on this host, LLVM 19 / x86-64+SSE4.1: all 14 stems × 3 widths fold; the C99
   spellings map to `llvm.minnum`/`llvm.maxnum` and to `llvm.{l,ll}rint.i64.f<W>`.)
2. **No link conflict is possible.** Every corpus file that defines a keep name defines
   *only* keep names (verified over all 245 `.bc`; the `s_fma`/`s_fmal` helpers
   `fesetround`/`add_and_denormalize`/`add_adjusted` are `internal` and called from their
   own TU), so a shimmed file is never pulled in for some other symbol it also defines.
3. **The probe scaffold keeps its blanket `-fno-builtin`, and that is load-bearing.**
   Measured A/B: LLVM only inlines a `"no-builtins"` callee (every corpus body is one) into
   a `"no-builtins"` caller. Dropping the blanket flag from `wprobe.probe` left `@acos`
   **outlined**, which re-routed 10 baseline-COMPILES cells through Phase-6 specialization
   and broke them. It costs no fidelity: the probe TU has no library call other than `fn`
   itself, and a ship-floor slice renames every vendored helper to `olm_*` — not a library
   name — so libcall simplification has nothing to act on there either.

**Residual, recorded honestly.** For a cell whose body calls a keep name, an older golden
may vendor the *software* helper (e.g. `slice_libm_real_lround.c` vendors `olm_round`)
while the census now models the intrinsic route. Both are real-openlibm slices and the
soft-body route is the strictly *larger* program, so those goldens remain valid — but they
verify a superset of the ship-floor route, not the identical IR. The `3c6m.60` goldens
(`acos`/`asin`/`hypot`/`pow`/`lgamma` families) use the `__builtin_<keep>` spelling and do
pin the exact ship-floor construct.

**If you touch this:** re-run the full 123-cell census and assert **0 regressions** against
`full_census_O1.json`, and keep `fmod.f64` declining (its loop is genuine — SCEV reports
`Unpredictable` for backedge-taken, constant-max and symbolic-max). A fix that makes
`fmod` compile has broken something.

## Reproduce
```bash
# 1. corpus (one-time source fetch; NOT a runtime dep)
#    NB the blanket -fno-builtin below is CORRECT and must stay (a libm source built
#    with builtins ON self-recurses: clang recognizes s_floor.c's body as `floor`).
#    It does NOT defeat the Rule-18 hardware keep-set for INNER calls any more —
#    wprobe.py::keep_shims() re-applies the ship-floor fold at the defmap. See the
#    CENSUS METHODOLOGY section above before changing either half (bd 3c6m.60).
#    clang here MUST be the LLVM-19 one (/usr/local/opt/llvm@19/bin/clang) — a
#    newer system/Xcode clang writes bitcode LLVM-19 llvm-dis cannot read.
#    -I "$OLA" (the openlibm ROOT) is LOAD-BEARING (bd 20xt, 2026-07-18): ld80
#    files include "ld80/invtrig.h"-style root-relative paths; without it FIVE
#    ld80 files (invtrig, e_fmodl, s_exp2l, s_remquol, s_truncl) silently fail
#    (the 2>/dev/null swallows it) and the census then MASKS real blockers —
#    invtrig.c is the DATA-ONLY TU holding the atanl/asinl/acosl coefficient
#    tables (_ItL_*), so atanl mis-bucketed as "L6 nested control" when it
#    actually COMPILES once the tables are linked.
git clone --depth 1 https://github.com/JuliaMath/openlibm <scratch>/openlibm
OLA=<scratch>/openlibm; mkdir <scratch>/bc
for c in $OLA/src/*.c $OLA/bsdsrc/*.c $OLA/ld80/*.c; do   # ld80 = long double bodies
  clang -g -O1 -fno-builtin -emit-llvm -c \
    -I "$OLA" -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
    "$c" -o <scratch>/bc/$(basename ${c%.c}).bc 2>/dev/null   # INLINE -I flags: zsh does
done                                                          # NOT word-split unquoted $INC
#   The trig entries need the BSD M_PI constants (same trick as b_tgamma in 1b
#   below) — without them they drop out and census as a spurious "unknown
#   callee". THE f32 SIBLINGS WERE MISSING FROM THIS LOOP until 2026-07-27 (the
#   bd tkju scoping pass): s_cosf/s_sinf/s_tanf hit the same undeclared M_PI_2
#   at src/s_cosf.c:33, so cosf/sinf/tanf mis-bucketed as "unknown callee" for
#   the whole campaign. With them built, all three unmask to their REAL blocker,
#   the Payne-Hanek reduction at src/k_rem_pio2.c:310 — i.e. the SAME capability
#   as the f64/f80 trig cells, which is how the trig lever went from an apparent
#   6 cells to a measured 9:
for b in s_cosl s_sinl s_tanl s_cosf s_sinf s_tanf; do
  clang -g -O1 -fno-builtin -DM_PI=3.14159265358979323846 -DM_PI_2=1.57079632679489661923 \
    -DM_PI_4=0.78539816339744830962 -emit-llvm -c \
    -I "$OLA" -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
    "$OLA/src/$b.c" -o <scratch>/bc/$b.bc
done
#   THE RETRACTION WAS ITSELF WRONG — RE-MEASURED 2026-07-27 (bd tegx, the L3
#   scoping pass). The 2026-07-27 tkju note claimed e_fmodl.c / s_remquol.c /
#   s_truncl.c "all three compile with rc=0 and ZERO errors under the exact flag
#   set above". MEASURED FALSE at that same corpus rev @82e90ae, this same host,
#   those exact flags:
#       e_fmodl   rc=1, 5 errors (incomplete type 'struct ieee_ext', EXT_FRAC*BITS)
#       s_remquol rc=1, 1 error  (fatal: 'machine/ieee.h' file not found)
#       s_truncl  rc=1, 2 errors (EXT_FRACHBITS undeclared)
#   The ORIGINAL bd-20xt note was right: they need BSD <machine/ieee.h>, which
#   openlibm does NOT ship anywhere in the tree (e_fmodl.c even has its #include
#   COMMENTED OUT at line 14 while still using `struct ieee_ext`). This is the
#   FIFTH corpus/bucket measurement error of the campaign; the lesson is the
#   standing one — check rc AND the error count, never rc alone, and never with
#   stderr redirected to /dev/null.
#   DURABLE FIX (in-tree, survives every reclone — the bd vuy6 lesson that
#   scratch-dir hand shims do not persist): shim/machine/ieee.h reconstructs the
#   x86 i387 fp80 layout. Its field layout is validated EMPIRICALLY by
#   shim/ieee_shim_check.c (struct view vs the raw 10 significant bytes over 7
#   known values) and the resulting BODIES are validated against the host libm by
#   shim/fmodl_remquol_check.c (1502 cases, PASS). NB s_truncl is NOT needed —
#   `truncl` resolves from src/s_truncl.c, and `remainderl` from src/e_remainderl.c;
#   only fmodl and remquol are genuine gaps. e_fmodl needs -include because its
#   own #include is commented out:
SHIM=<repo>/tools/library_coverage/full_surface/shim
clang -g -O1 -fno-builtin -emit-llvm -c -I "$SHIM" -include machine/ieee.h \
  -I "$OLA" -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
  "$OLA/ld80/e_fmodl.c" -o <scratch>/bc/e_fmodl.bc
clang -g -O1 -fno-builtin -emit-llvm -c -I "$SHIM" \
  -I "$OLA" -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
  "$OLA/ld80/s_remquol.c" -o <scratch>/bc/s_remquol.bc
#   TWO UPSTREAM DEVIATIONS the body validation surfaced, both real and neither
#   caused by the shim (recorded so a future run does not re-litigate them):
#   (a) openlibm ld80 returns n=31 quotient bits from remquol, the host n=3 —
#       both conform, C11 7.12.10.3 makes n implementation-defined (>= 3);
#   (b) OPENLIBM BUG ld80/s_remquol.c:89 — the |x|==|y| branch does `*quo = 1;`
#       where the f64 twin src/s_remquo.c:54 does `*quo = (sxy ? -1 : 1);`, so a
#       negative unit quotient loses its sign. A literal constant, no dependence
#       on <machine/ieee.h>. fmodl (the one that DOES use `struct ieee_ext`)
#       matches the host bit-for-bit in all 1502 cases.
#   STILL A GENUINE GAP: there is NO s_nexttowardl.c anywhere in the corpus
#   (openlibm ships nexttoward/nexttowardf only). It needs an alias shim like
#   ldexp's; it would land on nextafterl's volatile-runtime blocker anyway.
#   nexttowardl.f80 is therefore the ONLY remaining honest "unknown callee" cell.
#   VERIFY THE WHOLE CORPUS BEFORE ANY CENSUS RUN (251 .bc -> 409 syms):
#     BC=<scratch>/bc OPENLIBM=<scratch>/openlibm python3 -c "import sys;\
#     sys.path.insert(0,'.');import wprobe;d=wprobe.build_defmap();print(len(d),\
#     [n for n in ('cosf','sinf','tanf','fmodl','remquol') if n not in d])"
#   Expect `409 []`. 404 / 407 or a non-empty list = an incomplete corpus, and a
#   missing .bc does NOT fail loudly — it masks the cell's real blocker as
#   "unknown callee".

# 1b. CORPUS-GAP CLOSURES (bd 3c6m.50 Step 0c) — three openlibm public names are
#     minted by the build's symbol aliasing, which the raw -emit-llvm corpus build
#     does not reproduce. Rebuild these so gamma/ldexp cells hit their REAL body
#     (not a spurious "unknown callee"):
#   tgamma double body (b_tgamma.c) needs the BSD M_PI constants:
clang -g -O1 -fno-builtin -DM_PI=3.14159265358979323846 -DM_PI_2=1.57079632679489661923 \
  -DM_PI_4=0.78539816339744830962 -emit-llvm -c \
  -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
  "$OLA/bsdsrc/b_tgamma.c" -o <scratch>/bc/b_tgamma.bc
#   public non-reentrant lgamma/lgammaf/lgammal wrappers (openlibm aliases them):
cat > /tmp/lgamma_public_shim.c <<'EOF'
extern double lgamma_r(double,int*); extern float lgammaf_r(float,int*);
extern long double lgammal_r(long double,int*); int signgam;
double lgamma(double x){return lgamma_r(x,&signgam);}
float lgammaf(float x){return lgammaf_r(x,&signgam);}
long double lgammal(long double x){return lgammal_r(x,&signgam);}
EOF
clang -g -O1 -fno-builtin -emit-llvm -c /tmp/lgamma_public_shim.c -o <scratch>/bc/lgamma_public_shim.bc
#   ldexp/ldexpf/ldexpl (openlibm strong_reference(scalbn, ldexp)):
cat > /tmp/ldexp_shim.c <<'EOF'
extern double scalbn(double,int); extern float scalbnf(float,int);
extern long double scalbnl(long double,int);
double ldexp(double x,int n){return scalbn(x,n);}
float ldexpf(float x,int n){return scalbnf(x,n);}
long double ldexpl(long double x,int n){return scalbnl(x,n);}
EOF
clang -g -O1 -fno-builtin -emit-llvm -c /tmp/ldexp_shim.c -o <scratch>/bc/ldexp_shim.bc

# 2. point BC / OPENLIBM at <scratch>, then:
BC=<scratch>/bc OPENLIBM=<scratch>/openlibm python3 full_census.py     # first-blocker
BC=<scratch>/bc OPENLIBM=<scratch>/openlibm python3 peel_census.py     # first-blocker (refreshed)
# rebuild the census-mode plugin (throwaway CQ_PEEL_CENSUS instrumentation), then:
BC=<scratch>/bc OPENLIBM=<scratch>/openlibm CQ_PEEL_CENSUS=1 python3 peel_census.py   # full stack
python3 synth_census.py                                               # -> peel_census_merged.json
```
