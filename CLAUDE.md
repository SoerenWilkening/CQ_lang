# CQ_lang — Operating Manual for AI Agents

CQ is a small extension of C for writing quantum programs: no `quantum` keyword, no
special type. A value becomes quantum by passing through a `cq_*` primitive, and an
out-of-tree **LLVM 19** pass (`cq-lowering`) propagates that **taint** forward and lowers
tainted opcodes to reversible runtime-template calls. Stock `clang -O1` compiles the
source; one `opt` pass does the rest.

**Read [`NORTHSTAR.md`](NORTHSTAR.md) first.** It holds the three goals and the ten design
principles, and it wins over anything below, in any comment, or in any bd memory.
This file is *how to work*. The previous 150 KB manual, the roadmap and the per-phase
records are in git at tag `pre-northstar` (`git show pre-northstar:CLAUDE.md`). Code
comments and fixture headers that cite "CLAUDE.md Rule N", "L10", "§4x" or `docs/prd/…`
mean that file (likewise `docs/design/rssa-swap-control/`, `docs/rationale/`, `docs/archive/`,
`ROADMAP.md`). They are history, not rules. The same holds for a bd memory key cited in a
comment or fixture that `bd memories` no longer lists: the 2026-10-03 consolidation retired
it (521 memories to 134). Read the old text from Dolt history with
`cd .beads/embeddeddolt/test_C_libtooling && dolt sql -r csv -q "select value from config as of 'vlca8sj02jpgil1i0ntj8vhnbhmd197d' where config.key='kv.memory.<key>'"`.
A comment or fixture header that spells `x = cq_phi(x, θ)` (or `%r = cq_phi(%x, ·)`)
describes the retired pre-`3qlq` register form and is history too; the fixture's `3qlq:`
note records how its IR was migrated (bd `v7oh`).

## The defining hazard

The **verify-clean silent miscompile**: a lowering that passes `opt -verify` and even
prints a plausible trace, yet computes the wrong unitary, drops a `phi` edge, fires a gate
on the wrong branch, or collapses a qubit by freeing an entangled rail. `opt -verify`
proves the IR is well typed, never that the unitary is right. Everything below exists
to prevent that one class of bug **without** buying safety by declining valid programs.

## Rules

**R1 — Build the intent; a decline is not an answer.** Per NORTHSTAR goal 1, the only
valid decline is a physics-forbidden program. A shape the compiler does not lower is a
compiler bug: implement it. When an implementation is genuinely hard or ambiguous, stop
and bring the question to the owner. Do not ship a decline-only stub and call it done.
An over-decline is a defect to remove, never a free safety margin. Until the lowering
exists the compiler still fails **loudly** (`DiagnosticInfoUnsupported`, `!dbg`-located,
`opt` exits non-zero, nothing lowered) and files a bd bug. It must never guess. A tainted
`br`/`select`/`switch` is never passed to the backend as classical control over quantum
state: the control emitter lowers it or the pass fails loudly.

**R2 — Verify-clean is necessary, never sufficient.** Correctness comes from analytic
or trace reasoning, the golden e2e trace diff (the only layer that links and proves
every emitted symbol resolves), and independent adversarial review. No simulator
(owner decision 2026-06-10). "Passes `opt -verify`" and "runs without crashing" are not
evidence.

**R3 — Taint is the only Q/C boundary.**
- `cq_theta` (Ry) is the sole taint source, `cq_measure` the sole sink.
- `cq_phi(θ)` is **register-free**: a branch phase with no data operand. It neither
  introduces nor propagates taint. Under a tainted condition it lowers by kickback onto
  the condition flag; uncontrolled it is a global phase and is deleted. The old
  `cq_phi_<sfx>(x, φ)` family is retired, and a use of it is a loud reserved-name error.
- **The angle operand of a rotation is classical today** (arg 1 of `cq_theta`, arg 0 of
  `cq_phi`): taint does not flow through it, and a quantum-derived angle fails loudly.
  Per NORTHSTAR goal 1 that is a **gap**, not a design limit: a quantum-valued angle must
  compile, as an angle register driving a bit-controlled rotation ladder (bd `94ad`).
  Until that lowering exists, do not
  "fix" a quantum angle ad hoc by allocating a qubit for the f64 or propagating taint
  through it. That is the f64/angle miscompile family. Integer and floating-point
  merge values can carry quantum data. Determine angle use from rotation-angle
  consumers through the shared taint and carrier checks.
- Casts are representation changes, never measurements.

**R4 — No fork, no rewriter, no new intrinsics.** Stock LLVM 19, out-of-tree MODULE
plugin, new pass manager, frontend is `include/CQ.h` only. No quantum arithmetic
intrinsics (`cq_add_qq`…): stock opcodes on tainted operands lower to templates. The
retired libtooling/`quantum`-keyword/cast-as-measurement design (`archive/`) is never
revived. No MLIR dialect. No GitHub CI. Never use `-O0` (mem2reg/SROA must have run).
`-O1` is the validated floor. `-O2`/`-O3` break taint signatures and are regression-matrix only.

