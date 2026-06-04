# Phase 5 PRD — IR pass: per-op uncomputation

Phase-specific design decisions, scope, and done criteria for
**productionizing** the prototype's `cq-uncompute` slice past the
`cqrt_free`-placeholder stage: emitting the adjoint of each tainted
**data** handle's gate chain at its SSA last-use point, then freeing the
register. This is a lean PRD — it memorializes the decisions resolved in
PRD-discovery so the rationale survives between sessions; the
implementation plan (module layout, fixture generation, commit shape)
lands next session as `IMPLEMENTATION.md` alongside this file.

Companion documents:
- [`ROADMAP.md`](../../../ROADMAP.md) §Phase 5 — phase scope and place in
  the sequence; the loop-extension forward reference.
- [`docs/backend.md`](../../backend.md) §9 (last-use computation, adjoint
  emission, escape detection), §10 (the `emit_inverse` rule, the
  forward + controlled-forward commitment, manual inversion).
- [`docs/prd/phase-04-controlled-form/PRD.md`](../phase-04-controlled-form/PRD.md)
  §2.9 — the Phase 4 / Phase 5 seam, pre-declared there: Phase 4 brackets
  its own control scratch so it "hands Phase 5 a region whose control
  ancillas are already balanced."
- [`docs/prd/phase-04-controlled-form/MISSING_CASES.md`](../phase-04-controlled-form/MISSING_CASES.md)
  — the deferred gaps that touch uncomputation (MUX-EXCH non-selected
  source = Phase 4 control scratch, *not* Phase 5; shared-merge UAF).
- [`docs/quantum-classical-handling.md`](../../quantum-classical-handling.md)
  — taint as the Q/C boundary; measurement as the sole sink.
- The Phase 5 prototype — `archive/prototype/cq_pass.cpp` (the
  `cq-uncompute` slice: `PostDominatorTree`-driven last-use + `ReturnInst`
  escape, validated on `input_phase5_branch.ll`).

---

## Status (2026-06-04)

| Item | State |
|---|---|
| PRD (this document) | ✍️ **DRAFT** — decisions resolved in PRD-discovery; written at phase start per the [PRD convention](../README.md) |
| `IMPLEMENTATION.md` | ⏳ next session |
| Code | ⏳ not started |

Phase 4 is complete (controlled-form lowering, incl. all in-region
control-scratch uncomputation), so the seam this phase builds on is in
place. Phase 5 is the first uncomputation work that owns **data** handles.

---

## 0. Invariant recap (not new — the ground Phase 5 stands on)

Carried from Phases 2–4, restated so the decisions below are unambiguous:

> **A quantum register reference is always an `i32` handle.** The runtime
> owns the rich state behind it ([`backend.md`](../../backend.md) §11.1).

> **Taint is the only Q/C boundary** (ROADMAP design principle 1). A value
> is quantum iff transitively derived from a `@cq_theta_*` return;
> `@cq_measure_*` is the sole sink.

> **Compile-time, per-op adjoints** (ROADMAP design principle 4). Adjoints
> are emitted at each tainted handle's SSA last-use point via dominator
> analysis — no runtime tracking, no whole-call Bennett wrap (that is
> reserved for Phase 6 §7.2 clone synthesis only).

> **Forward + controlled-forward only** (ROADMAP design principle 7;
> [`backend.md`](../../backend.md) §10.2). The runtime declares forward and
> controlled-forward templates; the inverse is *derived* by `emit_inverse`.
> The `_inv` / `_controlled_inv` surface is already declared with **zero
> gaps** (Phase 3/4 autogen) — Phase 5 needs **no new runtime symbols**.

---

## 1. Scope

**In scope.** Emit the adjoint-plus-free of every tainted **data** handle
at its last-use point, productionizing the prototype slice:

- **Whole-chain reversal at last use** (2.1): for each terminal tainted
  data handle, reverse its entire forward gate chain (not per-SSA-value),
  anchored at the SSA last-use point.
