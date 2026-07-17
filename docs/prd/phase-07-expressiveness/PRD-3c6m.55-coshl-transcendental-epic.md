# PRD — 3c6m.55: ld80 fp-transcendental cells (coshl→expl) — the 3-lever epic

**Status:** SCOPING COMPLETE — Rule-11 re-derivation done, owner-approved 2026-07-17 ("full
3-lever coshl epic"). Rule-13 HIGH throughout (core lowering + fp80 bit-pattern memory).
**Branch:** `3c6m.14-control-l6`. **First driver cell:** `coshl` → `expl` at the -O1 ship floor.
**Ground truth:** a real openlibm vendored `slice_libm_real_coshl` at -O1 (per memory
`libm-real-slice-recipe`; keep `IEEEl2bits` verbatim). NOT the census aggressive-inline model
(inline-threshold=2000000 over-states).
**Supersedes** the premise in bd 3c6m.55 (2026-07-16/17 comments) that the residual is "just the
Shadow half re-run on the clone body". Re-derivation below shows it is a **SHADOW + LOOP + CONTROL**
triple composition.

---

## 1. Problem — the Rule-11 re-derivation (2026-07-17, IR-confirmed)

Reproduced with `BC=/private/tmp/bc CENSUS_OPTLEVEL=O1 wprobe.probe("coshl","f80",[("q","f80")],0)`.
`coshl` inlines but calls `@expl` — the **sole** transitive Phase-6 spec candidate (floorl, ldexpl,
`__polevll` are all inlined INTO expl at -O1). Decline:

```
error: in function expl x86_fp80 (x86_fp80): cq specialization: callee contains a
non-reversibilizable construct under quantum lift (unsupported instruction)
```

`@expl` (with inlined floorl/ldexpl/__polevll) at -O1 is a **9-union + 2-loop + multi-diamond** body.
The union is only the FIRST-declining layer. Three composed levers, each IR-confirmed:

### Lever A — SHADOW: fp80-union-web coverage (extends bd 3c6m.51)

`promoteFp80Union` ALREADY runs on `@expl` at module level (it iterates every function; vqlq's
`AdmitArgDerived` admits expl's untainted fp80 `Argument` seed). Debug-instrumented verdict:
`expl candidates=3 opportunistic=1` — of 9 unions, only **3 promote**. The other 6 fail for THREE
distinct reasons, none of which "re-run on the clone body" fixes:

1. **Seed-admissibility cascade (dominant — drops 5 of 8 structurally-valid unions).**
   `fpSeedValueOk`'s transparent-op whitelist is `{sitofp,uitofp,fadd,fsub,fmul,fdiv,frem,fneg,
   fpext,fptrunc,phi,select,freeze}`. expl's union seeds are computed by **`@llvm.fmuladd.f80`**
   (polynomial eval, k-scaling reconstruction), by **`load x86_fp80` from const-global coefficient
   arrays** (`@P`/`@Q`), and by **reloads of OTHER unions** (a reload-chain web). A seed reaching a
   `call`/unlisted op → `seedClass==0` → dropped; and a dropped union's reload drops its dependents
   (cascade). Spike (admit fmuladd/fma/sqrt/fabs/copysign/floor/… into the walk) recovered only
   **+1** union — the rest chain through const-array loads and reload chains. So Lever A itself is a
   multi-part coverage extension: (a) curated pure fp intrinsics as transparent seed ops,
   (b) const-global fp-array loads as constant-rooted seeds, (c) the reload-web fixpoint.

2. **Sign-extract reads (GET_LDBL80).** `gep i8 %u,8; %w=load i64; shl i64 %w,48; ashr exact i64 _,48;
   trunc nsw to i32` (sign-extend the 16-bit expsign). ANALYSIS: this is **actually sound** — the
   `shl 48` shifts the diverged padding bits [16,64) completely out (to ≥64, discarded) BEFORE the
   `ashr exact`, so the `ashr exact` operand carries zero divergence and PaddingWalk line ~573
   (`Da.isZero()&&Db.isZero()`) short-circuits it sound. So once a sign-extract union becomes a
   *candidate* (Lever A.1 admits its seed), the PaddingWalk should already pass. VERIFY this holds
   (do NOT assume) — it is the cleanest sub-piece and a good red-green anchor.

3. **Integer-seeded SET_LDBL packs (floorl reconstruct).** NO `store x86_fp80` seed; instead
   `load i64 @off8; and 65535; and old,-65536; or disjoint; store i64 @off8; store i32 manh @off4;
   store i32 manl @off0; load x86_fp80 @0 (return u.e)`. `analyzeStructure` line ~231 explicitly
   declines the non-fp80-seeded reload-pack (same family as lroundl SET_LDBL). Needs new structural
   coverage: accept the reconstruct-from-scratch pack whose reload IS the terminal, with the §4.4
   padding-non-bijectivity proof (the reload observes the whole 80 bits — every packed byte must be
   fully defined, i.e. all three words written before the reload).

### Lever B — LOOP: static-K force-unroll of `__polevll` (extends bd 8h7d "static-K unroll")

`@expl` carries **2 tainted-accumulator polynomial loops** (`__polevll` Horner over const fp80 tables
`@P`/`@Q`: `acc = fmuladd(acc, x*x, coeff[i])`; `phi ptr [@P,..],[gep i8 %p,16,..]`; counter
countdown, trip counts **2 and 3**). The accumulator phi is tainted (x*x derives from the theta
arg). CONFIRMED BLOCKING: even with every union promoted, these decline — in-clone loop lowering is
Phase-7.3/8h7d territory and NEITHER `lowerLoops` NOR any unroll runs on a spec-clone body
(`specialize` is after `lowerLoops`).

FEASIBILITY PROVEN: the loops carry `!llvm.loop.unroll.disable` (openlibm marks `__polevll`), which
is why -O1/-O2 keep them. Stripping the disable metadata + `loop-unroll-full` eliminates BOTH loops
(0 loops, straight-line 38-fmuladd chain) and leaves a lowerable body (the residual then reverts to
Lever A). So Lever B = a **force full-unroll pre-pass** for small known-constant-trip loops (SCEV
`getSmallConstantTripCount`, `UnrollLoop` with `Force=true` to override the disable metadata),
bounded by a max trip count.

Design questions (resolve in the increment):
- **Placement/gating.** Must fire on `@expl` BEFORE `detectSpecializations` (so the clone inherits an
  unrolled body). Full-unroll of a constant-trip loop is semantics-preserving (taint-independent), so
  it can run as a pre-pass on any theta-reachable module. BUT it must NOT unroll a loop that
  `lowerLoops` (799w) already handles rolled-in-place (that would change 799w goldens). Candidate
  fence: only unroll loops that are NOT `lowerLoops`-claimable (e.g. those carrying a const-array
  memory read in the body, or run the unroll only inside spec-candidate callees). NEEDS the
  Rule-13 gating proof.
- Interaction with the union promotion order (unroll first exposes more straight-line fmuladd seeds
  for Lever A; but Lever A's candidates are outside loop blocks anyway — verify no coupling).

### Lever C — CONTROL + residual casts (I2, mostly done)

Post-union, post-unroll, expl's residual is fp arith (fmul/fadd/fsub/fdiv/fneg/fpext/fptrunc — all
lowerable), curated fmuladd intrinsics, ~15 `phi` + `select` + `icmp`/`fcmp` (the isnan/overflow/
k-scaling **diamonds** — I2 in-clone control), and **one `fptosi x86_fp80 to i32`** (the
`k=(int)floorl(...)` exponent cast — VERIFY it is in `castInScope`; likely needs coverage). I2 lifts
multi-exit controlled-return / compound-cond value diamonds, but expl's control graph is larger than
I2's tested envelope (~15 phis, many arms) — the compose step must confirm `lowerCloneControl`
(PredMux) flattens it, else widen.

---

## 2. Increment plan (each: red-green Rule 12 + independent Rule-13 clearance Rule 13)

The levers are gated by declines in this order at the spec-callee scan: **union alloca (A) → loop (B)
→ control/cast (C)**. But for OBSERVABLE frontier advance, Lever A moves the decline union→loop, so A
is the natural first increment. Sequence:

- **Inc 1 — Lever A (fp80-union-web coverage).** Sub-staged:
  - **1a. Seed-cascade: curated pure fp intrinsics** as transparent `fpSeedValueOk` ops (fmuladd/fma
    + the Rule-18 keep-set). Strict-predicate care: the shipped strict predicate must stay
    byte-identical (add intrinsics to BOTH modes only if a tainted-through-intrinsic seed is genuinely
    strict — an intrinsic of tainted operands IS tainted, so this is sound and mirrors fmul; document
    the argument). Red-green: positive `lowering_fp80_union_seed_fmuladd.ll`; the existing decline
    fixtures stay char-for-char.
  - **1b. Seed-cascade: const-global fp-array loads** (`load x86_fp80` from an `internal constant`
    global) admitted as constant-rooted seeds (the `@P`/`@Q` coefficients). Fence: the global must be
    `constant` + `internal`/read-only (never a Shadow/QRAM table).
  - **1c. Sign-extract read** — VERIFY it promotes once its seed is admitted (likely free); add the
    positive + a decline probe for an UNSOUND sign-extract variant (an `ashr exact` where the `shl`
    does NOT fully clear divergence).
  - **1d. Integer-seeded SET_LDBL reconstruct pack** — new `analyzeStructure` acceptance for the
    reload-terminal reconstruct, with the §4.4 all-words-defined-before-reload proof + a decline
    probe for a partial (undefined-word) pack.
  - Milestone: `expl candidates` → all 9; decline moves union→loop; a leaf GET_LDBL/SET_LDBL
    straight-line ld80 cell (if one exists) compiles at top-level.

- **Inc 2 — Lever B (static-K force-unroll pre-pass).** New `LoopUnrollPrepass.cpp` (or fold into an
  existing pre-pass file). SCEV-driven full-unroll of small known-constant-trip loops with the
  799w-non-clobber fence. Red-green: `lowering_unroll_const_trip.ll` (a bounded tainted loop that
  currently declines → unrolled → lowers) + a decline/skip probe (a 799w rolled-in-place loop stays
  untouched; a non-constant-trip loop declines its existing way). Milestone: decline moves loop→
  control/cast.

- **Inc 3 — Lever C (compose + land coshl).** `fptosi` cast coverage if needed; confirm/ widen
  `lowerCloneControl` for expl's control graph; the fp-ABI spec + I2 control compose. Milestone:
  **coshl compiles at -O1** + a committed `slice_libm_real_coshl` e2e golden + no census regression +
  full `ctest` green + re-census confirms coshl (and by extension sinhl — same expl reduction) move
  to COMPILES. Then re-derive the remaining 5 cells (atan2l/lgammal/log10l/powl/tgammal — each routes
  through a polynomial-eval inner callee, so Levers A/B/C apply; per-cell inner-callee coverage may
  add rows).

## 3. Done criteria (epic)

`coshl` (and sinhl) compile at the -O1 ship floor with real openlibm vendored e2e goldens; the 7-cell
census (`tools/library_coverage/full_surface/ld80_census.py` at -O1) confirms the moves; every new
accept-predicate ships a decline fixture + adversarial probe; each increment independently Rule-13
cleared; `gen_templates.py --check` clean; full `ctest` green.

## 4. Rule-13 cores (highest silent-miscompile risk)

- Lever A seed widening must not admit a seed that is a **re-interpreted bit pattern** (only pure fp
  producers + constants + candidate reloads). The §4.1 PaddingWalk is the backstop but the seed gate
  is the first fence.
- Lever A.1d SET_LDBL reconstruct: the fp80 reload observes ALL 80 bits — a partially-written pack
  (an undefined word) reaching the reload is a silent miscompile (undefined bytes read as a definite
  value). Prove every packed byte is written before the reload, or decline.
- Lever B force-unroll must NOT change any tainted loop `lowerLoops` already lowers (799w golden
  drift) and must only unroll PROVEN constant-trip loops (a wrong trip count = wrong program).
- Lever C: the padding-as-0 mask fence (`kMsgFp80Padding`) and the promoted i80 write surface in the
  clone TWIN remain the adjoint cores (per the task brief).

## 5. Repro / evidence (regenerate if `/tmp`/`/private/tmp` cleared)

- Corpus: `/private/tmp/bc` (241 `.bc`), `/private/tmp/openlibm`. Probe:
  `cd tools/library_coverage/full_surface; BC=/private/tmp/bc CENSUS_OPTLEVEL=O1 python3 ld80_census.py`
  (the `BC=` is load-bearing — omitting it globs empty → bogus 0/41).
- The coshl inlined IR + per-lever spikes for this re-derivation live under
  `$CLAUDE_JOB_DIR/tmp/coshl/` (session 2026-07-17): `inl.ll` (the -O1 linked/inlined module),
  `expl_body.ll` (the pre-promote expl), `unrolled_ok.ll` (force-unroll spike: 0 loops), the
  `CQ_FP80_DBG2` seed-drop trace. Re-derive per `libm-real-slice-recipe` for ground truth.
- Debug levers used (reverted; re-add if needed): a module dump after the promoteFp80Union fixpoint
  in `CQLoweringPass.cpp`; per-alloca `struct/acyclic/seedDom/candidates/opportunistic/PaddingWalk-BAD/
  DROP-seed` logging behind `CQ_FP80_DBG2` in `Fp80Union.cpp`.

## 6. Do NOT

- Do NOT "re-run promoteFp80Union on the clone body" and call it done — the module-level pass already
  sees `@expl`; the 6 surviving unions fail for shape reasons the re-run does not change, and the
  loops sit behind them.
- Do NOT migrate to an -O2 floor to get the unroll (Rule 9); the force-unroll pre-pass handles it.
- Do NOT ship a decline-only stub for coshl (Rule 17 — owner directive); the levers are real, scoped,
  and feasibility-proven.
