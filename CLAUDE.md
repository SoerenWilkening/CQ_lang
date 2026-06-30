# CQ_lang — Taint-Driven Quantum-C Compiler: Directives for AI Agents

CQ is a small extension of C for writing quantum programs. There is no
`quantum` keyword and no special type: a value becomes quantum by passing
through a `cq_*` primitive, and an out-of-tree **LLVM 19** pass propagates that
**taint** forward through stock C arithmetic, control flow, and calls — lowering
tainted opcodes to reversible runtime-template calls. **No LLVM fork, no MLIR
dialect, no AST rewriter, no custom parser, no `quantum` keyword.** Stock
`clang -O1` compiles the source; one `opt` pass (`cq-lowering`) does all the
work; the program links against the trace runtime and runs.

You are working on a **quantum reversible compiler**. The defining hazard of
this codebase is the **verify-clean silent miscompile**: a lowering that passes
`opt -verify` — and even prints a plausible trace — yet computes the wrong
unitary, drops a `phi` edge, fires a gate on the wrong branch, or collapses a
qubit by freeing an entangled rail. Everything below exists to prevent that one
class of bug.

> **Authoritative status lives in [`ROADMAP.md`](ROADMAP.md), not here.** This
> file is the *operating manual*; the ROADMAP is the *plan of record* (Phases
> 0–10 + the 10 cross-cutting design principles). **Phase 4 — RSSA swap-routed
> tainted control flow — is DONE** (clean-slate `4.0`, the `4.1` phase-arm
> emitter, `4.2` (value/permutation arms, method-B), `4.3` (depth-2 nested
> control), `4.4` (tainted `select` — controlled-XOR copy merge), and `4.5`
> (tainted `switch` — N-way eq-flag routing + const-fold re-anchor) all **done**
> on branch `swap-route-control`). **Phase 5 — whole-DAG LIFO uncomputation over
> the void `_unc` ABI — is also DONE** (all 7 WIs; the per-terminal `_inv` slice
> productionized to whole-DAG reversal of dead source-derived data handles,
> Rule-13 cleared incl. the WI-7 compare-uncompute over-accept fix). **Phase 6 —
> call-graph specialization (function lifting) — is DONE: `6.0`
> (compare `_unc` grid), `6.1` (clone-on-taint core + Bennett wrap +
> `(callee,mask)` cache + carve-out), `6.2` (signature masks / cache /
> multiplicity), `6.3` (transitive worklist — depth-first inner
> specialization reversed in the outer wrap via a synthesized void uncompute
> twin `@__cq_q_<inner>_<mask>_unc`; recursion/cycle + varargs loud reject;
> the stale-classical-attr fix), `6.4` (rejection-set hardening — full decline
> matrix + over-accept probe family), and `6.5` (classical call under quantum
> control — a pure all-classical-args call inside a tainted-condition DIAMOND arm
> runs classically, its i32 result route-merged into the controlled register via
> the 4.4 controlled-XOR copy mechanics over a flattened diamond; the call is
> HOISTED into the pred since it is pure; clone-ORTHOGONAL — `ClassicalCallArm`
> Kind + `classifyClassicalCallArm` + `emitClassicalCallArmRegion`, NO clone) are
> ALL DONE (branch `phase-6.5-classical-call`, each Rule-13 cleared). Read
> `ROADMAP.md` and `docs/design/rssa-swap-control/` *before* touching control
> flow. Phases 0–6 done; **7.1/7.2/7.5/7.6 done** (incl. controlled `return`/`abort`
> via epic `65wb`, closed 2026-06-23); **7.5 DONE** (epic `7z9k`: the frozen
> `cqrt_qram_alloc/load/store_<W>` (+ `_unc`) ABI + const-global QROM reads + alloca
> Shadow store/load with whole-DAG LIFO store reversal; Inc 3 added the
> single-origin provenance walk (flat geps + gep chains + pointer phi/select) + the
> full pattern-naming over-accept decline matrix, all Rule-13-cleared — the Inc-3
> review FOUND+FIXED a non-zero-`memset` silent-miscompile over-accept, now
> `kMsgQramInit`; 2026-06-23/24); **7.3 core DONE** (epic `799w`, CLOSED: rolled-in-place
> bounded loops — Inc 1 `799w.1` Case A in-place persistent-rail collapse + Inc 2 `799w.2`
> Case B per-iteration in-body uncompute, each Rule-13-cleared; 2026-06-25); **7.4 core
> DONE** (epic `y05j`, CLOSED: value-arm `break` — `y05j.1` the `tryBreak` recognizer +
> decline partition, `y05j.2` the index-gated copy-not-move capture + whole-loop
> reverse-play EMISSION over a new post-lowering `lowerBreakReversePlay` stage + the dtzb
> `cqrt_xorc`/`cqrt_addc` `EmitInverse` adjoints; the canonical capture+reverse-play
> sim-replay-verified, 7 over-accept holes found+fixed as the E1–E11 decline
> preconditions across **three** adversarial Rule-13 rounds; 2026-06-26). **"DONE" here
> means the scoped CORE increments shipped + Rule-13-cleared; everything outside the
> shipped accept-shape declines loudly (Prime Directive), so the open follow-ons are
> additive coverage / deferred separate capabilities, NOT correctness debt.** The
> post-core break/loop widenings (multi-break, nested-loop break, `continue`, mixed
> break+return, static-K unroll, value-arm widening) live under the open 7.x-widenings
> tracker `8h7d` — freeze-orthogonal (7.2–7.4 add no frozen symbols). **Phase 7 core
> complete (7.1–7.6 core DONE; widenings tracked under `8h7d`);** 8–11 remaining.
> **Roadmap resequenced 2026-06-19:**
> Phase 7 is now **pre-freeze expressiveness completion** (7.1 opcode-surface
> completion incl. Q+Q data compare + wide integers `__int128`/`_BitInt`; 7.2
> controlled function-`return`; 7.3 bounded loops; 7.4 `break`; 7.5 QRAM full
> Shadow model); manual inversion (`cq_invert`) moved to **Phase 8**; runtime
> templates / integration / freeze are **9 / 10 / 11**. The freeze is gated only
> on the 7.5 QRAM memory ABI, the 7.1 wide-integer widths, and the 7.6 I/O
> output-tape ABI (`cqrt_tape_alloc` / `cqrt_tape_write_<W>` (+ `_controlled`)) — the control/loop work (7.2–7.4)
> adds no frozen symbols. See `ROADMAP.md` for the authoritative plan.

