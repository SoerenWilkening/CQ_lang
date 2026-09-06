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
> sim-replay-verified; the shipped fence is **E1–E15** (`grep -o '(E[0-9]*)'
> `ir-pass/src/LoopLowering.cpp`), grown by **13 recorded over-accept holes** — 7 in the
> Inc-2 round, **3 more in the `rwou` round that ran AFTER this epic was already closed as
> "Rule-13 cleared"**, and 3 Risk-4 recognizer fixes — across **three** adversarial Rule-13
> rounds; 2026-06-26). That 3-for-3 hit rate across successive rounds, including one round
> *after* clearance, is the load-bearing fact when scoping any further loop work: assume the
> next loop shape also hides over-accepts, and budget the adversarial rounds up front.
> **It is now 4-for-4:** the first adversarial round on the 7.3 Inc-3 in-loop-control
> commit (`ba35c1f`, bd `8h7d.5`) found a confirmed silent miscompile in it *plus* an
> older one of the same class in round-1 Case A that had shipped since Increment 1
> (bd `test_C_libtooling-5sva`) — see the in-loop paragraph below. Both were
> verify-clean, golden-clean and stage-2b-clean.
> **"DONE" here
> means the scoped CORE increments shipped + Rule-13-cleared; everything outside the
> shipped accept-shape declines loudly (Prime Directive), so the open follow-ons are
> additive coverage / deferred separate capabilities, NOT correctness debt.** The
> post-core break/loop widenings (multi-break, nested-loop break, `continue`, mixed
> break+return, static-K unroll, value-arm widening) live under the open 7.x-widenings
> tracker `8h7d` (7.2–7.4 themselves add no frozen symbols, but `8h7d` is no longer
> wholly freeze-orthogonal: the **fp-DATA select un-staging** under it — kjd1, DONE
> 2026-07-02, `docs/prd/phase-04-swap-route-control/fp-data-select-PRD.md` — added the
> frozen-designate `cqrt_copy_f{16,32,64,80}_controlled` family, minted ONLY by the
> select-local `copyControlledFpFn`; the shared `copyControlledFn` integer null-fence
> is untouched — it IS the 6.5 classical-call arm's live fp classifier, and every
> non-select fp-under-control path still declines). **Phase 7 core
> complete (7.1–7.6 core DONE; widenings tracked under `8h7d`);** 8–11 remaining.
> **Roadmap resequenced 2026-06-19:**
> Phase 7 is now **pre-freeze expressiveness completion** (7.1 opcode-surface
> completion incl. Q+Q data compare + wide integers `__int128`/`_BitInt`; 7.2
> controlled function-`return`; 7.3 bounded loops; 7.4 `break`; 7.5 QRAM full
> Shadow model); manual inversion (`cq_invert`) moved to **Phase 8**; runtime
> templates / integration / freeze are **9 / 10 / 11**. The freeze is gated only
> on the 7.5 QRAM memory ABI, the 7.1 wide-integer widths, the 7.6 I/O
> output-tape ABI (`cqrt_tape_alloc` / `cqrt_tape_write_<W>` (+ `_controlled`)), the kjd1 fp select
> copy family (`cqrt_copy_f{16,32,64,80}_controlled`), and the drbq control-in-place
> rotation family (`cqrt_ry_<W>_controlled` ×9, a Phase-4 extension —
> `control-in-place-PRD.md` §5) — the control/loop work (7.2–7.4)
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
`cq_phi` is **REGISTER-FREE** — `void cq_phi(double θ)`, a BRANCH PHASE with no
data operand — so it neither introduces taint nor propagates it, and there is
nothing to propagate *through* (bd `test_C_libtooling-3qlq` Inc 1, D1; under a
tainted condition it lowers by kickback onto the condition flag, and
uncontrolled or classically controlled it is a global phase and is DELETED, D2
— `docs/frontend.md` §3.3, `docs/backend.md` §6.1a). ⚠ The pre-3qlq reading —
"`cq_phi` (Rz) propagates taint but never introduces it (deleted on classical
operands)" — described a `cq_phi_<sfx>(x, φ)` operand that no longer exists;
read it only as history. **The angle operand of a rotation is classical** —
arg-1 for `cq_theta`, arg-0 (the only operand) for `cq_phi`. Never propagate
taint through it; a quantum-derived angle is a loud decline
(`cq rotation lowering: unsupported quantum-derived rotation angle`, or
`cq controlled lowering: rotation angle under quantum control` inside a tainted
region). For `cq_theta` the exclusion is **per-operand-use, not global** (a
value also used as an arg-0 handle stays tainted); `cq_phi` has no such case,
having no handle operand. Never allocate a qubit for an angle or coerce it to
an `i32` handle — that is the f64/angle miscompile family.

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

**Rule 7 — Method matches arm class.** ⚠ **SHIPPED 2026-09-05 (bd
`test_C_libtooling-3qlq.2`, Increment 1): the phase-arm gate is the register-free
KICKBACK `cqrt_rz_i1(f, θ)` on the FLAG — no gate on `q` at all, no
`cqrt_rz_<W>_controlled`, no route — because the per-qubit Rz this rule describes
is not an oracle; see the Inc-1 record in the Correctness-Risk section. The
kickback is now the phase-arm lowering at EVERY site: the flat diamond/if-else, the
folded angle select, the compound condition tree, the depth-2 NEST and the `switch`
— the last two USED to keep the route and no longer do (`NestedRouteEmit.cpp` is
DELETED; `SwitchRouteEmit`'s phase path mints a kickback gate). Everything below
about the phase arm's gate describes the pre-3qlq generation and is kept as
HISTORY, not as instruction; the Ry and value halves are unaffected, and the route
survives only for VALUE arms (Increment 2, not landed).** **Phase arms** (`Rz` =
`cq_phi`) keep the
answer (a phase) **in place on `q`**, and the data-derived flag is stripped by the
**uncontrolled** `icmp_inv(q)`. **The arm gate itself is now ONE
`cqrt_rz_<W>_controlled(f, q, θ)` on the FLAT `emitRegion` path** (bd
`test_C_libtooling-drbq` Inc 2a, 2026-09-02 — the §6a control-in-place peephole,
default-on; ⚠ HISTORY since 3qlq Inc 1, 2026-09-05 — that gate is no longer
emitted anywhere, and `cqrt_rz_<W>_controlled[_inv]` is a DECLARED-BUT-UNEMITTED
symbol): no work rail, no `cqrt_cswap` route, so the old "**zero controlled
gates**" is **no longer true there** and must not be quoted as a phase-arm
invariant. ⚠ The sentence that used to follow — "it still holds verbatim for the
shapes that KEEP the route, the 4.3 depth-2 nest and the 4.5 switch, where the rail
is `|0⟩` for free (`Rz|0⟩ = |0⟩`) and freed clean" — is **FALSE since 3qlq Inc 1**
in both halves: those two shapes no longer route a phase arm, and `Rz|0⟩ = |0⟩` is
retired as a load-bearing argument precisely because it is what makes a per-qubit
Rz not an oracle. The two forms are the SAME unitary, not an approximation:
`cswap(f,q,w)·Rz_w(θ)·cswap(f,q,w)` with `w = |0⟩` equals `cRz(f,q,θ)` exactly
under the project's `Rz = diag(1,e^{iθ})` convention (no global-phase residue).
**Inc 2b (2026-09-03) adds a SECOND way that same controlled gate is reached** —
`if(c) r=R(r,A); else r=R(r,B);`, which `clang -O1` folds to ONE call with an
angle `select`, lowers BY DIFFERENCE to `R(h,B)` unconditional + one
`R_controlled(f,h,A−B)`. Same gate, same flag mint and strip, no route and no
`cqrt_x`; exact in REAL arithmetic by angle additivity on one axis, for both
stems — but **NOT in IEEE double**, and that distinction is a round-1 Rule-13
finding, not a footnote: the emitted true-arm angle is `B + fl(A−B)`, so
`|δ| ≤ ½ ulp(A−B) ≈ |A−B|·2^-53`. That is 2^-54 rad on the flagship `0.9/0.3`
golden and **0.858 rad on `π/1e16`**, which the pre-2b binary declined loudly.
CONSTANT arms are therefore fenced at a **placeholder** `2^-40` rad
(`kAngleSelectMaxRoundingRad`, on the owner's desk — see the notes §9 item).
**RUN-TIME arms DECLINE — the accept class is CONSTANT arms only**, and the two
review rounds that said otherwise are corrected rather than deleted (round-2
Rule-13 review graded the run-time half CONFIRMED-MISCOMPILE and the disposition
then was "stay accepted, document the residual"; the independent Rule-13
**CLEARANCE** review ranked it a **BLOCKER** — finding F-11 / B1 — and the owner
decision is option (2), narrow to constants; notes §11). The two halves are now
the REASON for the refusal: (i) the rounding `|δ| ≤ ½ ulp(A−B)` bounds the
*difference* and is **unbounded in absolute radians** — measured **0.858 rad from
plain C** with `π`/`1e16` as run-time angles, i.e. `Ry(π)` realized as `Ry(4.0)`;
and (ii) a **non-finite `fl(A−B)` from two FINITE arms**, measured
`cqrt_ry_i32_controlled(f, h, inf)` from `±8.99e307`. Neither is fenceable at
compile time, and the mitigation the earlier disposition rested on is false: "it
is the same arithmetic the manual twin performs" is true of the *arithmetic* and
false of any *program CQ compiles* — that twin, with run-time arms, declines
`control flow` on **both** binaries (`clang -O1` sinks the `fsub` into the arm
block), so the class was reachable **only through 2b**. All six plain-C
reproducers now emit stderr **byte-identical to the pre-2b oracle**. Widening back
is owner option (1), ONE line at `angleSelectArmsAdmissible` clause (2c); option
(3), the two-controlled form, performs no subtraction at all and is exact for
run-time arms too (PRD §12.3, notes §9/§11).
What is still dropped is **method-A** controlled-adjoint *rail cleanup*
(2026-06-09) — a different thing from controlling the arm gate in place, and the
reason it was dropped ("if you would emit a controlled gate to clean a rail, you
could have controlled the op in place from the start") is exactly what Inc 2a
acts on. Classical-permutation /
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

**Rule 18 — A library function means its SOURCE, injected.** Compiling a
`math.h`/libc function ALWAYS means compiling with its real implementation
**injected as source** (an openlibm-style soft-body llvm-linked + inlined
*before* `cq-lowering`; caller `-fno-builtin-<fn>` so the named call resolves to
the body) so the taint pass sees stock **opcodes**. Library-function coverage is
measured **only** by source injection — **never** by recognizing `@llvm.<fn>` /
`@<fn>` by name and emitting a per-fn `cq_template_<fn>`. That name-recognition
path is **fiction**: once the source is injected the named call is inlined away,
so the recognizer never fires (this is why the old `math.h` 165/174 "95%"
overclaimed — measured recognition, not injection). *Note precisely what was
wrong with it, because a labelled whole-surface TOTAL is now published (the
2026-08-22 headline ruling under the CQ-PROVIDED amendment below): `165/174` was a
**mislabelled** number — recognition counted **as** injection. The headline total
is a **labelled** one, printed with its composition and never called injection.*
The **sole exception** is an
**in-grid IR construct CQ recognizes before codegen that Bennett.jl backs** — it
has no injectable body and is lowered directly. The keep/cut line is **testable
and target-dependent** (measure, never guess — Rule 11) and needs **BOTH**
conditions: **(1)** `clang -O1` on `T f(T x){return f(x);}` folds the call to a
hardware instruction, an inline opcode sequence, or a recognized `@llvm.<fn>`
intrinsic **before codegen** — the operative test is the *IR construct the pass
sees*, **NOT** "no `call`/`jmp _<fn>` in the final asm" (the l-suffix rounders
`rintl`/`nearbyintl`/`truncl` emit `callq _<fn>l` at f80 codegen yet are keeps
because CQ intercepts `@llvm.{rint,nearbyint,trunc}.f80` first — the `floor.f80`
precedent); **and (2)** Bennett.jl ships a reversible gate sequence for that
construct (so a Phase-9 backend has a source), else it is a parity-*inversion* we
cannot realize and it **declines**.
**Condition (2) means a CONCRETE gate sequence — a K-parameterized unroller is
NOT one** (owner decision 2026-07-27). Bennett's data-dependent-trip *loop*
support is a family of circuits indexed by a user-supplied `max_loop_iterations`:
`for _iter in 1:K` with the back edge removed (`src/lowering/cfg.jl:219`),
refusing to run without K (`driver.jl:80-83`), with **zero** static trip-count
inference anywhere in `src/`, and whose only correctness witness is a convergence
wire read at **simulate time over random probe inputs**
(`simulator.jl:215-223`) that `reversible_compile` never even invokes. CQ has no
simulator and will not get one (Rule 2, owner decision 2026-06-10), so that
witness is structurally unavailable to us. **A construct whose realization
depends on an unverifiable parameter does not satisfy condition (2): it is a
parity inversion and it declines.** This is not a cost judgement — it is the
keep/cut line, and it applies to *every* data-dependent-trip library body
(the `fmod`/`remainder`/`remquo` family, Payne–Hanek `rem_pio2`, and any future
one). Note the contrast that makes the line coherent: Bennett's **fixed**-trip
branchless kernels *are* concrete gate sequences (e.g. the 64-iteration restoring
divider `src/divider.jl:22-36`), which is why a bounded, statically-known trip
count stays in scope while a quantum-dependent one does not (**narrowed
2026-08-21 — read that clause with the NARROWED paragraph below**). Scoped,
measured and recorded in
`docs/prd/phase-07-expressiveness/SCOPING-L3-data-dependent-trip-loops.md` and bd
[`l3-quantum-trip-loop-verdict-2026-07-27`]. **The line was sharpened by owner
ruling 2026-07-28 on the one cell it did not cleanly reach (`logbl.f80`): a
quantum-dependent trip count is out EVEN WHEN the loop recurrence is purely
classical** — *as ruled 2026-07-28; **NARROWED 2026-08-21**, below, and never
quotable without it.* That cell measures as the best possible case for the other
reading —
back-edge excision makes it lower *completely* (`opt` exit 0, verify-clean, zero
residual `@cq_*`, **no deeper layer at all**), and its loop-carried values are a
counter and a shift register, so no dirty rail crosses the back edge and Rules 6/8
are untouched; only the trip count is quantum. It still declines — and the
cleanliness of the loop body never enters the test. **Two corollaries
worth carrying:** the ruling is about the CONSTRUCT the pass sees, so it says
nothing about a library body reached by *source injection* — for those,
Bennett-backing is owed by the **opcodes the body decomposes into**, not by a
`soft_<fn>` of the same name (the `lgamma`/`tgamma` mistake — bd
[`bennett-grounding-asymmetry-2026-07-28`]); and a decline ruled on these grounds
is a **parity** wall, never a **physics** one, so it must not be quoted as
"impossible" (the census records it as `scope: decided-decline` with its re-opening
condition — **or, once a later ruling changes that ground,
`deferred-capability`**; bd [`libm-census-scope-axis-2026-07-28`], which the
2026-08-21 ruling says is **not quotable un-narrowed** — see below).

**NARROWED by owner ruling 2026-08-21 (bd `eyhj`) — to a DERIVATION, never a
parameter — and the narrowing is RULED BUT UNBUILT.** The 2026-07-28 test above was
"the **trip count** alone"; it is one clause short. **A quantum-dependent trip count
is ADMISSIBLE when the compiler PROVES a quantum-independent upper bound `B` from the
IR in front of it and emits the loop ROLLED at classical trip count `B`, with the body
predicated on a quantum still-running flag. Failure to derive `B` is a loud decline.**
Why a *derivation* and never a cheaper `K` — this is the whole safety argument: a
parameter can be wrong and still compile, whereas a derivation that fails to derive
**stops the compiler**, so an undersized bound becomes **UNREACHABLE** rather than
**UNDETECTED**. That asymmetry is load-bearing because **neither shipped gate can see
an undersized bound** — the golden byte-diff records a gate stream self-consistent
under whatever predicate was chosen, and `free_pairing_check.py` witnesses rail
*pairing*, which stays clean; an undersized bound is a verify-clean silent miscompile,
definitionally. So a user-supplied `K`, a `name → K` table, a flag that *supplies* `K`,
and an **offline-measured** `K` are all still refused on that one ground (the last
specifically because a classical run samples the **guard-admitted** domain while the
emitted circuit runs the **unguarded** one — PredMux removes every guard — so more
samples do not converge on the right answer), and **Bennett's user-`K` refusal above is
untouched**. Nor does this weaken condition (2): a *derived* `B` makes the emitted
circuit a **fixed-trip** `B`-iteration circuit, the same shape as Bennett's
64-iteration restoring divider, which the line above already admits. *(That reading is
analytic — the Bennett checkout was **absent when last measured (2026-08-22)**, so
condition (i) is **unmeasurable** for this family and must not be asserted as checked.
Re-measure before relying on it: restoring the checkout silently falsifies this
sentence.)*

> **DO NOT QUOTE THIS AS A CAPABILITY — NOTHING IMPLEMENTS IT, and Rule 18 is prose,
> not a fence.** At HEAD `LoopLowering.cpp`'s Q1 quantum-bounded-exit decline is intact
> and unconditional (`tryCaseA`'s L1: `taintedExit` ⇒ `diagnoseUnderControl(TE,
> "loop")`, checked FIRST), and **no bound derivation for a quantum-trip loop exists
> anywhere in the pass** — `hasFiniteClassicalTripBound` is the 7.4 `break` path, which
> requires a **classical** bound already present in the exit condition, and is not
> this. So **no quantum-dependent trip count is LOWERED AS A LOOP today** — `tryCaseA`'s
> Q1 declines every one that reaches `lowerLoops`, exactly as before the ruling.
> *(State it that way and never as "they all decline": `CtlzIdiomPrepass` — bd `ww4c` —
> claims shift-count loops whose exiting condition **is** tainted and COMPETES WITH Q1
> for them, but it wins by **erasing** the loop and substituting a closed form of fixed
> gate count before `lowerLoops` runs. That is a **value** substitution, not a bound:
> no `B` is computed, no loop survives, no still-running flag is minted.)* The
> implementing increment (bd `m57l`) is **DEFERRED with no customer**: the two cells it
> was scoped for — `ilogb.f64`, `ilogbf.f32`, 98 → 100 — were taken by that recognizer
> instead. **The narrowing's marginal payoff at HEAD is therefore ZERO cells.**
> Building the fence is Rule-12 red-green **plus** Rule 13, with the five measured
> conditions as its decline partition — constant ∧ non-negative ∧ small ∧ reachability-**total** ∧
> `1 ≤ shift-amount ≤ W-1`, the constant-max BTC read as an **APInt at its own width**,
> every one of them a measured over-accept hole (C1–C4 on real census loops, C3 and C5
> on committed constructed controls in `loop_bounds/probes/opaque_control.ll`, since
> neither ever bound a classification on the census itself — `isa<SCEVConstant>` alone
> over-accepts **30 of the 49** loops it takes; worst bound 4294967295 trips, and
> `getSmallConstantMaxTripCount` returns `4294967295` on some vacuous bounds and `0` on
> others, so neither return value distinguishes vacuity in either direction). Until
> that fence exists, this paragraph licenses **nothing**.

**What the 2026-08-21 ruling changes is one cell's GROUND, not any verdict.**
`logbl.f80` above keeps its decline and loses its reason: it declines because SCEV
reports `CouldNotCompute` on both its loops under **12 measured `opt` pipelines**
(incl. `default<O2>`/`<O3>`) and on the post-`promoteFp80Union` module, and its rotated
body genuinely does not terminate on 2 of 2^32 inputs — **not** because its trip count
is quantum. *(Say "12 measured pipelines", never "every pipeline": the sweep is a
finite measured set whose raw artifacts are not committed, and a universal quantifier
over an unmeasured set is the fenv failure mode above.)* It and `ilogbl.f80` are
accordingly recorded `scope: deferred-capability` (bd `ywws`), **not**
`decided-decline`, and this paragraph exists so `CLAUDE.md` stops asserting a ground the
census has already retired (`full_surface/full_census.py`: *"the 2026-07-28 ruling no
longer grounds ANY of these four"*). The `fmod`/`remainder`/`remquo` nine and the
Payne–Hanek nine are **unmoved** — bd `19v3` measured the whole census surface
(2026-08-21, **pre-`ww4c`**: its §1 gate table counts Q1 at 10 cells and multi-site at
3, which the census now reads as 6 and 5, because `ww4c` moved `fmod.f64` and
`remainder.f64` to a later first blocker at identical status), not one family.
**State those eighteen as CELLS, never as one block** — "all 18 data-dependent-trip
cells decline" is FALSE: **12 decline** (the `fmod` nine + `sinf`/`cosf`/`tanf`.f32)
and **6 already COMPILE** (`sin`/`cos`/`tan` at f64 and f80, which are CQ-PROVIDED, so
upstream's un-injectable body is never injected and their `decided-decline` survives
only as `upstream_scope`). Recorded in bd
[`narrowed-quantum-trip-rule-2026-08-21`]; measurements in
`docs/prd/phase-07-expressiveness/SPIKE-19v3-loop-bound-population.md`.

On x86-64+SSE4.1 the keep-set is
`sqrt fabs copysign floor ceil trunc round rint nearbyint fmin fmax fma/fmuladd
lrint llrint` (+ the non-`math.h` integer bit-intrinsics), **all Bennett-backed**
(soft-float `soft_round`/`soft_trunc`/`soft_floor`/… + hardware ops; Bennett's
SoftFloatLib is **f64** — the `.f80` rounder variants are that same algorithm
**widened**, CQ's standing width parity-inversion per Rule 15, unlike `frem` which
has **no** Bennett algorithm at any width to widen); everything
else (transcendentals, `pow`, all direct-libm, by-ref `frexp/modf/remquo`,
`lround/llround`) is a library function and **declines** without injection.
**`fmod`/`fmodf`/`fmodl` are NOT keeps** despite folding to the in-grid `frem`
**opcode** (condition 1 holds): Bennett ships **no** `frem`/`fmod` gate sequence
(condition 2 fails — its only `frem` token is an error-string entry; `frem` is a
CQ recognizer parity-*inversion*, tracked separately), so `fmod` stays a
declining library cell (bd `fmod-frem-keep-2026-07-24` / `3c6m.56`). See
`docs/prd/phase-07-expressiveness/p119-libm-coverage-honesty/PRD.md` and bd
[`libm-coverage-source-injection-rule`]. This **retires** the per-fn
name-recognition of library functions (the old `3c6m.2` direct-libm matcher and
the `iw81.4.b` transcendental-intrinsic rows).

**AMENDMENT — the CQ-PROVIDED set (owner ruling 2026-07-31, bd `guwr`).** The
keep/cut line above admits a **third** category beside *recognition* and
*injection*: a function whose implementation **CQ itself ships**. The rationale is
that Rule 18's two conditions are independent, and for the trig family only
condition **(1)** fails: Bennett backs `sin`/`cos`/`tan` with a **concrete
branchless** gate sequence (re-verified at rev `e15ea23` — `soft_sin`
`src/softfloat/fsin.jl:683`, `soft_cos` `:739`, `soft_tan` `ftan.jl:200`,
`_rp_paynehanek` `:468`; zero `for`/`while`, ≤2 ULP), so condition **(2)** holds
*robustly* — what is ruled out is only openlibm's **source form**
(`k_rem_pio2.c`'s nested data-dependent-trip loops). The precedent is already in
the tree: the hardware keep-set is never injected, and an injected body that
**calls** a keep-set fn still counts as injection-covered (`keep_shims()` in
`tools/library_coverage/full_surface/wprobe.py` — this is exactly why `ceil` does
not block `tgamma`). Extending that set is structurally the same move.

**The rule stays extremely strict everywhere else.** Admission to the CQ-provided
set requires **ALL THREE** of the following **plus an explicit owner ruling per
function**. It is **not** developer discretion and **not** an escape hatch — Rule
17 posture applies verbatim (a decline is not the development escape hatch, and
neither is authoring a leaf instead of doing the lowering):

- **(i)** Bennett ships a **concrete branchless** gate sequence for it —
  condition (2) above, **unchanged**; a K-parameterized unroller is still **not**
  one.
- **(ii)** CQ itself ships a **verified branchless implementation with a
  committed e2e golden AT THAT WIDTH**. This is checked **mechanically**, never
  asserted: the leaf `tools/library_coverage/branchless/<spelling>.c`, the slice
  `tests/e2e/slice_branchless_<spelling>.c`, its `.expected.log` golden, and its
  `tests/e2e/CMakeLists.txt` registration must all exist, and the leaf body must
  not have **drifted** from the slice the golden pins.
- **(iii)** it is recorded as **CQ-PROVIDED** and **NEVER merged into the
  injection number** (bd [`libm-scoreboard-two-numbers`] — now *three* numbers).
  **This bullet is UNCHANGED by the 2026-08-22 headline ruling below** — the
  *injection* number stays pure. What that ruling adds is a **separate, labelled
  TOTAL**, not a bigger injection row.

**HEADLINE — the whole-`math.h` total is now the number we quote (owner ruling
2026-08-22, bd `fhas`).** Previously a merged headline was a documented **bug**
here, and the ruling it replaces was right about a real hazard: the retired
`165/174` (95%) claim is what merging produced. The owner asked for the merged
number anyway, so the published headline is now **`math.h` coverage: 159/183 cells
(87%)** — composed of `101/120` injection + `6/6` CQ-PROVIDED + `42/42` recognition
keep-set + `10/12` type-generic macros + `0/3` by-design `nan`. *(Those figures are
**as measured 2026-08-23** and are the only hand-written copy of them in the tree —
every PUBLISHED occurrence is generated from `probe.mathh_union_scoreboard()` into a
marked region. If this paragraph ever disagrees with `README.md`, believe the
generator and fix this line.)*
**They were `158/183` and `100/120` at the ruling (2026-08-22) and moved DOWN by
three on 2026-08-23 — bd `3c6m.63`, and the direction is the whole point.** The
census corpus was building ten openlibm TUs from `ld80/` whose basenames also exist
in `src/`, and openlibm's own build **excludes all ten**, so `nextafterl.f80`,
`nexttoward.f64` and `nexttowardf.f32` were scored `COMPILES` on **a program that
ships nowhere**. Correcting the corpus flipped exactly those three (plus
`nexttowardl.f80`, which was never the corpus gap it was recorded as — openlibm
mints it by `strong_reference` from the same file), with 120 cells byte-identical.
**No compiler capability was lost; the number stopped measuring the wrong program.**
This is the retired `165/174` error class caught again, and it took one of the
campaign's own recent `+1`s with it (bd `k710`'s `nexttowardf.f32`, 97→98 — its
write-only `volatile` idiom is not in the shipped body; the **fenv ruling and
`eraseDeadVolatileScalarStores` are unaffected**). The recipe is now an executable,
self-checking script (`tools/library_coverage/full_surface/build_corpus.py`) and a
new gate (`e2e-census-slice-sync`) stops the e2e goldens drifting out of step with
the census.
**AND THEN THE SAME DAY THEY MOVED BACK UP BY FOUR — `159/183` and `101/120`, bd
`3c6m.67` — WHICH IS A DIFFERENT KIND OF CHANGE AND MUST NOT BE NETTED AGAINST THE
`-3`.** The `-3` was a **correction**: a number that had been measuring a program
that ships nowhere. The `+4` is **compiler work**: all four cells — `nextafterl.f80`,
`nexttowardl.f80`, `nexttoward.f64`, `nexttowardf.f32` — declined on ONE construct,
the ulp-direction test `if((x>0.0) ^ (x<y))` at `src/s_nextafterl.c:55` and
siblings, i.e. an `xor i1` of two tainted compares used as a **branch condition**.
Two condition-tree recognizers whitelisted and/or-over-compare-leaves and neither
admitted a two-operand xor; **no rationale for the exclusion was ever recorded**, in
a function that documents its other fences at 25 and 20 lines apiece. It was an
absence of a decision that hardened by repetition — the same failure mode as the
pre-ruling `fenv` prose above. Admitting the node (it emits `cnot(L,G); cnot(Rv,G)`
onto a fresh `|0⟩` ancilla — the OR node **minus** its toffoli, so strictly fewer
gates and no new frozen symbol) cleared all four, each with a committed ship-floor
golden. *Note what the two moves do NOT do together: `-3` then `+4` is not "+1". The
covered SET changed twice for unrelated reasons, and quoting a net would hide both.*
**Three conditions make it honest, and they are not optional:**
**(a)** the **composition is printed with the total, every time** — a total without
it is the retired overclaim wearing a new denominator;
**(b)** the total is read as *"CQ compiles 158 of the 183 modelled `math.h` cells"*
(**true** — a user calling `sqrt()` gets a real lowering) and **never** as *"CQ
compiled openlibm's body 158 times"* (**false** — 42 cells have **no injectable
body at all** and 6 use **CQ's own leaf**);
**(c)** **the campaign number for COMPILER progress remains the injection row
alone** — rows (1) and (3) move with no compiler work, so quoting the total as
progress would be the `165/174` error again.
It is **computed, never hand-copied** (`probe.mathh_union_scoreboard()`; the bd
`5ft3`/`aik2` lesson), and **-3** if `fma{,f,l}`'s *partial* cells are excluded.

**Day-one consequence, measured:** exactly **6 cells** qualify — `sin`/`cos`/`tan`
at f64 and `sinl`/`cosl`/`tanl` at f80 — and `sinf`/`cosf`/`tanf` are **rejected**
because no leaf exists at f32 (bd `eur4`). A change that "covers" 9 has broken
condition (ii).

**Mechanism — this is the whole design.** CQ ships its own reversible libm
source, and for the admitted set the pipeline **injects CQ's leaf instead of
upstream's body**. Everything stays inside the existing injection machinery:
**no new recognizer, no per-fn `cq_template_<fn>`, no new frozen symbols.** Do
**NOT** build a name recognizer — this Rule calls that path *fiction* and
explicitly retires it. The **only** thing that changes is *which source is
injected* for the named functions. That is also what makes the honesty claim
defensible: "CQ ships its own reversible `sin`" (what openlibm is to a C
compiler), **not** "CQ compiled openlibm's `sin`".

**GATE WORDING — "9 cells" IS A TRIPWIRE, NOT A CAP (clarified by owner ruling
2026-08-10).** The ruling is **per FUNCTION (stem)**; condition (ii) is
**mechanical and per WIDTH** (`probe.cq_provided_cells()` measures leaf + slice +
golden + whole-token ctest registration + `_leaf_in_sync` on disk — deliberately
never a hand-maintained spelling list, because a hand list is how "verified at
that width" rots into an assertion). So the earlier phrasing "a change that
'covers' 9 has broken condition (ii)" must be read as: **9 reached WITHOUT three
new genuinely verified f32 leaves and goldens** means condition (ii) has broken.
Read literally it forbade bd `eur4` from ever succeeding, which was never the
intent — `eur4` authoring real f32 leaves takes the count 6 → 9 **legitimately**.
Note what `eur4` is worth, so it is never mis-quoted: `sinf`/`cosf`/`tanf` are
**declines** today, so admitting them leaves the injection **numerator at 97** and
shrinks its denominator — pure row-3 movement, **never** injection progress.
*(Both `97` figures in this and the next paragraph are **as-of-2026-08-10**, the
numbers those two rulings were computed on. The campaign number went 97 → 98
(`k710`) → 100 (`ww4c`) → **97 on 2026-08-23** (bd `3c6m.63` retired three
cells measured on a body openlibm does not build, `k710`'s among them) → **101 the
same day** (bd `3c6m.67`, the xor condition-tree widening, which took those same
three cells back on the bodies openlibm DOES build, plus `nexttowardl.f80`). The
momentary return to `97/120` was a **coincidence of arithmetic, not a
restoration** — the denominator really is the same 120, but the covered SET was not:
that 97 was 2026-08-10's **minus** `nextafterl.f80` and `nexttoward.f64`
**plus** `ilogb.f64` and `ilogbf.f32`. Never diff two of these by their level. The
rulings' **arithmetic and conclusions are unchanged** by any of it, because both turn
on a **difference**, not a level; the figures are deliberately left as ruled rather
than silently restated.)*

**DECLINED 2026-08-10 (owner ruling): the `log` stem / `logl` spelling are NOT
admitted.** Measured, not argued: `log.f64` and `logl.f80` **both already pass
condition (ii) on disk AND are both already `COMPILES` by real openlibm
injection**. Admitting the stem therefore moves two *covered* cells out of the
injection row to buy one (`lgammal.f80`), taking the campaign number **97 → 96**;
even the `logl`-only variant is **flat, not +1** (a survey claim of "+1 injection
cell, the cheapest lever on the list" was wrong on this arithmetic). More
fundamentally the amendment's *grounding* does not reach `log`: CQ-PROVIDED exists
because openlibm's **source form** is un-injectable (trig's Payne–Hanek
`k_rem_pio2.c`), whereas `log`'s source form works and is injected **today** —
admitting it would trade the true claim "CQ compiled openlibm's `log`" for the
weaker "CQ ships its own `log`". `lgammal.f80` is to be **re-scoped** instead; its
census `scope_ref` already self-flags its decided-decline ground as SPENT.

**Rule 19 — Run what can WITNESS the change; the full suite is a GATE, not a
heartbeat** (owner ruling 2026-08-13). The default inner loop is **targeted**:
run the layer that can actually observe what you edited, and nothing else. The
full suite is expensive attention as much as expensive wall-clock — a 3-minute
run after every keystroke trains you to skim its output, which is how a real red
turns into "probably contention". Measured inner-loop costs, all on a quiet box:

| you edited | run | cost |
|---|---|---|
| one `.ll` fixture | `cd build && lit ir-pass/test --filter '<name>'` | **1.5s** |
| one e2e slice or its golden | `ctest --test-dir build -R '^e2e-slice-<name>$'` | **1.7s** |
| `tools/opcode_table.yaml`, `runtime/*` | `ctest --test-dir build -R runtime -j6` **+** an e2e slice (the only layer that LINKS) | **~5s** |
| `include/CQ.h` | `ctest --test-dir build -R frontend-lit` **+** e2e | **~5s** |
| pass source, iterating | `ctest --test-dir build -R ir-pass-lit` | **~60–105s** |
| docs / comments only | nothing | 0s |

**The full `ctest -j6` is MANDATORY, no judgement call, at these five moments:**
1. **Before any commit touching the Rule-13 lowering core** (`TaintPropagation`,
   the swap-route / control emitters, `FreePoint`, `EmitInverse`, `ChainWalk`,
   `Uncomputation`, `RotationLowering`). Rule 13 is untouched by this rule.
2. **Before `git push` / at session end**, whenever the push contains any change
   to code, fixtures, goldens, or the harness — the Session Completion gate. A
   push that is *purely* docs/comments (this file, `ROADMAP.md`, a `//` block)
   does not need it; that is the one case where the docs-only row above wins.
3. **After any change to the harness itself** (`run_slice*.sh`, any
   `CMakeLists.txt`, `lit.cfg.py`, `cq-opt`, the caches). A harness edit changes
   how *every* test runs, so no subset can witness it. This is not theoretical:
   a `lit.cfg.py` PATH edit in this repo turned 551 fixtures red in a way that
   read exactly like a lowering regression, and only the full suite caught it.
4. **After regenerating the templates** (Rule 15) — the ABI moved under every layer.
5. **When an accept/decline predicate changed** — Rule 12's probe families live
   across both `ir-pass-lit` and e2e, and a widened predicate is exactly the
   over-accept shape the Prime Directive exists to stop.

**Report only what you ran.** If you ran `ir-pass-lit`, say "lit green (1069)",
never "tests pass" — an unqualified green claim about layers you did not execute
is a false statement about verification, and this project's whole defence is that
verification claims are literal. Same for a sampled gate: say it sampled.

**A skipped layer is a deferred cost, not a saved one.** The full suite is ~5x
cheaper than it was (825s → ~160–200s at `-j6`), so when in doubt about which
bucket a change falls in, just run it — this rule exists to stop reflexive
full-suite runs, not to make skipping the default.

---

## Scope of the semantic model — `fenv` is OUT (owner ruling 2026-08-10)

**CQ does not model floating-point exception flags** (`FE_UNDERFLOW`,
`FE_INEXACT`, the rest of `<fenv.h>`), and **a `volatile` access to a
non-escaping function-local object is not observable** in CQ's model. There is no
fenv concept anywhere in the runtime ABI, the pass, or `CQ.h`, and this ruling
adds **no frozen symbol** — the Phase-11 freeze is untouched.

**Why this needed ruling at all, and the lesson in it.** The sentence "fenv is out
of scope project-wide" has been *shipped source prose* since `eb31e18`
(2026-07-14, `ir-pass/include/QramLowering.h:172`), repeated in
`PRD-3c6m.51.md:231`, and **load-bearing for two stages that already delete
volatile accesses** — `foldVolatileConstGlobalLoads` and
`foldVolatileConstAllocaLoads` (bd `etiq`, which erases the volatile store, the
lifetime markers and the alloca). It appeared in **no** bd memory, **not** in this
file, and **not** in the ROADMAP. It was an agent-authored justification that
hardened by repetition into a de-facto ruling — exactly what bd
[[bennett-grounding-asymmetry-2026-07-28]] warns against. It is now ruled, and the
scope is deliberately narrower than the old prose: **non-escaping locals**, not
"anything volatile". MMIO, external linkage, escaping addresses, and atomics are
untouched and keep their existing loud declines.

**What it licenses — and say it plainly, because the comfortable version is
false.** An operation whose *only* consumer is a store to a never-read
non-escaping `volatile` local may have that **store** removed. **The computation
then usually disappears too, and the ruling accepts that.** For openlibm's
underflow idiom (`volatile float u = x*x; /* underflow */`,
`ld80/s_nexttowardf.c:63`) the emitted circuit ends up with **no multiply at
all** — measured: zero `fmul_f32` in `slice_libm_ld80_nexttowardf`'s trace.

The mechanism is ordinary and pre-existing, not something the k710 stage does:
once the store is gone the `fmul` is trivially dead, and
`PredMuxFlatten.cpp:2618`'s `RecursivelyDeleteTriviallyDeadInstructions` takes
it — a cleanup that exists for a Rule-6/8 reason of its own (a dead *tainted* op
left alive lowers to a forward gate that is never uncomputed and never freed, a
dangling entangled flag). So "we only delete the store" is true of the *stage*
and false of the *pipeline*, and only the second one matters.

> **This correction is recorded because the ruling was first granted on the wrong
> summary.** The claim "the implementation keeps the `fmul`, so nothing the source
> demanded be evaluated is removed" was put to the owner and was an artifact of a
> fixture with **no control flow** — nothing there invokes that DCE path. Owner
> re-affirmed the ruling on the corrected facts (2026-08-10): "fenv is out of the
> model" *means* an operation whose only purpose is raising a flag has no
> observable effect, and unobservable dead code gets deleted. The reassurance was
> the wrong reason for a decision that stands without it.

Note the asymmetry, which is real and worth knowing before reading a trace: with
**no** enclosing tainted control flow the dead product IS lowered, uncomputed and
freed (a useless but harmless gate pair — see
`lowering_volatile_scalar_deadstore.ll`); inside a PredMux region it is deleted
outright. Both are sound here; they are not the same circuit. And the contrast
that makes the whole family legible: the `nexttoward` (f64) and `nextafterf.f32`
slices each keep exactly **one** `fmul` in their committed goldens, because they
**read** the scalar — the multiply is live, and nothing in this ruling touches it.

> **THE RULING STANDS; ITS CENSUS CELL DOES NOT (bd `3c6m.63`, 2026-08-23).** The
> write-only idiom above is `ld80/s_nexttowardf.c`, and **openlibm does not build
> that file** — `CMakeLists.txt:174` names `src/s_nexttowardf.c`, whose scalar `t`
> **is read** (`t = x*x; if(t==x) return t; else return x;`). So the shipped body
> never reaches this path, and bd `k710`'s `+1` for `nexttowardf.f32` is
> **retracted** (the cell declines earlier, on control, at
> `src/s_nexttowardf.c:45:5`). **Nothing about the ruling, the scope of the model,
> or `eraseDeadVolatileScalarStores` changes** — the stage keeps its lit coverage
> and `tests/e2e/slice_libm_ld80_nexttowardf` remains its only e2e witness, which
> is why that slice was renamed out of the coverage namespace rather than deleted.
> What is withdrawn is the *coverage credit*, not the *capability*. Read the
> paragraphs above as being about the idiom, which is real openlibm source either
> way; do not re-cite them as "this is why cell `nexttowardf.f32` is covered".

Note the pre-existing rationale at `QramLowering.h:222-226` — "volatile's only
effect is to defeat FP reassociation, which taint lowering never does" — is
**factually wrong for this idiom family** and must not be cited for it. openlibm's
`volatile` here forces evaluation for the FPU flag, not to block reassociation.
The correct ground is this ruling, not that sentence.

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

⚠ **READ THIS FIRST: every shipped Grover golden is the IDENTITY on `q`, and the
mechanism the rest of this section describes is what made it so** (finding
2026-09-05, `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §1;
bd memory [`grover-goldens-are-identity-tensored-rz-2026-09-05`]). `cqrt_rz_<W>`
is **TENSORED** — Rz on EACH qubit of the register (`docs/backend.md` §11.3,
`docs/frontend.md` §3.2) — so `if (q == 5) q = cq_phi(q, PI)` lowers to
`cqrt_rz_i32_controlled(f, h, π)`, whose marked phase is `(−1)^popcount(target)`
= **+1** for 5 under either Rz convention; and the reflection
`if (q == 0) q = cq_phi(q, PI)` is worse, because a per-qubit **diagonal** gate
FIXES `|0…0⟩` and can never put `−1` there. Nothing caught it and nothing could:
the golden byte-diff proves every symbol resolves and signature-matches, not that
the unitary is right (Rule 2), and there is no simulator (owner decision
2026-06-10) — the traces are self-consistent records of the identity. The
physically correct spelling, the explicit kickback ancilla
`bool m = (q == 5); m = cq_phi(m, PI);` with `m` then dead, **declines** at HEAD
in both measured spellings with `cq uncompute: dead chain would free a measured
register`, so **Grover is not expressible at HEAD by any spelling**. The fix is bd
`test_C_libtooling-3qlq` (PRD D1–D7): `cq_phi` becomes **register-free**,
`void cq_phi(double θ)` = "multiply the CURRENT BRANCH's amplitude by `e^{iθ}`",
lowered by **KICKBACK** — the ordinary flag mint, then `cqrt_rz_i1(f, θ)`
**UNCONTROLLED** on the flag, then the ordinary `_unc` strip (which returns `f` to
`|0⟩` on every branch) and `cqrt_free` — with an uncontrolled or
classically-controlled `cq_phi` DELETED as a global phase (D2, a documented
semantic and not a diagnostic), NO multi-bit Rz at all (D4 — the register-wide Z
rotation is the classical per-bit loop `for (i…) if ((q>>i)&1) cq_phi(θ)`), and
**no new runtime symbol** (D3 — the emitted Rz set SHRINKS to `cqrt_rz_i1`).
Inc 0 is the docs + the `cq_ry` statement macro; the header change and the
kickback lowering are bd `3qlq.2` (Inc 1). **The standing lesson is a
RETIREMENT: "`Rz|0⟩ = |0⟩` for free"
must never again be quoted as a load-bearing argument.** It is cited below and in
the ROADMAP as what makes the phase-arm route junk-free, and it is TRUE — it is
also EXACTLY the property that makes a routed or controlled per-qubit Rz **not an
oracle**, because a gate that fixes `|0⟩` on every wire fixes `|0…0⟩` on the
register. A W-bit "rotation" ABI needs its multi-qubit semantics pinned BEFORE a
control emitter is built on it. Read every "phase arm" sentence in this section,
in Rule 7, and in `ROADMAP.md` as describing the PRE-3qlq generation.

