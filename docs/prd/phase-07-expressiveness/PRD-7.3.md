# Phase 7.3 PRD — Bounded loops (rolled-in-place)

> **Status: Inc 1 + Inc 2 DONE (2026-06-25).** Increment 1 — Case A in-place
> persistent-rail collapse — and Increment 2 — Case B per-iteration in-body
> uncompute — are both landed and Rule-13-cleared (independent adversarial
> review each; Inc-2 review additionally surfaced + fixed a do-while-nested-loop
> silent miscompile now pinned by `lowering_reject_loop_nested_quantum.ll`). New
> stage `lowerLoops` (`ir-pass/src/LoopLowering.cpp` / `include/LoopPlan.h`) +
> the `taint.IterationLocalBlocks` spine hook; 6 positive/negative lit fixtures +
> 2 e2e goldens (`slice_loop_phase_accum`, `slice_loop_iter_local`); NO new
> frozen runtime ABI. The deferred **static-K unroll fallback** for X1
> cross-iteration dirty rails (§2.7, Deliverable 6) is filed as `799w.3` and is
> NOT part of this phase's done-criteria. Originally written 2026-06-24 to
> memorialize the design decisions for epic `799w`. Does not duplicate
> [`ROADMAP.md`](../../../ROADMAP.md) §"Phase 7 — 7.3" or
> [`docs/design/rssa-swap-control/SCOPING.md`](../../../docs/design/rssa-swap-control/SCOPING.md)
> §4/§5; captures the 7.3-specific decisions, deliverables, and done criteria.
>
> **Model supersession (owner decision 2026-06-24, `bd memories owner-dynamic-circuits-in-model`).**
> This PRD **supersedes the static-K-unroll framing** carried by the `799w` issue
> description, ROADMAP §7.3 ("static-trip-count unroll"), `SCOPING.md` §5 ("Loops:
> still require a static upper bound … must be unrolled"), and the Bennett parity
> map. CQ's model is **not** restricted to fixed/static circuits — dynamic circuits
> (classical control over quantum variables) are in scope. **Loops lower ROLLED
> IN-PLACE**: the loop CFG is preserved and the body's tainted ops lower to the same
> `cqrt_*` / `cq_template_*` stream that the straight-line form produces. Unrolling
> buys nothing for the common case (a rolled phase loop traces byte-identically to
> the manually-unrolled form — verified 2026-06-24); **static-K unroll is demoted to
> an optional, deferred fallback** for the cross-iteration-dirty-rail case only.
>
> **Owner scope decision (2026-06-24):** 7.3 ships the **full sound-rolled
> invariant** — Case A (in-place persistent accumulator) **and** Case B
> (iteration-local born-and-dies temporaries via per-iteration in-body uncompute,
> the ROADMAP "Phase-5 obligation" discharge). It declines cross-iteration dirty
> rails (→ deferred static-K unroll follow-on) and quantum/measurement-bounded loops
> (→ different model). Governing memories: `[[owner-dynamic-circuits-in-model]]`,
> `[[divergent-arm-uncompute-soundness-guard]]`, `[[5-wi4-closure-check-unifies-fanout-and-leak]]`,
> `[[swap-route-detect-known-limits]]`.

---

## 0. Invariant recap (not new — the ground 7.3 stands on)

- **Over-declining is safe; over-accepting is a silent miscompile** (Prime
  Directive). A wrong static trip count or a dirty rail freed across a backedge is
  a verify-clean miscompile; every new accept-predicate ships a decline fixture +
  adversarial probe (Rule 12).
- **Verify-clean ≠ correct** (Rule 2). 7.3 touches `TaintPropagation`
  (`declineClassicalMuxes`), the Phase-5 uncompute spine
  (`FreePoint`/`Uncomputation`/`DagTraversal`/`EmitInverse`), and adds a
  loop-recognition stage — the modules where every silent miscompile has lived. It
  is cleared by independent adversarial Rule-13 review, **not** by a green suite
  (Rule 13).
- **Taint is the only Q/C boundary** (Rule 3). 7.3 adds **no** taint source and
  **no** new opcode taint rule. `@cq_theta` stays the sole source, `@cq_measure`
  the sole sink. A loop-carried header `phi` whose incoming is tainted is **already
  tainted** by stock forward propagation (`TaintPropagation.cpp:283-285`,
  `:310-311`) — 7.3 changes only *which* such phis are **accepted**, not how taint
  flows.
- **Detection is pure analysis by SSA/CFG identity, before any mutation** (Rule 9).
  Loop recognition uses a freshly-built `LoopInfo` (`DominatorTree DT(F); LoopInfo
  LI(DT)`), reading header/latch/backedge/exit/header-phis, **before** any lowering
  — the same direct-construction idiom already used for the backedge guards
  (`FreePoint.cpp:240`, `Uncomputation.cpp:291`).
- **Coherent-first; never insert a measurement** (Rule 5). 7.3 emits **zero**
  measurements; a rolled in-place handle keeps its answer on the rail and is
  measured/escaped after the loop exactly as the straight-line form is.
- **Free only a proven-`|0⟩` rail; no-cloning** (Rules 6/8). The Case-B
  per-iteration `cqrt_free` lands **inside the loop body, after the temporary's last
  in-iteration use and before the backedge** — provably `|0⟩` (its whole DAG is
  recovered within the iteration) and provably reached **once per iteration**, never
  the function-scope post-dominator (which would free K times → use-after-free +
  double-free).
- **`clang -O1` is the validated floor** (Rule 9). `-O1` keeps a `cq_*`-bodied loop
  **rolled** with a preserved backedge (`br …, !llvm.loop`) and an integer
  induction variable; it **never unrolls** it (the `cq_*` calls are opaque externs
  it cannot speculate) — verified by extracting real IR (Rule 11, §1). 7.3 cannot
  lean on the unroller; it lowers the rolled shape directly.

---

## 1. Scope

7.3 widens the **accepted-C subset** so a **classically-bounded** loop (`for`/
`while` with an untainted trip/exit condition) over a tainted body lowers
**rolled in place**. `CQ.h` does not change — loops are plain C. The pass keeps the
loop CFG and lowers the body's tainted rotations/ops to the existing reversible
stream. **No new frozen ABI** (ROADMAP §7.3): 7.3 reuses `cqrt_alloc_<W>` /
`cqrt_ry`/`cqrt_rz`/`cqrt_x`/`cqrt_cnot` (in-place gates), the `cq_template_*`
(+`_unc`) value/compare surface, `cqrt_free`, and the `emit_inverse` adjoint spine.

### 1.1 The load-bearing empirical finding (verified 2026-06-24, Rule 11)

Running the live plugin (`opt -load-pass-plugin … -passes=cq-lowering`) on six loop
shapes establishes the ground truth 7.3 must change. **Every loop over quantum
state declines today** — there is *no* rolled-loop path, *no* unroll path, and *no*
leak; all declines are loud (`opt` exit 1, empty output, Prime Directive honored).
The decline lands in one of two distinct guards keyed on **whether the exit
condition is tainted**:

| # | Shape (C) | `-O1` loop | TODAY | Diagnostic (verbatim) |
|---|---|---|---|---|
| 0 | straight-line manual unroll (no loop) | n/a | **LOWERS** — `cqrt_alloc`+`cqrt_ry`+N×`cqrt_rz`+`cqrt_measure`, in-place, no free | — |
| A1 | const-bound phase accumulator `for(i<4) q=cq_phi(q,0.1*i)` | rolled, classical exit | **DECLINE** | `cq taint escape: tainted value muxed by a classical-condition phi` |
| A2 | runtime-bound `for(i<n)` (n a param) | rolled, classical exit | **DECLINE** (same) | `cq taint escape: tainted value muxed by a classical-condition phi` |
| B1 | iteration-local dead temp `t=q+i; cq_phi(q,…)` | rolled, classical exit | **DECLINE** (header-phi reject fires first) | `cq taint escape: tainted value muxed by a classical-condition phi` |
| X1 | cross-iteration value accumulator `acc=acc+q` | rolled, **loop-carried tainted phi** over a fresh `fadd` rail | **DECLINE** | `cq taint escape: tainted value muxed by a classical-condition phi` |
| Q1 | quantum/measurement-bounded `while(acc<10.0)`, `acc` tainted | rolled, **tainted** exit `fcmp olt` | **DECLINE** (different guard) | `cq controlled lowering: nested control flow under quantum control` |

Two facts fall out: (1) **the target lowered form already exists** — the
straight-line chain (case 0) lowers to the exact in-place stream a rolled loop body
needs; 7.3's job is to let the *rolled* form reach it. (2) `clang -O1` **never
unrolls** a `cq_*` body, so 7.3 lowers the rolled CFG directly.

### 1.2 What 7.3 actually is

`ControlDetect` keys **strictly on condition taint** (`ControlDetect.cpp:370`,
`:382`, `:394`). A classically-bounded loop's exit `icmp` is **untainted**, so the
loop CFG (backedge, header phi) is **invisible** to control detection — the loop is
**not** a tainted-control problem. 7.3 is a **taint + uncompute** problem with two
sub-cases, each removing one of the two guards in §1.1:

- **Case A — in-place persistent accumulator (Increment 1).** A tainted handle
  threaded through a loop-carried header phi, mutated only by **in-place** gates
  (`cq_phi`=Rz, `cq_theta`=Ry in the preheader, in-place `x`/`cnot`), and
  ultimately **measured or escaped** after the loop. The *only* blocker is
  `declineClassicalMuxes`'s loop-header-phi reject (`TaintPropagation.cpp:1042`,
  `kMsgClassicalPhi`). 7.3 recognizes the in-place self-cycle and **collapses the
  header phi to its single persistent rail** so the body lowers to `cqrt_rz(%h,
  angle_i)` over a loop-invariant `%h`. **No in-body free** (the handle lives past
  the loop). This is the owner-headlined common case (phase accumulation, repeated
  rotation, Trotterization).

