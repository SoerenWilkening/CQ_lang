# Full-surface libm injection census (bd 3c6m.49 / 3c6m.50)

**⚡ VERIFY-FIRST SWEEP — THE TWO NUMBERS NOW COINCIDE (2026-07-25, bd `3c6m.58`).**
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

## Reproduce
```bash
# 1. corpus (one-time source fetch; NOT a runtime dep)
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
#   s_cosl/s_sinl/s_tanl need the BSD M_PI constants (same trick as b_tgamma in
#   1b below) — without them the trig trio drops out and cosl/sinl/tanl census
#   as a spurious "unknown callee":
for b in s_cosl s_sinl s_tanl; do
  clang -g -O1 -fno-builtin -DM_PI=3.14159265358979323846 -DM_PI_2=1.57079632679489661923 \
    -DM_PI_4=0.78539816339744830962 -emit-llvm -c \
    -I "$OLA" -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
    "$OLA/src/$b.c" -o <scratch>/bc/$b.bc
done
#   STILL-FAILING (accepted residual corpus gaps, bd 20xt): e_fmodl.c,
#   s_remquol.c, s_truncl.c need BSD <machine/ieee.h> (struct ieee_ext /
#   EXT_FRAC*BITS) which openlibm does not vendor for this target — fmodl /
#   remquol (and remainderl, which calls remquol) stay "unknown callee".
#   There is NO s_nexttowardl.c (needs an alias shim like ldexp's; it would
#   land on nextafterl's volatile-runtime blocker anyway).

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
