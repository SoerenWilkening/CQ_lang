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

> **Three files, three jobs.** **This file is the operating manual** — the rules
> and the current state of the art. **[`ROADMAP.md`](ROADMAP.md) is the plan of
> record** (Phases 0–11 + the 10 cross-cutting design principles); it, not this
> file, is authoritative for status. **[`docs/CLAUDE-HISTORY.md`](docs/CLAUDE-HISTORY.md)
> is the verbatim archive** of this file as it stood at `571c7cd` (2026-09-13),
> before it was compacted from 289 k to under 150 k characters. Nothing was
> deleted: every dated narrative this file no longer carries inline — the
> round-by-round adversarial records, the historical count chains, the
> superseded generations of the Phase-4 lowering, the libm-census arithmetic —
> is there, and the per-increment records it summarises are under
> `docs/prd/phase-04-swap-route-control/` and in `bd remember`.

## Status in brief (authoritative: `ROADMAP.md`)

**Phases 0–6 DONE. Phase 7 core DONE (7.1–7.6); 8–11 remain.** Roadmap
resequenced 2026-06-19: Phase 7 is pre-freeze expressiveness completion,
manual inversion (`cq_invert`) is Phase 8, runtime templates / integration /
freeze are 9 / 10 / 11. The freeze is gated only on the 7.5 QRAM memory ABI,
the 7.1 wide-integer widths, the 7.6 I/O output-tape ABI, the kjd1 fp select
copy family (`cqrt_copy_f{16,32,64,80}_controlled`) and the drbq
control-in-place rotation family (`cqrt_ry_<W>_controlled` ×9).

**"DONE" means the scoped CORE increments shipped + Rule-13-cleared.**
Everything outside the shipped accept-shape declines loudly (Prime Directive),
so the open follow-ons are additive coverage or deferred capabilities, **not**
correctness debt. Post-core loop/break widenings live under the open tracker
bd `8h7d`.

**The project's one KNOWN verify-clean silent miscompile is CLOSED** — bd `3d8q`,
`81c55430`, 2026-09-14: a `cq_theta` arg-0 or `cq_measure` operand that reads a
STALE rail name is now asked the same linear rule `declineStaleRecordOps` asked
of pure ops, and **104 corpus modules that accepted on the pre-session oracle now
decline** (merge-gate sweep, `MERGE_REPORT.md` §5a). ⚠ **That is not "no
correctness debt", and do not quote it as such.** The same Rule-13 rounds filed a
NEW P1 over-accept of their own (a rail φ carrying a dtzb-mutated `cq_theta`
result IN PLACE — `IMPL_D.md` §15.4, cross-referenced to bd `a3z7` / bd `0njv`),
and bd `lo7u`, bd `s82e` and bd `yiid` are open P1s today. Count the known ones;
never claim zero.

⚠ **Phase 4 has had THREE generations, and the first two are traps.** The
controlled-op generation shipped and was **removed wholesale** (`7cde677`). The
**RSSA swap-route** generation that replaced it is **also retired** (bd
`test_C_libtooling-3qlq`, landed 2026-09-06). Old ROADMAP/issue text naming a
"finished" Phase 4, and the sub-item labels `4.1 (phase arms)` / `4.2 (value
arms, method-B)`, describe **delivered history, not the shipped mechanism**.
What runs today: a **phase arm is a register-free KICKBACK**, a **value arm is a
CONTROLLED-COPY MERGE**, and `cqrt_cswap` has exactly **one** minter, the 7.2
`AbortParkEmit`. See CORRECTNESS RISK below before touching control flow.

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

⚠ Read this together with **Rule 17**: the Prime Directive governs *inputs*, not
*development posture*. An off-pattern input declines. The feature you were asked
to build does not get declined because the lowering is hard. And per the owner
ruling of 2026-09-11 — *"our end-goal is to not decline any code that will lead
to a valid quantum circuit"* — an **over-decline is a defect to remove, not a
free safety margin**.

---

## Non-Negotiable Rules

**Rule 0 — Institutional memory.** Durable, hard-won knowledge goes in
`bd remember` (read them: `bd memories <keyword>`). Design-of-record goes in
`docs/` and per-phase PRDs (`docs/prd/phase-NN-*/`). Do **not** use TodoWrite,
markdown TODOs, or `MEMORY.md`. Every gotcha, LLVM-19 quirk, and
silent-miscompile root cause must be written down — future agents (and you,
after compaction) depend on it.

**Rule 1 — Fail loud, decline safe.** Use the loud diagnostic and lower nothing
when unsure (see Prime Directive). Diagnostics carry the offending instruction's
`!dbg` so they are source-located and `opt` exits non-zero. A tainted
`br` / `select` / `switch` is **never** silently passed to the backend as
classical control over quantum state — `ControlDetect.cpp` either hands the
region to an emitter or declines it loudly; there is no third path. ⚠ That "no
third path" has been violated exactly once and it was found by adversarial
review, not by the suite (3qlq F-L6-1: a stale-header `@cq_phi_<sfx>` call was
neither lowered nor declined). `declineSurvivingIntrinsicCalls` now makes the
pass's postcondition — no `@cq_{theta,phi,measure}_<sfx>` remains — a **checked,
LOUD** property rather than a comment; not an `assert`, because Release builds
have assertions off and Release is what every gate here runs.

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
nothing to propagate *through*. Under a tainted condition it lowers by kickback
onto the condition flag; uncontrolled or classically controlled it is a global
phase and is **DELETED** (`docs/frontend.md` §3.3, `docs/backend.md` §6.1a).
⚠ Any pre-2026-09-05 text describing a `cq_phi_<sfx>(x, φ)` register operand is
HISTORY — that operand no longer exists, and a **use** of the retired family is
a reserved-name loud decline.

**The angle operand of a rotation is classical** — arg-1 for `cq_theta`, arg-0
(the only operand) for `cq_phi`. Never propagate taint through it; a
quantum-derived angle is a loud decline (`cq rotation lowering: unsupported
quantum-derived rotation angle`, or `cq controlled lowering: rotation angle
under quantum control` inside a tainted region). For `cq_theta` the exclusion is
**per-operand-use, not global** (a value also used as an arg-0 handle stays
tainted); `cq_phi` has no such case, having no handle operand. Never allocate a
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
corrupts under downstream interference (Grover/QPE). Region-local
**reverse-play** (the adjoint of the forward stream, via `EmitInverse`) is the
**on-demand** undo for user `cq_invert`, **not** an eager per-increment step
(revised 2026-06-09). ⚠ Since 3qlq Inc 2 (2026-09-06) the value arm's emitter
replays NOTHING — it hoists the chain and merges by controlled copy, leaving the
chain to the ordinary whole-DAG `_unc` spine — so `cq_invert` is `EmitInverse`'s
remaining region-local customer (`docs/design/rssa-swap-control/SCOPING.md` §3a).

**Rule 6 — Free only a proven-`|0⟩` rail.** `cqrt_free` is **compiler-emitted
only** and is a hardware reset = projective measurement. Emit it **only where the
rail is provably `|0⟩`**. A rail **not** provably `|0⟩` is **left allocated** (a
qubit leak, accepted in the qubits-not-scarce regime), **never freed dirty** —
freeing a dirty/entangled rail is a hidden measurement that collapses `q`
(revised 2026-06-09). Never free a handle that **Escaped** (`ret` /
`cq_invert_*`) or is **Measured** — the caller / the measurement owns it. Route
every free through the `FreePoint` post-dominator discipline; a post-measure
gate, a loop-backedge live range, or an unrecognized user is a **loud reject**,
never a silent skip.

Live examples of "left allocated on purpose": a value arm's chain-final rail
(3qlq Inc 2, PRD §0 E1); a controlled-Ry arm's rotated register and its control
register (drbq Inc 1 / l4x4.b — `Ry(θ)|0⟩ ≠ |0⟩`); a kickback flag whose chain
the spine refuses to close (`!cq.branchphase`).

**Rule 7 — Method matches arm class.** **Phase arms** (`cq_phi`) put the answer
**on the FLAG**: the register-free KICKBACK `cqrt_rz_i1(f, θ)`, uncontrolled,
`cqrt_x`-bracketed for a ¬flag arm on an ancilla — never a `cqrt_x` on a user
register — then the ordinary `_unc` strip and one `cqrt_free`. Nothing is
emitted on `q` at all. **Value / classical-permutation arms**
(`add`/`mul`/`x`/`toffoli`) are the **CONTROLLED-COPY MERGE**: hoist the arm's
pure chain into the pred so it runs unconditionally on the ORIGINAL register,
mint the ordinary flag, merge the answer into a fresh `|0⟩` rail with two
X-bracketed `cqrt_copy_<W>_controlled`, then the chain's `_unc`, the compare
strip and ONE `cqrt_free`.

⚠ **Never merge a phase arm by a basis copy.** A CNOT copies a basis *label*,
not a *phase*, so `R†` cancels the very superposition that was the answer
(verified P0 0.585 → 0.500, fully dephased). That is why the phase arm is the
kickback.

⚠ An arm that value-rewrites a variable the condition reads is a **loud reject**
(clobber, SCOPING §3c).

⚠ **HISTORY, and it is quoted wrongly more than anything else in this file.**
Three earlier phase-arm forms existed — the swap route (`cqrt_cswap` into a
`|0⟩` work rail, verbatim arm Rz, route back: "zero controlled gates"), the drbq
Inc-2a control-in-place `cqrt_rz_<W>_controlled(f, q, θ)`, and the routed nest /
switch. All three are the same unitary *as each other*, and that is precisely
the problem: **all three put a TENSORED per-qubit Rz on `q`**, which is what made
every shipped Grover golden the identity. Do **not** restore any of them, and do
**not** quote *"zero controlled gates"* or *"`Rz|0⟩ = |0⟩` for free"* as a
phase-arm invariant. Method-A controlled-adjoint **rail cleanup** stays dropped
(2026-06-09); controlling a gate *in place* is a different thing and is what the
Ry arm does.

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

⚠ `-O1` does more than swap polarity, and every item here was a confirmed
miscompile before it was a fence: it **sinks** ops into arms and **hoists** them
into preheaders; it **fuses** consecutive regions with provably-equivalent
conditions into one diamond with several merge phis (bd `b6ap`); it folds an
if/else over one register into **one call with a `select` on the ANGLE** (drbq
Inc 2b); it **const-folds** an equality edge on both sides (the F1/F2 state-prep
fences); it rewrites a compare **sideways** onto a sibling or **downward** onto
an ancestor of the register IPSCCP actually pinned (F2 rounds 2–3); it
**LICM-hoists** a loop-invariant compare out of the body; and it rewrites an
affine add-recurrence's exit value into a closed form.

**Rule 10 — All bugs are deep and interlocked.** Never assume a shallow bug.
Investigate root cause fully; a fix that passes one test but violates an
invariant elsewhere is not a fix. Off-by-one and "it works now" are suspect.
Nearly every silent miscompile in the history (f64 φ, gated-switch mixed/distinct
φ, MUX-EXCH G3b stray rotation, jumptable over-match, nested-merge UAF) was found
by a deliberate **adversarial probe family**, not by the positive suite.

**Rule 11 — Skepticism.** Verify everything — subagent output, prior sessions
(against `git log`), and **bd memories** (they reflect what was true *when
written*; a named file/flag may be gone — e.g. `ControlDetection.cpp`,
`MergeDissolution.cpp` and `NestedRouteEmit.cpp` are **gone**). The same applies
to every dated block in this file and to all of `docs/CLAUDE-HISTORY.md`.
Extract and read the actual lowered IR before implementing; do not guess LLVM
patterns.

**Rule 12 — Every accept-predicate ships with a decline fixture + adversarial
probe.** Red-green: write the lit fixture first (positive `CHECK` **plus** a
negative `RUN: not … | FileCheck` that mirrors the diagnostic string
character-for-character), watch it fail, implement minimally. A new shape-matcher
without a probe family is incomplete. `ir-pass-lit` and the e2e goldens are
regression baselines — keep them green; regenerate baselines deliberately, never
by reflex.

⚠ Three fixture-hygiene defects have each shipped undetected through a green
suite; assume the fourth is yours. (a) A positive `CHECK-COUNT` inside a
negative prefix **windows** every negative after it — an injected gate after the
flag's free was caught by **0 of 20** blocks. Counts belong in their own
whole-file prefix, and negatives must be pure. (b) A decline fixture's IR-text
`CHECK-NOT`s are **vacuous**: a `DS_Error` decline writes 0 bytes to stdout, so
the property is pinned by the `not` inversion on the RUN line, not by the
checks. (c) A decline fixture that goes green because its **subject no longer
exists** pins nothing. Validate by **mutation** (an injection matrix over the
accepts) and record the MISSED count, not by re-reading the prefixes.

**Rule 13 — Core lowering changes get adversarial verification, not just green
tests.** Changes to the lowering core (`TaintPropagation`, the control emitters,
`FreePoint`, `EmitInverse`, `ChainWalk`, `Uncomputation`, `RotationLowering`,
`MergePhiPeel`, the condition-wire fences) are where the silent miscompiles
live. Before committing, clear the change via an independent second
reviewer/agent using analytic/trace-level reasoning (no statevector simulations
at this stage — owner decision 2026-06-10). A green suite alone does **not**
clear a core change.

⚠ **Budget the rounds up front; the measured hit rate says the next round finds
something.** 7.4 break: 13 over-accept holes over three rounds, three of them in
a round that ran **after** the epic was closed as "Rule-13 cleared". 7.3 in-loop:
7 findings over 3 rounds, plus an older one of the same class that had shipped
since Increment 1. 3qlq Inc 1's C-1 family: **8 instances over 6 rounds on one
function — two of them introduced by a fix, and the eighth found by a round
reviewing a *different* increment after the work had already landed.** drbq Inc
4's F2 fence lost **four consecutive rounds**, each to a different `-O1` rewrite.
Every one of these was `opt` exit 0, verify-clean and stage-2b clean.

**Rule 14 — Reuse before reinvention; no duplicated lowering.** Check existing
handlers (`OpcodeSupport` / `ArithLowering` / `CompareLowering` / `CastLowering`,
the `EmitInverse` adjoint spine, the Phase-5 uncompute spine
`ChainWalk`/`FreePoint`/`Uncomputation`, `CondTreeEmit`, `SelectMergeEmit`, and
the `cqrt_cswap`/`cqrt_toffoli` primitives) before adding a new one.

The canonical instance is 3qlq Inc 2: `emitValueRegion` writes no merge of its
own — it hoists the arm's chain, builds a `select`, and calls the
Rule-13-cleared 4.4 `SelectMergeEmit` **verbatim**, which is why its stream is
byte-identical to the manually pre-hoisted `select` twin's and why it inherits
that emitter's clearance. The counter-example is the drbq Inc-3 (b′) defect: a
**second spelling** of a predicate the tree already owned. Ask by *calling* the
one owner (`railWireClosure`, `railPhiRootMint`, `classifyInPlaceReassignment`),
never by re-deriving its answer.

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
off-pattern, unprovable *input* still declines loudly. What changes is
**development posture**: do not reach for a decline as the convenient way out of
a difficult lowering, and do not reflexively gate the intended shape behind an
over-safe decline check. If the implementation proves genuinely difficult,
ambiguous, or off-pattern in a way that tempts a decline of the very thing we
aimed to build, **stop and bring questions back to the owner** rather than
silently shipping a decline-only stub and calling it done. Over-declining what
we set out to build is a punt, not a feature.