- **Case B — iteration-local born-and-dies temporary (Increment 2).** A tainted
  value computed **and** dead within one iteration (a value-op rail consumed inside
  the body, recovered by the Phase-5 spine). This requires the spine to place the
  per-iteration recovery **inside the loop body** (after the temp's last
  in-iteration use, before the backedge), lifting `FreePoint`'s loop-backedge guard
  (`FreePoint.cpp:237-245`, `kMsgLoopBackedge`) and the driver backstop
  (`Uncomputation.cpp:284-299`) **for the proven iteration-local shape only**. This
  is the ROADMAP "discharge the Phase-5 obligation" work.

**Declined (loud), not lowered:** quantum/measurement-bounded loops (Q1 — different
model + coherence); cross-iteration dirty rails (X1 — deferred to the static-K
unroll follow-on); tainted control inside the body; QRAM/tainted-index memory in a
loop (`iw81.13`, gated on this phase). See §2.6–§2.8 and the §2.10 matrix.

---

## 2. Design decisions

### 2.1 Rolled-in-place is the model; static-K unroll is a deferred fallback (owner decision 2026-06-24)
The lowered IR **preserves** the loop's header/latch/backedge/exit. Lowering mutates
individual tainted instructions in place (`replaceAllUsesWith` + `eraseFromParent`)
and calls **no** CFG-restructuring transform, so a freshly-rebuilt `LoopInfo` after
lowering reports the same loop. **The trip count need not be a compile-time
constant** — a *dynamic but classical* bound (`for(i<n)`, A2) lowers identically to
a constant bound (A1); the runtime loop runs the body the right number of times.
This is the central reversal vs. the old "prove K at compile time" requirement,
which existed **only** because unrolling needs K. Unrolling is demoted to a deferred
fallback for the cross-iteration-dirty-rail case (§2.7); `bd memories
owner-dynamic-circuits-in-model` also flags that a future Phase-9 fixed-circuit
gate backend **may** re-impose static-K — out of scope here, trace-only hides
dynamic gate counts today.

### 2.2 The sound-rolled invariant — the accept predicate (the heart; evaluated on SSA/CFG identity before any mutation, Rule 9)
A natural loop `L` (from `LoopInfo`) is **rolled-lowerable** iff **ALL** hold:

**(L1) Classical trip/exit.** Every exiting branch condition of `L`
(`L->getExitingBlocks`) is **untainted** (`!taint.Tainted.count(cond)`). Else
DECLINE — *quantum-bounded loop* (§2.6). The canonical taint query is the existing
`taint.Tainted.count(BI->getCondition())` (`ControlDetect.cpp:370`). (Note: a
`cq_measure` **result** is *not* tainted — `isMeasureSink` halts propagation at
`TaintPropagation.cpp:293` — so a loop bounded by `if(measure(q))` has a *classical*
exit and is **not** Q1; a loop bounded by `icmp/fcmp` on a live tainted value is.)

**(L2) No tainted control inside the body.** No tainted-condition `br`/`select`/
`switch` in `L`'s blocks. Else the **existing** `ControlDetect`/`RegionTreeDetect`
declines (loop-resident nest, `RegionTreeDetect.cpp:140-145`; `swap-route-detect-known-limits`).
7.3 does not lower control-in-loop (§2.8).

**(L3) No tainted-index memory in the body.** No tainted `load`/`store`/`gep` in
`L`. Else the **existing** `kMsgQramLoop` declines (`QramLowering.cpp:103-104,
:416-417`); QRAM-in-loop is `iw81.13`, gated on this phase (§2.8).