---

## The Prime Directive — when in doubt, DECLINE

`opt -verify` clean proves the IR is **well-typed**, never that the **unitary is
correct**. Correctness here is established by analytic/trace reasoning, golden
end-to-end diffs, and independent adversarial review (no simulations at this
stage — owner decision 2026-06-10) — *not* by the verifier.

**Over-declining is always safe. Over-accepting is a silent miscompile.** When
any detection or lowering precondition is ambiguous, unproven, or off-pattern,
emit the loud `DiagnosticInfoUnsupported` (`"… under quantum control"`, `opt`
exits non-zero) and **lower nothing**. A loud reject is a feature; a silently
wrong answer is the only unforgivable bug. The bd-memory history records this
exact class hit a dozen-plus times (diamond, gated-switch, jumptable, MUX-EXCH,
angle paths) — every time caught by adversarial reasoning or e2e diff, *never*
by `opt -verify`.

---

## Non-Negotiable Rules

**Rule 0 — Institutional memory.** Durable, hard-won knowledge goes in
`bd remember` (26 memories already encode the silent-miscompile history — read
them: `bd memories <keyword>`). Design-of-record goes in `docs/` and per-phase
PRDs (`docs/prd/phase-NN-*/`). Do **not** use TodoWrite, markdown TODOs, or
`MEMORY.md`. Every gotcha, LLVM-19 quirk, and silent-miscompile root cause must
be written down — future agents (and you, after compaction) depend on it.

**Rule 1 — Fail loud, decline safe.** Use the loud diagnostic and lower nothing
when unsure (see Prime Directive). Diagnostics carry the offending instruction's
`!dbg` so they are source-located and `opt` exits non-zero. A tainted
`br` / `select` / `switch` is **never** silently passed to the backend as
classical control over quantum state — `ControlDetect.cpp` either hands the
region to the swap-route emitter (`SwapRouteEmit.cpp`) or declines it loudly;
there is no third path.

**Rule 2 — Verify-clean is necessary, never sufficient.** Establish correctness
by golden e2e trace diff (the only layer that links and proves every emitted
symbol resolves and signature-matches) **plus** independent adversarial review
with analytic/trace reasoning. No simulations and no backend at this stage
(owner decision 2026-06-10); the one-off oracles in
`docs/design/rssa-swap-control/` are historical design artifacts, not a gate.
"Passes `opt -verify`" and "runs without crashing" are not evidence.

**Rule 3 — Taint is the only Q/C boundary.** A value is quantum iff it is
(transitively, via stock LLVM data flow) derived from a `@cq_theta_*` result.
`cq_theta` (Ry) is the **sole** taint source; `cq_measure` the **sole** sink;
`cq_phi` (Rz) propagates taint but never introduces it (deleted on classical
operands). The **arg-1 angle** operand of a rotation is classical — never
propagate taint through it, and the exclusion is **per-operand-use, not
global** (a value also used as an arg-0 handle stays tainted). Never allocate a
qubit for an angle or coerce it to an `i32` handle — that is the f64/angle
miscompile family.