**Rule 18 — A library function means its SOURCE, injected.** Compiling a
`math.h`/libc function ALWAYS means compiling with its real implementation
**injected as source** (an openlibm-style soft body llvm-linked + inlined
*before* `cq-lowering`; caller `-fno-builtin-<fn>` so the named call resolves to
the body) so the taint pass sees stock **opcodes**. Library-function coverage is
measured **only** by source injection — **never** by recognizing `@llvm.<fn>` /
`@<fn>` by name and emitting a per-fn `cq_template_<fn>`. That name-recognition
path is **fiction**: once the source is injected the named call is inlined away,
so the recognizer never fires. This is why the old `math.h` 165/174 "95%" claim
was retired — it was a **mislabelled** number, recognition counted **as**
injection.

**The keep/cut line is testable and target-dependent (measure, never guess —
Rule 11) and needs BOTH conditions:**

- **(1)** `clang -O1` on `T f(T x){return f(x);}` folds the call to a hardware
  instruction, an inline opcode sequence, or a recognized `@llvm.<fn>` intrinsic
  **before codegen**. The operative test is the *IR construct the pass sees*,
  **NOT** "no `call`/`jmp _<fn>` in the final asm" — the l-suffix rounders
  (`rintl`/`nearbyintl`/`truncl`) emit `callq _<fn>l` at f80 codegen yet are
  keeps, because CQ intercepts `@llvm.{rint,nearbyint,trunc}.f80` first.
- **(2)** Bennett.jl ships a reversible gate sequence for that construct, else it
  is a parity-*inversion* we cannot realize and it **declines**.

**Condition (2) means a CONCRETE gate sequence — a K-parameterized unroller is
NOT one** (owner ruling 2026-07-27). Bennett's data-dependent-trip loop support
is a family of circuits indexed by a user-supplied `max_loop_iterations`, with
zero static trip-count inference and a convergence witness readable only at
*simulate* time — and CQ has no simulator and will not get one (Rule 2). **A
construct whose realization depends on an unverifiable parameter is a parity
inversion and it declines.** That covers every data-dependent-trip library body
(the `fmod`/`remainder`/`remquo` family, Payne–Hanek `rem_pio2`, and any future
one). Bennett's **fixed**-trip branchless kernels *are* concrete gate sequences
(the 64-iteration restoring divider), so a bounded, statically-known trip count
stays in scope. A decline on these grounds is a **parity** wall, never a
**physics** one — never quote it as "impossible".

**NARROWED by owner ruling 2026-08-21 (bd `eyhj`) — to a DERIVATION, never a
parameter.** A quantum-dependent trip count is admissible **when the compiler
PROVES a quantum-independent upper bound `B` from the IR in front of it** and
emits the loop ROLLED at classical trip count `B`, with the body predicated on a
quantum still-running flag. **Failure to derive `B` is a loud decline.** The
asymmetry is the whole safety argument: a parameter can be wrong and still
compile; a derivation that fails **stops the compiler**, so an undersized bound
is UNREACHABLE rather than UNDETECTED — and **neither shipped gate can see an
undersized bound** (the golden byte-diff records a stream self-consistent under
whatever predicate was chosen; `free_pairing_check.py` witnesses rail *pairing*,
which stays clean). So a user-supplied `K`, a `name → K` table, a flag supplying
`K`, and an **offline-measured** `K` are all still refused — the last because a
classical run samples the **guard-admitted** domain while the emitted circuit
runs the **unguarded** one.

> ⚠ **DO NOT QUOTE THE NARROWING AS A CAPABILITY — NOTHING IMPLEMENTS IT, and
> Rule 18 is prose, not a fence.** At HEAD `LoopLowering.cpp`'s Q1
> quantum-bounded-exit decline is intact and unconditional, and **no bound
> derivation exists anywhere in the pass**. `hasFiniteClassicalTripBound` is the
> 7.4 `break` path and is not this. State it precisely: no quantum-dependent
> trip count is **lowered as a loop** today. (`CtlzIdiomPrepass`, bd `ww4c`,
> claims shift-count loops whose exiting condition *is* tainted — but it wins by
> **erasing** the loop and substituting a closed form, a **value** substitution,
> no `B`, no still-running flag.) The implementing increment (bd `m57l`) is
> DEFERRED with **no customer**: its two scoped cells were taken by that
> recognizer, so the narrowing's marginal payoff at HEAD is **zero cells**.
> Building the fence is Rule-12 red-green **plus** Rule 13, with five measured
> decline conditions — constant ∧ non-negative ∧ small ∧ reachability-**total** ∧
> `1 ≤ shift-amount ≤ W-1`, the constant-max BTC read as an **APInt at its own
> width** — every one a measured over-accept hole (`isa<SCEVConstant>` alone
> over-accepts **30 of the 49** loops it takes; `getSmallConstantMaxTripCount`
> returns `4294967295` on some vacuous bounds and `0` on others, so neither
> return value distinguishes vacuity).

**On x86-64+SSE4.1 the keep-set is** `sqrt fabs copysign floor ceil trunc round
rint nearbyint fmin fmax fma/fmuladd lrint llrint` (+ the non-`math.h` integer
bit-intrinsics), **all Bennett-backed**. Everything else (transcendentals,
`pow`, all direct-libm, by-ref `frexp/modf/remquo`, `lround/llround`) is a
library function and **declines** without injection. **`fmod`/`fmodf`/`fmodl`
are NOT keeps** despite folding to the in-grid `frem` opcode: Bennett ships no
`frem`/`fmod` gate sequence, so condition (2) fails.

**AMENDMENT — the CQ-PROVIDED set (owner ruling 2026-07-31, bd `guwr`).** A
third category beside recognition and injection: a function whose implementation
**CQ itself ships**. It exists because the two conditions are independent — for
the trig family only **(1)** fails, while Bennett backs `sin`/`cos`/`tan` with a
concrete branchless sequence; what is ruled out is only openlibm's **source
form**. Admission requires **ALL THREE** below **plus an explicit owner ruling
per function**. It is not developer discretion and not an escape hatch (Rule 17
applies verbatim — authoring a leaf instead of doing the lowering is the same
punt):

- **(i)** Bennett ships a **concrete branchless** gate sequence for it.
- **(ii)** CQ ships a **verified branchless implementation with a committed e2e
  golden AT THAT WIDTH**, checked **mechanically** (`probe.cq_provided_cells()`
  measures leaf + slice + golden + ctest registration + `_leaf_in_sync` on disk
  — deliberately never a hand-maintained spelling list, because a hand list is
  how "verified at that width" rots into an assertion).
- **(iii)** it is recorded as **CQ-PROVIDED** and **NEVER merged into the
  injection number**.

**Mechanism — this is the whole design.** For the admitted set the pipeline
**injects CQ's leaf instead of upstream's body**. Everything stays inside the
existing injection machinery: **no new recognizer, no per-fn
`cq_template_<fn>`, no new frozen symbols.** The honesty claim is "CQ ships its
own reversible `sin`" (what openlibm is to a C compiler), not "CQ compiled
openlibm's `sin`".

Day-one, measured: exactly **6 cells** qualify (`sin`/`cos`/`tan` at f64 and
f80). `sinf`/`cosf`/`tanf` are rejected — no leaf at f32. **"9 cells" is a
TRIPWIRE, not a cap** (clarified 2026-08-10): 9 reached *without* three
genuinely verified f32 leaves and goldens means condition (ii) has broken;
authoring real leaves (bd `eur4`) takes it 6 → 9 legitimately, and is worth
**zero injection progress** (those cells are declines today, so it only shrinks
the denominator). **The `log` stem / `logl` spelling are NOT admitted** (owner
2026-08-10): both already pass (ii) *and* are already covered by real openlibm
injection, so admitting them moves covered cells out of the injection row, and
`log`'s source form is injectable — the amendment's grounding does not reach it.

**HEADLINE — the whole-`math.h` total is the number we quote (owner ruling
2026-08-22, bd `fhas`):** **`math.h` coverage: 159/183 cells (87%)** —
composed of `101/120` injection + `6/6` CQ-PROVIDED + `42/42` recognition
keep-set + `10/12` type-generic macros + `0/3` by-design `nan` (as measured
2026-08-23). It is **computed, never hand-copied**
(`probe.mathh_union_scoreboard()`); every published occurrence is generated into
a marked region — if this paragraph disagrees with `README.md`, believe the
generator. **Three conditions make it honest and none is optional:** (a) the
**composition is printed with the total, every time**; (b) it is read as *"CQ
compiles 159 of the 183 modelled `math.h` cells"* and **never** as *"CQ compiled
openlibm's body 159 times"* (42 cells have no injectable body at all and 6 use
CQ's own leaf); (c) **the campaign number for COMPILER progress is the injection
row alone** — rows (1) and (3) move with no compiler work.

⚠ **The lesson that number carries is worth more than the number.** On
2026-08-23 it moved **down by three** (bd `3c6m.63`): the census corpus was
building ten openlibm TUs from `ld80/` whose basenames also exist in `src/`, and
openlibm's own build **excludes all ten** — three cells were scored `COMPILES`
on **a program that ships nowhere**. No compiler capability was lost; the number
stopped measuring the wrong program. It then moved **up by four** the same day
(bd `3c6m.67`) for an unrelated reason — a two-operand `xor i1` of tainted
compares used as a branch condition was excluded from both condition-tree
recognizers with **no rationale ever recorded**, an absence of a decision that
hardened by repetition. **Never net those two against each other**: a
correction and compiler work are different events, and a net would hide both.
The recipe is now an executable self-checking script
(`tools/library_coverage/full_surface/build_corpus.py`) with a
`e2e-census-slice-sync` gate. Full arithmetic history:
`docs/CLAUDE-HISTORY.md`; see also
`docs/prd/phase-07-expressiveness/p119-libm-coverage-honesty/PRD.md` and bd
[`libm-coverage-source-injection-rule`], [`libm-census-scope-axis-2026-07-28`],
[`bennett-grounding-asymmetry-2026-07-28`],
[`narrowed-quantum-trip-rule-2026-08-21`].

Two corollaries to carry: a ruling about the CONSTRUCT the pass sees says
nothing about a body reached by *source injection* — for those, Bennett-backing
is owed by the **opcodes the body decomposes into**, not by a `soft_<fn>` of the
same name (the `lgamma`/`tgamma` mistake); and `logbl.f80`/`ilogbl.f80` are
`deferred-capability`, **not** `decided-decline` — they decline because SCEV
reports `CouldNotCompute` under 12 measured pipelines and the rotated body
genuinely does not terminate on 2 of 2^32 inputs, *not* because their trip count
is quantum. Say "12 measured pipelines", never "every pipeline".

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
1. **Before any commit touching the Rule-13 lowering core.**
2. **Before `git push` / at session end**, whenever the push contains any change
   to code, fixtures, goldens, or the harness. A push that is *purely*
   docs/comments does not need it.
3. **After any change to the harness itself** (`run_slice*.sh`, any
   `CMakeLists.txt`, `lit.cfg.py`, `cq-opt`, the caches) — a harness edit changes
   how *every* test runs, so no subset can witness it. Not theoretical: a
   `lit.cfg.py` PATH edit turned 551 fixtures red in a way that read exactly like
   a lowering regression, and only the full suite caught it.
4. **After regenerating the templates** (Rule 15) — the ABI moved under every layer.
5. **When an accept/decline predicate changed** — Rule 12's probe families live
   across both `ir-pass-lit` and e2e.

**Report only what you ran.** If you ran `ir-pass-lit`, say "lit green (1893)",
never "tests pass" — an unqualified green claim about layers you did not execute
is a false statement about verification, and this project's whole defence is
that verification claims are literal. Same for a sampled gate: say it sampled.
**A skipped layer is a deferred cost, not a saved one.**

⚠ **Never relink a binary under a running measurement, and never `pkill` by
pattern.** Measured twice in one session: a `cq-opt-equivalence` run `***Failed`
with `FileNotFoundError … /build/ir-pass/cq-opt` purely because a rebuild was in
flight under it, and a whole corpus sweep died mid-run for the same reason. A
failed gate that is actually a rebuild artefact is worse than a slow gate — it
trains you to discount a real red.

---

## Scope of the semantic model — `fenv` is OUT (owner ruling 2026-08-10)

**CQ does not model floating-point exception flags** (`FE_UNDERFLOW`,
`FE_INEXACT`, the rest of `<fenv.h>`), and **a `volatile` access to a
non-escaping function-local object is not observable** in CQ's model. There is
no fenv concept anywhere in the runtime ABI, the pass, or `CQ.h`, and this
ruling adds **no frozen symbol**. MMIO, external linkage, escaping addresses and
atomics are untouched and keep their existing loud declines.

**What it licenses — and the comfortable version is false.** An operation whose
*only* consumer is a store to a never-read non-escaping `volatile` local may have
that **store** removed. **The computation then usually disappears too, and the
ruling accepts that**: once the store is gone the `fmul` is trivially dead and
`PredMuxFlatten`'s `RecursivelyDeleteTriviallyDeadInstructions` takes it — a
cleanup that exists for a Rule-6/8 reason of its own (a dead *tainted* op left
alive lowers to a forward gate that is never uncomputed and never freed). So "we
only delete the store" is true of the *stage* and false of the *pipeline*, and
only the second one matters. Note the asymmetry before reading a trace: with
**no** enclosing tainted control flow the dead product IS lowered, uncomputed and
freed; inside a PredMux region it is deleted outright. Both are sound; they are
not the same circuit.

