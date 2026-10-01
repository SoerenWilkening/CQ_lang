// ChainWalk.h — Terminal-handle detection + the shared per-gate predicates the
// Phase-5 uncompute spine (and the WI-4 whole-DAG recovery, `DagTraversal`) key
// on. Pure analysis — emits no IR.
//
// A tainted DATA register is built by a DAG of gates: a `cqrt_alloc_<W>` mint,
// in-place rotations (`cqrt_ry/rz_<W>`), and reassigning data templates
// (`cq_template_<op>_<W>[_hl|_lh|_qq]`) that each RAUW-produce a FRESH result
// handle. A register may have two tainted parents (a QQ node) and may fan out to
// several consumers (a DAG, not a linear chain). The whole-DAG adjoint is emitted
// ONCE at the last-use point (PRD §2.1/§2.11); `DagTraversal::recoverDataDag`
// recovers the DAG from the terminal handles, and this module supplies the
// terminal test plus the gate predicates both it and the driver share (Rule 14 —
// one definition, no per-TU duplication of the chain vocabulary).

#ifndef CQ_IRPASS_CHAIN_WALK_H_
#define CQ_IRPASS_CHAIN_WALK_H_

#include "llvm/IR/Instructions.h"
#include "llvm/IR/Value.h"

namespace cq {

struct TaintSet;

// A FORWARD QRAM store in one of the two FROZEN ABI shapes, and the ONE definition
// of that relation (Rule 14):
//   * plain   `cqrt_qram_store_<W>(arr, idx, val)`                   — VOID, arg_size 3
//   * guarded `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)`  — VOID, arg_size 4
// The `_unc` adjoint twins are excluded (the spine EMITS those; it never recognizes
// one as a forward gate), as is any other spelling — a declaration contradicting the
// frozen ABI on EITHER axis (arity or void-ness) is off-pattern input and declines
// (Prime Directive).
//
// BOTH AXES ARE CHECKED, and the second one is the load-bearing one. The property the
// spine actually needs is "this gate MINTS NO RAIL" — that alone is why a store may be
// adjointed by a SAME-ARGS `_unc` rather than the out-first form every rail-minting
// producer gets. Arity is a proxy for it; VOID-ness IS it. Checking arity alone leaves
// the original defect fully reachable at the frozen arity (see the .cpp).
//
// SHARED, deliberately, between `isInPlaceGateOn` (which register does this gate
// write?) and `EmitInverse::isInverseEmittable` (can the spine adjoint it?). Those
// two used to answer from independent spellings — the second a bare PREFIX match at
// ANY arity — so an off-ABI-arity store was invertible to one and not an in-place
// gate to the other, and the spine emitted an adjoint that zeroed no rail while
// still freeing a register (bd test_C_libtooling-1fim; MEASURED silent, `opt` rc=0,
// verify-clean, and CERTIFIED by `free_pairing_check.py`). Same class as the bd uow0
// `railOf` mis-attribution: two predicates, one gate, different answers. Ask this
// function; do not re-spell its arity tests.
bool isAbiQramStore(const llvm::CallInst *G);

// An in-place, handle-threading gate on `H` — a VOID gate that MUTATES `H` rather
// than minting a fresh handle, so it belongs to `H`'s link of the DAG. Three
// callee shapes, each with its own required arity and handle SLOT (see the .cpp):
//   * `cqrt_ry/rz_<W>(H, θ)`                          — arg 0, arg_size 2
//   * `cqrt_addc/xorc_<W>(H, imm)`                    — arg 0, arg_size 2
//   * `cqrt_qram_store_<W>(H, idx, val)`              — arg 0, arg_size 3
//   * `cqrt_qram_store_<W>_controlled(flag, H, idx, val)` — arg 1, arg_size 4
// Every `_inv`/`_unc` twin fails (it is the adjoint, never a forward gate), as does
// any other `_controlled` form. THIS PREDICATE IS THE SINGLE DEFINITION OF "which
// register does this gate write": `railOf` is derived from it (bd
// test_C_libtooling-uow0), so a new shape added here is automatically attributed
// there. Callers pass a candidate handle; it does NOT test that `H` is a register,
// so `railOf` filters constants before asking.
//
// The `cqrt_addc/xorc_<W>` row arrived with M-C (bd test_C_libtooling-6uqc Inc
// 2a). Until then those gates were minted only inside a loop the spine leaks, so
// their absence was inert; M-C puts them on straight-line rails the spine must
// zero and free, which makes every consumer of this predicate depend on the row.
// See the .cpp for the per-consumer list.
bool isInPlaceGateOn(const llvm::CallInst *G, const llvm::Value *H);

// ---------------------------------------------------------------------------
// THE BRANCH-PHASE (KICKBACK) GATE RECORD — bd test_C_libtooling-3qlq Inc 1
// part A, Rule-13 round-1 finding F-L7-1 (a CONFIRMED silent miscompile).
//
// WHAT THE RECORD IS FOR. After D1/D2 the register form of `cq_phi` is retired
// and `cqrt_rz_i1(f, θ)` no longer means "the user wrote `x = cq_phi(x, θ)`, a
// member of `x`'s reversible chain". It means THE PROGRAM'S ANSWER, kicked back
// onto a control ancilla: `Σ a_x |x⟩|c(x)⟩ → Σ a_x e^{iθ c(x)} |x⟩|c(x)⟩`. It is
// not a step toward a value; it IS the value. Adjointing it deletes the program.
//
// MEASURED, plain C, `clang -O1`, `opt` exit 0, verify-clean, STRICT stage-2b
// clean (`$SP/progress/review_r1_L7/probes/j3_sharecond_measure_only.c`): on the
// ziov `ShareCondFlag` path — where the compare is ALSO read as data, so the flag
// rail is a live member of a data lineage the whole-DAG spine reverses — the
// spine emitted `cqrt_rz_i1(h1, -θ)` right after the kickback's `cqrt_rz_i1(h1,
// +θ)`. Both are diagonal in the same basis label and the copy between them does
// not move it, so the product is EXACTLY the identity: the emitted circuit is
// byte-for-byte the circuit for the same program with the `cq_phi` DELETED. The
// pre-3qlq oracle keeps its phase gate on that source, so it is a fidelity
// REGRESSION, not an inherited hazard.
//
// WHY A RECORD AND NOT A NAME TEST. `isInPlaceGateOn`'s uncontrolled-rotation row
// admits `cqrt_rz_<W>(H, θ)` on grounds that remain CORRECT for a genuine chain
// gate; what changed is not the symbol, it is who emitted it and what it denotes.
// Two producers of the same symbol now want opposite answers from the spine, so
// the discriminator has to be the emission, not the name. (A name test would also
// become a second spelling of this set the moment part B narrows the emitted Rz
// surface to `cqrt_rz_i1` — Rule 14, `railOf` drift.)
//
// WHY INSTRUCTION METADATA AND NOT A `TaintSet` POINTER SET. The Rule-13 round-1
// plan proposed `taint.BranchPhaseGates`. Metadata is used instead, deliberately,
// for three measured-in-this-tree reasons — and there is exactly ONE spelling of
// the question either way:
//   (1) `isInPlaceGateOn`, `preservesBasisUnderRecord` and
//       `EmitInverse::isInverseEmittable` are PURE per-gate predicates with no
//       `TaintSet` parameter, asked from **22 sites across seven files**
//       (`grep -rn 'isInPlaceGateOn(\|preservesBasisUnderRecord(\|isInverseEmittable(' ir-pass/src`,
//       minus the three definitions: `ArithLowering` 1, `BennettWrap` 1,
//       `BreakReversePlay` 2, `ChainWalk` 7, `DagTraversal` 3, `EmitInverse` 1,
//       `Uncomputation` 7) — three of which (`railOf`,
//       `railCarriesControlledRotation`, `ArithLowering::priorUseIsSettled`)
//       have no `TaintSet` in scope at all. Threading one through all of them is
//       a cross-cutting signature change to the Rule-13 core made in service of
//       a fix to the Rule-13 core. (Round-1 wrote "19 sites across six files";
//       Rule-13 round-2 lens R2 measured 21/7 and I measure 22/7 — the residue
//       is whether `ChainWalk.cpp`'s adjacent `isInPlaceGateOn` /
//       `preservesBasisUnderRecord` pair counts once or twice. The ARGUMENT is
//       unaffected in every reading; the number is corrected because a census in
//       a write-up that does not reproduce is the F-L6-2 class.)
//   (2) A `Value *` set keyed at emission time and read many stages later is the
//       bd `drbq` Inc-1 round-1 defect VERBATIM: the set dangled because a later
//       stage RAUW'd and erased the keyed instruction, and the freeze silently
//       stopped applying. Metadata cannot dangle — it dies with its instruction.
//   (3) Metadata SURVIVES `CloneFunctionInto` (Phase-6 specialization) where a
//       pointer set would not — stated as a PROPERTY OF THE RECORD, which is all
//       it is. Rule-13 round-2 finding F-R1-5: it is not a live hazard at this
//       HEAD, because F-L3-3's own fix (feeding `taint.PhaseCalls` to
//       `SpecializeReject`/`SpecializeDetect`) makes a callee containing ANY
//       `cq_phi` a loud reject — `cq specialization: callee contains a quantum
//       primitive (cq_*); only classical functions are lifted` — so no clone can
//       contain a kickback gate to lose. Reasons (1) and (2) are measured and
//       carry the choice on their own; keep (3) as a property, and do not quote
//       it as an argument.
// The record is also VISIBLE in the lowered `.ll` (`!cq.branchphase`), which is
// the artifact `free_pairing_check.py` and every fixture read.
//
// STAMP IT AT EVERY EMISSION SITE — AND THE ENUMERATION IS THE FENCE, SO IT IS
// KEPT EXACT (Rule-13 round-2 findings F-R1-3 / F-R2-2: this sentence said
// "three" while the tree it shipped in had six, in the one comment whose whole
// job is to let a reader audit exactly that). There are **SIX**
// `markBranchPhaseGate` calls, wrapping SIX `CreateCall(Rz, …)` expressions, in
// FOUR files, belonging to FIVE emitters:
//   1. `SwapRouteEmit.cpp:1538`  — P1 flat, the arm loop           (pinned by
//      `control_phase_kickback_and2.ll`'s MDTAG, and by the CHECK in
//      `..._share_flag*.ll` / the three `..._inloop*.ll`);
//   2. `SwapRouteEmit.cpp:1568`  — P1 flat, the merge-tail loop    (pinned by
//      `..._ifelse.ll`, `..._ifelse_tail_armfalse.ll`, `..._negated_tail_phi.ll`);
//   3. `SwapRouteEmit.cpp:1773`  — P4, `emitPhaseKickbackNestRegion` (pinned by
//      `control_phase_nest_kickback.ll`'s `MDTAG-COUNT-2`);
//   4. `SwitchRouteEmit.cpp:179` — P5, `emitSwitchPhaseRegion`      (pinned by
//      `control_phase_switch_kickback.ll`'s `MDTAG-COUNT-3`);
//   5/6. `AngleSelectEmit.cpp:179` and `:181` — P2, the Rz stem's two gates
//      (pinned by `control_angle_select_phase_{constants,runtime,nonfinite_arm}.ll`).
// Sites 3 and 4 were added by the Inc-1b merge, which is the concrete form of
// the warning that follows: a SEVENTH emitter that mints a kickback gate and
// forgets this call re-opens F-L7-1 with no diagnostic anywhere. Re-measure with
// `grep -c 'markBranchPhaseGate(' ir-pass/src/*.cpp` rather than trusting the
// list.
void markBranchPhaseGate(llvm::CallInst *G);

// Is `G` a recorded branch-phase (kickback) gate? Asked by the three spine
// predicates named above, each of which must treat it as OPAQUE: an
// unrecognized consumer, never a DAG link. The consequence is `D.NotClosed` on
// the flag rail, so the rail is LEFT ALLOCATED rather than reversed and freed —
// Rule-6 safe (a leak, never a dirty free) and byte-for-byte the pre-3qlq
// oracle's disposition on the same source.
bool isBranchPhaseGate(const llvm::CallInst *G);

// Does the rail `H` carry a `cqrt_{ry,rz}_<W>_controlled` gate — i.e. is it
// FROZEN for the whole-DAG uncompute spine (bd test_C_libtooling-drbq Inc 1,
// round-1 review finding L3 §1 / L5 §1)?
//
// A controlled gate's adjoint NEEDS ITS CONTROL, and the in-place rotation-arm
// emitter mints the flag, fires the gate, STRIPS the flag and FREES it all
// inside the region's own stream. The spine runs LAST and places a rail's
// reversal after that rail's final user, which for any register with a
// post-region consumer is AFTER the flag free — so the emitted adjoint would
// name a `cqrt_free`d rail (fires on |0>, i.e. never), leave the register dirty,
// and then `cqrt_free` a register still entangled with the condition: a hidden
// measurement (Rules 6/8), `opt` exit 0, verify-clean. Such a rail is therefore
// LEFT ALLOCATED — Rule 6's documented fallback, in the qubits-not-scarce
// regime.
//
// ⚠ THE QUESTION IS ASKED STRUCTURALLY, OF THE EMITTED IR, AND THAT IS THE WHOLE
// POINT. Inc 1 shipped this as a `SmallPtrSet<Value *>` (`ControlledRotationRails`)
// populated in `lowerRotations` with the theta's arg-0 — a PRE-`lowerOps` SSA
// value. For a DERIVED base (`r = p*5`, `p+5`, `p^5`, `p&5`, `zext p`,
// `@llvm.sqrt(p)`) that is the raw LLVM instruction, which `lowerOps` (the very
// next pipeline stage) RAUWs to a `cq_template_*` result and ERASES — through
// five separate `promote()` copies, none of which scrubbed the set. The set then
// held a DANGLING pointer, the live rail was in no owner set, and all three
// query sites THEN EXISTING answered "not frozen" (there are FOUR today — see
// (2) below): the use-after-free + dirty free above
// returned verbatim, from plain C, on an accept shape the increment's own probe
// `a1` had measured. MEASURED on 5 of 5 out-of-place base opcodes and on two
// independent `promote()` paths (i32 arith and f64 intrinsic).
//
// Deriving the rail from the GATE at query time is stale-proof by construction:
// the gate is a `CallInst` the pass mints and never erases, and its arg-1 USE
// follows every later RAUW, so `G->getArgOperand(1)` IS the live rail whenever
// this is asked. It also cannot be address-reused (there is no `Value *` set to
// reuse an address in — the `RegionFlatten::scrubTaint` hazard), and it covers
// BOTH stems: Inc 2 turns on `emitRz`'s controlled arm and inherits the freeze
// rather than the defect.
//
// It is deliberately WIDER than the set it replaces — ANY in-place controlled
// rotation on `H` freezes it, including one in hand-written input IR. Freezing
// is the Rule-6-safe direction (a leaked rail, never a dirty free), so a wider
// predicate here can only over-leak.
//
// ── Three facts the round-2 Rule-13 review (bd drbq) asked this header to state
//    explicitly, because each was true of the code and written down nowhere ──
//
// (1) THE STEMS ARE SPLIT: THIS IS AN `ry`-ONLY FREEZE (bd drbq Inc 2a). The
//     round-2 review recorded a CONTRADICTION here — this predicate froze any
//     `cqrt_{ry,rz}_<W>_controlled` rail while `preservesBasisUnderRecord` called
//     the `rz` spelling basis-preserving, i.e. NOT frozen, i.e. freeable; one
//     gate, two answers, with this one winning because it is asked first
//     (`DagTraversal` step 1 and step 3 both cut before the closure scan that
//     feeds the other). Inc 2 owned the decision (notes §10.3) and DECIDED IT THE
//     OTHER WAY: a DIAGONAL controlled rotation is NOT frozen.
//
//     WHY, in one line: the oracle for what a controlled Rz must look like to the
//     spine is the swap ROUTE it replaces, and under the route the register's
//     only users are `cqrt_cswap`s — unrecognized consumers, never a freeze. Inc
//     2a therefore narrows `isInPlaceGateOn` to the `ry` stem, which makes the
//     controlled Rz an unrecognized consumer too: `isTerminalHandle` false,
//     `isInteriorConsumer` false, `DagTraversal` closure `NotClosed`, and this
//     predicate false. Four verdicts, all identical to the route's, which is what
//     makes the Inc-2a golden multiset diff EXACTLY the collapsed route quintuple
//     and nothing else. See PRD §12.1 and bd `drbq-freeze-vs-261j-reconciled`.
//
//     The `ry` stem is UNCHANGED and still frozen, for the reason at the top of
//     this header: an Ry relabels its target on the `f=1` branch, so a skipped
//     adjoint moves a basis, and the adjoint cannot be emitted because it needs a
//     flag the region already freed. Never merge the two stems again without
//     re-reading both this note and `preservesBasisUnderRecord`'s.
//
// (2) IT IS A POST-`lowerRotations` SPELLING OF THE QUESTION, and there is a
//     DIFFERENT pre-lowering spelling. The fact "this register is under a
//     controlled rotation" exists twice: `TaintSet::ControlledRotations` (theta
//     → flag, populated at EMISSION in `SwapRouteEmit`, readable from
//     `lowerControlRegions` onward) and this structural query (readable only
//     after `lowerRotations` has minted the gate). All FOUR of this predicate's
//     query sites — `DagTraversal`'s step-1 walk and its step-3 closure scan,
//     `Uncomputation`'s interior partition and its terminal selection — are
//     inside `uncompute`, so the ordering obligation holds. But `IOSinkLowering`,
//     `lowerQramReads` and `lowerShadowMemory` all run BEFORE `lowerRotations`
//     and would get `false` here even if they asked: no gate exists yet. A new
//     stage must pick the spelling for its slot.
//
// (3) THE FREEZE SUPPRESSES THE SPINE'S DIAGNOSTICS, NOT ONLY ITS FREES.
//     `collectTerminalCandidates` skips a frozen rail BEFORE the terminal is
//     classified, so every loud decline that terminal would have raised is
//     skipped with it. Measured on a matched pair differing only in whether a
//     `cq_theta` on a QRAM-stored value sits in a tainted-condition arm: the
//     unconditional twin declines `cq uncompute: dead chain would free a
//     measured register`; the controlled twin exits 0 and leaves the whole
//     Shadow chain unreversed. The accepted stream is SOUND (Rule 6's
//     left-allocated fallback) — but a MISSING diagnostic downstream of this
//     predicate is not a clean bill of health.
bool railCarriesControlledRotation(const llvm::Value *H);

// A `cqrt_alloc_<W>` mint — a tainted register ROOT (the DAG bottoms out here).
bool isAllocMint(const llvm::Value *V);

// A REASSIGNING template producer (`cq_template_<op>_<W>…`) — its result is a
// FRESH rail the DAG must zero and free. A Phase-7.5 `cqrt_qram_load_<W>` result
// counts too (a cell copy-out is a fresh rail on the same footing). Rotations are
// in-place, allocs are roots, and the controlled forms / `_inv`/`_unc` twins are
// not forward data producers.
//
// HOISTED HERE from `DagTraversal`'s anonymous namespace by bd
// test_C_libtooling-6uqc Inc 5a, unchanged, because the M-B interior partition
// (`isInteriorTerminalHandle` below) is a THIRD consumer and this project's
// history is unambiguous about what a second spelling of one gate relation
// costs (bd uow0 `railOf`, bd 1fim `isAbiQramStore`). Rule 14.
bool isTemplateProducer(const llvm::CallInst *G);

// bd 261j(a) — does gate `G` keep its rail a BASIS PERMUTATION OF LIVE CONDITIONS,
// so that re-emitting the adjoint still returns the rail to |0⟩ even though the
// rail was RECORDED into a carrier the reversal never touches? See the .cpp for
// the full invariant (owner ruling 2026-08-10) and the per-row arguments.
//
// TWO CONSUMERS, and they ask it for two different reasons:
//   * `DagTraversal` step 3b — the record FREEZE, seeded per rail from
//     `recordsIntoKeptCarrier`.
//   * the M-B INTERIOR partition (Inc 5a) — which applies the same invariant
//     UNIVERSALLY rather than by seed, because an interior rail is BY
//     CONSTRUCTION recorded into a downstream carrier the reversal never
//     touches: that is exactly what makes it interior rather than a dead
//     terminal. So every gate of every owned interior rail must pass this, and
//     the alloc-minted `cqrt_ry` source rail — which never can — stays a
//     BORROWED parent, read-only and left allocated.
//
// FAILS CLOSED: anything not named in the .cpp is NOT basis-preserving.
bool preservesBasisUnderRecord(const llvm::CallInst *G);

// A `@cqrt_measure_<W>` sink (the lowered measure form Phase 5 sees). A measured
// handle is a quantum→classical sink, not a forward data consumer.
bool isMeasureSink(const llvm::CallInst *CI);

// A `@cqrt_tape_write_<W>` I/O output-tape sink (Phase 7.6). Like a measure, it
// is a SINK on its `src` arg — it READS the handle (a CNOT-class basis copy) but
// is NOT a forward data consumer that extends src's chain, so the whole-DAG spine
// treats a tape-write user as benign: src stays a terminal candidate and the tape
// write itself is never recovered as a reversible gate. Distinct from
// `isMeasureSink`: a tape write is NOT a quantum→classical collapse (it sets no
// MeasuredUpstream), and the kept `out_handle` it returns is an `OutputRails`
// member the spine subtracts separately (TaintSet::OutputRails).
//
// "PRESERVES src" is TRUE of the src REGISTER and FALSE of src's freeability
// (bd 261j(a), owner ruling 2026-08-10). A CNOT-class copy onto a rail the
// reversal NEVER touches leaves src ENTANGLED with the kept carrier, so src's
// lineage does NOT uncompute normally whenever src's own chain is not a basis
// permutation of live conditions. `recordsIntoKeptCarrier` + the `FrozenRails`
// freeze (DagTraversal step 3b) is what decides that; do NOT re-derive "the tape
// preserves src, therefore src frees" from this predicate.
bool isOutputSink(const llvm::CallInst *CI);

// Does the sink call `S` RECORD the handle `H` into a carrier the reversal never
// touches — today exactly a `cqrt_tape_write_<W>[_controlled]` kept output rail
// (bd 261j(a))? A record is not a collapse and not a forward consumer, but it
// CORRELATES H with a register that is never uncomputed and never freed, which is
// what makes a later `cqrt_free(H)` a hidden measurement unless H's own forward
// chain is a basis permutation of still-live conditions (Rules 6/8).
//
// SLOT-BLIND ON PURPOSE. The controlled form is
// `cqrt_tape_write_<W>_controlled(ctrl, tape, src)` (runtime/cq_runtime.h:438-442):
// BOTH `ctrl` and `src` are recorded — the ctrl's label lands in the entry's
// existence pattern exactly as the src's label lands in its content. Testing "src
// is arg 1" is correct only for the UNCONTROLLED form and would MISS the recorded
// src of the controlled one (an under-freeze is the over-accept class), and it
// cannot be broken by a later argument-order change (Rule 11).
//
// WHAT SLOT-BLINDNESS COSTS, stated honestly: on EMITTER-produced IR, nothing —
// the tape TOKEN is a classical resource handle from `cqrt_tape_alloc`, never
// tainted and never a DAG rail, so it is never even offered to this predicate. On
// HAND-WRITTEN IR a tainted handle CAN sit in the token slot, and it is then read
// as recorded and frozen (MEASURED in the bd 261j(a) Rule-13 round). That is an
// over-decline — a leak, the safe direction — and it is accepted deliberately
// rather than repaired with a slot test, because every slot test is an
// under-freeze risk on the controlled form and under-freeze is the unforgivable
// direction. Do not "fix" it by indexing arguments.
//
// TWO SURFACES, and only the tape arm is slot-blind. The method-B copy-out
// `cqrt_copy_<W>(src, dst)` now ALSO records (bd 5pio, owner ruling 2026-08-11): its
// destination is a kept carrier the reversal never touches, the same relation the
// tape has. That arm is SLOT-AWARE — it fires only when `H` is the SOURCE.
//
// NOT because seeding the destination would do harm: it would not, and a Rule-13
// reviewer measured that. `FrozenRails` is read at exactly ONE site and only to skip
// a `cqrt_free`, so the freeze is purely SUBTRACTIVE; and a copy destination is never
// freeable to begin with (in that role it is not a benign closure user, so it forces
// `D.NotClosed` and the whole DAG leaks). Seeding it would change nothing, and if it
// ever did it would be a leak — the safe direction, exactly as the tape arm's own
// slot-BLINDNESS argues above. The asymmetry is sound because of that `NotClosed`
// compensation, which is what a future over-decline-reduction would remove. See the
// .cpp for the same correction; an earlier draft asserted the harm in BOTH files and
// only one was fixed.
//
// This replaces the previous "deliberately TAPE-ONLY" rule, which deferred the copy
// surface to bd 8gi5/5pio on the grounds that its safety rested on an emitter-side
// census. It did, and that is exactly the durability problem: `isCopyOutSink` is a
// NAME-shaped predicate, so a future emitter minting a copy on a rotation-bearing
// rail inherits a free with nothing checking. The census is now mechanical (zero
// hazard-shape instances across 1241 lowered modules) and the freeze no longer rests
// on it.
bool recordsIntoKeptCarrier(const llvm::CallInst *S, const llvm::Value *H);

// A method-B copy-out `cqrt_copy_<W>(src, dst)` reading `H` as its SOURCE (arg 0).
// Like a measure / tape-write SINK it READS H (a CNOT-class basis copy) without
// consuming it, so the whole-DAG spine treats it as a benign terminal user: H
// stays a terminal candidate while the copy DESTINATION (dst, arg 1) is the kept
// escaped/measured carrier. The 3-arg `_controlled` data-mux copy (4.4/6.5) and
// any `_inv`/`_unc` twin fail this predicate.
//
// The "PRESERVES H ⇒ H's lineage uncomputes normally" rationale this predicate
// used to carry is the SAME false step bd 261j(a) ruled out on the tape surface —
// see `isOutputSink` above. It is not a LIVE defect here, and the reason is a
// CENSUS, not an argument (bd 8gi5). Exactly FIVE sites mint an uncontrolled 2-arg
// `cqrt_copy_<W>`, and each is excluded for a DIFFERENT structural reason:
//   * SwapRouteEmit.cpp   — the src's cswap users force `NotClosed`, so the spine
//                           never reverses it.
//   * SwitchValueEmit.cpp — same (routed base, cswap users).
//   * BreakReversePlay.cpp— the capture rails are `ControlOwnedRails` (DD-4),
//                           subtracted from the DAG before any of this runs.
//   * BennettWrap.cpp     — inside a Phase-6 clone body, invisible to the spine
//                           and rotation-free.
//   * QramLowering.cpp    — the ONE case the spine does reverse, and it is the
//                           SOUND Bennett case: the src is a `cqrt_qram_load_<W>`
//                           result, a permutation of arr/idx that reverse program
//                           order keeps at their producer-time values.
// WHAT THAT CENSUS DID AND DID NOT BUY — and it is now HISTORY, not the rule. It
// said no emitter reached the bad shape; it never said the predicate CHECKED
// anything, and nothing in it stopped a future emitter minting
// `ry(%h); copy(%h,%dst); ry(-%h); free(%h)`. That gap is CLOSED: bd 5pio ruled
// (owner, 2026-08-11) and `isCopyOutSink` now SEEDS the 261j record freeze via
// `recordsIntoKeptCarrier`, so the source's own chain is re-proved instead of
// trusted. The census survives only as the reason the change was PROPHYLACTIC
// against that direct shape rather than a fix for a live miscompile — and if you add
// a sixth emitter site it is still the thing to re-run.
//
// THE RULING WENT AGAINST THE GUARD THIS BLOCK USED TO PROPOSE. Admitting the copy
// sink only when the destination is provably measured was REFUTED, not merely left
// unadopted: Bennett.jl requires nothing of a copy-out destination (not measured —
// it has no measurement concept — not kept, not even fresh or zero) and ships three
// kernels that copy out and then uncompute-and-free the SOURCE into a live register,
// an accumulator and a scratch checkpoint. A dst-measured rule breaks all three.
// It is also not SUFFICIENT: it says nothing about the source's correlation with its
// own ancestors, which is what the backward `AncEdges` walk models — and in practice
// the ancestors are where the behaviour change actually lands (the sxuk QRAM index
// roots, whose frees the freeze now suppresses; 9 lit fixtures and 6 e2e goldens
// moved, 30 frees, every changed line a removed `cqrt_free`).
// (bd memory [bennett-copyout-destination-2026-08-11].)
//
// ORDERING IS SEPARATE FROM FREEZING, and this predicate is consulted for both.
// A copy is a benign terminal user for CLOSURE, but it is still a USE: the spine
// records it in `DataDag::PreservingSinks` so the reversal is placed after it (bd
// 8gi5 item 3 / bd e4zs — MEASURED use-after-free before that fix).
bool isCopyOutSink(const llvm::CallInst *G, const llvm::Value *H);

// The RAIL a gate creates — the value the gate's adjoint zeroes and the driver
// then frees. An in-place rotation (`cqrt_ry/rz_<W>`, self-adjoint `cqrt_x`) acts
// on its arg-0 handle; a template producer's result IS the rail (PRD §2.11).
// Shared by the emission driver (`Uncomputation::emitDagReversal`) and the freeze
// decision (`DagTraversal` step 3b) so the two cannot drift — the same Rule-14
// hoist `LiteralIntegrity` applied to `valueCarriesUndef`.
//
// DERIVED FROM `isInPlaceGateOn`, NOT RE-SPELT (bd test_C_libtooling-uow0, fixed):
// for an in-place gate the rail is the argument that predicate matches, so the two
// cannot disagree about which register a gate writes. They DID disagree before —
// this returned the arg-0 FLAG of `cqrt_qram_store_<W>_controlled(flag, arr, idx,
// val)` while `isInPlaceGateOn` matched its arg-1 ARRAY — which mis-keyed
// `Earliest` (whose rail's free is anchored to which gate) on every guarded-store
// module. A producer's fresh result is its own rail; `cqrt_x` is handled explicitly
// and agrees with the derivation (see the .cpp).
llvm::Value *railOf(llvm::CallInst *G);

// Is `Handle` the TERMINAL of its register's def-use DAG? True when no OTHER
// tainted instruction consumes it as a forward data operand — its only remaining
// users are non-producers (a measurement sink, a `ret` escape, classical reads,
// or its own in-place rotations, which mint no new handle). Collapses a
// reassigned-variable chain (`q = q + 1; q = q * 2`) to a SINGLE terminal so the
// whole DAG is reversed once (PRD §2.1, R-whole-chain).
//
// Deliberately STRICTER than a tainted-RESULT test: Phase-4 flag/teardown
// producers (`cq_template_icmp_* → flag`, the `_inv` teardown) are NOT in
// `taint.Tainted`, yet a condition register feeding them is still live (its `_inv`
// teardown reads it after any candidate free point). Keying on the result's taint
// would mis-free that base register — observed breaking the control e2e goldens.
//
// `isOutputSink` MUST stay in the benign list — the bd 261j(a) record freeze
// REQUIRES a taped rail to remain selectable as a terminal, because the freeze is
// PER-RAIL and the DAG it prunes from has to be recovered first. Dropping the
// exemption here (the ruling note's "mirror at ChainWalk.cpp:105") empties
// `Terminals`, so `Uncomputation` bails before any of its scans run: MEASURED to
// lose the SOUND `cqrt_free` of the derived rail in two fixtures AND to silently
// disarm all three of the driver's loud declines (uninvertible / divergent-arm /
// measured-lineage). That is strictly worse than the blunt rule. Do NOT mirror.
bool isTerminalHandle(llvm::Value *Handle, const TaintSet &taint);

// ── M-B INTERIOR MODE (bd test_C_libtooling-6uqc Inc 5a) ─────────────────────
//
// `isTerminalHandle` above answers "is this register's last value never read
// again?" — the DEAD-TERMINAL question. It is FALSE for every rail in the middle
// of a live chain, which is why the whole condition-provenance chain of
//     int f = sqrt(a + 3.0) <= 5.0;   /* a = cq_theta(...) */
// has no terminal at all and is never seeded into `recoverDataDag`: four
// entangled rails minted, never uncomputed, never freed, and both shipped gates
// blind to it (the golden records a self-consistent stream; `free_pairing_check`
// does not track template-minted rails). That is bd 6uqc's P1.
//
// The INTERIOR question is different and is a POSITION question: is this rail
// dead AFTER its last forward use? This predicate answers the STRUCTURAL half
// only — the half that can be decided from the def-use graph — and the driver
// (`Uncomputation`'s interior partition) owns the positional half (every
// consumer provably executed before the discharge point and never re-read
// after; `provablyBefore`, dominance + `!isPotentiallyReachable`).
//
// A rail is a structural interior candidate iff ALL of:
//   (I1) it is tainted and its producer is an UNCONTROLLED `cq_template_*` —
//        a fresh rail minted by a basis permutation of its operands. A
//        `cqrt_alloc_<W>` source rail is deliberately EXCLUDED: it carries the
//        `cqrt_ry` that MINTED the superposition, so once anything downstream
//        holds a record of it no adjoint returns it to |0⟩ (the `DagTraversal`
//        "decisive corollary"). Such a rail is a BORROWED parent — read-only,
//        never adjointed, never freed. `cqrt_qram_load_<W>` rails are excluded
//        too, by SCOPE not by physics (Inc 5 leaves the 7.5 surface alone;
//        pinned by lowering_uncompute_interior_leak_qram_load.ll).
//   (I2) it is NOT already a dead terminal (`isTerminalHandle`) — the existing
//        whole-DAG partition owns those, and one rail must have exactly ONE
//        owner or its shared prefix is adjointed twice (Rule 8).
//   (I3) EVERY user is a `CallInst` and `isInteriorConsumer`: an in-place
//        gate on the rail that `preservesBasisUnderRecord` (Rz / addc / xorc —
//        NOT `cqrt_ry`), a forward reassigning template producer that READS it,
//        or — since M-B Increment 6 — an EMITTER-RECORDED Phase-4 flag strip
//        (`TaintSet::DischargedFlagGates`) reading it in a shifted handle slot,
//        or — since bd rhk5 — a Phase-6 CLONE CALL whose body is PROVEN not to
//        write it (`cloneCallPreservesArg`, below), or — since bd r2j3.1 — a
//        forward ABI QRAM STORE reading it outside its array slot (index, value
//        or guarded path flag: read and preserved; a store the dead-terminal
//        spine reverses has already claimed the rail, so this governs only a
//        never-reversed store).
//        A measure, a tape write, a copy-out, a `ret`, a φ/select, a
//        controlled gate, a route, an UNPROVEN clone call, a `cqrt_free` or any OTHER
//        adjoint twin all DISQUALIFY the rail (it is observed, escaped, recorded
//        into a kept carrier, or owned by another emitter) — safe-leak, never a
//        decline (M-A owns loudness; the driver is LEAK-FIRST).
//   (I4) it has at least one FORWARD consumer, else (I2) would have caught it.
//
// The predicate is deliberately blind to position so that the two halves cannot
// be confused: everything here is true of the SSA graph and survives any
// scheduling, and everything the driver adds is a dominance/reachability proof.
//
// `AdmitCloneCalls` (bd rhk5 round 2, bd `kyy1`) switches clause (b′) of
// `isInteriorConsumer` — a Phase-6 clone call proven read-only — on or off. OFF
// reproduces the pre-rhk5 candidate set EXACTLY; `Uncomputation`'s interior driver
// plans both ways and keeps the plan set that discharges a SUPERSET of the other's
// rails, so no discharge the pre-rhk5 planner makes ON THE MODULE IT IS ASKED ABOUT
// can be lost (r1B F-r1B-1 lost one: a rail (b′) made interior dragged its dead
// sibling's discharge point past a non-diagonal gate). ⚠ "On the module it is asked
// about": the M-C late round asks the same question one stage earlier, so the claim
// is per call, not end to end — see `collectInteriorPlans` (r2A F-r2A-4). Pass it
// explicitly; there is no default on purpose.
bool isInteriorTerminalHandle(llvm::Value *Handle, const TaintSet &taint,
                              bool AdmitCloneCalls);

// The per-USER half of `isInteriorTerminalHandle` (I3), exported because the DAG
// closure scan needs the SAME answer: an interior rail's forward consumer is a
// benign closure user (it does not make the DAG `NotClosed`) precisely when it is
// one of the shapes this predicate admits. Two spellings of that would be the
// `railOf`/`isAbiQramStore` drift hazard again (Rule 14).
//
// `taint` is needed for exactly one clause — `DischargedFlagGates` membership
// (M-B Increment 6). It is passed rather than name-matched because "is a `_unc`"
// is TRUE of the uncompute spine's own adjoints, and admitting those would let
// one partition free a rail another partition's adjoint still reads.
//
// `AdmitCloneCalls` gates clause (b′) only — see `isInteriorTerminalHandle`.
bool isInteriorConsumer(const llvm::CallInst *C, const llvm::Value *R,
                        const TaintSet &taint, bool AdmitCloneCalls);

// ── bd test_C_libtooling-rhk5 — a PHASE-6 CLONE CALL THAT ONLY READS `V` ─────
//
// Does the call `C` — a call to a function the SPECIALIZER built (a clone
// `__cq_q_<callee>_<mask>` or its `_unc` twin) — leave the computational-basis
// LABEL of `V` unchanged, in EVERY argument slot `C` passes `V` in?
//
// WHY THIS IS A QUESTION AT ALL. A clone call executes a whole function body at
// one program point, so for the uncompute spine it is one gate with an unknown
// write set — and both spine predicates that meet it (`preservesBorrowedParent`,
// the M-B clause-(d) scan, and `isInteriorConsumer` above) FAILED CLOSED on it,
// counting it as a mutation of every argument. The hand-inlined twin of the SAME
// program puts a `cq_template_*` producer where the call was, which both
// predicates admit, so the twin discharged a derived chain and the clone program
// left it allocated and ENTANGLED across a later non-diagonal gate (bd rhk5: a
// Rule-8 wrong unitary, `opt` exit 0, one lyyf-(B) warning). Hand-inlining a pure
// callee must not change the circuit.
//
// WHAT IS PROVEN, AND FROM WHAT. The answer is derived from the callee BODY as
// it stands when the spine asks (the specializer built and lowered every clone
// inside `specialize()`, long before `uncompute`; no later stage emits into a
// clone), and nothing is assumed of the Bennett wrap. ⚠ THE FIRST SPELLING OF
// THIS PARAGRAPH SAID "Nothing is read off the NAME", AND THAT WAS FALSE (bd rhk5
// Rule-13 r1A F-r1A-1 / bd `fb5y`, a P1): each use inside the body was classified
// by its callee's NAME, so a module that DEFINED `cq_template_evil_i32(k){cqrt_x(k)}`
// and called it from a pre-supplied `_unc` twin got the caller's chain discharged
// AFTER a write to `q` — two frees of non-|0⟩ rails, one a hidden measurement, at
// `opt` exit 0 with no warning and STRICT 2b clean. What is read off a name NOW,
// and why that is the right place for it, is stated per row below: a name is
// trusted ONLY for a callee that is a DECLARATION in this module — an external
// runtime symbol, whose semantics are the frozen ABI every emitter already relies
// on — and a DEFINED callee is never classified by its name at all.
//
// The callee must be
//   (C1) a non-varargs `Function` with an EXACT definition
//        (`hasExactDefinition()`: defined here AND not interposable, not
//        `linkonce`/`weak`/`available_externally` — bd `fb5y` F-r1A-2, where a
//        `weak` read-only twin was replaced at LINK time by a strong writing one,
//        so the walked body was not the body that ran), resolved from the called
//        OPERAND (an alias, bitcast or indirect call does not resolve — the bd
//        xy9n lesson), and RECORDED in `taint.SpecHandleArgMask` — the
//        specializer's own record of what it built (bd l3oi F-R7-1), never the
//        `__cq_q_` prefix. ⚠ The record is NOT proof of authorship:
//        `Specialization::ensureTwin` REUSES a module-supplied `<clone>_unc`, and
//        `buildClone` records it like one it synthesized. That is why the body is
//        walked rather than trusted;
//   (C2) passed `V` ONLY in argument slots (never in an operand bundle), each of
//        them a slot the record marks as a HANDLE;
// and for each such slot the FORMAL parameter must be proven label-preserving in
// the body: EVERY use of it is an argument of a `CallInst` that is one of
//   (B1) a call to a DECLARED forward reassigning producer (`isTemplateProducer`:
//        a `cq_template_*` or a `cqrt_qram_load_<W>`) — the runtime ABI reads
//        every operand and mints a fresh rail; there is no mutating slot;
//   (B2) a call to a DECLARED out-first `cq_template_*_unc` adjoint reading the
//        formal in a HANDLE slot other than slot 0 (`isUncHandleSlot` — the ONE
//        slot table): the adjoint XORs onto its slot-0 rail and leaves every other
//        operand as it found it (DD-3). Slot 0 — the rail it WRITES — is refused;
//   (B3) a call to a DECLARED basis copy (`isCopyGate`, `RotationLowering.h` — the
//        ONE statement of "a `cqrt_copy_<W>[_controlled]` writes its LAST operand
//        and reads the others", Rule 14; the first spelling re-derived it inline,
//        r1A F-r1A-6 / r1B F-6) reading the formal in any slot but the last, the
//        formal not also passed as the destination;
//   (B4) a call to another function this predicate proves, recursively — an inner
//        clone call or an inner `_unc` twin call, formal for formal, under (C1)/(C2).
// ANYTHING ELSE refuses the whole call: a `ret` or φ/select of the formal (an
// alias escaping the body), a store, a cast or classical op (an alias the walk
// would lose track of — `spec_leak_clone_read_twin_alias.ll`), `cqrt_x`, a copy
// DESTINATION, a rotation, a measure, a free, a toffoli/cnot target or control, a
// formal in an adjoint's slot 0 or literal slot, and ANY name-shaped callee that
// the module DEFINES. (B1) deliberately does NOT ask which slot of a forward
// producer holds the formal — it is `preservesBorrowedParent` clause (2)'s own
// test, and a producer has no writing slot at all, so the slot cannot bear on the
// LABEL; `isInteriorConsumer` (b)'s handle-slot fence answers a different question
// and is applied there.) FAILS CLOSED, and the fail direction is a LEAK (Rule 6's
// fallback, the oracle's behaviour byte for byte), never a misplaced adjoint.
//
// COST AND TERMINATION (bd `tcpq`, r1A F-r1A-3). The verdict per (function,
// formal slot) is MEMOISED for the duration of one query, so a call DAG of clones
// costs its size, not its number of paths (the first spelling had no memo and a
// 29-line width-2 library took 18 s at nesting 12). A (function, slot) re-entered
// while it is still being proved is a CYCLE and refuses; a nesting deeper than 16
// refuses (16 (function, formal) pairs is the deepest proof admitted — pinned from
// both sides by spec_accept_clone_read_depth_at_cap.ll / spec_leak_clone_read_depth_cap.ll).
// WHY A CYCLE CANNOT LICENSE ITSELF THROUGH THE CACHE — two reasons, the second
// being the one that carries the weight: (i) both refusals are PROVISIONAL (they
// depend on the path that reached them) and are never memoised, and a "yes" can
// never depend on one, because the walk is a CONJUNCTION — any refusal below a node
// makes the node a refusal; (ii) the memo lives for ONE query and the walk aborts
// that query at its FIRST refusal, so no entry written after a provisional refusal
// is ever read. (ii) makes (i) belt-and-braces: a mutant that memoised provisional
// refusals as "yes" could not change a verdict (argued, and recorded as such in
// TRACK_RHK5.md round 2 rather than claimed as a kill).
//
// THE RESIDUAL TRUST, stated because it is the one thing this proof cannot see: a
// DECLARED name-shaped callee is taken to be the runtime's. A module that
// declares a novel `cq_template_evil_i32` from a pre-supplied twin and supplies
// its body in another object at LINK time is outside what any stage of this pass
// can inspect — the same boundary every emitter already stands on (a user object
// defining `cq_template_add_i32_hl` hijacks every lowering in the tree, the
// oracle's included). Reaching it needs a pre-supplied reserved-name twin AND a
// link-time object (r1A F-r1A-2's class).
//
// WHAT THE ANSWER LICENSES, precisely: that after `C` returns, `V` holds the basis
// label it held before `C` ran. It says nothing about ENTANGLEMENT — the clone's
// fresh result rail is a function of `V`'s label and stays correlated with it —
// and nothing more is needed by either caller: an out-first `_unc` is a
// LABEL-ONLY READER (the `routeGroupFullyInside` argument in Uncomputation.cpp),
// so a gate that leaves `V`'s label alone cannot disturb an adjoint that reads
// `V` later, and a read-only consumer has finished with `V` once it has run.
// Transient writes that the body undoes (a `cqrt_x` bracket pair) would ALSO
// preserve the label at the boundary; they are refused anyway, because proving
// the pairing is a second argument this predicate does not make.
//
// L3 — the THIRD predicate that meets the same gate is `Uncomputation`'s
// moved-anchor clause-(d) scan in `reverseTerminalGroup`, which asks
// `isInPlaceGateOn` and so ALREADY treats EVERY clone call as not mutating its
// operands — an UNSTATED premise about clone bodies. For a body the specializer
// SYNTHESIZES, what holds is LABEL PRESERVATION AT THE CALL BOUNDARY: the Bennett
// wrap reverses every gate it applies, and `inBennettClone` keeps M-C's in-place
// gates out. ⚠ That is NOT the same as "every use is a (B1)–(B4) shape", which the
// first spelling of this sentence claimed (r1A F-r1A-7): a `_Bool`-condition clone
// select may BRACKET the formal with a `cqrt_x` pair (restored before return),
// which this predicate refuses although the label is preserved at the boundary.
// It does NOT hold by construction for a PRE-SUPPLIED `_unc` twin, which
// `Specialization::ensureTwin` reuses verbatim and `buildClone` records like any
// other (the `spec_leak_clone_read_twin_*.ll` family are such bodies, refused
// here). The scan is left as it is — it is the whole-DAG spine, not the interior
// partition bd rhk5 is about — and the gap is noted on bd `jj3o`.
bool cloneCallPreservesArg(const llvm::CallInst *C, const llvm::Value *V,
                           const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CHAIN_WALK_H_