**(L4) Every tainted value defined inside `L` is exactly one of:**
  - **(a) persistent in-place handle** — threaded through a loop-carried header phi
    of `L`, every definition an **in-place** gate (`cqrt_rz`/`cqrt_ry`/in-place
    `cqrt_x`/`cqrt_cnot`), the latch-incoming resolving (peeling in-place hops) back
    to **the header phi itself** (a closed self-cycle ⇒ a single persistent rail),
    and the value **measured or escaped** after `L` (it lives past the loop, never
    freed in the body); **or**
  - **(b) iteration-local** — its whole recovered DAG (`DagTraversal::recoverDataDag`)
    lies **within** `L`, is **CLOSED** (`!D.NotClosed`), **not** `MeasuredUpstream`,
    **not** `Escaped`, and is recovered + `cqrt_free`d by an in-body per-iteration
    uncompute placed after its last in-iteration use, before the backedge.

  A tainted value that is **neither (a) nor (b)** — a **cross-iteration dirty rail**
  (born in iteration *i*, consumed in *i+1*; or a dirty out-of-place accumulator
  threaded through the header phi to a *different* rail each iteration, needing
  post-loop reversal, X1) — DECLINES (§2.7).

The predicate is the union "everything born in an iteration dies in it; only
in-place-gated persistent state crosses the backedge" — the owner's sound-rolled
invariant verbatim.

### 2.3 Where the loop stage slots (orchestration)
A new `detectLoops` (pure analysis) + `lowerLoops` pair interposes in
`CQLoweringPass::run` (`CQLoweringPass.cpp:50-186`) **beside `detectControlRegions`
(`:110`)**, with three hard ordering constraints from the existing pipeline:
1. **Before `lowerRotations` (`:177`)** — like every other control/QRAM/IO stage,
   it must read the still-present `@cq_theta`/`@cq_phi` SSA values *before*
   `lowerRotations` RAUWs them to `i32` handles.
2. **Before `declineClassicalMuxes` (`:154`)** — so the recognized loop-carried
   header phi is consumed by the Case-A header-phi collapse (§2.4) and never reaches
   the `kMsgClassicalPhi` reject. An unrecognized loop phi still declines there as
   today (the residual net).
3. **Before `uncompute` (`:182`)** — Case A emits its collapse here; Case B
   registers the in-body free points the spine then honors (§2.5). An
   unrecognized/declined loop never reaches `uncompute`; the `FreePoint` backedge
   guard (`FreePoint.cpp:237-245`) remains the **defense-in-depth backstop** for any
   loop shape the recognizer did not affirmatively accept.

`ControlPlan.h`'s `Kind` enum (`:152-159`) has no loop member and the `ControlRegion`
struct has no header/latch/trip fields — a new `LoopRegion` representation
(header/latch/preheader/exiting blocks + the (a)/(b) classification of each carried
phi) is added rather than overloading the diamond/switch vocabulary.

### 2.4 Increment 1 — Case A: the header-phi collapse (lift `kMsgClassicalPhi` for the in-place self-cycle)
`liftOneRegisterMergePhi` (`TaintPropagation.cpp:847-977`) is an **if/switch-merge**
lift: it requires every incoming to resolve via `resolveWireBase`
(`:808-822`, peels in-place `cq_theta`/`cq_phi` arg-0 hops) to **one common base**,
and it explicitly **rejects the self-incoming cycle** (`:883-884`,
`Chains[0].Base == Phi`). A loop-header phi `%q = phi [%q0, preheader], [%qnext,
latch]` where `%qnext = cq_phi(%q, …)` is *precisely* that rejected self-cycle —
which is why A1/A2/B1 decline today.

**Mechanism (the rolled collapse).** After `lowerRotations`, an in-place gate RAUWs
its result to its operand handle, so `%qnext`'s handle **is** `%q`'s handle. The
header phi degenerates to `phi i32 [%h_alloc, preheader], [%h_self, latch]` with both
incomings the same rail ⇒ loop-invariant `%h`. 7.3 recognizes the **in-place
self-cycle** (latch-incoming peels through in-place gates back to the header phi
itself, over a classical-bounded loop), **collapses the header phi to its single
persistent rail** (RAUW phi → `%h`, erase the phi), and lowers the body so
`cqrt_rz_f64(%h, angle_i)` fires once per iteration on the loop-invariant `%h`. The
value is measured/escaped after the loop — **no in-body free, no uncompute** (Case A
needs neither). This collapse must run coordinated with `lowerRotations` so the phi
never survives as an ill-typed `phi double` with `i32` incomings. Multiple
independent persistent handles (`for(i){q=g(q); p=h(p);}`) collapse independently.

### 2.5 Increment 2 — Case B: per-iteration in-body uncompute (discharge the Phase-5 obligation)
The Phase-5 **recovery + reversal engine is already loop-agnostic**: terminal
detection (`ChainWalk.cpp:82-101`), whole-DAG backward recovery + QQ fan-out + dedup
(`DagTraversal.cpp:53-90`), the closure/measure/escape analysis (`:108-191`), and
the void `_unc` adjoint + free emission (`Uncomputation.cpp:165-188`,
`EmitInverse.cpp`) all work on def-use edges and would correctly recover an
iteration-local DAG entirely within `L`'s body. **The obstruction is purely
placement**, in three coupled spots:

1. **Free-point placement.** `computeFreePoint` (`FreePoint.cpp:116-274`) places the
   free at the **nearest common post-dominator of all use-site blocks**
   (`:247-258`) — for an in-loop use that is the loop exit (outside the body) or a
   point reached once, **wrong** for per-iteration recovery; and the loop-backedge
   guard (`:237-245`) hard-rejects first. 7.3 adds an **in-body insertion point**:
   the last in-iteration use of the temp's DAG, within `L` and before the latch's
   backedge — proven to execute **exactly once per iteration**.
2. **The two loop guards become conditional.** `FreePoint.cpp:237-245`
   (`kMsgLoopBackedge`) and `Uncomputation.cpp:284-299` (silent leak) fire on *any*
   in-loop gate today. 7.3 makes them defer to an **affirmatively-recognized
   iteration-local DAG** (place the in-body free) and keep rejecting/leaking only
   for **unrecognized** in-loop live ranges (the residual net).
3. **Dominance-as-total-order across the backedge.** The reverse-program-order =
   reverse-topological premise rests on "every gate dominates the single insertion
   point" (`DagTraversal.cpp:92-106`; the driver's `kMsgDivergentArm` check
   `Uncomputation.cpp:316-325`). For an **iteration-local** DAG with the insertion
   point in the *same* iteration's body, this holds **within the iteration** (no
   value crosses the backedge by construction of (L4b)); 7.3 scopes the dominance
   reasoning to the loop body so the total-order assumption stays sound. A value
   that would force cross-iteration ordering is exactly the (L4) cross-iteration
   dirty rail → declined (§2.7), never handed to the spine.

This is the genuinely-new spine surgery and the core Rule-13 hazard zone (the
`divergent-arm-uncompute-soundness-guard` lesson applies: a single adjoint must not
reverse a chain that ran K times — which is why the free is placed **inside** the
body, once per iteration, not at a merge).