> **Two lessons attached to this ruling.** (1) It needed ruling *because* the
> sentence "fenv is out of scope project-wide" had been shipped source prose
> since `eb31e18`, load-bearing for two stages that already delete volatile
> accesses, and appeared in **no** bd memory, **not** in this file and **not** in
> the ROADMAP — an agent-authored justification that hardened by repetition into
> a de-facto ruling. (2) It was first granted on the **wrong summary** ("the
> implementation keeps the `fmul`"), an artifact of a fixture with no control
> flow; the owner re-affirmed it on the corrected facts. The reassurance was the
> wrong reason for a decision that stands without it.
>
> **THE RULING STANDS; ITS CENSUS CELL DOES NOT** (bd `3c6m.63`): the write-only
> idiom is `ld80/s_nexttowardf.c`, which openlibm does not build, so the `+1`
> coverage credit for `nexttowardf.f32` is **retracted** while the capability and
> `eraseDeadVolatileScalarStores` are unaffected.

Note the pre-existing rationale at `QramLowering.h:222-226` — "volatile's only
effect is to defeat FP reassociation, which taint lowering never does" — is
**factually wrong for this idiom family** and must not be cited for it. The
correct ground is this ruling.

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
      │            ├─ detectControl()    tainted br: peel merge phis → claim region → emit; else LOUD DECLINE
      │            ├─ lowerRotations()   theta → cqrt_alloc_<W> + cqrt_ry_<W>   (cq_phi carries no register)
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

⚠ **Control detection runs TWICE.** `repropagateControlMerges` re-seeds taint
from the 6.5/4.5 merge `%out` rails and runs a **second, full** round of
`detectControlRegions` + `lowerControlRegions` to a fixpoint. Every stage
between the first round and that fixpoint has a premise round 2 can falsify —
see the standing lesson in CORRECTNESS RISK.

---

## CORRECTNESS RISK — Tainted control flow (the live work, the deepest hazard)

Tainted `br` / `select` / `switch` is the construct that has produced **every**
verify-clean silent miscompile in this project's history. Read this section and
`docs/design/rssa-swap-control/` before touching control flow; read
`docs/CLAUDE-HISTORY.md` for the round-by-round record behind every claim here.

### 0. The finding that reframes everything — every shipped Grover golden was the IDENTITY

(2026-09-05, `retire-swap-route-PRD.md` §1; bd
[`grover-goldens-are-identity-tensored-rz-2026-09-05`].) `cqrt_rz_<W>` is
**TENSORED** — Rz on *each* qubit of the register — so `if (q == 5) q =
cq_phi(q, PI)` lowered to a gate whose marked phase is `(−1)^popcount(target)` =
**+1** for 5 under either convention; and the reflection `if (q == 0) …` is
worse, because a per-qubit **diagonal** gate FIXES `|0…0⟩` and can never put
`−1` there. Nothing caught it and nothing could: the golden byte-diff proves
every symbol resolves and signature-matches, not that the unitary is right
(Rule 2), and there is no simulator — the traces are self-consistent records of
the identity.

**The standing lesson is a RETIREMENT: "`Rz|0⟩ = |0⟩` for free" must never again
be quoted as a load-bearing argument.** It is true, and it is *exactly* the
property that makes a routed or controlled per-qubit Rz **not an oracle**. A
W-bit "rotation" ABI needs its multi-qubit semantics pinned **before** a control
emitter is built on it. The fix was to make `cq_phi` register-free and lower it
by kickback (Rule 3 / Rule 7); the register-wide Z rotation is now the classical
per-bit loop `for (i…) if ((q>>i)&1) cq_phi(θ)`.

### 1. What lowers today

| shape | mechanism | emitter |
|---|---|---|
| phase arm (flat diamond / if-else, folded angle select, compound condition tree, depth-2 nest, `switch`, rolled in a bounded loop) | **KICKBACK**: mint flag → `cqrt_rz_i1(f, θ)` **uncontrolled** per `cq_phi` → `_unc` strip → free | `SwapRouteEmit::emitPhaseKickbackRegion` / `…NestRegion`, `emitKickbackGroup` |
| value / permutation arm (diamond, if/else) | **CONTROLLED-COPY MERGE**: hoist the arm's pure chain into the pred → build a `select` → hand to `SelectMergeEmit` verbatim | `emitValueRegion` |
| tainted-condition integer- or scalar-fp-data `select` (4.4) | controlled-XOR copy merge: flag → `|0⟩` rail → two `cqrt_copy_<W>_controlled` (¬flag `cqrt_x`-bracketed) → compare-`_inv` strip → one free | `SelectClassify` + `SelectMergeEmit` |
| tainted-scrutinee `switch` (4.5), 4 accept shapes | homogeneous phase (N-way eq-flag + kickback + the §5 const-fold re-anchor scrub) · homogeneous value and all-const data-mux (**preload + XOR-delta**: `cqrt_copy_<W>(p,out)` once, then per case a hoisted chain, a Q+Q `xor` delta, an eq-flag and one `cqrt_copy_<W>_controlled`) · the eq-folded diamond | `SwitchClassify` (G0–G11) + `SwitchArmProve` + `Switch{Route,Value,DataMux}Emit` + `EqFoldArm` |
| in-place controlled **Ry** arm on a register disjoint from every condition wire | the arm's theta is hoisted and `cqrt_ry_<W>_controlled(f, h, θ)` is minted; the rotated register is then **FROZEN** (never reverse-played, never freed) | `emitInPlaceRotationRegion` |
| controlled **state prep** (`int r = SEED; if (COND) r = cq_theta(SEED, θ)`) | `cqrt_alloc_<W>(SEED)` + `cqrt_ry_<W>_controlled(f, h, θ)` on the fresh rail, frozen the same way | same, `StatePrep` kind |
| folded if/else angle select, **Ry stem** | BY DIFFERENCE: unconditional `R(h,B)` + one `cqrt_ry_<W>_controlled(f, h, A−B)`. **CONSTANT arms only** | `AngleSelectEmit` |
| folded if/else angle select, **Rz stem** | a KICKBACK PAIR `cqrt_rz_i1(f,B)`, `cqrt_rz_i1(f,A)` — no subtraction, so run-time arms are admissible here | `AngleSelectEmit` |
| classical call under quantum control (6.5) | a pure all-classical-args call inside a tainted-condition diamond arm runs classically and is HOISTED into the pred; its `i32` result is route-merged by 4.4 mechanics. **Clone-orthogonal** — no clone | `ClassicalCallArmEmit` |
| **sequential** flat regions (`if(q){…}; if(q'){…}`) | ordering, not a new lowering: `lowerControlRegions` builds a precedence graph, Kahn-sorts it, declines only on an unresolvable alias or a cycle | bd `hcrg` |
| a NON-EXITING tainted **phase** region inside a classically-bounded loop | lowered **ROLLED** (IR size independent of the trip count: 87 lines at K=3 and at K=1000) | bd `8h7d.5` |
| an in-place controlled **Ry** arm inside such a loop | ROLLED, with `cqrt_ry_<W>_controlled` where the phase path puts the kickback | drbq Inc 3 |
| a **bare `_Bool` rail condition** (`br i1 %b` with no compare) at the kickback, the nest, the Rz-stem angle select, the 4.4 data select, the in-place Ry arm and the state prep — and since 2026-09-14 the **in-loop** form of the last two | the register **is** the flag; it is read only as a **control**, never `cqrt_x`-bracketed and never freed | bd `3qlq.4` / `r9e5` / `l4x4`.b / `wx8g` |
| a diamond whose merge carries phis the region does not define | **normalised before detection**: each independent merge phi becomes a `select` with its own compare clone | `MergePhiPeel` (bd `b6ap`) |
| a preceding state-prep region's **merge φ** as a condition-tree LEAF at the **phase kickback**, and at an **INTERIOR** position of the `and`/`or`/`xor` tree at **both** consumers (the 4.4 data select and the branch phase) | the φ IS the rail. ONE predicate — Track M's `preppedRailPhiRegionIdx`, **exported and CALLED** by each consumer, re-derived by neither (Rule 14) — so the widening adds an **ACCEPT, not a STREAM** (measured: the emitted stream is the shipped one) | bd `3qps` + `4aiu` (`71de13c2`) |
| an in-place controlled **Ry** arm or controlled **state prep** on a bare `_Bool` **inside** a classically-bounded loop, and an **iteration-local** rolled rail for every condition kind | ROLLED. Measured: **8 of 8** accepting pairs BYTE-IDENTICAL to the hand-unrolled twin, and the lowered IR is K-independent (81 / 66 / 85 / 83 / 105 lines at K=3 **and** K=1000, measured without `-g`) | bd `wx8g` (`a2b86139`) |

`RegionFlatten` erases the CFG diamond after emission.

**Witnesses.** The value arm's is BYTE IDENTITY with the manually pre-hoisted
`select` twin on four pairs (`e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical`)
— a comparison against the *old* compiler's stream, since that spelling already
lowered through the cleared 4.4 emitter. The in-loop work's is BYTE IDENTITY
with the hand-unrolled twin (**40** `*-twin-identical` ctest gates today, **29**
of them named `*loop*`) plus K-independence of the lowered IR.
`e2e-loop-twin-matrix` (**338** cells since bd `uq96` gave it an `i1` axis,
`49b7f7bc`) is the only instrument in the tree that can see a **leaked
TEMPLATE-minted rail** — stage 2b is structurally blind to those, having no
`cqrt_alloc` to count. ⚠ Before `uq96` the matrix had **no `i1` axis at all**, so
the witness of record for in-loop work could not see the width of the owner's
whole cascade; and the first 40 `i1` cells still could not see the
iteration-local rail, because every `B_ARM` declares its second register
**outside** the loop — which is why the axis took a second pass of 10 more cells
(`IMPL_T.md` §8.1). An instrument is only ever blind in the shape nobody has
pointed it at yet.

**Three conventions that are load-bearing, not cosmetic:**

- **Nothing non-diagonal ever touches a user register under control.** A gate
  that must fire on `b == 0` is the diagonal `rz(h_b, −θ)`, on
  `X·P(θ)·X = e^{iθ}·P(−θ)` — a global phase, which is already discarded. A
  *non*-diagonal gate has no such escape, so a negated controlled **Ry** is
  spelled by **additivity**: `ry(h, θ); ry_controlled(h_b, h, −θ)` (`fneg`,
  exact). ⚠ That cancellation is exact for every **finite** angle and is *not*
  the identity for a non-finite one — `__builtin_inf()` is a loud
  `rotation angle` decline (found by review, before landing).
- **A rail root that needs a ¬-copy gets a CNOT copy, never a bracket.**
  `bf = cqrt_alloc_i1(0); cqrt_cnot(h_b, bf)`, the shipped stream on `bf`, then
  `cqrt_cnot(h_b, bf); cqrt_free(bf)` — `Σ αₓ|x⟩|x⟩`, one copy per basis branch,
  `b` untouched, `bf` back to `x ⊕ x = 0` on every branch, a proven-`|0⟩` free.
- **Two RAUW conventions live in `SwapRouteEmit.cpp` and which is which
  matters.** M-α (RAUW the merge φ to the base) for the Rz stem, because a
  diagonal gate's two names denote the same basis state; **M-β** (RAUW to the
  LAST HOISTED GATE) for the Ry stem and for state prep, where M-α would make a
  prepped register classical or turn a zero-hop identity carry into a frozen
  record. Retiring the split is follow-on bd `drbq.10`.

### 2. What declines — and the fences that decide

Everything not in the table above declines loudly. The named fences, because
they are what a widening must argue with:

- **Condition-wire disposition.** `2c condition predates a non-diagonal gate` is
  **the live fence in front of almost everything** — measured, it fires on 16 of
  27 alternative readings of the state-prep shape where R4 fires on 0. P1
  (`SawValueArm || !(SawPhaseArm || SawRotationArm)`), P4 (an unbounded
  cross-block gap — this is why an LICM-hoisted loop-invariant compare declines,
  so **Grover's condition register must be loop-variant**), the rail ladder's
  rungs (i)/(ii)/(iii), and `railWireNamesBackward` / `collectNonDiagonalWireGates`.
- **F1 / F2, the state-prep fences.** F1: the merge's Pred incoming must be
  pointer-identical to the seed, and a TAINTED pred incoming is a no-cloning mux.
  **F2** asks a *semantic* question — "is some live tainted value provably equal
  to the seed on one of the branch's two edges, **and not on the condition's own
  backward wire**?" — via `LazyValueInfo` on both edges plus an abstract forward
  evaluation using LLVM's own `ConstantRange`/`ConstantFold`/`KnownBits`. ⚠ The
  `CondWire` exclusion is applied at the equality **TEST**, never at the LVI
  **ANCHOR** (at the anchor, all 40 F2 fixtures flip). ⚠ The LVI dominance
  filter is an **API precondition, not an optimization**: asking LVI about a
  value defined after the branch SIGSEGVs a Release `cq-opt`. Since 2026-09-14
  the TEST carries a third exclusion beside `CondWire` and `PeelClones` — the
  **φ-DESCENDANT** conjunct (bd `om35`, `30317792`), whose ground is
  AVAILABILITY and which is written out in §4c because a widening has to argue
  with it.
- **The STALE-READER fence** (bd `3d8q`, `81c55430`). `recordStaleQuantumReaders`
  runs as pure ANALYSIS beside `declineStaleRecordOps` (and again, delta-scoped,
  inside `adjudicateTaintDelta`), and `declineRecordedStaleQuantumReaders` is the
  **last slot before `lowerRotations`** — a BACKSTOP, never a preemptor, because
  `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`). A
  `cq_theta` **arg-0** or a `cq_measure` operand that the wire walker cannot
  prove executes before a non-diagonal gate on the same wire is
  `cq opcode lowering: rotation/measure operand predates a non-diagonal gate`.
  The accept direction is leg 1b's `readerStalesItself` — SCEV proving the
  reader runs on at most one iteration — and the decline direction is
  `std::nullopt`: ⚠ the boundary is **SCEV DECIDABILITY, not runtime-ness**, and
  a runtime-start IV that SCEV can decide accepts soundly (measured,
  `REVIEW_D_R3.md` F-D3-1).
- **Rail staleness in loops.** `staleRailRecordRead`: a rail member may be read
  only where no rail-relabelling gate (Ry, or a dtzb in-place `add`/`xor`; Rz is
  diagonal and exempt) executes between the record's definition and the read
  without that definition re-executing. Grouped per **ROOT MINT** — two chains
  from one mint are one register and must interfere; two mints must not. The
  **gate** set is the rail's forward closure; the **record** set is the rail's
  too; the **SKIP** set stays the chain's. Two sets, two questions.
- **In-place reassignment (M-C).** `classifyInPlaceReassignment`'s G2/G5/G6/G7
  decide whether a `add`/`xor` mutates the rail in place. Its answer is
  **committed** in `taint.InPlaceRailOps` with the proven operand INDEX
  (`InPlaceRailIdx`) so no consumer re-derives it, and **re-verified at
  `lowerOps` under FINAL taint** for every member the pre-loop path marked —
  declining loudly, never falling back silently.
- **Loop scope.** Irreducible cycles, multi-latch and nested loops, in-loop value
  (merge) arms, in-loop nests/`switch`/6.5 arms, and a rail whose header φ the
  round-2 collapse will not claim. ⚠ An **iteration-local rotated register no
  longer declines** (bd `wx8g`, §4c); what survives inside it is measured and
  filed, not a proof — the `il*`×`bcar` combination (an iteration-local TARGET
  rail beside a condition rail re-rotated in the body, 3 twin cells,
  `MERGE_FILINGS.md` §3), a DERIVED condition with no invariant register root,
  the MIXED case (a clause-(c) rail beside a loop-carried one whose exit value is
  read, `IMPL_W.md` §7.2 H-2), and bd `onq1`.
- **The switch off-pattern matrix** (multi-phi C1, grouped C4, non-empty-default
  C5, MUX-EXCH C8/G8, mixed arms, fp/vector/`i128` G4, nested G11, §3c clobber
  G7, tainted angle G3, jump-table fold, impure/unowned scrutinee G10), deeper or
  non-homogeneous nests, a quantum-derived rotation angle anywhere, and a
  **run-time-arm** Ry angle select.
- **`bare i1 register condition`** for the tree consumers that have not yet been
  given a rail leaf: the UNFOLDED value diamond (bd `fg9k`), the 6.5
  classical-call arm (bd `54ur`) and the Ry-stem angle select (bd `l4x4`.a). ⚠
  The in-loop form of the Ry arm / prep is **no longer** on this list — bd
  `wx8g` landed 2026-09-14 (§4c). `branch phase on a bare i1
  condition` survives as the discriminator for the non-register `i1` residuals
  (a loop-carried `bool` header phi — bd `boi6`; `trunc`/`zext`/phi/argument —
  bd `r903`).

⚠ **Two decline strings name mechanisms that no longer exist** and are still
loud, correct declines: `value-arm swap-route` (6 sites, 28 fixtures) and the
`_controlled` Rz family's declared-but-unemitted symbols. Renaming is bd
`OQ-13`, not a free edit.

### 3. The standing lessons — this is the part to read twice