**R5 — Coherent-first; never insert a measurement.** The compiler never emits a
measurement the user did not write. `cqrt_free` is compiler-emitted only and is a
hardware reset (a projective measurement), so free **only a provably-`|0⟩` rail**.
A rail not provably `|0⟩` is left allocated (a leak we accept), never freed dirty.
Never free a handle that escaped (`ret`, `cq_invert_*`) or was measured. Route every
free through the `FreePoint` post-dominator discipline.

**R6 — Method matches arm class.**
- **Phase arms** (`cq_phi`) put the answer on the FLAG: the register-free kickback
  `cqrt_rz_i1(f, θ)`, uncontrolled, `cqrt_x`-bracketed for a ¬flag arm on an ancilla,
  then the `_unc` strip and one `cqrt_free`.
- **Value/permutation arms** hoist the arm's pure chain into the pred, build a `select`,
  and go through the **controlled-copy merge** (`SelectMergeEmit`): two X-bracketed
  `cqrt_copy_<W>_controlled` into a fresh `|0⟩` rail, the chain's `_unc`, the compare
  strip and one free.
- **In-place controlled Ry arms and state prep** use `cqrt_ry_<W>_controlled`, and the
  rotated register is then frozen (never reverse-played, never freed).
- **Never merge a phase arm by a basis copy.** A CNOT copies a label, not a phase.
- **Nothing non-diagonal ever fires on a user register under control.** A negated
  controlled Ry is `ry(h,θ); ry_controlled(h_b,h,−θ)`, and a ¬rail Rz is the diagonal
  `rz(−θ)`.
- Do **not** restore the swap route, the tensored per-qubit `cqrt_rz_<W>` phase arm,
  or `cqrt_rz_<W>_controlled`. Every shipped Grover golden was the identity under that
  mechanism. `cqrt_cswap` has exactly one minter, the 7.2 `AbortParkEmit`.

**R7 — No-cloning / linearity.** Copy + uncompute cannot disentangle a superposition;
freeing a superposed source needs `cqrt_cswap`. Whole-chain reversal needs linear
lineage: bail on fan-out (>1 forward consumer on a non-terminal handle) or you
double-uncompute. A permutation that leaves a rail dirty and entangled still dephases
under later interference.

**R8 — Stock LLVM IR is not stable.** Never assume formatting, order, naming or branch
polarity. `-O1` swaps successors, sinks and hoists ops, fuses regions with equivalent
conditions, folds if/else over one register into a `select` on the angle, const-folds
equality edges, rewrites compares sideways and downward, LICM-hoists invariant compares,
and closes affine recurrences. Detection is pure analysis by SSA-value identity before
any mutation. Never cache block pointers across erasures. Extract and read the actual
lowered IR before implementing.

**R9 — Skepticism.** All bugs are deep and interlocked, and a fix that passes one test
but violates an invariant elsewhere is not a fix. Verify subagent output, prior sessions
(against `git log`) and **bd memories** (true when written; a named file or flag may be
gone). The adversarial probe family finds the miscompiles; the positive suite has never
found one. Fix a wrong comment in the same change that corrects it in a record.

**R10 — Every accept-predicate ships a decline fixture and an adversarial probe.**
Red-green: write the lit fixture first (positive `CHECK` plus a negative `RUN: not …`
mirroring the diagnostic character-for-character), watch it fail, implement minimally.
Fixture-hygiene traps that each shipped through a green suite:
- a positive `CHECK-COUNT` inside a negative prefix windows every negative after it;
- a decline fixture's stdout `CHECK-NOT`s are vacuous, since the property is the `not` inversion;
- a fixture whose subject no longer exists pins nothing.

Validate by mutation and record the MISSED count. Regenerate baselines deliberately, never by reflex.
When a twin-matrix cell changes from decline to accept, keep the gate red until the
new acceptance's semantic evidence is reviewed. Update the expectation in the same
reviewed capability change; the historical decline is not a permanent restriction.
Twin disagreement remains a failure to investigate.

**R11 — Core lowering changes get adversarial review, not just green tests.** Core =
`TaintPropagation`, the control emitters, `FreePoint`, `EmitInverse`, `ChainWalk`,
`Uncomputation`, `RotationLowering`, `MergePhiPeel`, the condition-wire fences. Before
merging, clear the change through independent reviewers who use analytic or trace-level
reasoning. The review has two rounds (owner ruling 2026-10-13, bd memory
`owner-ruling-r11-wide-then-narrow-2026-10-13`):

