# Phase 6 / issue 5po2 (continued) — tainted `br`/diamond in a lifted callee

`test_C_libtooling-5po2`, second increment. The first increment
(`5po2_SELECT_IN_CLONE.md` + `kmdc_FP_SELECT_IN_CLONE.md`) lifted a callee whose
in-body control is a straight-line **`select`**. This increment lifts a callee
whose in-body control is a real **multi-block `br` diamond** — the shape
`SpecializeReject::scanBody` still declines at the single-block gate
(`SpecializeReject.cpp:230`, `kMsgInBodyControl` =
`"cq specialization: callee contains tainted control flow under quantum lift"`).

**Why now (the leverage).** This is the *first blocker* for the 7 ld80
fp-transcendental cells (`atan2l coshl lgammal log10l powl sinhl tgammal`,
tracked as **3c6m.55**, blocked on this ticket). After 3c6m.54 lifted the fp-ABI
gate, these cells decline at `InBodyControl` on the inner reduction — e.g.
`coshl → expl`, whose openlibm body (`ld80/e_expl.c`) is:

```c
if (x > MAXLOGL) return (huge * huge);            /* overflow  → classical sentinel */
if (x < MINLOGL) return (twom10000 * twom10000);  /* underflow → classical sentinel */
/* ... expensive tainted polynomial in x ... */
return x;
```

`x` is a superposition (tainted); the guards `x > MAXLOGL` are tainted compares;
the early-return values are **compile-time-classical** overflow/underflow
sentinels; the fall-through returns the expensive tainted reduction. clang `-O1`
keeps this as a genuine multi-block region (it will **not** speculate the whole
polynomial into a `select`), so it survives as `br`, not the select the first
increment already handles.

## Reproduction (ground truth)

- The original select repro `demo/foo_superposition/foo_noinline.c` now compiles
  **clean** (EXIT 0) — clang `-O1` collapses `if(b<5)a+=b` to
  `select(b<5,b,0)`, handled by the first increment.
- A genuine multi-block callee still declines:
  ```c
  __attribute__((noinline)) int foo(int b) {
      if (b > 100) return 999;   /* early-return arm */
      return b * b + 7;          /* main arm */
  }
  ```
  → `error: in function foo: cq specialization: callee contains tainted control
  flow under quantum lift`.

## The two pipelines this must bridge (and why it is not a shape-matcher tweak)

1. **Top-level tainted control** is lowered *in place* by the Phase-4 swap-route
   emitter (`ControlDetect` → `ArmClassify` → `SwapRouteEmit` → `RegionFlatten`)
   and, for controlled `return`/`abort`, by the epic-`65wb` machinery. It mints a
   flag, routes with `cqrt_cswap`, emits the arm, routes back, strips the flag,
   frees — **self-contained**, and `RegionFlatten` erases the CFG diamond leaving
   a straight-line block.
2. **A callee receiving a superposition** is cloned to `@__cq_q_<callee>_<mask>`
   and **Bennett-wrapped** (`BennettWrap.cpp`): compute the body → `cqrt_copy` the
   result out to a `|0⟩` rail → **reverse-play the whole forward stream** via
   `emitInverseChain` → free scratch → `ret out`. Its adjoint twin
   `@…_unc` (`synthUncomputeTwin`) is a verbatim clone of the *wrapped* body with
   the out-alloc swapped for an out-param and `ret void`.

The wrap and the twin both assume a **single straight-line BB and a linear
forward stream** (`BennettWrap.cpp:45`). The already-shipped select path proves
the *method-B* discipline composes with the wrap for a straight-line mux
(`Specialization::lowerCloneSelect` mints the flag **live** and lets the wrap's
reverse play the controlled-copy `_unc`). This increment is "the select case,
but the mux sits behind a real CFG that must be flattened first."

**Key simplifier — a clone body is rotation-free.** `scanBody` rejects every
`cq_theta`/`cq_phi` (`QuantumPrimitive`), so a tainted diamond in a clone is
**never a phase arm** — it is always a value/permutation arm, lowered by
method-B, exactly the discipline the wrap already uses. There is no
Rz-in-place / dephasing hazard here (Rule 7); the whole problem stays inside the
Bennett/method-B world.

## Central hazards (the Rule-13 core, resolve in the PRD before emitting)