**Rule 4 — No fork, no rewriter, no new intrinsics.** Stock LLVM 19, out-of-tree
MODULE plugin. The frontend is `CQ.h` only. There are **no** quantum arithmetic
intrinsics (`cq_add_qq`, …) — stock LLVM opcodes on tainted operands are lowered
to templates. The retired `quantum`-keyword / cast-as-measurement /
libtooling-transpiler design lives in `archive/` and `docs/archive/old-design/`
— **reference only; never revive** (see Key Prohibitions).

**Rule 5 — Coherent-first; never insert a measurement.** The compiler **never**
emits a measurement the user did not write (hard project invariant). There is
**no** measure-only / forward-only mode (struck 2026-06-08) — it silently
corrupts under downstream interference (Grover/QPE). Coherence for the common
**phase arm** is the uncontrolled `icmp_inv(q)` **flag-strip** (the rail is `|0⟩`
for free under `Rz = diag(1,e^{iθ})`); region-local **reverse-play** (the adjoint
of the forward stream, via `EmitInverse`) is the **on-demand** undo for user
`cq_invert` and value-arm method-B, **not** an eager per-increment step (revised
2026-06-09, superseding "mandatory in every increment"; see
`docs/design/rssa-swap-control/SCOPING.md` §3a).

**Rule 6 — Free only a proven-`|0⟩` rail.** `cqrt_free` is **compiler-emitted
only** and is a hardware reset = projective measurement. Emit it **only where the
rail is provably `|0⟩`** — for a **phase arm** that is immediately (the rail is
`|0⟩` for free, `Rz|0⟩ = |0⟩`); for a **value arm** only after its method-B
reverse-play. A rail **not** provably `|0⟩` is **left allocated** (a qubit leak,
accepted in the qubits-not-scarce regime), **never freed dirty** — freeing a
dirty/entangled rail is a hidden measurement that collapses `q` (revised
2026-06-09). Never free a handle that **Escaped** (`ret` / `cq_invert_*`) or is
**Measured** — the caller / the measurement owns it. Route every free through the
`FreePoint` post-dominator discipline; a post-measure gate, a loop-backedge live
range, or an unrecognized user is a **loud reject**, never a silent skip.

**Rule 7 — Method matches arm class.** **Phase arms** (`Rz` = `cq_phi`) keep the
answer (a phase) **in place on `q`**; the rail is `|0⟩` for free and the
data-derived flag is stripped by the **uncontrolled** `icmp_inv(q)` — **zero
controlled gates** (method-A controlled-adjoint rail cleanup is **dropped**,
2026-06-09: it buys nothing over §6a control-in-place). Classical-permutation /
**value arms** (`add`/`mul`/`x`/`toffoli`) use compute → copy-out → reverse-play
(**method-B**, `cqrt_copy_<W>`). **Never apply method-B to a phase arm** — a CNOT
copies a basis *label*, not a *phase*, so `R†` cancels the very superposition that
was the answer (verified P0 0.585 → 0.500, fully dephased). An arm that
value-rewrites a variable the condition reads is a **loud reject** (clobber,
SCOPING §3c).

**Rule 8 — No-cloning / linearity.** Copy + uncompute cannot disentangle a
superposition. Freeing a source that carries superposition requires
controlled-SWAP (`cqrt_cswap` / Fredkin), not copy + uncompute. Whole-chain
reversal requires **linear lineage** — bail on fan-out (>1 forward consumer on a
non-terminal handle) or you double-uncompute the shared prefix (use-after-free +
double-free). Only Rz (phase) and Ry (superposition) create quantum coherence;
`x`/`toffoli`/`cswap` are permutations — but a permutation that leaves a rail
dirty **and entangled** still dephases under later interference.

**Rule 9 — Stock LLVM IR is not stable; `-O1` is the validated floor.** Never
assume formatting, instruction order, naming, or branch polarity. `clang -O1`
canonicalizes (`if(u!=k)` → `icmp eq; br eq, Merge, Arm`), swapping successors
and value-propagating the straight-through edge to a constant — so the gate arm
is often the **false** successor and a gate-body phi must RAUW to the **tainted**
incoming, not the Pred edge. Detection is **pure analysis by SSA-value identity,
before any mutation** (so it survives rotation lowering's RAUW-to-handle; never
cache block pointers across erasures). `mem2reg`/SROA must have run (`-O0`
unsupported); `-O2`/`-O3` break taint signatures, post-dominators, and handle
identity (regression-matrix only).

