# Phase 7.2 PRD — Controlled function-`return` (reconverging early-exit) (DRAFT)

> **Status:** DRAFT, written at the start of Phase 7.2 (2026-06-22) to
> memorialize the design decisions resolved in PRD-discovery discussion (owner
> session 2026-06-22, recorded in `bd memories 7-2-clang-reconverges-controlled-return`).
> Does not duplicate [`ROADMAP.md`](../../../ROADMAP.md) §"Phase 7 — 7.2" or
> [`docs/design/rssa-swap-control/SCOPING.md`](../../../docs/design/rssa-swap-control/SCOPING.md)
> §4; captures the 7.2-specific decisions, deliverables, and done criteria.
> Covers controlled `return` **and** its non-reconverging `abort`/`exit` member
> (owner decision: both in this increment).

---

## 0. Invariant recap (not new — the ground 7.2 stands on)

- **Over-declining is safe; over-accepting is a silent miscompile** (Prime
  Directive). Every new accept-predicate ships with a decline fixture +
  adversarial probe (Rule 12).
- **Verify-clean ≠ correct** (Rule 2). 7.2 is a **core control change** — it
  touches `ControlDetect` and the dispatch into `SwapRouteEmit` / `FreePoint` /
  the uncompute spine, exactly the modules where every silent miscompile in this
  project's history has lived. It is cleared by independent adversarial Rule-13
  review, **not** by a green suite (Rule 13).
- **Taint is the only Q/C boundary** (Rule 3). 7.2 adds **no** taint source and
  **no** new opcode taint rule; `@cq_theta` stays the sole source, `@cq_measure`
  the sole sink. 7.2 changes *which CFG shapes* taint-driven control is lowered
  on, not how taint flows.
- **Coherent-first; never insert a measurement** (Rule 5). The merged return
  value is produced by a pure unitary insertion; the emitter adds **zero**
  measurements (pinned today by `control_swap_select_ret.ll`).
- **Free only a proven-`|0⟩` rail** (Rule 6); **no-cloning** (Rule 8). 7.2 frees
  nothing new — it reuses the emitters' existing rail-cleanup discipline.
- **Method matches arm class** (Rule 7). Phase answers stay **in place** and are
  flag-stripped (`icmp_inv`); value/basis answers are copied. A `CNOT`/XOR-copy
  of a **phase** dephases it (verified P0 0.585 → 0.500,
  `bd memories rz-diag-flag-strip-invariant`) — so a phase-class value reaching a
  data-copy path is a **loud decline**, never a silent copy.
- **`clang -O1` inverts branch polarity** (Rule 9): the gate arm is often the
  **false** successor; control on `¬flag` via the self-inverse `cqrt_x` bracket.
  7.2 inherits the proven brackets from the reused emitters; it does not re-derive
  them.
- **`emit_inverse` is a closed adjoint dispatch table** ("feature → spine").
  Because 7.2 **reuses** the existing emitters, the adjoint rules they need are
  **already registered** (`cqrt_cswap` is self-adjoint, `EmitInverse.cpp:47-48`;
  the `cq_template_*_unc` forms exist). 7.2 introduces **no new reversible
  construct** that needs a new adjoint rule — the one new emission (the `abort`
  park) is built from `cqrt_cswap`, already invertible.

---

## 1. Scope

7.2 lifts the permanent reject for a tainted-condition `if` whose arm exits early
via `return` (and the `abort`/`exit` non-reconverging sink), **for the bounded +
reconverging (D4) subset only**. A genuinely non-reconverging *value* exit stays
physics-rejected **forever**; the only non-reconverging shape 7.2 accepts is the
**no-value `abort`/`exit`** member, which terminates.