- **H1 — double-uncompute.** The top-level value-arm emitter *already* does
  compute → copy-out → reverse-play *inside* the region. If we run it on the
  clone body and then let the Bennett wrap reverse the whole stream again, a
  shared prefix is uncomputed twice (use-after-free + double-free, Rule 8). The
  design must make the flattened region leave **exactly one** clean forward
  stream for the wrap to reverse — i.e. the in-clone control emitter must emit
  the *forward half only* (route-in, arm compute, copy-to-merge, route-back,
  flag kept **live**, as `lowerCloneSelect` does), and let the wrap own the single
  reverse. It must **not** call the top-level self-contained reverse-play.
- **H2 — the early-return skips the guarded computation.** On the overflow path
  the polynomial is never evaluated; a naive flatten evaluates it unconditionally
  on a possibly out-of-range input. For **reversibility** we need the guarded
  region's forward stream to be reversible on *every* control path and to leave
  every scratch rail provably `|0⟩` before free (Rule 6). The early-return arms
  returning **classical constants** is the load-bearing simplification: the merge
  is `out = cond1 ? C1 : (cond2 ? C2 : f(x))`, a controlled data-mux at the
  return with classical mux-arms and one tainted arm — expressible as the 4.4/4.5
  controlled-XOR copy family the wrap already reverses, **iff** `f(x)`'s own
  forward stream is captured into the single wrap reverse (H1).
- **H3 — block lifetime under sequential flatten** (the historical UAF, Rule 9):
  `RegionFlatten` erases merge blocks; capture all identities before the first
  erase, or decline while blocks are valid.

## Two candidate mechanisms — and why PredMux, not SwapRoute (the H1 resolution)

Investigation (2026-07-16) mapped both existing control-lowering paths against
the Bennett-wrap composition. They differ in exactly the way H1 cares about:

- **SwapRoute `emitValueRegion`** (`SwapRouteEmit.cpp:206`) is a **self-contained,
  balanced** region: flag mint → `cqrt_alloc` rail → `cqrt_cswap` route-in →
  uncontrolled forward chain → route-back mux onto `q` → **uncontrolled**
  `cqrt_copy(q,out)` → **its own reverse-play** (route-back†, chain `_unc`,
  route-in†) → free rails → **local `icmp_inv` flag-strip + free**. It leaves a
  *balanced* stream, not a forward one, and strips its flag locally. Feeding that
  into the Bennett wrap (which copies out + reverses the whole stream) **double-
  uncomputes** (H1) — use-after-free + double-free. So SwapRoute-reuse is the
  wrong composition.
- **PredMux `flattenPredMuxRegions`** (`PredMuxFlatten.cpp:789`) flattens the
  acyclic tainted diamond into a **forward** block-predicate merge stream —
  `cq_template_icmp_*` flag mints, `cqrt_toffoli` predicate conjunction,
  `cqrt_alloc` literal rails, `cqrt_copy_i32_controlled` XOR-merge copies — and
  leaves reversal to a **separate** uncompute stage (module-level `uncompute()`
  at top level). That is *exactly* the shape `lowerCloneSelect` already composes
  with the Bennett wrap (forward controlled copies captured, wrap plays their
  self-inverse `_unc`). It is the natural fit.

Decisive enabler: `flattenPredMuxRegions(Module&, TaintSet&)` is **taint-scoped**
(`PredMuxFlatten.cpp:795` only processes functions whose terminator is tainted
*under the passed set*). Called with the clone's disjoint `cloneTaint`, it
flattens **only** the clone's diamond and leaves every other function untouched.
It already runs as a module fixpoint (`CQLoweringPass.cpp:155/395`) — but
**before** `specialize` (line 300), so it never sees the fresh clone.

## Design (PredMux-in-clone)

Mirror `lowerCloneSelect`, generalized from a straight-line `select` to a
flattened diamond. In `buildClone`, after `seedClone` and the transitive inner
drain, **before** `lowerOps`/capture/wrap:

1. `scanBody`: replace the hard single-block gate with a **prove-or-decline**
   check — accept a body whose extra blocks form a PredMux-recoverable acyclic
   single-exit value region (`recoverRegion` succeeds under `cloneTaint`);
   everything else (multi-exit — the I2 shape; in-loop; store/call arms; nested
   beyond scope) stays `InBodyControl` (Prime Directive). Rotation-free is
   already guaranteed, so the region is a value/data-mux — never a phase arm.