**(L1) A stage that runs ONCE has a round-2-FALSE premise.** Control detection
and lowering run **twice** (`repropagateControlMerges`). Anything computed
between them over "taint is settled" is wrong for any value derived from a
6.5/4.5 `%out`. **Three species, each found by adversarial review and none by
the suite:**
- a **STAGE** — `deleteGlobalPhases` deleted a branch phase whose region did not
  exist yet, and the orphaned angle then lowered as quantum fp **DATA**
  (`cqrt_alloc_f64(…)` — a rotation angle materialised on a quantum rail, the
  Rule-3 wire-crossing); and the in-loop rail collapse missing the round-2 delta;
- a **PREDICATE** — the condition-wire closure keyed on `taint.Tainted` and asked
  at round-1 taint, while `lowerRotations` decides chained-vs-source at FINAL
  taint: a `cq_theta` on a `%out`-derived value is a SOURCE to the fence and
  CHAINED to the lowering, so two siblings on one rail were controlled on the
  wrong state (bd `9pum`, `r9e5` F-B1R2-1);
- a **TAINT-GROWTH EVENT** — `MergePhiPeel` *manufactures* tainted values ~90
  lines after the guards that adjudicate consumers of tainted values have run;
  five plain-C escapes of a rail HANDLE to classical code compiled at exit 0
  (bd `b6ap` F-B6-1).

