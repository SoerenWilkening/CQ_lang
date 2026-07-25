# NEXT-SESSION PROMPT — libm compileability: status, taxonomy, and the next step

> **Purpose.** This is a **discussion prompt** for the next session (owner + agent).
> It captures the *complete* libm-coverage compileability picture as measured at the
> end of the 2026-07-25 session, so we can decide **what to do next** — verify, build
> the loop lever, close corpus gaps, or invest in the deep cells. It is self-contained:
> everything needed to have the discussion is below. **Do not start building before the
> discussion** — the point is to choose the next investment together.

---

## 0. How we got here (this session, 2026-07-25)

- **bd zco4 Inc 1** (`promoteVolatileScalarLocals`) was already shipped (`008384e`);
  independently re-verified (build + ctest 195/195 + real-openlibm probe) and given a
  fresh 6-lens Rule-13 adversarial re-clearance (0 silent miscompiles). PRD §1/§9
  census-honesty framing aligned (`3b64988`).
- **bd vuy6** (`feat`, `b2a878b`): the census defmap now resolves openlibm module-asm
  `.set` strong_reference aliases (`ldexp*`→`scalbn*`, `isinff`/`isnanf`→`__is*f`) by
  synthesizing forwarding shims — durable, reclone-proof; retires the fake "unknown
  callee" masks. A/B: **0 regressions**, `log10l.f80` unmasked to its honest
  `__isnanl` early-exit.
- **O1 baseline reconciliation** (`census`, `79d3179`): committed
  `full_census_O1.json` (NEW, all-widths O1) + refreshed `ld80_census_O1.json`.
  The numbers below come from `tools/library_coverage/full_surface/full_census_O1.json`.

**All three landed + pushed on branch `3c6m.14-control-l6`.**

---

## 1. Current coverage — 68 / 123 = **55%** (injection-covered, O1)

| width | COMPILES / cells |
|---|---|
| f32 | 24 / 41 |
| f64 | 25 / 41 |
| **f80** | **19 / 41** (the hard half) |
| **total** | **68 / 123 (55.3%)** |

**Two-numbers discipline (Rule 2 — never conflate):**
- **Injection-covered = 68** (the census `cq-lowering` accepts the real openlibm body).
- **Verified = a SEPARATE number** (a committed real-openlibm `slice_libm_real_*`
  golden that LINKS + RUNS + byte-matches at the true `clang -O1 → cq-lowering` ship
  floor). **68 is an UPPER BOUND** on the ship floor: the census `default<O1>` cleanup
  (SimplifyCFG/instcombine) pre-flattens some control the real ship floor leaves — so
  some of the 68 might not survive `run_slice.sh`.

> **✅ RESOLVED 2026-07-25 by bd `3c6m.58` (the verify-first step of §3 below).**
> Verified was **re-measured at 53**, not the "~42–47" guessed above (53 committed
> goldens, all wired, full ctest green). The 15-cell gap was then closed: goldens were
> minted for `expm1l` `fdim` `fdimf` `frexp` `frexpf` `frexpl` `llroundl` `lroundl`
> `modfl` `nextafter` `nextafterf` `nextafterl` `nexttoward` `sinhl` `tanhl`, and
> **ALL 15 HELD at the true ship floor → verified 53 → 68 = injection-covered.**
> Full ctest **210/210**. So for THIS O1 baseline the upper bound is **tight**: the
> answer to §4.2 is a measured **NONE** — zero census-pipeline-only cells. The caveat
> remains live for any *future* census-COMPILES cell until its golden is minted.
> (It was NOT vacuous historically: under the older **O2** baseline 4 of 48 —
> `log1p{,f}`/`atanh{,f}` — genuinely failed at -O1; they are honest declines in
> `full_census_O1.json`.) Scope notes recorded in `full_surface/README.md`: the by-ref
> cells' goldens verify the return-value half only (the census probe never reads the
> out-param, so clang DCEs the stores — measured, and NOT a capability gap: a
> live-out-param `frexp` variant also compiles clean).

---

## 2. The compileability taxonomy — a clean partition of the 55 declines

Verified this session by 3 parallel research lenses + a reconcile lens (all read the
committed census JSON, `FULL_DEPTH_CENSUS.md`, `peel_census_merged.json`, bd memories,
and CLAUDE.md Rule 18) and spot-checked against the live corpus. **Counts: 0 + 7 + 48 = 55.**

