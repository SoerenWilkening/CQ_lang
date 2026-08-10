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

// An in-place, handle-threading gate on `H` — a VOID gate that MUTATES `H` rather
// than minting a fresh handle, so it belongs to `H`'s link of the DAG. Three
// callee shapes, each with its own required arity and handle SLOT (see the .cpp):
//   * `cqrt_ry/rz_<W>(H, θ)`                          — arg 0, arg_size 2
//   * `cqrt_qram_store_<W>(H, idx, val)`              — arg 0, arg_size 3
//   * `cqrt_qram_store_<W>_controlled(flag, H, idx, val)` — arg 1, arg_size 4
// Every `_inv`/`_unc` twin fails (it is the adjoint, never a forward gate), as does
// any other `_controlled` form. THIS PREDICATE IS THE SINGLE DEFINITION OF "which
// register does this gate write": `railOf` is derived from it (bd
// test_C_libtooling-uow0), so a new shape added here is automatically attributed
// there. Callers pass a candidate handle; it does NOT test that `H` is a register,
// so `railOf` filters constants before asking.
bool isInPlaceGateOn(const llvm::CallInst *G, const llvm::Value *H);

// A `cqrt_alloc_<W>` mint — a tainted register ROOT (the DAG bottoms out here).
bool isAllocMint(const llvm::Value *V);

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
// Deliberately TAPE-ONLY: `cqrt_copy_<W>` is NOT a recorded carrier here. Its
// destination is the kept escaped/measured carrier of a method-B copy-out whose
// safety rests on an emitter-side invariant (bd 8gi5) — a separate surface bd
// 261j(a) did not rule, and including it drags the backward closure across every
// shipped QRAM golden.
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
// see `isOutputSink` above. It is not a LIVE defect here (bd 8gi5 censused all 5
// emitter sites: the only copy src the spine ever reverses is a
// `cqrt_qram_load_<W>` result, a permutation of live arr/idx, and the sxuk QRAM
// index roots are measurement-immune by QramLowering.cpp:1749-1757). The freeze
// below is deliberately NOT extended here — bd 8gi5 owns that surface.
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

}  // namespace cq

#endif  // CQ_IRPASS_CHAIN_WALK_H_