**The cure is always the same and it is a pattern, not a prediction:** RECORD the
question at the site that asks it (`!cq.branchphase`, `taint.RailCondReads`,
`taint.CmpCondReads`, `taint.InPlaceRailOps`) and **RE-ASK it after the round-2
fixpoint, in BOTH entry points**, declining loudly. For a stage, move it after
the fixpoint. For taint growth, run `adjudicateTaintDelta` — the same guard
sequence `repropagateControlMerges` already runs. ⚠ **The record must be at
EVERY emission site** (`markBranchPhaseGate` 6 calls / `markRailCondRead` 6 call
sites): a seventh emitter that forgets it re-opens the window with **no
diagnostic anywhere**. `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 carries the stage
table that asks every stage in the window *"do you compute something a later
stage consumes over a premise round 2 falsifies — and do you GROW the taint
set?"*. Read it as a METHOD, not a result.

**(L2) When you WIDEN a set, ask what OTHER set was computed over the same
closure.** 8h7d.5 F-1 widened the *gate* set from the chain to the rail and left
the *record* set enumerating chain members; F-3 was that omission, found one
round later and not by the 1281 green fixtures. Same shape: r9e5 rung (ii)'s
measure set was the rail's SSA NAME while rung (iii)'s gate set was the rail's
WIRE; r10v widened the read POINT and did not re-derive the same-block clause.

**(L3) When a set is NARROWED, ask what OTHER predicate names the same gate** —
and the answer is not always "narrow it too". Three spine predicates were taught
to refuse a kickback gate by **membership**; a fourth,
`Uncomputation::preservesBorrowedParent`, still answers `true` for the same
instruction **BY NAME**, and that verdict is **SOUND**: the three ask *"may the
spine ADJOINT this gate?"* (no — that cancels the answer), it asks *"does this
gate DISTURB the borrowed parent's basis label?"* (no — it is diagonal, whoever
emitted it). Narrowing it "for symmetry" would silently delete a real discharge.
A closure table that claims to be complete is worth exactly its most-missing row.

⚠ **The MIRROR of L3 cost a P1 filing on 2026-09-14: when you ADD A CALLER to a
shared predicate, read the callee's RETIREMENT TRIGGER and state which direction
you are using it in.** `WireWalk.h` named the dtzb vocabulary gap precisely,
called it "NOT EXPLOITABLE" *for the callers it then had*, and instructed the
next caller to *"WIDEN THE VOCABULARY (or fence the caller) IN THE SAME CHANGE"*.
A third GRANTING caller (`readerStalesItself`) arrived, the argument behind "NOT
EXPLOITABLE" did not reach it, and nobody read the trigger — `IMPL_D.md` §15.4 /
§16, filed and open, cross-referenced to bd `a3z7` / bd `0njv`.

**(L4) A wire question must be a gate SET, not a BOOLEAN over a return-first
walker.** "Is any non-diagonal gate visible?" answered by a walker that returns
the FIRST one it finds is defeated by putting an already-ACCEPTED gate in front
of an unaccepted one. Enumerate, take the difference, and carry the exemption as
a per-entry bit (`WireRuled`).

**(L5) A syntactic answer to a semantic question loses.** F2 enumerated the ways
`-O1` could fold a seed and lost **four rounds running**, each to a different
rewrite (forward user, sideways compare, curated intrinsic, type gate, fp
invisibility). It stopped being a set and became **the question**, asked with
LLVM's own machinery. When you cannot bound something, say what is skipped and
why the *compiler* could not have folded it either.

**(L6) Before declining a shape, ask whether the thing you are protecting is the
unitary or the emitter's bookkeeping.** The sequential-region pair declined as
`nested control flow` for four months — a STRUCTURAL guard wearing a semantic
label. The real hazard was a teardown **order** bug, and it was fixed by order.
Only a unitary hazard is a Prime-Directive decline.

**(L7) An agent-authored justification hardens into a ruling if nobody rules.**
`fenv`, the missing `xor i1` condition-tree node, the rail fence's "the
positional prong is already what the walk asks" (false — no measurement behind
it). If a bound is load-bearing and unruled, take it to the owner.

⚠ **L7 WITH A TWIST, measured three times on one sentence (bd `z9t1`, 2026-09-14):
A RECORD CORRECTION THAT IS NOT APPLIED TO THE SOURCE IS NOT A CORRECTION.** The
false clause — *"i.e. only where the object was undefined on BOTH edges"* — was
corrected in the track's record in review round 1 and **never landed in the
source**; round 2 found it still in `RotationLowering.cpp` and specified the fix;
**that fix did not land either**; round 3 found it a third time and measured it
*wronger than round 2 had* (the "i.e." describes a rule whose population is about
**four** modules; the shipped clause's is **164**). The justification was not
merely unruled — it was ruled wrong three times and kept being read off the
source comment that still carried it. Fix the comment in the same change, or the
next round re-derives the same finding.

**(L8) Write RETIREMENT TRIGGERS into fixture headers and source comments; they
work.** A fixture header that said *"when `l4x4` lands, this file's string
changes and it becomes an ACCEPT whose emitted stream is … Re-derive it then; do
not delete it"* was **character-for-character correct** on the landed binary.
⚠ And a **merge can resurrect a `git mv`'d fixture** — one module under two
names with contradictory verdicts, invisible to every review that ran before the
merge. Run a duplicate-body scan (sha-256 over each fixture's non-comment lines)
after any merge that renames fixtures.

**(L9) The enduring RSSA lessons, restructured but not deleted:**
- **RSSA φ appear on BOTH splits and joins.** The merge is the **adjoint of the
  branch**, sharing the **same live condition**. The *mechanism* (a `cqrt_cswap`
  route in, a `cqrt_cswap` route back) is HISTORY; the *obligation* is not —
  whatever the join does must be the split's undo. In the controlled-copy merge
  the split is "hoist the chain, mint the flag" and the join is "two X-bracketed
  `cqrt_copy_<W>_controlled` into a fresh `|0⟩` rail, then strip the flag".
- **RSSA proves *classical* reversibility only.** The superposed-control /
  no-cloning / Rz·Ry / reverse-play layer is the **original** part of this
  design, validated by one-off statevector reasoning — never "it's RSSA,
  therefore correct" (SCOPING §0).
- **Method matches arm class, not convenience** (Rule 7). Bennett
  compute→copy→uncompute is the *special* case (basis-valued arms), not the
  general one; it **dephases** phase/rotation answers.
- **Branch polarity is inverted by `clang -O1`** (Rule 9).
- **An unlowerable merge φ must DECLINE, never dangle.** Integer merge φ is a
  real **data mux**; floating-point merge φ is a rotation **angle** — do not
  cross these wires. Test FP-ness with `isFPOrFPVectorTy()` (scalar-only
  `isFloatingPointTy()` misses `<2 x double>`); never key data-mux lowering on
  `abiWidthFromType()` being non-empty (f64 has a valid width yet is an angle —
  that was the f64 silent miscompile).
- **Free only a proven-`|0⟩` rail** (Rule 6); **never free a source carrying
  superposition by copy+uncompute** — that needs `cqrt_cswap` (Rule 8).
- **Block lifetime under sequential lowering:** linearization erases merge
  blocks; a region whose predecessor is another region's merge block
  dereferences freed memory (SIGSEGV on valid input). Capture identities before
  the first erase, or decline while blocks are still valid — and do **not**
  blanket-decline every shared merge (the nested-AND pair legitimately shares
  its merge).

**(L10) Instruments earn their keep by being attacked.** The quarantine file
(`tools/loop_twin_matrix.quarantine.txt`) pins each blessed divergence by
`(verdict, SHA-256 of the exact unified diff)` and **fails if the signature
moves, if the cell stops diverging, or if it appears in both files** — with two
boundary controls that run on every invocation, `--regenerate` included (a
review found both write modes returning *before* the controls ran, and
`--regenerate` writing a forbidden row under a message that called itself a
refusal). Its own mutant validation is `e2e-loop-twin-quarantine-selftest` (27
cases). Same argument as `free_pairing_check_test.py`: a checker nobody has
tried to fool is a checker nobody should trust. A gate expected to be red is a
gate people stop reading.

⚠ **AN INSTRUMENT'S FAILURE MODE IS TO REPORT A PASS, so the only instrument
worth citing is one that has been made to fail on purpose.** This is a
restatement of L10, not a new rule, and it is in the file because **six measured
instances landed in ONE session** (2026-09-14), each found by the agent that
owned the instrument and none by a green suite: a **vacuity checker** printed
`checked 0` on a batch of 29 real negatives (it matched only handle-form
negatives); an **injection matrix** printed `0 mutations, MISSED 0, N/A 0` when
invoked with **no fixture argument** (now exits non-zero); an **injection
harness lied twice in the MISSED direction** before it told the truth, the second
spelling moving a mutation *across a function boundary*; an earlier matrix
reported **45 MISSED against fixtures that catch everything**, because it ran
`FileCheck --check-prefix` and dropped the RUN line's `--implicit-check-not`
flags — *a harness that runs a weaker command than lit measures itself, not the
fixtures*. Two more destroy evidence rather than misreport it: `--regenerate`
silently ate **54 lines of Rule-13 ruling prose** from a baseline header and
reported success (bd `gfsk`), and **a 0-byte `.ll` module ACCEPTS** through the
passthrough early-out, so six probes scored ACCEPT on nothing (bd memory
`empty-module-accepts-vacuity-trap`; the cause was `sed X.s1.ll > X.S1.ll` on a
case-insensitive filesystem). ⚠ And the twin matrix's own instructive cell:
`m_none_pbitd_none_premark_rypost` went `ACCEPT-IDENTICAL` → `DECLINE-BOTH` when
the stale-reader fence landed — **a cell whose two halves agreed because BOTH
were wrong is precisely what `ACCEPT-IDENTICAL` cannot see; only a fence can.**

### 4. The 2026-09-11 landing — the owner's file compiles

`example/grover/grover_oracle_uncompute.c` — `_Bool b0`, `_Bool b1`, no `int`
workaround and no new `cq_*` function — compiles **as written**: `opt` exit 0,
stderr empty, 19 trace lines, STRICT stage 2b `6 rail mint(s) of which 5 left
allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven`. It took
four increments in one session because it had **three walls in order**: the
multi-phi merge peel (bd `b6ap`, `3a3a2b9`) → the bare-`_Bool` controlled-Ry arm
and state prep (bd `l4x4`.b, `e96f89c`) → F2's `CondWire` narrowing (bd
`drbq.14`, `a9cc062`), alongside the compare-select fence parity (bd
`9pum`+`r10v`+`r903`(b), `7203d1c`).

The emitted stream, and the one invariant to read it by: `alloc_i1→h0;
ry_i1(h0,.5)`; `alloc_i1→h1; ry_i1(h1,.5); ry_i1_controlled(h0,h1,−.5)`; the
peeled `a`-mux as the rail-root CNOT-copy select merge (`alloc_i1→h2;
cnot(h0,h2); alloc_i32(0)→h3; alloc_i32(2)→h4; copy_i32_controlled(h2,h4,h3);
x(h2); alloc_i32(5)→h5; copy_i32_controlled(h2,h5,h3); x(h2); cnot(h0,h2);
free(h2)`); then three measures. ⚠ **`h0` is read ONLY as a control** and
measured once: never `cqrt_x`-bracketed, never freed. The two `cqrt_x` are on
the ancilla `h2`, whose `x ⊕ x = 0` return makes its free a proven-`|0⟩` one.
The emitted ORDER puts the negated prep before the peeled mux (swapped vs
source) and that is the same unitary exactly — both are block-diagonal in `h0`'s
basis and act on disjoint targets, so they commute — and it is STRUCTURAL, since
`-O1` fused the two source regions and left no source order between them.

**The owner's rulings from that session**, because they govern what comes next:
*"our end-goal is to not decline any code that will lead to a valid quantum
circuit"* (an over-decline is a defect); **option 1** for the compare-select work
(fences first — A.1 — widenings second — A.2 — then bd `3d8q` on its own);
**H-3 = ADMIT** (the S† after a VALUE region, refused at P1 on `SawValueArm`
while the 6.5 arm has no P1 wrapper — decide once, in the admit direction; it is
an A.2 widening and is **not built**); and the reversal of "the `i1` state-prep
width is OUT" — *"WE DO NOT WANT TO WRITE `int b1`. also WE DO NOT WANT ANOTHER
cq function … I dont see the need for the over-decline."*

⚠ **What the F2 narrowing silently absorbs, in the words it must be said in.** A
program that was LOUDLY REFUSED now receives the circuit for the *other* reading,
with no diagnostic: **α** (15 of 19 flipped fixtures) an in-place Ry on the
CONDITION's own register, which after `-O1` is **byte-identical** to the genuine
prep; **β** (4) where the straight-through incoming was a live register `-O1`
folded to the seed. No fence can separate them because after `-O1` there is one
module, so the mitigation is **disclosure**, not a predicate — and a warning was
deliberately NOT added (it would fire on every Grover state prep the ruling
exists to enable). It is admissible because the rival has **no lowering to be
robbed of**: `railWireClosure` inserts its seed before any gate, so
`RotBase ∈ CondRails ⇒ R4 declines` for every chained rotation arm, and β is
covered by a state-vector argument (on the pinned edge the register *is* the
product basis state |seed⟩, so a controlled copy yields |seed⟩⊗|seed⟩ — nothing
cloned). ⚠ **RETIREMENT TRIGGERS**: the narrowing must be re-derived from
scratch if `railWireClosure` as called by F2 ever diverges from R4's
`CondRails` (different helper, `WireDir`, seed set, `Exclude`, or one call site
"tidied"), and it becomes an OVER-ACCEPT the day any chained rotation arm whose
`RotBase` is in `CondRails` lowers — whose live door is **2c**, not R4.

### 4b. The 2026-09-13 landing — the owner's EXTENDED file compiles; the loop form is scoped

The owner added ONE line, `if (b1) a -= 3;`, after the bool-controlled prep of `b1`, and it declined
`control flow`: `-O1` if-converts it into a 4.4 DATA `select` whose CONDITION is the prep region's
MERGE φ, off the leaf grammar. **Measured before any code: `if (b1) a -= 1;` compiled on the same binary**
(InstCombine folds a ±1 delta to `add(a, sext b1)` — the φ was already a quantum register to `lowerOps`;
only the `select` consumer was refused), and the target stream was read off the ORACLE from a hand-IR
twin (`trackM/probes/m18.ll` = the module after M-β), so the increment was provably an ACCEPT-only
widening. Three squash landings (records `inc1-records/session-2026-09-13-orchestrator/`, PRD §16):

- **`59ac5b7` — Track M, bd `boi6` D-B / `8xaw`: the region-merge-φ RAIL LEAF for the 4.4 data select.**
  `CondTree::RailPhiLeaves` + `AllowRailPhi` (default false; `true` ONLY from `classifySelectRegion`;
  `isCondRailLeaf` NOT widened, `RailLeaves` NOT retyped — the TYPE is the enforcement), ROOT-ONLY; rung 0
  admits the φ iff it is the `Merge` of a region ALREADY in the plan as `BranchRegion` with
  `ClassArm`/`ClassArmFalse == InPlaceRotation` and a non-empty `Shadow` — **by CALLING `classifyArms`'
  committed verdict, never re-deriving it**; rung (ii) over `condProvenance(φ)` (not `Shadow.front()`);
  rung (iii) = gate 2c seeded from the φ. **`CondTreeEmit` needs 0 lines**: by emit time
  `emitInPlaceRotationRegion`'s M-β has RAUW'd the φ to the theta CALL and the r9e5 `CopyRailRoot` stream
  fires unchanged. Two hazards that bit: (H-1) the plan's raw `ControlRegion::Condition` DANGLES after the
  prep's flatten erased the φ — `SelectMergeEmit` re-reads `cast<SelectInst>(R.Merge)->getCondition()`,
  proved by COUNTERFACTUAL (one line reverted → the owner's file declines ×3: the emitter was walking
  freed memory); never "fix" it with a `WeakTrackingVH`. (F-M1, review r1) a `SelectRegion` was INERT in
  `lowerControlRegions`' `hcrg` precedence graph, so a following kickback whose `Pred` is the prep's merge
  block could push the prep to emit LAST — fixed by recording `PrepRegionIdx` at rung 0 and adding ONE
  edge "prep before select" by calling that record (a `SelectRegion` sets no block fields ⇒ a sink ⇒ no
  cycle); every emitter inserts positionally, so the stream is source order regardless of schedule. The
  owner's file: **29 lines, STRICT 2b `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2
  verified, 0 violation(s), 0 unproven`**, lines 1–16 = the 2026-09-11 stream; `h0`/`h1` read only as
  CNOT controls; the four `cqrt_x` on ancillas. Also lowers: the run-time-`a` general cascade (31), a
  compare-conditioned prep + select (21 — the scoped `RailLadderProven` conjunct was an over-decline and
  was dropped), a third region after the select (33), an in-loop select on an OUTSIDE prep's φ rolled ==
  unrolled 43 = 43. **H-6 ruled ADMIT**: "two preps of `b1`" is the S† shape (the theta is CHAINED on the
  condition's own name; the rail spelling accepts on the frozen ORACLE); the GENUINE `3d8q` sibling shape
  reproduces on the ORACLE with no φ — Track M adds customers to that P1 hole, no fence. **Deferral was
  measured UNSOUND**: `declineClassicalMuxes` `continue`s on a tainted-condition select, so a deferred
  select is declined by NOTHING and the `i32` RAUW leaves `select i1 <i32>` → `report_fatal_error`.
- **`94c085e` — Track R-1, bd `rb9x`: F2 excludes the peel's compare CLONES via `taint.PeelClones`**
  (`WeakTrackingVH`; consulted as ONE conjunct at the TEST beside `!CondWire.count(V)`; never at the
  anchor, never pruning the users walk — `control_peel_reject_fp_stateprep.ll` declines through
  `f2Model`'s conservative arm on an fp select reachable ONLY via the clone). The route: the clone is
  dominance-filtered out of the BACKWARD `Cand` set and enters through the FORWARD users walk (no
  position filter), folds to a singleton `i1` per edge, and matches an `i1` seed. The argument is
  PREIMAGE (a value the pass MANUFACTURES has no source preimage, hence no rival), NOT "same wire" (a
  two-diamond function clones the OTHER region's condition too). **A dominance conjunct is REFUSED IN
  WRITING**: ≥11 shipped F2 fixtures pin MERGE-BLOCK colliders (`range_forward_*`, `sideways_*`,
  `merge_edge_sideways`, `step_cap_over`). The `int b0`/`bool b1` fused spelling compiles (22).
- **`23b0cd1` — Track C, bd `21mg`: `cq_measure` of a never-quantum value lowers to the classical value**
  (the sole sink splits on TAINT and nothing else; no symbol, no gate, NO trace line — owner Q-1: if the 7.6
  output tape wants every user-written measurement, this is the site; a new loud `undef/poison` decline).
  The round-2 window is discharged by ORDER (`lowerMeasures` after `repropagateControlMerges` in both entry
  points — RETIREMENT TRIGGER: moving it passes an `i32` HANDLE through as data). Fact recorded:
  **`LLVMContext::diagnose` EXITS on the first `DS_Error`** — a fixture pins ONE diagnostic; the in-tree
  "report and skip" comments are wrong (bd `br4a`). Plus **L-0**: the two shipped-but-unpinned rolled
  accepts (a carried `_Bool` whose condition is the in-body chained theta) pinned 9 = 9, K-independent.

**Still declined, by owner ruling or by scope:** `vd.c` (N=3) — the `b1` prep's seed collides with the
THIRD region's guard pinned on the true edge (no peel; bd `om35`: the audited spelling R-2′ "a collider
pinned on ONE edge is not a collider" closes it with an argument but flips ≥11 shipped decline fixtures);
the phase consumer on a prep merge-φ (bd `3qps` — the same leaf-grammar gap, NOT `drbq.7`'s wire fence:
`SCOPE_boi6` §0.3 is true of a CHAINED arm theta and false of a SOURCE-theta prep); the in-place-ARM φ
(pinned as a DECLINE whose retirement is "land the `3d8q` fence, then re-derive `condProvenance`'s seed").
⚠ **All three moved on 2026-09-14 — read §4c**: `vd.c` compiles (bd `om35`, by the φ-descendant
exclusion and NOT by R-2′, whose cost was re-measured at **25** flipped decline fixtures, not 11), the
phase consumer on a prep merge-φ lowers (bd `3qps`), and the `3d8q` fence the third item names is
landed, so that retirement trigger is now live work rather than a wait.

**The LOOP form (Track L, scoped, `trackL/SCOPE_loop.md`, 37 probes, no code).** Spelling (i) `bool
b[N]` has exactly ONE wall, N-independent — `cq taint escape: tainted value stored to memory`, BEFORE
`lowerLoops`; rolled, `-O1` stamps `llvm.loop.unroll.disable` so no constant N scalarises; fix = bd `xdu2`
L-1a the bounded rail ARRAY (`[N x i1]` → `[N x i32]` of handles in classical memory; no new ABI; rails
stored to memory are FROZEN; `free_pairing_check` counts alloc SITES so the golden trace is the witness).
Spelling (ii) scalar `bool b` has four walls (bd `x5fp` L-2 the §3c clobber THROUGH THE BACK EDGE; the
LICM-hoisted compare; L-3 `bool b = 0` gives `railPhiRootMint` NO MINT; bd `ej5w` L-4 the loop layer's X1
clause declines the in-loop VALUE arm before detection — NOT `3qlq.6`) **and denotes a DIFFERENT circuit**
(`a` goes negative). A carried `_Bool` is an `i8` WIRE in every loop form (bd `r903` is load-bearing there).
Owner question Q2 carried: (i) recommended.

**The non-redundancy protocol (owner addon 2026-09-13, `PROTOCOL.md`)**: a hash-keyed `GATES.md` per
track; a gate result is a fact about a BINARY; the merge-and-gate agent is the ONLY full-`ctest` runner.
Measured: 4 full-suite runs for 3 landings; 0 cited-but-stale lines. Instrument lessons: md5s do not
compare ACROSS sweeps; the shared corpus tag regex hides a D→D string change inside the `cq_measure`
family (close with a full-stderr byte-compare); a mutator reading N/A is a hole; a named negative can be
VACUOUS (`trackM/probes/impl/vacuity.py`).

### 4c. The 2026-09-14 landing — the owner's N=3 cascade compiles, and the project's one known silent miscompile is CLOSED

**The owner's `example/grover/grover_oracle_uncompute.c` with the THIRD region live compiles as
written** — three `_Bool`s, no `int` workaround, no new `cq_*` function. Measured on the rebuilt
primary at `66428ddc` (`CLOSING_MEASUREMENTS.md` §3–§4): `opt` exit 0, **stderr 0 bytes** (no warning
either), **35 trace lines**, STRICT stage 2b `9 rail mint(s) of which 7 left allocated, 3 cqrt_free
site(s): 3 verified, 0 violation(s), 0 unproven`, and the trace is **BYTE-IDENTICAL** (equal sha-256)
to `tests/e2e/slice_control_cascade_three_bools.expected.log`. The invariants are readable straight
off that golden: `h0` and `h5` are the USER'S registers and appear only at arg 0 of a `cqrt_cnot`, as
the control of `cqrt_ry_i1_controlled`, or in a measure — never `cqrt_x`-bracketed, never freed;
every `cqrt_x` sits on an ancilla (`h1`, `h7`) whose `x ⊕ x = 0` return makes its `cqrt_free` a
proven-`|0⟩` one; `h9` is the third region's flag — one mint, one strip, one free.

⚠ **The owner measured that same file DECLINING on that same tree, and the cause was a STALE BUILD,
not a regression.** The primary `build/` was still the frozen pre-merge oracle, three increments old;
the string it printed was a real, correct, historically accurate diagnostic — emitted by a compiler
that predates the fix. **The cheap discriminator is the hash**: `shasum -a 256 build/ir-pass/cq-opt`
*before* believing any decline. It is the trap this file already records, seen from the other side —
`--target CQPass` alone leaves `cq-opt` stale and lit reports **false green**; a stale `cq-opt` makes
a *fixed* program look broken by hand and a *broken* pass look green in lit.

**Six increments, ONE group gate** (`MERGE_REPORT.md`, and every gate line hash-keyed in the session
`GATES.md`):

| # | bd | commit | what landed |
|---|---|---|---|
| 1 | `uq96` | `49b7f7bc` | the `i1` axis for `e2e-loop-twin-matrix` — 288 → 338 cells, the pre-existing 288 byte-identical and unmoved. An instrument, not a lowering, and it landed FIRST because it is the witness for increment 5 |
| 2 | `z9t1` | `f28e435a` | an `undef`/`poison` SEED reaching a **source** `cq_theta` becomes the type's concrete zero **at the allocation**, normalized early and silently (owner ruling, five clauses) |
| 3 | `om35` | `30317792` | F2's **φ-DESCENDANT** exclusion — the owner's N-deep cascade compiles; **0 of 29** F2-naming fixtures moved |
| 4 | `3qps` + `4aiu` | `71de13c2` | a preceding prep's merge φ as a rail LEAF at the phase kickback, and at an INTERIOR tree position at both consumers — ONE predicate, two call sites |
| 5 | `wx8g` | `a2b86139` | the IN-LOOP iteration-local rail and the retirement of the `l4x4`.b carve-out: a rolled bool-controlled Ry arm / state prep lowers, where `CLAUDE.md` recorded it compiling in **NO spelling on ANY binary** |
| 6 | `3d8q` | `81c55430` | the **STALE-READER fence** — the project's one known verify-clean silent miscompile, closed |
| — | — | `66428ddc` | the merge gate's resolution: the e2e half of the stale-reader ruling, and the adjudication of the 41 moved twin-matrix cells |

**The owner's rulings of 2026-09-14** (`DECISIONS.md`, verbatim where quoted): **Q3** — bd `3d8q`
gets a track, *correctness over expressiveness*, because the miscompile's population had been widened
twice and now blocks a filed widening too. **Q1** — for bd `om35`, build the **φ-descendant**
predicate and **not** R-2′; the question put to the owner was *"which one would result in a more
general method not over-declining, so compiling code that actually leads to valid quantum
circuits?"*, and the measured answer was that R-2′ flips **25** shipped decline fixtures (13 of which
say CONFIRMED MISCOMPILE in their own headers) while the φ-descendant rule flips **zero** and closes
all three customers; R-2′ stays FILED as a costed capability. **Q2** — the loop spelling is (i) the
bounded rail ARRAY, and after Track L's scoping falsified bd `xdu2`'s premise (three walls, not one)
the order was changed to build `wx8g` FIRST. **The in-loop invariant re-read DECLINES** — `int b =
cq_theta(q, 0.1);` re-reading a loop-INVARIANT `q` every trip has **two realizable circuits and the
source names neither**, so it is ambiguous; the conditional-probability measurement settled it
(intended `P(1) = sin²(0.2) ≈ 0.0395` i.i.d. per trip against the emitted `P(1|prev=0) ≈ 0.0025` /
`P(1|prev=1) ≈ 0.9975`, locked onto the first outcome). ⚠ The reading that had been put to the owner
— *"fresh from `q` each trip requires CLONING, so the emitted chain is the only possible circuit"* —
was **false**, and re-preparing a KNOWN state is not copying an unknown one.

**What the stale-reader fence cost, measured and not estimated.** 104 corpus modules go
`ACCEPT → DECLINE` on the new string `cq opcode lowering: rotation/measure operand predates a
non-diagonal gate`; 12 of them are shipped `ir-pass/test` fixtures, all converted with the increment.
**Two e2e slices could not be converted in place** — the e2e layer has no decline shape (`run_slice*.sh`
runs under `set -euo pipefail` and byte-diffs a golden) — so both `.c` files were KEPT unregistered
with a conversion header and an L8 retirement trigger, both goldens **DELETED** rather than rewritten,
following the `slice_control_switch_phase.c` precedent of 2026-09-05. ⚠ **A coverage hole was found in
the process**: the `cmp` program was already pinned by Track D's inverted fixture, but the **bool
(rail-leaf) program was pinned nowhere at all**, so unregistering it alone would have dropped the
decline entirely — its verbatim linked stage-1 module is now
`ir-pass/test/control_swap_reject_select_rail_round2_window.ll`, validated NON-VACUOUS **by binary
mutation** (FileCheck does not match on the pre-session oracle, where `opt` exits 0). Net coverage
cost of the conversion: **zero**.

**F2's φ-DESCENDANT exclusion — carried verbatim from the track that measured it (bd `om35`,
`IMPL_F.md` §2 / `CLAUDE_MD_EDITS.md` §1).** ⚠ Read it with the paragraph that follows it: its closing
retirement trigger says *"the day `wx8g` lands"*, and `wx8g` landed in the same merge, so the block's
sentence *"every in-loop state prep is stopped before F2 today"* is **already history**:

> **F2's φ-DESCENDANT exclusion (bd `om35`, owner-ruled 2026-09-14) — the ground is AVAILABILITY, and it is
> an OPERAND argument, not a position one.** F2 asks *"could the source the author wrote have been
> `cq_theta(<that register>, θ)`?"*, and that register can occupy exactly **two** slots of the module in
> front of the pass: the arm theta's arg-0, or the merge φ's PRED-edge incoming. The region's own merge φ
> `M` is defined **at the join**, so `M` is available at **neither** slot — and therefore **no value whose
> operand chain reaches `M` can be SPELLED at either slot, in any module**. Such a value is not a register
> the author could have named in the definition of `M` itself, so it is not a witness, and F2 stops counting
> it. It **removes a witness, not a decline**: any other pinned value that could occupy a slot is still
> found, on either edge, and still declines.
> ⚠ **Never compress this to "`V` sits after the join".** That sentence is about POSITION, it *is* the
> dominance conjunct that stays REFUSED IN WRITING, and it is **false** — `-O1` **sinks**, so the ≥11 shipped
> merge-block colliders (`range_forward_*`, `sideways_*`, `merge_edge_sideways`, `offwire_sideways_min`,
> `step_cap_over`) also sit after the join and are genuine rivals precisely because their position is a
> consequence of the fold, not evidence about the source. The operand form survives sinking because
> **sinking moves a definition and never rewrites its operands**; and a pre-region value cannot *acquire* a
> use of `M` in place at any `-O` level, because that is invalid SSA.
> ⚠ **The argument is a theorem only for an ACYCLIC user chain, and since 2026-09-14 that precondition is
> ENFORCED, not assumed.** A φ is the one opcode whose operand need only dominate its incoming EDGE, so a
> **loop-header φ taking an `M`-descendant on its BACK EDGE** both uses `M` and dominates both slots — the
> available collider the bullets say cannot exist (measured as a mover: ORACLE fires F2, the un-narrowed
> subject does not). `collectStatePrepPhiDescendants` therefore **skips a φ user that `M`'s block does not
> dominate**. That is a **NARROWING of the EXCLUSION set** — opposite object and opposite direction from the
> refused conjunct, which tests a *collider* against the *arm* and turns declines into accepts, where this
> tests a *member* against *`M` itself* and can only add declines. The invariant it buys is that every member
> lies in a block dominated by `M`'s block.
> ⚠ **RETIREMENT TRIGGER: bd `wx8g`, by name.** Every in-loop state prep is stopped before F2 today
> (`control flow inside a loop body`), and that open over-decline is the **only** reason the back-edge shape
> is unreachable rather than merely narrowed — in-loop regions **do** reach `classifyArms`, so the loop is
> not a blanket fence. The day `wx8g` lands, re-derive the narrowing against the shapes it admits, and do not
> assume the φ case is the only cyclic one. The fixture pair
> `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll` is the tripwire.

⚠ **THAT RETIREMENT TRIGGER HAS ALREADY FIRED, AND THE RE-DERIVATION IS OWED, NOT DONE** — `wx8g`
landed in the same merge. Measured at the group gate (`MERGE_FILINGS.md` §1, probes committed under
`merge_gate_probes/x5{a,b,c}_*.c`): the two named tripwire fixtures **HELD** (both still decline at
F2, with a byte-identical `CQ_CTRL_DBG` anchor to the oracle, `lit --filter backedge` 4/4), **but the
premise "`wx8g` is the ONLY reason the back-edge-φ shape is unreachable" is now FALSE.** Three probes
built from the shapes `wx8g` admits go from `control flow inside a loop body` on the oracle to, on the
merged binary, an F1 decline with a source-located `!dbg` (`x5a`, the available back-edge collider
itself) and two ACCEPTs with STRICT 2b clean (`x5b`, `x5c`). Nothing the gate could construct
over-accepts; the skip is **live rather than vacuous**; and the trigger's own second sentence — *"do
not assume the φ case is the only cyclic one"* — is exactly the part three probes cannot discharge.
**The argument text in `ArmClassify.cpp` is STALE and must not be cited as it stands.** (The
narrowing has two further open filings of its own, bd `hrts` and bd `l3i1`: the dominance skip is
broader than its stated rationale and has ACYCLIC customers, so the retirement trigger naming only
`wx8g` describes the CYCLIC half.)

**The bd `z9t1` DISCLOSURE — carried verbatim from `IMPL_U.md` §2(b′), whose same text is at the
mechanism in `RotationLowering.cpp`.** It is the same class as the F2 α/β narrowing: a loud refusal
becomes a silent compile, no predicate can separate the readings after `-O1`, and the mitigation is
therefore **disclosure, not a fence**.

**136 modules that the ORACLE loudly REFUSED now compile SILENTLY, and 116 of them move through one
mechanism: F1's pointer-identity proof is MANUFACTURED, not found.** F1's second sub-clause is a
literal `Value*` comparison — `MergePhi->getIncomingValue(PredIdx) != RotBase`
(`ArmClassify.cpp:3905-3908`, read in source by this fix round, not inherited) — and
`Constant::getNullValue` is **uniqued**, so rewriting a seed `undef` and a straight-through `undef`
to "the type's zero" makes them **the same `Value*`**, for two operands the source never equated.
The other 20 rows: 14 `control flow` (the `MergePhiPeel` P3b route above), **4
`cq_measure_<sfx> operand is an undef/poison literal`** — the ruled clause-4 decline reached
*upstream* of the sink, which is **F-U3-1, open with the owner, and NOT covered by this
paragraph** — 1 `condition predates a non-diagonal gate`, 1 `nested control flow`.

**The rival reading, stated as a program and not as an IR shape:** the seed and the merge's
straight-through incoming were **two different uninitialized C objects**, and the source never said
they were equal. `pD_two_objects` is the minimal witness — the prep seeds from object *X*, the
straight-through edge carries object *Y*, and it moves `D→A`. The compiler now treats them as **one
value** at the state-prep proof.

**Why the rival has no lowering to be robbed of — two halves, because either alone would be an
assertion.** (1) On the oracle the two-object module is a **loud decline**, so there was no circuit
for the other reading and nothing is displaced. (2) The accept it now receives is a **refinement**,
not a choice between two circuits: LangRef lets an `undef` stand for any value of its type, so `0` at
each read is a value the source **already licensed**, and the emitted stream is **byte-identical** to
what a written `= 0` on both objects produces — measured on all **164** modules of the phi half's
population, 0 divergences, 0 `A→D`. On the ¬flag component the fresh rail holds |0⟩, which is a value
object *Y* was permitted to have. **No fence is deceived about a value the program actually wrote.**

**Why disclosure and not a predicate.** After `-O1` there is nothing left to discriminate: *"one
object read twice"* and *"two objects that were both uninitialized"* are **the same module** —
`undef` is uniqued per type, so the IR carries no record of how many C objects there were. A fence
that refused the two-object reading would have to refuse the one-object reading this rule was **ruled
to compile**. And a warning was **deliberately not added**, for the same reason CLAUDE.md §4 gives for
the F2 one: it would fire on the owner's own ruled spelling — *"both codes are supposed to compie!!
also no warnings."*

⚠ **RETIREMENT TRIGGERS, three, each naming what would make this paragraph wrong rather than merely
out of date:** **(i)** F1's second sub-clause stops being a `Value*` **identity** test — a
value-equality or provenance test would make the manufacture *visible*, and that is the only place a
real predicate could live; re-derive from scratch. **(ii)** the clause rewrites anything that is not
`isa<UndefValue>`, or `undef` stops being uniqued per type — those are the refinement's only two
load-bearing facts, and either one gone makes this an **over-accept**. **(iii)** the 4 `cq_measure`
rows are **not** covered here: they are a ruled clause reached by a new route, and they are with the
owner.

**One positive from the same surface, recorded so the disclosure is not read as all-cost.**
`lowering_unroll_const_trip` is round 3's single `IR-only` row: at HEAD with an undef phi incoming,
LLVM constant-folds the `fma` to NaN and **the user's `cq_measure` disappears from the emitted module
entirely**; the subject restores it. bd `z9t1` *removes* a vanished user measurement here — it does
not create one.

> ⚠ **TWO DIFFERENT 164s, EQUAL BY COINCIDENCE.** *"164 of 972 carried thetas"* (direction 1) is a
> **count of thetas**, from the census; *"164 modules"* is the phi half's **module population**, from
> the isolation sweep. Different instruments, different denominators. **Do not cite one as evidence
> for the other** — this warning is carried at every site either number appears
> (`RotationLowering.cpp` ×2, the fixture header, `FIX_U_R3.md`).
> — and now here, in `CLAUDE.md`.

**What the group gate found that no single track could** (`MERGE_REPORT.md` §5, `MERGE_FILINGS.md`):

- **The F × P composition — two new ACCEPTs cleared BY MEASUREMENT and NOT BY REVIEW.** Of 290 corpus
  movers, 8 are reproduced by no single-track binary, and three of those are one shape: *a condition
  TREE whose leaves are preps' merge φs* (`if (b1 && b0) cq_phi(0.3)` and `if (b1 && b0) a -= 3;`).
  Track F alone clears F2 and then hits the leaf-grammar wall; Track P alone admits the leaf and then
  hits F2; **only together do they accept.** Both are STRICT-2b clean with well-formed streams (the
  kickback sits on a `cqrt_toffoli` of the two rail leaves, `h0`/`h1` read only as controls, ancillas
  returned to `|0⟩` before their free) — and that is exactly the evidence Rule 2 calls **necessary
  and not sufficient**. Track F's Rule-13 rounds saw a binary on which these decline, and so did
  Track P's. **A composition is not cleared by clearing its parts.**
- **Three surviving over-declines on the `il*` × `bcar` combination** (`MERGE_FILINGS.md` §3): the
  rolled side declines `control flow inside a loop body` while the FLAT spelling of the same program
  lowers. The blocker is the COMBINATION and the matrix isolates it by measurement — an
  iteration-local TARGET rail (clause (c)'s subject) beside a CONDITION rail re-rotated inside the
  body; the same carried condition with no iteration-local target **did** flip. Per the owner's 2026-09-11
  ruling that is a defect to remove, not a safety margin.
- **One ACCEPT→DECLINE outside the fence** (`d4_noRailRegion.c`, Track W): safe-direction, present
  already in the Rule-13-cleared binary, and its own round-1 review had measured that program as a
  rolled-vs-unrolled TRACE DIVERGENCE **on the oracle**. Filed as an over-decline candidate with that
  note, not as a defect.
- **Diagnostic locations: 0 lost `!dbg` over 2060 decline rows, 21 gained.** A lost source location is
  invisible to every other gate in the tree (Track P's F-P2 found one by sweep, and it was a
  regression).

**The non-redundancy protocol, measured again** (`PROTOCOL.md`): **3 full-suite runs for 6 landings**
— the group gate twice (RED, then GREEN after the resolution) and the closing rebuild once — with **0
cited-but-stale gate lines** found, every `cited:` line re-hashed against the binary on disk. Two
corrections it earned: (a) a **measured ERRATUM** — `tests/e2e/CMakeLists.txt` is **not** append-only
at disjoint anchors; it has ONE tail anchor above the mandatory-last `get_property` sweep, every
slice-adding track appends there, and this merge hit two content conflicts in it. The post-union check
is now standard: **0 duplicate `add_test` names, the registration count, sweep still last.** (b) the
**duplicate-body scan** (L8) is worth more when it reads each duplicate's CLAIMED VERDICT off its RUN
lines and flags groups that MIX them — 1994 fixtures, four normalisations, **0 contradictory-verdict
groups**, and all four `git mv`'d fixtures confirmed absent (no resurrection).

**Three items are OPEN WITH THE OWNER and must not be written up as settled:** (a) **F-U1-1** — bd
`z9t1` composes with `LiteralIntegrity` GUARD 1 (`declineUnpairedUndefLiterals`), a *counting* gate
over a population this clause only partially empties, so `double d; d = cq_theta(d,d);` moves from a
loud decline to exit 0 emitting `cqrt_ry_f64(i32 %h, double undef)`; the measurements point away from
restoring the decline (the genuine pairing hazard still fires, the survivor occupies exactly one
slot, the blessed precedent is an ALLOC operand, and a materialized undef is already committed in a
shipped golden — bd `u7z9`), **no conjunct was added**, and the ruling is bd `dnqo`. (b) **F-U3-1**
(bd `fve8`) — the φ clause disarms ruling clause 4 UPSTREAM of the sink: `cq_measure` of an undef
declines by the ruling, but the clause deletes the undef before `MeasureLowering` sees it; 4 of 710
rows, all byte-identical to the written-zero twin, and the DIRECT spelling still declines. (c) the
**X5 re-derivation**, recorded as OWED above.

### 5. Open follow-ons, by bd id

⚠ **bd `3d8q` is CLOSED** (`81c55430`, 2026-09-14 — §4c), and so are the other
five of that session: `z9t1`, `om35`, `3qps`/`4aiu`, `wx8g`, `uq96`. What follows
is what is still open.

**Pre-existing silent miscompiles, still open:** bd `lo7u` (the 4.5 `switch`
mints eq-flags from a MEASURED scrutinee — `Switch*Emit` goes through
`emitEqFlag` with no `CmpInst`, so neither A.1 rung covers it); bd `s82e` (an
in-loop leak of entangled which-path rails that needs **no tainted control flow
at all** — six lines of C with no region, byte-identical on the oracle); bd
`a3z7`, **re-raised to P1** (the rail φ that carries a dtzb-mutated `cq_theta`
result IN PLACE: `readerStalesItself` is a third GRANTING caller of
`phiTracksWire` and the documented dtzb vocabulary gap is live, so two well-formed
C programs one φ operand apart get ONE circuit — `IMPL_D.md` §15.4, with the
red-green pair to write WITH the fix; bd `0njv` is the distinct straight-line
sibling, which the compiler gets RIGHT).

**Over-declines** (defects to remove, per the owner's ruling): bd `35t0` (a 6.5
arm immediately followed by a flat region declines at the `hcrg` precedence graph
— `reorderable()` admits only `BranchRegion`/`PhaseKickback`); bd `52og` (the
in-loop phi PHASE kickback over an OUTSIDE prep declines while the in-loop phi
DATA SELECT over the same prep is a shipped ACCEPT — an asymmetry between two
consumers of one leaf grammar, and it is the shape a **rolled Grover phase
kickback on a bool-controlled prep** takes); bd `onq1` and the three `il*`×`bcar`
twin cells (`MERGE_FILINGS.md` §3) as the residue inside `wx8g`'s capability; bd
`hrts` / bd `l3i1` (the φ-descendant dominance skip is broader than its stated
rationale and has ACYCLIC customers); bd `1ro3`, bd `58tc`, bd `x5fp`, bd `832l`,
bd `hqor`; the `a3` residual of leg 1b (a guard that runs once but **not on the
first trip** — the leg proves "false on every latch arrival", strictly narrower
than "true on at most one iteration", and widening it is an ACCEPT-direction
relaxation needing its own Rule-13 round); `d4_noRailRegion.c` (safe-direction,
with a pre-existing trace divergence on the oracle — a candidate, not a defect);
an in-loop hoisted loop-invariant TEMPLATE rail read by the body's condition
(Q-R1-1, a Prime-Directive decline, not a proof).

**Capabilities filed, not built:** bd `xqgx` (the **A.2** widenings — the S†
after a compare select via the DT prong, the P1 `SawValueArm` retirement under a
live-chain-rail fence = the H-3 ruling, and `AllowLogicalSelect` for data
selects); bd `xdu2` L-1a (the bounded rail ARRAY — the owner's Q2 spelling, still
the loop form's first wall); bd `yiid` (an UNRULED BOUNDARY, L7: `cq_measure` is
not modelled as a wire event at all, so reading a name AFTER measuring it
compiles in every spelling — reading (b) is costed at **2 goldens, 0 shipped
accepts, no ABI, no new symbol** in `IMPL_D.md` §14 and is an **owner decision**);
bd `dnqo` (the F-U1-1 ruling — is an `undef`/`poison` ROTATION ANGLE a loud
decline?); bd `fve8` (the F-U3-1 disposition); bd `l4x4`.a (the Ry-stem angle
select on a `bool`); bd `54ur`, bd `fg9k`, bd `boi6`, bd `r903`; bd `m57l` (the
Rule-18 bound derivation, no customer); the 7.x loop/break widenings under bd
`8h7d`. R-2′ (the rival F2 spelling the owner did **not** take) stays filed with
T1/T2 pinned.

**Owed, and owed as a REVIEW rather than as code:** the **X5 re-derivation** of
`ArmClassify.cpp`'s dominance-skip trigger, whose premise the same merge
falsified (§4c); and a **Rule-13 opinion on the F × P composition** — two accepts
that exist only with both increments present, cleared by measurement and by no
review (`MERGE_FILINGS.md` §1–§2).

**Owner-disposition pending / quarantined divergence:** bd `1m5p` (class A: a
hoisted loop-invariant derived chain whose top rail the ROLLED form leaves
allocated and the flat form discharges) and bd `a3z7` (class B: the M-C
in-place-vs-out-of-place decision on a trailing `a += off`) — **both reproduce
byte-for-byte on the pre-Inc-3 oracle, so they are pre-existing and
arm-class-independent**; ⚠ "pre-existing" is true of the defect and FALSE of its
population — the increment that exposed them **adds customers** to a known
defective path.

**Test debt:** the M-A CTRL-slot pin is lost and currently unpinnable (bd `6uqc`
family); bd `f8eu` (57 missed mutations over 17 fixtures of pre-existing
injection-matrix debt in the drbq Inc-4 state-prep accepts, identical on the
`main` oracle); bd `1yeu` (**a STRUCTURAL instrument gap**: every corpus and gate
in the tree is effectively ONE FUNCTION PER MODULE, so a cross-function defect is
invisible to all of them — two over-ACCEPTs found 2026-09-14 passed 1937 lit
fixtures, 15 e2e entries, a COMPLETE corpus sweep, a 0-MISSED injection matrix
and 328 twin cells for that single reason); bd `gfsk` (the `--regenerate` prose
deletion of L10); bd `gahu` (three `*_reject_*` fixtures are ACCEPTs after bd
`z9t1` — deliberately NOT renamed yet, because a `git mv` can be resurrected by a
merge, L8); bd `21re` (`free_pairing_check.py`'s `provably_not_a_rail` rests on a
premise the `xdu2` rail bank would make false).

---

## Hallucination-Risk Callouts (specific things agents get wrong)

- **`ControlDetection.cpp` / `MergeDissolution.cpp` / `ControlStub.cpp` /
  `NestedRouteEmit.cpp` no longer exist.** The live emitter chain is
  `ControlDetect.cpp` / `ArmClassify.cpp` / `SwapRouteEmit.cpp` /
  `SelectMergeEmit.cpp` / `CondTreeEmit.cpp` / `MergePhiPeel.cpp` /
  `RegionFlatten.cpp`, with `ControlPlan.h` populated. The old controlled-op
  logic is recoverable from git history but is **not** the path forward.
- **The *old* controlled-form "done" Phase 4 is a trap, and so is the swap
  route.** See the Status note at the top: three generations, two retired.
  `SwapRouteEmit.cpp` keeps `emitRoute` only as the 7.2 abort-park's shared
  primitive — its file name is now history.
- **Casts are representation changes, NEVER measurements.** The only path to a
  measurement gate is an explicit `cq_measure(...)`. There is no flag or syntax
  to turn a cast into a measurement (this asymmetry is by design; it is what lets
  plain C functions with hidden internal casts lift to quantum callers).
- **`cqrt_free` is compiler-emitted only**, and freeing an entangled rail is a
  **hidden measurement** that collapses `q` (Rule 6) — not a benign lifetime op.
- **A floating-point merge φ is an angle, not data** (see L9).
- **"No new primitive" holds only for keep-sources-live additive copy.** Freeing
  a superposed source needs `cqrt_cswap` (Rule 8).
- **`cq_phi` has no register operand** and `emitRz` is deleted; `cqrt_rz_<W>` for
  W>1 and `cqrt_rz_<W>_controlled[_inv]` are **declared-but-unemitted**.

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
# MEASURED (bd 8h7d.5): 100% pass on a knowingly broken pass, then 49 reds the
# moment cq-opt was built. Two fix agents and one reviewer hit it.
cmake --build build --target CQPass cq-opt   # if you must name targets, name BOTH

# Full suite — a GATE, not the inner loop (Rule 19). RUN IT PARALLEL.
cmake --build build -j8 && ctest --test-dir build -j6 --output-on-failure

# One layer at a time
ctest --test-dir build -R ir-pass-lit  --output-on-failure   # ONE entry wrapping every ir-pass/test/*.ll (1 XFAIL)
ctest --test-dir build -R frontend-lit --output-on-failure   # 1 entry — CQ.h survives clang -O1 (no plugin)
ctest --test-dir build -j6 -R '^e2e-'  --output-on-failure   # the only layer that LINKS
ctest --test-dir build -R runtime      --output-on-failure   # 7 entries, ~9s — trace goldens, header compile, template drift, link/core-ABI smokes

# One fixture (lit --filter matches the test display name)
cd build && lit -v ir-pass/test --filter 'lowering_basic'

# Run the pass on one .ll by hand (absolute tool path required)
/usr/local/opt/llvm@19/bin/opt -load-pass-plugin build/ir-pass/libCQPass.so \
    -passes=cq-lowering -S ir-pass/test/lowering_basic.ll \
  | /usr/local/opt/llvm@19/bin/FileCheck ir-pass/test/lowering_basic.ll
```