- **The Phase 4 / Phase 5 partition** (2.2): Phase 5 owns *source-derived
  data* handles; Phase 4 already owns *pass-invented control scratch*
  (flags, conjunction `toffoli`, MUX-EXCH non-selected sources).
- **`emit_inverse` as a shared helper** (2.3): reverse-order, negate
  parameterized angles, self-adjoint gates as-is; at **template-call
  granularity** while bodies are stubs. One reusable helper, also called by
  Phase 7 (manual inversion).
- **Last-use via `PostDominatorTree`** (2.4): `Value::users()` →
  user-block set → nearest common post-dominator → `getFirstInsertionPt()`.
- **Measurement as a terminator** (2.5): a measured handle gets no adjoint
  and no free.
- **Escape detection + catch-all diagnostic** (2.6): skip `ReturnInst` /
  `main` / `cq_invert_*`; **fail loud** on any unrecognized user — never
  silently skip.
- **In-shadow handles → controlled adjoint** (2.7): a data handle born
  inside a tainted-branch shadow reverses in **controlled** form, nested
  inside Phase 4's still-live flag bracket (flag kept alive, LIFO).
- **Pass ordering: Phase 5 runs last** (2.8), after opcode + controlled +
  measure lowering, so `emit_inverse` walks the *final* forward sequence.
- **Acyclic-CFG assumption + loop guard** (2.9): loops deferred; a tainted
  handle whose live range crosses a backedge is **diagnosed**, not
  miscompiled.
- **`cqrt_free` after the adjoint** (2.10), at the same insertion point.

**Out of scope.** See §5. Load-bearing exclusions: loop-carried /
per-iteration reversal (the loops phase **extends** this mechanism, does
not replace it); manual `cq_invert_*` inversion (Phase 7 — beads
[`test_C_libtooling-42t`](../../../.beads/issues.jsonl), reuses 2.3's
helper); rejection-set classification / non-adjointable breadth (Phase 6);
real template bodies + gate-granularity `emit_inverse` (post-freeze);
MUX-EXCH non-selected-source uncompute (Phase 4 control scratch — beads
[`test_C_libtooling-npu.6`](../../../.beads/issues.jsonl)).

---

## 2. Design decisions

Each was resolved during PRD-discovery and is binding.

### 2.1 Reverse the *whole register chain* at last use — not per-SSA-value

A C-level tainted variable is one logical register transformed in place.
`q = cq_theta(...); q = q + 1; q = q * 2;` is three gates on **one**
register; "uncompute `q`" means undo `*2`, then `+1`, then the rotation —
the entire chain, reversed. The unit of uncomputation is therefore the
**terminal handle's forward chain** — reconstructed by walking def-use
**operand-0 threading** back from the terminal SSA value to the
`cqrt_alloc` mint (each gate threads its handle as operand 0; a controlled
gate threads the flag as arg 0 and the handle as arg 1). `BirthOrder` in
`TaintSet` is a flat mint counter, **not** a lineage record, so it serves
only as a program-order tie-breaker — not the walk itself
([`IMPLEMENTATION.md`](./IMPLEMENTATION.md) §2.3). "Per-op" describes only
the granularity of the inverse sequence emitted, not the unit.

The trigger is the terminal handle's **SSA last-use point** (2.4). This is
the structural realization of the user-stated rule "*each tainted variable
not measured at scope exit is completely reverted*": last-use is always
**earlier-than-or-equal-to** C lexical scope exit, so it satisfies
"reverted by scope exit" while reclaiming the register as early as
possible — and, unlike lexical-brace timing, it needs **no debug-info
scope recovery** (`clang -O1` has already erased the braces; only `!dbg`
would carry them, and coupling correctness to `!dbg` survival is what
Phase 10 audits as fragile).

**Reconciliation.** [`backend.md`](../../backend.md) §9 frames this
per-tainted-handle; this decision pins the handle to the *register chain*
(terminal SSA value), which the §9 prototype exercised only implicitly
(its fixtures had single-op chains).