### (A) Uncompilable **BY DESIGN**: **0 cells (0%)**

There is **no** fundamental wall (no-cloning / physics / no-reversible-realization)
anywhere in the 123-cell surface. The peel census "**zero C-physics walls**" finding is
**CONFIRMED** — not by the census self-check (which is *vacuous*: `synth_census.py` tests
6 wall-strings the pass never emits, so `cphys=[]` is guaranteed regardless of reality)
but by an **independent disassembly of all 241 openlibm bodies** (68k IR lines): **0**
`inttoptr`/`ptrtoint`, `atomicrmw`/`cmpxchg`, `invoke`/`landingpad`,
`indirectbr`/`callbr`/`blockaddress`, heap, `va_arg`, inline-asm; all 585 GEPs rooted to
stack/const-global. Every libm body is a deterministic classical permutation → reversibly
embeddable *in principle*. **Every decline is a temporary capability/corpus gap, never a wall.**

> **The `fmod`/`frem` "by-design" trap — resolved.** `fmod` folds to the in-grid `frem`
> opcode, and Bennett.jl ships **no** `frem` gate at any width (`soft_frem` is OPEN) — so
> on the **recognition/keep path** (builtins-on) `fmod` is a correctly-declined
> parity-inversion (bd `3c6m.56`, Rule 18). **BUT this does not bite the injection census
> at all:** under `-fno-builtin-fmod` the real `e_fmod.c` looped body links and the pass
> never sees a `frem` opcode. So `fmod.f64`/`fmodf.f32`'s real blocker is their
> **bit-reduction LOOP** (category C), and `fmodl.f80`'s is a **corpus header gap**
> (category B). Even the keep-path decline is a *deferred Bennett implementation*, not a
> physics wall. (Separate open item: retire/retain the CQ native `frem` recognizer +
> template — bd `3c6m.57`.)

### (B) Corpus / infrastructure gaps (NOT compiler walls): **7 cells (5.7%)**

The census can't build/link the real body, so the true capability behind them is
**UNMEASURED**. Fixing these is cheap *infra* (build-recipe / shim), not compiler work,
and would un-mask the real blocker picture.

| Cells | Reason (README REPRODUCE + bd 20xt) | Fix |
|---|---|---|
| `cosf` `sinf` `tanf` (.f32) | `s_cos/sin/tanf.c` init π/2 tables from `M_PI_2`; the corpus main build passes no `-DM_PI_2` (only the f80 trio loop does) → **bodies never built** (verified absent from `/private/tmp/bc`) | add `-DM_PI*` to the f32 trig build (mirror the f80 loop) |
| `fmodl` `remquol` `remainderl` (.f80) | need BSD `<machine/ieee.h>` (`struct ieee_ext`/`EXT_FRAC*BITS`) openlibm doesn't vendor for this target → unbuilt (`remainderl` calls the missing `remquol`) | vendor a minimal `machine/ieee.h`, or shim |
| `nexttowardl` (.f80) | no `s_nexttowardl.c` exists — needs an alias shim (kin to the vuy6 `.set` fix); would then land on `nextafterl`'s volatile-runtime Shadow blocker | alias shim `nexttowardl→nextafterl`-ish |

*(Behind the f32 trio sits the same Payne-Hanek Shadow blocker as their f64/f80 siblings.)*

### (C) Theoretically compilable, NOT yet covered: **48 cells (39% of surface, 87% of declines)**

Every one has a known, owned lever. **Ordered by leverage (cell count).**