**Counts, measured 2026-09-14 at `66428ddc` (the six landings; re-run by the closing docs pass, not
copied).** ctest **442** · `^e2e-` **432** · `^e2e-slice-` **381** · `twin-identical` **40** · `ls
ir-pass/test/*.ll | wc -l` **1994** · `ls tests/e2e/*.expected.log | wc -l` **383** · twin matrix
`grep -c '^m_' tools/loop_twin_matrix.expected.txt` **309** + `grep -c '^cell '
tools/loop_twin_matrix.quarantine.txt` **29** = **338** cells. Full `ctest -j6` on that tree:
**442/442** in 436.73 s; `cq-opt-equivalence-full`: **1993/0** (measured at the group gate on the
bit-identical binary, over the 1993 fixtures that existed before the resolution's one addition).
(2026-09-13 at `59ac5b7`: 420 · 410 · 365 · 34 · 1928 · 367 · 288; 1928/0. 2026-09-11 at `e96f89c`:
403 · 393 · 353 · 30 · 1893 · 355 · 288; 1893/0.) The twin matrix moved 288 → 338 because bd `uq96`
gave it an `i1` axis. **Re-measure rather than quote** — `ctest --test-dir build -N` and the
`ls`/`grep` lines above are the source of truth, and these go stale on every fixture batch. The
per-commit chain and every earlier figure are in `docs/CLAUDE-HISTORY.md`.

**Timing.** ~**130–230 s** at `-j6` on a **quiet** box (the spread tracks how
warm the stage-1 content-addressed cache is), down from 825 s serial. **Under
concurrent agent load, 250–460 s** — not comparable; budget command timeouts from
the loaded figure and only ever compare two runs taken under the same load. The
long pole is now `e2e-loop-twin-matrix` (~180–400 s, starts first and finishes
last), not `ir-pass-lit` (~35–55 s). `-j6` is the pick: `-j12` oversubscribes (6
physical / 12 logical cores) **and** `ir-pass-lit` already forks 12 lit workers
internally, so `-j6` is ~17-way concurrent already. The suite is embarrassingly
parallel by construction (every slice in its own `mktemp -d`, every fixture on
`%t`, zero `RUN_SERIAL`/`FIXTURES_*`/`RESOURCE_LOCK` in the tree). **Contention
causes false FAILURES, never false passes** — re-run any `-j` failure serially
BEFORE calling it a regression; use `-j1` only to isolate a suspected flake. The
suite got 5× faster by removing process spawns (`-j6`, lit opt-spawn dedup,
python shim bypass, the stage-3 link split — bd `dgn5`), **without deleting a
test or regenerating a golden**.

**Full pipeline for one `.c`** (mirrors `tests/e2e/run_slice.sh`;
`LLVM=/usr/local/opt/llvm@19/bin`):

```bash
"$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S file.c -o /tmp/s1.ll          # 1: frontend
"$LLVM/opt" -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
            -S /tmp/s1.ll -o /tmp/s2.ll                                               # 2: cq-lowering
python3 tools/free_pairing_check.py /tmp/s2.ll                                         # 2b: Rule-6 free pairing
"$LLVM/clang" /tmp/s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o /tmp/a  # 3: link*
/tmp/a                                                                                # 4: run → trace
```

\* **Link order is load-bearing:** `libcq_templates.a` **before**
`libcq_runtime.a` (template `_hl` symbols call `cqrt_*`; single-pass `ld` needs
the caller first). The harness splits stage 3 (bd `dgn5`): CMake derives a linker
wrapper from this same clang via `clang -###`, drops the `-lto_library` that
makes `ld` dlopen libLTO→libLLVM (140 MB) on every `-O0` slice link, and exports
it as `CQ_LD` (0.74–0.94 s → 0.35–0.44 s per slice). It is re-derived on every
reconfigure and fails **loudly** if stale; unset `CQ_LD` ⇒ the plain driver
command, exactly equivalent. The three `ld: warning: object file … built for
newer 'macOS' version` lines are **pre-existing** (CMake builds the archives with
`/usr/bin/cc`, stage 3 uses Homebrew clang 19).

**`%cq-opt` is NOT stock `opt` — it is `build/ir-pass/cq-opt`.** The pass costs
~5 ms while stock `opt` costs 0.238 s of fixed per-spawn cost (dyld-binding 140
MB of `libLLVM.dylib` + static initializers for every target backend); at ~1330
spawns that dominated everything. `cq-opt` (`ir-pass/tools/cq_opt_main.cpp`,
built from the **same** `CQPass` sources so the two cannot drift) links only what
the pass needs: 0.124 s. It accepts and IGNORES `-load-pass-plugin`, so RUN lines
are **byte-identical under either binary**, and it hard-errors on any pipeline
other than `cq-lowering` rather than silently no-op'ing. It is **one process per
invocation**, not a compile server. Equivalence is **gated, not assumed**
(`tools/cq_opt_equivalence.py`: stdout, stderr **and** exit code). The routine
ctest entry samples (`--stride 8`, ~13 s); run the full sweep after any change to
the diagnostic or analysis surface:
`cmake --build build --target cq-opt-equivalence-full`.

> **TRAP, cost one 551-fixture red suite.** `lit.cfg.py` puts the LLVM tools dir
> on `PATH` so the `not` wrapper resolves. That must be derived from **FileCheck**
> (or `config.llvm_tools_dir`), **never** from `dirname(cq_opt)` — `%cq-opt` lives
> in the build tree, which contains no `not`. The failure is vicious rather than
> obvious: `not: command not found` goes down the same `2>&1` pipe the fixture
> FileChecks, so 551 negative fixtures failed on a *missing diagnostic* and read
> exactly like a lowering regression.

**The standalone `opt -passes=verify` RUN line is GONE, and must not come back.**
`opt` already verifies the pass output in-process (`-debug-pass-manager` shows
`cq::CQLoweringPass` → **`VerifierPass`** → `PrintModulePass`, and `opt` exits
non-zero when the verifier fails). What the extra spawn uniquely added was a
print→reparse→re-verify round-trip — a check on LLVM's printer/parser symmetry,
not on CQ lowering — and that is covered end-to-end by every e2e slice, where
stage 3's `clang` reparses the textual IR and fails loudly if it cannot. Net: 451
spawns × 0.345 s ≈ **156 s of CPU** for a structurally redundant check.

**Adding fixtures is nearly free; adding `opt` invocations is not.** `ir-pass-lit`
is SPAWN-bound. Reuse one `%cq-opt … > %t.cqd0.ll` and point every extra
`--check-prefix` at that file; do NOT re-run the pass per prefix.

**Stage 2b — the Rule-6 free-pairing gate (bd `8txa`).** `run_slice.sh` /
`run_slice_multi.sh` run `tools/free_pairing_check.py` on the same lowered IR
they link, because **the golden byte-diff cannot witness "freed at `|0⟩`"** — no
trace label can answer whether a rail was actually `|0⟩` when freed, at any ABI.
The two gates are **complementary**: the trace sees the angles and not the rail
identities; the checker sees the rail identities and not the angles (`cqrt_rz` is
deliberately transparent to it, being diagonal). ⚠ **It is structurally blind to
a leaked TEMPLATE-minted rail** — there is no `cqrt_alloc` to count — and
reported `0 violation(s)` on every circuit in the C-1 leak family; do not cite it
as clearance for that class. Read the file header for exactly what it does and
does not witness. Its own mutant validation is `free_pairing_check_test.py`
(ctest `e2e-free-pairing-selftest`). **Four** `e2e-slice-loop-break*` entries pass
`--allow-unproven` with a written reason (the dtzb whole-loop reverse-play is a
Bennett recompute + a back-edge-crossing write history, neither structurally
provable); **every other slice runs strict, and a new `--allow-unproven` needs a
reason of that kind.** A new `cqrt_*` symbol must be classified in `classify()`
or the checker fails loudly rather than guessing its read/write effects.

There is **no GitHub CI** (no `.github/` exists); all quality gates run locally
through `ctest` plus `gen_templates.py --check` drift verification. Do not add CI.

**Three ctest entries are PURE-PYTHON RECORD gates, not compiler tests, and they
exist because this project's other failure mode is a number that measures the
wrong program** — `keepset_vendor_check.py` (no slice may vendor a software body
for a Rule-18 hardware keep), `slice_census_sync_check.py` (no `slice_libm_real_*`
golden may claim coverage the census does not report), and
`free_pairing_check_test.py`. They run in seconds, need no plugin, and each was
added *after* the defect it catches shipped undetected through a fully green
suite.

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
  `SwitchNormalization`), and **do NOT restore the swap route for an arm class**
  — both generations are retired (see Status and CORRECTNESS RISK). ⚠ The
  `_controlled` template family is **not** a "reserve": its **Ry** half is live
  (the in-place rotation arm), its **copy** half **IS** the value path's merge
  primitive, and its **Rz** half has **no minter at all** — re-enabling
  `cqrt_rz_<W>_controlled` for a phase arm would restore the tensored gate that
  made every Grover golden the identity. What the value path emits is a
  controlled *basis copy* into a fresh `|0⟩` rail, **not** a controlled twin of
  the arm's own gates.