### 2.2 The Phase 4 / Phase 5 partition: data vs control scratch

Phase 4 already emits adjoints — but only of the **ancillas it invented**
to realize control: comparison flags (`cq_template_icmp_*_inv`),
conjunction `cqrt_toffoli_inv`, De Morgan `X` brackets, and MUX-EXCH
non-selected-source prep reversal. None of those exist in the user's
source. Phase 5 owns the complement: **source-derived data handles**. The
partition is by *what* is reversed (control scratch vs data), **not** by
*where* (in/out of a conditional) — Phase 5 does reverse data born inside a
conditional (2.7).

Operationally, Phase 5's target set = `TaintSet` handles **minus** the
control-flag map (`value → control flag`, populated by Phase 4) **minus**
measured handles (2.5) **minus** escapes (2.6). Keying on this set is what
prevents double-emit (R1).

**Reconciliation.** [`backend.md`](../../backend.md) §9.4 + Phase 4 PRD
§2.9 both pre-declare this seam; this decision makes the set-subtraction
that enforces it explicit.

### 2.3 `emit_inverse` — one shared helper, template-call granularity now

`emit_inverse(forward_sequence)` injects real reversed instructions into
the IR: walk the sequence in reverse and, per call,

- parameterized rotation → re-emit with the angle **negated**
  (`cqrt_ry_<W>(h, θ)` → `cqrt_ry_<W>(h, -θ)`, likewise `cqrt_rz`);
- template call → emit the declared `_inv` twin
  (`cq_template_<op>_<W>` → `cq_template_<op>_<W>_inv`; controlled →
  `_controlled_inv`, flag still arg 0);
- self-adjoint gate (`cqrt_x/h/cnot/toffoli`, `cqrt_cswap`) → emit as-is.

It walks at **template-call granularity** while template bodies are stubs;
once bodies are real, the *same* helper walks at gate granularity
([`backend.md`](../../backend.md) §10.1). It is built as a **standalone
reusable helper** from day one, because Phase 7 (manual inversion) calls
the identical operation on an explicitly bracketed sequence (beads
[`test_C_libtooling-42t`](../../../.beads/issues.jsonl)) — "shared helper"
is a code-organization decision (one copy of the inversion logic), not an
alternative to injecting instructions.

### 2.4 Last-use via `PostDominatorTree`

The correct insertion point runs **after every use, on every path,
exactly once** — a post-dominance query. Per the validated prototype
([`backend.md`](../../backend.md) §9.1):

1. `for u in %h.users(): user_blocks.insert(u.getParent())`
2. `PostDominatorTree::findNearestCommonDominator(user_blocks)` → merge
   block
3. insert at `getFirstInsertionPt()` of that block (after φ-nodes, before
   the terminator).

This adds one stock LLVM analysis (`PostDominatorTreeAnalysis` via
`FunctionAnalysisManagerModuleProxy`). Phase 4 deliberately used the
*dominator* tree (it anchored at blocks it already knew); Phase 5 needs
the **post**-dominator because its insertion point is computed from a set
of use-blocks. The dominator and post-dominator structures are genuine
trees (each block one immediate (post)dominator); the CFG they are built
from is acyclic under 2.9.

### 2.5 Measurement is a terminator

A handle consumed by `@cq_measure_*` (lowered to `cqrt_measure_<W>`)
collapses and the register is reclaimed by measurement — so a **measured
handle receives no adjoint and no `cqrt_free`**, and the measure call is
**excluded** from the last-use post-dominator set (it is a sink, not an
ordinary use). Applying a gate to a handle **after** it is measured is
**ill-formed and rejected** (R-diag), keeping "measured ⇒ done"
unambiguous.

### 2.6 Escape detection + catch-all loud diagnostic

No uncomputation is emitted when the handle escapes the function, per
[`backend.md`](../../backend.md) §9.3:

- consumed by a `ReturnInst` — the **caller** owns it (uncomputes at the
  caller's last use);
- the enclosing function is **`main`** — no caller, process exit tears
  down the registers anyway;
- inside an explicit **`cq_invert_*`** region — Phase 7 supersedes.

Any tainted data handle that reaches a user **outside** this recognized
set (e.g. a `store`/capture once a memory model exists) is **diagnosed
loudly** — `DiagnosticInfoUnsupported` with `!dbg` source location —
**never silently skipped**. This is the conservative default: an
unrecognized escape is a hole, not a no-op.

### 2.7 In-shadow data handles → controlled adjoint, flag kept alive

A data handle minted *inside* a tainted-branch shadow had its forward
gates substituted to `_controlled` by Phase 4. Its adjoint must therefore
also be **controlled** on the same flag. The control flag is **kept
alive**: Phase 5 anchors its controlled data-adjoint **inside** Phase 4's
existing flag bracket — immediately **before** the flag's uncompute — so
the order is

```
flag-compute → [ controlled forward … controlled data-adjoint(P5) ] → flag-uncompute(P4)
```

i.e. the data-adjoint nests in the same LIFO bracket as the data-forward —
the physically natural structure (forward and adjoint share the flag's
lifetime). The **recompute-the-flag** alternative is rejected: it would
emit the compare twice **and** carries a correctness hazard — recomputing
`q1 < q2` requires `q1`/`q2` still intact, but Phase 5 is in the business
of reverting them, reintroducing the very ordering problem keep-alive
avoids.

**Implementation note (resolved — anchor is *not* SSA-discoverable).**
Keep-alive requires Phase 4 to leave its flag-teardown discoverable as an
anchor. The implementation audit found it is **not**: Phase 4's teardown is
an intentionally **unconsumed** `cq_template_icmp_*_inv` over the
*condition's* data handles (not the flag), and the merge block that carried
the anchor is erased by CFG linearization — so `users(flag)` never reaches
it. The anchor is therefore **recorded explicitly**: a new
`TaintSet::FlagTeardown` map, populated by a ~6-line Phase-4 hook, is a
**mandatory prerequisite** (Step 0), not a verify-at-WP-time deferral
([`IMPLEMENTATION.md`](./IMPLEMENTATION.md) §2.4 / §6).

### 2.8 Pass ordering: Phase 5 runs last

`emit_inverse` must walk the **final** forward calls. If Phase 5 ran
before Phase 4's controlled substitution it would reverse the *plain*
`cq_template_<op>_<W>` (emitting `_inv`) while Phase 4 then made the
forward `_controlled` — pairing a controlled forward with an
**unconditional** inverse: it would not undo the operation and would fire
unconditionally. Phase 5 therefore runs **last**, after opcode lowering
(Phase 3), controlled substitution (Phase 4), **and** measure lowering
(2.5) — recognizing the final `cqrt_measure` / `_controlled` forms.

### 2.9 Acyclic-CFG assumption; loops deferred and the mechanism *extended* later

Phase 5 assumes an **acyclic CFG** (a CFG is a DAG iff it has no
backedges; SSA data-flow is acyclic regardless). Straight-line and
`if/else` diamonds qualify — and Phase 4's `CFGLinearization` has already
straightened the tainted diamonds before Phase 5 runs, so the multi-BB
cases Phase 5 sees are largely classical control flow around tainted data,
which the post-dominator handles cleanly.

Loops are **out of scope**. A tainted handle whose live range crosses a
loop backedge (loop-carried register, per-iteration reversal) is
**diagnosed loudly**, never silently miscompiled. When the loops phase
lands, it **extends** Phase 5's `emit_inverse` + last-use machinery to
loop semantics (per-iteration compute/uncompute, loop-carried chains) —
it does **not** replace it. This obligation is recorded in both this PRD
(§5) and ROADMAP's loop section.

### 2.10 `cqrt_free` after the adjoint sequence

At the computed insertion point, the adjoint sequence is emitted first,
then `cqrt_free(%h)` returns the register to the runtime pool
([`backend.md`](../../backend.md) §9.2). This supersedes the prototype's
bare-`cqrt_free` placeholder (no adjoint) — the free now closes a balanced
forward/adjoint bracket.

---

## 3. Deliverables

- **New `Uncomputation` module** (`ir-pass/src/`) — the prototype's
  `cq-uncompute` slice lifted into the production pass-plugin layout:
  target-set computation (2.2), last-use via `PostDominatorTree` (2.4),
  whole-chain walk (2.1), escape + measurement filtering (2.5, 2.6),
  in-shadow controlled-adjoint anchoring (2.7), `cqrt_free` (2.10).
- **`emit_inverse` shared helper** — standalone, reused by Phase 7 (2.3);
  template-call granularity, with the gate-granularity path noted for
  post-freeze.
- **Pass pipeline** — slot `Uncomputation` **last** (2.8); wire
  `PostDominatorTreeAnalysis`.
- **No runtime / template changes** — the `_inv` / `_controlled_inv`
  surface is already declared with zero gaps (Phase 3/4 autogen,
  [`runtime/cq_templates.h`](../../../runtime/cq_templates.h) +
  `cqrt_*_controlled_inv` / `cqrt_free`); call out explicitly that the
  YAML/header SHA is **unchanged** this phase.
- **LIT fixtures** — one per shape (§4): linear single-handle revert;
  whole-chain reassigned variable; multi-BB branch (both-arm use → single
  merge-block uncompute, the prototype `input_phase5_branch.ll`
  trajectory); HH intermediate (`q1*q2` temp reverted, measured result
  not); in-shadow controlled-adjoint (`_controlled_inv`, nested in the
  flag bracket); escape cases (`return`/`main`/`cq_invert` → no emit;
  unrecognized user → loud diagnostic); loop-backedge guard diagnostic.
  Each carries the `opt -verify` RUN line.
- **e2e trace smoke** — a program with a mid-function non-`main` last use,
  run-and-diff against a golden showing the reversed template-call
  sequence + `cqrt_free`.
- **Doc cross-links** — mark ROADMAP Phase 5 done-criteria coverage; the
  loop-extension forward reference (2.9); reconciliations vs
  [`backend.md`](../../backend.md) §9/§10.

---

## 4. Done criteria

- A tainted data handle with a **mid-function, non-`main`** last use emits
  its reversed template-call sequence **+ `cqrt_free`** at the
  post-dominator block; `opt -verify` clean.
- A **reassigned** variable (`q = cq_theta; q = q+1; q = q*2;`) with a
  non-measured terminal use reverses the **whole chain** —
  `mul_inv` → `add_inv` → `cqrt_ry(-θ)` — in that order (2.1).
- A handle **used on both arms** of a branch emits a **single** uncompute
  at the merge (post-dominator) block, no duplication (prototype
  `input_phase5_branch.ll` trajectory).
- An **HH intermediate** (`q1*q2` temporary) is reverted at its last use,
  while a handle whose only consumer is `cq_measure` gets **no** adjoint
  or free (2.5).
- A data handle minted **inside a tainted `if`** reverses in **controlled**
  form (`_controlled_inv`), nested inside Phase 4's flag bracket (flag
  uncompute lands **after** the data-adjoint); `opt -verify` clean (2.7).