| # | Lever — concrete blocker | Cells | Ticket / phase | Difficulty |
|---|---|---|---|---|
| **24** | **BOUNDED LOOPS** — a classically-bounded loop (Newton/poly refinement, bit-reduction) declines "loop under quantum control". Shipped 7.3/7.4 core deliberately declines these. **Split:** dirty-rail cross-iter (5, f32) · loop×control (17) · multi-break (2). | dirty-rail: `acosf` `acoshf` `asinhf` `hypotf` `powf` · loop×ctrl: `acos.f64` `acosh.f64` `asin.f64` `asinf` `asinh.f64` `acosl` `acoshl` `asinl` `asinhl` `hypot.f64` `hypotl` `logbl` `pow.f64` `remainder.f64` `remquo.f64` `remquof` `fmod.f64` · multi-break: `fmodf` `remainderf` | **8h7d** (799w.3 dirty-rail, y05j.3 multi-break, rkg1 static-K unroll, iw81.13 QRAM-in-loop); Phase 7.3–7.4 | **large** (deferred) |
| **8** | **L6 NESTED CONTROL** — fdlibm `log1p`/`atanh` 1+x arg-reduction is a depth>1 tainted `br` diamond exceeding PredMux's **-O1** accept-shape (measured O1/O2 gap: covered under census O2, not O1). | `atanh{,f,l}` `log1p{,f,l}` `log2l` `logl` | **q2wk** (PredMux -O1 accept-shape widening; sibling `1dky` deeper nests) | **medium** |
| **6** | **PAYNE-HANEK TRIG** (the DEEPEST cells) — `rem_pio2`/`rem_pio2l` arg-reduction Shadow store of `tx[]`/`iq[]`, gated by an **L3 data-dependent-trip loop** (`while(iq[jz]==0)` compress; `jz+=k` recompute-goto) SCEV can't bound. | `cos` `sin` `tan` (.f64 + .f80) | **8h7d.1** (Payne-Hanek deep loop) + iw81.16 (const-idx Shadow) + 3c6m.51 (fp80 union, f80 done) | **large / roadmap-scale** |
| **3** | **PHASE-6 IN-CLONE CONTROL** — the spec-clone of an inner helper (`lgamma`→`floor`, `powl`→`frexpl`) has multi-block tainted `br` diamonds `scanBody` rejects. | `lgamma` `lgammaf` `powl` | **5po2** (in-clone control, in progress) + 3c6m.52 (powl frexpl by-ref) | **medium** |
| **2** | **BOUNDED RECURSION** — `b_tgamma.c` is genuinely recursive (`tgamma↔neg_gam/large_gam` SCC) so it never inlines; also needs loop+control+aggregate behind the recursion barrier. | `tgamma` `tgammaf` | unscoped (Phase 6+) | **large** |
| **2** | **fp80-UNION in spec callee** — `IEEEl2bits` word-pun (bitcast-through-memory) in a transitive-spec-callee context 3c6m.51 hasn't reached (it shipped only for the straight-line/top-level union). | `lgammal` `tgammal` | 3c6m.51 (transitive-spec fp80 union) + 5po2 + bounded-recursion | **medium/large** |
| **2** | **VALUE-ARM EARLY-EXIT** — the `__isnanl` early-exit VALUE region (a controlled-return diamond whose arm is a value, at TOP level), unmasked by the vuy6 fix. `log10l` is genuinely multi-increment (also `ldexpl` done, then `frexpl` switch + rolled `__polevll` loops). | `expl` `log10l` | **zco4** (log10l) / 3c6m.51 (expl) / 65wb (controlled-return substrate) | **medium** |
| **1** | **VOLATILE-RUNTIME SHADOW** — `s_nextafter`'s algorithm-intrinsic `volatile double t=x*x` side-effect store (a *runtime*-valued volatile, unlike zco4's promotable scalar). Body links fully — the sole real compiler blocker among the memory-store f32 cells. | `nexttowardf` | Phase 7.5 QRAM/Shadow ABI (no dedicated ticket) | **medium** |

**Headline structural insight:** **bounded loops are ~half of all declines (24/55).** The
inverse-trig, hyperbolic, `hypot`, `pow`, `remainder`, `fmod` families *all* block on the
same loop capability. **8h7d is by far the highest coverage-per-effort lever.** The
Payne-Hanek trig trio (6) is the deepest — it needs a compile-time trip count for a
data-dependent reduction and even Bennett currently lacks a clean source for it.

---

## 3. Recommended next step (for discussion, not a decree)

**Verify first (cheap, high-signal), then build the loop lever.**

1. ~~**VERIFY NEXT (do this first).**~~ ✅ **DONE 2026-07-25 — bd `3c6m.58`.** The owner
   chose verify-first; the sweep goldened all 15 compile-but-ungoldened cells and **all 15
   held**, taking verified 53 → 68 = injection-covered, full ctest 210/210. It cost no
   compiler change. Expected "a handful to fall out" — **none did**, which is itself the
   result: for this O1 baseline the census is not over-reporting. (`erfcl`/`erfl` were
   already goldened by bd `20xt.2`; the vuy6-unblocked remainder was `expm1l`/`tanhl`.)

2. **→ NOW THE LIVE RECOMMENDATION: build the loop lever (8h7d).** 24 cells behind one
   capability family — nothing else comes close on coverage-per-effort. With step 1 done,
   the 68 is now a *trustworthy* floor to build on rather than an unaudited upper bound,
   so investment decisions can be made against it directly.