2. A new `lowerCloneControl` (sibling of `lowerCloneSelect`): run a **scoped
   PredMux fixpoint** on the clone (`while (flattenPredMuxRegions(M, cloneTaint))`
   then re-propagate `cloneTaint` from the clone's tainted roots — the same
   flatten+repropagate loop the module driver uses). It flattens the diamond to a
   single straight-line block and emits the forward merge stream. The minted flag
   is kept **live** (H1) — no local strip, exactly as `lowerCloneSelect`.
3. Capture: the existing `buildClone` capture loop already routes
   `cqrt_copy_<W>_controlled` (SelectCopyOps-style) as forward-only reverse links
   and `cqrt_alloc` out-rails as ScratchRails. **Verify** each *additional*
   PredMux-emitted op composes: `cqrt_toffoli` (self-inverse involution?),
   literal-constant `cqrt_alloc` rails (scratch to free), and any muxed-select
   residue. Extend the capture sets minimally where needed — no new frozen
   symbol is the goal.
4. The Bennett wrap + `synthUncomputeTwin` then reverse the single captured
   forward stream unchanged.

**Open verification before commit (the de-risking spike):** wire the scoped
PredMux fixpoint into `buildClone` behind the accept fixture, build, and confirm
(a) the clone flattens to one block, (b) every PredMux-emitted op is captured +
inverse-emittable (no dropped `cqrt_toffoli`/rail → dirty free), (c) the wrap +
twin reverse cleanly, (d) `re-propagate` under `cloneTaint` terminates. This is
the H1/H2/H3 correctness core — clear it analytically (Rule 13) before the golden.

## Red-green fixtures (Rule 12, in place)

- `ir-pass/test/spec_accept_diamond_body.ll` — one-arm merge-phi value diamond
  `helper(b)=(b<5)?(b+7):b` as a real `br`; **fails today** (declines
  `InBodyControl`), the I1 target.
- `ir-pass/test/spec_reject_diamond_multiexit.ll` — the multi-exit expl shape;
  **passes today** and must keep declining after I1 (it is the I2 increment).

## Increment plan (each: Rule-12 red-green + Rule-13 adversarial clearance)

- **I1 — merge-phi value diamond** (the simplest `br` shape that survives `-O1`:
  a two-arm mux clang keeps as a diamond, e.g. via a `volatile`/side-effect arm).
  Proves the flatten→capture→wrap→twin composition end-to-end on the gentlest
  control shape. Golden e2e slice.
- **I2 — multi-exit controlled-return, classical-sentinel arms** (the fp80
  target: expl-style `if(guard) return C; … return f(x)`). Composes I1 with the
  `65wb` controlled-return substrate inside the clone. First real cell:
  `coshl → expl` at `-O1`; then the remaining 6 fp80 cells; each a committed
  golden. Re-census after landing (peel_census) to expose any opcode/shadow layer
  hidden behind the now-lowered control.
- **(later, separate tickets)** `switch` in a clone; nested/depth-2 in-clone
  control; non-sentinel (tainted-both-arm) early returns.

## Decisions taken

1. **Increment scope:** **I1 first** (merge-phi value diamond) — owner decision
   2026-07-16. The clean composition proof before I2 (the fp80 controlled-return
   target) stacks the controlled-return substrate on top.
2. **H1 mechanism:** resolved by investigation — **PredMux-in-clone** (forward
   merge stream captured, single Bennett-wrap reverse), NOT SwapRoute reuse
   (which self-balances and would double-uncompute). See the two-mechanism
   analysis above.

## Implementation — I1 LANDED (2026-07-16, pending Rule-13 clearance)

Five coordinated changes, all reusing shipped machinery (Rule 14):

1. **`scanBody` multi-block loosening** (`SpecializeReject.cpp`): the hard
   single-block gate is replaced by a per-block whitelist walk over EVERY block;
   `br` (diamond edge) and `phi` (merge mux, with a width/vector fence) are
   accepted as flattenable control, `switch`/`indirectbr`/`invoke` decline. A
   non-value construct in ANY arm still declines (store-in-arm probe).
2. **`isLiftableSelect` two-arm shape** (`SpecializeReject.cpp`): accepts a
   two-non-constant-arm integer `select(icmp, X, Y)` in addition to the
   increment-1 `select(icmp, param, 0)` — the integer analog of
   `isLiftableFpSelect`.
3. **`lowerCloneControl` + `reseedCloneTaintFromParams`** (`Specialization.cpp`):
   a scoped `while (flattenPredMuxRegions(M, cloneTaint)) reseed` fixpoint that
   flattens a claimable diamond, then `MergeBlockIntoPredecessor` folds the
   unconditional-br tail (PredMux leaves the merge block + an unconditional edge)
   into one straight-line block. Backstop: still-multi-block ⇒ LOUD decline
   (catches multi-exit / loop / compound / classical-condition control).