**The load-bearing empirical finding (verified 2026-06-22, Rule 11).** Because the
pass works on the **IR clang gives us**, not on C source structure, the shape that
actually arrives matters more than the C: `clang -O1` (mem2reg/SROA/SimplifyCFG)
reconverges essentially **every** straight-line tainted early-return into a
**single `ret` fed by a merge-φ or `select`** — even for complex non-inlinable or
external call arms (SimplifyCFG sinks the common `ret`). The
SCOPING §4 "multiple `ret` terminators / per-site return register" shape almost
never appears. Recursion becomes a **loop** at `-O1` (7.3), not a call cycle. The
genuine non-reconverging survivors are narrow: `abort`/`exit` (→ `unreachable`)
and tree/mutual recursion (a call cycle → specializer reject, not 7.2).

**Consequence — what 7.2 actually is: detection/classification widening. The
conditional routing is *unchanged* (owner decision 2026-06-22).** 7.2 recognizes
the reconverging diamonds clang produces and **dispatches each arm to the existing
emitter**:

| arm kind in the tainted-condition diamond | emitter reused **as-is** |
|---|---|
| transforms a shared base (`if(q){p=op(p)}…`) | **4.2** two-rail `cqrt_cswap` swap-route (`SwapRouteEmit`, `control_swap_value_ifelse.ll`) |
| select-folded / two independent values / constant data-mux | **4.4 / 4.5** controlled-XOR-copy into one out-rail (`SelectMergeEmit` / `SwitchDataMuxEmit`) |
| append-only I/O (`printf`/`putchar`) | **7.6** `cqrt_tape_write_<W>_controlled` (`IOSinkLowering`) |
| `abort`/`exit`/noreturn | **park cascade** (the one genuinely-new emission) |

A **mixed-kind diamond** is allowed (owner decision): dispatch **arm-by-arm**.

**Genuinely-new work (narrow):**
1. Widen region detection to accept the reconverging early-return diamonds that
   currently hit the generic decline — chiefly the **exp2 gap** (a `br`-diamond
   with two **independent** computed value arms and no shared base).
2. The **both-arm I/O** generalization (`if(q)printf(a);else printf(b);`), folded
   into 7.2 (owner decision).
3. The **`abort`/`exit` park cascade** (mint flag → `cqrt_cswap` live regs into a
   graveyard → downstream runs uncontrolled → record flag → truncate tape at
   inspection).
4. A **dedicated decline diagnostic** partitioning the dispositions, replacing
   today's generic `"control flow under quantum control"` catch-all
   (`ControlDetect.cpp:172`).

**No new frozen ABI.** Reuses `cqrt_cswap` / `cqrt_copy_<W>(_controlled)` /
`cqrt_tape_write_<W>(_controlled)` / `emit_inverse` (ROADMAP:1105). One caveat:
§2.8.

---

## 2. Design decisions

### 2.1 7.2 changes detection + dispatch, never the routing (owner decision)
The proven emitters do the routing; 7.2 classifies a diamond's arms and dispatches
each to the right existing emitter. **Reuse the 4.2 two-rail `cqrt_cswap`
swap-route exactly as shipped** (owner decision: do *not* substitute the
one-extra-register / false-arm-in-place form floated in discussion — it is a
different construction; the shipped two-rail emitter routes the base into a fresh
rail per arm with `p` as a pure router, `control_swap_value_ifelse.ll:41-81`).
This keeps 7.2 out of the routing core and concentrates the change in
`recoverRegion` / arm classification + an arm-by-arm dispatcher.