- **Round 1 is wide.** Two or three reviewers work in parallel over the WHOLE change,
  each with a disjoint set of hypotheses and at most six probes. Every finding names
  the invariant it breaks. The fix restores that invariant, typically with a
  final-outcome gate-set check (L3), and never patches the one probe.
- **Round 2 is narrow.** One reviewer reads the fix delta only. Stop when it is clean;
  otherwise repeat round 2 on the new delta.

A non-core change gets round 1 with one reviewer.

Why two rounds and not one: fixes introduce bugs. In one core function, 2 of 8
findings came from fixes. Why not more: batch 052's `p3kd.13` took ten delta-only rounds
because each fix patched one path of a single hole class and each round saw only its own
delta; a round-8 hole had existed since round 5. A green suite alone never clears a core
change.

**R12 — Reuse before reinvention.** Check `OpcodeSupport`/`ArithLowering`/`CompareLowering`/
`CastLowering`, the `EmitInverse` adjoint spine, the uncompute spine
(`ChainWalk`/`FreePoint`/`Uncomputation`), `CondTreeEmit`, `SelectMergeEmit` and the
`cqrt_cswap`/`cqrt_toffoli` primitives before writing a new handler. Ask a question by
calling the one owning predicate, never by re-deriving its answer. A second spelling of a
predicate is a defect.

