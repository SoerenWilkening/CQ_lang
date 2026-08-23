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
class Value;
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

// `inBennettClone` (bd 20xt.5.2, the PredMux `ClaimAll` claim only) BYPASSES the
// coherent-escape no-cloning fence: inside a Phase-6 specialization clone the
// Bennett wrap copies the return out to a fresh basis rail and reverse-plays the
// whole forward stream (the qram-load `_unc` + the index), so a read whose value
// escapes to the clone ret is SOUND — the same bypass `lowerQramReads` applies at
// the emitter, threaded here so claim and emit cannot diverge (Rule 14). The
// carve/signpost callers pass false and keep the fence (a real top-level escape).
// `OutIndexBecomesOpaque` (bd 20xt.7, optional): when non-null, receives whether a
// CLAIMED read's index is currently untainted — i.e. region-internal-phi-derived, so
// the flatten + `lowerCloneSelect` lower it to an opaque `cqrt_alloc_i64` handle the
// emitter's bounds re-proof cannot see. The E4 Provable-pow2 clone-read mask uses it
// to mask ONLY that opaque case (a source-masked, already-tainted Provable index
// keeps its raw op and is re-proven directly — masking it would be a redundant
// double-`and`). Meaningless for a `No` verdict.
QromClaim classifyQromReadUnderControl(
    llvm::LoadInst *LI, const TaintSet &taint, llvm::DominatorTree &DT,
    llvm::LoopInfo &LInfo, uint64_t *OutCount = nullptr,
    const llvm::SmallPtrSetImpl<llvm::BasicBlock *> *Region = nullptr,
    bool inBennettClone = false, bool *OutIndexBecomesOpaque = nullptr);

// bd q2wk (3c6m.14 Inc 5) — "will the PredMux flatten TAINT this currently
// untainted value?": true iff `V` is already tainted, or is a region-internal
// instruction transitively derived from a region-internal PHI (which
// `convertPhis` rewrites onto the tainted edge predicates). This is the SAME
// predicate the Inc-3 QROM index gate uses, exported so PredMux's E6
// classical-branch gate cannot drift from it (Rule 14). PredMux use: PRD §4.4b
// rule (B) — a branch condition that is a re-materialized tainted control
// decision (an all-constant i1 phi, or a compare over a phi-derived scale
// accumulator) is NOT classical control inside a tainted region.
// `RegionEntry` (bd q2wk Rule-13): the claimed region's ENTRY block — and, by its
// presence, the caller's opt-in to the PRECISE question "will this phi actually
// convert to a TAINTED value?" rather than the historical "is it a region-internal
// phi?". Both fences at the definition are gated on it. PredMux's E6 gate passes
// `R.Entry` because its residual would WIDEN the accept surface past the argument
// that justifies it. The Inc-3 QROM index gate passes nothing and genuinely keeps
// the historical looser answer: its residual is benign by that increment's own
// design (an index that stays classical simply makes the speculated read a plain
// classical in-bounds load), and the delta Rule-13 round MEASURED that tightening
// it un-claims an all-equal index phi and turns a separately-cleared Inc-3 accept
// into an `E4-gep` decline — safe, but not this increment's business.
//
// So: a caller that passes an entry gets "admitted ⇒ tainted after the flatten"
// as a real invariant (up to the two documented over-declines); a caller that
// passes null does NOT, and must not lean on it.
bool valueWillTaintAfterFlatten(
    const llvm::Value *V, const TaintSet &taint,
    const llvm::SmallPtrSetImpl<llvm::BasicBlock *> &Region,
    const llvm::BasicBlock *RegionEntry = nullptr);

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