### 2.2 Target the single-`ret`-merge shape; reserve the multi-park cascade for `abort`
Because `-O1` reconverges to one exit, the accepted reconverging shape is a
**single output register** fed by the diamond's merge — exactly what 4.4's one
out-rail and 4.2's single copy-out already produce. **This supersedes SCOPING §4's
per-site return register / multi-register exit-priority cascade for the
reconverging case** (the user's "single register the conditional returns are
applied on"). The multi-register park cascade survives **only** as the
`abort`/`exit` mechanism (§2.8), where the parked registers are a *graveyard*
inspected after termination, never selected back.

### 2.3 The `exp2` gap → the data-mux emitter, not 4.2
> **[Correction — 2026-06-22 persisting-`ret` review.]** The example below
> (`if(q>5) return q+1; return 3*q+7;`) does **not** decline today: `clang -O1`
> folds it to a `select` and the existing 4.4 `SelectMergeEmit` path already
> **accepts** it (verified, `opt` exit 0). The genuinely-new `br`-diamond surface
> is **narrow and optimizer-cost-fragile** — it survives as a `br`-diamond only
> when an arm exceeds clang's branch-speculation cost budget or carries a
> non-escaping side effect (a `q`-consuming call arm taint-escape-declines
> regardless of return shape). Deliverable-1 fixtures (§3) must therefore use a
> shape **verified to survive as a `br`-diamond at `-O1`**, not one that
> folds-to-`select` (already handled) or taint-escapes (declined upstream). The
> data-mux disposition below remains physically correct for the surviving shape.

The (formerly described as currently-declining) core case is a `br`-diamond whose
merge-φ has **two independent computed value arms with no shared base** (e.g.
`if(q>5) return q+1; return 3*q+7;` *only* on the rare path where clang keeps the
diamond instead of folding to `select`). It does **not** fit 4.2's route-a-base model (there is no
incoming base to `cqrt_cswap`). **Decision:** detection recognizes this shape and
routes it to the **data-mux / controlled-XOR-copy** emitter (the 4.4/4.5 path,
generalized from a literal `select`/`switch` operand to a `br`-diamond with
computed arm values): compute each arm value on a fresh rail, controlled-XOR-copy
the active one into the single `|0⟩` output rail, `icmp_inv`-strip the flag,
uncompute the arm scratch via the Phase-5 spine, free, escape `out`. No new
emitter — a new **detection→data-mux adapter**.

### 2.4 Mixed-kind diamonds dispatch arm-by-arm (owner decision)
One diamond, one flag, but each arm-effect is routed to its own coherent
mechanism: **value → 4.2 or 4.4; append-only I/O → 7.6 controlled tape write;
`abort`/`exit` → park.** An arm may carry more than one effect (e.g. a `printf`
*and* a returned value) — each effect is lowered by its respective emitter under
the same minted flag.

### 2.5 Both-arm I/O generalization is in 7.2
7.6 Inc 2 (`lowerControlledIOSinks`, `IOSinkLowering.cpp`) recognizes only the
**single-arm** void I/O diamond (`ArmIsSoleSink`). `if(q)printf(a);else
printf(b);` (both arms I/O) declines today. **Decision:** generalize the I/O
recognizer to both arms within 7.2's diamond classifier — each arm becomes a
`cqrt_tape_write_<W>_controlled` under its arm's flag polarity (entry always
appended, content committed under the flag; the tape length stays
classical/deterministic — never a superposition over "N vs N+1 entries"). Reuses
the shipped Inc-2 mechanics and `OutputRails` keep-discipline unchanged.

### 2.6 Return values are basis/data only (owner decision) — discharges hazard (ii)
ROADMAP hazard (ii) "coherent return *values*" is **resolved by scope, not by new
proof**: a returned value that carries a relative **phase** is **not** in scope —
such an answer stays on the existing **in-place flag-strip** escape path
(`control_swap_ifelse_escape.ll`: phase arm, `q` escapes coherent, **never
copied**). 7.2 accepts only **basis/data** return values, lowered by the existing
copy mechanisms (`cqrt_copy_<W>(_controlled)` / `cqrt_cswap`). **A phase-class
value that would reach a data-copy path is a loud decline** (Rule 7) — never a
silent XOR-copy that dephases. This is an arm-class guard at classification time,
reusing the existing phase-vs-value split in `ArmClassify`.