- **Escape**: a returned handle, a handle in `main`, and a handle inside a
  `cq_invert_*` region each get **no** uncompute; a tainted handle reaching
  an **unrecognized** user emits the loud diagnostic (2.6).
- **Loop guard**: a tainted handle crossing a loop backedge emits the loud
  diagnostic — no silent miscompile (2.9).
- A **control flag** (Phase 4 scratch) is **not** touched by Phase 5
  (no double-emit) — asserted by a `CHECK-NOT` (R1).
- The e2e trace smoke diffs clean against its golden.

---

## 5. Out of scope

- **Loops** — loop-carried registers and per-iteration reversal. Deferred
  to the loops phase, which **extends** (does not replace) Phase 5's
  `emit_inverse` + last-use mechanism (2.9). Until then, backedge-crossing
  tainted live ranges are diagnosed (§4). Recorded in ROADMAP's loop
  section.
- **Manual inversion** — `cq_invert_begin` / `cq_invert_end` brackets,
  Phase 7 (beads
  [`test_C_libtooling-42t`](../../../.beads/issues.jsonl)). Reuses the
  2.3 `emit_inverse` helper; Phase 5 only *skips* handles inside such
  regions (2.6).
- **Rejection-set classification / non-adjointable breadth** — Phase 6
  ([`backend.md`](../../backend.md) §7.4). Phase 5's only diagnostics are
  the unrecognized-escape, post-measurement-use, and loop-backedge guards;
  the broader "non-adjointable callee" set is Phase 6's.