**Rule 10 — All bugs are deep and interlocked.** Never assume a shallow bug.
Investigate root cause fully; a fix that passes one test but violates an
invariant elsewhere is not a fix. Off-by-one and "it works now" are suspect.
Nearly every silent miscompile in the history (f64 φ, gated-switch mixed/distinct
φ, MUX-EXCH G3b stray rotation, jumptable over-match, nested-merge UAF) was found
by a deliberate **adversarial probe family**, not by the positive suite.

**Rule 11 — Skepticism.** Verify everything — subagent output, prior sessions
(against `git log`), and **bd memories** (they reflect what was true *when
written*; a named file/flag may be gone — e.g. `ControlDetection.cpp` and
`MergeDissolution.cpp` were **excised** in `7cde677`). Extract and read the
actual lowered IR before implementing; do not guess LLVM patterns.

**Rule 12 — Every accept-predicate ships with a decline fixture + adversarial
probe.** Red-green: write the lit fixture first (positive `CHECK` **plus** a
negative `RUN: not … | FileCheck` that mirrors the diagnostic string
character-for-character), watch it fail, implement minimally. A new shape-matcher
without a probe family is incomplete. `ir-pass-lit` and the e2e goldens are
regression baselines — keep them green; regenerate baselines deliberately, never
by reflex.

**Rule 13 — Core lowering changes get adversarial verification, not just green
tests.** Changes to the lowering core (`TaintPropagation`, the swap-route /
control emitter, `FreePoint`, `EmitInverse`, `ChainWalk`, `Uncomputation`,
`RotationLowering`) are where the silent miscompiles live. Before committing,
clear the change via an independent second reviewer/agent using
analytic/trace-level reasoning (no statevector simulations at this stage —
owner decision 2026-06-10). A green suite alone does **not** clear a core
change.

**Rule 14 — Reuse before reinvention; no duplicated lowering.** Check existing
handlers (`OpcodeSupport` / `ArithLowering` / `CompareLowering` / `CastLowering`,
the `EmitInverse` adjoint spine, the Phase-5 uncompute spine
`ChainWalk`/`FreePoint`/`Uncomputation`, and the `cqrt_cswap`/`cqrt_toffoli`
primitives) before adding a new one. The swap-route rebuild **reuses**
`emit_inverse` for reverse-play and `FreePoint` for rail cleanup — extend, do
not fork.

**Rule 15 — Width-only ABI; edit the YAML, never the generated files.** The
runtime template surface is generated:
`tools/opcode_table.yaml` → `tools/gen_templates.py` → `runtime/cq_templates.{h,c}`.
Edit the YAML and regenerate; the SHA-256 drift check (`gen_templates.py
--check`) gates it. Signedness lives in the opcode (`add nsw` vs `nuw`,
`icmp slt` vs `ult`); the IR pass strips it — a runtime handle is **always
`i32`** regardless of width.

**Rule 16 — Phase discipline.** Each phase carries a PRD written at its start,
not in advance. Don't implement out-of-scope features or skip a phase's
done-criteria (both lit fixtures **and** ≥1 e2e golden smoke). The bd tracker
spans **two design generations** — closed old AST-frontend / transpiler issues
do **not** indicate new-design progress.

**Rule 17 — Build the intent; a decline is not the development escape hatch.**
When the task is to *implement* support for a construct, attempt the real
lowering — do **not** substitute a loud decline for the hard work we set out to
do. This does **not** weaken the Prime Directive at **runtime**: a genuinely
off-pattern, unprovable *input* still declines loudly (over-accepting is still
the one unforgivable silent miscompile, and an over-safe decline of a shape we
were **not** trying to support is still correct). What changes is **development
posture**: when implementing a feature, do not reach for a decline as the
convenient way out of a difficult lowering, and do not reflexively gate the
intended shape behind an over-safe decline check. If the implementation proves
genuinely difficult, ambiguous, or off-pattern in a way that tempts a decline of
the very thing we aimed to build, **stop and bring questions / a discussion back
to the owner** rather than silently shipping a decline-only stub and calling it
done. Over-declining what we set out to build is a punt, not a feature — the
decline belongs to the inputs outside the target shape, not to the target shape
itself.

---

## Pipeline Architecture

```
 plain C + CQ.h
      │  clang -O1   (stock; no CQ parser — intrinsics survive as @cq_* calls on plain SSA)
      ▼
 LLVM 19 IR ──► opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering
      │            │
      │            ├─ propagate()        forward taint  (@cq_theta = source · @cq_measure = sink)
      │            ├─ guards             taint-escape · stale-record · (post-detect) classical-mux → LOUD DECLINE
      │            ├─ detectControl()    tainted br: phase-arm region → swap-route emit + flatten; else LOUD DECLINE
      │            ├─ lowerRotations()   theta → cqrt_alloc_<W> + cqrt_ry_<W> ; phi → cqrt_rz_<W>
      │            ├─ lowerOps()         tainted add/mul/icmp/cast → cq_template_*[_hl|_lh]
      │            ├─ lowerMeasures()    cq_measure → cqrt_measure_<W>
      │            └─ uncompute()        whole-DAG LIFO adjoint (void _unc) + cqrt_free   (runs LAST)
      ▼
 lowered IR  (only cqrt_* and cq_template_* externs — all cq_* intrinsics gone)
      │  clang + link   (libcq_templates.a BEFORE libcq_runtime.a — load-bearing order)
      ▼
 executable → prints one trace line per gate → byte-diff vs golden .expected.log
```