**INCREMENT 1 SHIPPED 2026-09-05 (bd `test_C_libtooling-3qlq.2`) — and the record
that matters is not the feature, it is that TWO adversarial rounds found THREE
CONFIRMED silent miscompiles in it, every one `opt` exit 0, verify-clean, and
STRICT-stage-2b `0 violation(s)`.** What lowers now: `void cq_phi(double θ)` under
a tainted condition is the KICKBACK — the ordinary compare mint, `cqrt_rz_i1(f, θ)`
UNCONTROLLED on the flag, the ordinary `_unc` strip, `cqrt_free(f)` — across seven
PRD rows (P1 flat diamond / if-else, P2 the folded angle select, P3 the compound
condition tree, P4 the depth-2 nest, P5 the `switch` **hand-IR only**, P6 the same
shapes rolled inside a classically-bounded loop, P7 the D2 deletion). The route is
GONE for phase arms at every one of those sites: `NestedRouteEmit.cpp` is DELETED,
`RotationLowering::emitRz` is DELETED, and the emitted Rz set is `cqrt_rz_i1` alone
(measured — see the `ir-pass-lit` note in Build & Test). **Value arms are Increment
2 and are NOT in this commit**, so `cqrt_cswap` still has minters (the value path
and `AbortParkEmit`).

