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

- **Inc 1 — Lever A (fp80-union-web coverage).** **DONE 2026-07-17** (1a commit `0e699fa`;
  1b/1c/1d this increment). Outcome: expl promotes **9/9** unions (coshl module promotes
  **all 37** module-wide); the O1 census moves 10 cells with 0 regressions — `expl` itself
  now `loop-carried` (the union→loop milestone verbatim), coshl/sinhl →
  `control (flat/diamond)` (the spec-scan hits the floorl diamond before the polevll loops —
  same Lever B/C frontier), tanhl/expm1l → `L6 nested control`, modfl +3 → control buckets;
  COMPILES stays 5/41 (no leaf cell newly compiles — every remaining GET/SET cell carries
  control/loops behind the unions, so the "leaf cell golden" clause is vacuous). 1c resolved
  as predicted: the sign-extract promotes free once seeded (the shl-48 clears divergence
  before the `ashr exact` guard; zero-divergence short-circuit precedes the flag check).
  Implementation notes vs the plan: (b) needed a cycle-safe gep/phi/select pointer
  resolution (`isConstGlobalFpLoad` — the Horner coefficient pointer is a loop-carried phi,
  not a direct gep); (c) landed as a wide-mode-only transparent case for any
  BinaryOperator/CastInst/CmpInst (the post-promotion sibling-union extract web feeds select
  CONDITIONS through icmp/add/trunc chains — the fp-only whitelist could never close the
  web); (d) = `Reconstruct` packs in `analyzeStructure` + the `packDefinednessOk` P1/P2
  proof (P1 dominating-insert coverage of [0,80) per reload; P2 uncovered-bit and-mask kill
  per word load), packs always OPPORTUNISTIC. Fixtures: seed_constglobal /
  seed_mutableglobal_drop / signextract / reject_signextract_partial / reconstruct_pack /
  reject_pack_{partial,unmasked,storeafter}. Sub-stages as planned:
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