Orchestrated by `CQLoweringPass::run` (`ir-pass/src/CQLoweringPass.cpp`); a
module with no theta/phi/measure is left **byte-identical** (passthrough).
Runtime is **trace-only** (each `cqrt_*` / `cq_template_*` prints
`symbol(args) -> ret`; `measure` returns 0; no simulation) — the golden trace is
the contract.

---

## CORRECTNESS RISK — Tainted control flow (the live work, the deepest hazard)

Tainted `br` / `select` / `switch` is the construct that has produced every
verify-clean silent miscompile in this project's history. The **old controlled-op
lowering** (mint a flag → substitute each arm gate with a `_controlled` template
→ dissolve the φ → uncompute the flag → linearize the CFG) shipped and was then
**removed wholesale** (`7cde677`) so the new **RSSA swap-route** design is built
without it shaping the implementation. Today `ControlDetect` recognizes
phase-arm AND value-arm if-diamond / if/else regions (incl. derived-base
routing); `SwapRouteEmit` lowers **phase arms** (flag mint → `cqrt_cswap` route
→ verbatim arm Rz → route back → clean frees → `icmp_inv` flag-strip, zero
controlled gates) and **value/permutation arms** by method-B (`R` →
`cqrt_copy_<W>` copy-out → reverse-play `R†`; a value arm that clobbers a
register the condition reads declines loudly — §3c); `RegionFlatten` erases the
CFG diamond. `RegionTreeDetect` + `NestedRouteEmit` lower the **depth-2
homogeneous-phase nest** (`if(a){…if(b){…}}`, flag-per-level routing — 4.3
DONE). `SelectClassify` + `SelectMergeEmit` lower a tainted-condition
**integer-data `select`** via the **controlled-XOR copy merge** (flag mint →
`|0⟩` rail → two `cqrt_copy_<W>_controlled`, ¬flag `cqrt_x`-bracketed → `icmp_inv`
strip → one `cqrt_free`; no cswap/route/flatten/reverse-play — 4.4 DONE; coherent
`Ry`-phase / fp-data operands ride the conservative decline). `SwitchClassify`
(G0–G11) + `SwitchArmProve` + `SwitchRouteEmit`/`SwitchValueEmit`/
`SwitchDataMuxEmit` + `EqFoldArm` lower a tainted-scrutinee `switch` (and the
equality-folded `br` diamond) in **four** ACCEPT shapes — homogeneous **phase**
(N-way eq-flag route + arg-1-only `cqrt_rz` + the **§5 const-fold re-anchor scrub**,
the verify-clean-invisible blocker), homogeneous **value** (N-way method-B over the
shared routed base `p != q`), all-`ConstantInt` **data-mux** (preload + XOR-delta
controlled copy), and the **eq-folded diamond** (`tryEqFoldArm` D1–D7, additive,
reuses `emitRegion`) — 4.5 DONE (16-reviewer Rule-13 clearance, 0 silent
miscompiles; `WI7_SWITCH_CLEARANCE.md`). **Every other tainted-control shape loudly
declines** (deeper or non-homogeneous nests; the switch off-pattern matrix: multi-phi
C1, grouped C4, non-empty-default C5, MUX-EXCH C8/G8, mixed arms, fp/vector/`i128`
G4, nested G11, `§3c` clobber G7, tainted angle G3, jump-table fold, impure/unowned-
scrutinee G10).
The enduring lessons — restructured, **not deleted** — that any control work
must respect:

- **RSSA φ appear on BOTH splits and joins.** The merge is the **adjoint of the
  branch**, sharing the **same live condition**: `br` routes the operand *in*
  (`cqrt_cswap` into a work rail), `phi` routes the active result *back*
  (`cqrt_cswap`). The join is literally the inverse of the split.
- **RSSA proves *classical* reversibility only.** Mogensen RSSA does **not** hand
  you quantum-coherence correctness. The superposed-control / no-cloning /
  Rz·Ry / reverse-play layer is the **original** part of this design, validated
  during design (2026-06) by one-off statevector reasoning — never "it's RSSA,
  therefore correct" (SCOPING §0).