**Deferred interaction (2026-06-22 review).** A phase-class value escaping via
`ret` **beside an `abort`/park arm** (`p = cq_phi(q); if(q>5) return p; abort();`)
is an **unproven** park-vs-dephasing interaction: whether the §2.8 `cqrt_cswap`
park of the live registers preserves the relative phase on the surviving arm's
escaping `ret` is **not yet shown**. 7.2 therefore **conservatively declines** this
case (over-decline is safe; Prime Directive) rather than asserting an outcome;
accept-vs-permanent-decline is resolved under Rule-13 (§2.11 C-iii). Do **not**
silently route it onto the in-place phase-escape path until the park interaction is
proven coherence-preserving.

### 2.7 Single escaping handle — discharges hazard (iii)
ROADMAP hazard (iii) is FreePoint's whole-function `ret`-as-Escaped assumption
(`DagTraversal.cpp:146-147`, `FreePoint.cpp:82-91`) vs. *multiple* parked exit
registers. In 7.2's reconverging scope there is **exactly one** escaping handle —
the single merged output rail (§2.2) — which **is** the existing single-`ret`
Escaped case FreePoint already handles correctly (pinned by
`lowering_uncompute_escape_return.ll`). Multiple parked registers arise **only**
in the `abort` cascade, where the arms end in `unreachable` (**not** `ret`), so
they never reach FreePoint's `ret`-as-Escaped path at all (§2.8). Hazard (iii)
therefore does **not** arise in either branch of 7.2's accept set.

### 2.8 `abort`/`exit` — the park cascade (the one new emission)
A noreturn sink (`@abort`/`@exit`/`__assert_fail`/`@llvm.trap`; `-O1` shape: a
tainted-condition `br` into an arm of `tail call void @abort()` + `unreachable`,
**no merge φ** → non-reconverging) joins the park cascade as its **no-value-select
member** (`bd memories abort-exit-park-cascade`). Mechanism: mint the abort flag,
`cqrt_cswap` the live registers into a graveyard under the flag (pre-abort state
**preserved + inspectable**), let downstream run **uncontrolled**, record the flag
→ **truncate the output tape** (7.6) at the abort point at inspection. **Why this
is both correct and cheap, and why it sidesteps the controlled-`return` hazards:**
abort **terminates**, so there is **no coherent downstream** → the
branch-correlated tail-garbage of hazard (i) is **never observed and never
dephases** (harmless — the same cost already accepted from swap-route arms). Do
**not** gate every downstream op on `¬flag` (drastically too costly and
pointless); that is reserved for the *non-terminating* conditional-output case
(7.6 Tier 0). **Freeze note (owner: reopening is acceptable):** truncation is a
backend/inspection concern (ROADMAP:937/943) and is intended to reuse
`cqrt_tape_write_i1` (record the abort flag as a kept tape entry) + a
truncate-at-inspection convention — **no new frozen symbol**. If implementation
proves a dedicated on-tape truncate/marker symbol is genuinely needed, the owner
has approved reopening the (already-frozen) 7.6 tape ABI for it; flag it loudly in
the Rule-13 clearance.

### 2.9 Hazard (i) — tail-garbage reverse-play, discharged by reuse + abort-terminates
ROADMAP hazard (i) was a property of the *multi-park-cascade-for-everything*
model: "remaining work runs uncontrolled, leaving branch-correlated garbage that
must be reverse-played." 7.2 does not use that model for reconverging returns —
the merge **fully reconverges** and the reused emitters (4.2 R-dagger; 4.4
`icmp_inv` strip) clean up **region-locally**, exactly as already shipped and
Rule-13-cleared. There is no unbounded post-park function tail in the reconverging
case. In the `abort` case the tail-garbage exists but is **harmless** (§2.8,
abort terminates). Hazard (i) therefore reduces to "reuse the proven region-local
reverse-play" — no new control-aware adjoint, no change to the spine.