### 2.6 Quantum/measurement-bounded loops decline — different model (L1)
A loop whose exit condition is a **live tainted value** (`while(q<k)`,
amplitude-/measurement-derived bounds) is a genuinely quantum-controlled branch: a
runtime branch on a qubit, which would require coherent superposition over trip
counts. **Permanent decline** for the trace-only/fixed-template model (it is the
"unbounded / quantum-conditioned `while`" that ROADMAP §"Beyond the freeze" parks).
7.3 emits a dedicated `cq controlled lowering: loop under quantum control`
(reusing the existing `"loop"` `What`, `ControlDetect.cpp:254-259`,
`diagnoseUnderControl`), partitioning this shape out of today's incidental
`"nested control flow under quantum control"` (Q1) for a clearer message.

### 2.7 Cross-iteration dirty rails decline; static-K unroll deferred (owner decision)
A tainted value carried across iterations on a **dirty** (non-in-place) rail (X1:
`acc=acc+q` threads a fresh `cq_template_add` rail through the header phi each
iteration; the prior iteration's rail is dead but **loop-carried**, recoverable
only by post-loop reversal of a K-deep chain) is **not** sound-rolled. It DECLINES
loudly — `cq loop lowering: loop-carried tainted value crosses iterations` (a new
diagnostic, mirror-exact). The **static-K unroll fallback** is the physically
correct lowering for this shape (unroll K bodies, recover each iteration's rail);
it is **deferred to a filed follow-on** (`bd` issue, §3) because (i) the owner
demoted it to "optional," (ii) it pulls in `ScalarEvolution::getSmallConstantTripCount`
+ `llvm::UnrollLoop` — a dependency bundle (TLI + AssumptionCache + TTI + ORE) the
no-link MODULE plugin has **never** linked, whose **dlopen symbol resolution is
unverified** and must be smoke-tested first (LoopInfo/DominatorTree are proven-safe;
SE/UnrollLoop are not), and (iii) over-decline is safe (Prime Directive).

### 2.8 Tainted control / QRAM inside the body reuse existing declines (L2/L3)
7.3 does **not** widen control-in-loop or memory-in-loop. A tainted-condition
branch inside `L` keeps declining via `ControlDetect`/`RegionTreeDetect` (the
nested-region backedge guard, `RegionTreeDetect.cpp:118-145`; `swap-route-detect-known-limits`
item 8). A tainted-index `load`/`store` in `L` keeps declining via `kMsgQramLoop`
(`QramLowering.cpp:416-417`) — QRAM-in-loop is `iw81.13`, which this phase
*gates* (its accept-predicate composes the 7.3 loop recognition with per-iteration
store reversal / LIFO tape pairing) but does not itself deliver. An early `return`/
`break` inside `L` is Phase **7.4** (`y05j`), explicitly blocked on 7.3.

#### 2.8-A AMENDMENT — Increment 3: NON-EXITING tainted control in the body ACCEPTS (owner ruling 2026-08-29, bd `test_C_libtooling-8h7d.5`)

§2.8 above is superseded for ONE shape and unchanged for every other. The owner
ruled on 2026-08-29 that **a purely classical loop (classical trip count,
classical induction variable) around tainted control flow must not decline** —
writing a Grover iteration as `for (i…) { oracle; reflection; }` is how anyone
would actually write it, and the hand-unrolled twin already compiled.

**Scope, exactly.** Every **NON-EXITING** tainted `if` inside a classically
bounded loop body is accepted. Every tainted terminator that **LEAVES** the loop
keeps its current disposition and is a later increment: the quantum-bounded exit
(Q1, `loop under quantum control`), the 7.4 `break`, the controlled `return`.
**No unrolling** — the loop stays ROLLED per §2.1: IR size independent of the trip
count, only the trace grows. Measured: the lowered IR of
`tests/e2e/slice_control_grover_loop_dynamic.c` is 87 lines at `cq_n = 3` and 87
lines at `cq_n = 1000`, byte-identical apart from the initializer, while the trace
goes 57 → 18003 lines.

**Three walls, all bookkeeping — none was a unitary argument.**

1. **The d8jl structural guard** (`ControlDetect::regionEntryInLoop`) declined
   every flat region on a CFG cycle because `RegionFlatten` erases the merge,
   which inside a loop can be the LATCH. That erase has REPAIRED itself since bd
   `dugh` (2026-07-04, written after d8jl): `flattenRegion` runs
   `Pred->replaceSuccessorsPhiUsesWith(Merge, Pred)` before the erase, which
   repoints exactly the header-phi incoming the broken-module report was about.
   The guard is now NARROWED by `flatRegionRollableInLoop`, which admits a region
   only when **(A)** `LI.getLoopFor(Pred)` is a natural loop, **(B)** every region
   block sits at that one depth, **(C)** the loop has a single latch, and **(D)**
   the entry is on no cycle other than that loop's back edge. **(A) and (D) are
   the irreducible fence and they are kept for a REASON THAT IS NOT THE FLATTEN:**
   every guard that adjudicates the flattened body — the Case-A/X1 rail analysis,
   `markIfRailLocal`, `FreePoint`'s back-edge live-range reject — is
   `LoopInfo`-gated and CANNOT SEE an irreducible cycle.
2. **Order.** `lowerLoops` (round 1) still runs BEFORE `detectControlRegions`, so
   Q1's message ownership is untouched; its gate L2 still leaves a
   control-in-body loop unclaimed, because pre-flatten the rail peel stops at the
   region's merge phi and the loop would X1-decline a clean shape. A **ROUND 2**
   (`collapseFlattenedLoopRails`) runs after `lowerControlRegions` and before
   `declineClassicalMuxes`, on the now-straight-line body, and collapses the
   persistent-rail header phi to its root mint. Round 2 makes ONE claim and does
   not re-prove `tryCaseA`'s COVERAGE: the post-flatten body legitimately holds
   values on no rail (the emitted region stream, a derived condition's
   iteration-local template rails), and their disposition belongs to the owners
   that already have it. **It DOES re-prove the other half of CLOSURE, and the
   first version of this increment did not — that omission was a silent
   miscompile (Rule-13 round 1, finding F1, 2026-08-30; see §2.11).**
3. **Position proofs.** `provablyBefore` = `dominates && !reachable-back` is
   falsified by ANY back edge, which is right when the object PERSISTS across
   iterations and useless when it does not. The per-activation reading
   (`provablyBeforePerActivation`, `WireWalk`) adds one disjunct: "every path from
   `B` back to `A` re-executes `Barrier`". It is consulted only when the plain
   proof already failed, so it is strictly additive. The barrier is always the
   instruction whose EXECUTION re-establishes the premise — the record's own
   definition, the rail's mint, the interval's opening gate — and every caller
   states which — **and never the proof's own subject `A`, which is VACUOUS: the
   barrier walk cuts at the instruction it is trying to reach, so the call
   degenerates to plain dominance and the reachability half is silently deleted
   (Rule-13 round 1, finding P1). It is now refused in the predicate.** For an
   interval `[First, At]` the two legs take DIFFERENT barriers: "First before GI"
   takes `At`, "GI before At" takes `First`. **`phiTracksWire` is the fence that
   keeps the record reading honest:** a loop-header phi re-reads the wire only if
   its incomings are the body's last wire writes; a phi carrying a superseded
   record gets no barrier (`lowering_reject_stale_record_loop_nontracking_phi.ll`).
   Its staleness test is **PER WIRE** — a `cq_theta` on an unrelated register
   cannot stale this record. It asked "any `cq_theta` at all" until Rule-13 round
   1 (finding OD1), which made the disposition depend on SOURCE ORDER (moving an
   unrelated mint above the loop's own flipped a decline into an accept) and made
   two independent registers in one loop permanently unlowerable
   (`control_swap_inloop_offwire_theta.ll`). §2.9 below is UNCHANGED — a
   LOOP-INVARIANT seed re-read after an in-body Ry is still the genuine
   iteration-2 stale record and still declines.

**What stays declined** (each with a red fixture): a VALUE (method-B) arm inside
a loop (`control_swap_reject_inloop_value_arm.ll` — its route-back is not the
adjoint of its split, the copied-out `%out` is a different handle every trip, and
nothing proves it `|0⟩` at the back edge); a depth-2 nest or a `switch` in a loop;
an irreducible cycle (`…_irreducible.ll`, `…_second_cycle.ll`); a multi-latch loop
(`…_multilatch.ll`); X1 and the Rule-8 fan-out, now reachable through round 2
(`lowering_reject_inloop_control_{cross_iter,rail_fanout}.ll`); the 6.5
classical-call arm in a loop.

### §2.11 The rail-record liveness fence (Rule-13 round 1, finding F1)

**An SSA name on a collapsed rail is a valid operand only at positions where the
register still holds the state that name denotes.** The collapse RAUWs every chain
member onto ONE handle, so an emitted gate reads whatever the wire holds AT ITS
OWN POSITION while the name denotes a fixed PREFIX of the rail's gate sequence.
Round 2 as first shipped collapsed without asking, and

```c
for (...) { if (q == 5) q = cq_phi(q, PI); acc = q * 7; q += 3; }
return cq_measure(q) + cq_measure(acc);
```

emitted `cq_template_mul_i32_hl(%h, 7)` in the EXIT block (`clang -O1` sinks it —
`acc` is loop-carried and only its last value is read), computing `(q0+3k)*7`
where the source says `(q0+3(k-1))*7`. `opt` exit 0, `opt -verify` clean, STRICT
stage-2b free-pairing clean, no warning: the shape is perfect and only the state
is wrong. Reproduced over the whole `lowerOps` class (`mul`, `and`, `sext`,
mid-body records, dynamic trip count) and — as ROUND 1, **pre-dating this
increment**, verified on a `7ba8b2d` base build (bd `test_C_libtooling-5sva`) —
through `cq_measure`: `for (…) { last = q; q += off; } return cq_measure(last);`.

**The fence** (`LoopLowering::staleRailRecordRead`, asked by round 1's CLOSURE and
by round 2 at steps 2b and 5): for a rail member `v` with definition `D` and a
non-member consumer reading at `p`, DECLINE (`cq loop lowering: rail record read
past an in-place gate on the same rail`) iff some path runs `D`, then a rail
GATE, then `p`, WITHOUT re-executing `D`. GATES are the members that relabel the
computational basis — `cq_theta` (Ry) and the dtzb in-place `add`/`xor` — never
`cq_phi` (Rz, diagonal), and never a SIBLING rail's gates.

**Why positional and not a locality or consumer-class rule.** "No rail member is
read outside `L`" refuses the customer's own `cq_measure(q)`; "no rail member has
a value-op consumer" refuses the region's OWN emitted
`cq_template_icmp_eq_i32_hl(%h, 5)`; "only the latch-carried value may escape" is
wrong in an UNROTATED loop, where the exit test precedes that iteration's gates so
the header phi at the exit edge IS the final state. The positional test gets all
three right without a special case. A PHI consumer's read position is its
**incoming block's terminator** — without that the `-O1` zero-trip guard's exit
phi is refused and `slice_control_grover_loop_dynamic` stops lowering. Fixtures:
`lowering_reject_inloop_rail_record_{escape,midbody}.ll`,
`lowering_reject_loop_rail_record_measure.ll` (red) and
`control_swap_inloop_rail_record_live.ll` (the accept boundary — the same program
with the read moved above the gate).

**One silent miscompile was found and fixed inside this increment**, and it is the
shape to re-probe first if round 2 is ever extended: the collapse RAUWs the header
phi to its root mint, and the peel to that root walks THROUGH an in-place value
self-update (`q += off`, issue dtzb). Round 1 compensates by marking each such op
into `taint.InPlaceRailOps`; the first draft of round 2 did not, so `lowerOps`
emitted the add OUT of place into a rail nothing read and the loop computed on `q`
where the source says `q + off`. `opt` exit 0, verify-clean, STRICT stage-2b
free-pairing clean — the only outward sign was one M-A warning. Pinned by
`control_swap_inloop_railop_inplace.ll` and
`tests/e2e/slice_control_grover_loop_offset.c`.

**The witness** is byte-identity with the hand-unrolled twin, which is the
strongest evidence available without a simulator (Rule 2): three rolled slices,
three unrolled twins, and three `cmp` entries in ctest
(`e2e-grover-loop{,-derived,-offset}-twin-identical`).

**ROUND 2 FOUND TWO HOLES IN THIS FENCE — in its two UNSTATED premises, not in the
sentence above; ROUND 3 THEN FOUND A THIRD, IN THE SAME PLACE ROUND 2 HAD JUST
EDITED.** The sentence was always "no rail-relabelling gate runs between the
record's definition and the read"; the code said narrower things, and every one of
those narrowings was a silent miscompile. Three adversarial rounds, three
`clang -O1`-reachable confirmed miscompiles in one fence: budget a fourth.

*F-1 — the gate set was the CHAIN's, not the RAIL's.* `collectRailGates` built
`Gates` from the peeled `root→PreV→phi→LatV` members only, so a `cq_theta` whose
arg-0 IS a member but whose RESULT is off the chain was not a gate:

```c
for (…) { if (q==5) q = cq_phi(q,PI); q = cq_theta(q,-.5); q = cq_theta(q,.5); }
int mark = q;  q = cq_theta(q, 0.125);       /* OFF-CHAIN in-place Ry */
return cq_measure(mark) + cq_measure(q);
```

emitted `cqrt_ry_i32(%h, 0.125); measure(%h); measure(%h)` — `opt` exit 0,
verify-clean, STRICT stage-2b clean. Ry is ALWAYS lowered in place
(`lowerRotations` RAUWs the result to the handle), so unlike an out-of-place value
op there is no escape hatch. Each chain is now extended FORWARD through the users
that keep mutating the SAME handle, with three edge kinds and each exclusion
load-bearing: a **rotation** unconditionally (`cq_theta` is a gate, `cq_phi` is
followed but is not — Rz is diagonal, and following it is what makes the Ry BEHIND
an Rz visible, whose arg-0 is on no chain); a **dtzb `add`/`xor`** only when it is a
member or already in `taint.InPlaceRailOps` (which is why
`mark = q; q = q + 9; cq_measure(mark)` is CORRECT today and keeps lowering —
`control_swap_inloop_postloop_railop.ll`; **the reason first recorded for this
exclusion, "an off-chain one is lowered OUT of place into a fresh rail", is FALSE as
an unconditional claim** — round 3 measured M-C firing in place on exactly that add
when nothing reads the pre-add register, and the exclusion is sound because M-C's
G6/G7 pair refuses whenever a later read exists, §2.11a); and a
**phi** naming the rail on SOME incoming (`railGateBetween` is an ∃-path test, so
"some" is the sound side). It is NOT transitive past the first gate and does not
need to be: `Def` dominates `t1` and `t1` dominates `t2`, so every path `Def → t2`
crosses `t1` (`lowering_reject_inloop_rail_record_theta_chain.ll` carries the proof).

*F-2 — the cut's premise.* `railGateBetween` suppresses every path that re-executes
the record's definition, on the premise that re-executing refreshes the record. True
of every in-place gate and of an ordinary rail phi; FALSE for a zero-hop
IDENTITY-CARRY phi `%rec = phi [%q0, entry], [%rec, latch]`, which step (1) accepts
TRIVIALLY (`peelInPlaceBase(LatV) == &P` holds with zero steps) and which
re-executes yielding the SAME value while a sibling chain on the same root mint
moves the wire — so the cut removed exactly the path carrying the staleness. Stated
generally, not as `In == P`: a carry refreshes only if it crosses a rail GATE, so an
incoming that peels back to the phi through diagonal/renaming steps alone is the
same frozen record wearing extra phases (`recordRefreshedByDef`). Frozen-ness is
deliberately NOT propagated forward — a gate applied to a frozen record is itself a
non-member read of that record at a stale position, so the fence declines at the
record first. Fixtures: `lowering_reject_inloop_rail_record_{postloop_theta,
onepath_theta,offchain_rz_theta,merge_theta,theta_chain}.ll` and
`lowering_reject_inloop_rail_identity_carry.ll` (red);
`control_swap_inloop_{postloop_railop,gatefree_body}.ll` (the two accept
boundaries — the out-of-place post-loop add, and the gate-free body whose
post-flatten rail phi IS an identity carry and must keep lowering).

### §2.11a Round 3, finding F-3 — the RECORD set was the chain's too

**F-1's exact twin, one hop out, and another confirmed silent miscompile.** Round 2
widened `collectRailGates`' **gate** set from the chain to the rail; it left the
**record** loop — the values `staleRailRecordRead` asks "is any read of you stale?" —
enumerating chain `Members`. A rail value one hop off the chain was therefore never
asked about:

```c
for (…) { if (q==5) q = cq_phi(q,PI); q = cq_theta(q,-.5); q = cq_theta(q,.5); }
int a = cq_theta(q, 0.125);   /* arg-0 IS a member, RESULT is OFF the chain */
int b = cq_theta(a, 0.25);    /* a rail gate AFTER the record `a` */
return cq_measure(a) + cq_measure(b);
```

emitted `ry(%h,.125); ry(%h,.25); measure(%h); measure(%h)` — `a` names the pre-`b`
register and is measured after `b`. `opt` exit 0, verify-clean, STRICT stage-2b
clean. Five programs reproduced it (the shape above; the record reached through a
DIAGONAL `cq_phi` hop; a `ret` escape instead of a measure; a three-hop chain with
TWO stale records at once; and the dynamic-bound hand-IR form). The reads that do
NOT reach here are already owned — a value-op read declines at
`declineStaleRecordOps`, a condition read at `ArmClassify` — so the uncovered
surface was exactly `cq_measure` and `ret`.

**Fix:** `collectRailGates` gained an `OnRailOut` out-parameter and the record loop
runs over that closure. **The SKIP set stays the chain's**, and this is not a
detail: widening it too was measured and turns
`lowering_reject_inloop_rail_frozen_gate_first.ll` from a decline into an accept,
because a `cq_theta` applied to a FROZEN identity-carry record joins the rail and a
rail-wide skip set deletes the very read that proves the record frozen (round 2's
F-2 argument depends on that read being visible). Two sets, two questions:

| set | question | scope |
|---|---|---|
| SKIP (`MemberSet`) | whose own in-place execution IS the wire moving? | the CHAIN |
| RECORD (`RailValues`) | which SSA names denote a state of this rail? | the RAIL |

**Rule 14 — two forward-extension spellings survive on purpose.** Round 1's
`railRoot` fixpoint (`tryCaseA`) grows a rail forward too, and it already covered
this program: the same C **without** the in-body tainted `if` declined at HEAD while
the version **with** it miscompiled. They are not unified because each is unsound in
the other's job — round 1 needs "ALL incomings" for a CLAIM set and follows an
unmarked in-place `add` because it is about to mark it; round 2/3 needs "SOME
incoming" for an ∃-path staleness witness and must not follow an unmarked add. The
pair is pinned instead of trusted:
`lowering_reject_loop_rail_record_offchain_theta.ll` (round 1) and
`lowering_reject_inloop_rail_record_offchain_theta.ll` (round 2/3) are the same C
program either side of the in-body `if`, and both must decline with the same message.

**The M-C cross-file dependency, now recorded at both ends.** The off-chain
`add`/`xor` exclusion above is sound only because M-C's position-aware deadness pair
(G6 "no data use AFTER the op", G7 "the prior use must be settled",
`ArithLowering.cpp`) refuses in-place exactly when a later read of the pre-op
register exists. Measured: `int r = q + 9; return cq_measure(r)` lowers in place as
`cqrt_addc_i32(%h, 9)`; adding `mark = q` and a later `cq_theta` sends it
out-of-place. `control_swap_inloop_postloop_railop_mc.ll` pins both dispositions —
**weakly, and it says so**: G6 and G7 each refuse that use on their own, so the
fixture only reddens if BOTH are relaxed.

**Fixtures.** Red: `lowering_reject_inloop_rail_record_{offchain_theta,offchain_rz,
offchain_ret,three_hops,offchain_dyn}.ll` and
`lowering_reject_inloop_rail_frozen_gate_first.ll`, plus the round-1 twin
`lowering_reject_loop_rail_record_offchain_theta.ll`. Green:
`control_swap_inloop_postloop_railop_mc.ll`. Both mutations verified with zero
cross-talk over all 1290 fixtures: reverting the record loop to `Members` fails
exactly the five F-3 reds; widening `MemberSet` to the rail fails exactly the
frozen-gate-first fixture.

### 2.9 The iteration-2 staleness guard is already correct — keep it (L4 boundary)
`declineStaleRecordOps` (`OpcodeLowering.cpp:117-198`, position-aware proof
`WireWalk.cpp:138-141`) already fires correctly on a real loop hazard: a pure
tainted producer whose pre-rotation record is read across the **backedge** by a
re-rotated wire (`lowering_reject_stale_record_loop.ll`) — a genuine wrong-unitary,
**not** a false positive. 7.3 must distinguish this from benign per-iteration
recompute: an iteration-local DAG (L4b) recomputed-from-live-source each iteration
is sound; a record that survives a non-diagonal gate **across** the backedge is the
stale-record miscompile and stays declined. The recognizer must not lift this
guard.

### 2.10 Decline-diagnostic partition (Rule 12) — mirror char-for-char
Each decline ships a source-located `DiagnosticInfoUnsupported(DS_Error)` (`!dbg`
attached, `opt` exits at the **first**, so one tainted loop per fixture) with a
mirror-exact negative fixture:

| shape | structural signature (SSA/CFG, pre-mutation) | disposition + message |
|---|---|---|
| Case A — in-place persistent accumulator | classical exit; header phi an in-place self-cycle; value measured/escaped after `L` | **accept** — header-phi collapse (no diagnostic) |
| Case B — iteration-local born-and-dies temp | classical exit; temp's whole DAG within `L`, CLOSED, not measured/escaped | **accept** — in-body per-iteration uncompute (no diagnostic) |
| quantum/measurement-bounded (Q1) | an exiting condition is a live tainted `icmp`/`fcmp` | **permanent decline** — `cq controlled lowering: loop under quantum control` |
| cross-iteration dirty rail (X1) | classical exit; a tainted value carried across iterations on a non-in-place rail | **decline → defer unroll** — `cq loop lowering: loop-carried tainted value crosses iterations` |
| NON-EXITING tainted PHASE `if` in body (Inc 3, bd `8h7d.5`) | flat diamond/if-else, all blocks at one depth of a reducible single-latch loop, no second cycle | **accept** — routed stream emitted in-body, rail phi collapsed by round 2 (no diagnostic) |
| tainted VALUE (method-B) arm in body | as above but `ClassArm == Value` | **decline** — `cq controlled lowering: control flow inside a loop body under quantum control` |
| tainted control in body, any other shape (nest / `switch` / irreducible / multi-latch) | tainted-condition `br`/`select`/`switch` ∈ `L` | **decline** — existing `…nested control flow…` / `…control flow inside a loop body…` (`ControlDetect`/`RegionTreeDetect`) |
| QRAM in body | tainted `load`/`store`/`gep` ∈ `L` | **decline** — existing `kMsgQramLoop` (→ `iw81.13`) |
| `break`/early-`return` in body | a body block exits `L` early under a tainted condition | **decline → defer 7.4** — existing control decline |
| unrecognized in-loop live range (residual net) | any tainted handle live across the backedge not classified (a)/(b) | **decline** — existing `kMsgLoopBackedge` / `kMsgClassicalPhi` |

---

## 3. Deliverables

1. **Loop recognition (`detectLoops`)** — a pure-analysis pass (LoopInfo, before
   mutation) that classifies each natural loop against the §2.2 sound-rolled
   invariant, and a `LoopRegion` representation in `ControlPlan.h` (header/latch/
   preheader/exiting + the (a)/(b) classification of each carried phi). **No ABI.**
2. **Increment 1 — Case A header-phi collapse** (`lowerLoops`, §2.4): lift
   `kMsgClassicalPhi` for the in-place self-cycle, collapse the header phi to its
   persistent rail, lower the body in place. Positive lit fixtures
   `lowering_loop_phase_accum_const.ll` (A1) + `lowering_loop_phase_accum_dynamic.ll`
   (A2, runtime bound) + a multi-handle `lowering_loop_two_handles.ll`. **No ABI.**
3. **Increment 2 — Case B per-iteration in-body uncompute** (§2.5): in-body
   free-point placement; the two loop guards made conditional on an
   affirmatively-recognized iteration-local DAG; loop-scoped dominance reasoning.
   Positive fixture `lowering_loop_iter_local_temp.ll` (B1) + the trace golden
   showing K compute/uncompute pairs. **No ABI** (reuses the `_unc` spine).
4. **Decline fixtures (Rule 12)** — one mirror-exact `RUN: not … | FileCheck` per
   §2.10 row: `lowering_reject_loop_quantum_bound.ll` (Q1),
   `lowering_reject_loop_cross_iter.ll` (X1), plus regression-pins confirming the
   existing control-in-loop / QRAM-in-loop / break-in-loop declines still fire
   unchanged. The existing `lowering_reject_classical_mux_phi_loop.ll` and
   `lowering_uncompute_loop_backedge.ll` are **re-pointed**: their accept-now shapes
   become positives, their genuinely-unrecognized residuals stay declines.
5. **≥1 e2e golden smoke (Rule 16)** in `tests/e2e/` — at minimum a rolled phase
   accumulator (Case A) whose golden trace is **byte-identical** to the
   manually-unrolled equivalent, and a Case-B iteration-local-temp slice — `opt
   -verify` clean, linked (`libcq_templates.a` before `libcq_runtime.a`), golden
   trace diff clean.
6. **Filed follow-on (deferred):** the static-K unroll fallback for cross-iteration
   dirty rails (§2.7), with the dlopen-symbol smoke test for `ScalarEvolution`/
   `UnrollLoop` as its first gate.

---

## 4. Done criteria

- A classically-bounded loop over an in-place persistent accumulator (Case A) lowers
  **rolled**: the loop CFG is preserved, the body emits `cqrt_*` in place, the header
  phi is collapsed to a loop-invariant handle, **zero** measurements inserted, **zero**
  in-body frees — and its golden trace is **byte-identical** to the manually-unrolled
  form (`opt -verify` clean, e2e diff clean).
- An iteration-local born-and-dies temporary (Case B) lowers with a **per-iteration
  in-body** compute/`_unc`/`cqrt_free`, the free provably reached **once per
  iteration** (after last in-iteration use, before the backedge) — never the
  function-scope post-dominator. The trace shows K balanced compute/uncompute pairs.
- A runtime-classical bound (A2) lowers **identically** to a constant bound (A1) —
  no compile-time trip count required.
- Every off-pattern shape declines **loudly**, source-located, with its own
  mirror-exact negative fixture (§2.10): quantum/measurement-bounded (permanent),
  cross-iteration dirty rail (deferred-unroll), tainted control in body, QRAM in
  body, break/early-return in body, and the unrecognized-in-loop residual.
- **No new frozen runtime symbol** is minted (verify against the runtime header).
- **Rule-13 clearance:** the loop recognizer (the §2.2 accept predicate), the Case-A
  header-phi collapse, and **especially** the Case-B in-body free placement + the
  loop-scoped dominance reasoning are cleared by **independent adversarial review**
  with analytic/trace reasoning + reading the actual lowered IR — a green suite alone
  does not clear them (Rule 13; this is a core uncompute-spine change). The review
  explicitly checks: a free never lands at a once-per-function point that runs K
  times; a cross-iteration dirty rail is never mis-accepted as (a)/(b); the
  stale-record-across-backedge guard (§2.9) is not lifted; and a quantum-bounded
  loop is never mis-read as classical (L1).

---

## 5. Out of scope (declines, or other phases)

- **Quantum/measurement-bounded `while`** — permanent decline (§2.6); the genuinely
  unbounded / amplitude-amplification case stays past the freeze (ROADMAP §"Beyond
  the freeze" §2.9).
- **Cross-iteration dirty rails / loop-carried value accumulators** — declined now
  (§2.7); the static-K unroll fallback is a **deferred follow-on**, *not* a permanent
  rejection (a tooling boundary: it is lowerable by unrolling once the SE/UnrollLoop
  dependency + dlopen smoke test are settled).
- **Tainted control inside a loop body** (nested control-in-loop) — reuse the
  existing control declines (§2.8); a future widening, not 7.3.
- **QRAM / tainted-index memory inside a loop** — `iw81.13` (gated on this phase),
  not delivered here.
- **`break` / early `return` inside a loop** — Phase **7.4** (`y05j`), blocked on
  7.3.
- **Static-K unroll as the primary mechanism** — superseded by rolled-in-place
  (§2.1); a possible Phase-9 gate-backend reimposition is flagged, not resolved.
- Any change to the trace-only runtime posture or to classical (untainted) loops
  (compiled exactly as C does).

---

## 6. Risks (the verify-clean ones first)

1. **A Case-B in-body free placed at a once-per-function point that runs K times** —
   freeing the rail on iteration 1, then operating on a freed register on iterations
   2..K (use-after-free) + K−1 double-frees; verify-clean and trace-plausible until
   the trace is diffed. **The central Rule-13 hazard.** Mitigation: the in-body
   insertion point is proven within `L`, after last in-iteration use, before the
   backedge (§2.5); the `FreePoint`/`Uncomputation` loop guards stay as the residual
   net for anything not affirmatively recognized; a probe diffing the trace's
   free-count against the iteration count.
2. **A cross-iteration dirty rail mis-accepted as (a) in-place persistent** — if the
   header-phi self-cycle check accepts a latch-incoming that is actually a *fresh*
   value-op rail (X1) rather than an in-place gate result, the collapse RAUWs a
   wrong/loop-variant handle → silent wrong unitary. Mitigation: the self-cycle peel
   accepts **only** in-place gates (`cqrt_rz`/`ry`/in-place `x`/`cnot`) back to the
   phi itself; a `cq_template_*` (value-op) latch-incoming fails the peel → §2.7
   decline; adversarial probe on `acc=acc+q`, `acc=acc*q`, and an in-place-vs-copy
   permutation.
3. **A quantum-bounded loop mis-read as classical (L1)** — accepting a loop whose
   exit condition is tainted would emit a runtime branch on a qubit. Mitigation: L1
   tests `taint.Tainted.count` on **every** exiting condition; a probe with the
   tainted compare folded/`select`-merged with a classical safety bound (the real
   Q1 `-O1` shape, §1.1) to ensure the taint is still seen.
4. **The stale-record-across-backedge guard (§2.9) silently lifted** — a recognizer
   that treats every in-loop producer as benign per-iteration recompute would
   re-open the `lowering_reject_stale_record_loop.ll` miscompile. Mitigation: the
   guard stays; an iteration-local DAG must be CLOSED *within* the iteration; probe
   the cross-backedge record-read shape.
5. **The header phi left as ill-typed `phi double` with `i32` incomings** — if the
   collapse races `lowerRotations`, the phi survives RAUW with mismatched types →
   verify failure (loud, not silent, but a correctness blocker). Mitigation: the
   collapse is ordered/coordinated with `lowerRotations` (§2.3/§2.4); the phi is
   erased, not retyped-and-left.
6. **`Escaped`/`main`-resident handles bypass the `FreePoint` backedge net**
   (`FreePoint.cpp:82-91`, `:122-123` short-circuit **before** the loop guard at
   `:237-245`) — a loop-body handle that escapes or sits in `main` never reached the
   old loop reject. Mitigation: 7.3's recognizer runs **before** `uncompute` and
   owns the affirmative accept/decline for all loop shapes (incl. escaping/`main`
   handles), so correctness no longer depends on the bypassable `FreePoint` net.
7. **dlopen symbol resolution for the deferred unroll fallback** — `ScalarEvolution`/
   `UnrollLoop` are not exercised by the no-link MODULE plugin today; a missing
   symbol surfaces as a late dlopen/lazy-bind crash, not a link error. Mitigation:
   the follow-on's **first gate** is a minimal dlopen smoke test; LoopInfo/
   DominatorTree (all 7.3 needs) are proven-safe.

---

## 7. Increments (each red → green → clear, Rule 12/13)

1. **Loop recognition + Case A header-phi collapse** — `detectLoops` (the §2.2
   predicate) + the in-place self-cycle collapse (§2.4). Flip A1/A2 from
   `kMsgClassicalPhi` decline → green; add the Q1 quantum-bounded decline partition
   (§2.6) and the X1 cross-iteration decline (§2.7). (No ABI.)
2. **Case B per-iteration in-body uncompute** — the spine surgery (§2.5): in-body
   free placement, the two loop guards made conditional, loop-scoped dominance.
   Flip B1 → green; the Case-B e2e golden. (No ABI; reuses `_unc`.) **This is the
   core control/uncompute change** — it clears independent adversarial Rule-13
   review before commit (Risk 1).
3. **Decline-diagnostic partition + fixtures** — the §2.10 mirror-exact negatives;
   re-point the existing loop-reject fixtures (accept-now shapes → positives,
   residuals → declines).

> Increments 1–3 may interleave at the fixture level, but **the loop recognizer, the
> Case-A collapse, and the Case-B in-body uncompute must each clear independent
> adversarial Rule-13 review before commit** — 7.3 is a core uncompute-spine change,
> and the verify-clean hazards (Risks 1–4) must be confirmed discharged, not
> assumed. The deferred static-K unroll fallback (§2.7, Deliverable 6) is **not**
> part of this phase's done-criteria.