- **Do NOT add quantum arithmetic intrinsics** (`cq_add_qq`, …). Arithmetic is
  stock LLVM opcodes identified by taint.
- **Do NOT make `cq_phi` a taint source**, do not restore a register operand to
  it, and do not reintroduce the retired `cq_phi_<sfx>` family or a multi-bit
  `cqrt_rz_<W>` under control. Only `cq_theta` allocates and creates taint;
  `cq_phi`'s one operand is the ANGLE, and allocating for *that* is the f64/angle
  miscompile family (Rule 3).
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

## Lab report — owner-facing, append-only (owner rule 2026-09-10)

`docs/labreport/` is a pdflatex **lab report**: one entry per working session,
**≤5 pages**, appended at Session Completion, built locally
(`tools/labreport/build.py`; the PDF is gitignored, the sources are committed).
It exists so the owner can read progress and the state of the art without
reading this file's dated history. Its rules, in `docs/labreport/README.md`, are
deliberately few:

- **Non-normative.** An entry records what happened and CITES where rules live
  (this file, `ROADMAP.md`, PRDs, `bd` ids). It never states a rule — this must
  not become a fourth place where agent prose hardens into a ruling (L7).
- **Append-only, mechanically.** A committed entry is sealed by SHA-256 in
  `MANIFEST.sha256`; the build fails if a sealed file changes. Corrections are
  dated ERRATA in a later entry. Figures live in `figures/NNN/` and are sealed
  with entry `NNN`.