- **Real template bodies + gate-granularity `emit_inverse`** — post-freeze.
  The same helper walks gate granularity once bodies exist (2.3).
- **Memory escapes** (`store`/capture of a handle) — there is no
  `load`/`store` lowering yet (post-freeze memory model); covered by the
  catch-all diagnostic (2.6) until then.
- **MUX-EXCH non-selected-source uncompute** — this is Phase 4 **control
  scratch** (the gated-switch disentangle), already owned by Phase 4.x
  (beads [`test_C_libtooling-npu.6`](../../../.beads/issues.jsonl);
  [`MISSING_CASES.md`](../phase-04-controlled-form/MISSING_CASES.md)), not
  Phase 5 data.
- **Whole-call Bennett wrap-around** — reserved for Phase 6 §7.2 clone
  synthesis, never used for per-op uncomputation
  ([`backend.md`](../../backend.md) §9.4).

---

## 6. Risks

- **Double-emit across the Phase 4 seam (2.2).** If Phase 5's last-use
  scan walks a *control* ancilla (a flag), it would uncompute what Phase 4
  already balanced. Mitigation: Phase 5 keys strictly on the data set
  (`TaintSet` minus the control-flag map minus measured/escaped); a
  `CHECK-NOT` fixture asserts no Phase-5 emission touches a flag handle.

- **Stale-sequence reversal (2.8).** Running before controlled
  substitution would pair a `_controlled` forward with a plain `_inv`.
  Mitigation: fixed last pass slot; an in-shadow fixture asserts
  `_controlled_inv` (not plain `_inv`) is emitted.

- **Flag-lifetime ordering under keep-alive (2.7).** The controlled
  data-adjoint must land *inside* Phase 4's flag bracket, before the flag
  teardown. The teardown is **not** SSA-discoverable (it is an unconsumed
  `_inv` over the condition handles, and its merge block is erased), so the
  anchor is recorded explicitly via a new `TaintSet::FlagTeardown` hook
  (Step 0, mandatory). Mitigation: anchor on the recorded teardown call; the
  in-shadow fixture asserts the flag uncompute follows the data-adjoint.

- **Whole-chain vs per-SSA confusion (2.1).** Reversing each intermediate
  SSA value independently (instead of the terminal chain) double-frees /
  mis-orders. Mitigation: reconstruct the chain from def-use **operand-0
  threading** back from the terminal handle (`BirthOrder` is a flat mint
  counter, used only as a tie-breaker — **not** a lineage walk); the
  reassigned-variable fixture pins the order.

- **Insertion point vs φ-nodes (2.4).** `getFirstInsertionPt()` must land
  after φ-nodes at the merge block. Mitigation: the both-arm multi-BB
  fixture exercises a φ-bearing merge; `opt -verify` RUN line guards.

- **`PostDominatorTree` on unusual CFG (2.4, 2.9).** No common
  post-dominator (e.g. an arm that does not reconverge) or a backedge.
  Mitigation: the acyclic assumption + loop-backedge diagnostic; a
  non-reconverging arm is an escape (2.6) → diagnosed, not miscompiled.