*The three confirmed classes, each with the mechanism that now fences it:*

* **The uncompute spine ADJOINTED the kickback gate and cancelled the user's phase
  EXACTLY** (round 1, found INDEPENDENTLY by three lenses — F-L7-1 / F-L1-1 /
  F-L2-1). On the ziov `ShareCondFlag` path the emitter hands the flag to the data
  lineage instead of stripping it, so the Phase-5 whole-DAG spine saw an ordinary
  reclaimable rail and emitted `rz_i1(f, +θ)` … `rz_i1(f, −θ)`. Both gates are
  diagonal in the same basis label, so `P(θ)·P(−θ) = I` and the emitted circuit was
  **byte-for-byte the circuit for the same program with the `cq_phi` deleted** —
  PRD §1's own defect arriving through a different door, from four lines of plain
  C. The root cause is a **symbol whose MEANING changed and a set that was not
  told**: before 3qlq `cqrt_rz_<W>(h, θ)` meant "the user wrote `x = cq_phi(x, θ)`"
  and adjointing it was correct; after D1/D2 it means "the ANSWER, kicked back onto
  an ancilla". The fix is **MEMBERSHIP, never a name** — every emitted kickback gate
  carries instruction metadata `!cq.branchphase`, refused FIRST by
  `ChainWalk::isInPlaceGateOn`, `ChainWalk::preservesBasisUnderRecord` and
  `EmitInverse::isInverseEmittable`, so the gate becomes an unrecognized consumer,
  the DAG is not closed, and the flag rail is LEFT ALLOCATED (a leak, the Rule-6
  safe direction, and byte-for-byte the oracle's own disposition). Metadata rather
  than a `Value *` set on purpose: a pointer set keyed at emission and read stages
  later is the bd `drbq` Inc-1 defect verbatim (it dangled when a later stage RAUW'd
  the key), while metadata dies with its instruction and is visible in the lowered
  `.ll` every fixture reads. ⚠ **The record must be at EVERY emission site**, and
  the notes shipped saying "three" in a tree that already had six — MEASURED with
  `grep -rn 'markBranchPhaseGate' ir-pass/src`: **6 calls, 4 files, 5 emitters**
  (`SwapRouteEmit` ×3, `SwitchRouteEmit`, `AngleSelectEmit` ×2). A seventh emitter
  that forgets the call re-opens this with no diagnostic anywhere. ⚠ Note also what
  the defect looked like before it was understood: it was **POLARITY-DEPENDENT** —
  the `¬flag` arm survived only because its `cqrt_x` bracket happened to make the
  flag carry an unrecognized consumer. Whether a user's phase survived depended on
  which polarity `clang -O1` canonicalized to. That is an accident, not a fence.
* **P7 deleted a branch phase whose region had never been looked at, and the
  orphaned angle then lowered as quantum fp DATA** (round 1, F-L3-1).
  `deleteGlobalPhases` sat immediately after `lowerControlRegions`, on Rule 1's
  premise *"by then every tainted `br` has been claimed or declined"*. That premise
  was false at that program point, because `repropagateControlMerges` — thirty lines
  later — is not a taint touch-up but a **SECOND, FULL round of
  `detectControlRegions` + `lowerControlRegions`**. A `cq_phi` under an ONWARD
  tainted branch (a condition reading a 6.5 classical-call-arm or 4.5 data-mux
  `%out` rail, and therefore classical at round 1) was deleted as a "global phase"
  before its region existed. Two defects per deletion, and the second is worse: the
  phase vanished, and with its only consumer gone the ANGLE `select` was
  re-classified at round 2 as plain fp data and lowered through the 4.4/kjd1 merge —
  measured `cqrt_alloc_f64(0x1.ccc…p-1)` … `cqrt_copy_f64_controlled(…)`, i.e. **a
  rotation ANGLE materialised on a quantum f64 rail**, which is the Rule-3
  wire-crossing this file names outright. The fix is the stage's POSITION: P7 now
  runs AFTER the round-2 fixpoint, in BOTH entry points, and the stages it crossed
  were re-asked in writing at the call site.
* **A stale-header Grover oracle was NEITHER lowered NOR declined — Rule 1's "no
  third path", violated** (round 1, F-L6-1). `ArmClassify::isPhiCall` still claimed a
  retired `@cq_phi_<sfx>` call by PREFIX and recorded it as an arm gate, while the
  loop in `RotationLowering` that used to lower it had been (correctly) deleted.
  **The boundary is ONE CHARACTER wide and the flagship customer is on the wrong
  side of it**: three spellings decline through `declineTaintEscapes`, which fires
  only on a TAINTED OPERAND, but for `if (q == 5) q = cq_phi(q, PI)` `clang -O1`
  CONST-FOLDS arg-0 to a classical `i32 5` on the equality edge, so there is no
  tainted operand and the guard structurally cannot fire. Result: exit 0, the flag
  minted / stripped / freed, **the phase gate DROPPED**, and an unresolved call left
  in the module — noticed only by `ld`, one linkable body away from silent. Two
  fixes, and the second is the general one: `resolveSources` declines any USE of the
  retired family under a reserved-name string, and `declineSurvivingIntrinsicCalls`
  turns the pass's documented postcondition ("no `@cq_{theta,phi,measure}_<sfx>`
  remains") from a comment into a **checked, LOUD property** — not an `assert`,
  because Release builds have assertions off and Release is what every gate here
  runs. ⚠ MEASURED at this HEAD: any **USE** declines
  (`cq rotation lowering: retired register-form cq_phi_si32; use the register-free
  void cq_phi(double)`, on the tainted, the const-folded AND the wrong-prototype
  spellings alike), while a **DECLARE-ONLY** retired symbol is still SWEPT at exit 0
  — a deliberate, argued narrowing (the set that can reach a wrong unitary is
  exactly the set with a use) whose cost is the family's prototype validation, and
  which is on the owner's desk as OQ-29 now that the corpus is migrated.

*Two more that are the same lesson, one level up:*

* **An in-loop kickback leaked one ENTANGLED which-path rail per activation, and
  rolled ≠ unrolled** — twice, for two different reasons. Round 1 (F-L7-2 / F-L5-1)
  found it on **D4's own designated idiom**, `for (i…) if ((q>>i)&1) cq_phi(θ)`,
  which minted `cq_template_and_i32_hl(h, 1<<i)` per trip and never discharged it (4
  leaked at K=4, 32 at K=32) while the hand-unrolled spelling discharged all K. The
  cause is that `markIfRailLocal` runs ONLY when `collapseRailPhisIn` returns
  `Collapsed`: under the register surface the arm's `q = cq_phi(q, θ)` made `q`
  loop-CARRIED so there was a rail phi to collapse; **register-free, a kickback body
  gates nothing, `q` is loop-INVARIANT, and the shape the old surface could not
  produce is the one the new surface makes normal.** Fixed by
  `LoopLowering::invariantRegisterRoots`, which supplies `markIfRailLocal` —
  UNCHANGED — with the Roots a loop-carried rail would have supplied, admitting only
  a ROOT MINT (proof: a root mint lowers to `cqrt_alloc_<W>`, which
  `isInteriorTerminalHandle`'s clause (I1) excludes from the M-B interior partition
  outright, so no adjoint anchor can ever be placed for it). Round 2 (F-R1-1) then
  found the SAME leak with a different Root: a Phase-4 **control-owned merge
  out-rail**, which `-O1` produces routinely — and the population was wider than the
  report, since the 4.4 select-merge and 4.5 data-mux out-rails leaked at ROUND 1
  too. Fixed in two halves (clause (ii-b) admitting a control-owned merge out-rail,
  plus a second `collapseFlattenedLoopRails` over the round-2 delta), each
  mutation-validated separately. ⚠ **Stage 2b is structurally blind to this whole
  class** — a leaked TEMPLATE-minted rail has no `cqrt_alloc` to count — and it
  reported `0 violation(s)` on every broken circuit; the round-1 implementation
  hand-back cleared the defect by citing that very checker. **AND THE INDEPENDENT
  RULE-13 CLEARANCE THEN FOUND A THIRD INSTANCE — finding C-1, its BLOCK verdict:**
  add ONE ancilla rotation to that same idiom's body (`for (i…) { if ((q>>i)&1)
  cq_phi(θ); r = cq_theta(r,.1); }`) and the loop returns `Collapsed` instead of
  `NotClaimed`, so `invariantRegisterRoots` was never asked and `markIfRailLocal`
  refused on `q` at its "accumulating loop-invariant tainted input" clause — 3 mints
  / **0** `_unc` against 3/3 hand-unrolled and 3/3 on the pre-3qlq oracle, exit 0 and
  strict-2b clean; fixed 2026-09-06 by having the `Collapsed` branch ALSO collect the
  invariant roots (a SEPARATE set unioned only on success, with a `CarriedRoots` skip
  so the collapse's own rail is not judged by clause (iii)), on clause (ii)'s
  UNCHANGED (I1) proof, and gated by `e2e-phase-perbit-loop-mixed-twin-identical`
  plus the matrix's new second-CARRIED-register sub-grid F (274 → 284 cells).
  ⚠ **AND THE INDEPENDENT ROUND ON THAT FIX FOUND A FOURTH AND A FIFTH INSTANCE, BOTH
  CONFIRMED, IN THE FIX'S OWN NEIGHBOURHOOD (2026-09-06, findings F-C1-1 / F-C1-2 —
  notes §3.10):** ONE added line, `q = q + 7;` in the loop's PREHEADER, restores the
  leak verbatim (the peel walks only ops whose disposition is `InPlace`, and a
  preheader `add` reads `Unproven` there while `lowerOps`' M-C lowers that very op IN
  PLACE — PRE-EXISTING and F-L5-1-era, since the same program with no carried
  register leaks identically); and the same mixed loop with an ONWARD (round-2)
  in-loop region leaks for two further reasons, the "already claimed" fact being a
  caller LOCAL while the collapse happens in the ROUND-1 call, and the round-2 delta
  being keyed on block MEMBERSHIP while a round-2 region flattens into the very
  `Pred` a round-1 region already used. Fixed by asking the ONE owner of the in-place
  decision (`ArithLowering::classifyInPlaceReassignment`) and COMMITTING to its answer
  via `taint.InPlaceRailOps`, by `taint.ClaimedRailRoots` written at both collapse
  sites, and by making `taint.InLoopFlattenedPreds` a per-block COUNT; gated by
  `e2e-phase-perbit-loop-mixed-preadd-twin-identical` and
  `e2e-phase-onward-perbit-loop-mixed-twin-identical`, with sub-grid F3 (284 → 286).
  ⚠ **AND A THIRD ROUND (2026-09-06, findings F-C1B-1 / F-C1C-1 — notes §3.11) FOUND
  THAT THAT FIX HAD ITSELF INTRODUCED A CONFIRMED SILENT MISCOMPILE, of the
  once-only-stage class, in a NEW stage nobody had given a row in §2's ⭐ table:**
  `commitOutOfLoopInPlaceOps` asks `classifyInPlaceReassignment` at ROUND 1 and
  `lowerOps` honours the marking without re-asking, so an immediate that becomes
  TAINTED at round 2 (anything derived from a 6.5/4.5 `%out`) was emitted as
  `cqrt_addc_i32(%h4, %h_op)` — a QUANTUM RAIL HANDLE IN THE ABI's CLASSICAL-IMMEDIATE
  SLOT, printed by the runtime as a bare decimal — with the commuted spelling MUTATING
  THE WRONG RAIL; four plain-C programs, exit 0, verify-clean, STRICT-2b clean, all
  correct on the two earlier binaries. Its `hasOneUse` conjunct guarded G6/G7 and
  NOTHING guarded G2 — *`hasOneUse` was asked of `P`, and the answer that went stale
  was about `Imm`*. **Building the fix's own tripwire then found a SECOND miscompile
  in the same conjunct**: `hasOneUse` is true of the SSA VALUE and false of the WIRE,
  because `lowerRotations` RAUWs a whole `cq_theta` chain onto ONE handle, so
  `int q2=cq_theta(q,.3); int a=q2+7; … cq_measure(q)` collapsed `q` and `a` onto one
  register. Fixed by (1a) a MONOTONE `isa<Constant>(Imm)` fence at the commit and
  (1b) a LOUD re-verification of the ONE fence at `lowerOps` for exactly the ops that
  path marked (`cq loop lowering: pre-loop in-place op no longer provable at
  lowering`; a silent fallback to out-of-place is NOT sound — the body marking the
  commit licensed already stands). The same round narrowed `taint.ClaimedRailRoots`
  from a module-wide set of ROOTS to `(root, the CLAIMING loop's header)` (F-C1B-2),
  after measuring a program where loop A's claim marked loop B's body on a rail loop
  B never proved. ⚠ **SEVEN INSTANCES ACROSS FIVE SUCCESSIVE ADVERSARIAL ROUNDS ON
  ONE FUNCTION — the third found by the CLEARANCE, the fourth and fifth by the round
  on its fix, and the sixth and seventh INTRODUCED BY that fix and found by the round
  on IT** — budget the next round on the assumption that an eighth is there, and note
  the shape all seven share: a dispatch precondition or a PREDICTION that excludes (or
  wrongly admits) a customer the underlying proof already settles.
* **A HOISTED loop-invariant TEMPLATE rail read by the body's condition is STILL
  refused, and still leaks** (Q-R1-1). A deliberate mutation admitting any
  loop-invariant tainted value made those rails discharge and did NOT exhibit the
  multiplicity hazard `markIfRailLocal`'s own comment names — **which is not the
  same as showing it absent**, and widening a Rule-13-core clause on "I could not
  break it in one afternoon" is exactly the reasoning this project's history says
  not to trust. Prime-Directive decline, owner question, not a proof.

**TWO STANDING LESSONS, and they are the reason to budget a third round on any
successor increment.** (1) **A stage that runs ONCE has a round-2-FALSE premise.**
F-L3-1 and F-R1-1 are the same defect in two different stages: a stage standing
where a one-round pipeline put it, whose premise is falsified the moment
`repropagateControlMerges` runs a second full round of control detection and
lowering. Two of them have now been found by adversarial review and **zero** by the
1656-fixture suite — the corpus at which they were missed, which is why the number
stays. ⚠ **The independent CLEARANCE then ran 12 probes for a THIRD instance of THIS
family and found none in the accept direction, so it stands at two — and its BLOCK,
C-1, must NOT be folded into this count: C-1 is the OTHER family**, the in-loop
entangled-rail leak of the bullet above, whose third instance it is (notes §3.1,
§3.2). Two families, two counters; conflating them would credit this lesson with a
finding that has nothing to do with a stage running once.
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 carries the artefact that
round owes the next one — a table asking EVERY stage between `lowerControlRegions`
and `repropagateControlMerges` *"does this stage compute something a LATER stage
consumes, over a premise round 2 falsifies?"* — with three residuals, all in the
DECLINE direction (`lowerControlledIOSinks`, `lowerLoops`, and the round-1 marking
that is never re-verified). Read that table as a METHOD, not a result. (2) **When a
set is NARROWED, ask what OTHER predicate names the same gate** — the mirror of the
bd `8h7d.5` F-1/F-3 lesson, and it cuts both ways. The three spine predicates were
taught to refuse a kickback gate by membership; a FOURTH,
`Uncomputation::preservesBorrowedParent` clause (1), still answers **`true` for the
same instruction, BY NAME** (`starts_with("cqrt_rz_")`, arity 2, arg0 == P). **That
verdict is SOUND and must NOT be narrowed "for symmetry":** the three ask *"may the
spine ADJOINT this gate?"* (no — that cancels the answer), this one asks *"does this
gate DISTURB the borrowed parent's basis label?"* (no — it is diagonal, whoever
emitted it). It is REACHED, not hypothetical, and narrowing it would silently delete
a real discharge — the identical narrowing of the CONTROLLED twin cost nine modules
theirs. A closure table that claims to be complete is worth exactly its most-missing
row; that row was missing for a whole round.

