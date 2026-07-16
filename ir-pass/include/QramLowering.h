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

#include "llvm/ADT/SmallPtrSet.h"

#include <cstdint>

namespace llvm {
class BasicBlock;
class DominatorTree;
class Instruction;
class LoadInst;
class LoopInfo;
class Module;
class StoreInst;
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
//   * `DeferControl` (iw81.7) — a tainted-index STORE (or its address gep) that
//     sits in a depth-1 tainted-diamond arm and has the bounded-alloca Shadow
//     shape: a GuardedStoreArm candidate. SUPPRESS the pre-detection escape decline
//     (like `Accept`) so `detectControlRegions` reaches it; the control emitter
//     flattens the diamond and records the store, then `lowerShadowMemory` emits
//     the GUARDED store. If detection instead DECLINES the region (any precondition
//     miss), it fires its own loud diagnostic — so a deferred store is always
//     resolved (accept or loud decline), never a silent pass (the divergence fence).
// The emitter classifiers share the SAME `matchQramAccess`, so the carve and the
// emit can never diverge (the Inc 1 discipline). The single-PtrOrigin provenance
// walk proves single-origin through gep chains + pointer phi/select; multi-origin
// declines (the over-accept surface — what stays rejected is forbidden by
// no-cloning / linearity, [[pointer-boundary-linearity-bennett]], not a shortcut).
enum class QramCarve { Accept, Decline, NotQram, DeferControl };

QramCarve qramCarveVerdict(const llvm::Instruction *I, const TaintSet &taint,
                           llvm::DominatorTree &DT, llvm::LoopInfo &LInfo,
                           const char *&outMsg);

// iw81.7 — the shared GuardedStoreArm SHAPE predicate: is `SI` a bounded-alloca
// tainted-index Shadow store sitting in a depth-1 tainted-diamond arm (single-pred
// block whose predecessor ends in a conditional tainted `br` to {this block, the
// merge}, and whose single successor is that merge)? Consulted by BOTH the carve
// (`qramCarveVerdict` → `DeferControl`) AND the control recognizer
// (`classifyGuardedStoreArm`), so the two can never diverge (the Inc-1 discipline).
// Proves the QRAM shape with `allowTaintedControl` (the region flattens the diamond
// to straight-line before `lowerShadowMemory` runs). Pure analysis (no mutation).
bool guardedShadowStoreShape(llvm::StoreInst *SI, const TaintSet &taint,
                             llvm::DominatorTree &DT, llvm::LoopInfo &LInfo);

// ── 3c6m.14 (L6) Inc 3: const-global QROM read under tainted control ────────────
//
// The claim classification consulted by BOTH the carve (`qramCarveVerdict` →
// `DeferControl`) AND PredMux's E4 speculation gate (PredMuxFlatten.cpp), so the
// two can never diverge (the iw81.7 GuardedStoreArm discipline). A read is
// claimable iff it is a would-be QROM read blocked solely by tainted control
// (`isQromReadBlockedOnlyByControl` — shape + width + no coherent escape) AND its
// SPECULATED execution is sound: the flatten moves the gep+load out of their
// guard, so the index must be in-bounds on EVERY basis state, not merely on the
// originally-guarded path.
//   * `Provable`  — known-bits proves index < N unconditionally (the exp
//     `ln2HI[xsb]` shape: `zext(lshr hx, 31)` < 2). Speculate as-is.
//   * `NeedsMask` — unprovable, but N is a power of two: the flatten rewrites the
//     gep index to `and idx, N-1` — the identity on every in-guard basis state
//     (the guard implied idx < N there); excluded states read a garbage ROW whose
//     value the merge's ∧-with-block-predicate discards (PredMux PRD §4.4/§6.1) —
//     the atan `atanhi[id]` / folded-jumptable mechanism.
//   * `No`        — off-shape / wrong width / coherent escape / bounds unprovable
//     with a non-pow2 table. The caller keeps its loud decline.
// `OutCount` (optional) receives the table's element count when claimable — the
// flatten needs it for the mask constant. `Region` (optional, the PredMux claim
// only) widens the tainted-index gate to a currently-UNTAINTED index the flatten
// itself will taint — one that transitively depends on a region-internal PHI
// (the atan `id` phi over constants: control-dependent, data-classical; the
// phi→select conversion rewires it onto the tainted edge predicates). The
// carve/signpost callers pass no region and keep the strict tainted-index gate.
// Pure analysis (no mutation).
enum class QromClaim { No, Provable, NeedsMask };

QromClaim classifyQromReadUnderControl(
    llvm::LoadInst *LI, const TaintSet &taint, llvm::DominatorTree &DT,
    llvm::LoopInfo &LInfo, uint64_t *OutCount = nullptr,
    const llvm::SmallPtrSetImpl<llvm::BasicBlock *> *Region = nullptr);

// 3c6m.14 Inc 3 — volatile-const global-load fold (curation, runs pre-PredMux in
// BOTH pipeline entry points). Folds a VOLATILE load whose pointer strips (through
// constant offsets) to an INTERNAL, definitively-initialized global that is never
// stored and whose address never escapes (every transitive user through
// gep/bitcast — instruction or constexpr — is a plain non-atomic load) to the
// loaded constant from the initializer. This is the openlibm anti-const-fold
// idiom (`static volatile double twom1000`, `*(volatile double *)&atanlo[3]`):
// the volatile qualifier exists purely to defeat classical FP folding /
// raise-inexact elision, and fenv is out of scope project-wide. The proof makes
// load == initializer on every execution, so the fold is exact; anything short of
// the proof (external linkage, any store, any escaping user, atomic, a type the
// initializer cannot produce at that offset) is left untouched — the existing
// loud declines own it. Folded loads are CLASSICAL (constant address), so taint
// is unaffected and no re-propagate is needed (the foldIdentityBitcasts
// precedent). Returns true if anything folded.
bool foldVolatileConstGlobalLoads(llvm::Module &M);

// bd etiq — volatile-const LOCAL fold: the alloca sibling of the global fold
// above (curation, runs immediately after it in BOTH pipeline entry points).
// The openlibm rounding idiom (`volatile double vd2 = 0x1.0p32;` in s_cbrtl.c)
// keeps a volatile store + load on a classical entry-block alloca at -O1
// (mem2reg never touches volatile), and PredMux E4 admits no volatile access.
// Folds every load of a static alloca whose ONLY users are: exactly one
// non-atomic store of a Constant (pointer operand A), non-atomic exact-type
// loads each DOMINATED by that store, and lifetime markers — at least one
// access volatile — to the stored constant, then erases the loads, the store,
// the markers, and the alloca (a surviving volatile store would still block
// E4, unlike the global fold's code-free global). Direct users only, no
// through-gep tolerance (the local proof is exact-type/exact-address; a
// type-punned or offset view is off-idiom and forfeits). The single-Constant
// store gate structurally excludes tainted (shadow-QRAM) allocas; folded
// values are CLASSICAL, so taint is unaffected and no re-propagate is needed
// (the foldVolatileConstGlobalLoads precedent). Anything short of the proof is
// left untouched for the existing loud declines. Returns true if anything
// folded.
bool foldVolatileConstAllocaLoads(llvm::Module &M, const TaintSet &taint);

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
