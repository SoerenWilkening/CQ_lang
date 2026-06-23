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
class Instruction;
class LoopInfo;
class Module;
}  // namespace llvm

namespace cq {

class WidthDispatch;
struct TaintSet;

// ── Phase 7.5 Increment 3: the single carve verdict ─────────────────────────────
//
// `declineTaintEscapes` consults ONE entry point for a tainted-pointer
// `load`/`store`/`gep` (replacing the per-family `isAccepted*` predicates):
//   * `Accept`  — a QRAM-shaped access the emitter (`lowerQramReads` /
//     `lowerShadowMemory`) lowers (or width-gates to a loud cell decline);
//   * `Decline` — a QRAM-shaped access that fails a PER-ACCESS precondition; the
//     caller fires `outMsg` (a pattern-naming, source-located diagnostic — the
//     §2.8(iv) decline matrix: multi-origin, inttoptr/ptrtoint, addrspacecast,
//     dynamic-N, heap, aliasing fan-out, in-loop). The alloca-WIDE declines
//     (mixed access / escape / mid-sequence observation) stay in the emitter.
//   * `NotQram` — not a tainted-index access (a classical-address / value-tainted
//     store, or a control-region access): fall through to the GENERIC taint-escape
//     decline (`kMsgStore` / `kMsgOther`).
// The emitter classifiers share the SAME `matchQramAccess`, so the carve and the
// emit can never diverge (the Inc 1 discipline). The single-PtrOrigin provenance
// walk proves single-origin through gep chains + pointer phi/select; multi-origin
// declines (the over-accept surface — what stays rejected is forbidden by
// no-cloning / linearity, [[pointer-boundary-linearity-bennett]], not a shortcut).
enum class QramCarve { Accept, Decline, NotQram };

QramCarve qramCarveVerdict(const llvm::Instruction *I, const TaintSet &taint,
                           llvm::DominatorTree &DT, llvm::LoopInfo &LInfo,
                           const char *&outMsg);

// Lower every accepted const-global tainted-index READ in `M`. Runs BEFORE
// `lowerRotations` (pre-RAUW SSA identity, the control/IO precedent): the emitted
// index operand is the still-tainted source value, which the rotation/opcode RAUW
// later rewrites to its i32 handle. An accepted-shape read whose element width has
// no reversible copy (fp/i128) declines LOUDLY here.
void lowerQramReads(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

// ── Phase 7.5 Increment 2: alloca-backed mutable array (Shadow-shaped) ──────────
//
// Lowers a STRAIGHT-LINE tainted-index store/load through an `alloca [N x iW]`
// (const N) — the `arr[q]=v` / `arr[p]` shape clang -O1 leaves once a dynamic
// access forces the alloca to survive — to one `cqrt_qram_alloc_<W>` (a TAINTED
// in-place-mutated register the uncompute spine reverses) + `cqrt_qram_store_<W>`
// (void in-place on the array handle; the backend owns the per-store tape) +
// `cqrt_qram_load_<W>` (Toffoli-copy-out). A dead scratch array's stores reverse in
// strict LIFO (`cqrt_qram_store_<W>_unc`); an escaped/measured array reverses
// nothing (§2.7). The array handle is a classical resource token, never freed
// (§2.9). Static-index memory is SROA'd away by clang (PRD-7.5 §1). Inc 3 widens
// the accepted pointer shape to flat element geps and single-origin pointer
// phi/select (the realistic indirected-access form) via `qramCarveVerdict`.
//
// Lower every accepted alloca-backed Shadow array in `M`. Runs BEFORE
// `lowerRotations` (pre-RAUW SSA identity, like `lowerQramReads`): the emitted
// index/value operands are still the tainted source values, which the
// rotation/opcode RAUW later rewrites to their i32 handles. An accepted-shape
// alloca whose element width has no reversible copy, that aliases/escapes, mixes a
// classical access, or is observed mid-sequence declines LOUDLY here.
void lowerShadowMemory(llvm::Module &M, WidthDispatch &wd, TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_QRAM_LOWERING_H_