// bd k710 — DEAD VOLATILE SCALAR STORE elimination: the write-only sibling of the
// two folds above (curation, runs immediately after them in BOTH pipeline entry
// points). Erases a static scalar alloca whose EVERY user is a direct non-atomic
// exact-type store with the alloca as the POINTER operand, or a lifetime marker —
// so ZERO loads, and the address demonstrably never escapes — provided at least
// one access is volatile. Stores, markers and alloca go; THE STORED VALUE STAYS.
//
// GROUND: the fenv ruling (owner 2026-08-10, CLAUDE.md "Scope of the semantic
// model"). CQ does not model FP exception flags, and a volatile access to a
// non-escaping function-local is not observable — so the store is dead, full stop.
// *** Do NOT cite the zco4 rationale at :222-226 ("volatile's only effect is to
// defeat FP reassociation") for this stage: it is FACTUALLY WRONG for this idiom
// family. *** openlibm's `volatile float u = x*x; /* underflow */`
// (ld80/s_nexttowardf.c:63, `u` never read) exists to force the multiply so the
// FPU raises FE_UNDERFLOW, not to block reassociation.
//
// *** THIS STAGE ERASES ONLY THE STORE, BUT THE PIPELINE USUALLY LOSES THE
// COMPUTATION TOO — AND THAT IS RULED, NOT ACCIDENTAL. *** Once the store is gone
// the stored value is trivially dead, and PredMuxFlatten.cpp:2618's pre-existing
// `RecursivelyDeleteTriviallyDeadInstructions` removes it (a cleanup that exists
// for its own Rule-6/8 reason: a dead TAINTED op left alive lowers to a forward
// gate that is never uncomputed and never freed). Measured on the motivating
// cell: the shipped `slice_libm_ld80_nexttowardf` trace contains ZERO
// `fmul_f32`. Do not write "we only delete the store" in a summary — it is true
// of this function and false of the pass, and the ruling was first requested on
// exactly that too-comfortable phrasing before being re-affirmed on the measured
// facts.
//
// ASYMMETRY WORTH KNOWING BEFORE READING A TRACE: with NO enclosing tainted
// control flow the dead product IS lowered, uncomputed and freed — a useless but
// harmless gate pair, pinned by lowering_volatile_scalar_deadstore.ll — because
// nothing invokes that DCE path. Inside a PredMux region it is deleted outright.
// Both are sound under the ruling; they are not the same circuit.
//
// WHY NOT just relax promoteVolatileScalarLocals' `Loads.empty()` clause at
// QramLowering.cpp — the obvious-looking one-token fix, and it is wrong (bd k710
// comment 2026-07-30): with zero loads there is nothing to PROMOTE, so
// PromoteMemToReg would merely delete the store, silently changing that stage's
// "promote a volatile accumulator" contract (bd zco4, :201-229) into "delete dead
// volatile stores" and making its gate 5 `everyLoadIsStoreDefined` VACUOUS. Two
// contracts in one stage is how a gate stops being checkable, so this is its own
// narrowly-named stage.
//
// STRUCTURALLY RARE, and that is the design: every compiling sibling of the
// motivating cell (nextafter{,f,l}, nexttoward) READS its volatile scalar at BOTH
// underflow sites, so no sibling alloca is ever store-only and existing promotion
// claims them. Anything short of the proof is left byte-untouched for the existing
// loud declines (ACCEPT-ONLY, emits no diagnostic — the foldVolatileConstAllocaLoads
// precedent). Returns true if anything was erased.
bool eraseDeadVolatileScalarStores(llvm::Module &M, const TaintSet &taint);