- **Method matches arm class, not convenience** (Rule 7). Phase arms keep the
  answer on `q` and strip the flag with `icmp_inv` (zero controlled gates;
  method-A is dropped). Bennett compute→copy→uncompute (**method-B**) is the
  *special* case (basis-valued/value arms), not the general one; it **dephases**
  phase/rotation answers.
- **Branch polarity is inverted by `clang -O1`** (Rule 9): the gate arm is often
  the *false* successor; control on `¬flag` via a self-inverse `cqrt_x` bracket,
  and dissolve a gate-body φ to the **tainted** incoming, not the Pred edge.
- **An unlowerable merge φ must DECLINE, never dangle.** Integer merge φ is a
  real **data mux**; floating-point merge φ is a rotation **angle** — do not
  cross these wires. Test FP-ness with `isFPOrFPVectorTy()` (scalar-only
  `isFloatingPointTy()` misses `<2 x double>`); never key data-mux lowering on
  `abiWidthFromType()` non-empty (f64 has a valid width yet is an angle — that
  was the f64 silent miscompile). A φ the reduction skips dangles into a broken
  module.
- **Free only a proven-`|0⟩` rail** (Rule 6) and **never free a source carrying
  superposition by copy+uncompute** — that needs `cqrt_cswap` (Rule 8).
- **Block lifetime under sequential lowering:** linearization erases merge
  blocks; a region whose predecessor is another region's merge block dereferences
  freed memory (SIGSEGV on valid input). Capture identities before the first
  erase, or decline while blocks are still valid. Do **not** blanket-decline
  every shared merge — the legitimate nested-AND `if(a){if(b)}` is a coordinated
  pair that shares its merge and lowers correctly.

When you cannot *prove* the shape, **decline loudly** (Prime Directive).

---

## Hallucination-Risk Callouts (specific things agents get wrong)

- **`ControlDetection.cpp` / `MergeDissolution.cpp` / `ControlStub.cpp` no
  longer exist.** The first two were excised (`7cde677`); the transitional
  `ControlStub.cpp` was replaced by the live emitter chain
  `ControlDetect.cpp` / `ArmClassify.cpp` / `SwapRouteEmit.cpp` /
  `RegionFlatten.cpp` (with `ControlPlan.h` populated — `Regions` is real now).
  The old controlled-op logic is recoverable from git history but is **not**
  the path forward.
- **The *old* controlled-form "done" Phase 4 is a trap.** The controlled-op Phase
  4 shipped and was **removed wholesale**; the current Phase 4 is the swap-route
  rebuild and is now **fully DONE** — `4.0` + `4.1` (phase arms) + `4.2` (value
  arms, method-B) + `4.3` (depth-2 nested) + `4.4` (tainted `select`) + `4.5`
  (tainted `switch` — N-way eq-flag routing + const-fold re-anchor) all done on
  branch `swap-route-control`. Old ROADMAP/issue references to a "finished"
  controlled-form Phase 4 describe the **deleted** generation, not this one.
- **Casts are representation changes, NEVER measurements.** The only path to a
  measurement gate is an explicit `cq_measure(...)`. There is no flag/syntax to
  turn a cast into a measurement (this asymmetry is by design; it's what lets
  plain C functions with hidden internal casts lift to quantum callers).
- **`cqrt_free` is compiler-emitted only**, and freeing an entangled rail is a
  **hidden measurement** that collapses `q` (Rule 6) — not a benign lifetime op.
- **A floating-point merge φ is an angle, not data** (see Correctness Risk).
- **"No new primitive" holds only for keep-sources-live additive copy.** Freeing
  a superposed source needs `cqrt_cswap` (Rule 8).

---

## Build & Test

LLVM 19 is **mandatory** (CMake `FATAL_ERROR`s otherwise). On this machine
`opt` / `clang` / `FileCheck` are **not on `PATH`** — they live only in
`/usr/local/opt/llvm@19/bin` (the lit/ctest harnesses bake absolute paths in, so
they work; by-hand `opt`/`clang` need the absolute path). Only `lit` is on
`PATH`.

```bash
# Configure (one-time; LLVM_DIR must be passed explicitly — it is not auto-discovered)
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release

# Build everything (the cq-lowering plugin + runtime archives + test exes)
cmake --build build -j8
cmake --build build --target CQPass        # just the pass → build/ir-pass/libCQPass.so

# Full suite (10 ctest entries; ~50s, expect 100% pass)
cmake --build build && ctest --test-dir build --output-on-failure

# One layer at a time
ctest --test-dir build -R ir-pass-lit  --output-on-failure   # 136 *.ll lowering/control/uncompute fixtures (1 XFAIL: Phase-7 tracker)
ctest --test-dir build -R frontend-lit --output-on-failure   # CQ.h surface survives clang -O1 (no plugin)
ctest --test-dir build -R '^e2e-'      --output-on-failure   # 6 vertical slices — the only layer that LINKS
ctest --test-dir build -R runtime      --output-on-failure   # trace golden-diff + header compile

# One fixture (lit --filter matches the test display name)
cd build && lit -v ir-pass/test --filter 'lowering_basic'

# Run the pass on one .ll by hand (absolute tool path required)
/usr/local/opt/llvm@19/bin/opt -load-pass-plugin build/ir-pass/libCQPass.so \
    -passes=cq-lowering -S ir-pass/test/lowering_basic.ll \
  | /usr/local/opt/llvm@19/bin/FileCheck ir-pass/test/lowering_basic.ll
```