4. **`lowerCloneSelect` two-arm integer path** (`Specialization.cpp`): a `TwoArm`
   flag routes a two-derived-arm integer select through the same two-copy stream
   (copy_T · ¬flag `cqrt_x` · copy_F · `cqrt_x`) the fp path uses, flag kept
   LIVE, captured for the Bennett reverse. Plus an explicit **Q+Q compare-
   condition fence** (the HL flag mint needs exactly one tainted operand) and a
   **surviving-tainted-select backstop** in `buildClone` (never wrap a raw mux).

**What actually flattens.** PredMux claims a value region only when
`NumMergePhis>=2 || (NumMergePhis==1 && incomings>2) || nested`
(`PredMuxFlatten.cpp:405`) — a plain depth-1 single-phi 2-incoming diamond is
left to the SwapRoute value path, so I1's flatten target is the **2-phi / ≥3-way
merge** shape. The flattened muxes are simple `select(icmp, derived, derived)`
(zero toffoli at single-level depth), lowered by the two-arm select path; nested
/ compound-condition muxes (toffoli) survive as un-`ICmpInst`-conditioned selects
and decline at the backstop (later increment).

**e2e reality.** A real multi-block merge-phi diamond almost never survives
`clang -O1` from C — SimplifyCFG if-converts it (even heavy arms) to a `select`,
and simple arms collapse to *constant*-arm selects (a declined shape). But the
same generalized two-arm path lowers a `select(icmp, derived, derived)` directly,
which clang DOES emit from an if/else with non-factorable arms. So the e2e
`e2e-slice-specialize-twoarm-select` (`spec_twoarm_{caller,lib}.c`) link-proves
the two-arm emission from real C, and the PredMux-flatten path is pinned by the
hand-written lit `spec_accept_diamond_body.ll`. The real multi-block-diamond e2e
arrives with I2 (fp80 multi-exit early-returns, which clang KEEPS).

## Verification

- **Lit accept** `spec_accept_diamond_body.ll` (2-phi diamond → flatten → two
  muxes → Bennett wrap; the reversible embedding pinned line-by-line).
- **Lit rejects** `spec_reject_diamond_{multiexit,store_arm,nested_compound,
  qq_cond}.ll` — the four over-accept boundaries (I2 multi-exit; memory-in-arm;
  compound/nested; Q+Q condition), each mirroring its diagnostic.
- **e2e** `e2e-slice-specialize-twoarm-select` — two-derived-arm select from real
  C, links + byte-diffs the 31-line reversible trace golden.
- Full ctest green; no regressions.

## Rule-13 adversarial clearance (2026-07-16, 3 independent lenses)

Three independent adversarial reviewers, each charged to REFUTE, probing the
built plugin (no source access to the reasoning):

- **Reversibility & Bennett composition — CLEAN.** All four charges (double-
  uncompute, dirty-free, dropped-edge/wrong-mux, LIFO) refuted with reproduced-IR
  evidence + exact rail-balance accounting (producers = frees + 1, the escaping
  out) across fan-out, mux-chains, shared-arm, sequential-diamond, wide-i64, and
  boolean-phi probes. No finding.
- **Taint / reseed / block-lifetime — 1 latent item, FIXED.** Reseed correctness,
  fixpoint termination, cross-function scoping, and flatten-before-drain ordering
  all refuted. Found ONE latent Rule-9 lifetime-invariant violation:
  `MergeBlockIntoPredecessor` (after the last reseed) can RAUW+erase a folded
  block's single-incoming tainted PHI, leaving a freed pointer in `ct.Tainted`
  (unexploitable — byte-correct output, unreachable from `clang -O1` — but the
  unforgivable hazard class). **Fix:** one final `reseedCloneTaintFromParams`
  after the fold loop.