Before designing a lowering, consult both implementation ground truths:
[Bennett.jl](https://github.com/tobiasosborne/Bennett.jl) and
[BennettVM.jl](https://github.com/tobiasosborne/BennettVM.jl). Check the current source
and adversarial tests, record each checkout's revision, and cite the matching mechanism
in the bd issue/design. BennettVM's CFG/SSA transfers, loop structure, call/aggregate
ABI and memory models inform precise compilation; translate them into CQ's compile-time
gate and adjoint emission. Consult Bennett.jl for the corresponding circuit construction.
Reference limitations never justify a physics decline, and a successful classical
round-trip alone never proves CQ's unitary. The source/test map and evidence limits are
in [reversible-lowering-ground-truth.md](docs/design/reversible-lowering-ground-truth.md).

**R13 — Width-only ABI; edit the YAML.** `tools/opcode_table.yaml` →
`tools/gen_templates.py` → `runtime/cq_templates.{h,c}` (SHA-256 drift check
`gen_templates.py --check`). Never edit the generated files. Signedness lives in the
opcode and the pass strips it. A runtime handle is always `i32`, and a classical
operand in a mixed Q+C op is passed as a literal to the `_hl`/`_lh` template, never
`cqrt_alloc`'d.

**R14 — Inject library source; justify every directly lowered primitive.**
Library coverage means compiling the real implementation as injected source:
`cqc` llvm-links the openlibm bundle before `cq-lowering`, and the pass binds a
quantum call to that body and lifts it (no inlining).

**"Hand-written" means a backend circuit, never CQ-written C** (owner, 2026-10-06).
A hand-written function lowers to ONE call, `cq_template_<fn>_<W>` plus its `_unc`,
and a circuit backend supplies the reversible circuit. Bennett.jl's implementation is
the circuit reference; BennettVM.jl complements it for lowering semantics and ABI
reconciliation. Both are consulted as source and tests, never linked. The lowered IR
shows that single call, not the function's arithmetic. CQ never writes its own C or IR
version of a library function
to stand in for the real source. The retired CQ-provided component
(`tools/library_coverage/branchless/`, bd `guwr`) did exactly that and was removed by
bd `3c6m.78`.

Direct intrinsic/opcode lowering requires an approved plausible hardware route with
no intrinsic implementation source to inject, or a reversible implementation provided
by Bennett.jl. Record the operation, widths and numerical contract; an LLVM name or
trace-template ABI entry alone never qualifies. When that route is absent, lift the
available source. Missing lowering fails loudly as a compiler gap under R1; it is
never a permanent physics decline or a covered cell.

Native `frem` had only trace templates and no Bennett.jl implementation;
it now fails loudly. Exact `fmod` source-lowering remains bd `3c6m.68`.
Absence from Bennett.jl cannot forbid a valid program: build the source-lifting route.
This differs from accepting an unsupported opaque primitive.

Publish source-injected and eligible intrinsic-lowered components separately,
following NORTHSTAR goal 2's runtime operands and every C/Q mixture. Direct routes
today: the hardware keep-set and `double` sin/cos/tan/asin/acos/atan (bd `3c6m.71`,
contracts in `tools/intrinsic_table.yaml`; `lrint`/`llrint` in `tools/libm_table.yaml`). The `cqc` bundle forwards those names to
their intrinsics, so a lifted body's own `sin` call takes the same route. `float` and
`long double` trig have no route yet (bd `3c6m.79`).
Counts come from census tooling, never hand-copied. Pipeline success does not certify
primitive eligibility, numerical accuracy or a correct unitary.

**R15 — Run what can witness the change** (owner ruling 2026-08-13, revised 2026-09-30).

| you edited | run | cost |
|---|---|---|
| one `.ll` fixture | `cd build && lit ir-pass/test --filter '<name>'` | ~1.5 s |
| one e2e slice or golden | `ctest --test-dir build -R '^e2e-slice-<name>$'` | ~2 s |
| `tools/opcode_table.yaml`, `runtime/*` | `ctest --test-dir build -R runtime -j6` + an e2e slice | ~5 s |
| `include/CQ.h` | `ctest --test-dir build -R frontend-lit` + e2e | ~5 s |
| pass source | the fixtures that pin the changed code, by name (`lit --filter`) | seconds |
| docs / comments only | nothing | |

**Test budget: a hard limit** (owner ruling 2026-10-01). Each bd issue gets at most
**three** lit/ctest invocations, and each one names its fixtures or slices:
1. **red**: the new fixtures only, once, before the fix;
2. **green**: the new fixtures plus the existing fixtures and slices the change can plausibly
   alter, once, after the fix;
3. **final**: once before the commit, and only if code changed since green.

Mutation validation adds one no-op mutant and at most **three** real mutants. Each mutant
runs only the fixture written to kill it. Between checkpoints, run no lit or ctest: run `cq-opt` once on one probe
and read the IR. Never re-run a passing set to confirm. Never run `ir-pass-lit` or a
label tier while iterating. Keep probe matrices to the shapes that test a stated
hypothesis. Reviewers re-run none of the implementer's tests (no suites, no fixtures, no
corpus re-lowering). Each reviewer in a round runs at most six targeted probes on the
highest-risk hypotheses in its own disjoint set and reports findings first (R11). Report the invocation count. Exceeding the budget
needs the owner's approval. A coordinator assigns each parallel unit a disjoint
fixture/slice set and runs the one batch gate below.

Branches never run the full suite; they run what witnesses the change. Merges to `main`
run at most the fast tier `ctest --test-dir build -LE heavy -j6`. **Once per batch** (normally
before `git push`) the **batch gate** runs `ctest --test-dir build -LE maintenance -j6` +
`cq-opt-equivalence-full` + `python3 tools/update_code_map.py --check`. It is mandatory whenever
the batch touches the lowering core, any code/fixture/golden/harness (`run_slice*.sh`, any
`CMakeLists.txt`, `lit.cfg.py`, `cq-opt`), regenerated templates, or an accept/decline predicate.
The `maintenance` label contains the exhaustive `taintset-scrub-guard-selftest` mutant
shards. Run `ctest --test-dir build -L maintenance -j6` when editing
`tools/taintset_scrub_guard.py`, `ir-pass/include/TaintPropagation.h`,
`ir-pass/include/ScrubOnDelete.h`, types reachable from `TaintSet`,
`ir-pass/tools/cq_scrub_selftest.cpp`, or their compiler flags / include configuration.
The ordinary scrub guard and executable scrub tests stay in the routine gates.
`ctest --test-dir build -j6` remains the explicit full audit.
A batch containing only test pruning or test scheduling changes uses the affected
fixtures and registration checks; it does not trigger a compiler-wide batch run.
If a gate fails, bisect over the batch's merges. **Report only what you ran** ("lit green
(N)", never "tests pass"), and say when a gate sampled. Never relink a binary under a running
measurement, and never `pkill` by pattern. Contention causes false failures, never false
passes, so re-run a `-j` red serially before calling it a regression.

**R16 — Scope of the semantic model.** `fenv` (FP exception flags) is out of the model.
A `volatile` access to an object nothing outside the program can reach is not observable
(function-local or internal linkage, never written, address never escapes, no atomic
access, no section, address space 0), so a quantum branch whose only content is such a
read is a no-op. MMIO, external linkage, escaping addresses and atomics stay loud.

**R17 — Instruments earn their keep by being attacked.** A checker's failure mode is
to report a pass. Seven measured instances: a vacuity checker printing `checked 0`, a
matrix printing `0 mutations, MISSED 0`, a harness running a weaker command than lit,
`rc=$?` capturing `grep`'s status, a 0-byte `.ll` that ACCEPTS. Before trusting a gate,
make it fail on purpose: run a no-op mutant and a null-tag control before the first real
measurement. A gate expected to be red is a gate people stop reading.

**R18 — Institutional memory.** Durable knowledge goes in `bd remember` (`bd memories
<keyword>`), design-of-record in `docs/`. Do not use TodoWrite, markdown TODOs or
`MEMORY.md`. Every LLVM-19 quirk and silent-miscompile root cause gets written down.
A ruling is only as good as the summary it was granted on: bring the measured
counter-example to the owner with the question. Agent-authored justifications harden into
rulings if nobody rules, so take a load-bearing unruled bound to the owner.

## Standing lessons for control-flow work

Tainted `br`/`select`/`switch` has produced every verify-clean silent miscompile in this
project. Read `git show pre-northstar:CLAUDE.md` (CORRECTNESS RISK, §1–§3) before
touching it.

- **L1 — A stage that runs once has a round-2-false premise.** Control detection and
  lowering run **twice** (`repropagateControlMerges`). Anything computed between the
  rounds over "taint is settled" is wrong for values derived from a control-merge `%out`.
  Cure: RECORD the question at the site that asks it and RE-ASK it after the round-2
  fixpoint in **both** entry points. Every emission site must record (a seventh emitter
  that forgets re-opens the window silently).
- **L2 — When you widen a set, ask what other set was computed over the same closure**
  (gate set vs record set vs skip set). **When you narrow one, ask what other predicate
  names the same gate**, and remember the answer is not always "narrow it too".
- **L3 — A wire question is a gate SET, not a boolean over a return-first walker.**
  Enumerate, take the difference, carry the exemption per entry.
- **L4 — A syntactic answer to a semantic question loses.** Enumerating `-O1` rewrites
  lost four rounds running. Ask the question with LLVM's own machinery.
- **L5 — Before declining a shape, ask whether you protect the unitary or the emitter's
  bookkeeping.** Only a unitary hazard justifies a loud failure, and then only until the
  lowering is built.
- **L6 — When you replace a structural containment with predicates, enumerate what the
  structure was holding.** (A vanishing `cq_phi` was hoisted and deleted; a user's
  `cq_theta` was erased by a sibling eraser.)
- **L7 — Write retirement triggers into fixture headers and source comments; they work.**
  After a merge, scan for duplicate fixture bodies (a `git mv` can be resurrected).
- **L8 — A composition is not cleared by clearing its parts.** Build the composed binary
  and probe it. `shasum -a 256 build/ir-pass/cq-opt` before believing a decline you see
  by hand, since a stale build looks like a regression.
- **L9 — "Pre-existing" is true of a defect and false of its population.** A landing that
  adds customers to a known-bad path owes that disclosure.

**Known open silent miscompiles — count them, never claim zero:** tracked in bd umbrella
`r2j3` section A (consolidated 2026-10-01; each original ID stays readable with `bd show`):
`lo7u` (4.5 `switch` eq-flags from a measured scrutinee), `s82e` (in-loop leak of entangled
which-path rails), `a3z7` (a dtzb-mutated `cq_theta` result carried through a rail φ),
`yiid` (reading a name after measuring it), `4e4p` (function-pointer `cq_theta` drops
`nomerge`), `uw5u` (`int m=(t==s)?t:s; cq_theta(&m, θ)` folds), `9oob` (a user `__cq_q_*_unc` twin
with a wrong body is trusted), the twin half of `kyy1`, `jlf8`, `yldg`,
`r2j3.7` (a dead tainted pure op is never uncomputed, a live copy of its source; filed
2026-10-01), `r2j3.37` (a lifted call `x = f(x, y)` keeps the old `x` rail beside the result: the
clone path never lowers a quantum-quantum op in place; filed 2026-10-15). `r2j3.32` (a straight-line
4.4 select merge `%out` never uncomputed) and `r2j3.33` (an out-of-place `t ^= a` keeping the old `t`
rail) were fixed 2026-10-16 (batch 054); `r2j3.36` (the carried-merge fence ignored in-loop gates)
was fixed the same batch. Latent, masked by a loud decline (batch 054): `r2j3.38` (an M-C
classical-immediate in-place gate converting while a 4.4 merge copy of the parent stands),
`r2j3.39` (`bracketQramIndexCasts` hides a stale QRAM `_unc` from the in-place QQ postcondition).
Not silent but noted: the post-loop reverse loop `8h7d.20` (rolled loops leave loop-carried merge
rails allocated; quarantined twin cells RB-A). The three uncompute-frontier holes `r2j3.21`, `r2j3.23`, `r2j3.24` were closed
2026-10-14 (batch 053, 04e4f09f): a cut record is reversed or the pass fails loudly, asked per
(record, move) by `isHazardousCutRecord`; `r2j3.23`'s QROM-load shapes are loud, not yet lowered
(`r2j3.27`). Warned rather than silent (owner ruling `lyyf`): `r2j3.8` (a reversed QRAM
call's computed index stays live until its `_unc`; deferred by the owner). Latent, masked by
a loud decline today: `r2j3.9` (`GuardedStoreArmEmit` never discharges a hoisted tainted-arm
value chain). Dirty-rail leak (r2j3 section B): `iwr7` (a dead `cq_template_zext` beside a
QRAM load of the same index is never uncomputed; 10 libm goldens) and `r2j3.16` (an in-arm
tainted select's `%out` rail and its operand chain stay dirty after a guarded store, reachable
from C; filed 2026-10-05) and `r2j3.40` (a dm7f.54 angle-select condition chain, e.g. reporter's
`t4.c`, is never uncomputed when its counter is measured later; filed 2026-10-15). Suspected, unprobed: `r2j3.17` (planTerminalReversal's silent
leak returns may dephase a parent rotated later). Latent, not yet built
from C (section D): `hp0x` (the 6.5 classical-call argument clause keys on `noundef` alone,
so a `dereferenceable` parameter without `noundef` is hoisted with poison). `r2j3.22` (a forged
`!cq.specsafe.twin` tag) and the instrument gap `r2j3.4` (stage 2b certified a phase inside a
superposing restore window) were fixed 2026-10-14 (batch 053).
`r2j3.1`–`r2j3.3` and `r2j3.5` were fixed 2026-10-01 (lab report 035); `r2j3.19` (a nested
lift's control chain read an inner clone's classical result as a qubit handle, found by the
2026-10-08 review) and `etj3` (narrow runtime arguments passed without `signext`/`zeroext`,
`r2j3.20`) were fixed 2026-10-08. `r2j3.6` (a lifted call reads a stale tainted argument:
`int q2=q; cq_theta(&q2,.3); f(q)`, every `cqc`-lifted math.h call included) was closed
2026-10-13: a movable read is placed before its gate in the same block, and every other
stale lifted-call read fails loudly (follow-ups `57ch.1`–`57ch.7`).
`cfmv` (a user `cq_theta` erased by a residue simplifier) was closed 2026-09-18 with no
recorded reason: re-verify before trusting it. Over-declines to remove are tracked in the
goal-1 umbrellas `dm7f` (control flow), `8h7d` (loops), `p3kd` (function lifting) and
`01po` (memory and data types).

## Pipeline

```
 plain C + CQ.h
      │  clang -O1  (stock; intrinsics survive as @cq_* calls on plain SSA)
      ▼
 LLVM 19 IR ──► opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering
      │            ├─ propagate()        forward taint (@cq_theta source · @cq_measure sink)
      │            ├─ guards             taint-escape · stale-record · classical-mux → loud failure
      │            ├─ detectControl()    peel merge φs → claim region → emit (else loud failure)
      │            ├─ lowerRotations()   theta → cqrt_alloc_<W> + cqrt_ry_<W>
      │            ├─ lowerOps()         tainted add/mul/icmp/cast → cq_template_*[_hl|_lh]
      │            ├─ lowerMeasures()    cq_measure → cqrt_measure_<W>
      │            └─ uncompute()        whole-DAG LIFO adjoint (void _unc) + cqrt_free   (runs LAST)
      ▼
 lowered IR (only cqrt_* and cq_template_* externs) → link (libcq_templates.a BEFORE libcq_runtime.a)
      ▼
 executable → one trace line per gate → byte-diff vs golden .expected.log
```

`CQLoweringPass::run` (`ir-pass/src/CQLoweringPass.cpp`) orchestrates; a module with no
theta/phi/measure passes through byte-identical. The runtime is trace-only (each
`cqrt_*`/`cq_template_*` prints `symbol(args) -> ret`; `measure` returns 0).
`RegionFlatten` erases the CFG diamond after emission.

**What lowers under tainted control today.**
- Phase arms (flat, if/else, folded angle select, condition tree, depth-2 nest, `switch`,
  rolled in a bounded loop) lower by kickback.
- Value/permutation arms lower by controlled-copy merge; the 4.4 tainted-condition
  integer/scalar-fp `select` and the 4.5 `switch` (homogeneous phase, homogeneous value /
  all-const data-mux, eq-folded diamond) do too.
- In-place controlled Ry arms and controlled state prep lower via `cqrt_ry_<W>_controlled`.
- Loop-carried handle variables, iteration-local rails and bare `_Bool` rail conditions
  lower, including rolled inside classically-bounded loops.
- A classical cone in a value arm and a classical call under quantum control are hoisted
  into the pred.
- Sequential flat regions are ordered by a precedence graph.

**The fences that decide what is not lowered yet** (each is a gap to close per R1, not a
design limit; details in the tagged manual): condition-wire disposition (`2c condition
predates a non-diagonal gate`), the state-prep fences F1/F2, the stale-reader and stale-rail
fences, in-place reassignment (M-C), loop scope (multi-exit, nested, irreducible), the
`switch` off-pattern matrix, and the remaining `bare i1 register condition` consumers.

## Build & test

LLVM 19 is mandatory. `opt`/`clang`/`FileCheck` are **not on `PATH`** on this machine: they
live in `/usr/local/opt/llvm@19/bin` (the harnesses bake absolute paths in). Only `lit` is on `PATH`.

```bash
cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release   # once
cmake --build build -j8
# NEVER `--target CQPass` alone: `%cq-opt` (build/ir-pass/cq-opt) is a separate target from the same sources and
# every lit RUN line uses it, so a CQPass-only rebuild leaves lit on a STALE binary and reports FALSE GREEN.
cmake --build build --target CQPass cq-opt cq-opt-debugalloc cq-scrub-selftest cq-merge-selftest   # if you name targets, name all five
ctest --test-dir build -R ir-pass-lit  --output-on-failure    # one entry wrapping every ir-pass/test/*.ll
ctest --test-dir build -R frontend-lit --output-on-failure    # CQ.h survives clang -O1 (no plugin)
ctest --test-dir build -j6 -R '^e2e-' --output-on-failure     # the only layer that LINKS
ctest --test-dir build -R runtime      --output-on-failure    # trace goldens, header compile, template drift
```

Full pipeline for one `.c` (mirrors `tests/e2e/run_slice.sh`; `LLVM=/usr/local/opt/llvm@19/bin`):

```bash
"$LLVM/clang" -Iinclude -include CQ.h -O1 -emit-llvm -S file.c -o /tmp/s1.ll                    # 1 frontend
"$LLVM/opt" -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S /tmp/s1.ll -o /tmp/s2.ll   # 2 lowering
python3 tools/free_pairing_check.py /tmp/s2.ll                                                    # 2b Rule-5 free pairing
"$LLVM/clang" /tmp/s2.ll build/runtime/libcq_templates.a build/runtime/libcq_runtime.a -o /tmp/a  # 3 link (order is load-bearing)
/tmp/a                                                                                            # 4 trace
```

- **`%cq-opt` is not stock `opt`.** It is `build/ir-pass/cq-opt`, built from the same
  `CQPass` sources, 0.12 s per spawn vs 0.24 s for stock `opt`. It ignores
  `-load-pass-plugin` and hard-errors on any pipeline other than `cq-lowering`. Equivalence
  is gated by `tools/cq_opt_equivalence.py`.
- **Trap: `lit.cfg.py` must put the LLVM tools dir on `PATH` from FileCheck's directory,**
  never from `dirname(cq_opt)`. Otherwise `not: command not found` flows down the same
  `2>&1` pipe the fixture FileChecks, and 551 negative fixtures fail on a missing
  diagnostic and read like a lowering regression.
- The standalone `opt -passes=verify` RUN line is gone and must not return (`opt` verifies
  in-process; every e2e slice re-parses the IR). Adding fixtures is nearly free, adding
  `opt` invocations is not: reuse one `%cq-opt … > %t.ll` and point extra `--check-prefix`
  at it.
- **Stage 2b (`tools/free_pairing_check.py`)** witnesses Rule-5 rail pairing, which the
  golden byte-diff cannot see. It is blind to a leaked *template-minted* rail (no
  `cqrt_alloc` to count); its CENSUS line reports those, a number to read, not a gate.
  Its mutant validation is `free_pairing_check_test.py`. A new `cqrt_*` symbol must be
  classified in `classify()`. Any `--allow-unproven` needs a written reason.
- **Stage cache** (`tools/cq_stage_cache.py`): stages 1, 2b, 3, 4 are content-addressed;
  stage 2 and every comparison always run. `CQ_E2E_NO_CACHE=1` disables it. After a
  Xcode/CLT/macOS update reconfigure or run uncached.
- Link stage: CMake derives a linker wrapper (`CQ_LD`) from `clang -###`; it is re-derived on
  reconfigure and fails loudly if stale. The three `object file … built for newer 'macOS'`
  warnings are pre-existing.
- **Counts are never quoted from a document.** Measure them (`ctest -N | tail -1`,
  `ls ir-pass/test/*.ll | wc -l`, `ls tests/e2e/*.expected.log | wc -l`).
- Three pure-Python record gates catch a number measuring the wrong program:
  `keepset_vendor_check.py`, `slice_census_sync_check.py`, `free_pairing_check_test.py`.
- Before locating a function with `rg`/`grep`, consult `CODE_MAP.md`; regenerate it with
  `python3 tools/update_code_map.py` after adding, moving or deleting a function. Keep
  maintained code files ≤ 400 physical lines.

## Where things live

| Path | Responsibility |
|---|---|
| `include/CQ.h` | The whole user surface: in-place `cq_theta(&x, θ)` (a void macro, `_Generic` on the pointer type; no value form, bd `1501`), `cq_measure` (`_Generic` over the 15 C scalar types, plus `long double` on x86-64), register-free `void cq_phi(double)`, `cq_invert_*`. Every `cq_theta_*` is `nomerge`. |
| `ir-pass/src/CQLoweringPass.cpp` | Orchestrator and passthrough early-out. |
| `TaintPropagation.cpp` | Forward taint, prototype validation, `declineTaintEscapes`, `declineClassicalMuxes`, `adjudicateTaintDelta` (run on every taint-growth event). |
| `RotationLowering.cpp` | `theta → cqrt_alloc_<W> + cqrt_ry_<W>`, the in-place `_controlled` mint, `normalizeUndefRotationSeed`. |
| `OpcodeLowering.cpp` + `Arith/Compare/Cast`, `OpcodeSupport`, `TemplateName`, `WidthDispatch` | Tainted opcodes → `cq_template_*`; in-place reassignment (M-C); stale-record/stale-reader guards. |
| `ControlDetect` · `ArmClassify` · `SwapRouteEmit` · `SelectMergeEmit` · `CondTreeEmit` · `Switch*Emit` · `AngleSelectEmit` · `ClassicalCallArmEmit` · `MergePhiPeel` · `RegionFlatten` · `PredMuxFlatten` | The control chain (file name `SwapRouteEmit` is history; `emitRoute` has one caller, `AbortParkEmit`). `MergePhiPeel` normalizes before detection and grows taint. `emitKickbackGroup` is the one spelling of "fire `P(θ)` when `ctl == v`". |
| `LoopLowering.cpp` | Bounded loops, `break`, the rolled in-loop collapse, loop-carried handles (`loopCarriedHandlePhi` is the one spelling). |
| `WireWalk.{h,cpp}` | Shared forward/backward wire walks. Note `isPotentiallyReachable(A,A)` is true by identity in LLVM 19. |
| `Uncomputation` · `ChainWalk` · `DagTraversal` · `FreePoint` · `EmitInverse` | The uncompute spine (runs last); `ChainWalk` owns the `!cq.branchphase` membership record. |
| `Specialization` · `SpecializeDetect` / `Reject` / `Clone` / `Seed` · `BennettWrap` · `IntrinsicLowering` | Function lifting: clone-on-taint (`__cq_q_<callee>_<mask>`) with its Bennett wrap, and the curated `llvm.*` intrinsic templates. |
| `QramLowering` · `IOSinkLowering` · `GuardedStoreArmEmit` · `AbortParkEmit` | Tainted-index QRAM, the output tape, guarded stores under tainted control, the noreturn-arm park (the one `cqrt_cswap` minter). |
| `LiteralIntegrity.cpp` | Emitted-gate literals must denote the source's value at every copied site. |
| `runtime/cq_runtime.{h,c}` | Hand-maintained (not generated) `cqrt_*` core ABI (trace-only). |
| `runtime/cq_templates.{h,c}` | **Generated**. Edit `tools/opcode_table.yaml`. |
| `tools/` | `free_pairing_check.py`, twin matrices, `library_coverage/` (census/probe), `cqc` driver, `install_cq.py`, stage cache. |
| `NORTHSTAR.md` | The plan of record: three goals, ten design principles. Wins over every other document. |
| `docs/` | `frontend.md` (user surface), `backend.md` (pass + runtime ABI), `quantum-classical-handling.md` (the taint boundary), `llvm-implementation.md` (LLVM APIs), `example.md` (worked walkthrough), `backend-provider.md` (static backends), `design/qram-local-array-uncompute.md` (design note), `labreport/`. Source comments cite `frontend.md` §3.1/§3.2/§3.5, `backend.md` §5.1/§11.3/§11.4 and `quantum-classical-handling.md` §5.2 by number: keep those sections stable. |
| `CODE_MAP.md` | Function to `file:line` index, regenerated by `tools/update_code_map.py`. |

Diagnostics are loud and source-located; negative fixtures mirror the message
character-for-character. Two runtime symbol families: `cqrt_*` (hand-maintained core) and
`cq_template_*` (generated:
`cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>][_hl|_lh][_controlled][_inv]`). Conventions:
C11/C++17, `CXX_EXTENSIONS OFF`, `-Wall -Wextra` without `-Werror`. Always use `cp -f`,
`mv -f`, `rm -f`, `rm -rf` in shell commands.

## Beads, lab report, session completion

- `bd` tracks all work: `bd ready`, `bd show <id>`, `bd update <id> --claim`, `bd close <id>`;
  `bd prime` prints the full workflow. `bd remember` holds durable knowledge.
- `docs/labreport/` is an owner-facing, append-only pdflatex log (one entry per session,
  ≤5 pages, sealed by SHA-256 in `MANIFEST.sha256`). It is non-normative: it cites where
  rules live and states none. Measured numbers only, with the command shown.
  Append with `docs/labreport/TEMPLATE.tex` → `sessions/NNN-YYYY-MM-DD-slug.tex`, then
  `tools/labreport/build.py --seal`. Commit the sources, never the PDF.
- **Ending a session:** file bd issues for remaining work; run the batch gate (R15) if code
  changed; close finished issues; append the lab-report entry; then `git pull --rebase &&
  git push` and confirm `git status` shows up to date. Work is not done until the push succeeds.
