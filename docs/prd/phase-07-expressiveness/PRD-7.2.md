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
The currently-declining core case is a `br`-diamond whose merge-φ has **two
independent computed value arms with no shared base** (e.g.
`if(q>5) return q+1; return 3*q+7;` when clang keeps the diamond instead of
folding to `select`). It does **not** fit 4.2's route-a-base model (there is no
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

### 2.10 Dedicated decline diagnostic — partition the dispositions (Rule 12)
Replace the generic `"control flow under quantum control"` catch-all
(`ControlDetect.cpp:172-173`) for early-exit shapes with **distinct, source-located
messages** for each disposition, so each ships a mirror-exact negative fixture:
1. **accept** — reconverging D4 (no diagnostic).
2. **permanent reject — non-reconverging *value* exit** (a value-returning arm
   that cannot rejoin the single exit).
3. **permanent reject — §3c clobber** (an arm value-overwrites a quantum register
   the branch condition transitively reads — non-injective, `icmp_inv` cannot
   recompute; `swap_route_reject_clobber.ll`).
4. **permanent reject — measurement / escape under control** (`cq_measure` in a
   tainted arm; `store` to untracked memory; an impure non-output external call —
   the `declineTaintEscapes` family).
5. **accept — `abort`/`exit` park** (§2.8; no diagnostic).

Width-dependent fall-through must be reconciled: a non-i32 tainted early-exit
`ret` is already declined earlier by `declineTaintEscapes`'s `kMsgNonI32Return`
(`TaintPropagation.cpp`, runs before `ControlDetect`); 7.2 must not double-own
that decline — i32-width is the only width that reaches the 7.2 recognizer.

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

- **Non-reconverging *value* exits** — physics-rejected forever (only the
  no-value `abort`/`exit` member is accepted).
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
   route (verify-clean). Mitigation: reconvergence proven by SSA/post-dominator
   identity **before** mutation (Rule 9); the dedicated decline (§2.10) is the
   default; over-decline is safe.
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