- **Over-accept holes — 1 CONFIRMED bug, FIXED.** An **fp-return multi-block
  value diamond** produced a verify-dirty broken module (SIGABRT, no house
  diagnostic): `predictReturnTainted` read only the entry-block terminator (a
  `br` for a diamond), under-predicting "classical", so `cloneFor` kept the
  `double` return while `emitBennettWrap` emitted `ret i32`. **Fix (root cause,
  Rule 17 — lower it correctly, don't decline the intent):** scan ALL blocks for
  the return value(s) and over-approximate return-taint. The fp-return diamond
  now lowers to a correct reversible embedding (i32-rewritten signature,
  `cqrt_copy_f64_controlled` arm muxes, i32 copy-out, exact LIFO reverse, rail
  balance 10−9=1, verify-clean) — pinned by `spec_accept_diamond_fpret.ll`. All
  other over-accept probes (compound, loop, unreachable, switch, store, Q+Q,
  constant-arm, i128/i80, multi-exit fp, classical-fp-return) decline loudly.

Both fixes folded and re-verified: the full over-accept probe battery re-run
shows the two broken cases now verify-clean, every prior decline still declines,
every prior safe-lowering still verify-clean; full ir-pass-lit 796 + 1 XFAIL.

## Status

I1 core LANDED + Rule-13-cleared (3 lenses, 2 findings fixed + re-verified) —
fixtures + e2e + full ir-pass green, full ctest re-running. **Ready to commit.**
I2 (multi-exit controlled-return, the fp80 cells → unblocks 3c6m.55) is the next
increment on the same substrate — and the `predictReturnTainted` + fp-return-
diamond correctness landed here is I2 substrate already proven.

---

## I2 — multi-exit controlled-return / constant-sentinel arms (2026-07-16)

### Reality first (Rule 11 — the phase-start de-risking spike, all IR extracted, none guessed)

The whole I2 plan pivots on what `clang -O1` *actually* emits for the fp80
early-return shape. The spike compiled the real openlibm guard shape and the
`expl` body and extracted the IR:

- **clang -O1 pre-merges multi-exit early-returns into a single-exit merge-phi
  diamond.** The int 3-guard `if(g1)ret C1; if(g2)ret C2; if(g3)ret C3; ret f(x)`
  and the fp80 `mini_expl` both come out of `clang -O1` as ONE `ret` over a merge
  phi with **classical-constant** incomings and one tainted incoming:
  `%9 = phi x86_fp80 [ %7,%5 ], [ INF,%1 ], [ 0.0,%3 ]`. SimplifyCFG does the
  return-merge itself; the genuine multi-exit `ret`-per-arm form (the hand-written
  `spec_reject_diamond_multiexit.ll`) is **synthetic** — real cells never reach
  the clone with separate `ret` blocks. A robust pass still normalizes the
  synthetic form to the same merge-phi shape (below), but the *load-bearing* work
  is the merge-phi-with-constant-arms lowering.
- **A single-guard early-return if-CONVERTS to a `select` with a constant arm**
  (`select i1 %2, i32 999, i32 %4`). So the 1-guard case arrives as a
  constant-arm select, not a diamond.
- **The scoped PredMux fixpoint already flattens the merge-phi diamond** (verified:
  the 3-guard normalized clone flattens clean and declines only at the constant
  arm). PredMux emits a nested `select` chain with (a) **compound and/or-tree
  conditions** (nested-guard edge predicates, `¬g1∧g2`) and (b) **classical-constant
  arms** (the sentinels). `lowerCloneSelect`'s I1 two-arm path declines both
  (`isLiftableSelect` requires an `ICmpInst` condition and both arms non-constant;
  the re-proof rejects a constant arm as "mixed classical/quantum").
- **The top-level select substrate already lowers exactly this** — materializes a
  const arm via `cqrt_alloc_<W>(const)` and mints a compound condition via
  `cqrt_toffoli` conjunction (`emitSelectRegion`/`materializeCopySource`,
  Rule-13-cleared). But it is **self-contained** (it strips its own flags via
  `_inv`+`free`), so reusing it verbatim in a clone would double-uncompute against
  the Bennett wrap (H1). The clone needs the **forward-only** version (flags LIVE,
  wrap owns the single reverse), exactly as I1's two-arm select already does for a
  single flag.

### Design (finalized) — five coordinated changes, maximal reuse

1. **Materialize-classical-arm** (`lowerCloneSelect`). A non-tainted (constant or
   classical-runtime) select arm is materialized into a copy-source rail via the
   shared `materializeCopySource` (`cqrt_alloc_<W>(V)`; Rule 14). The materialized
   rail is a **separable classical |const⟩** — it is **left allocated, never
   freed** (Rule 6 "a rail not provably |0⟩ is left allocated, never dirty-freed";
   the SAME behavior the Rule-13-cleared top-level `emitSelectRegion` exhibits, so
   no fp-`xorc` clean is needed and int/fp are uniform). It is captured into
   NEITHER `ForwardStream` nor `ScratchRails` (leaked); the controlled copy that
   reads it IS in `ForwardStream` and the Bennett reverse re-reads the still-live
   |const⟩. This unlocks BOTH the 1-guard `select(icmp,C,f(x))` and every
   PredMux-flattened const-arm mux.
2. **Compound-condition forward mint** (`lowerCloneSelect`). The condition is
   generalized from `dyn_cast<ICmpInst>` to `collectCondTree` + the post-order
   network mint (leaf `cq_template_icmp` flags via `lowerCompareToFlag`; `and`→
   `cqrt_toffoli(l,r,g)`; `or`→`cnot;cnot;toffoli` — the `emitSelectRegion` step-1
   logic, mirrored clone-locally so the shared top-level emitter is untouched). The
   mint is **forward-only** — no local strip; the root flag gates the two copies.
   The network (leaf flags, node toffoli/cnot mints, i1 ancilla allocs) is captured
   for the single Bennett reverse. A single-leaf tree is byte-identical to the I1
   `lowerCompareToFlag` mint (existing fixtures unaffected). Per-leaf Q+Q fence
   retained.
3. **`cqrt_toffoli`/`cqrt_cnot` → `isInverseEmittable`** (EmitInverse). They are
   self-adjoint involutions (`g ^= a&b` / `g ^= a`, applied twice = identity),
   re-emitted as-is exactly like `cqrt_cswap`/`cqrt_x` (same self-inverse branch,
   same CurHandle-never-threaded discipline — `emitInverseChain` always passes
   null). **Top-level-safe:** the whole-DAG uncompute's terminal selection
   (`isDataProducer`) only recovers `cqrt_alloc`/`cqrt_qram`/uncontrolled
   `cq_template_*`; ancilla toffolis/cnots are never tainted and never data
   producers, so they never enter a recovered chain — this only enables the NEW
   clone Bennett reverse. Verified against `Uncomputation.cpp:isDataProducer` +
   the self-contained top-level strip.
4. **`ClaimAll` in the clone** (PredMuxFlatten). The W-witness
   (`NumMergePhis>=2 || 3-incoming || nested`) exists only to avoid overlapping the
   top-level SwapRoute/select emitters — irrelevant in a clone (they do not run
   there). `lowerCloneControl` drives `flattenPredMuxRegions(M, ct, /*ClaimAll=*/
   true)` so PredMux claims ANY acyclic single-exit tainted value region, incl. the
   2-incoming single-guard diamond the synthetic fixture normalizes to. Module-level
   callers keep `ClaimAll=false` (zero top-level behavior change; the param
   defaults false).
5. **`normalizeReturnMerge`** (Specialization, in `lowerCloneControl` before the
   PredMux fixpoint). Genuine multi-exit `ret`s (synthetic fixture + front-end
   robustness) are merged into a single-exit merge-phi block (the 65wb
   controlled-return merge, but a rotation-free value body — no controlled gates,
   just a phi + one `ret`), reducing any multi-exit to the merge-phi shape PredMux
   claims. Identities captured before erasing (Rule 9 / H3).

### Hazard resolution (the Rule-13 core)

- **H1 (double-uncompute)** — forward-only mint, flags kept LIVE, the network +
  copies + materialized rails captured into the single Bennett `ForwardStream`;
  the wrap's `emitInverseChain` plays the exact LIFO strip
  (`x⁻¹, copy⁻¹, toffoli/cnot⁻¹, icmp _unc`, then frees). This IS the top-level
  step-5 strip, owned by the wrap — exactly one reverse, no local strip.
- **H2 (early-return skips the guarded compute)** — the fall-through computation is
  speculated unconditionally by PredMux `moveBody`; a pure rotation-free clone body
  is safe to over-compute (Bennett uncomputes it), and the mux selects the correct
  value on each basis state. Every rail is provably |0⟩ before free (materialized
  |const⟩ rails are left allocated, never freed).
- **H3 (block-lifetime UAF)** — PredMux owns the flatten teardown (already
  Rule-13-cleared); `normalizeReturnMerge` captures block/return identities before
  the first erase; `reseedCloneTaintFromParams` recovers `ct` after the flatten (as
  in I1).

### Decline boundaries (Prime Directive — new I2 over-accept probes)

Classical-condition tainted select (classical control over quantum arm) declines
"mixed"; Q+Q compare leaf declines (per-leaf fence); unsupported-width arm / fp
vector / i128 arm / `fp128` decline; a loop / non-acyclic / non-claimable control
shape declines at the `lowerCloneControl` backstop; a surviving un-lowered tainted
select declines at the `buildClone` backstop.

### Increment ships coshl→expl first (Rule 17 — build the intent), then the 6

Core target: the merge-phi-with-constant-arms diamond (all 7 fp80 cells arrive in
this shape). First committed golden: `coshl → expl` at -O1 from the openlibm
corpus. Re-census (`peel_census`) after landing to expose any layer behind the
now-lowered control.

## I2 — LANDED (2026-07-16, pending Rule-13 clearance)

Five coordinated changes shipped, all reusing shipped machinery (Rule 14):

1. **`EmitInverse.cpp`** — `cqrt_toffoli`(arg_size 3)/`cqrt_cnot`(arg_size 2) added
   to the self-inverse involution family in `isInverseEmittable`/`emitInverseCall`.
   The EXACT-arity gate fences the synthetic non-void same-named fake in
   `lowering_uncompute_uninvertible.ll` (that probe now uses a 1-arg i32 `cqrt_cnot`
   which stays un-invertible → the top-level uncompute still declines). Top-level
   safe: real gates are void, never tainted, never `isDataProducer`.
2. **`PredMuxFlatten.cpp`** — `flattenPredMuxRegions(M, taint, claimAll=false)`; the
   clone passes `true`, dropping the W anti-overlap witness (claims any acyclic SESE
   tainted region). Module callers keep the default (top-level byte-identical).
3. **`Specialization.cpp lowerCloneSelect`** — generalized: the condition is minted
   as a `collectCondTree` NETWORK forward-only (`mintCondNetwork`: leaf
   `cq_template_icmp` flags + `cqrt_toffoli`/`cqrt_cnot` conjunctions onto |0⟩ i1
   ancillas, flags LIVE); a classical arm is materialized via `materializeCopySource`
   (`cqrt_alloc_<W>(const)`, left allocated — a separable |const⟩ leak, Rule 6). The
   taint trichotomy (tainted-cond → emit; classical-cond+tainted-arm → loud "mixed";
   whole-classical → leave) + per-leaf Q+Q fence. The i1 ancilla allocs join
   `SelectOutRails` (ScratchRails/freed); the toffoli/cnot node mints join
   `SelectNodeMints` (ForwardStream reverse-only); materialized const rails are
   captured by NEITHER (leaked). The I1 one-copy fast path is preserved
   (single-leaf tree + const-0 false + tainted true).
4. **`Specialization.cpp normalizeReturnMerge`** — folds genuine multi-exit `ret`s
   into a single-exit merge-phi block (before the PredMux fixpoint). Idempotent on
   the common `clang -O1` pre-merged single-`ret` shape. A load-bearing DEFENSIVE
   guard: it BAILS if any `ret` value type ≠ the clone's declared return type — the
   fp-ABI-rewritten case (i32 return, x86_fp80 `ret` values, RAUW resolves later)
   would otherwise build a mistyped (broken) phi. A genuine-multi-exit-FP clone thus
   declines cleanly at the backstop (`spec_reject_multiexit_fp.ll`); the pre-merged
   fp shape (the real cells) lowers.
5. **`SpecializeReject.cpp`** — unchanged accept gate (the merge-phi diamond passes
   the existing phi/br whitelist; the flattened const-arm/compound selects are
   created post-detection in the clone, so they bypass the raw-`select` gate —
   `isLiftableSelect` is left as-is, keeping the raw const-arm-select fixtures green
   and risk contained).

**Verification.** e2e golden `e2e-slice-specialize-multiexit-fp80`
(`spec_multiexit_{caller,lib}.c` — an fp80 `expl`-family multi-exit controlled-return,
the openlibm shape) LINK-proves `@__cq_q_mini_expl_1` + `cqrt_copy_f80_controlled` +
`cqrt_toffoli` + the fp80 producer `_unc` twins resolve; 46-line deterministic trace.
Accept fixtures `spec_accept_{diamond_multiexit, diamond_nested_compound,
multiexit_const_mux, fpret_const_diamond}.ll` (the 1-const-arm, depth-2 compound,
both-const-arm, fp-const-return shapes, reversible embeddings pinned). Decline probes
`spec_reject_{clone_switch, clone_loop, clone_classical_cond, clone_classical_leaf,
multiexit_fp}.ll` (the I2 boundary: in-clone switch, loop,
classical-condition-over-quantum, classical-compare-leaf, genuine-multi-exit-fp).

## I2 — Rule-13 adversarial clearance (2026-07-17, 4 independent lenses + 1 re-clear)

Four independent adversarial reviewers, each charged to REFUTE, probing the built
plugin:

- **Reversibility & Bennett composition — CLEAN on all axes**, but independently
  CONFIRMED Finding 1 (below). H1 double-uncompute, dirty-free, materialized-rail
  leak, toffoli/cnot self-inverse, LIFO, rail balance, and the nested-clone twin all
  refuted with per-basis tracing + exact rail-balance accounting across fan-out,
  OR-condition, 3-guard ladder, shared-leaf, and nested-clone probes.
- **Taint / reseed / block-lifetime — CLEAN.** The decisive invariant: during the
  block-erasing window in `lowerCloneControl`, `BirthOrder`/`StaleDeclined` are
  empty and `HandleWidth` is arg-keyed only, while `Tainted` is fully rebuilt by the
  final unconditional `reseedCloneTaintFromParams`; every post-control writer keys on
  live values; `scrubCloneTaint` clears all four maps per cascade-erased node.
  `claimAll` is clone-local by pointer identity (verified with sibling clones).
- **Top-level regression — CLEAN.** Five barriers prove a real (void) `cqrt_toffoli`/
  `cqrt_cnot` can never reach any top-level inversion path (`DagTraversal` recovers
  only via `isInPlaceGateOn`/tainted operands, both excluding void gates;
  `isDataProducer` excludes them; the arity fence rejects the synthetic fake; all
  `emitInverseCall` sites pass `CurHandle=null`). `claimAll` defaults false at both
  module callers (unflippable compile-time default).
- **Over-accept — 2 CONFIRMED findings, both FIXED + re-verified:**
  * **Finding 1 (verify-clean silent miscompile):** a COMPOUND branch condition
    `c1 ∧ c2` with `c1` tainted and `c2` an ALL-CLASSICAL leaf minted the classical
    runtime value into the i32 HANDLE slot (`cq_template_icmp_..._hl(i32 %classical,
    …)`) — a phantom rail ID aliasing an unrelated qubit (§5.2 prohibition; the top
    level declines the same shape). Reproduced from real C at `-O1` (wrong answer,
    exit 0). **Fix:** a per-leaf all-classical fence in `mintCondNetwork` (a leaf
    with NEITHER operand tainted → loud decline), mirroring the top-level gate. A
    Q-vs-classical-runtime leaf (exactly one tainted operand) still lowers correctly
    (the classical value rides the `_hl` literal slot). Pinned by
    `spec_reject_clone_classical_leaf.ll`.
  * **Finding 2 (broken module, exit 134, no house diagnostic):**
    `predictReturnTainted` filtered out constant return values, so an fp diamond
    whose arms are classical constants (`if(q>C) return 1.0; return 0.75`) predicted
    classical → `cloneFor` kept the `double` return while `lowerCloneSelect` minted a
    tainted i32 out rail → a mistyped `ret i32`. **Fix (root cause, Rule 17):**
    `predictReturnTainted` over-approximates — a tainted conditional terminator ⇒
    predict the return tainted ⇒ `cloneFor` rewrites the fp return → i32; the
    pre-merged fp-const diamond (the real clang -O1 shape) now lowers to a correct
    reversible embedding (i32 signature, `cqrt_copy_f80_controlled` muxes, exact
    reverse), pinned by `spec_accept_fpret_const_diamond.ll`. Plus a symmetric
    defense-in-depth guard in `buildClone` (actual-tainted + fp-declared → loud
    decline). Over-prediction of a genuinely-classical-fp-return-under-tainted-diamond
    is caught by the existing mispredict guard (safe decline).
  * SECONDARY (scope note, not a bug): `isLiftableFpSelect` whitelists {f32,f64} for
    RAW selects, but the diamond→PredMux→`lowerCloneSelect` route intentionally admits
    f80 (the fp80 cells; `copyControlledFpFn` supports f80, verified reversible). Raw
    f80 selects still decline conservatively (a later widening); the diamond-route f80
    acceptance is the I2 target — the SAME raw-gated / flattened-handled consistency as
    the const-arm case.

Both fixes re-verified: the full over-accept probe battery re-run (both findings now
decline/lower correctly, all prior REFUTED shapes still lower/decline, Q+Q vs
Q-vs-classical vs all-classical trichotomy correct), plus a targeted re-clearance
lens on the two fixes. Full ctest all-pass, ir-pass-lit green with the two new
regression fixtures.