---

## 4. Open questions to decide together

1. ~~**Verify-first vs. build-first?**~~ ✅ **ANSWERED** — owner chose verify-first
   (2026-07-25); done as bd `3c6m.58`. See §3.1.
2. ~~**Which of the 68 are census-pipeline-only?**~~ ✅ **ANSWERED: none.** All 15
   previously-ungoldened cells held at the true ship floor. The remaining live question is
   the narrower one this surfaced: the **by-ref cells** (`frexp{,f,l}`, `modf{,f,l}`) are
   censused with a dead out-param, so both the census AND their goldens exercise only the
   return-value half. A live-out-param `frexp` was measured and also compiles — so no
   capability gap — but if we ever want the scoreboard to mean "the whole function
   compiles", the by-ref probe convention should change. **Worth deciding: leave the
   convention (and keep the caveat documented), or widen the probes?**
3. **Close the 7 corpus gaps?** Cheap infra (add `-DM_PI_2` to the f32 trig build; vendor
   a minimal `machine/ieee.h`; a `nexttowardl` alias shim). Un-masks the real blockers for
   +7 cells' worth of honest measurement. Worth doing before deciding the loop investment?
4. **Loop lever (8h7d) scope** — full bounded-loop support is large. Do we want the whole
   24, or a first increment (e.g. the 5 f32 dirty-rail, or the multi-break widening for
   `fmodf`/`remainderf`)?
5. **Payne-Hanek trig trio (6, deepest)** — invest (roadmap-scale, and Bennett lacks a
   clean source) or explicitly defer?
6. **Refresh the O2 baseline?** This session refreshed only the O1 files; the O2 headline
   (`first_blocker_refreshed.json` = 48/123) is intentionally stale. Refresh for parity?
7. **`frem` recognizer (bd 3c6m.57)** — retire or retain the CQ native `frem` template
   (the parity-inversion Bennett can't realize)?

---

## 5. Pointers (everything needed to reproduce / dig in)

- **Census data:** `tools/library_coverage/full_surface/full_census_O1.json` (all-widths O1,
  the source of every number here) · `ld80_census_O1.json` (ld80 O1) ·
  `README.md` banners (methodology, corpus REPRODUCE, the O1-reconciled banner).
- **Depth analysis:** `tools/library_coverage/FULL_DEPTH_CENSUS.md` (peel census, lever map,
  the zero-walls scan) · `peel_census_merged.json` (per-cell full blocker STACKS).
- **Re-run the census (O1, all widths):** `BC=/private/tmp/bc OPENLIBM=/private/tmp/openlibm
  CENSUS_OPTLEVEL=O1 python3 full_census.py` (writes `full_census_results.json`). Corpus is
  reboot-transient — rebuild per README REPRODUCE if `/private/tmp` was wiped. **Gotcha:**
  `peel_census.py` HARDCODES `default<O2>` (ignores `CENSUS_OPTLEVEL`) — use `full_census.py`
  or `ld80_census.py` for a true O1 measurement.
- **Tickets:** `8h7d` (loops/break widenings — the 24-cell lever) · `q2wk` (PredMux O1
  accept-shape — 8 cells) · `5po2` (Phase-6 in-clone control — 3 cells) · `3c6m.51` (fp80
  Shadow) · `zco4` (log10l, deferred multi-increment) · `3c6m.57` (frem recognizer).
- **Memories:** `bd memories libm-full-depth-peel-census-2026-07-11` (zero-walls) ·
  `fmod-frem-keep-2026-07-24` (the frem by-design nuance) · `census-module-asm-set-alias`
  (this session's vuy6 fix) · `libm-real-slice-recipe` (how to mint verified goldens) ·
  `libm-scoreboard-two-numbers` (injection-covered vs verified) ·
  `libm-coverage-source-injection-rule` (Rule 18).
- **This session's commits (branch `3c6m.14-control-l6`):** `3b64988` (zco4 PRD honesty) ·
  `b2a878b` (vuy6 .set-alias resolution) · `79d3179` (O1 baseline reconciliation).

> **Honesty guardrails (carry into any next step):** injection-covered ≠ verified (never
> quote 68 as verified); census-COMPILES is an upper bound on the ship floor; over-DECLINE
> is safe, over-ACCEPT is the one unforgivable silent miscompile (Prime Directive).
