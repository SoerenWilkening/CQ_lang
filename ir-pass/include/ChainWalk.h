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

// An in-place, handle-threading gate on `H`: an UNCONTROLLED rotation
// `cqrt_ry/rz_<W>(H, θ)` whose arg 0 IS the handle (arg_size 2). These mint no
// new handle (void), so they belong to `H`'s link of the DAG. The 3-arg
// controlled forms and `_inv`/`_unc` twins fail this predicate.
bool isInPlaceGateOn(const llvm::CallInst *G, const llvm::Value *H);

// A `cqrt_alloc_<W>` mint — a tainted register ROOT (the DAG bottoms out here).
bool isAllocMint(const llvm::Value *V);

// A `@cqrt_measure_<W>` sink (the lowered measure form Phase 5 sees). A measured
// handle is a quantum→classical sink, not a forward data consumer.
bool isMeasureSink(const llvm::CallInst *CI);

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
bool isTerminalHandle(llvm::Value *Handle, const TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CHAIN_WALK_H_