- **Measured numbers only, with the command shown** (Rule 19 wording). Figures
  are welcome — from committed data generated by a script under
  `tools/labreport/figures/`, never hand-typed.
- **Not a ctest gate** (TeX is not a suite dependency) and **not a handoff**
  (`HANDOFF_*` / `NEXT_SESSION_PROMPT` stay agent-to-agent; the entry links to
  them).

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Append the lab-report entry** (owner rule 2026-09-10) - copy
   `docs/labreport/TEMPLATE.tex` to
   `docs/labreport/sessions/NNN-YYYY-MM-DD-slug.tex`, write ≤5 pages on THIS
   session, then `tools/labreport/build.py --seal` (it fails on a tampered
   sealed entry or an over-budget one) and commit the sources. Never the PDF.
5. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
6. **Clean up** - Clear stashes, prune remote branches
7. **Verify** - All changes committed AND pushed
8. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
---

## Where Things Live

| Path | Responsibility |
|---|---|
| `ir-pass/src/CQLoweringPass.cpp` | Orchestrator: `propagate → escape/stale guards → peel+detectControl+emit → classical-mux guard → declineRecordedStaleQuantumReaders → lowerRotations → lowerOps → lowerMeasures → uncompute`; passthrough early-out. ⚠ The reader decline sits in that one slot **in both entry points**, and the slot is a contract: it is the last owner to speak, because `LLVMContext::diagnose` EXITS on the first `DS_Error`. ⚠ Control detect+lower runs **twice** (`repropagateControlMerges` fixpoint) — every stage in that window owes the L1 question |
| `ir-pass/src/TaintPropagation.cpp` | Forward taint (seed `@cq_theta`, sink `@cq_measure`, skip arg-1 angle) + collection-time `cq_*` prototype validation + `declineTaintEscapes` + `declineClassicalMuxes` (live select/phi over tainted data; one-register merge-phi lift) + **`adjudicateTaintDelta`** (the guard re-run every taint-GROWTH event owes — bd `b6ap`) |
| `ir-pass/src/RotationLowering.cpp` | `theta → cqrt_alloc_<W> + cqrt_ry_<W>` (the qubit allocation point); RAUW the result to the `i32` handle; the `cqrt_ry_<W>_controlled` mint for in-place arms; **`normalizeUndefRotationSeed`** (bd `z9t1`) — a whole-value `undef`/`poison` SEED at a SOURCE theta, and every same-typed `UndefValue` incoming of every phi that carries that theta, becomes `Constant::getNullValue`, silently (the disclosure is §4c; the `ConstantExpr` residual is excluded by its own conjunct, because the predicate gates a DECLINE everywhere else and a REWRITE here). ⚠ **`emitRz` is DELETED** — `cq_phi` carries no register, so the only Rz the pass emits is the kickback `cqrt_rz_i1(f, θ)` from the CONTROL emitters, and an uncontrolled one is deleted as a global phase. A `@cq_phi_<sfx>` **use** is a reserved-name loud decline. ⚠ `Chained` is decided at FINAL taint — that asymmetry with round-1 fences is L1's PREDICATE species |
| `ir-pass/src/OpcodeLowering.cpp` + `Arith/Compare/Cast` | Tainted `add/mul/icmp/fcmp/cast/fneg → cq_template_*`; up-front cast-width capture before RAUW; `classifyInPlaceReassignment` (M-C) and the `lowerOps` **re-verification** of every pre-loop in-place marking under FINAL taint; `declineStaleRecordOps` (pass-wide: a tainted **pure** op scheduled past a non-diagonal wire gate → loud decline) **+ the READER half, bd `3d8q` (`81c55430`): `recordStaleQuantumReaders` runs as pure ANALYSIS at two slots (beside `declineStaleRecordOps`, and delta-scoped inside `adjudicateTaintDelta` — every taint-GROWTH event owes the L1 question), and `declineRecordedStaleQuantumReaders` is the last slot before `lowerRotations`, a BACKSTOP and never a preemptor.** ⚠ The old note *"pure ops only"* is HISTORY: a `cq_theta` **arg-0** and a `cq_measure` operand are now asked the same question |
| `ir-pass/src/OpcodeSupport.cpp` · `TemplateName.cpp` · `WidthDispatch.cpp` | Supported-set / commutativity / predicate policy · symbol-string grammar · suffix→width + lazy `FunctionCallee` minting |
| `ir-pass/src/MeasureLowering.cpp` | `@cq_measure_<sfx> → cqrt_measure_<W>` |
| `ir-pass/src/ControlDetect.cpp` · `ArmClassify.cpp` · `SwapRouteEmit.cpp` · `SelectMergeEmit.cpp` · `Switch*Emit.cpp` · `RegionFlatten.cpp` · `ClassicalCallArmEmit.cpp` · `include/ControlPlan.h` | The control chain: region detection (declines what it cannot prove) · arm/condition classification, the tainted-angle and stale-condition guards, the §13.3 **rail ladder**, the state-prep fences **F1/F2** — whose TEST carries three exclusions, `CondWire`, `PeelClones` and the 2026-09-14 **φ-DESCENDANT** set (`collectStatePrepPhiDescendants`, bd `om35`) — and the 6.5 `classifyClassicalCallArm` · phase **kickback** emission (flat + depth-2 nest) and value **controlled-copy-merge** emission (`emitValueRegion` hoists the chain, builds a `select`, calls `SelectMergeEmit` verbatim) · the 4.4 select merge · the 4.5 switch shapes · CFG flattening · the populated region plan. ⚠ **`preppedRailPhiRegionIdx` (declared in `SelectClassify.h`) is the ONE spelling of "this φ is a prep region's rail"** — the phase kickback and the data select both CALL it (bd `3qps`/`4aiu`); a second spelling is the drbq Inc-3 (b′) defect. ⚠ **`emitRoute` has exactly ONE call site**, `AbortParkEmit.cpp` (7.2) — the file name `SwapRouteEmit` is history. ⚠ **`emitKickbackGroup` is the ONE spelling of "fire `P(θ)` when `ctl == v`"**: on an ancilla the `cqrt_x` bracket, on a RAIL the diagonal `rz(−θ)` |
| `ir-pass/src/MergePhiPeel.cpp` · `include/MergePhiPeel.h` | **A NORMALISER that runs before detection, not a lowering** (bd `b6ap`). `peelIndependentMergePhis` rewrites every merge phi whose incomings are all pred-available into a `select` with its OWN compare clone, so a fused multi-phi diamond becomes the one-phi shape `soleMergePhi` proves. Called before **EVERY** `detectControlRegions` (3 sites); ≥2-phi entry gate, no in-loop peel, no `undef`, P10 `armWritesMemory` keeps the guarded-store arm declining. ⚠ It **grows the taint set** — that obligation is discharged by `adjudicateTaintDelta`, and a sixth taint-consuming stage added above it and not added there re-opens F-B6-1 with no diagnostic |
| `ir-pass/src/CondTreeEmit.cpp` · `include/CondTreeEmit.h` | The ONE spelling of "turn a condition into a flag" for the phase path: `collectCondTree` (the `and`/`or`/`xor` tree over tainted compare leaves, incl. `select i1` combinators via `AllowLogicalSelect` — admitted for the branch phase, **not** for the 4.4 data select: one grammar, two verdicts) · `emitCondNetwork` (one leaf flag per compare, `cqrt_toffoli` for AND, hands back the ROOT the kickback sits on, torn down LIFO). **RAIL LEAVES** map to themselves (`RootIsRail`; nothing minted, stripped or freed). With `CopyRailRoot=true` a bare rail root gets the **CNOT-copy** ancilla instead of a bracket. ⚠ `Specialization::mintCondNetwork` is a THIRD, forward-only copy with no strip, deliberately not folded in |
| `ir-pass/src/AngleSelectEmit.cpp` | The folded if/else angle select. **Ry stem** by DIFFERENCE (constant arms only, IEEE fence); **Rz stem** a KICKBACK PAIR that performs no subtraction. Do not migrate a fence between the stems. Positional steps, no CFG surgery; every `return` below the first emission is UNREACHABLE and commented as such |
| `ir-pass/src/LoopLowering.cpp` · `include/LoopPlan.h` | Bounded loops (7.3), `break` (7.4), the rolled in-loop control collapse (`collapseRailPhisIn`, `markIfRailLocal`, `invariantRegisterRoots`), the R7-loop **clause (c)** ITERATION-LOCAL rail (bd `wx8g`), `staleRailRecordRead`, `hasFiniteClassicalTripBound`, and the **Q1 quantum-bounded-exit decline** (unconditional; the Rule-18 bound derivation is NOT built) |
| `ir-pass/src/WireWalk.{h,cpp}` | The shared forward/backward wire walks (position-free and position-aware; `provablyBeforePerActivation`, `phiTracksWire`, `findNonDiagonalWireGate`, `collectNonDiagonalWireGates`, `railWireNamesBackward`, `railWireClosure`, and the stale-reader leg `readerStalesItself` behind `RequireEmitDominance`, whose NULL-parameter default is byte-identical to the pre-2026-09-14 behaviour). ⚠ `isPotentiallyReachable(A, B)` in LLVM 19 opens `if (A == B || A->comesBefore(B)) return true;` — so `gateIsHarmless(I, I, …)` is true **by identity** and spelling the leg that way declines 12 shipped cleared ACCEPT fixtures (measured). ⚠ A walker's ANCESTRY rule is a Rule-13 fence in its own right — "same physical rail" must be computed by the relation the **lowering** uses (`Chained`), not by the spelling of the parent |
| `ir-pass/src/Uncomputation.cpp` · `ChainWalk.cpp` · `DagTraversal.cpp` · `FreePoint.cpp` · `EmitInverse.cpp` | The whole-DAG LIFO uncompute spine (runs last): terminal selection · whole-DAG recovery · post-dom free point · reverse-program-order void `_unc` adjoint + `cqrt_free`; compares decline loudly (no `_unc` grid). `ChainWalk` owns the **`!cq.branchphase` MEMBERSHIP record** (`markBranchPhaseGate`/`isBranchPhaseGate`) refused first by `isInPlaceGateOn`, `preservesBasisUnderRecord` and `EmitInverse::isInverseEmittable`, so the spine cannot adjoint the user's answer. ⚠ Asked as membership of the **instruction**, never by name — and `preservesBorrowedParent` clause (1) deliberately still admits the same gate BY NAME, a different and sound question (L3) |
| `ir-pass/src/LiteralIntegrity.cpp` | ONE invariant: an emitted gate's LITERAL operands must denote the source's value, identically at every site the lowering copies them to. `declineUnpairedUndefLiterals` (an `undef`/`poison` literal in two gate slots is read as two values at the `-O0` stage 3, so an adjoint stops inverting its forward) · `declineAddressTakenBlocks` / `removeUnreachableBlocksChecked` at all 7 block-erase sites (`~BasicBlock()` RAUWs a `BlockAddress` module-wide) · the shared `valueCarriesUndef`. ⚠ Neither defect is visible to `opt -verify` **or** to `free_pairing_check.py` — the structure is perfect and only the run-time values differ |
| `runtime/cq_runtime.{h,c}` | Hand-written `cqrt_*` core ABI (trace-only) |
| `runtime/cq_templates.{h,c}` | **Autogenerated** `cq_template_*` bodies — edit `tools/opcode_table.yaml`, not these (Rule 15) |
| `include/CQ.h` | The user-facing surface: 14 types × **2** register-carrying families (`cq_theta`, `cq_measure`) via `_Generic`, **plus the single register-free `void cq_phi(double)`** (no per-type family, no `_Generic` — the two-argument spelling is a hard compile error), + `cq_invert_*` and the `cq_ry` statement macro |
| `tools/free_pairing_check.py` · `tools/free_pairing_check_test.py` | The Rule-6 free-pairing gate over the **lowered IR** (e2e stage 2b — the rail identities the trace loses) · its mutant validation |
| `tools/loop_twin_matrix.py` · `…expected.txt` · `…quarantine.txt` · `angle_select_twin_matrix.py` · `inplace_twin_matrix.py` · `golden_multiset_audit.py` | The rolled-vs-unrolled and twin matrices, the pinned-signature quarantine (+ its selftest), and the golden multiset substitution audit. **Instruments, not ctest gates** except `e2e-loop-twin-matrix` and the quarantine selftest — the rest are pending an owner cost decision (bd `drbq.9`) |
| `tools/library_coverage/…/build_corpus.py` · `tools/slice_census_sync_check.py` · `tools/keepset_vendor_check.py` | The libm-census integrity gates: the corpus recipe as an executable self-checking script (it skips the ten `ld80/` bodies openlibm does not build and verifies every `.bc`'s `source_filename`) · the gate that stops a golden claiming coverage the census does not report · the Rule-18 keep-set vendoring gate. **None is a miscompile gate — all three catch numbers measuring the wrong program** |
| `docs/labreport/` · `tools/labreport/` | The owner-facing append-only lab report + its build/rule checker and figure generators |
| `docs/CLAUDE-HISTORY.md` | **The verbatim archive of this file** as of `571c7cd` (2026-09-13), before the compaction to <150 k characters. Non-normative; read it the way Rule 11 says to read any dated block |

**Docs map:** `ROADMAP.md` (plan of record) · `docs/frontend.md` (intrinsic
surface) · `docs/backend.md` (IR pass + runtime ABI) ·
`docs/quantum-classical-handling.md` (taint as the Q/C boundary; mixed-operand
semantics) · `docs/design/rssa-swap-control/{OVERVIEW,SCOPING,MINT_AT_COMPARE}.md`
(the control design + its one-off oracles) · `docs/llvm-implementation.md`
(stock LLVM-19 C++ APIs) · `docs/prd/` (per-phase PRDs) ·
`docs/archive/old-design/` (retired design — reference only).

**For control flow specifically**, the per-increment record of record is
`docs/prd/phase-04-swap-route-control/`: `retire-swap-route-PRD.md` (owner
decisions D1–D7, accept rows P1–P7, §0 E1–E16), `control-in-place-PRD.md`
(drbq §4/§12/§13/§14 — the in-place arm, the angle select, the in-loop arm, state
prep + F2), the `*_NOTES.md` files (the adversarial rounds, the stage table,
the findings ledgers) and `inc1-records/session-*/` (the per-session briefs,
implementation notes, review verdicts and clearance records).
