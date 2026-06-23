// QramLowering.h — Phase 7.5 Increment 1: tainted-index const-global READ.
//
// Lowers a STRAIGHT-LINE tainted-index read of a const-global table (`return
// tbl[q]`, the QROM-shaped access clang -O1 leaves as a `getelementptr` off a
// `@constant` array + `load`) to one `cqrt_qram_alloc_<W>` (array-handle birth)
// + one `cqrt_qram_load_<W>` (Toffoli-copy-out; the cell is preserved). Static-
// index memory is SROA'd away by clang and never reaches the pass (PRD-7.5 §1),
// so this fires ONLY for the dynamic index the optimizer cannot scalarize.
//
// The accept predicates `isAcceptedQromLoad` / `isAcceptedQromGep` are the SHARED
// truth consulted by BOTH the `declineTaintEscapes` carve-out (so the escape
// guard does not decline a read we own) AND the emitter (so carve and emit can
// never diverge — the `isRecognizedIOSink` discipline). The structural accept is
// deliberately NARROW (single gep directly off a const global, canonical
// array-decay form, NOT under tainted control); an accepted-shape read with an
// unsupported element width (fp / i128 cell) is still loud-declined IN the
// emitter, so the carve never becomes a silent accept (PRD-7.5 §6.9).

#ifndef CQ_IRPASS_QRAM_LOWERING_H_
#define CQ_IRPASS_QRAM_LOWERING_H_

namespace llvm {
class DominatorTree;
class GetElementPtrInst;
class LoadInst;
class LoopInfo;
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// Is `LI` an accepted straight-line const-global tainted-index READ (Inc 1)? A
// simple `load` whose pointer is a single-use `getelementptr` directly off a
// `constant` GlobalVariable of array type `[N x iW]`, canonical array-decay form
// (exactly two indices: a constant-zero then the tainted element index), with the
// load NOT control-dependent on a tainted-condition branch (straight-line, §2.11)
// and NOT inside a natural loop (a QRAM access in a loop needs 7.3 bounded-loop
// unroll — it declines until then, §5/§6). The element width may be unsupported
// (fp/i128) — the STRUCTURAL shape still matches; the emitter performs the width
// gate and loud-declines.
bool isAcceptedQromLoad(const llvm::LoadInst *LI, const TaintSet &taint,
                        llvm::DominatorTree &DT, llvm::LoopInfo &LInfo);

// Is `GEP` the address-gen of an accepted QROM read (its sole user is an accepted
// QROM `load`)? Used by the `declineTaintEscapes` carve to skip the gep's escape
// decline alongside its load.
bool isAcceptedQromGep(const llvm::GetElementPtrInst *GEP, const TaintSet &taint,
                       llvm::DominatorTree &DT, llvm::LoopInfo &LInfo);

// Lower every accepted const-global tainted-index READ in `M`. Runs BEFORE
// `lowerRotations` (pre-RAUW SSA identity, the control/IO precedent): the emitted
// index operand is the still-tainted source value, which the rotation/opcode RAUW
// later rewrites to its i32 handle. An accepted-shape read whose element width has
// no reversible copy (fp/i128) declines LOUDLY here.
void lowerQramReads(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_QRAM_LOWERING_H_