// bd zco4 — volatile scalar-local SSA promotion: the mem2reg sibling of
// foldVolatileConstAllocaLoads above. The etiq fold folds a single-CONSTANT-store
// volatile scalar to its constant; this generalizes to a MULTI-STORE COMPUTED
// accumulator (the OpenBSD/Moshier "***CAUTION***" idiom `volatile long double z`
// in e_log10l.c: an anti-reassociation guard on a private non-escaping scalar).
// clang's own mem2reg never promotes a volatile access, so the store/load pair
// survives -O1 and a tainted stored value declines at kMsgStore (or blocks a
// tainted region at PredMux E4). For an alloca whose EVERY gate holds — a single
// INTEGER/FP SCALAR (never an array/struct/vector: those are the Shadow/MUX-EXCH /
// promoteFp80Union domains), address NEVER escaping (every user a direct
// non-atomic load/store of the alloca at the EXACT allocated type, or a
// lifetime/droppable intrinsic — no gep/call-arg/ptrtoint/cast/phi/select/cmp on
// the address), ≥1 VOLATILE access (else clang mem2reg already promoted it —
// nothing to do), EVERY load proven defined (dominated on all paths by a store, so
// promotion never invents an undef), and the FUNCTION not calling a
// returns_twice/setjmp routine (whose volatile-liveness contract promotion would
// break) — this clears isVolatile on the alloca's loads/stores and runs LLVM
// PromoteMemToReg. The result is EXACTLY the SSA clang's mem2reg would build for
// the same body with `volatile` removed (per-alloca, deterministic, no aliasing —
// direct accesses only), so the transform maps the volatile idiom to IR the pass
// already adjudicates (compile-correct or loud-decline); dropping volatile is the
// same deliberate, idiom-invited choice etiq established (a private non-escaping
// scalar has no external observer — volatile's only effect is to defeat FP
// reassociation, which taint lowering never does — so the "***CAUTION***" order is
// preserved). Anything short of ANY gate is left byte-untouched for the existing
// loud declines (Prime Directive; ACCEPT-ONLY, emits no diagnostic). Promotion
// mints tainted SSA (the accumulator's stored value flows to its loads), so the
// caller RE-PROPAGATES taint after a true return (the promoteFp80Union fixpoint
// precedent). Returns true if anything promoted.
bool promoteVolatileScalarLocals(llvm::Module &M, const TaintSet &taint);

// bd 20xt.4 — the taint-blind STRUCTURAL const-global QROM-read shape, the shared
// truth for the Phase-6 spec-clone ADMIT paths (`scanBody` in SpecializeReject and,
// Inc 2, `isSpeculatableDataflow` in PredMuxFlatten). True iff `LI` is a simple load
// whose pointer is a single-use canonical gep off a constant-initialised `[N x cell]`
// global (N>0, scalar cell of a qram-cell width). Reuses the SAME structural helpers
// `matchQramAccess` calls (`matchAddressGep`/`walkPtrOrigin`/`isDirectOriginPtr`), so
// the admit can never STRUCTURALLY diverge from the emitter's `classifyQromRead`
// (Rule 14). TAINT-BLIND + DT/LInfo-free: the index-taint, straight-line/loop AND
// bounds proofs are DEFERRED to the emitter (`lowerQramReads` under the clone's
// `cloneTaint`, where the index IS tainted and the intra-clone flatten has masked it).
bool qromReadShapeInScope(const llvm::LoadInst *LI);

// Lower every accepted const-global tainted-index READ in `M`. Runs BEFORE
// `lowerRotations` (pre-RAUW SSA identity, the control/IO precedent): the emitted
// index operand is the still-tainted source value, which the rotation/opcode RAUW
// later rewrites to its i32 handle. An accepted-shape read whose element width has
// no reversible copy (fp/i128) declines LOUDLY here.
//
// `inBennettClone` (bd 20xt.4): when lowering INSIDE a Phase-6 Bennett clone body,
// SKIP the coherent-return no-cloning fence (`kMsgQramCohEscape`). That fence exists
// only for the TOP-LEVEL `return tbl[q]` shape, where the raw entangled load value
// escapes with no copy-out and the whole-DAG uncompute later dirty-frees the local
// index (dephasing the carrier). In a clone the escape is handled correctly by the
// Bennett wrap: the return is COPIED OUT to a fresh basis rail BEFORE the reverse,
// and the reverse uncomputes the ENTIRE forward stream (the qram load `_unc` AND the
// index) so the copied-out value is a clean basis function of the borrowed inputs
// (Bennett's theorem — sound). The wrap is what makes the escape lowerable, so the
// top-level fence is vacuous here; every OTHER gate (width, taint, straight-line)
// still applies. Default false keeps the top-level entry points unchanged.
void lowerQramReads(llvm::Module &M, WidthDispatch &wd, TaintSet &taint,
                    bool inBennettClone = false);

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
