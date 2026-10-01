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
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"

#include <cstdint>
#include <optional>

namespace llvm {
class AllocaInst;
class BasicBlock;
class DominatorTree;
class Instruction;
class LoadInst;
class Loop;
class LoopInfo;
class Module;
class SCEV;
class ScalarEvolution;
class StoreInst;
class Type;
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

// bd test_C_libtooling-r2j3.2 — THE REGISTERS A QRAM ACCESS READS AT ITS OWN
// POSITION. A QRAM call reads its index (and a store its value) when it runs, at
// the access, so `declineStaleRecordOps` asks the pure-op stale question about
// these values with the access as the emission point. True iff `I` is a QRAM
// access; `Reads` receives its tainted read operands (APPENDED, not cleared):
//   * the pre-emission form — a `load`/`store` through a canonical tainted-index
//     address gep (`matchAddressGep`): the register the emitter will read as the
//     index (`qramIndexRegister`, the strip `resolveQramIndex` applies), and the
//     stored value;
//   * the emitted form (the post-lift re-sweep runs after both emitters) — a
//     `cqrt_qram_load_*` / `cqrt_qram_store_*` call: every tainted argument.
// Pure analysis (no mutation).
bool qramAccessReads(llvm::Instruction &I, const TaintSet &taint,
                     llvm::SmallVectorImpl<llvm::Value *> &Reads);

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
// bd fn1q increment 4, Rule-13 round 1 P1 — "is this load a QROM-SHAPED table read
// whose index is tainted NOW or WILL BE tainted once the flatten converts the
// region's phis to selects?" PredMux's classical-table admission must refuse every
// such load: it is reached only after `classifyQromReadUnderControl` said No, and
// one of QROM's No reasons is the coherent-escape NO-CLONING fence. Without this,
// a QROM read refused for no-cloning is laundered through the classical arm and
// `cqrt_qram_load_<W>` is emitted on a superposed, never-freed index rail. See the
// definition for the measured witness.
bool qromShapedReadTaintsIndexAfterFlatten(
    llvm::LoadInst *LI, const TaintSet &taint, llvm::DominatorTree &DT,
    llvm::LoopInfo &LInfo, const llvm::SmallPtrSetImpl<llvm::BasicBlock *> &Region,
    const llvm::BasicBlock *RegionEntry);

// bd fn1q increment 4 — the SAME known-bits in-bounds proof QROM's `Provable`
// verdict uses, exported for PredMux's E4 CLASSICAL-table-read admission. It does
// NOT require a tainted index or a qram cell width (see the definition): those are
// QROM's own preconditions, not the bounds proof's. Rule 14 — one spelling.
bool classicalTableIndexKnownInBounds(llvm::LoadInst *LI, const TaintSet &taint,
                                      llvm::DominatorTree &DT,
                                      llvm::LoopInfo &LInfo);

// bd xdu2.4 — the runtime-alloca sibling of the bounds proof above, for a
// CLASSICAL load speculated within its enclosing loop.  This is not QRAM: both
// the address index and the loaded value remain classical.  The proof accepts
// only a direct `alloca cell, extent`, allocated before the loop, with an
// untainted extent and affine non-wrapping 0,+,1 index whose exact loop trip
// count is semantically equal to that extent at the speculation point. Failure
// to prove any conjunct leaves PredMux's existing loud E4 decline in place —
// ⚠ UNLESS (bd xdu2.8) the arm-guarded sibling
// `classicalRuntimeAllocaReadIsInBoundsUnderGuard` (GuardedClassicalRead.h)
// proves the read in bounds under a CLASSICAL conjunct of the arm's own path
// condition, in which case E4 admits it on condition that the flatten rewrites
// its address to a bounds-checked select. This predicate's answer is unchanged.
bool classicalRuntimeAllocaReadIsInBounds(
    llvm::LoadInst *LI, const TaintSet &taint, llvm::DominatorTree &DT,
    llvm::LoopInfo &LInfo, llvm::ScalarEvolution &SE,
    const llvm::BasicBlock *RegionEntry);

// bd xdu2.8 — the two halves of the proof above, exported so the GUARDED sibling
// (`GuardedClassicalRead.h`) asks the same structural questions with the same
// answers (Rule 14). `runtimeAllocaReadShape` is every conjunct that does not
// depend on the bound relation (direct runtime-alloca origin, classical extent
// and index, scalar cell, alignment, liveness at the region entry terminator);
// `unitCounterTrips` is the loop half (a {0,+,1} non-wrapping counter of the loop
// enclosing `RegionEntry`, returning that loop's exact trip count, or null).
struct RuntimeAllocaRead {
  llvm::Value *RawIndex;
  llvm::Value *Extent;
  llvm::AllocaInst *AI;
};
std::optional<RuntimeAllocaRead> runtimeAllocaReadShape(
    llvm::LoadInst *LI, const TaintSet &taint, llvm::DominatorTree &DT,
    const llvm::BasicBlock *RegionEntry);
const llvm::SCEV *unitCounterTrips(const llvm::LoadInst *LI,
                                   const llvm::Value *RawIndex,
                                   llvm::LoopInfo &LInfo,
                                   llvm::ScalarEvolution &SE,
                                   const llvm::BasicBlock *RegionEntry);

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
// idiom (`static volatile double twom1000`, `*(volatile double *)&atanlo[3]`).
// GROUND (owner ruling 2026-09-26, bd memory `owner-ruling-volatile-unreachable-object-2026-09-26`):
// a volatile access to an object NOTHING OUTSIDE THE PROGRAM CAN REACH is not
// observable in CQ's model — internal linkage (or function-local), never written,
// address never escaping, no atomic access, and NOT in a named section or at an
// absolute/fixed address (that is how MMIO is declared). Each conjunct is a gate
// here. ⚠ Round 4 wrote "Every conjunct is a gate here" when it had added only the
// EXPLICIT section and the absolute symbol; `#pragma clang section bss=/data=/
// rodata=/relro=` sets an IMPLICIT section `hasSection()` does not see, and an MMIO
// `static volatile int STATUS;` under the pragma still folded (bd `qce6`, r4B
// F-YB-1). Since round 5 the gate is: explicit section, implicit section
// (`hasImplicitSection()` — CONSERVATIVE: any pragma attribute, whether or not the
// object's section kind makes the backend honour it, bd `ad35`), absolute symbol,
// and — owner decision 2026-09-27,
// conservative — any NON-DEFAULT ADDRESS SPACE (device memory). Pins:
// `lowering_reject_volatile_global_{section,absolute_symbol,pragma_bss,pragma_data,
// addrspace}.ll`. ⚠ The sentence that stood here —
// "the volatile qualifier exists purely to defeat classical FP folding …, and fenv
// is out of scope project-wide" — was an agent-authored over-generalisation (L7):
// the 2026-08-10 fenv ruling spoke of FUNCTION-LOCAL objects, and "why the author
// wrote `volatile`" is not a licence. The proof makes load == initializer on every
// execution, so the fold is exact; anything short of the proof (external linkage,
// any store, any escaping user, atomic, a named section — explicit or pragma-implied —,
// an absolute symbol, a non-default address space, a type the initializer cannot
// produce at that offset) is left untouched — the existing
// loud declines own it. Folded loads are CLASSICAL (constant address). ⚠ But the
// stage does not leave taint unaffected (bd vsfp round 3, bd otam / stl3): an arm
// the fold EMPTIES is folded by `deleteDeadCones` (the empty-arm fold its three
// siblings run), and a two-entry φ under a QUANTUM condition becomes
// `select %taintedCond, …` — a NEW tainted value. The caller re-`propagate`s
// whenever this returns true (both entry points). Returns true if anything
// folded.
bool foldVolatileConstGlobalLoads(llvm::Module &M, const TaintSet &taint);

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
// values are CLASSICAL. ⚠ FALSE SINCE bd vsfp ROUND 2, and the source of bd otam
// (Rule-13 r2A F-WA-1/F-WA-2): this used to read "taint is unaffected and no
// re-propagate is needed". Round 2 gave the stage `deleteDeadCones(…, Emptied)`,
// whose empty-arm fold turns a two-entry φ under a QUANTUM condition into
// `select %taintedCond, …` — a NEW tainted value — and both call sites ignored
// the return. A classical consumer then computed with a `%out` rail handle and a
// user `cq_measure` vanished (r2A `stale4`). The caller now re-`propagate`s
// whenever this returns true. Anything short of the proof is left untouched for
// the existing loud declines. Returns true if anything folded.
bool foldVolatileConstAllocaLoads(llvm::Module &M, const TaintSet &taint);

// bd k710 — DEAD VOLATILE SCALAR STORE elimination: the write-only sibling of the
// two folds above (curation, runs immediately after them in BOTH pipeline entry
// points). Erases a static scalar alloca whose EVERY user is a direct non-atomic
// exact-type store with the alloca as the POINTER operand, or a lifetime marker —
// so ZERO loads, and the address demonstrably never escapes — provided at least
// one access is volatile. Stores, markers and alloca go, and — since bd vsfp
// round 2 (bd qjoc) — so does the stored value's DEAD cone (see below).
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
// *** THIS STAGE ERASES THE STORE AND THE COMPUTATION THAT DIES WITH IT — AND
// THAT IS RULED, NOT ACCIDENTAL. *** (bd test_C_libtooling-qjoc, bd vsfp round 2.)
// Once the store is gone the stored value is dead, and the stage deletes its dead
// cone with the pass's ONE liveness predicate (`DeadValueLiveness.h`: never a
// root, so never a user's `cq_theta`/`cq_measure` and never a call that may have
// side effects). The fenv ruling licenses exactly this ("the computation then
// usually disappears too, and the ruling accepts that"). Measured on the
// motivating cell: the shipped `slice_libm_ld80_nexttowardf` trace contains ZERO
// `fmul_f32` (there PredMux's cleanup used to take it; now this stage does).
//
// ⚠ WHAT THIS PARAGRAPH SAID BEFORE, AND WHY IT WAS FALSE (L7, corrected at the
// source). It said that with no enclosing tainted control flow "the dead product
// IS lowered, uncomputed and freed — a useless but harmless gate pair … Both are
// sound". Two measured counter-examples (bd qjoc; bd vsfp Rule-13 r1B F-VB-7):
// a dead 4.4 data SELECT got its `%out` which-path rail minted and never
// discharged (silent dephasing of a later `Ry` on the condition register), and a
// dead TEMPLATE product whose source later took a non-diagonal gate was left
// DIRTY, not uncomputed (warned, lyyf-(B)). CLAUDE.md's owner-ruled fenv section
// carries the same "Both are sound" sentence; it is FLAGGED to the owner in the
// bd vsfp round-2 record (TRACK_VSFP §6), not edited here. The circuit is now
// the same inside and outside a region: the dead computation is gone.
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
//
// ⚠ THE STAGE GROWS THE TAINT SET, AND ITS CALLERS OWE A RE-`propagate` (bd otam,
// bd vsfp Rule-13 r2A F-WA-1). An arm this stage EMPTIES is folded by
// `deleteDeadCones`, and a two-entry φ under a QUANTUM condition becomes
// `select %taintedCond, …` — a new tainted value. Round 2 ignored the return at
// both call sites; a later classical consumer then computed with the select's
// `%out` rail handle and a user `cq_measure` vanished (r2A `stale3c`, `loop2`).
// Both entry points now re-`propagate` whenever this returns true, and
// `declineStaleTaintSet` re-derives the taint set before `detectSpecializations`
// so a future stage that forgets is LOUD.
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
//
// bd vsfp round 2 (r1B F-VB-1 `v29c`): after promotion, the promoted stores'
// values are handed to `deleteDeadCones` (`DeadValueLiveness.h`). An idiom such
// as `volatile char z = a; char w = z; return … + (w - w);` leaves the stored
// `trunc` DEAD once the loads are replaced; the residue is deleted so no stage —
// the dead-argument drop that runs after this one, or the lowering — sees a dead
// tainted op as a reader.
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


// ── bd `xdu2` / L-1a Increment W1: the rail-bank CARVE CLASSIFIER ───────────────
//
// A RAIL BANK is a bounded, non-escaping local array whose cells each hold ONE
// quantum rail, written once per trip of a classically-bounded loop:
//
//     bool b[N];                                  //  or `= {0}`
//     for (int i = 0; i < N; ++i) {
//       if (a >= 3) b[i] = cq_theta(b[i], .5);    //  the per-trip rail
//       if (b[i]) a -= 3;
//     }
//
// The full L-1a pipeline now consumes `Bank`: the promoter removes partial cell
// reads, the marker supplies the bank taint rule, fixed narrow cells are rewritten
// to handle storage, and D5 admits the final parked-handle store. xdu2.4 extends
// that same contract to an at-most-once runtime `alloca i32, extent`; i32 already
// matches the handle ABI, so only the marker is needed. This remains a rail bank,
// never QRAM: its extent and every cell index are classical.
//
// ⚠⚠ AND IT APPLIES TO `Bank` ONLY. `BankRaw` MUST KEEP DECLINING, IN EVERY FUTURE
// HALF (bd `test_C_libtooling-de8n`, P1, closed 2026-09-15). Before clause C7
// existed there was ONE accept-shaped verdict and the trigger above turned it into
// the accept — but that verdict did **not** imply the shape the type rewrite can
// serve, and the gap was reachable from plain `-O1` C (three families, MEASURED:
// a second bank loop with no dedicated preheader, an in-loop whole-array re-zero,
// in-loop lifetime markers — each `carve=[Bank] promo=0` on the 2026-09-15 ORACLE
// `0e280fc6`). On such a bank the per-trip cell is still read INSIDE the loop and
// that read is PARTIALLY AVAILABLE (`SCOPE_L1a.md` §0 H3), so the rewrite would
// make it read handle `0` — a LIVE RAIL. C7 is the separation, and the invariant
// the tree now relies on is: **the promoter's INPUT is `BankRaw`, its OUTPUT is
// `Bank`.**
//
// ⚠ SECOND RETIREMENT TRIGGER — `railBankCarveVerdict` is a PURE PREDICATE and
// must stay one. It mutates nothing, mints no metadata and GROWS NO TAINT, which
// is the whole of its round-2 (L1) answer: `adjudicateTaintDelta` re-runs
// `declineTaintEscapes`, and `repropagateControlMerges` goes through that, so the
// verdict is re-asked at the fixpoint automatically in BOTH entry points and a
// relaxation here is symmetric by construction. The day it acquires a side effect,
// that argument is void and the L1 question must be re-answered from scratch.
//
// THE CLAUSES (SCOPE_L1a §2; C2′ and C6 are new and both are Prime-Directive
// load-bearing):
//   C1  one non-escaping local object per function activation: either a fixed
//       `alloca [N x cell]` or xdu2.4's `alloca i32, extent`, with a provable zero
//       initializer or — owner ruling D1, 2026-09-14, composing with bd `z9t1` —
//       NO initializer at all. EVERY user is a canonical cell access, a lifetime
//       marker or that initializer. Entry placement is not required; allocation
//       in a CFG cycle is refused because it creates a fresh object per cycle
//       activation. Supporting that physically-valid case is increment C, not a
//       permanent semantic boundary.
//   C2  every access is a CLASSICAL-index cell access. A TAINTED index is 7.5's
//       axis and keeps 7.5's own decline — enforced by ORDER (this verdict is
//       consulted only after `qramCarveVerdict` has answered `NotQram`) AND by an
//       explicit entry conjunct, so the two axes cannot merge by accident.
//   C2′ INJECTIVITY. The cell index must be an affine, NON-SELF-WRAPPING `{0,+,1}`
//       add-recurrence of the enclosing loop. A fixed bank needs a proven constant
//       trip count ≤ N; a runtime bank needs its exact symbolic trip count equal
//       to its untainted extent. The walk loop must not itself be re-executed by
//       an enclosing one.
//       *Why it is load-bearing:* if two activations write one cell, a later trip's
//       SEED load reads a previously-stored HANDLE and the promoter forwards the
//       wrong value.
//       ⚠ THE `getParentLoop()` HALF WAS AN OVER-ACCEPT THIS INCREMENT SHIPPED AND
//       THEN CAUGHT ITSELF (`for (k<2) for (i<3) b[i] = cq_theta(b[i], .5);`
//       classified `Bank`, with 18 fixtures green, the corpus clean and the
//       injection matrix 29/29). **The lesson is L2's**: every other conjunct of
//       C2′ is a statement about ONE ACTIVATION of the walk loop and says nothing
//       about how many times that loop RUNS. When a proof is complete, ask what
//       OTHER closure re-runs it.
//   C3  the stored value is tainted and the cell width has a REVERSIBLE COPY —
//       `widthHasReversibleCopy`, NEVER `abiWidthFromType(...).empty()`: `i128` has
//       a width string and no copy (`OpcodeSupport.h`), and an fp cell has a width
//       and no `cqrt_copy_f*`.
//   C4  no aliasing fan-out: every user of a cell address is a simple load/store of
//       the cell type through that address, and the bank has exactly ONE store.
//   C6  TOTALITY. The fixed `N` or runtime extent equals the proven trip count,
//       every in-loop read is of the cell THIS trip writes, and every other read
//       is an exact full post-loop walk — "post-loop" meaning every FEASIBLE path
//       to it passes the walk-loop header, proven by the guards' implied
//       conditions (bd xdu2.10), not by header dominance. *Why:* after handle-storage conversion a
//       never-written cell reads as handle `0`, and `h0`
//       is a LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`).
//       ⚠ C6 proves the index VISITS each cell once. It does NOT prove each cell is
//       WRITTEN — a conditional arm store visits and writes nothing. That half is
//       C7(b) (corrected 2026-09-15; the old wording said "written" and was true of
//       the promoted shape only).
//   C7  TYPE-REWRITABLE SHAPE — the `Bank` / `BankRaw` separation, and the ONLY
//       clause that is about which CONSUMER may have the bank:
//         (a) no read of the bank survives INSIDE the walk loop (the §0 H3
//             partially-available second load — the promoter removes these); and
//         (b) the store is TOTAL PER TRIP: its block dominates the latch and the
//             latch is the only exiting block, so every cell read after the loop
//             was written by the trip that owned it.
//       Both hold by construction of the per-activation promoter's output, and
//       neither is implied by C1–C6. `BankRaw` is the promoter's input; `Bank` is
//       the marker/type-rewrite input.
//
// ⚠ C4 DELIBERATELY ADMITS A CELL ADDRESS USED BY BOTH A LOAD AND THE STORE, where
// `matchQramAccess`'s `GEP->hasOneUse()` would refuse it — and that deviation is
// what lets ONE predicate serve both consumers. `hasOneUse` answers the
// TAINTED-INDEX aliasing question (two superposed addresses the tape cannot keep
// coherent); a rail bank's index is CLASSICAL, so one address is one definite cell
// and a read-modify-write of it is the customer, not a hazard. The promoter sees
// the RAW read-modify-write shape (it runs in the `-O1`-repair normaliser
// fixpoint); `declineTaintEscapes` sees the PROMOTED one-store shape.
// ⚠ CORRECTED 2026-09-15 (bd `test_C_libtooling-de8n`): this sentence used to end
// *"Both classify `Bank`"*, and after clause C7 they do not — the RAW shape is
// `BankRaw` and the PROMOTED one is `Bank`, which is the entire point of the split.
// C4's deviation is unchanged and still what lets ONE predicate serve both
// consumers; what changed is that the two consumers now get DIFFERENT verdicts,
// deliberately. MEASURED, and it is worth knowing which module a given fixture's
// anchor is really about: `lowering_railbank_bank_anchor_n3.ll` carries the RAW
// text but its `[Bank]` line names `store i8 %cq.bank, ptr %cq.bank.addr` — the
// promoter's output, because the promoter runs first.
//
// ⚠ `matchQramAccess` is NOT called, and the reason is measured, not stylistic:
// three of its gates reject EVERY rail-bank store outright (`LInfo.getLoopFor` — a
// bank store is always in a loop; `instUnderTaintedControl` — the raw arm store;
// `requireTaintedIndex`), and a fourth answers a different question (above). What
// Rule 14 is protecting — *"do not re-spell the provenance walk"* — is honoured:
// `walkPtrOrigin`, `isDirectOriginPtr` and `matchAddressGep` are all CALLED, which
// is why this classifier lives in the QRAM TU beside them. The four conjuncts that
// ARE replicated (the pun fence, the origin-array/cell-type agreement, `N != 0`,
// scalar cell) are cross-referenced in both directions at the definition.
enum class RailBankCarve {
  NotBank,          // not a rail-bank cell write — fall through to the existing owners
  Bank,             // C1–C4, C2′, C6 AND C7 hold — the TYPE-REWRITABLE shape.
                    // A marked bank is owned by the rail-bank lowering.
  BankRaw,          // C1–C4, C2′, C6 hold and C7 does NOT: a rail bank the
                    // TYPE REWRITE must not see. ⚠ NOT A DECLINE (`outMsg` is null,
                    // the caller keeps its generic `kMsgStore`) and ⚠ NEVER AN
                    // ACCEPT — it is the per-activation PROMOTER'S INPUT and
                    // nothing else. See C7 and the L8 trigger above
  RejectShape,      // C1  — provenance / escape / mixed access / initializer
  RejectIndex,      // C2′ — index is not an injective {0,+,1} over the enclosing loop
  RejectWidth,      // C3  — the cell width has no reversible copy
  RejectAlias,      // C4  — the cell address fans out, or the bank has >1 store
  RejectTotality,   // C6  — extent != exact trips, or a cell no iteration visits
};

// The resolved bank on a `Bank` OR `BankRaw` verdict — handed back so no consumer
// re-derives it (Rule 14: *"ask by CALLING the one owner, never by re-deriving its
// answer"*; the drbq Inc-3 (b′) defect is a SECOND SPELLING of a predicate the tree
// already owned). It is filled for BOTH accept-shaped verdicts because the
// promoter's input is `BankRaw` and it needs the same resolved facts. Meaningless for
// every `Reject*` and for `NotBank`.
struct RailBankShape {
  llvm::AllocaInst *Alloca = nullptr;  // the bank object
  llvm::Loop *L = nullptr;             // the loop whose {0,+,1} index walks the cells
  llvm::Value *RawIndex = nullptr;     // the store address's trailing classical index
  llvm::Value *Extent = nullptr;       // VLA element count; null for fixed arrays
  llvm::Type *CellTy = nullptr;        // the cell scalar type
  llvm::StringRef ElemAbi;             // "i1" / "i8" / "i16" / "i32" / "i64"
  uint64_t Count = 0;                  // fixed N; 0 for a runtime-sized bank
  uint64_t Trips = 0;                  // fixed trip count; 0 for runtime-sized
  bool RuntimeSized = false;           // Extent is classical and equals loop trips
};

// The SINGLE rail-bank verdict — the `qramCarveVerdict` discipline, one entry point
// consulted by the carve AND (bd `xdu2` Track B) by the per-activation promoter, so
// the two can never diverge. `outMsg` is non-null exactly for a `Reject*` verdict
// (a pattern-naming, source-located diagnostic the negative fixtures mirror
// CHARACTER-FOR-CHARACTER). `outShape`, when non-null, receives the resolved bank
// on `Bank` AND on `BankRaw`, and is left untouched otherwise. PURE ANALYSIS — no
// mutation.
RailBankCarve railBankCarveVerdict(const llvm::StoreInst *SI, const TaintSet &taint,
                                   llvm::DominatorTree &DT, llvm::LoopInfo &LI,
                                   llvm::ScalarEvolution &SE, const char *&outMsg,
                                   RailBankShape *outShape = nullptr);

}  // namespace cq

#endif  // CQ_IRPASS_QRAM_LOWERING_H_
