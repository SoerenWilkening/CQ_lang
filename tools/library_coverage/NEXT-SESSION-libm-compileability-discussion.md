# NEXT-SESSION PROMPT — libm compileability: status, taxonomy, and the next step

> ## ⏭ SUPERSEDED FOR PLANNING — read [`LEVER-SURVEY-2026-08-22.md`](LEVER-SURVEY-2026-08-22.md) instead
>
> Every number below is the **2026-07-25 generation** (68/123, then 80/123). The
> baseline is now **155/183 headline / 97/120 injection** *(2026-08-23, after bd
> `3c6m.63` corrected a corpus defect that had three cells measured on bodies openlibm
> does not build — it read 158/100 as surveyed on 2026-08-22)*, and the *shape* of the
> question has changed too: the "which lever is biggest" framing this doc is built
> around no longer has an answer that moves the campaign number, because **no lever
> moves the injection numerator upward** (measured 2026-08-22). Keep this file for its
> §0 history and its correction banners — they record how the 24-bounded-loop headline
> turned out to be a census harness artifact, which is still the best worked example of
> that failure mode in the tree.

> **Purpose.** This is a **discussion prompt** for the next session (owner + agent).
> It captures the *complete* libm-coverage compileability picture as measured at the
> end of the 2026-07-25 session, so we can decide **what to do next** — verify, build
> the loop lever, close corpus gaps, or invest in the deep cells. It is self-contained:
> everything needed to have the discussion is below. **Do not start building before the
> discussion** — the point is to choose the next investment together.
>
> ---
>
> **STATUS 2026-07-25 (end of session) — THE DISCUSSION HAPPENED; THIS DOC IS NOW PARTLY SUPERSEDED.**
> - §1 (coverage) — **resolved**: verify-first ran (bd `3c6m.58`), verified 53 → **68 = injection-covered**.
> - §2 (taxonomy) and §3 (recommendation) — ⛔ **WRONG, do not decide from them.** A follow-up scoping
>   investigation measured them: the "24 bounded-loop cells / biggest lever" headline is a **census
>   harness artifact** (blanket `-fno-builtin` injects openlibm's *software* `sqrt`/`floor` into every
>   other cell, defeating Rule 18's keep-set for inner calls — bd `3c6m.60`). Loops are **7/43**, not
>   24/55. See the correction banners in §2 and §3.
> - **The live plan of record is the bd memory `libm-next-steps-harness-then-q2wk`**:
>   **STEP 1** bd `3c6m.60` — census keep-set harness fix (~1 day, harness only, +12 cells, 0/68
>   regressions) → then mint goldens. **STEP 2** bd `q2wk` — PredMux -O1 nested control (15 cells).
> - **STEP 1 IS DONE (2026-07-25, bd `3c6m.60`).** The predicted numbers were *confirmed by a full
>   123-cell O1 re-census*: **68 → 80 non-declining, `REGRESSIONS: NONE`**, exactly the 12 predicted
>   cells (`acos{,f,l}` `asin{,f,l}` `hypot{,l}` `pow{,f}` `lgamma{,f}`), with `fmod.f64` still
>   declining as required. All 12 were goldened before the number was published, so
>   **injection-covered = verified = 80/123 (65%)**. The 7 re-attributed cells make bd `q2wk`
>   (L6/PredMux) the largest remaining lever at 15. Every count in §1/§2/§3 below is the PRE-fix
>   68/55 generation — read them with the correction banners, or read
>   `full_surface/README.md` (top banner + **CENSUS METHODOLOGY**) for the current picture.
> - §4 open questions 1 and 2 are answered; the rest still stand.

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

> ### ⛔ §2 AND §3 ARE WRONG — DO NOT DECIDE FROM THEM (corrected 2026-07-25, bd `3c6m.60`)
>
> A follow-up scoping investigation **measured** this taxonomy and found its central claim inverted.
> The rows below are kept for the record; the corrections are authoritative.
>
> **⚡ THE FIX HAS SINCE LANDED AND EVERY PREDICTION BELOW WAS CONFIRMED BY RE-MEASUREMENT.**
> `wprobe.py::keep_shims()` (bd `3c6m.60`) now resolves an inner keep-set call to the `@llvm.<fn>`
> intrinsic at the defmap. Full 123-cell O1 re-census, same corpus + same HEAD plugin:
> **68 → 80 non-declining, `REGRESSIONS: NONE`** — the 12 flips are exactly `acos{,f,l}` `asin{,f,l}`
> `hypot{,l}` `pow{,f}` (→`COMPILES`) and `lgamma{,f}` (→`COMPILES (spec-clone)`), and the 7
> re-attributions are exactly `acosh{,f,l}` `asinh{,f,l}` `hypotf` (`loop-carried` → `L6 nested
> control`). `fmod.f64` still declines. So the measured post-fix buckets are: **L6 nested control 15**,
> unknown-callee/corpus 7, Shadow 7, **loops 7**, control-flat 3, value-arm 2, fp-copy 2 — total 43
> declines. The methodology rule that keeps this from regressing is written down in
> `full_surface/README.md` § **CENSUS METHODOLOGY — the hardware keep-set**.
>
> **Root cause — a census methodology bug, not a compiler gap.** `full_surface/README.md:309/317/334`
> builds every openlibm `.c` with a **blanket `-fno-builtin`**, which defeats Rule 18's hardware
> keep-set for **inner calls**: a body that calls `sqrt`/`floor` gets openlibm's *software*
> implementation closure-linked in, instead of the `@llvm.<keep>` intrinsic `clang -O1` emits at the
> ship floor. The census is self-inconsistent — `probe.py:68` *skips* `sqrt`/`fabs`/`floor` as **cells**
> ("recognition-covered, no injectable body") while injecting their software bodies **inside every
> other cell**. Rule 18 itself specifies per-function `-fno-builtin-<fn>` *on the caller*.
> Reproduced A/B (same source, same pass, same inline pipeline — only the builtin flag differs):
> `acos.f64` **declines** "loop under quantum control" under the census build (the site is the software
> `__ieee754_sqrt`'s subnormal loop, `src/e_sqrt.c:118`) and **compiles clean** at the true ship floor
> (23 `cqrt_alloc`, 0 residual intrinsics). `hypot.f64` likewise (145 allocs). Counter-check:
> `fmod.f64` still declines — its loop is genuine (SCEV `Unpredictable`).
> **The error direction is SAFE — the census UNDER-reported. No published number was ever inflated.**
>
> **Corrections to the rows below:**
> - **The "24 BOUNDED LOOPS" row is mis-attributed.** 17 of the 24 do not block on a loop in their own
>   body at all — `e_acos.c`/`e_asin.c`/`e_hypot.c` contain **zero loops** (`grep`). With the keep-set
>   honoured: **10 compile today with no compiler change**, 7 become L6 cells, and only **7 are
>   genuinely loop-blocked**. Its sub-labels are also wrong: "dirty-rail cross-iter (5, f32)" is
>   entirely artifact (those 5 bodies have no loop), and "loop×control (17)" misreads the diagnostic —
>   `loop under quantum control` is emitted from ONE site (`LoopLowering.cpp:1161`, gated by
>   `taintedExit`) and means the **trip count** is quantum-dependent, saying nothing about control
>   inside the body (that is L2, a different diagnostic and a far harder fix). Ticket routing is wrong
>   too: `799w.3`/`rkg1` own **zero** cells, and the static-K unroll that actually shipped
>   (`LoopUnrollPrepass.cpp`, bd `lf8s`) is absent here and excludes all 24 by construction.
> - **The "8 L6 NESTED CONTROL" row grows to 15** (it absorbs the 7 re-attributed cells) and becomes
>   the **largest lever on the surface**. Its O1/O2 framing is also stale — in the committed O1
>   baseline all four log1p/atanh cells are plain `L6 nested control` declines.
> - **The "3 PHASE-6 IN-CLONE CONTROL" row is stale by 2:** `lgamma.f64`/`lgammaf.f32` compile under
>   the keep-fix (they blocked on the *software* `floor` body — same artifact). Only `powl.f80` remains.
> - **§2(B) "7 corpus/infra gaps" undercounts by 12** — the soft-sqrt/soft-floor artifact is a
>   corpus/infra gap of exactly the same kind. (`FULL_DEPTH_CENSUS.md:303-315` had already documented
>   it; the 2026-07-25 taxonomy dropped that caveat.) **And those 7 are NOT a cheap coverage lever:**
>   building the missing `s_cosf/s_sinf/s_tanf` with `-DM_PI*` and re-censusing yields **0 new
>   COMPILES** — all three land on "tainted value reaches an unsupported instruction". Do it for census
>   honesty, not the scoreboard.
>
> **Corrected ranking (measured):** L6/PredMux **15** > Shadow 7 = corpus gaps 7 = **loops 7** >
> control-flat 3 > fp-copy 2 > value-arm 2. **Loops are 7/43, not 24/55.**
>
> Plan of record: bd memory `libm-next-steps-harness-then-q2wk`. Tickets: `3c6m.60` (P1, the harness
> fix) then `q2wk` (15 cells).

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
embeddable *in principle*. ~~**Every decline is a temporary capability/corpus gap, never a wall.**~~

> **⚠ THAT LAST SENTENCE IS SUPERSEDED (2026-07-28).** Its *physics* half survives intact and
> is not in question: there is still **no C-physics / no-cloning wall** anywhere in the
> 123-cell surface, and the disassembly evidence above stands. What does **not** survive is the
> operational reading it invites — *"every decline will eventually be covered, so every decline
> is a lever waiting for effort."* The owner decision of **2026-07-27** (CLAUDE.md Rule 18
> condition (2): a K-parameterized unroller is not a concrete gate sequence, so **any**
> data-dependent-trip library body is a parity inversion) puts **20 of the 28 declines**
> out of scope — not because they are impossible, but because CQ has foregone the
> simulate-time witness Bennett's mechanism requires (Rule 2, owner decision 2026-06-10), so
> their realization rests on a parameter the compiler cannot check. A **parity** wall is not a
> **physics** wall, and the distinction is exactly what makes both statements true at once.
> **Measured actionable set: 5 cells.** Read `scope`, not `bucket`, in
> `full_surface/full_census_O1.json`; the reading guide is `full_surface/README.md`
> "READ THIS FIRST". Everything in §2/§3 below predates this and is retained as history.

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

> ⛔ **THE FOLLOWING PARAGRAPH IS THE SPECIFIC CLAIM THAT MEASUREMENT INVERTED** — see the §2
> correction banner. Loops are **7/43**, not 24/55, and `8h7d` is **not** the highest
> coverage-per-effort lever; the harness fix (`3c6m.60`, +12 cells/~1 day) and then `q2wk`
> (15 cells) both beat it. Kept below only as the record of what was believed on 2026-07-25.

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

2. ~~**NOW THE LIVE RECOMMENDATION: build the loop lever (8h7d).**~~ ⛔ **RETRACTED 2026-07-25
   (bd `3c6m.60`)** — this rested on the mis-attributed 24-cell count (see the §2 banner).
   Do **not** execute it as written. `8h7d` owns 7 cells, not 24, and 6 of those 7 are the
   roadmap-scale fmod/remainder/remquo family that re-opens the whole-DAG uncompute spine.

3. **→ THE ACTUAL LIVE PLAN (plan of record: bd memory `libm-next-steps-harness-then-q2wk`):**
   - **STEP 1 — bd `3c6m.60` (P1): the census keep-set harness fix.** ~1 day, harness only,
     zero compiler risk, **+12 cells (68 → 80/123)**, 0/68 regressions measured. Gate: re-run
     the full census asserting 0 regressions, then **mint `slice_libm_real_*` goldens before
     quoting 80/123** — census-COMPILES ≠ verified, which bd `3c6m.58` just spent a session
     enforcing.
   - **STEP 2 — bd `q2wk`: PredMux -O1 nested-control widening. 15 cells**, medium, reuses the
     shipped substrate. Its payoff grew 8 → 15 *because of* step 1's re-attribution, which is
     exactly why step 1 must come first — otherwise q2wk gets scoped against the wrong cell
     list, which is the failure this whole correction documents.
   - Its blocker chain is clear: `3c6m.50` was stale-OPEN carrying a `blocks` edge on the P1
     lever `3c6m.14`; closed 2026-07-25 (all deliverables were committed).

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