**Full pipeline for one `.c`** (mirrors `tests/e2e/run_slice.sh`; `LLVM=/usr/local/opt/llvm@19/bin`):

```bash
"$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S file.c -o /tmp/s1.ll          # 1: frontend
"$LLVM/opt" -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
            -S /tmp/s1.ll -o /tmp/s2.ll                                               # 2: cq-lowering
"$LLVM/clang" /tmp/s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o /tmp/a  # 3: link*
/tmp/a                                                                                # 4: run → trace
```

\* **Link order is load-bearing:** `libcq_templates.a` **before** `libcq_runtime.a`
(template `_hl` symbols call `cqrt_*`; single-pass `ld` needs the caller first).

There is **no GitHub CI** (no `.github/` exists); all quality gates run locally
through `ctest` (LIT+FileCheck for ir-pass/frontend, shell+golden-diff for e2e)
plus `gen_templates.py --check` drift verification. Do not add CI.

---

## Conventions

- **C11 / C++17**, `CXX_EXTENSIONS OFF`. `-Wall -Wextra` propagated to every
  sub-build — deliberately **not** `-Werror`.
- The pass is a **MODULE** library (`libCQPass.so`, `.so` even on macOS) that
  **does not link LLVM** — symbols resolve from the host `opt`/`clang` at
  `dlopen` (`-undefined dynamic_lookup` on Apple). Loaded with the **new** PM
  `-load-pass-plugin`, never legacy `-load`. The pass name is exactly
  **`cq-lowering`**.
- Pass code is split **one width-parametric module per concern** in
  `ir-pass/src/`, each in the `cq` namespace; `Plugin.cpp` registers,
  `CQLoweringPass.cpp` orchestrates.
- **Two runtime symbol families:** `cqrt_*` = the hand-written core ABI (7
  allocators + 7 measure + `cqrt_free` + `ry`/`rz`/`x`/`cnot`/`toffoli`/`cswap`,
  plus controlled twins); `cq_template_*` = the **autogenerated** reversible-op
  bodies for stock opcodes. Naming grammar:
  `cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv]`
  (HL = handle+literal, LH = literal+handle, QQ = both handles; `_inv` = adjoint
  twin). Handles are always `i32`; signedness stripped.
- **Diagnostics are loud and source-located** (`DiagnosticInfoUnsupported`,
  `DS_Error`, `!dbg` attached). Negative fixtures mirror the message
  character-for-character so code and test cannot drift.
- **Non-interactive shell flags always** (`cp -f`, `mv -f`, `rm -f`, `rm -rf`) —
  `cp`/`mv`/`rm` may be aliased to interactive `-i` and hang the agent
  (see `AGENTS.md`).

---

## Key Prohibitions

- **Do NOT revive the libtooling AST rewriter / transpiler.** It is archived
  (`archive/transpiler/`, `archive/tests/e2e/`); `find_package(Clang)` is gone.
  The frontend is a header lowered entirely in the IR pass — no AST pass, no
  parser, no rewriter.
- **Do NOT reintroduce the old `quantum`-keyword design or its surfaces** — the
  keyword/macro, `qint_mid_t` mid-structs, `cq_init_*` / `cq_alloc_*` families,
  `cq_when_begin/_end` brackets, the `MidHandleRebind` module, and
  **cast-as-measurement** are all eliminated.
- **Do NOT rebuild the excised controlled-op control path** (`ControlDetection`,
  `ControlFlag`, `ControlledLowering`, `ControlledSubstitution`,
  `FlagConjunction`, `CFGLinearization`, `MergeDissolution`,
  `SwitchNormalization`). The swap-route design replaces them. The `_controlled`
  template family is retained **only** as a reserve for the optional §6a
  control-in-place peephole — not as the control mechanism.
- **Do NOT add quantum arithmetic intrinsics** (`cq_add_qq`, …). Arithmetic is
  stock LLVM opcodes identified by taint.
- **Do NOT make `cq_phi` (Rz) a taint source** or allocate a qubit for it on a
  classical operand — only `cq_theta` allocates and creates taint.