Tainted `br` / `select` / `switch` is the construct that has produced every
verify-clean silent miscompile in this project's history. The **old controlled-op
lowering** (mint a flag → substitute each arm gate with a `_controlled` template
→ dissolve the φ → uncompute the flag → linearize the CFG) shipped and was then
**removed wholesale** (`7cde677`) so the new **RSSA swap-route** design is built
without it shaping the implementation. Today `ControlDetect` recognizes
phase-arm AND value-arm if-diamond / if/else regions (incl. derived-base
routing); `SwapRouteEmit` lowers **phase arms** by **KICKBACK** since bd
`test_C_libtooling-3qlq` Inc 1, 2026-09-05 (flag mint → one `cqrt_rz_i1(f, θ)` per
`cq_phi` call, UNCONTROLLED, `cqrt_x`-bracketed for a ¬flag arm → `icmp_inv`
flag-strip → flag free; **no work rail, no route, no gate on `q` at all, so the
region's only `cqrt_free` is the flag's** — and on the ziov `ShareCondFlag` path,
where the strip and free are skipped because the data lineage owns the flag, the
region frees **nothing at all**). ⚠ The two earlier phase-arm forms are HISTORY and
are recorded because the arguments made for them are still quoted: the drbq Inc-2a
control-in-place form (one `cqrt_rz_<W>_controlled(f, q, θ)` per arm gate,
2026-09-02 → 2026-09-05) and, before it, the route (flag mint → `cqrt_cswap` route
→ verbatim arm Rz on a `|0⟩` rail → route back → clean frees → strip, **zero
controlled gates**). All three are the same unitary *as each other*, and that is
exactly the problem: **all three put a TENSORED per-qubit Rz on `q`**, which is why
every shipped Grover golden was the identity (PRD §1). Do not restore either form
for a phase arm, and do not quote "zero controlled gates" or "`Rz|0⟩ = |0⟩` for
free" as a phase-arm invariant. `SwapRouteEmit` lowers **value/permutation arms** by
method-B (`R` → `cqrt_copy_<W>` copy-out → reverse-play `R†`; a value arm that
clobbers a register the condition reads declines loudly — §3c) — **this is the ONLY
arm class that still routes**, and it is Increment 2's subject; `RegionFlatten`
erases the CFG diamond. `RegionTreeDetect` + `SwapRouteEmit::
emitPhaseKickbackNestRegion` lower the **depth-2 homogeneous-phase nest**
(`if(a){…if(b){…}}` — 4.3 DONE; ⚠ the flag-per-level ROUTE and
`NestedRouteEmit.cpp` are DELETED. Each level's condition becomes a root flag
through `CondTreeEmit::emitCondNetwork`, the outer arm's phases ride the OUTER
root and the inner arm's ride a `cqrt_toffoli` CONJUNCTION ancilla, and the
networks are torn down LIFO). `SelectClassify` + `SelectMergeEmit` lower a tainted-condition
**integer- or scalar-fp-data `select`** via the **controlled-XOR copy merge** (flag
mint — icmp or, since kjd1, fcmp → `|0⟩` rail → two `cqrt_copy_<W>_controlled`
(fp widths minted only by the select-local `copyControlledFpFn`), ¬flag
`cqrt_x`-bracketed → compare-`_inv` strip → one `cqrt_free`; no
cswap/route/flatten/reverse-play — 4.4 DONE, fp-DATA un-staged 2026-07-02
(kjd1) behind the three-legged angle fence; the kjd1 Rule-13 clearance also
added — both type families — the gate-2c **stale-condition wire guard** (a
chained Ry between compare and select declines, the ArmClassify mirror) and
**wire-anchored gate-5** walks (sibling-alias phase/interference + curated-call
crossing; `FP_SELECT_CLEARANCE.md`); coherent `Rz`-lineage /
downstream-rotation operands, fp vectors, and `fp128` ride the conservative
decline, and fp stays declined at every NON-select consumer). `SwitchClassify`
(G0–G11) + `SwitchArmProve` + `SwitchRouteEmit`/`SwitchValueEmit`/
`SwitchDataMuxEmit` + `EqFoldArm` lower a tainted-scrutinee `switch` (and the
equality-folded `br` diamond) in **four** ACCEPT shapes — homogeneous **phase**
(N-way eq-flag route + arg-1-only `cqrt_rz` + the **§5 const-fold re-anchor scrub**,
the verify-clean-invisible blocker), homogeneous **value** (N-way method-B over the
shared routed base `p != q`), all-`ConstantInt` **data-mux** (preload + XOR-delta
controlled copy), and the **eq-folded diamond** (`tryEqFoldArm` D1–D7, additive,
reuses `emitRegion`) — 4.5 DONE (16-reviewer Rule-13 clearance, 0 silent
miscompiles; `WI7_SWITCH_CLEARANCE.md`). **SEQUENTIAL flat regions** — two or more
`br` diamonds in a row, each region's merge hosting the next region's tainted
branch — lower since bd `hcrg` (2026-08-27) via the emission-ORDER fix in the
block-lifetime bullet below; the
follower must be a diamond (an `if/else` follower's routed base is the previous
merge phi, which `isValueChangingOp` reads as a new basis value → over-declines,
`control_swap_reject_seq_ifelse_second.ll`). A **NON-EXITING tainted PHASE region
INSIDE a classically-bounded loop** lowers **ROLLED** since bd `8h7d.5` (owner
ruling 2026-08-29) — Grover written as `for (i…) { oracle; reflection; }` compiles,
with IR size independent of the trip count (measured: 87 lines of lowered IR at
K=3 and at K=1000). Three pieces: the d8jl `regionEntryInLoop` decline is narrowed
by `flatRegionRollableInLoop` (reducible `LoopInfo` loop, one depth, single latch,
no second cycle through the entry — the IRREDUCIBLE half is kept because every
downstream loop guard is `LoopInfo`-gated, **not** because the flatten breaks; bd
`dugh` repaired that on 2026-07-04); a ROUND-2 `collapseFlattenedLoopRails` +
`markIfRailLocal` (`LoopLowering`) runs after the flatten to collapse the
persistent rail phi and license the in-body per-iteration discharge; and
`provablyBefore` gained a per-activation reading (`provablyBeforePerActivation` +
the `phiTracksWire` fence, `WireWalk`) so a body Ry reached only around the back
edge reads as the NEXT iteration's producer rather than this one's staler. The
witness is BYTE-IDENTITY with the hand-unrolled twin (four `cmp` ctest gates).
**THE FIRST ADVERSARIAL ROUND ON THAT COMMIT FOUND A CONFIRMED SILENT MISCOMPILE
IN IT, WHICH IS THE FACT TO CARRY, NOT THE FEATURE.** Round 2 said it
"deliberately does not re-prove `tryCaseA`'s COVERAGE/CLOSURE" — but CLOSURE was
carrying **two** obligations under one name: a CLAIM condition (may round 1 own
this loop?) and a **UNITARY** condition (is a rail record read at a position where
the register still holds it?). Only the first is round-1-specific; dropping the
bundle dropped both, and `for (…) { if (q==5) q=cq_phi(q,PI); acc = q*7; q += 3; }`
emitted the `mul` in the EXIT block against the **post-loop** register (`clang -O1`
sinks it) — a different unitary at `opt` exit 0, verify-clean and STRICT stage-2b
clean. The fence is `LoopLowering::staleRailRecordRead`, asked by **both** rounds:
a rail member may be read only where no rail-relabelling gate (`cq_theta`/Ry or a
dtzb in-place `add`/`xor`; `cq_phi`/Rz is diagonal and exempt) executes between the
record's definition and the read without that definition re-executing. Grouped per
ROOT MINT — two chains from one mint are **one** register (`int a=q,b=q` is an
alias, Rule 8) and must interfere, two mints must not. **The same round found the
identical defect in ROUND 1, PRE-DATING the increment** (`CLOSURE` admitted a
`cq_measure`/`ret` of a rail value at any position; verified on a `7ba8b2d` base
build, bd `test_C_libtooling-5sva`), plus a **vacuous** `provablyBeforePerActivation`
call whose barrier was the proof's own subject `A` — the barrier walk cut at the
instruction it was trying to reach, so the call silently degenerated to plain
dominance (`Barrier == A` is now refused in the predicate), and a **wire-blind**
`phiTracksWire` whose staleness test made the disposition depend on SOURCE ORDER and
made two independent registers in one loop permanently unlowerable (now per-wire;
`control_swap_inloop_two_registers.ll` + `slice_control_grover_loop_two_regs`).
**THE SECOND ADVERSARIAL ROUND THEN FOUND TWO MORE HOLES IN THAT FENCE ITSELF, both
in premises it never stated — read the count as 6 findings over 2 rounds on one
increment, and budget a third.** (F-1, `clang -O1` C-reachable and CONFIRMED) the
gate set was built from **chain members**, so a `cq_theta` whose arg-0 IS a member
but whose RESULT is off the chain — canonically a rotation on the loop's EXIT value
— was not a gate and the record collapsed stale (`mark = q; q = cq_theta(q,.125);
cq_measure(mark)` emitted `ry(%h,.125); measure(%h)`). The gate set is now the
RAIL's: each chain is extended FORWARD through the users that keep mutating the same
handle — a rotation unconditionally (Ry/Rz are always lowered in place), a dtzb
`add`/`xor` only when it is a member or already in `taint.InPlaceRailOps` (an
off-chain one is lowered OUT of place into a FRESH rail, which is exactly why
`mark = q; q = q + 9; cq_measure(mark)` is CORRECT today and must keep lowering), and
a phi that names the rail on SOME incoming. Following the *diagonal* Rz hop is
load-bearing even though Rz is never itself a gate: without it the Ry BEHIND an Rz
has an arg-0 on no chain and is missed. (F-2) `railGateBetween`'s cut — which
suppresses every path that re-executes the record's definition, on the premise that
re-executing refreshes it — is FALSE for a zero-hop **identity-carry** phi
(`%rec = phi [%q0, entry], [%rec, latch]`, which step (1) accepts trivially): it
re-executes yielding the SAME value while a sibling chain on the same mint moves the
wire, so the cut removed exactly the path carrying the staleness. A carry now
refreshes only if it crosses a rail GATE.
**AND THE THIRD ROUND FOUND F-1's EXACT TWIN ONE HOP OUT — 7 findings over 3 rounds
on one increment, three of them (round 1's F1, round 2's F-1, round 3's F-3)
confirmed `clang -O1`-reachable silent miscompiles in or around this ONE fence,
beside round 1's separately confirmed pre-existing hole.**
(F-3) F-1 widened the **gate** set from the chain to the rail and left the **record**
set — the values the fence asks "is any read of you stale?" — enumerating chain
members, so a rail value ONE HOP off the chain was never asked about:
`int a = cq_theta(q,.125); int b = cq_theta(a,.25); measure(a) + measure(b)` after
the loop emitted `ry(%h,.125); ry(%h,.25); measure(%h); measure(%h)`, with `a`
naming the pre-`b` register. The record loop now runs over the rail's own forward
closure (`collectRailGates`' `OnRailOut`) — **but the SKIP set stays the chain's**,
and widening both was measured to turn a decline into an accept (a gate ON a frozen
identity-carry record is the very read that proves it frozen). Two sets, two
questions. Round 3 also RETIRED a false in-source ground: "an off-chain in-place
`add` is lowered OUT of place by M-C into a FRESH rail" is not unconditional — M-C
DOES fire in place there, and the exclusion is sound only because M-C's G6/G7 pair
refuses whenever a later record read exists (recorded at both ends, and pinned
weakly — the fixture only reddens if BOTH clauses are relaxed).
**THE STANDING LESSON FROM THIS SEQUENCE, worth more than any one finding: when you
widen a set, ask what OTHER set was computed over the same closure.** F-1 widened
the gates and not the records; F-3 was that omission, found one round later by an
adversarial reviewer and not by the 1281 fixtures that were green at the round-2
HEAD.
Read bd memories [`inloop-control-rolled-8h7d5`],
[`inloop-rail-record-escape-closure-8h7d5`],
[`peractivation-barrier-must-not-be-subject-p1`],
[`per-wire-staleness-not-source-order-od1`],
[`offchain-forward-ry-is-a-rail-gate`],
[`identity-carry-phi-does-not-refresh`],
[`rail-record-set-is-the-rail-not-the-chain`],
[`d8jl-correction-flatten-repairs-headerphi`] and
[`provably-before-per-activation`] before touching any of it. IN-LOOP VALUE
(method-B) arms, depth-2 nests, `switch`, the 6.5 classical-call arm, irreducible
cycles and multi-latch loops all keep the loop decline. **AN IN-LOOP CONTROLLED
`Ry` ARM NO LONGER DOES** — bd `drbq` Inc 3 (2026-09-04, PRD §13): a tainted-arm
`cq_theta` on a register disjoint from the condition lowers ROLLED inside a
classically-bounded loop, with `cqrt_ry_<W>_controlled` where the phase path puts
`cqrt_rz_<W>_controlled`. THREE pieces, and all three were required: R7's loop
half became clauses (b) (some member of the base's rail closure is a `PHINode` in
`L`'s header — the rail crosses the back edge) and (b′) (that φ is one the round-2
collapse will CLAIM, asked by CALLING `LoopPlan.h`'s `railPhiRootMint`, which IS
`collapseRailPhisIn` step (1)'s body — never a second spelling); R6's two flat
position predicates were replaced, FOR IN-LOOP REGIONS ONLY, by a PER-ACTIVATION
certificate (`recordLivePerActivation`: the barrier is the record's own def `D`,
the read position of a φ consumer is the terminator of the incoming block on the
edge that names the member, `D` must REFRESH — `WireWalk::phiTracksWire`, now
exported — and `Barrier == To` is refused outright as the finding-P1 vacuity; the
DOMINANCE conjunct is deliberately dropped, which is the one widening and is why
the FLAT path keeps `provablyBefore`/`cannotFollowGate` byte-for-byte); and the
emitter gained **M-β** — for the Ry stem ONLY, `emitInPlaceRotationRegion` RAUWs
the merge φ to the LAST HOISTED GATE instead of to the base, chaining an if/else's
two gates so the second reads the first's result. M-β is not a peephole: with the
base as the target, S2 (no post-region gate) becomes a zero-hop identity carry that
`recordRefreshedByDef` correctly calls FROZEN and the increment's own target shape
declines `rail record read past an in-place gate`, while S1 gives the header φ TWO
in-place `cq_theta` users and the Rule-8 fan-out guard fires — both MEASURED. The
Rz stem keeps M-α (the base) because a diagonal gate's two names denote the same
basis state; **two RAUW conventions now live in `SwapRouteEmit.cpp` and which is
which is load-bearing** (retiring the split is follow-on `drbq.10`).
`ControlDetect`'s in-loop scope fence part 3 is RETIRED (it was a blanket decline
of the shipped shape); parts 1 and 2 are unchanged. Witness: BYTE-IDENTITY with
the hand-unrolled twin on SIX e2e pairs (the sixth is the round-1 review's
O(K)-freeze-leak reproducer, the only program in the tree that reads the ROTATED
register inside the body — it strands 2 TEMPLATE-minted rails per activation that
nothing ever frees, Rule-6 correct, strict-2b blind, and BYTE-IDENTICAL to its
flat twin, which is how it shows the cost belongs to the FREEZE and not to the
ROLL), and IR size independent of the trip count (74 lowered-IR lines at K=3 and
at K=1000). **THE SAME INCREMENT MOVED A
FLAT FENCE**, and it had to: `ArmClassify`'s final P1 clause read `(SawValueArm ||
!SawPhaseArm)`, which is phase-arm-only, so `if (q==5) r=Ry(r,.9); q=Ry(q,.3);` —
NO LOOP IN IT — declined `condition predates a non-diagonal gate` while the same
program with `q=Rz(q,.3)` accepted. It is now
`(SawValueArm || !(SawPhaseArm || SawRotationArm))`, on P1's own argument with the
arm class substituted: an in-place rotation arm copies nothing, replays nothing and
allocates no work rail, so `ProvenPostRegion` carries to every call in its stream.
Without it the flagship customer — Grover as a `for` loop with an Rz oracle, a
controlled Ry on an ancilla and an **Ry** reflection — does not compile, rolled OR
flat. **THE INCREMENT'S HEADLINE FINDING IS NOT THE FEATURE**: `e2e-loop-twin-matrix`
was RED on 15 cells at hand-back, in two classes (a hoisted loop-invariant derived chain whose
top rail the ROLLED form leaves allocated and the flat form discharges; and the
M-C in-place vs out-of-place decision on a trailing `a += off`), and **both
reproduce byte-for-byte on the pre-Inc-3 oracle with an `Rz` arm** — pre-existing,
arm-class-independent, and exposed only because this is the first matrix axis whose
ARM ROTATES A REGISTER THE CONDITION DOES NOT READ. They are an owner decision, not
something the increment may bless. **THE ROUND-1 REVIEW RESOLVED THE GATE WITHOUT
BLESSING THE DIVERGENCE**: the 15 rows are OUT of `loop_twin_matrix.expected.txt`
(258 rows) and INTO the new PINNED-SIGNATURE QUARANTINE
`tools/loop_twin_matrix.quarantine.txt` (15 cells: 6 class A → bd
`test_C_libtooling-1m5p`, 9 class B → bd `test_C_libtooling-a3z7`), each with its
class, its owning subsystem AND DIRECTION, and a SHA-256 digest of the exact
unified diff of the two traces. A quarantined cell passes ONLY while it diverges
in exactly that way and FAILS if the signature moves, if it stops diverging
("quarantine stale — remove it"), or if it appears in both files; any
non-quarantined divergence still fails as before. Two boundary controls (no region
⇒ identical; arm ON the condition register ⇒ identical) run beside the cells on
every invocation — **`--regenerate` and `--refresh-quarantine` included, each
refusing to write while a control has moved (the ROUND-2 review found both write
modes returning before the controls ever ran, and `--regenerate` writing the
forbidden `TRACE-DIVERGENCE` row to disk under a message that called itself a
refusal)** — so the class story is a measurement. **`e2e-loop-twin-matrix` is
GREEN again** — which matters for the Rule-19 reason: a gate expected to be red is
a gate people stop reading, and the 8h7d.5 F-4 class was found BECAUSE the gate was
green and one cell went red. ⚠ "Pre-existing" is true of the defect and FALSE of
its population: all 15 shapes declined before Inc 3 and compile now, so this
increment ADDS CUSTOMERS to a known-defective path.
> ⚠ **THE TWO NUMBERS IN THE PARAGRAPH ABOVE ARE 2026-09-04 HISTORY. RE-MEASURE
> BEFORE QUOTING** (bd `test_C_libtooling-3qlq` Inc 1, prep-d2, 2026-09-05). The
> matrix's SHIPPED surface is now the register-free `cq_phi` (`--phi-surface
> void`), which changes what the generator EMITS, so both tables were re-measured
> end to end rather than edited: **`tools/loop_twin_matrix.expected.txt` holds 245
> rows** (`grep -c '^m_' tools/loop_twin_matrix.expected.txt`) and
> **`tools/loop_twin_matrix.quarantine.txt` holds 29 cells in THREE classes** —
> **6 class A** (bd `test_C_libtooling-1m5p`), **21 class B** (bd
> `test_C_libtooling-a3z7`) and **2 class C** (bd `test_C_libtooling-3qlq`, the
> `m_xor_range_{none,rz}` pair: `-O1` drops the mask's low bit on the FLAT side
> only, so the two spellings are different PROGRAMS — a generator question, not a
> compiler defect; OQ-27, not blessed) — MEASURED with `grep -c '^cell '` and
> `grep -o 'class *[A-C]' … | sort | uniq -c`. 245 + 29 = the 274 cells the gate
> runs. **Re-measured 2026-09-06 after the C-1 fix round (branch
> `3qlq-inc1-fix-c1`): 255 expected rows + 29 quarantined = 284 cells** — the
> quarantine is UNTOUCHED at 29 in the same three classes, and the +10 is **sub-grid
> F, the second-CARRIED-register axis: the only axis in the instrument that can see
> C-1**, because until it existed no cell put a loop-INVARIANT condition register and
> a loop-CARRIED register in the same body. **RE-MEASURED AGAIN after the SECOND C-1
> round on the same branch: 257 expected rows + 29 quarantined = 286 cells**, the +2
> being **sub-grid F3** — a PREHEADER in-place `add` on the invariant register at the
> diffusing and non-diffusing per-bit regions, i.e. the one POSITION the
> `PREFIX × REGION × SUFFIX` product could not express (`PREFIX` is BODY text, and an
> in-body `add`/`xor` is refused outright by M-C's G5, so every existing such cell
> exercises the disposition the peel already gets right). Both were TRACE-DIVERGENCE
> on 542d588 AND on the round-1 fix and are ACCEPT-IDENTICAL now; all **1136**
> pre-existing generated sources hash identically, twice. The `xor` spelling of that
> axis is DROPPED with its measurement in the code (the `addpost` precedent): `xor`
> DISTRIBUTES over a bit test, so `-O1` rewrites the FLAT side's `((a^9)>>i)&1` onto
> the PRE-xor register and the two spellings stop being the same program — which also
> makes the plain-C `q ^= 9` pair an unfaithful twin, its rolled trace moving 3/0 →
> 3/3 under the fix with nothing able to witness it. **Every one of the 245 earlier rows is
> byte-unchanged** (`comm -23` over the `^m_` rows, empty, run twice), and the 1104
> pre-existing generated SOURCES hash identically on both surfaces — the axis adds
> cells, it does not re-cut old ones. 9 of the 10 new cells would have been HARD
> FAILURES on 542d588 and are `ACCEPT-IDENTICAL` on the fix (4 sampled by hand on the
> pre-fix binary, all four `TRACE-DIVERGENCE(4)`; the 10th is `UNROLLED-ONLY … rail
> record read past an in-place gate`, a verdict 23 shipped cells already carry, on
> BOTH binaries). One candidate cell was DROPPED rather than quarantined —
> `addpost`, where the flat spelling's `-O1` SINKS an `add nsw` past the second
> region and a loop body cannot, so the two SOURCES are different programs after
> `-O1`; filing a scheduler artefact as a compiler defect is what the quarantine
> file's own header forbids. Counts MEASURED with `grep -c '^m_'` and `grep -c
> '^cell '`. The old REGISTER-surface tables are kept byte-unchanged as
> `tools/loop_twin_matrix.{expected,quarantine}.register.txt` — **frozen history,
> not a live mode**: the register surface is unreachable from the shipped `CQ.h`
> (prep-d2's OQ-D2-3). Two things about the machinery changed with them: the
> surface classifier `phi_surface_of_header()` is now ONE whitespace-insensitive
> spelling shared by all three instruments (it was a duplicated literal substring
> test, and it broke this increment's own first run — round-1 finding F-L5-7), and
> the **second boundary control (arm ON the condition register ⇒ identical) is now
> itself an INSTANCE of class A** and no longer bounds anything: a branch phase
> writes nothing, so that control now satisfies the precondition it was built to
> exclude. It is kept and pinned by `(verdict, digest)`, and the class story is
> bounded by `q_noregion` ALONE (OQ-28, on the owner's desk). The quarantine's own
> mutant validation grew with the surface: `e2e-loop-twin-quarantine-selftest`
> runs **27 cases** (12 × 2 surfaces + 2 guard-mismatch + 1 shipped-header), not
> the twelve named further down this file.
**AND ONE CLAUSE OF ROW W BELONGS IN THIS PARAGRAPH, because it is the shape a
customer writes first (bd `test_C_libtooling-drbq.12`):** lifting the loop fence
does NOT make `for (…) { if (q > 5) r = cq_theta(r, .9); }` compile when `q` is
untouched in the body. With no gate on `q` the condition register is
LOOP-INVARIANT, `clang -O1` LICM-hoists the compare out of the loop, and
`condWireDisposition`'s P4 precondition (`Cond->getParent() != R.Pred` — an
unbounded gap across blocks) returns `DeclineNow` before any rotation clause runs:
the program declines `condition predates a non-diagonal gate`, and the arm's own
Ry plays no part in it. **THE CONDITION REGISTER MUST BE LOOP-VARIANT** (Grover's
is — its oracle rotates `q` every trip), or the threshold opaque. It is an
over-decline, pinned by
`control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll` and by 16 cells of
the twin matrix, and it is identical for the shipped Rz stem. **A tainted-arm `Ry`
(`cq_theta`) on a register whose PHYSICAL wire is disjoint from every condition
wire lowers CONTROL-IN-PLACE since bd `drbq` Inc 1** (2026-09-02, PRD §4 shape
(a) only — a flat DIAMOND; the if/else arm is supported symmetrically but is
reachable only from HAND-WRITTEN IR, because `clang -O1` merges the two arms into
ONE call with a `select` on the ANGLE — **which is the shape bd `drbq` Inc 2b now
LOWERS, so "declines `rotation angle`" is no longer true of it; see the 2b
paragraph below**): the
arm's theta is hoisted to the pred and
`RotationLowering` mints the new frozen-designate `cqrt_ry_<W>_controlled(flag,
h, θ)` — the swap route CANNOT carry an Ry (`Ry|0⟩ ≠ |0⟩` leaves the inactive
work rail dirty and entangled, Rules 6/8), so this is the MECHANISM, not a
peephole. The rotated register is then FROZEN — never reverse-played, never freed
by the whole-DAG spine, because a controlled gate's adjoint needs its control and
the flag is stripped and freed inside the region (measured: it emitted a
use-after-free of the flag and then a dirty free). **THE FREEZE IS ASKED
STRUCTURALLY OF THE EMITTED GATE** (`ChainWalk::railCarriesControlledRotation`,
which derives the rail from the gate's own arg-1 use), and that spelling is the
round-1 Rule-13 fix: Inc 1 shipped it as a `Value *` set keyed on the theta's
arg-0 at `lowerRotations` time, which for a DERIVED base (`r = p*5`, `p+5`,
`p^5`, `zext p`, `sqrt(p)`) is an instruction the very next stage (`lowerOps`)
RAUWs and ERASES — so the set dangled, the freeze silently did not apply, and the
use-after-free + dirty free returned verbatim — from plain C for the `mul` base, and
in hand IR for the other 4 of 5 out-of-place base opcodes. **STATE PREP LEFT THAT
DECLINE LIST at bd `drbq` Inc 4** (2026-09-05, PRD §14): `int r = SEED; if (COND(q))
r = cq_theta(SEED, θ);` — a flat DIAMOND whose arm theta has a CLASSICAL
`ConstantInt`/`ConstantFP` arg-0 — lowers to `cqrt_alloc_<W>(SEED)` at the hoisted
theta followed by `cqrt_ry_<W>_controlled(f, h, θ)` on that fresh rail, which is
then FROZEN by the same structural freeze; R4/R6 are SKIPPED (not fed an empty
set: `railWireClosure` inserts before its taint gate and a `ConstantInt` is
module-uniqued, so R6 would enumerate unrelated users), and M-β is a CORRECTNESS
requirement there rather than a convenience (M-α would RAUW the merge to the SEED
and make `r` classical — measured silent on the `ret` and tape consumers). TWO new
fences: **F1** `state prep seed does not match the merge incoming` (the merge's
Pred incoming must be pointer-identical to the seed — `-0.0` vs `0.0` declines)
and **F2** `state prep seed is proven equal to the condition register`
(polarity-free: `clang -O1` folds an equality edge on BOTH sides, so
`if (q==k) r=cq_theta(q,θ)` and `int r=q; if (q!=k) r=cq_theta(k,θ)` compile
BYTE-IDENTICAL to a genuine prep whose seed is `k` — accepting would turn two loud
declines into silence, and the price is that `seed == k` OVER-DECLINES a genuine
program, workaround one character). ⚠ **F2 SHIPPED AS A TEST ON THE COMPARE'S
LITERAL AND THAT WAS A CONFIRMED SILENT MISCOMPILE, FOUND BY THE FIRST ADVERSARIAL
ROUND** (2026-09-05, lens L2): the literal enumerates TWO ways a seed can be a
fold of the condition register and there is a THIRD — either edge can pin the
register **BY RANGE**, to a value that is NOT `k`. `int t = q & 1; int r = 1;
if (t) r = cq_theta(t, θ);` — an in-place Ry on the CONDITION rail, plain
`clang -O1` C — folds to `cq_theta(i32 1, θ)` against `k = 0`, so F2 was silent BY
DESIGN and the region lowered onto a fresh rail while `t` was never rotated. Nine
plain-C spellings accepted; the pre-Inc-4 binary declined every one. F2 is now
**RANGE-BASED on BOTH edges** — `computeConstantRange ∩ fromKnownBits(computeKnownBits)
∩ makeExactICmpRegion(pred, k)`, asked of the predicate AND its inverse, declining
on `isSingleElement() == seed` — which is the same arithmetic IPSCCP used to
create the ambiguity, and the `isEquality()` gate is dropped (an ordered compare
pins at an extremum too). It only ever DECLINES, so it is monotone. **One shipped
accept fixture flipped and it was an over-accept**: at `i1` BOTH edges of an `i1`
equality pin, so an `i1` seed under an `i1` condition is always ambiguous.
⚠ **AND THE SECOND ADVERSARIAL ROUND FOUND THAT THE FIRST ROUND'S FIX WIDENED THE
PREDICATE AND KEPT THE SET — the bd `8h7d.5` F-1/F-3 lesson a THIRD time, in the
same file, one round later** (2026-09-05, lens R1 finding F-R1-1, CONFIRMED
SILENT MISCOMPILE). The range question was asked of `H`, the compare's own tainted
operand, and `clang -O1` does not leave the pinned register there: IPSCCP proves
the theorem about a register **X**, substitutes it into the arm, and a LATER
InstCombine rewrites the COMPARE downward onto an ANCESTOR of X — so X ends up a
FORWARD USER of the `H` CQ sees. **Six plain-C programs accepted with X ALIVE in
the emitted circuit, MEASURED by the source, and never rotated**
(`t = 5+(q&1)`, `(q&1)^7`, `(q&1)-4`, `(q&1)|8`, `((unsigned)q)>>31`, `q>>31`);
the pre-Inc-4 binary declined every one. F2 now asks its singleton question of a
**BOUNDED FORWARD CLOSURE** — seeded with (`H`, `H`'s value set on this edge) and
pushed forward through `H`'s TAINTED same-type integer `op constant` users with
`ConstantRange::binaryOp`, depth 8 / 64 values, **the bound itself declining**.
Casts are NOT followed (a cast is a different physical wire — every cast CQ can
lower is out of place, §14.2c) and φ/`select` are NOT followed (under CQ a live
classical mux is refused outright and the ones that survive become a FRESH merged
register via the 4.4 copy merge). **THE RESIDUAL IS NARROWER THAN THE ROUND-1
TEXT SAID, AND THE ROUND-1 TEXT'S ERROR IS THE POINT**: it read "instcombine
deletes the register AND rewrites the compare onto an ancestor", conflating two
events — the rewrite ALWAYS happens (now fenced) and the DELETION only sometimes
does. What remains is the deleted-register half, and it is bounded for a reason
worth carrying: a register is deleted only when NOTHING READS IT, so the
difference between rotating that rail and rotating a fresh one prepared to the
same pinned value is confined to a leaked ancilla no `cq_measure`/`ret`/tape
write observes — the move the `fenv` ruling already blesses. **That argument does
not extend one inch to the six, where the register IS read.** Measured members —
**five, and the round-1 list is UNCHANGED**: `k03`, `k04`, `r3`, `r4`, `r6`
(`int b=(q!=5); int r=0; if(q==5) r=cq_theta(b,.9);`), whose `@slice` body is
BYTE-IDENTICAL to the flagship slice's. ⚠ `k03` (`((unsigned)q)>>31` with the
result NEVER MEASURED) stays in the residual and `x23` — the same expression with
`cq_measure(s)` added — is one of the fenced six: **one token apart, opposite
dispositions**, which is the always-vs-sometimes boundary made concrete. Every alternative
source in that class is a data MUX that CQ refuses whenever the register survives,
so it is filed as PRD §14.11 Q3, not fenced. A second measured over-accept rides
with it and is **hand-IR only**: `ConstantRange::fromKnownBits` is a HULL, so
`and q,4` reads `[0,5)` and its true `{4}` pin is missed — harmless today only
because IPSCCP's lattice is a `ConstantRange` too and therefore performs no fold
either, i.e. the two analyses fail together (retirement trigger: a known-bits-aware
SCCP). ⚠ **AND THE THIRD ADVERSARIAL ROUND FOUND THE SAME MISTAKE A THIRD TIME,
THREE MISTAKES WIDE — 42 plain-C CONFIRMED SILENT MISCOMPILES — SO F2 STOPPED
BEING A SET AND BECAME THE QUESTION** (2026-09-05, lens R3, findings F-R3-1/2/3).
Round 2's FORWARD closure left (i) the DIRECTION — `-O1` also moves the compare
**SIDEWAYS** onto a fresh SIBLING of the rotated register (`q/4 == 5` becomes
`icmp eq (and q,-4), 20`; `q/3 == 5` becomes `icmp ult (add q,-15), 3`), so no
forward walk from `H` can ever reach it (30 programs, incl. one whose own trace
rotates the same wire IN PLACE two lines later); (ii) the OPCODE CLASS — the walk
enumerated `BinaryOperator` users while `IntrinsicLowering` lowers a curated 16-strong
`llvm.*` family to real rails (`bswap`/`bitreverse`/`fshl`/`fshr`, 4 programs);
and (iii) a **K/seed TYPE GATE one line above the walk's caller** that skipped ALL
of F2 whenever `-O1` narrowed the compare to the root's width — which is what an
ordinary `long long t = q;` does (8 programs, the `sext` rail live and measured).
**F2 is now SEMANTIC** (`f2SeedPinnedByLiveRegister`): `LazyValueInfo::getConstantRangeOnEdge`
on BOTH edges about every tainted integer value LIVE ON THE EDGE (the BACKWARD half,
by a real edge analysis rather than a preimage table), plus an abstract evaluation
forward over the tainted user graph using LLVM's OWN machinery — `ConstantRange`
binaryOp/castOp/intrinsic, EXACT `ConstantFold*` once every operand is pinned, and a
`KnownBits` refinement — with the test spelled as `Constant *` POINTER IDENTITY
against the seed, so there is no type gate and an fp seed is covered for free.
The forward closure is DELETED, not kept as a second spelling. **It still skips one
thing, and the argument is the fence:** a tainted user it cannot bound whose operands
are none of them pinned is skipped, because `clang`'s own lattice is overdefined there
too and could not have folded the seed from it (`@cq_theta`/`@cq_phi` are the everyday
members); but a value it cannot bound that HAS an exactly-pinned operand DECLINES.
⚠ **AND THE FOURTH ROUND FOUND THAT SENTENCE FALSE FOR EVERY `CallBase`, PLUS AN
ENTIRE TYPE FAMILY THE BACKWARD HALF NEVER ASKED ABOUT** (2026-09-05, lens R4,
findings F-R4-1 / F-R4-3; the round found **0** `clang -O1`-reachable accepts in 270
new programs, so what it found is a hand-IR miscompile and two false doc claims, not
a fifth generation of the same mistake). (i) **fp was structurally invisible**: LVI is
defined over `ConstantRange` — an integer lattice — so the anchor loop is
`isIntegerTy()`-gated and NO floating-point register was ever asked F2's question. A
live f64 pinned to 5.0 by the region's own `fcmp oeq`, seed 5.0, ACCEPTED and measured
the rail UNROTATED, against an unconditional twin that is byte-identical on both
binaries and rotates it in place. Worse than the module, the shipped comment carried a
RETIREMENT TRIGGER claiming the clause "needs no change" the day LLVM gains that
fold — false in both halves. The fix is an **fp ANCHOR**, not a wider query (there is
none to make): an equality `fcmp` against a `ConstantFP` pins its tainted operand on
the edge where the equality HOLDS (`oeq`/`ueq` true, `one`/`une` false), with **±0.0
and NaN constants REFUSED** (`oeq` with `0.0` admits `-0.0`, so the edge is not a
singleton — which is also why `clang` cannot perform the substitution); the FORWARD
half is reused unchanged, so no second walker exists. `clang -O1` still does not
produce that IR at LLVM 19 (`EarlyCSE` runs before `IPSCCP`, and `propagateEquality`
will not cross `fcmp oeq`), and the unfolded shape keeps declining. ⚠ **THE ANCHOR
COSTS A REAL `clang -O1` ACCEPT AND THE COST IS THE fp MIRROR OF §14.11 Q1**:
`double r = 5.0; if (q == 5.0) r = cq_theta(5.0, θ);` and its `!=` twin ACCEPTED at
the round-3 HEAD and now DECLINE (measured from C), with the same ONE-CHARACTER
workaround the integer class documents — any seed other than the compare constant
(`cq_theta(7.0, θ)`) accepts. For integers that over-decline is FORCED (clang really
does substitute, so the two spellings arrive byte-identical); at fp it is
PRECAUTIONARY, and it is shipped anyway because the alternative is a fence correct
only while one optimiser declines to do something — which is the assumption this
round found written down as a retirement trigger and false. (ii) **the
conservative half took its `CallBase` early return BEFORE computing whether any
operand was pinned**, so the rule was never asked for that whole class — a `nobuiltin`
`@llvm.bswap.i32` with its operand pinned to `{5}` and the seed `bswap(5)` ACCEPTED.
The order is reversed, and the not-foldable branch now DISTINGUISHES: an OPAQUE callee
(`@cq_theta`/`@cq_phi`, a specialised clone, any declaration) is still skipped on the
original argument, while a call `isCuratedReversibleIntrinsic` accepts — a pure total
function CQ LOWERS TO A RAIL — takes the conservative DECLINE. A `load` structurally
cannot reach the rule (its only operand is a pointer) and is a documented SKIP, not a
decline. (iii) `kF2MaxSteps` = 4096 was reachable and pinned by NOTHING; it now has a
straddling pair (4090 accept / 4200 decline) and the exact boundary is recorded —
`Steps = N + 2`, so the cap is exactly 4096.
⚠ **The LVI dominance filter is an API precondition, not an optimization** — asking
LVI about a value defined after the branch SIGSEGVs a Release `cq-opt`
(`solveBlockValueNonLocal` `cast<Argument>`s any non-Argument entry-block live-in),
which is exactly why the forward half is not redundant with LVI. ⚠ **THE `i1`
STATE-PREP WIDTH IS OUT, and it is the one capability this cost**: the branch
condition is itself a tainted `i1` pinned to `true` on one edge and `false` on the
other, so every `i1` seed collides — the ARM half is plain-C reachable and was a live
miscompile behind the type gate (`_Bool c=(q==5); if (c) r=cq_theta(c,.9);` arrives as
`cq_theta_i1(i1 true,…)`), while the MERGE half is an over-decline at this clang and
the fixture says so. The round-2 `fromKnownBits` HULL over-accept above is now
**CLOSED** (the ≤256 `Known`-consistent enumeration it named as its own fix), and
the residual is narrowed once more: the deleted-register difference is confined to a
leaked ancilla **only when no value DERIVED from the deleted register is observed** —
`n03_k03_derived` is the measured counterexample, and its unfolded twin declines on
BOTH binaries with `operand predates a non-diagonal gate`, so that class is reachable
only through the fold (PRD §14.11 Q3, notes §12.2). An if/else prep declines
`if/else state prep allocates two rails` when BOTH arms are preps and
`if/else state prep beside a chained or phase arm` otherwise (owner ruling; from C
it is an angle select refused at S3 — follow-on `drbq.13`), and F1's second clause
says `state prep merged with a quantum register` when the pred incoming is
TAINTED — a no-cloning mux, which is what the folded plain-C R4 program actually
is. ⚠ **AND THE INCREMENT'S HEADLINE IS AN
OVER-DECLINE IT COULD NOT HAVE PREDICTED**: `int s = r * 3;` after the region
DECLINES, because a state-prepped register's straight-through value is a
compile-time constant, so `-O1` SINKS the op INTO the arm and R1 refuses the
two-instruction arm — 48 of the 297 `--stateprep` twin-matrix cells, invisible to
the chained twin, which is why no probe saw it (PRD §14.13). Ry on the
CONDITION's own wire, nested, switch, `ShareCondFlag`, a Q+Q condition
(PRE-EXISTING — the in-place emitter's flag mint passes no Q+Q width, and the
chained twin declines identically on the pre-Inc-4 oracle),
multi-gate arms and any post-region read of the pre-Ry record all keep declining
(**`in-loop` LEFT THIS LIST at bd `drbq` Inc 3 — see the in-loop paragraph above;
what still declines in a loop is an ITERATION-LOCAL rotated register, a rail whose
header φ the round-2 collapse will not claim, an irreducible or multi-latch loop, a
nested loop, and every one of the flat declines listed here**)
— the last one over the base's whole RAIL closure, φ/select/freeze crossed
FORWARD (a classical join φ over one register laundered a `cq_measure`/`ret`/tape
write/clone arg/`cq_invert` past the fence: the round-1 review's second confirmed
silent miscompile). Read
`docs/prd/phase-04-swap-route-control/{control-in-place-PRD,CONTROL_IN_PLACE_INC1_NOTES}.md`
§11 / findings K-M before touching any of it.
**The plain C `if/else` with a rotation on ONE register in each arm compiles for
BOTH stems since bd `drbq` Inc 2b** (2026-09-03, PRD §12.3): `clang -O1` never
hands that source to the pass as a diamond — SimplifyCFG merges the two arms into
ONE call whose ANGLE is a tainted-condition `select` — so `SelectClassify`'s
gate 3 hands it to `classifyAngleSelect` (`ArmClassify`, S1–S10) and
`AngleSelectEmit` lowers it BY DIFFERENCE: an unconditional `R(h, B)`, the
ordinary flag mint, ONE `cqrt_{ry,rz}_<W>_controlled(f, h, A−B)`, the ordinary
`_unc` strip, one `cqrt_free`. Exact in REAL arithmetic by angle additivity on one
axis (`Rz`'s two diagonals multiply entrywise, so no global-phase residue); in
IEEE double the emitted true-arm angle is `B + fl(A−B)` with
`|δ| ≤ ½ ulp(A−B)`, so **BOTH ARMS MUST BE CONSTANTS** (`ConstantFP`), fenced at
the placeholder 2^-40 rad. A **RUN-TIME arm declines** `rotation angle`: the
compiler would synthesize an `fsub` the source never wrote, whose error is
unbounded in absolute radians (`Ry(π)` realized as `Ry(4.0)`, measured from plain
C) and which can be `inf`/`NaN` from two FINITE arms (`inf` in the controlled gate
from `±8.99e307`) — neither fenceable at compile time, both retired by the
two-controlled form on the owner's desk. That narrowing is the Rule-13
**clearance** review's blocker F-11 and owner option (2); the widening back is one
line. NO new frozen symbol,
no CFG surgery, no hoist, no `cqrt_x` — a select always means "A when the flag is
1", so there is no polarity case at all. Ry keeps EVERY Inc-1 fence verbatim (R4
disjoint wires, R6 stale record, the structural freeze); Rz is exempt from both
on the §12.1 diagonal argument. The witness is BYTE IDENTITY with the manual
by-difference twin (`r = R(r,B); if (c) r = R(r,A−B);`), an in-place diamond the
PRE-2b binary already lowered — three e2e `compare_files` twin gates plus a
158-cell all-pairs twin matrix (`tools/angle_select_twin_matrix.py`, 102
BOTH-ACCEPT-IDENTICAL + 16 EXPECTED-DECLINE-RUNTIME-ARMS, 0 MISMATCH — the 16
`args` cells are the red-green witness that a run-time arm declines, and their
twin accepts only because that harness passes the difference in as a PARAMETER
and performs no subtraction). **Scoped to ONE consumer per select**;
N consumers, two selects on one compare, a compare shared with a region or a data
use, a Q+Q or compound condition, a `float`-armed select, a RUN-TIME arm, a
classical arg-0 (state prep), a cross-block consumer, an in-place `Ry` in the
compare→consumer window and every in-loop form decline loudly. **The round-1 Rule-13 review added
two fence families and they are not cosmetic** — S7's loop question was spelled
`LoopInfo`-only and was therefore NARROWER than every sibling's, which accepted
an angle select on an IRREDUCIBLE cycle (invisible to `LoopInfo`) and one whose
rotated register's RAIL lives in a loop while the three anchors sit in its exit
block (`lowerLoops`'s `staleRailRecordRead` runs 13 pipeline steps too early to
see 2b's twin, so the manual twin declines and the select form did not). S7 now
ORs `LoopInfo`, `ControlShape.h`'s `blockOnCycle` walk over `Cond`/`Sel`/`T`'s
blocks, and either question over EVERY MEMBER of the base's rail closure — which
is now computed for BOTH stems (the Rz stem computed none) once and reused by S8
and S9 unchanged. And nothing in S1–S10 inspected the arm VALUES: an
`undef`/`poison` arm folded the difference to a concrete NaN and destroyed the
DEFINED arm, a non-finite constant arm or an overflowing difference of two FINITE
ones manufactured an `inf`/`NaN` the source never named, and the IEEE rounding
above went unfenced. **The ROUND-2 review then reviewed those fixes and found
three more things about them** (notes §10): the arm-value fence split the world
with `dyn_cast<ConstantFP>`, so a `double` `ConstantExpr` — a LINK-TIME constant
whose value this compiler cannot read — fell into the `else` labelled "runtime
arm" and bypassed every value clause (now refused; hand-IR-only); the S7 comment
claimed it "asks all three questions, ORed, over-declining by construction" when
the rotated register's rail FORWARD of the consumer and the CONDITION register's
rail are asked by NO prong (both accept, both byte-identical to the manual twin on
the pre-2b oracle, so the disposition is Inc-1's structural freeze, not 2b's —
accept fixture `control_angle_select_forward_rail_cycle_frozen.ll`); and prong
(iii)'s coverage of the loop-rail family is CONTINGENT on `lowerLoops`' Case-A
rail collapse having re-anchored the in-loop gate, so a change there silently
narrows S7. It also found that the 2^-40 threshold was pinned by NOTHING (the
suite stayed green for any value in `(2^-54, 0.858]` and for a `>=` re-spelling)
— now pinned by a δ = exactly-2^-40 accept and a δ = 2^-39 decline.
**AND THE CLEARANCE REVIEW THEN BLOCKED ON THE HALF BOTH ROUNDS HAD LEFT OPEN**
(finding F-11): the whole value fence was `ConstantFP`-GATED, so every one of its
clauses was silently skipped for a RUN-TIME arm — a shape inside the shipped
accept class, reachable from plain C, wrong on `π`/`1e16`, and declined loudly by
the pre-2b binary. The decisive new fact was that the manual by-difference twin
of that shape **declines on both binaries**, so the residual was reachable only
through 2b rather than inherited. Shipped: option (2), constant arms only. Cost:
two fixtures rewritten, 0 goldens, 16 twin-matrix cells reclassified.
TWO fixtures FLIPPED to accept and were rewritten
(`control_swap_defer_select_angle.ll`,
`control_swap_reject_switch_datamux_angle.ll` — the second's "a Rule-3 f64/angle
wrong unitary if lowered" header was true of the lowering that existed then and
is false of this one: 2b never realizes the angle as a number; its arms were then
changed from run-time parameters to the constants 0.9/0.3 by the clearance
narrowing, with the run-time spelling kept as its own decline fixture). ⚠ One protection
is NOT in S1–S10: the flag is minted AT THE CONSUMER, so an in-place
`cqrt_addc`/`cqrt_xorc` on the CONDITION's rail in that window would mint a wrong
predicate — it is correct on every measured reproducer only because `lowerOps`
runs later and M-C refuses an in-place conversion when a later read exists (our
own mint and strip). Read `CONTROL_IN_PLACE_INC2B_NOTES.md` findings G/H and §8
before widening anything.
**Every other tainted-control shape loudly declines** (deeper or non-homogeneous nests; the switch off-pattern matrix: multi-phi
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
- **Method matches arm class, not convenience** (Rule 7). Phase arms put the
  answer ON THE FLAG (the kickback `cqrt_rz_i1(f, θ)`, 3qlq Inc 1) and strip the
  flag with `icmp_inv`; nothing is emitted on `q` at all. ⚠ The two earlier
  readings — "keep the answer in place on `q`", and drbq Inc 2a's one
  `cqrt_rz_<W>_controlled` on the FLAT path with the nest and the switch keeping
  the route — are HISTORY, and both are the shape that made Grover the identity;
  method-A rail cleanup is still dropped. Bennett compute→copy→uncompute
  (**method-B**) is the
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
  pair that shares its merge and lowers correctly. **Nor is the block-lifetime
  hazard a reason to decline the SEQUENTIAL pair, and for four months it was
  treated as one** (bd `hcrg`, fixed 2026-08-27): `if(q){…}; if(q'){…}` puts
  region 2's branch inside region 1's merge after `-O1`, and that declined as
  `nested control flow` — a STRUCTURAL guard wearing a semantic label. The hazard
  is a teardown **order** bug, so it is now fixed by ORDER:
  `lowerControlRegions` builds a precedence graph (A before B when A names a
  block B's flatten erases), Kahn-sorts it, and declines loudly only on an alias
  ordering cannot resolve or a cycle. The emitted gate stream is unaffected —
  each emitter inserts positionally into its own pred block, so source order
  survives a reversed emission order (`slice_control_seq_regions` /
  `slice_control_seq_grover` are the byte-level goldens). The lesson generalizes:
  **before declining a shape, ask whether the thing you are protecting is the
  unitary or the emitter's bookkeeping** — only the first is a Prime-Directive
  decline.

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
# NEVER `--target CQPass` ALONE. `%cq-opt` (build/ir-pass/cq-opt) is a SEPARATE
# TARGET built from the SAME sources, and every lit RUN line goes through it — so
# a CQPass-only rebuild leaves lit on a STALE binary and reports FALSE GREEN.
# MEASURED THIS INCREMENT (bd 8h7d.5): 100% pass on a knowingly broken pass, then
# 49 reds the moment cq-opt was built. Two fix agents and one reviewer hit it.
cmake --build build -j8                    # the safe default: builds both
cmake --build build --target CQPass cq-opt # if you must name targets, name BOTH

# Full suite. NOT the inner loop — see Rule 19: run the layer that can WITNESS
# your change (one fixture 1.5s, one slice 1.7s), and keep the full run for the
# five gate moments (Rule-13 core commit · pre-push · harness change · template
# regen · accept/decline predicate change).
#
# 348 ctest entries (2026-09-06 — **UNCHANGED by the THIRD C-1 review round**, which is
# narrowing-only and adds 7 lit fixtures and NO e2e slice or gate; re-measured
# `ctest -N` **348 / 338 `^e2e-` / 308 `^e2e-slice-`**. Was set by the **SECOND C-1 review round** on branch
# `3qlq-inc1-fix-c1` — findings F-C1-1 / F-C1-2: **+6 over the 342 below, every one
# in the e2e layer**, so `^e2e-` goes 332 → 338 and `^e2e-slice-` 304 → 308.
# ADDED, 4 slices: `e2e-slice-control-phase-perbit-loop-mixed-preadd{,-unrolled}`
# (the mixed loop plus ONE line, `q = q + 7;` in the PREHEADER — F-C1-1) and
# `e2e-slice-control-phase-onward-perbit-loop-mixed{,-unrolled}` (the mixed loop
# whose invariant register is a 6.5 classical-call-arm `%out`, TWO TUs through
# `run_slice_multi.sh` — F-C1-2). ADDED, 2 `compare_files` twin gates:
# `e2e-phase-perbit-loop-mixed-preadd-twin-identical` (38 = 38, was 32 vs 38) and
# `e2e-phase-onward-perbit-loop-mixed-twin-identical` (47 = 47, was 41 vs 47).
# REMOVED: none. ⚠ The `r40` shape — a round-1 region and a round-2 onward region
# in ONE loop — gets NO e2e twin, because its hand-unrolled spelling declines
# `control flow under quantum control` on every binary in the epic (OQ-C1-3 / bd
# `3qlq.9`); it is pinned in lit with a structural per-trip pairing assertion
# instead, which the fixture header says outright. MEASURED with `ctest -N`. Two
# other counts moved with it: the lit corpus 1660 → **1666** (below; this line said
# 1665, one short of the tree it shipped in — corrected by the THIRD C-1 round, notes
# §3.11 F-C1B-5, which then took it to **1673**) and the twin
# matrix 284 → 286 cells / 255 → 257 expected rows (UNCHANGED by round 3 — its
# `e2e-loop-twin-matrix` run was **Passed, 181.66 s**, no cell moved). Its own gate run was
# `ctest -j6 -R 'perbit|onward-perbit|twin-identical|quarantine-selftest'` ->
# **30/30, 4.21 s**, plus `e2e-loop-twin-matrix` **Passed, 176.31 s** at 286 cells
# and `ir-pass-lit` **Passed, 33.35 s**; the FULL suite is the orchestrator's gate
# and this round did not run it), was 342 (2026-09-06, the bd
# `test_C_libtooling-3qlq` **C-1 FIX ROUND**
# on branch `3qlq-inc1-fix-c1` — the clearance BLOCK: **+3, every one in the e2e
# layer**, so `^e2e-` goes 329 → 332 and `^e2e-slice-` 302 → 304. ADDED, 2 slices:
# `e2e-slice-control-phase-perbit-loop-mixed{,-unrolled}` (D4's per-bit idiom with
# ONE ancilla rotation added to the body — the mixed invariant-root + loop-carried
# register that leaked its `and` rails per activation). ADDED, 1 `compare_files`
# twin gate: `e2e-phase-perbit-loop-mixed-twin-identical` (rolled == hand-unrolled,
# 37 = 37). REMOVED: none. MEASURED with `ctest --test-dir build -N` in that
# worktree and name-DIFFED against the 542d588 build's list — never by subtracting
# or by adding up hand-backs. Two other counts moved with it and are recorded at
# their own lines: the lit corpus 1656 → 1660 (below) and the twin matrix 274 → 284
# cells (the matrix paragraph above). Nothing ELSE moved, and that is the fix's own
# witness: the fix agent's `ctest -j6 -R '^e2e-'` on its build was **332/332** with
# **no pre-existing golden and no pre-existing matrix cell changed** — the +10
# matrix rows are the NEW axis added afterwards, not a moved verdict), was 339
# (2026-09-05, bd `test_C_libtooling-3qlq` Inc 1 — the
# register-free `cq_phi`: **+15 ADDED, −3 REMOVED**, net +12, every one in the e2e
# layer, so `^e2e-` goes 317 → 329 and `^e2e-slice-` 293 → 302. MEASURED by
# `comm` over the two `ctest -N` name lists — this checkout's build against the
# pre-3qlq ORACLE build at 52d7764 — never by adding up hand-backs.
#   ADDED, 11 slices: `e2e-slice-control-phase-{andcond,angle-select,
#   angle-select-runtime-arms,grover,grover-loop,grover-loop-unrolled,nest,
#   perbit-loop,perbit-loop-k32,perbit-loop-unrolled}` + `e2e-slice-loop-phase-
#   accum-unrolled`. ADDED, 4 `compare_files` twin gates:
#   `e2e-phase-{grover-loop,perbit-loop}-twin-identical` (rolled vs hand-unrolled —
#   D4's per-bit idiom and Grover-as-a-loop), `e2e-phase-nest-andcond-identical`
#   (the depth-2 nest vs the `&&` spelling — ONE golden, two sources) and
#   `e2e-loop-phase-accum-twin-identical`, which closes a byte-identity claim
#   `slice_loop_phase_accum.c`'s header had asserted since Phase 7.3 Inc 1 **with
#   no twin in the tree**.
#   REMOVED, 3, each with a reason and none of them a capability loss:
#   `e2e-slice-loop-break-qq-phase` (its stage-1 IR became byte-identical to
#   `slice_loop_break_qq`'s once `cq_phi` lost its register — a duplicate, OQ-5;
#   this is also why the `--allow-unproven` count above went five → four),
#   `e2e-angle-select-rz-twin-identical` (its twin's global phase is DELETED by
#   D2, so no byte-identity twin for the Rz angle select is expressible under the
#   void surface at all — OQ-15, and the reviewers had to argue P2's unitary
#   analytically instead), and `e2e-slice-control-switch-phase` (P5, the phase
#   `switch`, has NO plain-C `-O1` customer: every phase arm's body is one
#   `call void @cq_phi(double)`, so SimplifyCFG's common-code sinking ALWAYS
#   applies and dense arms become a `@switch.table` of angles with ONE shared
#   call. The `.c` is KEPT in the tree UNREGISTERED with the measurement in its
#   header, the capability is pinned in lit, and both `-O1` outcomes are pinned as
#   loud declines — OQ-4/OQ-11, owner question).
#   NOT a ctest entry, deliberately, following the drbq instrument precedent: the
#   `--epic 3qlq` mode of `tools/golden_multiset_audit.py` (the 71-golden
#   substitution audit), and the three twin-matrix instruments' POST records under
#   `docs/prd/phase-04-swap-route-control/inc1-records/`.
# was 327 (2026-09-05: +3 for the bd drbq Inc-4 controlled-STATE-PREP
# group — `slice_control_inplace_ry_stateprep{,_negated,_twin}.c`, all STRICT
# stage 2b. There is deliberately NO `cmp` twin gate: the witness is byte identity
# between the SUBJECT golden and a REDUCTION of the TWIN golden (delete the
# `Ry(0)`, move the fresh-rail alloc, renumber — PRD §14.8), so the two goldens
# differ by a reduction and a `compare_files` gate would assert something FALSE.
# The twin is committed as a slice in its own right so a reviewer can re-derive
# the reduction by hand from two files in the tree. Its lit fixtures — 59 at
# hand-back (20 accept / 39 decline; the "58" first written here was an arithmetic
# slip, lens L5 F-L5-4) and **76 after the round-1 Rule-13 review (28 accept / 48
# decline)** — add NO ctest entry, and neither does the `--stateprep` twin matrix
# (297 cells, pre-4 and post-4 tables committed under `inc4-records/` — the PAIR is
# the witness), following the Inc-1/Inc-2b instrument precedent exactly.
# was 324 at 2026-09-04: +19 for the bd drbq Inc-3 in-loop controlled-Ry
# group — 12 e2e slices (6 rolled + 6 hand-unrolled twins), 6 `cmp` twin gates and
# `e2e-loop-twin-quarantine-selftest` (the quarantine's own mutant validation:
# TWELVE cases, no clang/opt/plugin, 0.2 s — a quarantine nobody has tried to fool
# is a quarantine nobody should trust, the `free_pairing_check_test.py` argument
# applied to the one mechanism that can make a divergence pass this gate; it was
# seven cases until the ROUND-2 review, whose five additions drive `--regenerate`
# and `--refresh-quarantine`, the two modes nothing exercised and both defective,
# three of them asserting on FILE BYTES because the defect exited non-zero WHILE
# writing);
# its 45 lit fixtures (21 accept / 24 decline, corpus 1430 -> 1474 including one
# EXISTING decline rewritten as an accept and re-homed) add NO ctest entry, and its
# K-independence check is a MEASUREMENT with no entry either, following the 8h7d.5
# precedent for `slice_control_grover_loop_dynamic` exactly. The last of those
# 18 is the round-1 review's O(K)-freeze-leak pair
# (`slice_control_inplace_ry_loop_leak{,_unrolled}.c` + its `cmp` gate) — the only
# program in the tree that reads the ROTATED register inside the body, which is
# what turns PRD §13.5's "K rails at run time" from analytic into MEASURED (2
# TEMPLATE-minted rails per activation, never freed, twin byte-identical, and
# STRICT stage 2b is structurally blind to all of them). ⚠ `e2e-loop-twin-matrix`
# was RED at hand-back on 15 of its 273 cells and is GREEN since the round-1 review
# moved those 15 into the PINNED-SIGNATURE quarantine
# `tools/loop_twin_matrix.quarantine.txt` (258 expected rows + 15 quarantined; a
# quarantine is NOT a blessing — it fails if the divergence signature CHANGES and
# equally if the cell STOPS diverging) — two PRE-EXISTING divergence classes the
# Inc-3 axis exposes, both reproduced character-for-character on the pre-Inc-3
# oracle with an Rz arm and both absent from a no-region control, now bd
# `test_C_libtooling-1m5p` / `test_C_libtooling-a3z7` awaiting an owner
# disposition. See
# CONTROL_IN_PLACE_INC3_NOTES.md §10.1. was 305 at 2026-09-03: +10 for the bd drbq Inc-2b angle-select group — 7 e2e slices (3 subject/twin pairs + the derived-base freeze) and 3 `cmp` twin gates; its lit fixtures (46 at hand-back, 62 after the round-1 Rule-13 review, 66 after the round-2 one, **68 after the CLEARANCE one** — which also DELETED one accept fixture and added a fourth decline outside the family name, corpus 1430) and its instrument `tools/angle_select_twin_matrix.py` add NO ctest entry, the instrument deliberately so, pending the same owner cost decision as the other two; was 295 at 2026-09-02, UNCHANGED by the bd drbq Inc-2a Rz peephole, which adds 9 lit fixtures and NO ctest entry — it regenerates 26 existing e2e goldens rather than adding slices; +3 for the bd drbq Inc-1 control-in-place group — the round-2 Rule-13 review added 2 lit FIXTURES and 2 `tools/` instruments but NO ctest entry, deliberately: `tools/inplace_twin_matrix.py` and `tools/control_flag_order_check.py` are instruments pending an owner cost decision, not gates — 2 Inc-1 slices + the round-1 Rule-13 review's derived-base freeze slice; 2026-08-30: +7 for the bd 8h7d.5 Rule-13 round-4 group — 4 slices, 2 `cmp` twin gates and `e2e-loop-twin-matrix`, the rolled-vs-unrolled matrix that is the ONLY instrument in the tree that can see a leaked TEMPLATE-minted rail (100 cells when added, 120 after the round-5 `range` axis, 156 after the bd drbq Inc-2a round-1 review added the RECORD axis, **273** since the bd drbq Inc-3 CONTROLLED-Ry-ARM axis (+117, committed at pre-Inc-3 dispositions BEFORE the lowering, which is what makes its diff the witness) — no `int mark = a;` existed in any cell until then, which is the shape 8h7d.5's F-1 and F-3 lived in; re-measure with `grep -c '^m_' tools/loop_twin_matrix.expected.txt` rather than trusting this); +3 for the Rule-13 round-1 two-register group — 2 slices + 1 `cmp` twin gate; 2026-08-29: +18 for the bd 8h7d.5 in-loop-control group — 7 rolled/unrolled/dynamic slices + 3 `cmp` twin gates, and the rest are the earlier libm/e2e growth; 2026-08-27: +2 for the bd hcrg sequential-region slices; the
# figures below were taken at 252/253 and their RATIOS still hold). RUN IT PARALLEL
# — `-j` is the default, not an
# optimization. MEASURED 162s at -j6, 252/252 pass (2026-08-13), down from 825s
# serial: 5.1x. RE-MEASURED 2026-08-17 on a QUIET box, 253/253 three times: 127s,
# 189s, 226s at -j6. So there is no single number — the spread tracks how warm the
# stage-1 content-addressed cache is (127s was a warm re-run; 189s/226s followed a
# full rebuild) plus scheduling luck. Treat ~130-230s as the quiet-box band and
# NEVER quote one figure as the expected time. UNDER CONCURRENT AGENT LOAD the owner
# measured 256-368s, which is NOT comparable: budget command timeouts from the
# loaded figure, and only ever compare two runs taken under the same load.
# ONE MORE LOADED DATA POINT, 2026-09-05 at the 3qlq Inc-1 merge: **399s wall for
# the full 339 entries**, under concurrent agent load, with the `-j` not recorded
# in the log — which is exactly why it is quoted as a loaded figure and not
# compared to the quiet band. `e2e-loop-twin-matrix` alone was 399s of that (it
# runs from the start and finishes last), so the suite's long pole is now the
# matrix, not `ir-pass-lit` (54.8s in the same run). Four independent changes got that, each verified green:
#   -j6 itself            825 -> 349s   (the single biggest win is scheduling)
#   lit opt-spawn dedup   -> lit 143 -> 104s wall, 925 -> 671s CPU
#   python shim bypass    -> stage 2b 0.39 -> 0.145s per slice
#   stage-3 link split    228 -> 162s, 1140 -> 778s CPU  (bd dgn5)
# NONE of this deleted a test or regenerated a golden. The suite was slow
# because it re-spawned processes, not because it had too many tests.
# -j scaling (measured BEFORE the last three, so the absolute numbers are
# stale but the ORDERING holds): -j4 322s · -j6 265-349s · -j8 284s · -j12
# 308-341s. -j6 is the pick; -j12 oversubscribes (6 physical / 12 logical
# cores) AND ir-pass-lit already forks 12 lit workers internally, so -j6 is
# ~17-way concurrent already. Never compare a -j figure to a serial one.
# The suite is embarrassingly parallel by construction — every slice works in
# its own `mktemp -d`, every lit fixture on `%t`, every python gate in a
# TemporaryDirectory; there are ZERO RUN_SERIAL / FIXTURES_* / RESOURCE_LOCK
# properties in the tree, and 10+ full parallel runs have never failed.
# Use -j1 ONLY to isolate a suspected flake. Contention causes false FAILURES,
# never false passes (a parallel run cannot hide a miscompile), so the rule is:
# re-run any -j failure serially BEFORE calling it a regression.
# NOTE: these figures are MEASURED, not estimated, and they go stale on every
# fixture batch — if yours disagree, re-measure and update rather than trusting
# the doc. Budget command timeouts from the wall time, NOT from a guess: a run
# that looks hung at 60s is almost certainly just running. Parallel figures are
# NOT comparable to the historical serial 825s / 1427s numbers.
cmake --build build -j8 && ctest --test-dir build -j6 --output-on-failure

# One layer at a time
ctest --test-dir build -R ir-pass-lit  --output-on-failure   # ONE ctest entry wrapping 1673 *.ll fixtures (1 XFAIL: lowering_invert_add_i32.ll, Phase-7 tracker; **1673 since the THIRD C-1 review round on branch `3qlq-inc1-fix-c1`: +7 over the 1666 the second round left** — 2 narrowing ACCEPTS asserting 542d588's CORRECT out-of-place stream for F-C1B-1's reproducers (`control_phase_kickback_mixed_preheader_r2derived_imm_outofplace.ll`, `..._r2derived_commuted_outofplace.ll`), 2 ACCEPT-AND-LEAKS controls (`..._preheader_volatile_imm_leak_control.ll` for the measured cost of the `isa<Constant>(Imm)` fence, `..._claim_across_loops_leak_control.ll` for F-C1B-2's per-loop key), the (1b) DECLINE `control_phase_kickback_reject_preloop_commit_stale.ll` (RED on 542d588, on the round-1 fix AND on the round-2 fix), and 2 DISCRIMINATORS — `..._preheader_chained_root_inloop.ll`, RED on the two PRE-round-2 binaries so it pins the CAPABILITY the tripwire must not blanket away, and `..._claim_across_loops_accept_control.ll`, green everywhere so the per-loop key cannot be a blanket refusal. The four narrowing files are RED **on the round-2 binary only** — that is the shape of a narrowing fixture. Injection matrix over the six accepts: first run **6 MISSED**, after adding the missing FCNT/XCNT/ACNT/MDCNT/UCNT prefixes and two `cqrt_rz_<W>` NOROUTE negatives, **0 MISSED / 0 DIRTY**. `ctest -R ir-pass-lit` on that build **Passed, 0 failed**; measured `ls ir-pass/test/*.ll | wc -l`. **1666 was the SECOND C-1 review round: +6 over the 1660 the first round left** — 3 ACCEPTS (`control_phase_kickback_mixed_preheader_addc_inloop.ll` for F-C1-1, `..._mixed_onward_inloop.ll` and `..._mixed_onward_r1open_inloop.ll` for F-C1-2's two causes; each RED on 542d588 AND on the round-1 fix binary, with the `and_i32_hl_unc` count as the discriminator) and 2 ACCEPT-AND-LEAKS controls (`..._mixed_preheader_add_outofplace_leak_control.ll`, where M-C itself goes out of place because the PRE-op value is read later, and `..._mixed_onward_deadgate_leak_control.ll`, one token from the accept — `int t = cq_theta(r,.1)` instead of `r = …` — where no collapse ever claimed the rail, so the marking must still be refused). Both controls are GREEN on all three binaries, which is how the two widenings are shown not to have reached the Q-R1-1 class; the injection matrix over all five is **0 MISSED / 0 DIRTY** after adding an `XCNT` prefix to the two that the FIRST run showed were blind to an injected `cqrt_x`. The SIXTH is `control_phase_kickback_mixed_short_sext_leak_control.ll` (finding F-C1-3): the C-1 accept's own source with `int` changed to `short` and nothing else, where `clang -O1` hoists a `sext` NOBODY WROTE into the preheader and the body's condition then reads a template rail — the Q-R1-1 class reached by a TYPE rather than by a cast, green on all three binaries and byte-unchanged, 0 MISSED / 0 DIRTY; **1660 was the 2026-09-06 C-1 fix round: +4 over the 1656 below** — the C-1 mixed-loop ACCEPT `control_phase_kickback_mixed_invariant_carried_inloop.ll`, the Q-R1-1 mixed hoisted-template LEAK CONTROL `control_phase_kickback_mixed_hoisted_template_leak_control.ll` (an ACCEPT-AND-LEAKS discriminator: it pins ZERO `and_i32_hl_unc` and ONE free, and it is MEASURED green on BOTH the pre-fix 542d588 binary and the fix build — which is how the C-1 widening is shown not to have reached the Q-R1-1 class), the B3 DECLINE pin `lowering_reject_break_phase_answer_kickback.ll` and its global-phase ACCEPT control `lowering_break_global_phase_before_accept.ll`; measured `ls ir-pass/test/*.ll | wc -l` in that worktree, and the 1656 the same way on 2026-09-05. ⚠ The `git diff --name-status 52d7764 HEAD -- ir-pass/test` census quoted in the next sentence reads **95 A / 17 D / 473 M** at that HEAD — the **+91 ADDED** below is the INC-1 figure, correct as of the Inc-1 merge and stale by exactly those 4 files; it is left as measured rather than restated, and the difference is not a migration). **bd `test_C_libtooling-3qlq` Inc 1 (the register-free `cq_phi`) took the corpus 1582 → 1656: +91 ADDED, −17 REMOVED, 473 MODIFIED** — MEASURED with `git diff --name-status 52d7764 HEAD -- ir-pass/test | awk '{print $1}' | sort | uniq -c`, against the pre-3qlq oracle commit, not by adding up hand-backs. Read those three numbers as three different things. The **473 MODIFIED** are the MIGRATION: every fixture whose subject was a `@cq_phi_<sfx>(x, φ)` had to be re-derived or re-spelled on the new surface (104 re-derived from the subject binary's own output, 143 re-spelled, 16 swapped to `cq_theta`, 6 retired), and **12 of them flipped DECLINE → ACCEPT** — each one reviewed by its own adversarial lens (`review_flips`, 0 over-accepts: 8 legitimate accepts renamed out of `reject_`, 4 retired because the property they pinned was the diagonal `cq_phi` gate itself and is now unrepresentable). ⚠ **A DECLINE FIXTURE THAT GOES GREEN BECAUSE ITS SUBJECT NO LONGER EXISTS IS NOT COVERAGE** — three fixtures LOST THEIR SUBJECT outright (they were built on `cq_phi(i32 CLASSICAL, θ)`, and an ill-formed CQ program is a well-formed LLVM module, so no oracle diff could see it), and a mechanical re-spell would have left them green while pinning nothing. The **+91 ADDED** are the new capability and its declines: `control_phase_kickback_*` **44 files (27 accept / 17 decline)**, `control_phase_switch_*` **10 (3/7)** — P5, hand-IR only — `control_phase_nest_*` **12 (5/7)**, `control_angle_select_phase_*` **12 (3/9)**, plus the six reserved-name / global-phase files `lowering_{legacy_phi_decl_prototype_family,phi_uncontrolled_deleted,reject_legacy_phi_register_form,reject_legacy_phi_register_form_eqfold,reject_phi_address_taken,reject_spec_branch_phase}.ll` (counts: `ls ir-pass/test/ | grep -c '^control_phase_kickback'` and `grep -l 'RUN: not'` for the decline half). **THE EMITTED Rz SET IS NOW `cqrt_rz_i1` ONLY** — round-2 lens R2 measured it over 1661 fixture outputs (35 emit an Rz, **0** at any other width), `#cqrt_rz_i1 == #!cq.branchphase` in every one, and the same holds tree-wide in the goldens (`grep -h 'cqrt_rz_' tests/e2e/*.expected.log | grep -v 'cqrt_rz_i1(' | wc -l` → **0**, and `cqrt_rz_<W>_controlled` → **0** of 304 goldens). That is owner decision D3 — no new runtime symbol, the emitted set SHRINKS — and `cqrt_rz_<W>` for W>1 plus `cqrt_rz_<W>_controlled[_inv]` are now DECLARED-BUT-UNEMITTED (ROADMAP Phase 4 / Phase 11). ⚠ The lit run recorded at the Inc-1 merge commit `be4e2ea` was **1656 discovered · 1 FAILED** (`lowering_reject_break_phase_answer.ll`, whose B3 string is pre-empted by an earlier `loop under quantum control` after the round-2 carrier fix); the very next commit re-points that fixture at the fence that fires. **I did not re-run lit for this doc pass and make no claim about the current colour.** ⚠ The B3 property that fixture pins now has a SECOND, dedicated file — `lowering_reject_break_phase_answer_kickback.ll`, built from the clearance's committed plain-C stage-1 module and mirroring `cq loop lowering: early break preserves a phase answer` character-for-character, with `lowering_break_global_phase_before_accept.ll` as its discriminating ACCEPT control (the D2-deleted bare `cq_phi` before the same loop, whose trace is byte-identical to the plain break loop's). The C-1 fix round reported its own `ctest -R ir-pass-lit` **Passed** at 1660 on its build; the 2026-09-06 doc pass re-ran nothing but `ctest -N` and makes no colour claim either. Historical count note (2026-09-03, when the corpus was 1582): measured AFTER the bd drbq Inc-2b angle-select batch AND BOTH its Rule-13 review rounds — Inc 2b added +46 `control_angle_select_*.ll` (15 accept / 31 decline) plus 2 REWRITTEN files that flipped to accept; the round-1 review added +16 (**2 accept / 14 decline**, MEASURED — the earlier "3 accept / 13 decline" here and in the notes was wrong, round-2 lens R2 N3) for the S7 cycle+rail prongs, the S1 arm-value/rounding fence, the emitter's step-0 S4 re-ask and the gate-2c window half; the round-2 review added +4 (2 accept / 2 decline) for the link-time-constant arm clause, the rounding threshold's two boundary cells and the forward-rail-cycle accept; the Rule-13 CLEARANCE review then narrowed the accept to CONSTANT arms (blocker F-11, owner option (2)) — **+4 declines, −1 accept DELETED** (`control_angle_select_ry_arg_angles.ll` replaced by `..._reject_runtime_arms.ll`), one of the four (`control_swap_reject_switch_datamux_angle_runtime.ll`) sitting outside the family name, so the corpus went 1427 → **1430** and the family 66 → 68. Then bd drbq Inc 3 (2026-09-04) added +29 at hand-back (**11 accept / 19 decline** across `control_inplace_ry_inloop_*.ll`, `control_inplace_ry_reject_inloop_*.ll` and the flat §13.4b pair `control_inplace_ry_{,reject_}post_region_theta*.ll`) and REWROTE one existing decline as an accept under a new name (`control_inplace_ry_reject_in_loop.ll` → `control_inplace_ry_inloop_diamond.ll`, its decline re-homed onto `..._reject_inloop_alias.ll`), corpus 1430 → 1459; **its round-1 Rule-13 review then added +14 (9 accept / 5 decline), corpus 1459 → 1473, family 30 → 44 files (20 accept / 24 decline)** — the F-L5-1 lifted-φ trio, the F-L5-2 tape pair, the F-L8-2 P1 coverage pair (derived condition + negated polarity), the L8 two-exit rolled loop, the L1 paired flat-decline/in-loop-accept witness for R6's two spellings, the L3 dead-rotated-register pair, and the L5-Q3 `phiTracksWire` refutation fixture. **Its ROUND-2 review then added +1 (1 accept), corpus 1473 → 1474, its own family 44 → 45 files (21 accept / 24 decline)** — the Rz twin named above. **It also CONVERTED 5 fixtures from trailing `CHECK-NOT`s to the whole-file `NOROUTE` prefix (F-L6-1: a `cqrt_cswap` injected into the LOOP BODY had left them GREEN) and removed a second, unstated `premark` refusal from the 3 CFG-gate declines (F-L6-2).** Family total on disk: **70 files, 20 accept / 50 decline** (`grep -L 'RUN: not' ir-pass/test/control_angle_select_*.ll | wc -l`) — 68/18/50 through the Inc-2b clearance, then +2 accepts from bd drbq Inc 3, one per STEM: `control_angle_select_ry_lifted_phi_after_select.ll` (round 1, F-L5-1's second customer) and `control_angle_select_rz_lifted_phi_after_select.ll` (ROUND 2, R1-Q1(c) — `AngleSelectEmit` records BOTH stems, so the Rz angle select flips oracle-decline → HEAD-accept exactly like the Ry one and nothing pinned it). **Then bd drbq Inc 4 (2026-09-05) added +57 net, corpus 1474 → 1531**: 59 files in the new `control_inplace_ry_{,reject_}stateprep_*.ll` family (20 accept / 39 decline) MINUS the 2 pre-existing files it RE-HOMED — `control_inplace_ry_reject_state_prep.ll` → `control_inplace_ry_stateprep_cond_ordered.ll` (DECLINE → ACCEPT with the IR UNCHANGED) and `control_inplace_ry_reject_inloop_stateprep.ll` → `..._reject_stateprep_inloop_carried.ll` (still a decline; its string moved to F1's, and it was the ONLY file in the 1494-fixture corpus Inc 4 turned red). Two existing fixtures gained cross-reference headers and no behaviour: `control_swap_eqfold_diamond.ll` (the §14.2d STEM PAIR — after Inc 4 one IR construct is read two ways, `cq_phi(i32 k,θ)` under `if(q==k)` re-anchors and `cq_theta(i32 k,θ)` declines on F2) and `control_angle_select_reject_state_prep.ll` (Inc 4's SECOND customer site, S3, shipped OUT as `drbq.13`). Six PRD §14.3 rows are folded into other fixtures' HEADERS rather than committed as separate `.ll` files because their `-O1` slice bodies are BYTE-IDENTICAL (a separate file would be a false coverage claim — the DER lesson), and one row (`controlled rotation width`) has NO reachable fixture for either arm class and none was fabricated. **Its round-1 Rule-13 review then added +17, corpus 1531 → 1548, family 59 → 76 files (28 accept / 48 decline)**: NINE declines for the F2 RANGE rewrite and F1's two unpinned clauses (`..._range_{mask1,a2_alias,ordered,knownbits,i1_both_edges}`, `..._unrecognized_suffix`, `..._eqfold_ne_else`, `..._undef_seed`, `..._poison_seed`) and EIGHT accepts (`..._range_ordered_seed0`, `..._cond_cast_seed`, `..._cond_bitcast_seed`, `..._suffix_control`, `..._feeds_later_cond{,_prep}`, `..._then_rolled_loop`, `..._warn_live_record`), plus ONE existing accept REWRITTEN (`..._stateprep_i1.ll` moved to an `i32` condition; its old module is now the decline `..._range_i1_both_edges.ll`). **It also regenerated the NEGATIVE assertions of all 28 accepts** — the Inc-3 F-L6-1 recurrence, AGAIN: a positive `NOROUTE-COUNT-n` inside the NOROUTE prefix WINDOWS every negative after it, so an injected `_controlled_inv` after the flag's free was caught by **0 of 20** blocks. Counts now live in their own `ACNT`/`FCNT`/`XCNT` prefixes, NOROUTE is pure-negative whole-file, handle names are DERIVED from the pass output (9 of 20 named a `%h1` that does not exist), and the three injections are caught **28 of 28**. **Its ROUND-2 review then added +9, corpus 1548 → 1557, family 76 → 85 files (29 accept / 56 decline)**: EIGHT declines — the six `..._range_forward_{add,xor,sub,or,lshr,ashr}` transcribed from the six plain-C programs of the F-R1-1 CONFIRMED MISCOMPILE (the forward closure; disabling the walk reddens exactly those six and all six then ACCEPT), and `..._range_constleft_{ugt,eq}` for F-R1-5 (nothing in the family put the literal on the LEFT, so deleting `getSwappedPredicate` reddened nothing) — and ONE accept, `..._stateprep_range_constleft_accept`, the control that keeps the swap a discriminator. It also added the missing whole-file `; NOROUTE-NOT: call i32 @cq_theta` to `..._stateprep_suffix_control.ll`, the ONE accept of 28 blind to a standing `@cq_theta` CALL — and the accept twin of the fixture whose whole counterfactual is a STANDING `@cq_theta_si32x` (lens R2 F-R2-1; validated exit 1 injected / exit 0 clean). **Its ROUND-3 review then added +16 net, corpus 1557 → 1573, family 85 → 101 files (30 accept / 71 decline)**: THIRTEEN new declines for the three CONFIRMED-MISCOMPILE classes of lens R3 — `..._sideways_{sdiv,offset}` (the SIDEWAYS rewrite, 30 plain-C programs), `..._cast_{sext,zext,trunc}_live` (the TYPE GATE, 8), `..._intrinsic_{bswap,bitreverse,fshl,fshr}` (the curated `llvm.*` rail family, 4), `..._range_knownbits_enum` (round-2's own F-R1-3 retirement trigger, now BUILT), `..._merge_edge_sideways` (why F2 asks BOTH edges, from plain C), `..._unevaluable_pinned_operand` (the conservative half) and `..._fp_seed_sitofp` (a SECOND vacuity gate beside the type one: `dyn_cast<ConstantInt>(RotBase)` meant NO fp seed was ever asked F2's question, and a live measured `sitofp` rail folded the seed from plain C) — plus TWO accepts, `..._stateprep_deep_chain` (the removed walk bound: three plain-C over-declines went away with it) and `..._stateprep_intrinsic_bswap_accept` (the ONLY file that separates F2's EXACT fold from its conservative decline — written because the mutation first measured 0 red). ONE ACCEPT WAS RE-HOMED AS TWO DECLINES: `control_inplace_ry_stateprep_i1.ll` → `..._reject_stateprep_i1_flag_pinned.ll` (IR unchanged) joined by `..._reject_stateprep_i1_arm_flag.ll`, because the branch condition is itself a tainted `i1` pinned on both edges and the ARM half was a live plain-C miscompile behind the type gate. **Its ROUND-4 review then added +9, corpus 1573 → 1582, family 101 → 110 files (34 accept / 76 decline)**: FIVE declines — `..._reject_stateprep_fcmp_oeq_folded.ll` (F-R4-1, the fp ANCHOR: the BACKWARD half was `isIntegerTy()`-gated, so NO fp register was ever asked F2's question and an f64 pinned by the region's own `fcmp oeq` accepted with the rail measured UNROTATED), `..._reject_stateprep_unfoldable_curated_call.ll` (F-R4-3, the conservative half's `CallBase` early return running BEFORE `AnyPinnedOperand`; a `nobuiltin` `@llvm.bswap.i32` is what makes `canConstantFoldCallTo` refuse a curated id at LLVM 19) `..._reject_stateprep_fcmp_une_folded.ll` (the anchor's OTHER EXACT half — `une` pins on the edge where it is FALSE, which is how `clang` canonicalises `!=`; the two over-approximating predicates `ueq`/`one` are deliberately left UNPINNED because deleting them can only remove over-declines, and the fixture says which is which), `..._reject_stateprep_fcmp_oeq_derived.ll` (the fp anchor's pin flowing FORWARD one hop — the anchor seeds ONE fact and every other fp value is covered by REUSING the existing forward evaluation, and nothing pinned that reuse) and `..._reject_stateprep_step_cap_over.ll` — and FOUR accepts, each of which exists to make a clause a DISCRIMINATOR rather than a decoration: `..._stateprep_fcmp_oeq_twin.ll` (the unconditional twin, byte-identical on BOTH binaries, which is what makes the fp decline a statement about a wrong UNITARY), `..._stateprep_fcmp_oeq_negzero.ll` (the ONLY file pinning the ±0.0 refusal — deleting `isZero()` reddens exactly it and nothing else), `..._stateprep_fcmp_oeq_derived_accept.ll` and `..._stateprep_step_cap_under.ll`. **The last pair pins `kF2MaxSteps` from BOTH sides** (4090 accept / 4200 decline; the exact boundary is `Steps = N + 2`, so the cap is exactly 4096) and they are 132 KB / 135 KB — ~10× the previous largest fixture, paid deliberately rather than avoided by shrinking the constant, and the accept half had to be a LINEAR CHAIN because a 4000-wide fan-out declines later at `uncompute: dead chain would free a measured register` (Rule 8). Base cb04d17 was 1361, NOT 1358 — the earlier note credited +49 for +46, an arithmetic slip caught by lens L6-N9. `ls ir-pass/test/*.ll | wc -l`. The "1 XFAIL" is CORRECT and re-measured — `grep -l XFAIL ir-pass/test/*.ll` returns 9, but 8 of those only MENTION the directive in prose; `lit ir-pass/test` reports `Expectedly Failed: 1`. Trust lit, not the grep). NO -j here: it is a single entry that already forks 12 lit workers itself. ⚠ **It is no longer the suite's long pole** — MEASURED in the 2026-09-05 full run at the 3qlq Inc-1 merge, `ir-pass-lit` took **54.8s** and `e2e-loop-twin-matrix` took **399s**, i.e. the whole wall time of the run. It is SPAWN-bound, not work-bound: bare `opt --version` costs 0.345s of libLLVM.dylib startup while the pass itself is ~0.02s, so fixture COUNT is nearly free and opt INVOCATIONS are not — spawns went 2088 -> 1087 and wall 143s -> ~61s without dropping one assertion. When adding a fixture, reuse one `%cq-opt ... > %t.cqd0.ll` and point every extra --check-prefix at that file; do NOT re-run the pass per prefix, and do NOT add a standalone `-passes=verify` RUN line (see below).
ctest --test-dir build -R frontend-lit --output-on-failure   # 1 entry — CQ.h surface survives clang -O1 (no plugin)
ctest --test-dir build -j6 -R '^e2e-'  --output-on-failure   # **338 entries / 308 slices** on branch `3qlq-inc1-fix-c1` after the SECOND C-1 review round (`ctest -N -R '^e2e-'` and `-R '^e2e-slice-'`, 2026-09-06); the breakdown below is the 2026-09-05 Inc-1 figure of 317 entries (293 slices, + free-pairing selftest, the loop-twin QUARANTINE selftest, fixture-guard-liveness, keepset vendor check, census-slice-sync, `e2e-loop-twin-matrix`, the 3 spec/predmux entries, the 6 bd 8h7d.5 `cmp` twin gates, the 3 bd drbq Inc-2b angle-select `cmp` twin gates and the 6 bd drbq Inc-3 in-loop controlled-Ry `cmp` twin gates; the 3 bd drbq Inc-4 state-prep slices add NO gate, deliberately — see the ctest note above) — the only layer that LINKS. -j6 cuts this from ~11.5min to ~3.6min. Counts measured 2026-09-05 (`ctest -N -R '^e2e-'` / `-R '^e2e-slice-'`); re-measure rather than trust them.
ctest --test-dir build -R runtime      --output-on-failure   # 7 entries, ~9s total — trace golden-diff, header compile, generated-template drift, and the link/core-ABI smokes with their selftests

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
python3 tools/free_pairing_check.py /tmp/s2.ll                                         # 2b: Rule-6 free pairing
"$LLVM/clang" /tmp/s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o /tmp/a  # 3: link*
/tmp/a                                                                                # 4: run → trace
```

\* **Link order is load-bearing:** `libcq_templates.a` **before** `libcq_runtime.a`
(template `_hl` symbols call `cqrt_*`; single-pass `ld` needs the caller first).
The by-hand stage 3 above is the clang driver, which is correct and is exactly
what the harness falls back to. The harness itself splits it (bd `dgn5`): CMake
derives a linker wrapper from this same clang via `clang -###`, drops the
`-lto_library` that makes `ld` dlopen libLTO→libLLVM (140MB) on every slice for
an `-O0` link that never uses LTO, and exports it as `CQ_LD`. MEASURED 0.74–0.94s
→ 0.35–0.44s per slice. It is re-derived on every reconfigure, so SDK /
platform-version drift is picked up automatically, and a stale line fails
**loudly** at link. Unset `CQ_LD` ⇒ the driver command, exactly equivalent.
Note the three `ld: warning: object file … built for newer 'macOS' version`
lines are **pre-existing** — CMake builds the archives with `/usr/bin/cc`
(minos 26.0) while stage 3 uses Homebrew clang 19 (minos 16.0), and the plain
driver emits the same three warnings today. They are not from the split.

**`%cq-opt` is NOT stock `opt` — it is `build/ir-pass/cq-opt`.** Every invocation
in this tree runs the identical `-passes=cq-lowering` pipeline, and the pass
itself takes **~5ms**, while stock `opt` costs **0.238s** of fixed per-spawn cost
(dyld-binding 140MB of `libLLVM.dylib` plus static initializers for every
component and target backend). At ~1330 spawns a run that dominated everything.
`cq-opt` (`ir-pass/tools/cq_opt_main.cpp`, built from the **same** `CQPass`
sources so the two cannot drift) links only the components the pass needs:
fixed cost **0.124s**. It accepts and IGNORES `-load-pass-plugin`, so RUN lines
and the e2e runners are **byte-identical under either binary**, and it hard-errors
on any pipeline other than `cq-lowering` rather than silently no-op'ing. It is
**one process per invocation** — not a compile server — so lit's isolation,
per-fixture diagnostics and `not` exit-code inversion are unchanged.
Equivalence is **gated, not assumed** (`tools/cq_opt_equivalence.py`): stdout,
stderr **and** exit code, 0 mismatches over all 1430 fixtures (re-measured
2026-09-03 after the Inc-2b round-1 review). The routine ctest
entry samples (`--stride 8`, ~13s) because the full sweep costs ~658s of CPU —
*more than the swap saves*; run the full one after any change to the pass's
diagnostic or analysis surface:
`cmake --build build --target cq-opt-equivalence-full`.

> **TRAP, cost one 551-fixture red suite.** `lit.cfg.py` puts the LLVM tools dir
> on `PATH` so the `not` wrapper resolves. That must be derived from **FileCheck**
> (or `config.llvm_tools_dir`), **never** from `dirname(cq_opt)` — `%cq-opt` now
> lives in the build tree, which contains no `not`. The failure is vicious rather
> than obvious: `not: command not found` goes down the same `2>&1` pipe the
> fixture FileChecks, so 551 negative fixtures failed on a *missing diagnostic*
> and read exactly like a lowering regression.

**The standalone `opt -passes=verify` RUN line is GONE, and must not come back.**
451 fixtures carried a `… | %cq-opt -passes=verify -disable-output -` round-trip.
It was removed (owner ruling 2026-08-13) after establishing — by measurement, not
assumption — that **`opt` already verifies the pass output in-process**:
`-debug-pass-manager` shows the order is `cq::CQLoweringPass` → **`VerifierPass`**
→ `PrintModulePass`, and `opt` exits non-zero when the verifier fails. So every
fixture still verifies, on the RUN line it already had; what the extra spawn
uniquely added was a **print→reparse→re-verify** round-trip, i.e. a check on
LLVM's own printer/parser symmetry rather than on CQ lowering. That property is
still covered end-to-end by **all 243 e2e slices**, where stage 2 writes textual
IR and stage 3's `clang` reparses it and fails loudly if it cannot. Net: 451
spawns × 0.345s ≈ **156s of CPU** for a check that was structurally redundant.
Do not re-add it per fixture; if you ever need to prove printer/parser symmetry
specifically, do it once, not 451 times.

**Stage 2b — the Rule-6 free-pairing gate (bd `8txa`).** `run_slice.sh` /
`run_slice_multi.sh` run `tools/free_pairing_check.py` on the same lowered IR
they link, because **the golden byte-diff cannot witness "freed at |0⟩"** — no
trace label can answer whether a rail was actually `|0⟩` when freed, at any ABI.
(The *compare flag-strip* half of this gap is now closed: bd `8txa` moved the
strip off the fresh-minting `_inv` — which named no rail and minted a phantom
handle 23342 times, never freed and never used — onto the void out-first
`cq_template_…_unc(rail, operands…)`, so a strip now names the rail the next line
frees and the golden DOES witness that pairing. The four once-identical
`fcmp_olt_f80_hl_inv(h67, …)` lines in `slice_libm_real_log1pl.expected.log` now
read `…_hl_unc(h78/h80/h106/h110, h60, …)`. Stage 2b still owns every other rail:
the whole-DAG spine's data `_unc` chains and the loop reverse-play write history.) The two
gates are **complementary** — the trace sees the angles and not the rail
identities; the checker sees the rail identities and not the angles (`cqrt_rz` is
deliberately transparent to it, being diagonal). Read the file header for exactly
what it does and does not witness before quoting it. Its own mutant validation is
`tools/free_pairing_check_test.py` (ctest `e2e-free-pairing-selftest`) — a checker
nobody has tried to fool is a checker nobody should trust. The **four**
`e2e-slice-loop-break*` entries pass `--allow-unproven` with a written reason (the
dtzb whole-loop reverse-play is a Bennett recompute + a back-edge-crossing write
history, neither structurally provable); **every other slice runs strict, and a
new `--allow-unproven` needs a reason of that kind.** ⚠ This said **five** until
2026-09-05 (bd `test_C_libtooling-3qlq` Inc 1): `slice_loop_break_qq_phase` was
the fifth and is DELETED, because under the register-free `cq_phi` its stage-1 IR
became byte-identical to `slice_loop_break_qq`'s — a duplicate, not a coverage
loss (prep-b2 OQ-5). The four that remain are `slice_loop_break`,
`slice_loop_break_qq`, `slice_loop_break_qq_derived` and `slice_loop_break_qq_i64`
(MEASURED: `grep -B14 'allow-unproven")' tests/e2e/CMakeLists.txt`, 4 invocation
sites; the other 9 `--allow-unproven` hits in that file are prose saying a slice
does **not** use it). A new `cqrt_*` runtime
symbol must be classified in `classify()` or the checker fails loudly rather than
guessing its read/write effects.

There is **no GitHub CI** (no `.github/` exists); all quality gates run locally
through `ctest` (LIT+FileCheck for ir-pass/frontend, shell+golden-diff for e2e,
`free_pairing_check.py` as e2e stage 2b) plus `gen_templates.py --check` drift
verification. Do not add CI.

**Three of those ctest entries are PURE-PYTHON RECORD gates, not compiler tests, and
they exist because this project's other failure mode is a number that measures the
wrong program** — `keepset_vendor_check.py` (no slice may vendor a software body for a
Rule-18 hardware keep), `slice_census_sync_check.py` (no `slice_libm_real_*` golden may
claim coverage the census does not report — bd `3c6m.63`), and
`free_pairing_check_test.py` (the stage-2b checker's own mutant validation). They run
in seconds, need no plugin, and each was added *after* the defect it catches shipped
undetected through a fully green suite.

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
  control-in-place peephole — not as the control mechanism. ⚠ Since 3qlq Inc 1
  its **Rz half has no minter at all**: `cqrt_rz_<W>_controlled[_inv]` is
  DECLARED-BUT-UNEMITTED, and re-enabling it for a phase arm would restore the
  tensored gate the whole increment exists to retire. The Ry half
  (`cqrt_ry_<W>_controlled`) is live and unaffected.
- **Do NOT add quantum arithmetic intrinsics** (`cq_add_qq`, …). Arithmetic is
  stock LLVM opcodes identified by taint.
- **Do NOT make `cq_phi` a taint source** or allocate a qubit for it — only
  `cq_theta` allocates and creates taint. Since 3qlq Inc 1 `cq_phi` is
  `void cq_phi(double)` and has **no data operand to allocate for**: its one
  operand is the angle, and allocating for *that* is the f64/angle miscompile
  family (Rule 3). Do not restore a register operand to it, and do not
  reintroduce the retired `cq_phi_<sfx>` family or a multi-bit `cqrt_rz_<W>`
  under control — the tensored gate is exactly what made every Grover golden
  the identity (see CORRECTNESS RISK).
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
| `ir-pass/src/RotationLowering.cpp` | `theta → cqrt_alloc_<W> + cqrt_ry_<W>` (qubit allocation point); RAUW result to the `i32` handle. ⚠ **`emitRz` is DELETED** (3qlq Inc 1): there is no `phi → cqrt_rz_<W>` row any more — `cq_phi` carries no register, so the only Rz this pass emits is the kickback `cqrt_rz_i1(f, θ)` minted by the CONTROL emitters, and an uncontrolled one is DELETED as a global phase (D2). A `@cq_phi_<sfx>` USE from a stale header is a reserved-name loud decline |
| `ir-pass/src/OpcodeLowering.cpp` + `Arith/Compare/Cast` | Tainted `add/mul/icmp/fcmp/cast/fneg → cq_template_*`; up-front cast-width capture before RAUW |
| `ir-pass/src/OpcodeSupport.cpp` · `TemplateName.cpp` · `WidthDispatch.cpp` | Supported-set/commutativity/predicate policy · symbol-string grammar · suffix→width + lazy `FunctionCallee` minting |
| `ir-pass/src/MeasureLowering.cpp` | `@cq_measure_<sfx> → cqrt_measure_<W>` |
| `ir-pass/src/ControlDetect.cpp` · `ArmClassify.cpp` · `SwapRouteEmit.cpp` · `RegionFlatten.cpp` · `ClassicalCallArmEmit.cpp` · `include/ControlPlan.h` | Swap-route control: region detection (declines what it can't prove) · arm/condition classification + tainted-angle/stale-condition guards + the 6.5 `classifyClassicalCallArm` · **phase-arm KICKBACK emission** (`emitPhaseKickbackRegion` flat, `emitPhaseKickbackNestRegion` for the 4.3 depth-2 nest) **and value-arm routed emission** · CFG flattening · the 6.5 hoist+controlled-copy merge (`emitClassicalCallArmRegion`) · populated region plan. ⚠ `ir-pass/src/NestedRouteEmit.cpp` is **DELETED** (3qlq Inc 1) — the nest no longer routes |
| `ir-pass/src/CondTreeEmit.cpp` · `include/CondTreeEmit.h` | **3qlq Inc 1 (PRD P3), and the ONE spelling of "turn a condition into a flag" the phase path uses.** `collectCondTree` recognises the `and`/`or`/`xor` tree over tainted compare leaves (incl. the `select i1` combinator spellings, admitted for the branch phase by `AllowLogicalSelect` and NOT for the 4.4 data select — one grammar, two verdicts, recorded as an owner question rather than left implicit); `emitCondNetwork` mints one leaf flag per compare, combines them (`cqrt_toffoli` for AND, the OR/XOR node emissions `SelectMergeEmit` already had — Rule 14, reuse), hands back the ROOT flag the kickback gate sits on, and tears the network down LIFO. `SwapRouteEmit` (flat + nest) and `SelectMergeEmit` are its callers. ⚠ `Specialization::mintCondNetwork` is a THIRD, forward-only copy of this network with no strip; it was deliberately NOT folded in (it would move the specialization goldens) and carries a cross-reference comment |
| `ir-pass/src/AngleSelectEmit.cpp` · `include/AngleSelectEmit.h` | **drbq Inc 2b + 3qlq Inc 1 (PRD P2) — the ANGLE-SELECT emitter, and the two stems no longer share a lowering.** The **Ry** stem is unchanged: BY DIFFERENCE, an unconditional `R(h,B)` plus one `cqrt_ry_<W>_controlled(f, h, A−B)`, CONSTANT arms only. The **Rz** stem is a KICKBACK PAIR — `cqrt_rz_i1(f, B)` and `cqrt_rz_i1(f, A)`, two gates on ONE flag, both `markBranchPhaseGate`-recorded — which performs NO subtraction, so the whole IEEE-rounding fence that constrains the Ry stem HAS NO SUBJECT there and run-time arms are admissible for Rz. Do not migrate a fence between the stems. The rest of the Inc-2b description below is the Ry stem's. Dispatched on `Kind == AngleSelectRegion` (pushed by `ArmClassify::classifyAngleSelect` through `SelectClassify`'s gate 3). Positional steps around the consuming rotation and no CFG surgery at all: **validate the plan by SSA identity, then re-ask S4 and S1's arm-value fence in lockstep (step 0b, the round-1 Rule-13 repair — without it a preceding SwitchDataMux region's RAUW made the compare Q+Q and the emitter bailed MID-STREAM)**, the classical difference `A−B`, an unconditional twin `R(h,B)`, the ordinary flag mint, the rewire + `taint.ControlledRotations` record, the ordinary strip + free, then erase the select (and the compare when it goes dead — a dead tainted compare would otherwise become a leaked flag rail in `lowerOps`). Every remaining `return` below the first emission is UNREACHABLE and commented as such, not as a bail |
| `ir-pass/src/OpcodeLowering.cpp` (`declineStaleRecordOps`) · `WireWalk.{h,cpp}` | Pass-wide stale-record guard (tainted pure op scheduled past a non-diagonal wire gate → loud decline) · shared forward in-place-gate wire walk (position-free and position-aware modes) |
| `ir-pass/src/Uncomputation.cpp` · `ChainWalk.cpp` · `DagTraversal.cpp` · `FreePoint.cpp` · `EmitInverse.cpp` | Whole-DAG LIFO uncompute spine (runs last): terminal selection · whole-DAG recovery · post-dom free point · reverse-program-order void `_unc` adjoint + `cqrt_free`; compares decline loudly (no `_unc` grid). **`ChainWalk` also owns the `!cq.branchphase` MEMBERSHIP record** (`markBranchPhaseGate` / `isBranchPhaseGate`, 3qlq Inc 1 F-L7-1): a kickback gate is refused FIRST by `isInPlaceGateOn`, `preservesBasisUnderRecord` and `EmitInverse::isInverseEmittable`, so the spine cannot adjoint the user's answer. Asked as membership of the emitted INSTRUCTION, never by name — `cqrt_rz_i1` alone does not identify a kickback gate, and `Uncomputation::preservesBorrowedParent` clause (1) deliberately still ADMITS it by name, which is a different and sound question |
| `ir-pass/src/LiteralIntegrity.cpp` · `include/LiteralIntegrity.h` | **The two literal-integrity guards (bd xy9n + 7udx).** ONE invariant: an emitted gate's LITERAL operands must denote the source's value, identically at every site the lowering copies them to. Guard 1 `declineUnpairedUndefLiterals` (module-wide, per-FUNCTION count, runs LAST) — a literal `undef`/`poison` in TWO emitted gate slots is read as two values at the `-O0` stage 3, so an adjoint stops inverting its forward (Rules 6, 8); guard 2 `declineAddressTakenBlocks` / `removeUnreachableBlocksChecked` at all **7** block-erase sites — `~BasicBlock()` RAUWs a `BlockAddress` to `inttoptr (i32 1 to ptr)` module-wide on a **well-defined** source. Also the shared `valueCarriesUndef`, lifted here from `PredMuxFlatten` so cone proof and guard cannot drift (Rule 14). **Neither defect is visible to `opt -verify` OR to `free_pairing_check.py`** — the structure is perfect and only the run-time values differ |
| `runtime/cq_runtime.{h,c}` | Hand-written `cqrt_*` core ABI (trace-only) |
| `runtime/cq_templates.{h,c}` | **Autogenerated** `cq_template_*` bodies — edit `tools/opcode_table.yaml`, not these |
| `include/CQ.h` | User-facing intrinsic surface: 14 types × **2** register-carrying families (`cq_theta`, `cq_measure`) via `_Generic`, **plus the single register-free `void cq_phi(double)`** (3qlq Inc 1 — no per-type family, no `_Generic`, the old 15-width `cq_phi_<sfx>` family DELETED from the header so the two-argument spelling is a hard compile error), + `cq_invert_*` and the `cq_ry` statement macro |
| `tools/golden_multiset_audit.py` | The GOLDEN-DIFF AUDIT, two modes. `--epic 2a` (default) is drbq Inc 2a's route→controlled collapse; **`--epic 3qlq` is Increment 1's** — it reads each changed golden's OLD and NEW trace as MULTISETS and classifies the difference as a mechanical SUBSTITUTION (the routed/controlled quintuple collapsing to one `cqrt_rz_i1` on the flag) or as a **FINDING** that a human must explain. It is what turned "the goldens moved" into a classification a human can sign: over the **72** changed goldens at the final tree state, **29 SUBSTITUTION-ONLY · 1 AMBIGUOUS-d · 1 AMBIGUOUS-ca · 11 NEW-FILE · 30 FINDING**, and the 30 FINDINGs are EXACTLY the 30 REWRITTEN PROGRAMS — `comm` empty in both directions, `--selftest` PASS (25 mutants + 10 controls + 2 tolerance pins, 0 survivors). *(Those five figures are prep-b2's step-12 run, not re-measured for this doc pass; re-run the tool rather than trusting them.)* ⚠ **NOT a ctest entry** — an instrument, like the twin matrices, pending the same owner cost decision (bd `drbq.9`); it exits 1 while any FINDING stands, which is the tool working as its docstring predicts. ⚠ A golden that is present at the compared rev and ABSENT in the tree is now a REPORTED `DELETED` status, never a pass and never a crash — it raised `FileNotFoundError` and aborted the whole run until prep-c's finding was fixed this increment (`golden_multiset_audit.py:1311`) |
| `tools/free_pairing_check.py` · `tools/free_pairing_check_test.py` | Rule-6 free-pairing gate over the **lowered IR** (e2e stage 2b — the rail identities the trace loses, bd `8txa`) · its mutant validation (ctest `e2e-free-pairing-selftest`) |
| `tools/library_coverage/full_surface/build_corpus.py` · `tools/slice_census_sync_check.py` | **The two libm-census integrity gates (bd `3c6m.63`).** The corpus recipe as an executable, self-checking script — it skips the ten `ld80/` bodies openlibm does not build, DERIVES that exclusion twice and hard-fails on disagreement, and verifies every `.bc`'s `source_filename` (the defect it replaces kept the right file NAME and the wrong BODY, so a symbol count could not see it) · the gate that stops a `slice_libm_real_*` golden claiming coverage the census does not report, which is how the published `verified` count could exceed `injection-covered` with **no test red** (ctest `e2e-census-slice-sync`). Neither defect is a miscompile — both are **numbers measuring the wrong program**, the retired `165/174` class |

**Docs map:** `ROADMAP.md` (plan of record) · `docs/frontend.md` (intrinsic
surface) · `docs/backend.md` (IR pass + runtime ABI) ·
`docs/quantum-classical-handling.md` (taint as the Q/C boundary; mixed-operand
semantics) · `docs/design/rssa-swap-control/{OVERVIEW,SCOPING,MINT_AT_COMPARE}.md`
(the control design + the `prototype_semantics.py` / `clearance_derived_base.py` /
`investigation_mint_at_compare.py` oracles) · `docs/llvm-implementation.md`
(stock LLVM-19 C++ APIs) · `docs/prd/` (per-phase PRDs — for the register-free `cq_phi`,
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` (the seven owner
decisions D1–D7 and the P1–P7 accept rows, with a dated ERRATA block at the top)
and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1/§2 (the two adversarial rounds, and the
"what else runs once before round 2" stage table); the per-increment records are
under `phase-04-swap-route-control/inc1-records/`) ·
`docs/archive/old-design/` (retired design — reference only).