### 2.10 Disposition matrix + dedicated decline diagnostics (Rule 12) — revised by the 2026-06-22 persisting-`ret` review
**Empirical correction (15+ adversarial `-O1` probes — see the tracking bd
issue).** `clang -O1` reconverges **every mergeable value early-return** to a single
exit (`select` or one merge-φ): confirmed across if-returns, switch-returns (all 5
variants collapsed to one `ret`, incl. side-effect and fall-through/`break`),
nested-if, struct/sret, and non-sinkable side-effect arms. A `ret` therefore
**persists in a conditional arm only for a *genuine* non-reconvergence reason** —
it is **never** a mergeable value-mux the pass would have to merge itself. The
dispositions are keyed on **which reason**, decided by the structural predicate in
§2.11, evaluated by **SSA identity before any mutation** (Rule 9). Each replaces
the generic `"control flow under quantum control"` catch-all
(`ControlDetect.cpp:172-173`) with a distinct, source-located message + a
mirror-exact negative fixture:

| shape (post-`-O1`) | structural signature (§2.11) | disposition + message |
|---|---|---|
| reconverging value/data diamond/switch | every arm `br`s to a common merge with a `soleMergePhi`; merge value is **basis/data** | **accept** — reused 4.2/4.4/4.5 emitter (no diagnostic) |
| recognized noreturn sink arm + **value sibling** | sink arm = `@abort`/`@exit`/`@_exit`/`@__assert_fail`/`@llvm.trap`/`@llvm.ubsantrap`/`noreturn` call + `unreachable`, **no value, no merge φ**; sibling is the ordinary uncontrolled `ret` | **accept** — §2.8 park (no diagnostic) |
| persisting **value** `ret` in an arm, not a noreturn sink (`musttail` return; two un-merged value rets) | arm ends in `ret` / `musttail call;ret` → `uncondSucc==null`, no merge φ | **decline** — `"non-reconverging value exit under quantum control"` |
| **phase-class** value escaping beside an exit (incl. an abort sibling) | escaping `ret` operand is Rz/phase-tainted (`cq_phi` lineage) | **decline (conservative)** — `"phase-class value escaping under quantum control"` (§2.6 deferred, §2.11 C-iii) |
| infinite-loop / non-`abort` divergence arm + value sibling | divergent arm = self-`br` loop, **no** recognized noreturn sink | **decline → defer 7.3/7.4** — `"loop under quantum control"` |
| §3c clobber | an arm value-overwrites a register the condition transitively reads | **permanent decline** — `"arm rewrites a condition operand under quantum control"` (`swap_route_reject_clobber.ll`) |
| `cq_measure` / `store` / impure non-output call in a tainted arm | the `declineTaintEscapes` family | **decline** — existing escape messages (runs **before** ControlDetect) |
| non-i32 / sret value exit | `declineTaintEscapes` width / `store` guard | **decline** — `kMsgNonI32Return` / `kMsgStore` (runs **before** ControlDetect; 7.2 must **not** double-own — i32 is the only width reaching the recognizer) |

**Reframing of "non-reconverging value exit" (corrects the §5/§2.10-disp-2
over-statement).** A persisting value `ret` that reaches the recognizer (not a
noreturn sink, not a phase, not an escape) declines because **clang did not
reconverge it and 7.2 deliberately does not synthesize the merge** (§2.11 A) — a
*tooling / canonicalization* boundary, **reopenable** if a real-world `-O1`
survivor is found, **not** the information-theoretic impossibility "rejected
forever." Empirically the only such survivors are `musttail` (the `ret` is glued to
a tail call by language rule, and is additionally a conditional tail-escape) and
two un-merged value rets, which non-`musttail` code essentially never produces at
`-O1`. This honors the user's correct intuition (a mergeable value-`ret` is the
*same program* as the accepted merge form) **without** an unsafe CFG-rewrite
prepass (§2.11 A rationale).

