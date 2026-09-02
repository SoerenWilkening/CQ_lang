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
answer (a phase) **in place on `q`**, and the data-derived flag is stripped by the
**uncontrolled** `icmp_inv(q)`. **The arm gate itself is now ONE
`cqrt_rz_<W>_controlled(f, q, θ)` on the FLAT `emitRegion` path** (bd
`test_C_libtooling-drbq` Inc 2a, 2026-09-02 — the §6a control-in-place peephole,
default-on): no work rail, no `cqrt_cswap` route, so the old "**zero controlled
gates**" is **no longer true there** and must not be quoted as a phase-arm
invariant. It still holds verbatim for the shapes that KEEP the route — the 4.3
depth-2 nest and the 4.5 switch — where the rail is `|0⟩` for free (`Rz|0⟩ = |0⟩`)
and freed clean. The two forms are the SAME unitary, not an approximation:
`cswap(f,q,w)·Rz_w(θ)·cswap(f,q,w)` with `w = |0⟩` equals `cRz(f,q,θ)` exactly
under the project's `Rz = diag(1,e^{iθ})` convention (no global-phase residue).
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

Tainted `br` / `select` / `switch` is the construct that has produced every
verify-clean silent miscompile in this project's history. The **old controlled-op
lowering** (mint a flag → substitute each arm gate with a `_controlled` template
→ dissolve the φ → uncompute the flag → linearize the CFG) shipped and was then
**removed wholesale** (`7cde677`) so the new **RSSA swap-route** design is built
without it shaping the implementation. Today `ControlDetect` recognizes
phase-arm AND value-arm if-diamond / if/else regions (incl. derived-base
routing); `SwapRouteEmit` lowers **phase arms** CONTROL-IN-PLACE since bd
`test_C_libtooling-drbq` Inc 2a (flag mint → one `cqrt_rz_<W>_controlled(f, q, θ)`
per arm gate, `cqrt_x`-bracketed for a ¬flag arm → `icmp_inv` flag-strip → flag
free; **no work rail, no route, so the region's only `cqrt_free` is the flag's** —
and on the ziov `ShareCondFlag` path, where the strip and free are skipped because
the data lineage owns the flag, the region frees **nothing at all**). The
pre-2a form — flag mint → `cqrt_cswap` route → verbatim arm Rz on a `|0⟩` rail →
route back → clean frees → strip, **zero controlled gates** — is still what the
4.3 nest and the 4.5 switch emit, and is still the *oracle* for the flat path:
the two are the same unitary and the Inc-2a golden diff is exactly the collapsed
quintuple and nothing else (`tools/golden_multiset_audit.py`, 26 goldens, 65
regions). `SwapRouteEmit` lowers **value/permutation arms** by method-B (`R` →
`cqrt_copy_<W>` copy-out → reverse-play `R†`; a value arm that clobbers a
register the condition reads declines loudly — §3c); `RegionFlatten` erases the
CFG diamond. `RegionTreeDetect` + `NestedRouteEmit` lower the **depth-2
homogeneous-phase nest** (`if(a){…if(b){…}}`, flag-per-level routing — 4.3
DONE). `SelectClassify` + `SelectMergeEmit` lower a tainted-condition
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
cycles and multi-latch loops all keep the loop decline. **A tainted-arm `Ry`
(`cq_theta`) on a register whose PHYSICAL wire is disjoint from every condition
wire lowers CONTROL-IN-PLACE since bd `drbq` Inc 1** (2026-09-02, PRD §4 shape
(a) only — a flat DIAMOND; the if/else arm is supported symmetrically but is
reachable only from HAND-WRITTEN IR, because `clang -O1` merges the two arms into
ONE call with a `select` on the ANGLE, which declines `rotation angle`): the
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
in hand IR for the other 4 of 5 out-of-place base opcodes. Ry on the
CONDITION's own wire, state prep, in-loop, nested, switch, `ShareCondFlag`,
multi-gate arms and any post-region read of the pre-Ry record all keep declining
— the last one over the base's whole RAIL closure, φ/select/freeze crossed
FORWARD (a classical join φ over one register laundered a `cq_measure`/`ret`/tape
write/clone arg/`cq_invert` past the fence: the round-1 review's second confirmed
silent miscompile). Read
`docs/prd/phase-04-swap-route-control/{control-in-place-PRD,CONTROL_IN_PLACE_INC1_NOTES}.md`
§11 / findings K-M before touching any of it.
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
- **Method matches arm class, not convenience** (Rule 7). Phase arms keep the
  answer on `q` and strip the flag with `icmp_inv`. Since drbq Inc 2a the FLAT
  path's arm gate is one `cqrt_rz_<W>_controlled` in place (the nest and the
  switch keep the route and keep "zero controlled gates"); method-A rail cleanup
  is still dropped. Bennett compute→copy→uncompute (**method-B**) is the
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
# 295 ctest entries (2026-09-02, UNCHANGED by the bd drbq Inc-2a Rz peephole, which adds 9 lit fixtures and NO ctest entry — it regenerates 26 existing e2e goldens rather than adding slices; +3 for the bd drbq Inc-1 control-in-place group — the round-2 Rule-13 review added 2 lit FIXTURES and 2 `tools/` instruments but NO ctest entry, deliberately: `tools/inplace_twin_matrix.py` and `tools/control_flag_order_check.py` are instruments pending an owner cost decision, not gates — 2 Inc-1 slices + the round-1 Rule-13 review's derived-base freeze slice; 2026-08-30: +7 for the bd 8h7d.5 Rule-13 round-4 group — 4 slices, 2 `cmp` twin gates and `e2e-loop-twin-matrix`, the rolled-vs-unrolled matrix that is the ONLY instrument in the tree that can see a leaked TEMPLATE-minted rail (100 cells when added, 120 after the round-5 `range` axis, **156** since the bd drbq Inc-2a round-1 review added the RECORD axis — no `int mark = a;` existed in any cell until then, which is the shape 8h7d.5's F-1 and F-3 lived in; re-measure with `grep -c '^m_' tools/loop_twin_matrix.expected.txt` rather than trusting this); +3 for the Rule-13 round-1 two-register group — 2 slices + 1 `cmp` twin gate; 2026-08-29: +18 for the bd 8h7d.5 in-loop-control group — 7 rolled/unrolled/dynamic slices + 3 `cmp` twin gates, and the rest are the earlier libm/e2e growth; 2026-08-27: +2 for the bd hcrg sequential-region slices; the
# figures below were taken at 252/253 and their RATIOS still hold). RUN IT PARALLEL
# — `-j` is the default, not an
# optimization. MEASURED 162s at -j6, 252/252 pass (2026-08-13), down from 825s
# serial: 5.1x. RE-MEASURED 2026-08-17 on a QUIET box, 253/253 three times: 127s,
# 189s, 226s at -j6. So there is no single number — the spread tracks how warm the
# stage-1 content-addressed cache is (127s was a warm re-run; 189s/226s followed a
# full rebuild) plus scheduling luck. Treat ~130-230s as the quiet-box band and
# NEVER quote one figure as the expected time. UNDER CONCURRENT AGENT LOAD the owner
# measured 256-368s, which is NOT comparable: budget command timeouts from the
# loaded figure, and only ever compare two runs taken under the same load. Four independent changes got that, each verified green:
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
ctest --test-dir build -R ir-pass-lit  --output-on-failure   # ONE ctest entry wrapping 1358 *.ll fixtures (1 XFAIL: lowering_invert_add_i32.ll, Phase-7 tracker; count measured 2026-09-02 AFTER the bd drbq Inc-2a Rz-peephole fixture batch — +9 `control_inplace_rz_*.ll`, and NO new ctest entry, since Inc 2a adds no e2e slice: it REGENERATED 26 existing goldens instead, `ls ir-pass/test/*.ll | wc -l`. The "1 XFAIL" is CORRECT and re-measured — `grep -l XFAIL ir-pass/test/*.ll` returns 9, but 8 of those only MENTION the directive in prose; `lit ir-pass/test` reports `Expectedly Failed: 1`. Trust lit, not the grep). NO -j here: it is a single entry that already forks 12 lit workers itself. Still the suite's long pole. It is SPAWN-bound, not work-bound: bare `opt --version` costs 0.345s of libLLVM.dylib startup while the pass itself is ~0.02s, so fixture COUNT is nearly free and opt INVOCATIONS are not — spawns went 2088 -> 1087 and wall 143s -> ~61s without dropping one assertion. When adding a fixture, reuse one `%cq-opt ... > %t.cqd0.ll` and point every extra --check-prefix at that file; do NOT re-run the pass per prefix, and do NOT add a standalone `-passes=verify` RUN line (see below).
ctest --test-dir build -R frontend-lit --output-on-failure   # 1 entry — CQ.h surface survives clang -O1 (no plugin)
ctest --test-dir build -j6 -R '^e2e-'  --output-on-failure   # 285 entries (271 slices, + free-pairing selftest, fixture-guard-liveness, keepset vendor check, census-slice-sync, `e2e-loop-twin-matrix`, the 3 spec/predmux entries and the 6 bd 8h7d.5 `cmp` twin gates) — the only layer that LINKS. -j6 cuts this from ~11.5min to ~3.6min. Counts measured 2026-09-02 (`ctest -N -R '^e2e-'` / `-R '^e2e-slice-'`); re-measure rather than trust them.
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
stderr **and** exit code, 0 mismatches over all 1358 fixtures (re-measured
2026-09-02). The routine ctest
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
nobody has tried to fool is a checker nobody should trust. The five
`e2e-slice-loop-break*` entries pass `--allow-unproven` with a written reason (the
dtzb whole-loop reverse-play is a Bennett recompute + a back-edge-crossing write
history, neither structurally provable); **every other slice runs strict, and a
new `--allow-unproven` needs a reason of that kind.** A new `cqrt_*` runtime
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
| `ir-pass/src/LiteralIntegrity.cpp` · `include/LiteralIntegrity.h` | **The two literal-integrity guards (bd xy9n + 7udx).** ONE invariant: an emitted gate's LITERAL operands must denote the source's value, identically at every site the lowering copies them to. Guard 1 `declineUnpairedUndefLiterals` (module-wide, per-FUNCTION count, runs LAST) — a literal `undef`/`poison` in TWO emitted gate slots is read as two values at the `-O0` stage 3, so an adjoint stops inverting its forward (Rules 6, 8); guard 2 `declineAddressTakenBlocks` / `removeUnreachableBlocksChecked` at all **7** block-erase sites — `~BasicBlock()` RAUWs a `BlockAddress` to `inttoptr (i32 1 to ptr)` module-wide on a **well-defined** source. Also the shared `valueCarriesUndef`, lifted here from `PredMuxFlatten` so cone proof and guard cannot drift (Rule 14). **Neither defect is visible to `opt -verify` OR to `free_pairing_check.py`** — the structure is perfect and only the run-time values differ |
| `runtime/cq_runtime.{h,c}` | Hand-written `cqrt_*` core ABI (trace-only) |
| `runtime/cq_templates.{h,c}` | **Autogenerated** `cq_template_*` bodies — edit `tools/opcode_table.yaml`, not these |
| `include/CQ.h` | User-facing intrinsic surface (14 types × 3 families via `_Generic` + `cq_invert_*`) |
| `tools/free_pairing_check.py` · `tools/free_pairing_check_test.py` | Rule-6 free-pairing gate over the **lowered IR** (e2e stage 2b — the rail identities the trace loses, bd `8txa`) · its mutant validation (ctest `e2e-free-pairing-selftest`) |
| `tools/library_coverage/full_surface/build_corpus.py` · `tools/slice_census_sync_check.py` | **The two libm-census integrity gates (bd `3c6m.63`).** The corpus recipe as an executable, self-checking script — it skips the ten `ld80/` bodies openlibm does not build, DERIVES that exclusion twice and hard-fails on disagreement, and verifies every `.bc`'s `source_filename` (the defect it replaces kept the right file NAME and the wrong BODY, so a symbol count could not see it) · the gate that stops a `slice_libm_real_*` golden claiming coverage the census does not report, which is how the published `verified` count could exceed `injection-covered` with **no test red** (ctest `e2e-census-slice-sync`). Neither defect is a miscompile — both are **numbers measuring the wrong program**, the retired `165/174` class |

**Docs map:** `ROADMAP.md` (plan of record) · `docs/frontend.md` (intrinsic
surface) · `docs/backend.md` (IR pass + runtime ABI) ·
`docs/quantum-classical-handling.md` (taint as the Q/C boundary; mixed-operand
semantics) · `docs/design/rssa-swap-control/{OVERVIEW,SCOPING,MINT_AT_COMPARE}.md`
(the control design + the `prototype_semantics.py` / `clearance_derived_base.py` /
`investigation_mint_at_compare.py` oracles) · `docs/llvm-implementation.md`
(stock LLVM-19 C++ APIs) · `docs/prd/` (per-phase PRDs) ·
`docs/archive/old-design/` (retired design — reference only).