- **Inc 2 — Lever B (static-K force-unroll pre-pass).** **DONE 2026-07-17** (ticket lf8s;
  `LoopUnrollPrepass.{h,cpp}` + the shared `loopHasInPlaceRailStructure` predicate exported from
  `LoopLowering.cpp`). The two §Lever-B design questions resolved:
  - **Placement/gating (Q1).** The pre-pass runs in BOTH pipeline entry points AFTER the
    promoteFp80Union + PredMux fixpoints and BEFORE `detectSpecializations` — NOT for the clone
    alone: the census `expl` cell INLINES `@expl` into the tainted probe function, so the loops
    the milestone needs sit in a TAINTED function and declined via `tryCaseA` X1 (`kMsgCrossIter`),
    not the spec scan. The U7 relevance fence (a tainted value in-loop, OR the enclosing function
    in the tainted-callee cone) therefore must read the SAME settled taint `detectSpecializations`
    reads — the taint reaching a `__polevll` accumulator flows through Lever-A-promoted unions, so
    a pre-fixpoint run would mis-classify the target as classical. The 799w-non-clobber gate is
    STRUCTURAL, not positional (fence U1–U8, LoopUnrollPrepass.h): Case A needs an in-place rail
    (in-loop `cq_*` gate — U2 — or dtzb add/xor self-update / zero-hop identity carry — U4, tested
    by the SAME `inPlaceValueRailOperand`/`peelInPlaceBase` predicates `tryCaseA` claims with,
    exported as `loopHasInPlaceRailStructure`); Case B needs an in-loop theta mint (U2);
    `tryBreak`/Q1 need a tainted exit (U5, plus U6 — a theta-derived exit has no constant BTC).
    U3 additionally keeps tainted in-loop CONTROL with its ControlDetect/d8jl owners (so e.g.
    `control_predmux_leave_inloop.ll` — constant trip 3, no in-loop cq call — is untouched).
    A 30-fixture flip audit confirmed ZERO existing fixtures change behavior. Each unroll re-runs
    the PredMux fixpoint (a region containing the loop was cyclic-unclaimable; post-unroll it is
    acyclic and claimable).
  - **promoteFp80Union coupling (Q2).** One-directional and satisfied by construction: the unroll
    DEPENDS on the promotion fixpoint having settled (taint through promoted unions, above); the
    reverse direction is nil for expl — the polevll bodies contain only const-global loads +
    fmuladd, no union access (spike-IR-verified), and 9/9 unions promote pre-unroll. A
    hypothetical union-accessed-only-inside-a-const-trip-loop stays unpromoted (status-quo silent
    drop → the existing loud decline) — noted as a possible 8h7d widening (re-run the fp80
    fixpoint after unroll), NOT a regression.
  - **The LCSSA lesson (found by red-green, Rule 12).** `llvm::UnrollLoop` rewrites exit values
    through LCSSA phis; on a raw `-O1` loop whose result is used directly outside (the polevll
    accumulator), unrolling WITHOUT `formLCSSARecursively` first remapped the out-of-loop use to
    the FIRST iteration's value and folded the rest away — a verify-clean dropped-Horner-step
    silent miscompile, caught by `lowering_unroll_const_trip.ll` on first contact (the feasibility
    spike missed it because `opt -passes=loop-unroll-full` runs inside the loop-pass adaptor,
    which forms LCSSA first). The claim sequence is `simplifyLoop` (the second polevll loop has NO
    preheader — its entry pred is the first loop's exiting block) → `formLCSSARecursively` →
    `UnrollLoop(Count = exact trip, Runtime=false, PreserveLCSSA=true)`, requiring `FullyUnrolled`
    (U6's max==exact witness pins the internal `CompletelyUnroll`).
  - Fixtures: `lowering_unroll_const_trip.ll` (positive — trip-2 Horner over an internal-constant
    table with the loop-carried coefficient-pointer phi and `!llvm.loop.unroll.disable`, which the
    UnrollLoop UTILITY never reads — that metadata is unroll-PASS cost-model input, which is why
    calling the utility directly overrides openlibm's marker) +
    `lowering_unroll_reject_dynamic_trip.ll` / `lowering_unroll_reject_overmax_trip.ll` (the same
    body, argument-bounded / trip-100 → `kMsgCrossIter` char-for-char) +
    `lowering_unroll_leave_caseA_rail.ll` (THE 799w sentinel: constant-trip dtzb xor rail — every
    fence but U4 passes — must stay rolled-in-place with ONE `cqrt_xorc`; the pre-existing 799w
    fixtures are all argument-bounded, so this is the only constant-bound rail pin) +
    `lowering_unroll_leave_identity_carry.ll` (U4(b) zero-hop peel).
  - Milestone MET: the census `expl` cell moves `loop-carried tainted value crosses iterations` →
    `value-arm swap-route under quantum control` (loop→control verbatim); all six polevll loop
    instances (4 inlined-in-probe + 2 in `@expl` via the cone) unroll (trips 2/3); coshl/sinhl
    unchanged (the floorl-diamond spec-scan control gate — the Lever-C frontier). BONUS: atanhl /
    logl / log1pl also move loop-carried → `L6 nested control` (their log-kernel polynomial loops
    are the same class). COMPILES 5/41 unchanged, 0 regressions.
  - **Rule-13 clearance (6-lens adversarial board, 2 Fable cores + 4 opus, 2-skeptic verify).**
    ONE CONFIRMED BLOCKING find (both skeptics reproduced): the fence was blind to
    **tainted-operand MEMORY ops** — a const-trip loop doing tainted-index gep/load/store with no
    cq call and no add/xor rail evaded U1–U8, unrolled, and (read shape) SILENTLY converted the
    rolled form's loud L3 `kMsgQramLoop` decline into an unreviewed `cqrt_qram_*` accept, or
    (Shadow store shape) routed into a LATENT `lowerShadowMemory` use-after-free crash (that
    straight-line crash is pre-existing — reachable without Lever B — filed as bd `gyc9`).
    FIXED as **U2b** (any gep / mayReadFromMemory / mayWriteToMemory instruction with a tainted
    operand → skip; the memory analog of U3, mirroring `markIfIterationLocal`'s L3 walk;
    classical `@P`/`@Q` coefficient loads unaffected) + fixtures
    `lowering_unroll_leave_qram_read_loop.ll` / `lowering_unroll_leave_shadow_store_loop.ll`
    pinning the L3 decline char-for-char. Also hardened from the board's mutate-on-skip note:
    **U3 now requires every in-loop terminator be a `br`** (a switch latch made `UnrollLoop` bail
    AFTER the simplifyLoop/formLCSSA mutation — the residue was adjudicated identically, but the
    tightening keeps the claim path residue-free). 7 other findings REFUTED by both skeptics
    (mutate-then-decline paths land on the identical pre-change diagnostics; the wrong-trip-count
    family verified clean across trips 1/2/8, wrapping-i8 stride-2, 2×2 nests, with the fixture
    output byte-identical to the manually-unrolled program's lowering). The fix delta was then
    itself re-reviewed independently (memcpy / inttoptr-laundered / pointer-select / switch-body
    probes all decline-to-decline with A/B classical controls proving no over-exclusion): the
    access class CLEAR, but ONE residual same-class find — a DEAD tainted-SIZE `alloca` (neither
    gep nor mayRead/Write) evaded U2b and rode `UnrollLoop`'s internal trivially-dead cleanup
    past the escape guard (unitary-equivalent — the deleted consumer was dead and
    side-effect-free — but an unreviewed decline→accept conversion). Closed by adding
    `AllocaInst` to the U2b class (+ `lowering_unroll_leave_alloca_tainted_size.ll` pinning the
    escape-guard decline char-for-char). A possible hardening follow-on for the owner (8h7d):
    invert U2b to a tainted-operand WHITELIST (arith/cmp/cast/phi/select/br only), which would
    close the same DCE channel for every other dead tainted consumer class by construction —
    weighed against Rule-17 over-exclusion risk, not done in this increment. Post-fix: full lit
    821+1 XFAIL, ctest 173/173, e2e re-run green, census byte-identical to the pre-fix Lever-B
    result (the fences cost the milestone nothing).

- **Inc 3 — Lever C (compose + land coshl).** **DONE 2026-07-17** (ticket adia). The three
  design questions resolved:
  - **Q1 (fptosi f80→i32).** ALREADY covered — `castInScope` admits it and the YAML has carried
    the int↔f80 cross-domain rows (+`_inv`/`_unc`) since bd 3c6m.5. Zero rows added. The real
    gap was the **p119.6 invariant, clone edition**: `lowerCloneSelect` minted its select
    out-rail without a `HandleWidth` entry, so the downstream `fptosi` read the laundered i32
    and declined `no template for fptosi i32`. Fixed by recording `cloneTaint.HandleWidth[Out]`
    exactly as the top-level emitter does (pinned by `spec_accept_fp_select_f80.ll`).
  - **Q2 (does PredMux claimAll flatten expl's graph?).** YES — `lowerCloneControl` flattens the
    full post-Lever-A/B @expl web (32 conditional branches / 17 phis / 1 fp80 select / 1 fptosi)
    once the frontier gates widened. Per-gate findings, each red-green + probed:
    * **scan gate**: `isLiftableFpSelect` was a {f32,f64} whitelist — the s_floorl.c:61 fp80
      select (icmp cond, both arms derived) declined at the SPEC-SCAN. Widened +f80 ONLY
      (f16 pinned declining, `spec_reject_fp_select_f16.ll`); the emission rides the kjd1
      select-local `copyControlledFpFn` (`cqrt_copy_f80_controlled` — frozen family, no new
      symbol; the shared integer minter's fp-null classifier untouched).
    * **Q+Q select-condition compares** (floorl's `i0 > mantissa-word`, two theta-derived
      words): the select flag mint was HL-only at BOTH levels. Widened via one shared
      predicate `qqSelectLeafWidth` (CompareLowering — HandleWidth-aware logical width, both
      operands tainted + equal width, i128/i80 fenced) feeding `lowerCompareToFlag`'s
      existing QQ path: SelectClassify gate-2b lifted + `compareFlagMintable` QQ branch
      (top), `mintCondNetwork` (clone). The QQ compare grid (40 icmp + 56 fcmp, `_inv`+
      `_unc`) was frozen by 7.1 — **zero new runtime symbols**. i1-operand fence holds
      (`control_swap_reject_select_qq_i1leaf.ll`).
    * **TOP-LEVEL envelope (the part the ticket under-scoped)**: the coshl census cell also
      carries tainted control in @probe ITSELF (the coshl exponent ladder + two inlined
      expm1l/expl copies + the outlined @expl call in an arm) — the spec-scan decline had
      MASKED it. Three PredMux widenings clear it, all accept-only:
      (a) **E4 pending-spec pure-callee admit** — a DIRECT call with ≥1 tainted arg (the 6.5
      classical-call-arm anti-overlap fence), template-width result, and a callee passing
      `isSpeculatablePureCalleeBody` (visible, non-vararg, acyclic CFG, br/ret terminators,
      every non-terminator speculatable dataflow; inner calls = curated intrinsics or
      recursively-proven bodies, OnStack cycle-broken) is speculatable dataflow — under
      quantum control every basis state executes every arm, so speculating a pure total
      terminating call is exactly the established arm discipline. Probes: impure/loop/
      recursive/classical-args callees all still decline loudly char-for-char.
      (b) **select-form condition trees** — clang -O1's poison-shielded short-circuit
      `select(a,b,false)`/`select(a,true,b)` (the `ex < K || (ex == K && mx < M)` ladder)
      admitted in E6 and canonicalized to plain and/or at flatten time; the SHIELDED
      operand's backward cone is `dropPoisonGeneratingFlags`-stripped first (the moveBody
      speculation discipline), making the rewrite basis-state-equivalent. Off-grammar
      combinators (all-non-const select-of-i1) keep declining.
      (c) **degenerate same-arm select fold** (`select(EP,x,x)` = x, the value-chain mirror
      of the BoolAlg x∨x guard) + **E6 constant-condition admit** + a **fold-first step**
      (the exported `foldConstantConesInFunction` runs per tainted-control function inside
      `flattenPredMuxRegions`, collapsing late-materialized all-constant compare/branch
      residues that otherwise read as "classical control inside a tainted region").
  - **Q3 (fp80 copy-out under the fp-ABI spec + angle fence).** Composes as shipped: the
    clone's fp80 return copies out via `cqrt_copy_f80` (3c6m.54 `copyFnClone`), the f80 select
    merges mint ONLY through the select-local `copyControlledFpFn`, and the census/real traces
    carry exactly ONE user ry + ONE user measure (Rule 5), 0 double-frees, 0 unborn frees.
  - **A fourth lever surfaced at the plain -O1 floor** (the real vendored slice, where floorl
    stays OUTLINED): expl's union seeds derive through `px = olm_floorl(...)` — a CALL in the
    seed cone — so Lever A's walk dropped 4 unions the census model (2M inline threshold) never
    showed. Widened: `fpSeedValueOk` admits a call to an `isSpeculatablePureCallee` body as a
    transparent fp derivation (AdmitArgDerived/opportunistic mode only; the proof passes only
    after the callee's own unions promoted, so the fixpoint cascades). Probes:
    `lowering_fp80_union_seed_purecall.ll` / `_impurecall_drop.ll`.
  - **Milestone MET:** `slice_libm_real_coshl` (real vendored openlibm closure: e_coshl +
    e_expl + s_expm1l + s_floorl + polevll `__polevll` + `__isnanl` + scalbnl-as-ldexpl,
    IEEEl2bits verbatim) compiles, links, runs deterministically at plain -O1 — the committed
    21,426-line golden + ctest wiring. Census ld80@O1: **COMPILES 5/41 → 9/41** (+frexpl,
    +modfl, +lroundl, +llroundl — the Q+Q/select-form widenings unlocked them), **coshl and
    sinhl → "COMPILES (spec-clone)"** (a new honest census bucket: opt exit-0 with the
    surviving @expl handled by clone-on-taint — every retargeted call proven in the lowered
    output; both hand-verified compile+LINK+RUN deterministic), zero regressions. The census
    `expl` cell (wprobe fully-INLINES expl into the tainted probe — the top-level value-arm
    envelope, 3c6m.14 L6 territory) stays declined — explicitly OUT of this increment's scope
    per the owner's frontier note.
  Then re-derive the remaining 5 cells (atan2l/lgammal/log10l/powl/tgammal — each routes
  through a polynomial-eval inner callee, so Levers A/B/C apply; per-cell inner-callee coverage
  may add rows). Post-Inc-3 buckets: atan2l/tgammal → fp-copy/specialization,
  lgammal/powl → control (flat/diamond), log10l → memory-store (Shadow).

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