### 2.11 The structural accept + park predicate (resolves the §6 Risk-2 boundary; new)
The 2026-06-22 review found §6 Risk-2's mitigation ("reconvergence proven by SSA /
post-dominator identity") had **no implementing analysis** (there is **no**
`PostDominatorTree` in the detection path), and that several real `-O1` shapes
matched **two** dispositions at once — `abort`+value matched both §2.8 (accept) and
§2.10-disp-2 (decline); the *same* source `if(f) return foo1(); return foo2();`
matched deliverable-1 **accept** when plain but the **decline** class when written
`musttail`. 7.2 therefore pins **explicit, mutually-exclusive** predicates,
evaluated on SSA identity **before any mutation** (Rule 9), reusing the existing
`uncondSucc` / `soleMergePhi` machinery — **no new pass, no CFG rewrite**:

**(A) Value-reconverging → ACCEPT (reuse 4.2/4.4/4.5).** ALL of:
1. every arm block is single-pred(`Pred`) and ends in an **unconditional `br`** to
   one common merge `M` (`uncondSucc(arm) == M`) — **no** arm ends in `ret`,
   `unreachable`, `switch`, or a conditional `br`;
2. `soleMergePhi(M)` exists; `M`'s terminator is **unconstrained** (`ret %φ` /
   `br %cont` / `measure;ret`) — `flattenRegion` is terminator-agnostic (**verified**:
   `control_swap_ifelse_escape.ll`'s merge ends in `ret i32 %qm` and flattens green);
3. the merged value is **basis/data-class**, not phase (else (C-iii));
4. no arm clobbers a condition operand (§3c).
This is *exactly* today's `recoverRegion` shape test, which **already** declines a
`ret`-terminated arm (`uncondSucc==null`). **Rationale for not auto-merging
persisting rets:** the accept set is precisely "what `clang -O1` already
tail-merged for us," and 7.2 adds **no** ret-merging of its own — a synthesize-the-
merge prepass would insert blocks / RAUW **before** taint analysis, violating
"detection is pure analysis by SSA identity, before any mutation" (the merge-block
use-after-free family). Empirically there is no surviving mergeable-value
population to serve.

**(B) Noreturn-sink park → ACCEPT (§2.8), structurally distinct from a value exit.**
Exactly one arm is a **recognized noreturn terminator sink** — a `call`/`invoke` to
{`@abort`,`@exit`,`@_exit`,`@__assert_fail`,`@llvm.trap`,`@llvm.ubsantrap`, or any
`noreturn`-attributed callee} immediately followed by `unreachable`, **carrying no
returned value and no merge φ** — and the sibling is the ordinary uncontrolled
remainder (which may itself `ret` a basis/data value). **Discriminator that kills
the §2.8↔§2.10 collision:** the sink arm has **nothing to merge** (no value, ends
in `unreachable`), so `abort`+value is a **park**, *never* a "non-reconverging value
exit"; the sibling's `ret` is the normal return, not a second mux arm.

**(C) Everything else → DECLINE** per the §2.10 matrix. An arm ending in `ret` that
is **not** a (B) sink is **never** silently folded into an (A) merge — (A) requires
an unconditional `br`, so the Risk-2 mis-accept **cannot occur structurally**.
Named rows: (C-i) `musttail` / un-merged value rets; (C-ii) non-`abort` divergence
(infinite loop) → defer 7.3/7.4; (C-iii) a phase-class value escaping beside an
exit → **conservative** decline pending the §2.6 park-coherence proof.

**Owner decisions to confirm (each flips a disposition):** (i) noreturn-sink +
value sibling = **park-accept**, not decline; (ii) `musttail` / un-merged value
rets = **decline** (reopenable tooling boundary), 7.2 does **not** synthesize a
merge; (iii) a phase value escaping beside a park arm = **conservative decline**
(unproven park coherence, §2.6); (iv) non-`abort` divergence = **defer to 7.3/7.4**,
not a park member.

---

## 3. Deliverables

1. **Reconverging value-merge detection** — widen `recoverRegion` /
   arm-classification to accept the early-return reconverging diamond, including
   the `exp2` two-independent-computed-arm shape, dispatched to the data-mux
   emitter (§2.3) and the shared-base shape dispatched to the reused 4.2 route
   (§2.1). Positive lit fixtures (single early return; two early returns kept as a
   diamond; `if(f)return foo1();return foo2();` reconverged call-result merge) +
   the matching negative decline fixtures.
2. **Mixed-kind + both-arm I/O dispatch** — arm-by-arm dispatcher (§2.4); both-arm
   I/O generalization of `lowerControlledIOSinks` (§2.5). Positive fixture for a
   value+I/O mixed diamond and an `if/else`-both-`printf` diamond.
3. **`abort`/`exit` park cascade** (§2.8) — flag mint, `cqrt_cswap` graveyard
   under the flag, uncontrolled downstream, flag recorded on the tape, truncate
   hook. Positive fixture (`if(q)abort();`) + the trace golden showing the parked
   graveyard and the recorded flag.
4. **Dedicated decline diagnostic + fixtures** (§2.10) — one mirror-exact
   `RUN: not … | FileCheck` per disposition (non-reconverging value exit, §3c
   clobber, measurement-under-control, opaque escape).
5. **≥1 e2e golden smoke** (Rule 16) exercising, at minimum: a reconverging
   controlled early-return (value merge), a mixed value+I/O diamond, and a
   controlled `abort` — `opt -verify` clean, linked, golden trace diff clean.

---

## 4. Done criteria

- Programs with a tainted-condition early-`return` that clang reconverges to a
  single exit lower to the expected reused-emitter sequence (4.2 cswap route /
  4.4 XOR-copy data-mux / 7.6 tape, per arm kind) — `opt -verify` clean, golden
  e2e trace diffs clean.
- A controlled `abort`/`exit` lowers to the park cascade with the pre-abort state
  preserved in the graveyard and the abort flag recorded on the tape.
- Every off-pattern / irreversible shape declines **loudly** with its own
  source-located diagnostic (§2.10): a non-reconverging value exit, a §3c clobber,
  a measurement under control, an opaque escape — each with a mirror-exact
  negative fixture (Rule 12).
- **A phase-class return value reaching a data-copy path declines** (Rule 7
  guard) — pinned by an adversarial probe, since a silent XOR-copy of a phase is
  verify-clean and trace-plausible.
- **No new frozen runtime symbol** is minted (verify against the runtime header);
  if §2.8 forces one, it is called out and cleared as a freeze-scope change.
- **Rule-13 clearance:** the detection widening, the arm-by-arm dispatcher, and
  the `abort` park are cleared by independent adversarial review with
  analytic/trace reasoning + reading the actual lowered IR — a green suite alone
  does not clear them (Rule 13; this is a core control change). The review
  explicitly checks the three ROADMAP hazards are discharged as argued in
  §2.6/§2.7/§2.9 and not merely hidden.

---

## 5. Out of scope (declines, or other phases)

- **Non-reconverging *value* exits** — declined (only the no-value noreturn-sink
  member is accepted, §2.11 B). **Not** "physics-rejected forever": a persisting
  value `ret` is the *same program* as the accepted merge form, so this is a
  *tooling / canonicalization* boundary (clang did not reconverge it and 7.2 does
  not synthesize the merge — §2.11 A), **reopenable** if a real `-O1` survivor
  appears. Empirically the only survivors are `musttail` and un-merged value rets,
  which non-`musttail` code essentially never produces at `-O1`.
- **Phase-carrying / superposition return values** — not returned; a phase escape
  stays on the in-place flag-strip path (§2.6); a phase value into a data path
  declines.
- **§3c clobber** — an arm rewriting a register the condition reads (permanent,
  information-theoretic).
- **Recursion as a call cycle** (tree/mutual) — specializer reject. Recursion that
  `-O1` turns into a **loop** is Phase **7.3**; an early-`return` inside an
  unrolled loop is `break` = Phase **7.4** (the 7.2 → 7.3 → 7.4 dependency chain,
  owner-accepted).
- **The callee-under-quantum-control axis** (Phase 6 clone-on-taint, 6.5
  classical-call-arm, a loop in a callee = 7.3, an external-body callee =
  taint-escape) — **separate** from the return-merge *shape*; `if(f)return
  foo1();…` lowers its return structure here but its callees are handled by 6.x /
  7.3.
- Any change to the conditional **routing** (reused unchanged) or the trace-only
  runtime posture.

---

## 6. Risks (the verify-clean ones first)

1. **A phase-class value silently XOR-copied** (Rule 7 dephasing, P0 0.585 →
   0.500) — verify-clean, trace-plausible, no backstop. Mitigation: the §2.6
   arm-class guard declines a phase value into any data path; adversarial probe
   that a phase escape is *never* routed to `cqrt_copy`.
2. **A non-reconverging exit mis-classified as reconverging** — accepting a shape
   whose tail does not actually rejoin the single exit would emit an unbalanced
   route (verify-clean). Mitigation **(revised — there is NO `PostDominatorTree` in
   detection; the original "post-dominator identity" mitigation was unbacked)**:
   the §2.11 A accept predicate is **purely structural** — every arm must end in an
   **unconditional `br`** to a `soleMergePhi` merge, which a `ret`/`unreachable`-
   terminated arm fails (`uncondSucc==null`), so a non-reconverging exit **cannot
   structurally match** the accept path. The §2.10 decline is the default;
   over-decline is safe.
3. **A mixed-kind arm mis-dispatched** (e.g. an I/O arm fed to the value-merge, or
   an impure non-output call treated as a pure call-arm) — Mitigation: the
   arm-by-arm classifier reuses the existing recognizers' guards verbatim
   (`isOutputSink` exact-name match; the 6.5 purity gate); anything unrecognized
   declines.
4. **`abort` park leaving an entangled live register freed dirty** — Mitigation:
   abort terminates (no downstream free of the graveyard); the graveyard is
   *kept* (escaped-class, like an output rail), never `cqrt_free`'d (Rule 6).
5. **FreePoint mis-owning the merged handle** — Mitigation: the single escaping
   output rail is the existing `ret`-as-Escaped case (§2.7); pinned by the
   reused-escape fixtures; no new FreePoint rail class is introduced.
6. **Freeze reopen for an `abort` truncate symbol** (§2.8) — a permanent ABI
   addition if needed post-7.6-freeze. Mitigation: default to reusing
   `cqrt_tape_write_i1` + inspection; only reopen with an explicit Rule-13 call-out.

---

## 7. Increments (each red → green → clear, Rule 12/13)

Suggested order — lowest-risk detection reuse first, the genuinely-new `abort`
emission and the diagnostic partition last:

1. **Reconverging value-merge detection + dispatch** — accept the early-return
   diamond, route the `exp2` two-arm shape to the data-mux emitter and the
   shared-base shape to the reused 4.2 route. Red fixture (today's decline) →
   green. (No ABI; reuses emitters.)
2. **Mixed-kind + both-arm I/O dispatch** — arm-by-arm dispatcher + both-arm I/O
   generalization. (No ABI.)
3. **`abort`/`exit` park cascade** — the one new emission; truncate hook on the
   7.6 tape. (No ABI unless §2.8 forces a symbol — **Rule-13 / freeze call-out**.)
4. **Decline-diagnostic partition** — replace the catch-all with the §2.10
   distinct messages + one mirror-exact negative fixture each.

> Increments 1–4 may interleave at the fixture level, but **the detection widening,
> the arm-by-arm dispatcher, and the `abort` park must each clear independent
> adversarial Rule-13 review before commit** — 7.2 is a core control change, and
> the three ROADMAP hazards are discharged *by scope* (§2.6/§2.7/§2.9), which the
> review must confirm rather than assume.