- **Do NOT promote a classical operand to a qubit handle** in mixed Q+C ops —
  pass the literal through to the `_hl`/`_lh` template; never `cqrt_alloc` it
  (`quantum-classical-handling.md` §5.2, non-negotiable).
- **Do NOT insert any measurement the user did not write, and do NOT free a rail
  that is not provably `|0⟩`** (a dirty rail is left allocated, never freed —
  Rules 5, 6).
- **Do NOT fork LLVM or add an MLIR dialect.** No-fork stock-LLVM-19 is locked
  for v1; MLIR re-evaluation is deferred to the Phase 10 freeze gate.
- **Do NOT add GitHub CI**, and **do NOT use TodoWrite / markdown TODOs /
  `MEMORY.md`** — use `bd` and `bd remember`.
- **Do NOT use `-O0`** (mem2reg/SROA must have run) and avoid `-O2`/`-O3` at
  Stage 1 outside the regression matrix (inlining pre-empts clone-on-taint,
  SimplifyCFG flattens post-dominators, GVN/SLP fuse handles).

---

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->

---

## Where Things Live

| Path | Responsibility |
|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | Orchestrator: `propagate → escape/stale guards → detectControl+emit → classical-mux guard → lowerRotations → lowerOps → lowerMeasures → uncompute`; passthrough early-out |
| `ir-pass/src/TaintPropagation.cpp` | Forward taint (seed at `@cq_theta`, sink at `@cq_measure`, skip arg-1 angle) + collection-time `cq_*` prototype validation + `declineTaintEscapes` (unknown call/store/other) + `declineClassicalMuxes` (live select/phi over tainted data; one-register merge-phi lift) |
| `ir-pass/src/RotationLowering.cpp` | `theta → cqrt_alloc_<W> + cqrt_ry_<W>` (qubit allocation point); `phi → cqrt_rz_<W>`; RAUW result to the `i32` handle |
| `ir-pass/src/OpcodeLowering.cpp` + `Arith/Compare/Cast` | Tainted `add/mul/icmp/fcmp/cast/fneg → cq_template_*`; up-front cast-width capture before RAUW |
| `ir-pass/src/OpcodeSupport.cpp` · `TemplateName.cpp` · `WidthDispatch.cpp` | Supported-set/commutativity/predicate policy · symbol-string grammar · suffix→width + lazy `FunctionCallee` minting |
| `ir-pass/src/MeasureLowering.cpp` | `@cq_measure_<sfx> → cqrt_measure_<W>` |
| `ir-pass/src/ControlDetect.cpp` · `ArmClassify.cpp` · `SwapRouteEmit.cpp` · `RegionFlatten.cpp` · `ClassicalCallArmEmit.cpp` · `include/ControlPlan.h` | Swap-route control: region detection (declines what it can't prove) · arm/condition classification + tainted-angle/stale-condition guards + the 6.5 `classifyClassicalCallArm` · routed phase-arm emission · CFG flattening · the 6.5 hoist+controlled-copy merge (`emitClassicalCallArmRegion`) · populated region plan |
| `ir-pass/src/OpcodeLowering.cpp` (`declineStaleRecordOps`) · `WireWalk.{h,cpp}` | Pass-wide stale-record guard (tainted pure op scheduled past a non-diagonal wire gate → loud decline) · shared forward in-place-gate wire walk (position-free and position-aware modes) |
| `ir-pass/src/Uncomputation.cpp` · `ChainWalk.cpp` · `DagTraversal.cpp` · `FreePoint.cpp` · `EmitInverse.cpp` | Whole-DAG LIFO uncompute spine (runs last): terminal selection · whole-DAG recovery · post-dom free point · reverse-program-order void `_unc` adjoint + `cqrt_free`; compares decline loudly (no `_unc` grid) |
| `runtime/cq_runtime.{h,c}` | Hand-written `cqrt_*` core ABI (trace-only) |
| `runtime/cq_templates.{h,c}` | **Autogenerated** `cq_template_*` bodies — edit `tools/opcode_table.yaml`, not these |
| `include/CQ.h` | User-facing intrinsic surface (14 types × 3 families via `_Generic` + `cq_invert_*`) |

**Docs map:** `ROADMAP.md` (plan of record) · `docs/frontend.md` (intrinsic
surface) · `docs/backend.md` (IR pass + runtime ABI) ·
`docs/quantum-classical-handling.md` (taint as the Q/C boundary; mixed-operand
semantics) · `docs/design/rssa-swap-control/{OVERVIEW,SCOPING,MINT_AT_COMPARE}.md`
(the control design + the `prototype_semantics.py` / `clearance_derived_base.py` /
`investigation_mint_at_compare.py` oracles) · `docs/llvm-implementation.md`
(stock LLVM-19 C++ APIs) · `docs/prd/` (per-phase PRDs) ·
`docs/archive/old-design/` (retired design — reference only).
