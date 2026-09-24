// QramLowering.cpp — see header. Phase 7.5 Increment 1: tainted-index const-global
// READ (QROM-shaped) lowering.
//
// `classifyQromRead` is the single structural classifier; both the carve predicates
// (`isAcceptedQromLoad`/`isAcceptedQromGep`, consulted by `declineTaintEscapes`) and
// the emitter (`lowerQramReads`) go through it, so the carve and the emit can never
// diverge. The structural accept is NARROW; an accepted-shape read with an element
// width that has no reversible copy (fp/i128 cell) is loud-declined IN the emitter,
// so a carve is never a silent accept (Prime Directive; PRD-7.5 §6.9).

#include "QramLowering.h"

#include "OpcodeSupport.h"      // abiWidthFromType / widthHasReversibleCopy
#include "PoisonFacts.h"        // indexBoundIsPoisonConditional (bd s6ao)
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"  // bd zco4 (isAllocaPromotable / PromoteMemToReg)

#include <algorithm>
#include <cstdlib>
#include <optional>
#include <utility>

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic string the QRAM read emitter owns (PRD-7.5 §3 deliverable
// 5; the element-width gate). The negative LIT fixtures mirror it CHARACTER-FOR-
// CHARACTER (Rule 12):
//   * lowering_reject_qram_i128_cell.ll  → kMsgQramCell (a `[N x i128]` cell)
//   * lowering_reject_qram_fp128_cell.ll → kMsgQramCell (a `[N x fp128]` cell)
// As of bd 38t2 an fp cell `[N x {half,float,double,x86_fp80}]` ACCEPTS (a faithful
// reversible bit-pattern cell); only i128 (no cqrt_qram_*_i128) and fp128 (no sound
// c_type on this x86-64 build) still hit this gate.
constexpr char kMsgQramCell[] =
    "cq QRAM read: array element is not a reversible cell";

// The exact diagnostic strings the Shadow (alloca-backed store/load) emitter owns
// (Phase 7.5 Inc 2; PRD-7.5 §2.8). The negative LIT fixtures mirror each one
// CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_qram_mixed_access.ll → kMsgQramMixed  (§6.6)
//   * lowering_reject_qram_alloca_escape.ll → kMsgQramEscape (§2.8(iv))
//   * lowering_reject_qram_mid_seq.ll      → kMsgQramMidSeq  (§2.8(iii))
//   * lowering_reject_qram_nonzero_init.ll → kMsgQramInit    (§2.6/§6.5, Inc 3)
constexpr char kMsgQramMixed[] =
    "cq QRAM store: alloca array mixes a tainted-index and a classical access";
constexpr char kMsgQramEscape[] =
    "cq QRAM store: alloca array escapes to an unsupported user";
constexpr char kMsgQramMidSeq[] =
    "cq QRAM store: array is observed before its last store";
// §2.6/§6.5 (Inc 3 — the Rule-13 initializer-mis-modeling fix): the trace runtime
// models a fresh QRAM array as |0⟩ cells (`cqrt_qram_alloc_<W>` records only the
// COUNT). A `memset` with a NON-ZERO (or non-constant) fill byte seeds classical
// contents the stub cannot represent — a later `load` of an un-overwritten cell
// would read 0 in the model while the true value is the fill (verify-clean WRONG
// DATA, PRD §6 risk #5). Only a ZERO-fill memset matches the model; any other
// initializer loud-declines (the QROM read path, Inc 1, carries real const
// contents through the const-global origin instead).
constexpr char kMsgQramInit[] =
    "cq QRAM store: alloca array has a non-zero initializer the trace model cannot represent";

// Phase 7.5 Increment 3 — the pattern-naming decline matrix (PRD-7.5 §2.8(iv),
// §5/§6; the Bennett signpost model). Each names the EXACT off-pattern the
// provenance walk could not prove a single statically-shaped origin for; the
// negative LIT fixtures mirror each one CHARACTER-FOR-CHARACTER (Rule 12). These
// are fired in `declineTaintEscapes` via `classifyQramCarve` (per-access info
// suffices); the alloca-WIDE declines (mixed/escape/mid-seq above) stay in the
// emitter. What stays rejected after 7.5 is forbidden by no-cloning / linearity
// ([[pointer-boundary-linearity-bennett]]), not a CQ shortcut.
//   * lowering_reject_qram_multi_origin.ll   → kMsgQramMultiOrigin
//   * lowering_reject_qram_inttoptr.ll       → kMsgQramProvenance
//   * lowering_reject_qram_ptrtoint.ll       → kMsgQramProvenance
//   * lowering_reject_qram_addrspacecast.ll  → kMsgQramAddrSpace
//   * lowering_reject_qram_dynamic_n.ll      → kMsgQramDynN
//   * lowering_reject_qram_heap.ll           → kMsgQramHeap
//   * lowering_reject_qram_aliasing.ll       → kMsgQramAlias
//   * lowering_reject_qram_in_loop.ll        → kMsgQramLoop
constexpr char kMsgQramMultiOrigin[] =
    "cq QRAM access: pointer resolves to multiple array origins";
constexpr char kMsgQramProvenance[] =
    "cq QRAM access: pointer has no static array provenance";
constexpr char kMsgQramAddrSpace[] =
    "cq QRAM access: pointer crosses an address space";
constexpr char kMsgQramDynN[] =
    "cq QRAM access: array has no compile-time shape (dynamic-size alloca)";
constexpr char kMsgQramHeap[] =
    "cq QRAM access: array has no compile-time shape (heap allocation)";
constexpr char kMsgQramAlias[] =
    "cq QRAM access: array address has aliasing fan-out";
constexpr char kMsgQramLoop[] =
    "cq QRAM access: tainted-index memory access inside a loop";
// bd 3c6m.13 → 3c6m.14 Inc 3 — a would-be QROM read (constant-global table, tainted
// index, clean single-origin shape) under tainted control. Since Inc 3 the CLAIMABLE
// subset (index known-bits-provably in-bounds, or a pow2 table the flatten can mask —
// `classifyQromReadUnderControl`) DEFERS to PredMux/control detection and lowers; what
// remains here is the read whose SPECULATION is genuinely unprovable — no known-bits
// bound and a non-pow2 table, so no sound mask exists. This precise signpost (the
// Bennett pattern-naming model, [[pointer-boundary-linearity-bennett]]) replaces the
// retired "needs nested-control lowering" text (nested-control lowering now EXISTS;
// the honest blocker is the bounds proof), keeping the injection census pointed at
// the real wall.
constexpr char kMsgQromUnderControlBounds[] =
    "cq QRAM access: const-global table read under tainted control: index not "
    "provably in-bounds (no known-bits proof; table size not a power of two)";
// The coherent-return no-cloning fence (bug test_C_libtooling-l6xk + the sxuk
// direct-return / Inc-1 QROM-return regressions; VERIFIED physics 2026-06-24,
// memory 7-5-qram-coherent-return-nocloning). A qRAM LOAD at a superposed index
// produces a value ENTANGLED with that index (`arr[p] = [p==q]·v`, a function of
// the load AND store addresses). When such a value flows COHERENTLY (through
// tainted reversible ops, NOT through a measure/tape collapse sink) into a
// `ret` / `cq_invert` of a NON-`main` function, the whole-DAG reversal uncomputes
// and FREES the LOCAL (`cq_theta`) index rails it is entangled with — a dirty free
// (STILL TRUE OF THIS DECLINED SHAPE after bd 5pio, and worth saying because the
// sibling comment at `emitCopyOutIfDirectMeasure` now reads the other way: the 5pio
// freeze is seeded by a `cqrt_copy_<W>`, and a coherent-`ret` shape mints NO copy —
// `emitCopyOutIfDirectMeasure` returns early unless the sole direct user is a
// measure — so nothing seeds the freeze and the reversal would indeed still free the
// index rail. This decline is NOT made redundant by the freeze.)
// (= hidden measurement, Rule 6) that DEPHASES the returned carrier to a classical
// mixture (off-diagonal coherence exactly 0; reduced ρ = diag(2c²s², c⁴+s⁴)). By
// no-cloning/monogamy NO reversible circuit can return a clean coherent `arr[p]`
// once its local address is erased — leaving the index allocated only DEFERS the
// collapse (the carrier is mixed the instant the copy-out fires). So the ONLY
// correct action is a LOUD DECLINE. A MEASURE collapses the value first (immune —
// the index-free is unobservable and the diagonal IS the correct distribution);
// `main`'s `ret` is the process-exit observation. The negative LIT fixtures mirror
// this CHARACTER-FOR-CHARACTER:
//   * lowering_reject_qram_coherent_return.ll       → kMsgQramCohEscape (Shadow)
//   * lowering_reject_qram_read_coherent_return.ll  → kMsgQramCohEscape (QROM)
constexpr char kMsgQramCohEscape[] =
    "cq QRAM load: coherently escaping value is entangled with a local index (no-cloning)";

// bd 20xt.4 Inc 2 (blocker c Rule-13 fix): a QROM read inside a Phase-6 Bennett
// CLONE whose SPECULATED index is not provably in-bounds. A clone is called on
// EVERY basis state of a hoisted-under-control call (PredMux speculation), so —
// unlike a top-level FAITHFUL `tbl[q]` whose in-bounds precondition is the
// source's obligation — the clone read may be driven OOB on the basis states the
// caller's guard excluded. The under-control DIRECT read masks (pow2) or declines
// (non-pow2) exactly this via classifyQromReadUnderControl; the straight-line clone
// emitter never runs that discipline, so an unmasked-index clone read would emit an
// out-of-contract OOB `cqrt_qram_load` (frozen ABI: idx ∈ [0,N); OOB undefined).
// DECLINE unless the index is known-bits in-bounds. The accept surface TODAY is a
// SOURCE-masked / constant / otherwise-known-bits-bounded index (a genuinely
// unbounded straight-line clone read declines LOUDLY). The DESIGNED-FOR future path
// — a read the clone's OWN internal flatten masks to `and id, N-1` (atanl's
// atanhi[id]) — is not yet exercisable: a QROM-read-arm clone declines UPSTREAM at
// SpecializeReject/lowerCloneControl ("tainted control flow under quantum lift"),
// and even past that the clone-read masking accept path also needs the
// coherent-escape gate in classifyQromReadUnderControl (which returns No for a read
// whose value flows to a non-`main` ret) revisited for clone reads. Both are the
// deferred clone-control follow-up; this fence is forward-compatible — once a masked
// i64 index reaches here it is provably in-bounds and passes.
constexpr char kMsgQramCloneUnbounded[] =
    "cq QRAM load: speculated const-global table read in a specialized clone: index not provably in-bounds";

// bd `xdu2` / L-1a Increment W1 — the RAIL-BANK decline matrix. Each names the
// EXACT clause the bounded-rail-array shape failed; the negative LIT fixtures
// mirror each one CHARACTER-FOR-CHARACTER (Rule 12). They are fired by
// `declineTaintEscapes` through `railBankCarveVerdict`, the one entry point the
// carve AND the promoter share, and they REPLACE the generic `kMsgStore` for
// exactly the population this classifier claims — a decline→decline string change
// and nothing else this increment (see the header's staging note).
//
// A separate string family from `kMsgQram*` DELIBERATELY: 7.5's axis is a TAINTED
// index over classical memory, L-1a's is a CLASSICAL index over quantum cells.
// Sharing a string would merge two decline populations whose fixtures pin opposite
// accept shapes, and would make the injection census point at the wrong wall.
//   * lowering_reject_railbank_global.ll        → kMsgBankShape
//   * lowering_reject_railbank_vla.ll           -> kMsgBankWidth
//   * lowering_reject_railbank_escape.ll        → kMsgBankEscape
//   * lowering_reject_railbank_mixed_access.ll  → kMsgBankMixed
//   * lowering_reject_railbank_nonzero_init.ll  → kMsgBankInit
//   * lowering_reject_railbank_noninjective.ll  → kMsgBankIndex
//   * lowering_reject_railbank_fp_cell.ll       → kMsgBankWidth
//   * lowering_reject_railbank_nowidth_cell.ll  → kMsgBankWidth
//   * lowering_reject_railbank_alias.ll         → kMsgBankAlias
//   * lowering_reject_railbank_two_stores.ll    → kMsgBankMultiStore
//   * lowering_reject_railbank_oversized.ll     → kMsgBankTotality
//   * lowering_reject_railbank_inloop_read.ll   → kMsgBankTotality
constexpr char kMsgBankShape[] =
    "cq rail bank: cell address has no bounded local-array provenance";
constexpr char kMsgBankEscape[] =
    "cq rail bank: array escapes to an unsupported user";
constexpr char kMsgBankMixed[] =
    "cq rail bank: array mixes a rail cell access with an unrecognized one";
constexpr char kMsgBankInit[] =
    "cq rail bank: array has an initializer the rail model cannot represent";
constexpr char kMsgBankIndex[] =
    "cq rail bank: cell index is not an injective per-iteration index";
constexpr char kMsgBankWidth[] =
    "cq rail bank: array element is not a reversible rail cell";
constexpr char kMsgBankAlias[] =
    "cq rail bank: cell address has aliasing fan-out";
constexpr char kMsgBankMultiStore[] =
    "cq rail bank: array is written from more than one store site";
constexpr char kMsgBankTotality[] =
    "cq rail bank: array has cells no iteration writes";
// The two clauses ADDED by this increment's own adversarial self-attack (IMPL_A.md
// §10 H-1 / H-13). Both were MEASURED as `Bank` over-accepts on the first subject
// binary (53d1a4b6…) and both are the SAME hazard C2′/C1 name, one activation level
// up — which is why they get their own strings rather than riding an existing one.
//   * lowering_reject_railbank_nested_walk.ll   → kMsgBankNested
//   * lowering_reject_railbank_dynamic_object.ll → kMsgBankDynamic
//   * lowering_reject_railbank_dynamic_{lifetime_end,stackrestore}.ll
//                                                 → kMsgBankLifetime
constexpr char kMsgBankNested[] =
    "cq rail bank: the cell walk is re-executed by an enclosing loop";
constexpr char kMsgBankDynamic[] =
    "cq rail bank: array allocation is re-executed by an enclosing cycle";
constexpr char kMsgBankLifetime[] =
    "cq rail bank: array storage is not live at every access";

// EXACT CFG reachability, `From` executing and then `To` executing later on
// some path (bd xdu2.4, Rule-13 round F-B2). LLVM's `isPotentiallyReachable`
// gives up after 32 blocks and answers "reachable", which is safe for a fence
// but turned the cycle question into a FALSE diagnostic on an ordinary acyclic
// body with a dozen diamonds. This walk is linear in the function's edges and
// has no budget, so its "no" and its "yes" are both facts.
bool instReaches(const Instruction *From, const Instruction *To) {
  const BasicBlock *FB = From->getParent();
  const BasicBlock *TB = To->getParent();
  if (FB == TB && From != To && From->comesBefore(To))
    return true;
  SmallVector<const BasicBlock *, 32> Work(succ_begin(FB), succ_end(FB));
  SmallPtrSet<const BasicBlock *, 32> Seen;
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (!Seen.insert(B).second)
      continue;
    if (B == TB)
      return true;
    Work.append(succ_begin(B), succ_end(B));
  }
  return false;
}

// ── C6 READ ORDER, asked SEMANTICALLY (bd xdu2.10) ────────────────────────────
//
// Per-query context for `readFollowsLoopOnEveryPath`. `InCycle` is computed ONCE
// per query from LLVM's own SCC iterator (a block is in a cycle iff its SCC has
// a cycle), and `SingleValued` memoises the closure verdict per condition.
// ⚠ Rule-13 round 1 (P3-1) measured the first spelling QUADRATIC: it called the
// per-instruction reachability walk `instReaches(I, I)` for every closure value
// of every walked branch and every dominator — 7.7 s at 3000 diamonds between
// the loops where the oracle took ~0.2 s. The cost is now O(blocks + edges ×
// facts + conditions × closure-budget); the fixtures pin the verdict, not the
// time, so this note is the only guard on the complexity.
struct ReadOrderCtx {
  const TaintSet &Taint;  // a TAINTED name is never a fact nor a prune (F-1).
  SmallPtrSet<const Value *, 8> Measures;       // `taint.MeasureCalls`, as a set.
  SmallPtrSet<const BasicBlock *, 32> Reached;  // reachable from entry.
  SmallPtrSet<const BasicBlock *, 32> InCycle;  // reachable and in a CFG cycle.
  DenseMap<const Value *, bool> SingleValued;

  ReadOrderCtx(const Function &F, const TaintSet &T) : Taint(T) {
    for (const CallInst *CI : T.MeasureCalls)
      Measures.insert(CI);
    for (scc_iterator<const Function *> I = scc_begin(&F); !I.isAtEnd(); ++I) {
      const bool Cyc = I.hasCycle();
      for (const BasicBlock *B : *I) {
        Reached.insert(B);
        if (Cyc)
          InCycle.insert(B);
      }
    }
  }
};

// Is `Root` a CLASSICAL condition whose every SSA name denotes ONE run-time
// value per function activation? False if ANY value in its backward operand
// closure is TAINTED (Rule-13 round 2, F-1, P2 — see `readFollowsLoopOnEveryPath`
// step (0)). Otherwise true when every instruction in the closure is
// in a reachable block that no CFG cycle contains (so it executes at most once),
// and no `undef`/`poison` appears in it. It guards reading an SSA-level
// implication between two conditions (`isImpliedCondition`, whose matching
// treats one SSA name as one value) as an implication between the values two
// DIFFERENT branch executions saw. A closure over the budget answers "no".
//
// ⚠ THE TWO HALVES ARE NOT EQUALLY LOAD-BEARING, and saying which is which is
// the point (L7). The `undef` half IS: every USE of `undef` may read a different
// value, so `icmp ne undef, 0` twice can disagree at run time while matching
// operand-for-operand (pinned: `railbank_readorder_reject_undef_condition.ll`,
// mutant M4). The at-most-once half is a MARGIN, argued redundant and UNPINNED
// (mutants M2/M3/M11 MISSED; the full argument is `TRACK_A.md` §"at-most-once").
// Sketch (Rule-13 round 1 P3-3 corrected the first version, which argued from
// the LAST pruned edge — whose source need not be walk-reachable): consider the
// part of a counter-path AFTER the last re-execution of any definition shared
// by the fact's compare and a pruned edge's compare, and induct on the FIRST
// pruned edge that part takes. Its source is walk-reachable; the shared
// definitions dominate both compares; and the fact must be RE-EVALUATED after
// that last redefinition (splice the definition-free entry prefix onto the
// remaining part: the result is a CFG path to the read, so it passes the
// dominating fact edge). So both compares read the SAME values and the
// SSA-level implication applies to that execution.
// The at-most-once half is kept because it can only DECLINE; its cost is an
// over-decline of a guard whose operand is computed inside a preceding
// classical cycle.
bool singleValuedClosure(const Value *Root, ReadOrderCtx &Ctx,
                         unsigned Budget = 64) {
  if (auto It = Ctx.SingleValued.find(Root); It != Ctx.SingleValued.end())
    return It->second;
  auto Answer = [&](bool A) {
    Ctx.SingleValued[Root] = A;
    return A;
  };
  SmallVector<const Value *, 16> Work{Root};
  SmallPtrSet<const Value *, 16> Seen;
  while (!Work.empty()) {
    const Value *V = Work.pop_back_val();
    if (!Seen.insert(V).second)
      continue;
    if (Seen.size() > Budget)
      return Answer(false);
    // A `cq_measure` RESULT is CLASSICAL (the measurement is the sole sink), so
    // it is a LEAF of the closure: its tainted operand is never walked into
    // (Rule-13 round 3, F-2 — the round-2 binary did, and so refused every guard
    // built from a measurement, a regression against round 1). It is still
    // asked the at-most-once question like any instruction. Membership of
    // `taint.MeasureCalls` is the one owner of "is this a measure call".
    if (Ctx.Measures.count(V)) {
      const auto *MI = cast<Instruction>(V);
      if (!Ctx.Reached.count(MI->getParent()) ||
          Ctx.InCycle.count(MI->getParent()))
        return Answer(false);
      continue;
    }
    if (Ctx.Taint.Tainted.count(const_cast<Value *>(V)))
      return Answer(false);  // quantum: its branch is FLATTENED, not taken.
    if (isa<UndefValue>(V))
      return Answer(false);  // undef AND poison (PoisonValue derives from it).
    if (auto *C = dyn_cast<Constant>(V)) {
      // A ConstantExpr may carry an undef operand; walk it like an instruction.
      for (const Use &U : C->operands())
        Work.push_back(U.get());
      continue;
    }
    if (isa<Argument>(V) || isa<BasicBlock>(V) || isa<MetadataAsValue>(V))
      continue;
    const auto *I = dyn_cast<Instruction>(V);
    if (!I || !Ctx.Reached.count(I->getParent()) ||
        Ctx.InCycle.count(I->getParent()))
      return Answer(false);  // re-executed by a cycle: one name, several values.
    for (const Use &U : I->operands())
      Work.push_back(U.get());
  }
  return Answer(true);
}

// Is every EXECUTION of `Read` preceded, on its own path, by an execution of
// `L`'s header? `DT.dominates(Header, Read)` is the SYNTACTIC half of this and
// used to be all C6 asked — and `clang -O1` defeats it on the plainest runtime
// bank (`int b[n]` with no explicit `if (n <= 0) return`): each loop gets its
// OWN `n > 0` guard, the read loop's guard block is reached both from the write
// loop's exit and from the write guard's FALSE edge, so the write-loop header
// no longer dominates the read — although the read runs iff `n > 0` iff the
// write loop ran (L5: a syntactic answer to a semantic question).
//
// THE SEMANTIC QUESTION, asked with LLVM's own machinery:
//   (0) THE PREMISE, and its scope. Everything below reasons about IR CFG
//       paths, and treats an execution as one. That is true only of CLASSICAL
//       control: a branch on a TAINTED condition is FLATTENED by control
//       lowering — both successors execute, and a value arm's chain (loads
//       included) is HOISTED into the predecessor — so a tainted edge is no
//       evidence of what executes. ⚠ Rule-13 round 2 (F-1, P2) found the first
//       version trusting a tainted fact (`if ((k>0) & c) x = … b[k&1] …`, with
//       `c` a `cq_theta` result): the carve answered `Bank` for a read that runs
//       on `k <= 0` too, and only an unrelated D5 wall declined the module. So
//       a TAINTED condition is never a fact and never prunes an edge (its edges
//       are FOLLOWED), and the CALLER gives a read that lies INSIDE a tainted
//       branch's REGION (`readInsideTaintedRegion`: reachable from the branch
//       without passing its immediate post-dominator) no semantic path at all —
//       only header dominance. The taint set is the one the carve
//       is handed; the round-2 re-ask is `adjudicateTaintDelta` →
//       `declineTaintEscapes`, which re-runs the carve with the GROWN set after
//       the onward control lowering.
//   (1) FACTS. Every CLASSICAL conditional branch edge `B→S` that DOMINATES the
//       read's block (`DT.dominates(BasicBlockEdge)`) is taken on every CFG path
//       to the read, so — control being classical — its condition has that
//       edge's polarity whenever the read executes. Only a classical,
//       single-valued condition is kept as a fact.
//   (2) PRUNED WALK. Walk the CFG forward from the entry block, never entering
//       `L`'s header, and drop an edge `B→S` whose (single-valued) condition, at
//       that edge's polarity, IMPLIES (`isImpliedCondition`) the NEGATION of
//       some fact. Such an edge lies on no path that reaches the read (see
//       `singleValuedClosure` for why the two SSA names agree in time).
//   (3) If the read's block is NOT reached, every feasible path to the read
//       passes the header. The caller has already proven that `L` has a SINGLE
//       exiting block and an exact backedge count, so passing the header and
//       then leaving `L` means a COMPLETE activation — all the old dominance
//       test ever licensed. ⚠ That the exiting block IS the latch is NOT proven
//       at C6; it is C7(b)'s `WriteIsTotalPerTrip` (and the promoter's), and
//       nothing here depends on it (Rule-13 round 1, P3-2).
// Anything unproven — a `switch` edge, a multi-valued condition, no fact that
// contradicts the edge — is FOLLOWED, so the walk over-approximates the
// feasible paths and a "reached" answer is the safe decline. It CANNOT turn a
// read that some real path reaches around `L` into an accept.
//
// ⚠ WHAT THIS DOES NOT PROVE, and must not be read as proving: that the READ
// loop's trip count equals the extent (the caller's per-read SCEV clause), or
// that the write is total per trip (C7(b)). It replaces ONLY the ordering half.
bool readFollowsLoopOnEveryPath(const Instruction *Read, const Loop *L,
                                const DominatorTree &DT, const DataLayout &DL,
                                const TaintSet &taint) {
  const BasicBlock *Header = L->getHeader();
  const BasicBlock *RB = Read->getParent();
  if (DT.dominates(Header, RB))
    return true;  // the syntactic case — a special case of the semantic one.

  ReadOrderCtx Ctx(*RB->getParent(), taint);

  // (1) FACTS — (condition, polarity) of every dominating conditional edge.
  // Edge dominance is asked FIRST: a dominator whose edges do not dominate the
  // read (every diamond head between the loops) never costs a closure walk.
  SmallVector<std::pair<const Value *, bool>, 8> Facts;
  for (const DomTreeNode *N = DT.getNode(RB); N; N = N->getIDom()) {
    const BasicBlock *D = N->getBlock();
    const auto *BI = dyn_cast<BranchInst>(D->getTerminator());
    if (!BI || !BI->isConditional() ||
        BI->getSuccessor(0) == BI->getSuccessor(1))
      continue;
    for (unsigned S = 0; S < 2; ++S)
      if (DT.dominates(BasicBlockEdge(D, BI->getSuccessor(S)), RB) &&
          singleValuedClosure(BI->getCondition(), Ctx))
        Facts.push_back({BI->getCondition(), S == 0});
  }
  if (Facts.empty())
    return false;  // no fact can refute any bypass edge — the walk would reach.

  // (2) PRUNED WALK from entry, never entering `Header`.
  auto EdgeRefutesAFact = [&](const Value *Cond, bool Taken) {
    for (const auto &[FC, FPol] : Facts) {
      std::optional<bool> Imp =
          isImpliedCondition(Cond, FC, DL, /*LHSIsTrue=*/Taken);
      if (Imp && *Imp != FPol)
        return true;
    }
    return false;
  };
  const BasicBlock *Entry = &RB->getParent()->getEntryBlock();
  SmallVector<const BasicBlock *, 32> Work{Entry};
  SmallPtrSet<const BasicBlock *, 32> Seen;
  while (!Work.empty()) {
    const BasicBlock *B = Work.pop_back_val();
    if (B == Header || !Seen.insert(B).second)
      continue;
    if (B == RB)
      return false;  // a path the proof could not refute bypasses `L`.
    const auto *BI = dyn_cast<BranchInst>(B->getTerminator());
    if (BI && BI->isConditional() &&
        BI->getSuccessor(0) != BI->getSuccessor(1) &&
        singleValuedClosure(BI->getCondition(), Ctx)) {
      for (unsigned S = 0; S < 2; ++S)
        if (!EdgeRefutesAFact(BI->getCondition(), /*Taken=*/S == 0))
          Work.push_back(BI->getSuccessor(S));
      continue;
    }
    Work.append(succ_begin(B), succ_end(B));
  }
  return true;
}

// Does `Read` lie INSIDE the REGION of a tainted branch — i.e. is it reachable
// from some tainted `br`/`switch` that dominates it, WITHOUT passing that
// branch's immediate post-dominator (its merge)? A branch with NO immediate
// post-dominator (a tainted early return, an abort park) has no merge, so
// everything it reaches is its region. Such a read may be hoisted or speculated
// by the flatten, so the caller gives it header dominance only.
//
// ⚠ DELIBERATELY NOT `instUnderTaintedControl` (Rule-13 round 3, F-1, P2). That
// shared 7.5 predicate answers "dominated by a tainted branch AND does not
// post-dominate it", which is NOT region membership (and not control
// dependence either): a tainted `if (c) cq_phi(pi);` diamond that FULLY MERGES
// before an unguarded runtime bank still counts, because `-O1` gives each bank
// loop its own classical guard and the read then post-dominates nothing — the
// Grover shape over-declined at this clause. The shared predicate is unchanged
// (its 7.5 callers ask a different question); this is the carve's own, narrower
// one. A read inside a region: `…_classical_fact_under_tainted_arm.ll`; a
// merged diamond before the bank: `…_accept_merged_tainted_diamond.ll`.
bool readInsideTaintedRegion(const Instruction *Read, const TaintSet &taint,
                             const DominatorTree &DT) {
  const BasicBlock *RB = Read->getParent();
  const DomTreeNode *Node = DT.getNode(RB);
  if (!Node)
    return true;  // unreachable read — the caller refuses it anyway.
  std::optional<PostDominatorTree> PDT;
  for (const DomTreeNode *D = Node->getIDom(); D; D = D->getIDom()) {
    const BasicBlock *B = D->getBlock();
    const Instruction *T = B->getTerminator();
    const Value *C = nullptr;
    if (const auto *BI = dyn_cast<BranchInst>(T)) {
      if (BI->isConditional())
        C = BI->getCondition();
    } else if (const auto *SI = dyn_cast<SwitchInst>(T)) {
      C = SI->getCondition();
    }
    if (!C || !taint.Tainted.count(const_cast<Value *>(C)))
      continue;
    if (!PDT)
      PDT.emplace(*const_cast<Function *>(RB->getParent()));
    const DomTreeNode *PN = PDT->getNode(B);
    const BasicBlock *Merge =
        (PN && PN->getIDom()) ? PN->getIDom()->getBlock() : nullptr;
    SmallVector<const BasicBlock *, 16> Work(succ_begin(B), succ_end(B));
    SmallPtrSet<const BasicBlock *, 32> Seen;
    while (!Work.empty()) {
      const BasicBlock *X = Work.pop_back_val();
      if (X == Merge || !Seen.insert(X).second)
        continue;
      if (X == RB)
        return true;
      Work.append(succ_begin(X), succ_end(X));
    }
  }
  return false;
}

// Can this `llvm.stackrestore` free `AI`'s storage? A restore pops back to its
// SAVE point, so it frees exactly the allocas made after that save. When the
// operand is an `llvm.stacksave` that `AI` dominates (and `AI` is in no cycle,
// which every caller has proven), the save was taken after `AI` on every path
// and the restore cannot free it — the scoped temporary VLA of F-B3. Any other
// operand is refused conservatively.
bool stackRestoreMayFree(const IntrinsicInst *Restore, const AllocaInst *AI,
                         const DominatorTree &DT) {
  const auto *Save = dyn_cast<IntrinsicInst>(
      Restore->getArgOperand(0)->stripPointerCasts());
  return !(Save && Save->getIntrinsicID() == Intrinsic::stacksave &&
           DT.dominates(AI, Save));
}

// The cell index must be as wide as the address arithmetic (F-B5): a narrower
// index is SIGN-extended by the gep while the extent is ZERO-extended by the
// alloca, so "the walk visits 0..n-1" would not survive n >= 2^(w-1).
bool indexIsAddressWidth(const Value *Idx, const Value *Ptr,
                         const DataLayout &DL) {
  return Idx->getType()->isIntegerTy(
      DL.getIndexTypeSizeInBits(Ptr->getType()));
}

// Semantic SCEV equality at one program point. The direct predicate query owns
// the general case. The narrow recursive arm handles clang's rotated-loop
// spelling `zext(smax(n, 1))`: below a dominating source precondition `n > 0`,
// the max is exactly n. Each unwrap is injective (matching zext source/result
// types), and the max arm asks ScalarEvolution to prove every ordering fact at
// `Ctx`; no syntactic resemblance is accepted as a proof.
bool scevEqualAt(const SCEV *A, const SCEV *B, const Instruction *Ctx,
                 ScalarEvolution &SE, unsigned Depth = 0) {
  if (A == B || SE.isKnownPredicateAt(ICmpInst::ICMP_EQ, A, B, Ctx))
    return true;
  if (Depth == 4 || A->getType() != B->getType())
    return false;

  const auto *ZA = dyn_cast<SCEVZeroExtendExpr>(A);
  const auto *ZB = dyn_cast<SCEVZeroExtendExpr>(B);
  if (ZA && ZB && ZA->getOperand()->getType() == ZB->getOperand()->getType())
    return scevEqualAt(ZA->getOperand(), ZB->getOperand(), Ctx, SE, Depth + 1);

  auto MaxEquals = [&](const SCEV *MaybeMax, const SCEV *Other) {
    const auto *Max = dyn_cast<SCEVSMaxExpr>(MaybeMax);
    if (!Max)
      return false;
    bool FoundOther = false;
    for (const SCEV *Op : Max->operands()) {
      if (scevEqualAt(Op, Other, Ctx, SE, Depth + 1)) {
        FoundOther = true;
        continue;
      }
      if (!SE.isKnownPredicateAt(ICmpInst::ICMP_SGE, Other, Op, Ctx))
        return false;
    }
    return FoundOther;
  };
  return MaxEquals(A, B) || MaxEquals(B, A);
}

// Equality of two SCEVs at every execution of a point inside loop `L`
// (Rule-13 xdu2.4 finding 2). `Fallback` is the destination point itself (the
// latch the promoted store moves to, or the region entry a flattened load is
// hoisted to) and is always sound. When BOTH sides are invariant in `L`, a proof
// at the preheader terminator is ALSO sound for every point in `L`: each loop
// activation executes that terminator first and neither value can change before
// the destination. It is the stronger query in practice, because SCEV's guard
// walk from a multi-predecessor latch sees no dominating branch at all. What is
// never sound is the ORIGINAL conditional store/load: its own guard is not in
// force at the point the lowering moves execution to.
bool scevEqualInLoop(const SCEV *A, const SCEV *B, const Loop *L,
                     const Instruction *Fallback, ScalarEvolution &SE) {
  if (const BasicBlock *PH = L->getLoopPreheader())
    if (SE.isLoopInvariant(A, L) && SE.isLoopInvariant(B, L) &&
        scevEqualAt(A, B, PH->getTerminator(), SE))
      return true;
  return scevEqualAt(A, B, Fallback, SE);
}

// Loud `DiagnosticInfoUnsupported(DS_Error)` with the offending load's `!dbg`
// (source-located; `opt` exits non-zero, which the negative fixtures invert with
// `RUN: not`). Same idiom as `diagnoseEscape` / `FreePoint::diagnose`.
void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// The recovered structural shape of an accepted QROM read. `ElemAbi` may name an
// UNSUPPORTED width (fp/i128) — the structural shape still matches; the emitter
// performs the `widthHasReversibleCopy` gate and loud-declines.
struct QromRead {
  GetElementPtrInst *Gep;
  GlobalVariable *GV;
  StringRef ElemAbi;   // element ABI width (may be unsupported — emitter gates)
  uint64_t Count;      // array length N
  Value *RawIndex;     // the gep's last (tainted) index operand
};

// ── Phase 7.5 Increment 2: alloca-backed mutable array (Shadow-shaped) ──────────
// The recovered structural shape of ONE well-formed tainted-index access (a load
// or a store) through an `alloca [N x iW]`. The alloca-WIDE invariants (mixed
// access, pointer escape, mid-sequence observation §2.8(iii)) are the emitter's.
struct ShadowAccess {
  Instruction *MemOp;       // the load or the store
  GetElementPtrInst *Gep;   // its sole-use array-decay / flat address-gen
  AllocaInst *Alloca;       // the single PtrOrigin
  StringRef ElemAbi;        // element ABI width (may be unsupported — emitter gates)
  uint64_t Count;           // array length N
  Value *RawIndex;          // the gep's trailing (tainted) index operand
  Value *StoreVal;          // the stored value (store only; null for a load)
  bool IsStore;
};

// Is `I` genuinely CONTROL-DEPENDENT on a tainted-condition branch? 7.5 lowers
// STRAIGHT-LINE memory only (§2.11); a CONDITIONALLY-executed access inside a
// tainted-control region (e.g. the const `@switch.table` gep/load of a clang-folded
// jump table, control_swap_reject_switch_jumptable.ll) is NOT ours and declines at
// the escape guard.
//
// The test is CONTROL DEPENDENCE, not mere dominance: `I` is under control of a
// tainted br at block `B` iff `B` strictly dominates `I`'s block AND `I`'s block
// does NOT post-dominate `B` (i.e. some path leaving `B` bypasses `I` — the access
// is genuinely conditional). A block that POST-DOMINATES the tainted br (the merge
// and everything after it) is reached on EVERY path, so it is unconditional /
// straight-line and NOT under control — a load `arr[q]` sitting after an
// `if(q<k){arr[i]=v;}` diamond executes regardless of the branch. Keying on plain
// dominance (the pre-iw81.7 form) over-declined every such post-merge access — a
// blocker for the guarded store (iw81.7), whose array is inevitably read after the
// diamond. Over-declining a conditional access is safe; ACCEPTING an unconditional
// post-dominating one is correct (it is exactly the straight-line 7.5 shape). The
// `PostDominatorTree` is built lazily — ONLY when a dominating tainted br is found
// (the rare case) — so the common no-tainted-control access pays nothing.
bool instUnderTaintedControl(const Instruction *I, const TaintSet &taint,
                             DominatorTree &DT) {
  BasicBlock *IB = const_cast<BasicBlock *>(I->getParent());
  DomTreeNode *Node = DT.getNode(IB);
  if (!Node)
    return true;  // unreachable / no node — decline conservatively.
  std::optional<PostDominatorTree> PDT;
  for (DomTreeNode *D = Node->getIDom(); D; D = D->getIDom()) {
    BasicBlock *B = D->getBlock();
    const Instruction *T = B->getTerminator();
    bool TaintedBr = false;
    if (const auto *BI = dyn_cast<BranchInst>(T))
      TaintedBr = BI->isConditional() &&
                  taint.Tainted.count(const_cast<Value *>(BI->getCondition()));
    else if (const auto *SI = dyn_cast<SwitchInst>(T))
      TaintedBr = taint.Tainted.count(const_cast<Value *>(SI->getCondition()));
    if (!TaintedBr)
      continue;
    if (!PDT)
      PDT.emplace(*IB->getParent());
    // Control-dependent iff `I`'s block does NOT post-dominate the tainted br `B`
    // (some successor path of `B` bypasses `I` — the access is conditional). A
    // post-dominating access is unconditional → straight-line → NOT under control.
    if (!PDT->dominates(IB, B))
      return true;
  }
  return false;
}

// ── Phase 7.5 Increment 3: the single-PtrOrigin provenance walk ─────────────────
//
// A recognized heap allocator (`malloc`/`calloc`/`realloc`/`aligned_alloc`/C++
// `operator new` mangled forms) — a pointer with NO compile-time shape (the heap
// reject, [[pointer-boundary-linearity-bennett]]). EXACT-name membership (never a
// `starts_with` accept) so a user `malloc_helper` is not mistaken for the libc
// allocator; any OTHER call origin rides the generic no-provenance reject anyway.
bool isAllocatorCall(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N == "malloc" || N == "calloc" || N == "realloc" ||
         N == "aligned_alloc" || N == "reallocf" || N == "valloc" ||
         N == "_Znwm" || N == "_Znam";  // operator new / new[]
}

// The resolved base object of a pointer chain, OR a named decline reason. `Msg`
// is non-null exactly when `Kind == Bad` (the pattern-naming diagnostic the
// carve fires; PRD-7.5 §2.8(iv)).
struct OriginResult {
  enum K { Alloca, Global, Bad } Kind;
  AllocaInst *AI = nullptr;
  GlobalVariable *GV = nullptr;
  const char *Msg = nullptr;
};

OriginResult originAlloca(AllocaInst *AI) { return {OriginResult::Alloca, AI, nullptr, nullptr}; }
OriginResult originGlobal(GlobalVariable *GV) { return {OriginResult::Global, nullptr, GV, nullptr}; }
OriginResult originBad(const char *M) { return {OriginResult::Bad, nullptr, nullptr, M}; }

// Do two origins name the SAME base object? (phi/select single-origin proof.)
bool sameOrigin(const OriginResult &A, const OriginResult &B) {
  if (A.Kind != B.Kind)
    return false;
  return A.Kind == OriginResult::Alloca ? A.AI == B.AI
       : A.Kind == OriginResult::Global ? A.GV == B.GV
                                        : false;
}

// The recursion-depth ceiling for the pointer-provenance walks. Real `-O1`
// pointer chains are a handful of nodes; a chain deeper than this is pathological
// (or a loop-carried-phi cycle) → conservatively decline rather than recurse
// forever. Depth-bounding (vs a visited-set) avoids a FALSE cycle when a value is
// legitimately reachable from BOTH arms of a phi/select (diamond reconvergence —
// the degenerate single-origin proof).
constexpr unsigned kPtrWalkMaxDepth = 32;

// Resolve `P` to its unique base object, following `bitcast`,
// `getelementptr` bases (gep chains), and pointer `phi`/`select` (ALL arms must
// resolve to the SAME origin). Returns a named `Bad` for any shape that is not a
// single origin — the Bennett signpost decline matrix. Dynamic stack allocas
// remain forbidden to QRAM callers; the rail-bank caller opts into seeing the
// origin so it can apply its separate classical-extent proof. Mutation-free.
OriginResult walkPtrOrigin(Value *P, unsigned Depth = 0,
                           bool AllowDynamicAlloca = false) {
  if (Depth > kPtrWalkMaxDepth)
    return originBad(kMsgQramMultiOrigin);  // pathological / cyclic (loop) chain.
  if (auto *AI = dyn_cast<AllocaInst>(P)) {
    if (AI->isArrayAllocation())
      return AllowDynamicAlloca ? originAlloca(AI)
                                : originBad(kMsgQramDynN);
    if (!isa<ArrayType>(AI->getAllocatedType()))
      return originBad(kMsgQramDynN);  // VLA / scalar alloca — no compile-time shape.
    return originAlloca(AI);
  }
  if (auto *GV = dyn_cast<GlobalVariable>(P)) {
    if (!isa<ArrayType>(GV->getValueType()))
      return originBad(kMsgQramProvenance);  // a non-array global is not a table.
    return originGlobal(GV);
  }
  if (auto *GEP = dyn_cast<GetElementPtrInst>(P))
    return walkPtrOrigin(GEP->getPointerOperand(), Depth + 1,
                         AllowDynamicAlloca);  // gep chain.
  if (auto *BC = dyn_cast<BitCastInst>(P))
    return walkPtrOrigin(BC->getOperand(0), Depth + 1,
                         AllowDynamicAlloca);
  if (isa<AddrSpaceCastInst>(P))
    return originBad(kMsgQramAddrSpace);
  if (isa<IntToPtrInst>(P))
    return originBad(kMsgQramProvenance);  // a forged address (inttoptr/ptrtoint).
  if (auto *Phi = dyn_cast<PHINode>(P)) {
    OriginResult Acc = originBad(kMsgQramMultiOrigin);
    bool First = true;
    for (Value *In : Phi->incoming_values()) {
      OriginResult R = walkPtrOrigin(In, Depth + 1, AllowDynamicAlloca);
      if (R.Kind == OriginResult::Bad)
        return R;  // propagate the most specific reason.
      if (First) { Acc = R; First = false; continue; }
      if (!sameOrigin(Acc, R))
        return originBad(kMsgQramMultiOrigin);  // ≥2 distinct origins.
    }
    return First ? originBad(kMsgQramProvenance) : Acc;
  }
  if (auto *Sel = dyn_cast<SelectInst>(P)) {
    OriginResult T =
        walkPtrOrigin(Sel->getTrueValue(), Depth + 1, AllowDynamicAlloca);
    if (T.Kind == OriginResult::Bad)
      return T;
    OriginResult F =
        walkPtrOrigin(Sel->getFalseValue(), Depth + 1, AllowDynamicAlloca);
    if (F.Kind == OriginResult::Bad)
      return F;
    return sameOrigin(T, F) ? T : originBad(kMsgQramMultiOrigin);
  }
  if (auto *CI = dyn_cast<CallInst>(P))
    return originBad(isAllocatorCall(CI) ? kMsgQramHeap : kMsgQramProvenance);
  return originBad(kMsgQramProvenance);  // Argument / unknown → no provenance.
}

// Is `P` a DIRECT origin pointer — `Origin` with a provable ZERO net offset? True
// iff `P`, stripping `bitcast`, IS the origin object, OR a `phi`/`select` ALL of
// whose arms are themselves direct. A gep-with-offset, or a same-origin-but-
// different-offset phi/select, is NOT direct (the index would not be cleanly the
// trailing gep operand — decline, Prime Directive). This is the offset-cleanliness
// half of the §2.8(iv) accept; `walkPtrOrigin` proves the single origin, this
// proves the clean index.
bool isDirectOriginPtr(Value *P, const OriginResult &Origin, unsigned Depth = 0) {
  if (Depth > kPtrWalkMaxDepth)
    return false;  // pathological / cyclic chain — conservatively not direct.
  if (auto *BC = dyn_cast<BitCastInst>(P))
    return isDirectOriginPtr(BC->getOperand(0), Origin, Depth + 1);
  if (Origin.Kind == OriginResult::Alloca && P == Origin.AI)
    return true;
  if (Origin.Kind == OriginResult::Global && P == Origin.GV)
    return true;
  if (auto *Phi = dyn_cast<PHINode>(P)) {
    for (Value *In : Phi->incoming_values())
      if (!isDirectOriginPtr(In, Origin, Depth + 1))
        return false;
    return Phi->getNumIncomingValues() > 0;
  }
  if (auto *Sel = dyn_cast<SelectInst>(P))
    return isDirectOriginPtr(Sel->getTrueValue(), Origin, Depth + 1) &&
           isDirectOriginPtr(Sel->getFalseValue(), Origin, Depth + 1);
  return false;  // a gep (offset) or anything else → not a direct origin pointer.
}

// The accessed-cell shape recovered from a memop's address gep: the trailing
// (tainted) index, the cell scalar type, and the gep itself. Returns false for a
// non-canonical gep (multi-index struct gep, non-zero leading index, a tainted
// NON-trailing index). Handles BOTH array-decay (`[N x E], base, 0, idx`) and the
// flat element form (`E, base, idx`) clang -O1 emits for pointer-indirected
// access (Inc 3, the realistic phi/select shape).
bool matchAddressGep(GetElementPtrInst *GEP, const TaintSet &taint,
                     Value *&RawIndex, Type *&CellTy,
                     bool requireTaintedIndex = true) {
  Type *Src = GEP->getSourceElementType();
  if (auto *AT = dyn_cast<ArrayType>(Src)) {
    // Array-decay: exactly (const-zero, trailing index).
    if (GEP->getNumIndices() != 2)
      return false;
    auto *First = dyn_cast<ConstantInt>(GEP->getOperand(1));
    if (!First || !First->isZero())
      return false;
    CellTy = AT->getElementType();
  } else if (Src->isIntegerTy() || Src->isFloatingPointTy()) {
    // Flat element gep: exactly one index.
    if (GEP->getNumIndices() != 1)
      return false;
    CellTy = Src;
  } else {
    return false;  // a struct / vector / aggregate source element is not a cell.
  }
  RawIndex = GEP->getOperand(GEP->getNumOperands() - 1);
  // The trailing index must be tainted — except for the Inc-3 PredMux claim,
  // which may waive it for a region-internal-phi-derived index the flatten
  // itself will taint (the caller enforces that proof; see
  // `classifyQromReadUnderControl`).
  return !requireTaintedIndex || taint.Tainted.count(RawIndex);
}

// The SINGLE structural ACCEPT — the shared truth for the carve AND both emitters
// (carve/emit can never diverge; the Inc 1 discipline). A simple `load`/`store`
// whose pointer is a single-use gep (array-decay OR flat) with a tainted trailing
// index, whose base resolves to a SINGLE statically-shaped origin (`walkPtrOrigin`)
// reached with a provable ZERO offset (`isDirectOriginPtr`), of array type
// `[N x E]` with a SCALAR cell `E` matching the gep, NOT under tainted control and
// NOT in a loop. The element width may be unsupported (fp/i128) — the structural
// shape still matches; the emitter width-gates it to kMsgQramCell (a carve is never
// a silent accept). Returns the resolved origin + shape, or nullopt.
struct QramMatch {
  Instruction *MemOp;
  GetElementPtrInst *Gep;
  OriginResult Origin;     // Alloca (Shadow) or Global (QROM read)
  StringRef ElemAbi;
  uint64_t Count;
  Value *RawIndex;
  Value *StoreVal;         // store only
  bool IsStore;
};

std::optional<QramMatch> matchQramAccess(Instruction *MemOp,
                                         const TaintSet &taint, DominatorTree &DT,
                                         LoopInfo &LInfo,
                                         bool allowTaintedControl = false,
                                         bool allowUntaintedIndex = false) {
  Value *PtrOp = nullptr;
  Value *StoreVal = nullptr;
  bool IsStore;
  if (auto *LI = dyn_cast<LoadInst>(MemOp)) {
    if (!LI->isSimple())
      return std::nullopt;
    PtrOp = LI->getPointerOperand();
    IsStore = false;
  } else if (auto *SI = dyn_cast<StoreInst>(MemOp)) {
    if (!SI->isSimple())
      return std::nullopt;
    PtrOp = SI->getPointerOperand();
    StoreVal = SI->getValueOperand();
    IsStore = true;
  } else {
    return std::nullopt;
  }
  auto *GEP = dyn_cast<GetElementPtrInst>(PtrOp);
  if (!GEP || !GEP->hasOneUse())
    return std::nullopt;  // single-use address gep (sole user is this memop).
  Value *RawIndex = nullptr;
  Type *CellTy = nullptr;
  if (!matchAddressGep(GEP, taint, RawIndex, CellTy,
                       /*requireTaintedIndex=*/!allowUntaintedIndex))
    return std::nullopt;  // non-canonical / classical-index gep — not ours.
  // Pun fence (38t2 Rule-13 clearance): the memop's ACCESSED type must BE the
  // cell type. A type-punned sub-width access (`store float` through a
  // `[N x double]` gep, `store i32` into an `[N x i64]` cell) would otherwise
  // resolve ElemAbi from the ORIGIN and emit a full-cell-width qram call fed by
  // a narrower rail — a verify-clean wrong-width gate stream. Not a qram shape;
  // the pass-wide taint-escape guards decline the tainted memop/index loudly
  // downstream (a carve is never a silent accept).
  Type *AccTy = IsStore ? StoreVal->getType() : MemOp->getType();
  if (AccTy != CellTy)
    return std::nullopt;
  Value *Base = GEP->getPointerOperand();
  OriginResult Origin = walkPtrOrigin(Base);
  if (Origin.Kind == OriginResult::Bad)
    return std::nullopt;  // not a single statically-shaped origin (carve names it).
  if (!isDirectOriginPtr(Base, Origin))
    return std::nullopt;  // dynamic / non-zero base offset — index not clean.
  Type *OriginArrTy = Origin.Kind == OriginResult::Alloca
                          ? Origin.AI->getAllocatedType()
                          : Origin.GV->getValueType();
  auto *OT = dyn_cast<ArrayType>(OriginArrTy);
  if (!OT || OT->getElementType() != CellTy)
    return std::nullopt;  // shape mismatch — the gep cell must be the origin cell.
  if (OT->getNumElements() == 0)
    return std::nullopt;  // a `[0 x iW]` array has no cell — any index is OOB (a
                          // degenerate/UB shape). Decline (Rule-13 Finding 2).
  Type *E = OT->getElementType();
  if (!E->isIntegerTy() && !E->isFloatingPointTy())
    return std::nullopt;
  if (Origin.Kind == OriginResult::Global &&
      (!Origin.GV->isConstant() || !Origin.GV->hasInitializer()))
    return std::nullopt;  // a QROM table must be a constant initialized global.
  if (!allowTaintedControl && instUnderTaintedControl(MemOp, taint, DT))
    return std::nullopt;  // straight-line only (§2.11). iw81.7 passes
                          // `allowTaintedControl` to prove the SHAPE of a store
                          // that a GuardedStoreArm region will flatten to
                          // straight-line before `lowerShadowMemory` runs.
  if (LInfo.getLoopFor(MemOp->getParent()))
    return std::nullopt;  // a QRAM access in a loop needs 7.3 unroll (§5/§6).
  return QramMatch{MemOp,  GEP,      Origin,   abiWidthFromType(E),
                   OT->getNumElements(), RawIndex, StoreVal, IsStore};
}

// QROM-read wrapper: an accepted access whose origin is a constant GLOBAL (Inc 1).
std::optional<QromRead> classifyQromRead(LoadInst *LI, const TaintSet &taint,
                                         DominatorTree &DT, LoopInfo &LInfo) {
  auto M = matchQramAccess(LI, taint, DT, LInfo);
  if (!M || M->Origin.Kind != OriginResult::Global)
    return std::nullopt;
  return QromRead{M->Gep, M->Origin.GV, M->ElemAbi, M->Count, M->RawIndex};
}

// Shadow wrapper: an accepted access whose origin is an ALLOCA (Inc 2).
std::optional<ShadowAccess> classifyShadowAccess(Instruction *MemOp,
                                                 const TaintSet &taint,
                                                 DominatorTree &DT,
                                                 LoopInfo &LInfo) {
  auto M = matchQramAccess(MemOp, taint, DT, LInfo);
  if (!M || M->Origin.Kind != OriginResult::Alloca)
    return std::nullopt;
  return ShadowAccess{M->MemOp,  M->Gep,   M->Origin.AI, M->ElemAbi,
                      M->Count,  M->RawIndex, M->StoreVal, M->IsStore};
}

// bd 3c6m.13 — is `LI` a would-be QROM read (constant-global table, tainted trailing
// index, single-use gep, clean direct origin) whose SOLE blocker is that it is
// control-dependent on a tainted branch? Reuses the SHARED `matchQramAccess`
// (`allowTaintedControl=true` strips only the straight-line gate) so the signpost
// names EXACTLY the shape the emitter WOULD lower were it straight-line — carve and
// emit cannot diverge (Inc-1 discipline). A non-const global (nullopt), an alloca
// Shadow origin, an aliased/off-shape gep (nullopt), or an in-loop read (nullopt) is
// NOT this shape → the caller falls to its existing verdict. Callers invoke this only
// from a branch already known to be under tainted control.
//
// "Blocked SOLELY by control" means the read WOULD lower were it hoisted straight-line —
// so the helper must replicate EVERY straight-line-accept gate `lowerQramReads` applies
// beyond the structural `matchQramAccess`, else the "needs nested-control lowering"
// signpost is a FALSE promise for a read a second blocker would decline anyway. Those
// gates are exactly two:
//   * WIDTH (design-review scope lens): `widthHasQramCell` (the SAME gate at L~790). An
//     i128 / fp128 const cell declines on WIDTH even straight-line (kMsgQramCell), so
//     control is not its sole blocker (de-nesting cannot make an i128 cell lowerable).
//   * COHERENT ESCAPE (Rule-13 clearance): a non-`main` read whose value coherently flows
//     to a `ret` / `cq_invert` (no measure/tape collapse first) declines straight-line with
//     the no-cloning fence (kMsgQramCohEscape, L~773) — perfect nested-control lowering would
//     STILL hit the no-cloning wall (the value is entangled with its local index), so the
//     signpost would misdirect. `coherentlyEscapesToReturn` is producer-agnostic and works at
//     carve time (walks raw SSA users, stops at `cq_measure_`; the not-yet-lowered tape is a
//     safe non-stop — a taped-only value returns false as its call result is dead).
// Either non-control blocker → helper returns false → the read falls to the caller's generic
// decline (kMsgOther), never the false signpost. So the predicate reads EXACTLY as "would be
// an accepted QROM read if hoisted straight-line, blocked solely by the tainted-control
// region." (`coherentlyEscapesToReturn` is defined later in this namespace — forward-declared.)
bool coherentlyEscapesToReturn(Value *V);
bool isQromReadBlockedOnlyByControl(LoadInst *LI, const TaintSet &taint,
                                    DominatorTree &DT, LoopInfo &LInfo) {
  auto M = matchQramAccess(LI, taint, DT, LInfo, /*allowTaintedControl=*/true);
  if (!M.has_value() || M->Origin.Kind != OriginResult::Global ||
      !widthHasQramCell(M->ElemAbi))
    return false;
  // A coherently-escaping value is no-cloning-blocked even straight-line — not a
  // control-sole shape (`main`'s ret is the process-exit observation, exempt).
  if (LI->getFunction()->getName() != "main" && coherentlyEscapesToReturn(LI))
    return false;
  return true;
}

// Inc 3 — will the flatten itself TAINT this (currently untainted) index? True
// iff the index transitively depends on a region-internal PHI: convertPhis
// rewrites every such phi to a select chain over the (tainted) edge predicates,
// and taint then flows forward through the pure ops between the phi and the
// gep. An index with NO region-phi dependence stays classical post-flatten —
// then the load is a plain classical load whose SPECULATION is in-bounds by the
// same proof/mask the caller enforces (immutable dereferenceable global), and
// it simply stays classical code. The atan `id` phi over constants is the
// canonical taint-after-flatten case.
bool indexWillTaintAfterFlatten(const Value *V, const TaintSet &taint,
                                const SmallPtrSetImpl<BasicBlock *> &Region,
                                const BasicBlock *RegionEntry = nullptr,
                                unsigned Depth = 0) {
  if (Depth > 16)
    return false;  // over-declining is safe.
  if (taint.Tainted.count(const_cast<Value *>(V)))
    return true;
  const auto *I = dyn_cast<Instruction>(V);
  if (!I || !Region.count(const_cast<BasicBlock *>(I->getParent())))
    return false;
  if (const auto *P = dyn_cast<PHINode>(I)) {
    // bd q2wk Rule-13 (4 of 6 lenses, independently) — "region-internal phi"
    // is NOT the same question as "a phi the flatten converts", and the two
    // FENCES below are where they come apart. Getting this wrong does not
    // miscompile (the flatten is a taint-blind classical rewrite), but it makes
    // the E6 accept surface wider than the argument that justifies it, and it
    // silently breaks the invariant "admitted ⇒ tainted after the flatten" that
    // a later caller could reasonably lean on.
    //
    // FENCE 1 — the ENTRY block. `RegionFlattener::run()` converts the phis of
    // every region block EXCEPT `R.Entry`, so an entry-block phi survives the
    // flatten AS A PHI and taints nothing. `R.InRegion` contains the entry, so
    // without this the walk answers "will taint" for it. Rule (A)'s
    // `isConvertiblePhiCond` has always fenced exactly this case; rule (B) did
    // not until now. Callers that do not know an entry pass null and keep the
    // historical looser answer (see the header note on the QROM caller).
    if (RegionEntry && P->getParent() == RegionEntry)
      return false;
    // FENCE 2 — a phi whose unique-block incoming VALUES are all ONE Value is
    // RAUW'd straight to that Value by `convertPhis`' SELECT-CHAIN path (it
    // seeds `Acc = In.back().second` and skips every `In[I].second == Acc`), so
    // it taints iff that Value does — recurse instead of assuming. Subsumes the
    // degenerate SINGLE-incoming phi (`control_predmux_reject_degenerate_phi_
    // classical.ll`) and the >1-block/one-value shape
    // (`control_predmux_reject_equal_incomings_phi.ll`): both are refused at the
    // CLAIM gate, detect-before-mutate, instead of declining downstream after
    // the region was already flattened.
    //
    // GATED ON `RegionEntry` — i.e. on the caller having opted into the PRECISE
    // semantics — for the same reason FENCE 1 is. The delta Rule-13 round caught
    // this ungated and it had silently tightened the Inc-3 QROM index gate: an
    // all-equal (or degenerate) INDEX phi stopped being claimable, so a
    // previously-accepted, separately-cleared QROM shape began declining at
    // `E4-gep`. Safe (an over-decline) but out of q2wk's scope, invisible to
    // every committed input, and flatly contradicted by this header's own
    // promise that the QROM caller keeps the historical answer.
    //
    // TWO PRECISION NOTES, both deliberate over-declines (safe direction):
    //  * the undef/poison FREEZE is mirrored below because `convertPhis`
    //    normalizes `isa<UndefValue>` incomings to the type's zero BEFORE it
    //    builds its `In` list — comparing raw incomings let
    //    `phi [0, %a], [undef, %b]` read as "not all equal" here while the
    //    flatten RAUW'd it to a constant. That was a FIFTH residual the delta
    //    round found compiling silently; the rule is "mirror `convertPhis`' In
    //    construction verbatim", so any future normalization it grows must be
    //    mirrored here too.
    //  * for an i1 phi that takes the BOOLEAN-ALGEBRA path this OVER-declines:
    //    that path builds `∨ᵢ(EPᵢ ∧ v)`, which is TAINTED even when every `v` is
    //    the same classical value. Predicting whether BoolAlg fires needs the
    //    grammar/record decision that is not available here, so the fence takes
    //    the safe side. Measured cost: none (census 92/123 unchanged, lit green).
    const Value *Sole = nullptr;
    bool AllEqual = true;
    for (unsigned K = 0, N = P->getNumIncomingValues(); K != N; ++K) {
      const Value *IV = P->getIncomingValue(K);
      if (isa<UndefValue>(IV))  // convertPhis freezes undef AND poison to zero.
        IV = Constant::getNullValue(P->getType());
      if (!Sole)
        Sole = IV;
      else if (Sole != IV) {
        AllEqual = false;
        break;
      }
    }
    if (RegionEntry && AllEqual && Sole)
      return indexWillTaintAfterFlatten(Sole, taint, Region, RegionEntry,
                                        Depth + 1);
    return true;  // converts to a select chain over tainted edge predicates.
  }
  for (const Value *Op : I->operands())
    if (indexWillTaintAfterFlatten(Op, taint, Region, RegionEntry, Depth + 1))
      return true;
  return false;
}

// bd 20xt.4 Inc 2 (blocker c Rule-13 fix) — the shared "index KNOWN in-bounds"
// proof, consulted by BOTH `classifyQromReadUnderControlImpl` (its `Provable`
// verdict) AND the Bennett-clone read fence in `lowerQramReads` (so the under-
// control claim and the clone emitter can never diverge — Rule 14). True iff the
// gep trailing index is ALREADY at the pointer-index width (clang -O1's i64, so no
// narrow-index sign-extension can turn a `< N` value into a negative offset) AND
// its known bits prove non-negative AND max < N. (Full signedness/pointer-width
// rationale in the `classifyQromReadUnderControlImpl` bounds comment below.)
bool qromIndexKnownInBounds(Value *RawIndex, GetElementPtrInst *Gep,
                            uint64_t Count, const DataLayout &DL) {
  if (RawIndex->getType()->getScalarSizeInBits() !=
      DL.getIndexTypeSizeInBits(Gep->getType()))
    return false;
  // *** THIS PROOF'S OBLIGATION IS TOTAL; `computeKnownBits` IS MODULO-POISON
  // (bd s6ao). ***
  //
  // WHICH HALF DOES THE WORK, stated precisely, because an earlier draft of this
  // comment said "both halves are REQUIRED" and that is wrong in the direction
  // that invites a bad simplification. HALF 2 (`indexBoundIsPoisonConditional`)
  // ALONE DISCHARGES THE OBLIGATION: it returns false only when a total,
  // fact-free bound below `Count` exists, and such a bound holds on every basis
  // state by construction. HALF 1 (`UseInstrInfo=false`) cannot make an accept
  // sound that half 2 rejected — it only PRUNES accepts half 2 would allow. Keep
  // both (defence in depth on a frozen ABI, and half 1 is free), but do not
  // delete half 2 believing half 1 covers it: that is the R1 miscompile.
  //
  // `classifyQromReadUnderControlImpl`'s contract (below) is that "the
  // SPECULATED read runs on every basis state, so in-bounds must hold
  // UNCONDITIONALLY … not merely on the originally-guarded path".
  // `computeKnownBits` guarantees something strictly weaker: "these bits hold,
  // OR the value is poison". A poison-conditional bound is precisely a bound
  // that holds only on the paths the SOURCE executes — i.e. exactly the
  // originally-guarded path the speculation removes. So every channel by which a
  // poison-conditional fact can enter the query must be closed, and there are
  // more of them than the obvious one.
  //
  // HALF 1 — `UseInstrInfo=false`. MEASURED against LLVM 19's `InstrInfoQuery`
  // (SimplifyQuery.h:25-59), this gates EXACTLY five accessors: `getMetadata`,
  // `hasNoUnsignedWrap`, `hasNoSignedWrap`, `isExact`, `hasNoSignedZeros`. So it
  // closes `nuw`, `nsw`, `exact` and ALL metadata (including `!range`) — AND
  // NOTHING ELSE. *** It structurally cannot gate `nneg`, `disjoint` or
  // `CallBase::getRange()`, because `InstrInfoQuery` has no accessor for them.
  // Do not read this argument as "poison annotations are now ignored". *** It is
  // passed rather than refusing on flag PRESENCE so that a cone merely CARRYING
  // `nuw` still yields its sound opcode-structural bound (`shl nuw nsw i64 %h,1`
  // bounds identically without its flags) — refusing on presence would be a pure
  // over-decline, and would drop the 49 `zext nneg i32 -> i64` corpus sites,
  // none of which is load-bearing.
  //
  // HALF 2 — `indexBoundIsPoisonConditional` (PoisonFacts.h) walks the cone for
  // the channels half 1 cannot reach: the ungated annotations above, INHERENT
  // poison (out-of-range/non-constant shift amounts, div/rem by a
  // non-provably-nonzero divisor, fptosi/fptoui), and the poison-generating
  // IMMARG of `llvm.ctlz`/`cttz`/`abs` — which is an ordinary call OPERAND, so
  // no flag-stripping API touches it at all.
  //
  // TWO MEASURED SILENT MISCOMPILES, one per half, both `opt` exit 0,
  // `opt -verify` clean and `free_pairing_check.py` clean, on the FROZEN-
  // designate `cqrt_qram_load_<W>`:
  //   * HALF 1: `%hi = lshr(bits,63)` (∈{0,1}) then `%sx = sub nuw i64 %hi, 1`
  //     proved `%sx == 0`, emitting an UNMASKED read into a THREE-cell table
  //     whose index rail carries 0xFFFF_FFFF_FFFF_FFFF wherever bit 63 is clear.
  //   * HALF 2, and this one has a REAL C WITNESS: `__builtin_ctzll` into a
  //     64-entry table — `llvm.cttz.i64(%bits, i1 true)` — whose `is_zero_poison`
  //     immarg tightens the range from [0,64] to [0,63]. Emitted UNMASKED; on
  //     the basis state `bits == 0` (`q == +0.0`, which the Ry rail genuinely
  //     occupies) the true `cttz` is 64, one past the end.
  // In BOTH, Rule 15's width-only ABI DISCARDS the fact the bound rests on
  // (`sub nuw` -> the wrapping `cq_template_sub_i64_hl`; the immarg -> a
  // byte-identical `cq_template_cttz_i64`), so the bound described a value the
  // emitted circuit does not compute. That is the whole defect, twice.
  //
  // WHAT THIS DOES *NOT* CLOSE, stated plainly so the next reader keeps looking:
  // the `llvm.assume` and dominating-condition channels are shut only because
  // this call passes `AC`/`CxtI`/`DT` as null — ORTHOGONAL to both halves. If
  // anyone ever threads an `AssumptionCache` or a `DomConditionCache` in here
  // for a tighter bound, those channels open with no flag and no immarg
  // involved.
  //
  // *** DO NOT "fix" bd m9d2 by carrying a pre-flatten witness or by recording
  // what `stripPoisonCone`/`moveBody` dropped. *** Both exist to make the
  // flag-derived bound SURVIVE the flatten, and that bound IS the miscompile
  // above. m9d2 is the SAFE face (a spurious decline) of this same defect, whose
  // sign flips with block topology; it does not close onto this fix, because the
  // ungated `range`-attribute channel still makes a claim/re-proof verdict
  // topology-dependent.
  //
  // COST, MEASURED ZERO for half 1 and double-sourced: stripping those flags
  // MODULE-WIDE (a strictly larger perturbation) changed exit code or the
  // emitted gate stream in 0 of 220 cached e2e stage-1 modules. (An
  // accompanying "0 of 196 flag-bearing fixtures" figure was quoted here and is
  // WITHDRAWN — the 196 does not reproduce under any regex tried on re-audit;
  // the fixture-layer evidence is the full suite, 253/253 with no golden
  // regenerated.) Surviving bounded-index routes are a
  // genuinely flag-free known-bits bound (`lshr 63`) and the pow2 `NeedsMask`
  // fallback below — and the fallback is why half 2 is not a capability loss:
  // the `__builtin_ctzll` cell above still lowers, now MASKED
  // (control_predmux_accept_qrom_read_cttz_masked.ll).
  if (indexBoundIsPoisonConditional(RawIndex, Count))
    return false;
  KnownBits KB = computeKnownBits(RawIndex, DL, /*Depth=*/0, /*AC=*/nullptr,
                                  /*CxtI=*/nullptr, /*DT=*/nullptr,
                                  /*UseInstrInfo=*/false);
  unsigned Wide = std::max<unsigned>(KB.getBitWidth(), 65);
  APInt MaxIdx = KB.getMaxValue().zext(Wide);
  APInt CountAP(Wide, Count);
  return KB.isNonNegative() && MaxIdx.ult(CountAP);
}

// 3c6m.14 Inc 3 — the claim classification (see QramLowering.h). The SPECULATED
// read runs on every basis state, so in-bounds must hold UNCONDITIONALLY
// (known-bits), not merely on the originally-guarded path; failing that, a pow2
// table admits the `and idx, N-1` mask (identity in-guard; excluded states read a
// garbage row the merge's ∧-with-block-predicate discards). Everything else is No
// — the caller keeps its loud decline (over-declining is safe). With `Region`
// (the PredMux claim) the tainted-index gate widens to indexes the flatten
// itself will taint (region-internal-phi-derived — the atan `id` shape); the
// carve/signpost callers pass no region and keep the strict gate.
QromClaim classifyQromReadUnderControlImpl(
    LoadInst *LI, const TaintSet &taint, DominatorTree &DT, LoopInfo &LInfo,
    uint64_t *OutCount, const SmallPtrSetImpl<BasicBlock *> *Region,
    bool inBennettClone = false, bool *OutIndexBecomesOpaque = nullptr) {
  auto M = matchQramAccess(LI, taint, DT, LInfo, /*allowTaintedControl=*/true,
                           /*allowUntaintedIndex=*/Region != nullptr);
  if (!M.has_value() || M->Origin.Kind != OriginResult::Global ||
      !widthHasQramCell(M->ElemAbi))
    return QromClaim::No;
  // The coherent-escape no-cloning fence (as in isQromReadBlockedOnlyByControl).
  // BYPASSED under `inBennettClone` (bd 20xt.5.2): the E4 region-claim walk that
  // flattens a Phase-6 specialization clone body (PredMux `ClaimAll`) reaches a
  // QROM read whose value flows to the clone's non-`main` ret — EXACTLY the
  // top-level coherent-escape shape this fence blocks. But a clone read is NOT a
  // top-level `return tbl[q]`: the Bennett wrap (`emitBennettWrap`) copies the
  // return out to a FRESH |0⟩ basis rail BEFORE the reverse and then reverses the
  // WHOLE forward stream (the `cqrt_qram_load_<W>_unc` AND the index), leaving
  // Σ aᵢ|inputᵢ⟩|f(inputᵢ)⟩ — the index is uncomputed cleanly, never dirty-freed.
  // So the escape is SOUND here (the same bypass `lowerQramReads(inBennettClone=
  // true)` already applies at the EMITTER; this threads it to the CLAIM so the
  // flatten and the emitter cannot diverge — Rule 14). The signal is `ClaimAll`,
  // set ONLY by `lowerCloneControl` (the sole `flattenPredMuxRegions(claimAll=
  // true)` caller), so it is exactly the "inside a Bennett clone" predicate; the
  // carve/signpost callers pass `inBennettClone=false` and keep the fence.
  if (!inBennettClone && LI->getFunction()->getName() != "main" &&
      coherentlyEscapesToReturn(LI))
    return QromClaim::No;
  // Index-taint gate: tainted now, or provably tainted-by-flatten.
  if (!taint.Tainted.count(M->RawIndex) &&
      (!Region || !indexWillTaintAfterFlatten(M->RawIndex, taint, *Region)))
    return QromClaim::No;
  if (OutCount)
    *OutCount = M->Count;
  // bd 20xt.7: does the index become an OPAQUE handle after the flatten? A
  // CURRENTLY-UNTAINTED claimed index is region-internal-phi-derived (the taint
  // gate above admitted it only via `indexWillTaintAfterFlatten`), so the flatten
  // converts its phi to a select and `lowerCloneSelect` lowers it to a
  // `cqrt_alloc_i64` handle whose known-bits the emitter's `qromIndexKnownInBounds`
  // re-proof cannot see — that read (if Provable, pow2) NEEDS the identity mask to
  // carry its bounds proof forward. A CURRENTLY-TAINTED index is a straight-line
  // data computation (e.g. a source `& 3`): its raw op SURVIVES to the gep, so the
  // emitter re-proves it directly and no extra mask is needed (masking it would be
  // a redundant double-`and`, Rule 14). The caller uses this ONLY for the Provable
  // clone-read mask decision; it is meaningless for a `No` verdict.
  if (OutIndexBecomesOpaque)
    *OutIndexBecomesOpaque = !taint.Tainted.count(M->RawIndex);
  // Bounds proof for the speculated read. An LLVM gep trailing index is a
  // SIGNED offset computed at the POINTER-INDEX width, sign-extending a narrower
  // index. That signedness makes both claim forms unsound for a narrow index:
  //   * Provable — a sign-bit-set narrow index (`i8 0x80`) sign-extends to a
  //     NEGATIVE offset, reading before the table, even though it is `< N`
  //     unsigned;
  //   * NeedsMask — the mask `and idx, N-1` is built in the INDEX's own type, so
  //     when N-1 fills that type (`[256 x i8]`, mask `and i8 idx, -1`) it is a
  //     no-op that leaves the sign bit set — the masked value still sign-extends
  //     OOB.
  // Require the index to ALREADY be at the pointer-index width (exactly what
  // clang -O1 emits — it widens every gep index to i64, so no sign-extension
  // occurs). Then Provable's non-negativity proof holds and NeedsMask's `and`
  // clears the high bits into [0,N-1] (N ≤ 2^63 for any real table). A narrower
  // hand-written index is over-declined (safe — Prime Directive).
  const DataLayout &DL = LI->getModule()->getDataLayout();
  // Pointer-index-width gate FIRST: it gates BOTH claim forms (a narrow index
  // sign-extends OOB, and the in-type `and idx, N-1` NeedsMask mask is a no-op on
  // it — lowering_reject_qram_read_narrow_index.ll). Kept explicit here so the pow2
  // NeedsMask branch below can never admit a narrow index; `qromIndexKnownInBounds`
  // re-proves it for the Provable verdict + the shared clone-read fence (Rule 14).
  if (M->RawIndex->getType()->getScalarSizeInBits() !=
      DL.getIndexTypeSizeInBits(M->Gep->getType()))
    return QromClaim::No;
  if (qromIndexKnownInBounds(M->RawIndex, M->Gep, M->Count, DL))
    return QromClaim::Provable;  // non-negative (bit 63 clear) AND max < N.
  if (isPowerOf2_64(M->Count))
    return QromClaim::NeedsMask;
  return QromClaim::No;
}

// iw81.7 — the shared GuardedStoreArm SHAPE predicate (impl; public wrapper
// `guardedShadowStoreShape` below). (a) The bounded-alloca tainted-index Shadow
// STORE shape, ALLOWING the tainted control the region flattens away. (b) The
// depth-1 diamond arm: the store's block has a single predecessor ending in a
// conditional TAINTED `br` whose two successors are exactly {this block, the
// merge}, and this block's single successor is that merge — a side-effect-only
// diamond arm. (The arm being EXACTLY {gep, store, br} — no other gate — is
// checked by `classifyGuardedStoreArm`, which owns the loud decline on any miss.)
bool guardedShadowStoreShapeImpl(StoreInst *SI, const TaintSet &taint,
                                 DominatorTree &DT, LoopInfo &LInfo) {
  auto M = matchQramAccess(SI, taint, DT, LInfo, /*allowTaintedControl=*/true);
  if (!M || M->Origin.Kind != OriginResult::Alloca || !M->IsStore)
    return false;
  BasicBlock *ArmBB = SI->getParent();
  BasicBlock *Pred = ArmBB->getSinglePredecessor();
  BasicBlock *Merge = ArmBB->getSingleSuccessor();
  if (!Pred || !Merge)
    return false;
  auto *BI = dyn_cast<BranchInst>(Pred->getTerminator());
  if (!BI || !BI->isConditional() ||
      !taint.Tainted.count(BI->getCondition()))
    return false;
  BasicBlock *S0 = BI->getSuccessor(0), *S1 = BI->getSuccessor(1);
  if (!((S0 == ArmBB && S1 == Merge) || (S1 == ArmBB && S0 == Merge)))
    return false;
  // Reject a NESTED diamond (Rule 10 — do NOT lean on clang's incidental
  // AND-flattening of `if(a){if(b){...}}` into one compound condition). If the
  // branch block `Pred` is ITSELF control-dependent on another tainted br, the
  // store sits inside an OUTER tainted region: accepting the inner diamond
  // standalone would guard the store on the INNER condition only, silently
  // dropping the outer guard (a verify-clean wrong unitary). v1 accepts only a
  // top-level (depth-1) diamond; a genuine nest declines loudly (the carve returns
  // NotQram → generic decline, or `classifyGuardedStoreArm` → NotApplicable →
  // `recoverRegion`'s nested decline). Reuses the same control-dependence test.
  if (instUnderTaintedControl(BI, taint, DT))
    return false;
  return true;
}

// The carve verdict for `declineTaintEscapes` (Inc 3). A tainted-pointer
// load/store is in QRAM's domain: it is Accepted (the emitter lowers it),
// loud-Declined with a pattern-naming message (fired HERE — per-access info
// suffices; the alloca-WIDE declines stay in the emitter), or NotQram (falls to
// the generic loud decline). A tainted address-gen GEP is carved so only its
// memop renders the verdict. TOTALITY: every tainted-pointer memop is Accept,
// Decline, or NotQram (→ generic kMsgOther/kMsgStore) — never a silent gap.
// (`QramCarve` is declared in QramLowering.h — the carve consumer's enum.)
QramCarve classifyQramCarve(const Instruction *I, const TaintSet &taint,
                            DominatorTree &DT, LoopInfo &LInfo,
                            const char *&Msg) {
  // A tainted address-gen GEP whose users are all pointer consumers (load/store/
  // gep) is carved — suppress its generic decline; its memop owns the verdict. An
  // escaping use (the gep captured as a value / ptrtoint'd) or a control-region
  // gep falls to the generic decline. (Avoids a duplicate message on the gep.)
  if (auto *GEP = dyn_cast<GetElementPtrInst>(I)) {
    if (!taint.Tainted.count(const_cast<GetElementPtrInst *>(GEP)))
      return QramCarve::NotQram;
    if (instUnderTaintedControl(GEP, taint, DT)) {
      // iw81.7 — a store address-gep in a GuardedStoreArm arm: defer with its
      // store (the sole user of a single-use address gep). SUPPRESS the generic
      // decline so `detectControlRegions` reaches the region.
      for (const User *U : GEP->users())
        if (auto *SU = dyn_cast<StoreInst>(U))
          if (SU->getPointerOperand() == GEP &&
              guardedShadowStoreShapeImpl(const_cast<StoreInst *>(SU), taint, DT,
                                          LInfo))
            return QramCarve::DeferControl;
      // bd 3c6m.13 → 3c6m.14 Inc 3 — a const-global QROM-read address gep under
      // tainted control (via the load user, the sole user of a single-use gep). A
      // CLAIMABLE read (provable/maskable bounds) DEFERS like the guarded store:
      // suppress the escape decline so PredMux (round 2: `repropagateControlMerges`
      // compositions) / `detectControlRegions` adjudicate the region — a deferred
      // read is always resolved (flattened+lowered, or the region's own loud
      // decline), never silent (the iw81.7 divergence fence). An unclaimable
      // would-be QROM read keeps the precise bounds signpost. Still a DECLINE.
      for (const User *U : GEP->users())
        if (auto *LU = dyn_cast<LoadInst>(U))
          if (LU->getPointerOperand() == GEP) {
            if (classifyQromReadUnderControlImpl(const_cast<LoadInst *>(LU), taint,
                                                 DT, LInfo, nullptr, nullptr) !=
                QromClaim::No)
              return QramCarve::DeferControl;
            if (isQromReadBlockedOnlyByControl(const_cast<LoadInst *>(LU), taint,
                                               DT, LInfo)) {
              Msg = kMsgQromUnderControlBounds;
              return QramCarve::Decline;
            }
          }
      return QramCarve::NotQram;
    }
    for (const User *U : GEP->users()) {
      if (const auto *LU = dyn_cast<LoadInst>(U))
        if (LU->getPointerOperand() == GEP)
          continue;
      if (const auto *SU = dyn_cast<StoreInst>(U))
        if (SU->getPointerOperand() == GEP)
          continue;
      if (const auto *GU = dyn_cast<GetElementPtrInst>(U))
        if (GU->getPointerOperand() == GEP)
          continue;
      return QramCarve::NotQram;  // the address escapes as a value — generic.
    }
    return QramCarve::Accept;  // pure address-gen — carve it.
  }

  Value *PtrOp = nullptr;
  if (auto *LI = dyn_cast<LoadInst>(I))
    PtrOp = const_cast<Value *>(LI->getPointerOperand());
  else if (auto *SI = dyn_cast<StoreInst>(I))
    PtrOp = const_cast<Value *>(SI->getPointerOperand());
  else
    return QramCarve::NotQram;

  if (!taint.Tainted.count(PtrOp))
    return QramCarve::NotQram;  // classical-address access (value-tainted store →
                                // generic kMsgStore; out of QRAM scope).
  if (instUnderTaintedControl(I, taint, DT)) {
    // iw81.7 — a bounded-alloca tainted-index STORE in a depth-1 diamond arm is a
    // GuardedStoreArm candidate: defer to `detectControlRegions` (which flattens
    // the diamond, then `lowerShadowMemory` emits the guarded store). A LOAD or a
    // deeper/off-shape access is NOT deferred — it stays the generic decline
    // (jumptable kMsgOther); detection never touches it.
    if (auto *SI = dyn_cast<StoreInst>(I))
      if (guardedShadowStoreShapeImpl(const_cast<StoreInst *>(SI), taint, DT,
                                      LInfo))
        return QramCarve::DeferControl;
    // bd 3c6m.13 → 3c6m.14 Inc 3 — a const-global QROM read under tainted control.
    // CLAIMABLE (provable/maskable bounds) → DEFER (see the gep branch above);
    // would-be-QROM but unclaimable → the precise bounds signpost. Loads only: a
    // const global cannot be stored (the store paths above own their own verdicts).
    if (auto *LI = dyn_cast<LoadInst>(I)) {
      if (classifyQromReadUnderControlImpl(const_cast<LoadInst *>(LI), taint, DT,
                                           LInfo, nullptr, nullptr) !=
          QromClaim::No)
        return QramCarve::DeferControl;
      if (isQromReadBlockedOnlyByControl(const_cast<LoadInst *>(LI), taint, DT,
                                         LInfo)) {
        Msg = kMsgQromUnderControlBounds;
        return QramCarve::Decline;
      }
    }
    return QramCarve::NotQram;  // ControlDetect/generic domain (jumptable kMsgOther).
  }
  if (LInfo.getLoopFor(I->getParent())) {
    Msg = kMsgQramLoop;
    return QramCarve::Decline;
  }
  if (matchQramAccess(const_cast<Instruction *>(I), taint, DT, LInfo))
    return QramCarve::Accept;  // the emitter lowers it (or width-gates fp/i128).

  // Tainted-pointer access we cannot accept → name the decline via the chain.
  if (auto *GEP = dyn_cast<GetElementPtrInst>(PtrOp)) {
    if (!GEP->hasOneUse()) {
      Msg = kMsgQramAlias;  // a shared address gep — aliasing fan-out (§6.3).
      return QramCarve::Decline;
    }
    OriginResult O = walkPtrOrigin(GEP->getPointerOperand());
    if (O.Kind == OriginResult::Bad) {
      Msg = O.Msg;
      return QramCarve::Decline;
    }
    // A clean single origin that failed the offset/shape cleanliness (e.g. a
    // dynamic byte offset, sel_single) → generic loud decline (safe, not silent).
    return QramCarve::NotQram;
  }
  // Pointer is not a gep (inttoptr / addrspacecast / phi / argument …) — walk it.
  OriginResult O = walkPtrOrigin(PtrOp);
  if (O.Kind == OriginResult::Bad) {
    Msg = O.Msg;
    return QramCarve::Decline;
  }
  return QramCarve::NotQram;
}

// §2.8(iii): is the value `V` (a loaded cell value) OBSERVED — does it flow,
// through any chain of tainted SSA users, into a sink that reads the intermediate
// array state? An observation between two stores reads an INTERMEDIATE array state
// that a later store-reversal would corrupt; the emitter loud-declines that shape
// rather than silently leak (owner decision 6 — an unprovable reversal invariant is
// a loud decline). Three sinks, all present at emitter time (after `lowerIOSinks`,
// before `lowerMeasures`/`lowerRotations`):
//   * a `ret` (the value leaves the function);
//   * a `@cq_measure_<sfx>` front-end measurement sink (not yet lowered here);
//   * a `@cqrt_tape_write_<W>` I/O OUTPUT sink (Inc 3 — `lowerIOSinks` already
//     lowered a `printf(arr[p])` to a tape write; WITHOUT this the output-observed
//     load lowered + then tripped the CONFUSING spine `kMsgDivergentArm` instead of
//     the clean `kMsgQramMidSeq`. bd 7z9k.3 over-decline hardening #1).
// CONSERVATIVE: an unrecognized observation path is not a miscompile here (the
// spine's closure check leaks it safely anyway, §6.7) — only a missed diagnostic.
bool isObservedValue(Value *V) {
  SmallVector<Value *, 8> Work{V};
  SmallPtrSet<Value *, 16> Seen;
  while (!Work.empty()) {
    Value *X = Work.pop_back_val();
    if (!Seen.insert(X).second)
      continue;
    for (User *U : X->users()) {
      if (isa<ReturnInst>(U))
        return true;
      if (auto *CI = dyn_cast<CallInst>(U)) {
        const Function *Callee = CI->getCalledFunction();
        StringRef N = Callee ? Callee->getName() : StringRef();
        if (N.starts_with("cq_measure_") || N.starts_with("cqrt_tape_write_"))
          return true;
      }
      if (auto *I = dyn_cast<Instruction>(U))
        Work.push_back(I);  // follow every SSA user (forward reachability).
    }
  }
  return false;
}

// Does the loaded value `V` flow COHERENTLY into a `ret` / `cq_invert` escape —
// i.e. through tainted reversible ops, WITHOUT first passing a collapse/observe
// sink? This is the precondition for the kMsgQramCohEscape decline (the no-cloning
// fence above). The walk STOPS at a `@cq_measure_*` measurement sink or a
// `@cqrt_tape_write_*` I/O sink (both COLLAPSE/observe the value — its coherence is
// already gone, so anything downstream is classical, not a coherent escape); it
// returns true the moment it reaches a `ret` or a `@cq_invert_*` escape by any
// other path. CONSERVATIVE (Prime Directive): following every SSA user can only
// over-detect an escape, which over-declines (safe), never under-declines. Runs at
// emitter time (after `lowerIOSinks`, before `lowerMeasures`/`lowerOps`), so the
// arithmetic chain is still raw LLVM and `cq_measure_` is still the front-end form.
bool coherentlyEscapesToReturn(Value *V) {
  SmallVector<Value *, 8> Work{V};
  SmallPtrSet<Value *, 16> Seen;
  while (!Work.empty()) {
    Value *X = Work.pop_back_val();
    if (!Seen.insert(X).second)
      continue;
    for (User *U : X->users()) {
      if (isa<ReturnInst>(U))
        return true;  // a coherent return of the (transformed) loaded value.
      if (auto *CI = dyn_cast<CallInst>(U)) {
        const Function *Callee = CI->getCalledFunction();
        StringRef N = Callee ? Callee->getName() : StringRef();
        if (N.starts_with("cq_invert_"))
          return true;  // manual-inversion escape (Phase 8) — same no-cloning wall.
        if (N.starts_with("cq_measure_") || N.starts_with("cqrt_tape_write_"))
          continue;  // a COLLAPSE/observe sink — coherence already gone; do not
                     // descend through its (void/classical) result. This `continue`
                     // only skips THIS user; the loop still examines the value's
                     // OTHER users, so a value that is BOTH taped/measured AND
                     // coherently returned still trips the `ret` below (verified) —
                     // the stop cannot hide a coherent escape.
      }
      if (auto *I = dyn_cast<Instruction>(U))
        Work.push_back(I);  // follow the forward tainted-reversible chain.
    }
  }
  return false;
}


// ── bd `xdu2` / L-1a W1 — the rail-bank structural helpers (file-local, beside the
//    provenance walk they CALL; SCOPE_L1a §0 H4 / §2's carve discipline) ─────────

// A canonical rail-bank CELL ADDRESS: `matchAddressGep` in its CLASSICAL-index
// form (array-decay `[N x E], base, 0, idx` OR the flat element form `E, base,
// idx` — the same two spellings `matchQramAccess` accepts), over cells of exactly
// `CellTy`, resolving to `Origin` with a provable ZERO net base offset.
//
// ⚠ The `!taint.Tainted.count(RawIndex)` conjunct is CLAUSE C2 and it is the axis
// separator: a TAINTED index is Phase 7.5's (`qramCarveVerdict`) and must keep
// 7.5's own decline. `matchAddressGep`'s `requireTaintedIndex` parameter already
// separates the two axes; this calls it with `false` and then requires the
// NEGATION, so the axes cannot merge by accident at either caller.
bool railBankCellAddress(GetElementPtrInst *G, const TaintSet &taint,
                         const OriginResult &Origin, Type *CellTy,
                         Value *&RawIndex) {
  Type *GotTy = nullptr;
  RawIndex = nullptr;
  if (!matchAddressGep(G, taint, RawIndex, GotTy,
                       /*requireTaintedIndex=*/false))
    return false;
  if (GotTy != CellTy)
    return false;
  if (taint.Tainted.count(RawIndex))
    return false;  // C2 — 7.5's axis, and it keeps 7.5's string.
  return isDirectOriginPtr(G->getPointerOperand(), Origin);
}

// Is `V` a provable WHOLE-ARRAY constant-zero initializer value for `ArrTy`?
// `clang -O1` spells `bool b[8] = {0}` as `store i64 0, ptr %b` and `bool b[2] =
// {0}` as `store i16 0, ptr %b` — NOT as a memset (MEASURED on this floor, Rule 9:
// "stock LLVM IR is not stable"). Both must be recognized or the C6 / C2′ clauses
// below become unreachable behind a spurious C1 escape decline.
bool wholeArrayConstantZero(const DataLayout &DL, Value *V, Type *ArrTy) {
  auto *C = dyn_cast<Constant>(V);
  if (!C || !C->isNullValue())
    return false;
  return DL.getTypeStoreSize(C->getType()).getFixedValue() ==
         DL.getTypeStoreSize(ArrTy).getFixedValue();
}

// The rail-bank verdict proper (see QramLowering.h for the clause table, the
// staging constraint and both retirement triggers). PURE ANALYSIS.
RailBankCarve railBankCarveVerdictImpl(StoreInst *SI, const TaintSet &taint,
                                       DominatorTree &DT, LoopInfo &LI,
                                       ScalarEvolution &SE, const char *&outMsg,
                                       RailBankShape *outShape) {
  outMsg = nullptr;

  // ── ENTRY. Every `NotBank` below leaves the input to its existing owner
  //    byte-for-byte: the generic `kMsgStore` / `kMsgOther` decline is unmoved,
  //    and so is every QRAM verdict (which the caller asked FIRST).
  if (!SI->isSimple())
    return RailBankCarve::NotBank;
  Value *StoreVal = SI->getValueOperand();
  if (!taint.Tainted.count(StoreVal))
    return RailBankCarve::NotBank;  // a classical store is never a rail bank.
  auto *G = dyn_cast<GetElementPtrInst>(SI->getPointerOperand());
  if (!G)
    return RailBankCarve::NotBank;  // a direct scalar/whole-object store.
  // C2, stated as a conjunct even though the CALLER's ordering already makes it
  // unreachable (`qramCarveVerdict` answers `NotQram` for a store only when the
  // pointer is UNtainted). L3's mirror: a shared ordering premise that is true
  // "for the callers it then had" is exactly what stops being true when a caller
  // moves, so the axis is enforced here as well, not only upstream.
  if (taint.Tainted.count(G))
    return RailBankCarve::NotBank;
  Value *RawIndex = nullptr;
  Type *CellTy = nullptr;
  if (!matchAddressGep(G, taint, RawIndex, CellTy,
                       /*requireTaintedIndex=*/false))
    return RailBankCarve::NotBank;  // non-canonical / struct / vector address.
  if (taint.Tainted.count(RawIndex))
    return RailBankCarve::NotBank;  // C2 — 7.5's axis.
  // THE PUN FENCE — the same question `matchQramAccess` asks at its `AccTy !=
  // CellTy` line (the 38t2 Rule-13 clearance): the memop's ACCESSED type must BE
  // the cell type, or a sub-width type-punned access would resolve the ABI width
  // from the ORIGIN and mint a wrong-width gate stream — verify-clean and wrong.
  // ⚠ RETIREMENT TRIGGER, BOTH DIRECTIONS: this conjunct and `matchQramAccess`'s
  // are one fence with two spellings because the two classifiers cannot share a
  // body (see the header). If either moves, the other moves in the same change.
  if (StoreVal->getType() != CellTy)
    return RailBankCarve::NotBank;
  Loop *L = LI.getLoopFor(SI->getParent());
  if (!L)
    return RailBankCarve::NotBank;  // a bank cell is written once per TRIP; a
                                    // straight-line tainted array store is not a
                                    // bank and keeps its generic decline (this is
                                    // what leaves `control_classical_call_arm_
                                    // reject_localarray_store.ll` untouched).

  // ── C1 — a non-escaping bounded LOCAL array.
  OriginResult Origin = walkPtrOrigin(G->getPointerOperand(), /*Depth=*/0,
                                      /*AllowDynamicAlloca=*/true);
  if (Origin.Kind != OriginResult::Alloca) {
    // A `Bad` origin (heap / inttoptr / multi-origin / no provenance) and a
    // GLOBAL array both land here. Runtime stack allocas reach the separate
    // extent proof below; every other bank still needs a function-local object
    // whose cells the pass can own.
    outMsg = kMsgBankShape;
    return RailBankCarve::RejectShape;
  }
  AllocaInst *AI = Origin.AI;
  // The object must be allocated at most once on every function activation.
  // Entry placement and constant extent are NOT that proof: clang -O1 emits a
  // constant-folded source VLA after preceding code, and a genuine VLA is an
  // `alloca T, i64 %n`.  Conversely, an alloca in any CFG cycle is re-executed
  // even when LoopInfo cannot name an irreducible natural loop.  Asking whether
  // the block terminator can reach back to the alloca is the execution-count
  // question directly; the bounded reachability query fails conservatively.
  if (instReaches(AI->getParent()->getTerminator(), AI)) {
    outMsg = kMsgBankDynamic;
    return RailBankCarve::RejectShape;
  }
  if (!isDirectOriginPtr(G->getPointerOperand(), Origin)) {
    outMsg = kMsgBankShape;  // a dynamic / non-zero base offset — index unclean.
    return RailBankCarve::RejectShape;
  }
  auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
  const bool RuntimeSized = AI->isArrayAllocation();
  Value *Extent = RuntimeSized ? AI->getArraySize() : nullptr;
  uint64_t N = 0;
  if (RuntimeSized) {
    // Increment A deliberately admits only `int b[n]`: its i32 cells already
    // ARE handle storage.  `_Bool b[n]` is i8 and needs a dynamic object rewrite
    // with a separately-proven byte extent; do not silently claim it here.
    if (AI->getAllocatedType() != CellTy || !CellTy->isIntegerTy(32)) {
      outMsg = kMsgBankWidth;
      return RailBankCarve::RejectWidth;
    }
    if (!Extent || taint.Tainted.count(Extent) ||
        !indexIsAddressWidth(RawIndex, G->getPointerOperand(),
                             SI->getModule()->getDataLayout())) {
      outMsg = kMsgBankIndex;
      return RailBankCarve::RejectIndex;
    }
  } else {
    // The origin-array/cell agreement + `N != 0`, `matchQramAccess`'s two shape
    // conjuncts (same retirement trigger as the pun fence above). A `[0 x iW]`
    // bank has no cell, so every index is OOB — a degenerate shape, declined.
    if (!AT || AT->getElementType() != CellTy || AT->getNumElements() == 0) {
      outMsg = kMsgBankShape;
      return RailBankCarve::RejectShape;
    }
    N = AT->getNumElements();
  }
  const DataLayout &DL = SI->getModule()->getDataLayout();

  // The alloca-WIDE user scan — the reusable non-escape proof, modelled on
  // `processShadowAlloca`'s (`kMsgQramEscape` / `kMsgQramMixed` / `kMsgQramInit`)
  // but asked HERE rather than in an emitter, because this increment ships no
  // emitter. EVERY user of the bank must be a canonical cell address, a direct
  // zero-offset cell access, a lifetime marker, or a provable full constant-zero
  // initializer. Anything else is an escape.
  SmallVector<StoreInst *, 4> Stores;
  SmallVector<LoadInst *, 8> Loads;
  SmallVector<Instruction *, 4> Inits;
  SmallVector<IntrinsicInst *, 2> LifetimeStarts;
  SmallVector<IntrinsicInst *, 2> LifetimeEnds;
  for (User *U : AI->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI) {
      outMsg = kMsgBankEscape;  // a ConstantExpr view of the address.
      return RailBankCarve::RejectShape;
    }
    if (auto *UG = dyn_cast<GetElementPtrInst>(UI)) {
      Value *Idx = nullptr;
      if (!railBankCellAddress(UG, taint, Origin, CellTy, Idx)) {
        outMsg = kMsgBankMixed;  // a classical-index byte view / a tainted index.
        return RailBankCarve::RejectShape;
      }
      // ── C4 — no aliasing fan-out. ⚠ A cell address used by BOTH a load and the
      //    store is ADMITTED here where `matchQramAccess`'s `GEP->hasOneUse()`
      //    refuses it: see the header. What is refused instead is any user that is
      //    not a simple load/store OF THE CELL TYPE THROUGH THIS ADDRESS — a
      //    chained gep, a `ptrtoint`, a call argument, an atomic, a punned width.
      for (User *GU : UG->users()) {
        if (auto *LD = dyn_cast<LoadInst>(GU)) {
          if (LD->isSimple() && LD->getPointerOperand() == UG &&
              LD->getType() == CellTy) {
            Loads.push_back(LD);
            continue;
          }
        } else if (auto *ST = dyn_cast<StoreInst>(GU)) {
          if (ST->isSimple() && ST->getPointerOperand() == UG &&
              ST->getValueOperand()->getType() == CellTy) {
            Stores.push_back(ST);
            continue;
          }
        }
        outMsg = kMsgBankAlias;
        return RailBankCarve::RejectAlias;
      }
      continue;
    }
    if (auto *LD = dyn_cast<LoadInst>(UI)) {
      // A direct zero-offset read of cell 0 — `clang -O1` emits this for `b[0]`
      // (MEASURED: `N5b_noninjective_var_index.c`'s measure loop). `walkPtrOrigin`
      // + `isDirectOriginPtr` already proved the zero offset by construction here.
      if (LD->isSimple() && LD->getType() == CellTy) {
        Loads.push_back(LD);
        continue;
      }
      outMsg = kMsgBankMixed;  // a volatile/atomic or punned-width whole-object read.
      return RailBankCarve::RejectShape;
    }
    if (auto *ST = dyn_cast<StoreInst>(UI)) {
      if (ST->isSimple() && ST->getPointerOperand() == AI) {
        if (AT && wholeArrayConstantZero(DL, ST->getValueOperand(), AT)) {
          Inits.push_back(ST);  // `= {0}` as `-O1` actually spells it.
          continue;
        }
        if (ST->getValueOperand()->getType() == CellTy) {
          Stores.push_back(ST);  // a direct zero-offset write of cell 0.
          continue;
        }
        outMsg = kMsgBankInit;  // a non-zero / partial whole-object seed.
        return RailBankCarve::RejectShape;
      }
      outMsg = kMsgBankEscape;  // the ADDRESS is the stored value — it escapes.
      return RailBankCarve::RejectShape;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(UI)) {
      Intrinsic::ID Id = II->getIntrinsicID();
      if (Id == Intrinsic::lifetime_start || Id == Intrinsic::lifetime_end) {
        (Id == Intrinsic::lifetime_start ? LifetimeStarts : LifetimeEnds)
            .push_back(II);
        continue;
      }
      if (Id == Intrinsic::memset || Id == Intrinsic::memset_inline) {
        // The `processShadowAlloca` §2.6 argument, verbatim in its rail form: the
        // model seeds every cell |0⟩, so ONLY a constant ZERO fill covering the
        // WHOLE array is representable. A non-zero (or short, or non-constant)
        // fill seeds classical contents no rail carries — a later read of an
        // un-overwritten cell would be 0 in the model and the fill in truth.
        auto *Fill = dyn_cast<ConstantInt>(II->getArgOperand(1));
        auto *Len = dyn_cast<ConstantInt>(II->getArgOperand(2));
        if (AT && Fill && Fill->isZero() && Len &&
            Len->getZExtValue() == DL.getTypeStoreSize(AT).getFixedValue()) {
          Inits.push_back(II);
          continue;
        }
        outMsg = kMsgBankInit;
        return RailBankCarve::RejectShape;
      }
    }
    outMsg = kMsgBankEscape;  // a call argument, ptrtoint, cmp, phi, select …
    return RailBankCarve::RejectShape;
  }

  // ⚠ OWNER RULING D1 (2026-09-14) — an alloca with NO initializer at all is
  // admitted as well as one with a provable constant zero, because the owner's file
  // writes `bool b0[3];` with no `= {0}`, and bd `z9t1` already rules that an
  // `undef` seed at a SOURCE `cq_theta` becomes the type's concrete zero AT THE
  // ALLOCATION. This is a deliberate COMPOSITION with `z9t1`, and it inherits that
  // ruling's DISCLOSURE and all three of its RETIREMENT TRIGGERS (`CLAUDE.md` §4c;
  // the disclosure in the two-halves form is `IMPL_A.md` §6). An initializer that IS
  // present must additionally DOMINATE the bank store — a re-zeroing write reachable
  // inside the loop denotes a different program (it would re-prepare cells mid-
  // cascade), and proving that is cheaper than arguing about it.
  for (Instruction *Init : Inits)
    if (!DT.isReachableFromEntry(Init->getParent()) || !DT.dominates(Init, SI)) {
      outMsg = kMsgBankInit;
      return RailBankCarve::RejectShape;
    }

  // ── C3 — the cell width must have a REVERSIBLE COPY.
  // ⚠ NOT `abiWidthFromType(...).empty()`: `OpcodeSupport.h` is explicit that i128
  // has a width string and NO reversible copy, and an fp cell has a width and no
  // `cqrt_copy_f*` either. Both halves are pinned (`_nowidth_cell` / `_fp_cell`).
  StringRef Abi = abiWidthFromType(CellTy);
  if (Abi.empty() || !widthHasReversibleCopy(Abi)) {
    outMsg = kMsgBankWidth;
    return RailBankCarve::RejectWidth;
  }

  // ── C4 (second half) — exactly ONE store site in the whole bank, and it is this
  //    one. Two writers of one bank are two rails per cell; the per-trip mint the
  //    promoter and the type rewrite are built on has no meaning for that shape.
  if (Stores.size() != 1 || Stores.front() != SI) {
    outMsg = kMsgBankMultiStore;
    return RailBankCarve::RejectAlias;
  }

  // ── C2′ — INJECTIVITY (NEW, and Prime-Directive load-bearing). If two
  //    activations can write one cell, a later trip's SEED load reads a previously
  //    stored HANDLE and the promotion forwards the wrong value.
  // ⚠ H-1, FOUND BY THIS INCREMENT'S OWN SELF-ATTACK AND MEASURED AS A `Bank`
  // OVER-ACCEPT before this conjunct existed (`H1_nested_outer_rewrite.c`:
  // `for (k<2) for (i<3) b[i] = cq_theta(b[i], .5);`). Everything C2′ proves is
  // about ONE ACTIVATION of `L`: `{0,+,1}` over `Trips == N` visits each cell once
  // PER ACTIVATION. If an enclosing loop re-executes `L`, cell `i` is written once
  // per outer trip and the second outer trip's SEED LOAD reads a previously-stored
  // HANDLE — which is, verbatim, the hazard C2′ exists to prevent, one level up.
  // *** THE LESSON, and it is L2's: when a set is proven over a closure, ask what
  // OTHER closure re-runs the proof. *** Declining the nested walk is the Prime
  // Directive answer; admitting it needs a proof about the OUTER loop that this
  // increment does not have, and `CLAUDE.md` already declines nested loops broadly.
  //
  // ⚠ CROSS-SEAM RETIREMENT TRIGGER, ADDED AT THE 2026-09-14c MERGE GATE AND
  // STATED IN THE DIRECTION THE NEXT EDITOR NEEDS (the L3 MIRROR: when a
  // predicate acquires a second caller, read the trigger and say which way you
  // are using it). THIS CONJUNCT IS LOAD-BEARING FOR A CALLER THAT IS NOT THIS
  // FILE. `promoteRailBankCells` (`RailBankPromote.cpp`, clause B6) calls this
  // verdict and refuses NOTHING of its own about an ENCLOSING loop — B1 refuses
  // an access in a SUB-loop only. Track B's round-2 mutant **M12 measured that
  // deleting this line makes the promoter FIRE** on `for (k…) for (i…) b[i] =
  // …`, forwarding the previous outer trip's stored HANDLE as a classical zero:
  // a hidden `|0⟩` assertion on an entangled rail that no fence in the tree can
  // see, because the rail/wire/uncompute machinery is MEMORY-BLIND by
  // construction (`SCOPE_L1a.md` §4.1). *** RELAXING THIS LINE WITHOUT GIVING
  // THE PROMOTER A CLAUSE OF ITS OWN, IN THE SAME CHANGE, IS AN OVER-ACCEPT —
  // a wrong unitary, not a wrong decline. *** Pinned from the other side by
  // `railbank_promote_reject_nested_outer_loop.ll`.
  if (L->getParentLoop()) {
    outMsg = kMsgBankNested;
    return RailBankCarve::RejectIndex;
  }
  // ⚠ AND ITS IRREDUCIBLE TWIN (bd xdu2.4 Rule-13 F-B1, P1, pre-existing for
  // FIXED banks on the HEAD oracle). An irreducible cycle has NO LoopInfo
  // parent, so the line above cannot see it: a `goto` back into a do-while
  // re-ran the walk, the second trip's theta read the rail stored by the first,
  // and the promoter forwarded a fresh |0> seed instead — Ry·Ry on one rail
  // compiled as Ry on a new one, exit 0, 2b clean. The question is the one the
  // allocation clause asks: can control leave `L` and reach its header again?
  {
    SmallVector<BasicBlock *, 4> Exits;
    L->getExitBlocks(Exits);
    for (BasicBlock *E : Exits)
      if (instReaches(&E->front(), &L->getHeader()->front())) {
        outMsg = kMsgBankNested;
        return RailBankCarve::RejectIndex;
      }
    // A `returns_twice` call (setjmp) re-runs code with NO CFG edge, so the
    // reachability question above cannot see it (round-2 review B F-R2B-2,
    // pre-existing for fixed banks): refuse the function outright.
    if (AI->getFunction()->callsFunctionThatReturnsTwice()) {
      outMsg = kMsgBankNested;
      return RailBankCarve::RejectIndex;
    }
  }
  const SCEV *IdxS = SE.getSCEV(RawIndex);
  const auto *AR = dyn_cast<SCEVAddRecExpr>(IdxS);
  if (!AR || AR->getLoop() != L || !AR->isAffine()) {
    outMsg = kMsgBankIndex;
    return RailBankCarve::RejectIndex;
  }
  // ⚠ H-17 — the recurrence must not WRAP. `{0,+,1}` over an index type narrower
  // than the trip count revisits cell 0 after 2^bits trips, so "start 0, step 1,
  // Trips ≤ N" is injective only modulo no-self-wrap. `-O1` widens most induction
  // variables and stamps `nuw nsw`, so this is nearly always available; when it is
  // not, declining is the safe direction (MEASURED: it costs none of the four
  // `Bank` anchors).
  if (!AR->hasNoSelfWrap()) {
    outMsg = kMsgBankIndex;
    return RailBankCarve::RejectIndex;
  }
  const auto *Start = dyn_cast<SCEVConstant>(AR->getStart());
  const auto *Step = dyn_cast<SCEVConstant>(AR->getStepRecurrence(SE));
  if (!Start || !Start->getAPInt().isZero() || !Step ||
      !Step->getAPInt().isOne()) {
    outMsg = kMsgBankIndex;
    return RailBankCarve::RejectIndex;
  }
  // The proven trip count. Fixed banks retain the constant proof below. A VLA
  // instead requires the exact symbolic trip count + 1 to equal the classical
  // alloca extent. Equal SSA spelling is neither required nor sufficient: pointer
  // equality handles the canonical SCEV, and `isKnownPredicateAt` additionally
  // admits context-proven forms such as `smax(n, 1) == n` below a dominating
  // source guard `n > 0`.
  const SCEV *ExactBTC = SE.getBackedgeTakenCount(L);
  if (isa<SCEVCouldNotCompute>(ExactBTC) || !L->getExitingBlock() ||
      !L->getLoopLatch()) {
    outMsg = kMsgBankIndex;
    return RailBankCarve::RejectIndex;
  }
  const SCEV *TripS =
      SE.getAddExpr(ExactBTC, SE.getOne(ExactBTC->getType()));
  const SCEV *ExtentS = nullptr;
  uint64_t Trips = 0;
  if (RuntimeSized) {
    ExtentS = SE.getSCEV(Extent);
    if (isa<SCEVCouldNotCompute>(ExtentS) ||
        ExtentS->getType() != TripS->getType() ||
        !scevEqualInLoop(ExtentS, TripS, L,
                         L->getLoopLatch()->getTerminator(), SE)) {
      outMsg = kMsgBankTotality;
      return RailBankCarve::RejectTotality;
    }
  }

  // The additional CONSTANT trip-count proof for fixed banks. Runtime banks
  // already discharged the symbolic equality above. ⚠ `CLAUDE.md` Rule 18 records
  // `getSmallConstantMaxTripCount` returning 4294967295 on some vacuous bounds and
  // 0 on others — NEITHER return value distinguishes vacuity — so the bound is read
  // as an `APInt` AT ITS OWN WIDTH, and vacuity is excluded by three separate
  // conjuncts instead of by a magic return value:
  //   (a) the EXACT backedge count is the SAME uniqued SCEV as the constant MAX,
  //       so the count is a proof and not merely an upper bound;
  //   (b) the all-ones APInt (SCEV's "no useful bound" at any width) is refused;
  //   (c) REACHABILITY-TOTAL: ONE exiting block and one latch, so there is no
  //       second exit the count did not model.
  // ⚠ `hasFiniteClassicalTripBound` (`LoopLowering.cpp`) is CITED, NOT CALLED: it
  // is the 7.4 `break` path over `getSymbolicMaxBackedgeTakenCount` and answers a
  // different question (does the loop terminate), where C2′ asks how many DISTINCT
  // cells the index visits.
  const auto *MaxC =
      dyn_cast<SCEVConstant>(SE.getConstantMaxBackedgeTakenCount(L));
  if (!RuntimeSized) {
    const auto *ExactC = dyn_cast<SCEVConstant>(ExactBTC);
    if (!MaxC || !ExactC || MaxC != ExactC) {
      outMsg = kMsgBankIndex;
      return RailBankCarve::RejectIndex;
    }
    const APInt &BT = MaxC->getAPInt();
    if (BT.isAllOnes() || BT.getActiveBits() > 32) {
      outMsg = kMsgBankIndex;
      return RailBankCarve::RejectIndex;
    }
    Trips = BT.getZExtValue() + 1;
    if (Trips > N) {
      outMsg = kMsgBankIndex;  // the index leaves the bank / revisits a cell.
      return RailBankCarve::RejectIndex;
    }
  }

  // ── C6 — TOTALITY. After handle-storage conversion a never-written cell
  //    reads as handle `0`, and `h0` is a LIVE RAIL in this runtime
  //    (`cqrt_alloc_i1(0) -> h0`). With C2′'s `{0,+,1}` index, an exact trip
  //    count equal to the fixed N or runtime extent and one exit, the index visits
  //    every cell exactly once.
  // ⚠ CORRECTED 2026-09-15 (bd `test_C_libtooling-de8n`, F-α1's attached finding).
  //    This clause used to end *"cells 0…N-1 are each written exactly once"*, and
  //    that is a claim about WRITES which trip count alone cannot support: the
  //    owner's own program stores inside the `if (a >= 3)` ARM, so a trip whose
  //    condition is false VISITS its cell and writes nothing. The sentence was true
  //    of the PROMOTED shape and false of the RAW one, and it was load-bearing for
  //    the handle-storage conversion. VISITING is what C6 proves; WRITING is C7(b)'s,
  //    below, and it is what separates `Bank` from `BankRaw`.
  if (!RuntimeSized && Trips != N) {
    outMsg = kMsgBankTotality;
    return RailBankCarve::RejectTotality;
  }
  // Every read of the bank is either (i) of the cell THIS trip writes — the
  // per-trip seed read and the partially-available re-read, both of which the
  // promoter (C5) removes — or (ii) after the loop, i.e. every FEASIBLE path to it
  // passes the loop header (bd xdu2.10: `readFollowsLoopOnEveryPath`, not header
  // dominance), where C2′ + `Trips == N` proves every cell has been VISITED
  // (written is C7(b)'s). Anything else reads a cell in a state the
  // rail model cannot name.
  // ⚠ REACHABILITY IS AN API PRECONDITION HERE, NOT AN OPTIMIZATION — the same
  // lesson `ArmClassify`'s F2 records for `LazyValueInfo` ("asking LVI about a value
  // defined after the branch SIGSEGVs a Release `cq-opt`"). `declineTaintEscapes`
  // walks EVERY block of the function, unreachable ones included, and an unreachable
  // block has no `DomTreeNode`; `SI` itself is protected by the entry gate (an
  // unreachable block is in no `Loop`, so `LI.getLoopFor` already returned null),
  // but a bank LOAD in one is not. Refuse rather than ask.
  bool AnyReadInsideL = false;
  for (LoadInst *LD : Loads) {
    if (!DT.isReachableFromEntry(LD->getParent())) {
      outMsg = kMsgBankTotality;
      return RailBankCarve::RejectTotality;
    }
    if (L->contains(LD->getParent())) {
      auto *LG = dyn_cast<GetElementPtrInst>(LD->getPointerOperand());
      Value *LIdx = nullptr;
      if (!LG || !railBankCellAddress(LG, taint, Origin, CellTy, LIdx) ||
          SE.getSCEV(LIdx) != IdxS) {
        outMsg = kMsgBankTotality;  // an in-loop read of some OTHER cell.
        return RailBankCarve::RejectTotality;
      }
      AnyReadInsideL = true;  // C7(a) — see below; the read itself is admitted.
      continue;
    }
    // ⚠ "PRECEDE" IS A SEMANTIC CLAIM ABOUT EXECUTIONS, not about dominance
    // (bd xdu2.10). Dominance by the header was the old, syntactic spelling;
    // `readFollowsLoopOnEveryPath` asks it with the guards' implied conditions
    // and answers yes for dominance as a special case. See its header for what
    // it proves and what it leaves to the clauses below.
    // The semantic path is for reads under CLASSICAL control only (F-1, step
    // (0) of `readFollowsLoopOnEveryPath`): a read INSIDE a tainted branch's
    // region (reachable from it before its merge) may be hoisted/speculated by
    // the flatten, so only dominance speaks. NOT `instUnderTaintedControl`,
    // which also refuses a read after a fully-merged tainted diamond (round 3).
    if (!DT.dominates(L->getHeader(), LD->getParent()) &&
        (readInsideTaintedRegion(LD, taint, DT) ||
         !readFollowsLoopOnEveryPath(LD, L, DT, DL, taint))) {
      // ⚠ `kMsgBankTotality` is shared by six C6 sub-clauses, so a decline
      // fixture's diagnostic cannot say WHICH one fired (Rule-13 round 1,
      // P3-4). This env-gated anchor (the `CQ_CTRL_DBG` lever the carve's
      // caller already uses for `railbank [Bank]`; byte-neutral when unset)
      // names the read-order sub-clause so `railbank_readorder_reject_*` pin it
      // by text, not only by mutation.
      if (::getenv("CQ_CTRL_DBG"))
        errs() << "CQ_CTRL_DBG: railbank C6 read-order refused: " << *LD << "\n";
      outMsg = kMsgBankTotality;  // a read the loop does not precede.
      return RailBankCarve::RejectTotality;
    }
    if (RuntimeSized) {
      // Every surviving read of a runtime bank must itself be an exact 0..n-1
      // walk.  This is the preparation/measurement-bound relation: the alloca,
      // write loop and each read loop agree by SCEV, not by operand spelling.
      auto *LG = dyn_cast<GetElementPtrInst>(LD->getPointerOperand());
      Value *LIdx = nullptr;
      Loop *RL = LI.getLoopFor(LD->getParent());
      if (!LG || !railBankCellAddress(LG, taint, Origin, CellTy, LIdx) ||
          !indexIsAddressWidth(LIdx, LG->getPointerOperand(), DL) ||
          !RL || RL == L || RL->getParentLoop() || !RL->getExitingBlock() ||
          !RL->getLoopLatch()) {
        outMsg = kMsgBankTotality;
        return RailBankCarve::RejectTotality;
      }
      const auto *LAR = dyn_cast<SCEVAddRecExpr>(SE.getSCEV(LIdx));
      if (!LAR || LAR->getLoop() != RL || !LAR->isAffine() ||
          !LAR->hasNoSelfWrap()) {
        outMsg = kMsgBankTotality;
        return RailBankCarve::RejectTotality;
      }
      const auto *LStart = dyn_cast<SCEVConstant>(LAR->getStart());
      const auto *LStep = dyn_cast<SCEVConstant>(LAR->getStepRecurrence(SE));
      const SCEV *LBTC = SE.getBackedgeTakenCount(RL);
      if (!LStart || !LStart->getAPInt().isZero() || !LStep ||
          !LStep->getAPInt().isOne() || isa<SCEVCouldNotCompute>(LBTC)) {
        outMsg = kMsgBankTotality;
        return RailBankCarve::RejectTotality;
      }
      const SCEV *LTrips =
          SE.getAddExpr(LBTC, SE.getOne(LBTC->getType()));
      if (LTrips->getType() != ExtentS->getType() ||
          !scevEqualInLoop(LTrips, ExtentS, RL, LD, SE)) {
        outMsg = kMsgBankTotality;
        return RailBankCarve::RejectTotality;
      }
    }
  }

  // A runtime bank must be live at every access. Accept at most one explicit
  // start/end interval, require the start to dominate every access, and refuse
  // an end that can reach one. A dynamic stackrestore can end the VLA lifetime
  // without naming the alloca, so apply the same reachability fence to it.
  // Clang's normal lifetime end / restore after the measurement loop passes.
  if (RuntimeSized) {
    if (LifetimeStarts.size() > 1 || LifetimeEnds.size() > 1) {
      outMsg = kMsgBankLifetime;
      return RailBankCarve::RejectShape;
    }
    for (IntrinsicInst *Start : LifetimeStarts) {
      // Dominance is not liveness: a start re-executed by a cycle (e.g. at the
      // top of the write loop) kills the cells earlier trips wrote (round-2
      // review B F-R2B-1). The start must run at most once, like the alloca.
      if (instReaches(Start->getParent()->getTerminator(), Start)) {
        outMsg = kMsgBankLifetime;
        return RailBankCarve::RejectShape;
      }
      for (StoreInst *ST : Stores)
        if (!DT.dominates(Start, ST)) {
          outMsg = kMsgBankLifetime;
          return RailBankCarve::RejectShape;
        }
      for (LoadInst *LD : Loads)
        if (!DT.dominates(Start, LD)) {
          outMsg = kMsgBankLifetime;
          return RailBankCarve::RejectShape;
        }
    }
    for (IntrinsicInst *End : LifetimeEnds) {
      for (StoreInst *ST : Stores)
        if (instReaches(End, ST)) {
          outMsg = kMsgBankLifetime;
          return RailBankCarve::RejectShape;
        }
      for (LoadInst *LD : Loads)
        if (instReaches(End, LD)) {
          outMsg = kMsgBankLifetime;
          return RailBankCarve::RejectShape;
        }
    }
    for (Instruction &I : instructions(*AI->getFunction()))
      if (auto *II = dyn_cast<IntrinsicInst>(&I))
        if (II->getIntrinsicID() == Intrinsic::stackrestore &&
            DT.dominates(AI, II) && stackRestoreMayFree(II, AI, DT)) {
          for (StoreInst *ST : Stores)
            if (instReaches(II, ST)) {
              outMsg = kMsgBankLifetime;
              return RailBankCarve::RejectShape;
            }
          for (LoadInst *LD : Loads)
            if (instReaches(II, LD)) {
              outMsg = kMsgBankLifetime;
              return RailBankCarve::RejectShape;
            }
        }
  }

  // Everything above holds for BOTH accept verdicts, so the shape is handed back
  // for both: the PROMOTER consumes it on `BankRaw` (its input), the marker/type
  // rewrite on `Bank`.
  if (outShape) {
    outShape->Alloca = AI;
    outShape->L = L;
    outShape->RawIndex = RawIndex;
    outShape->Extent = Extent;
    outShape->CellTy = CellTy;
    outShape->ElemAbi = Abi;
    outShape->Count = N;
    outShape->Trips = Trips;
    outShape->RuntimeSized = RuntimeSized;
  }

  // ── C7 — TYPE-REWRITABLE SHAPE. `Bank` vs `BankRaw`.
  //
  // ⚠ THIS CLAUSE EXISTS BECAUSE `Bank` DID NOT IMPLY WHAT ITS OWN L8 RETIREMENT
  // TRIGGER PROMISED (bd `test_C_libtooling-de8n`, P1, Rule-13 round 1 finding
  // F-α1). The trigger says the `Bank` arm "stops breaking and becomes a
  // `continue`" when the taint rule + type rewrite land — i.e. `Bank` IS the
  // accept predicate of record. Before this clause it was strictly WEAKER than
  // the shape the type rewrite can serve, and the gap was reachable from plain
  // `-O1` C (`probes/r2_nopreheader.ll`: `carve=[Bank] promo=0`, MEASURED on the
  // 2026-09-15 ORACLE `0e280fc6`; three plain-C families reproduce it).
  //
  // THE TWO HAZARDS, each stated as the property the type rewrite needs — not as a
  // structural echo of the promoter's clauses, which live in another file and were
  // cleared for another purpose (`MERGE_FILINGS.md` F-1's lesson):
  //
  //   (a) NO IN-LOOP READ SURVIVES. A per-trip cell read INSIDE the walk loop is
  //       the PARTIALLY AVAILABLE second load of `SCOPE_L1a.md` §0 H3: the store
  //       sits in a conditional arm, GVN does not forward it, and after the
  //       `[N x cell]` → `[N x i32]` rewrite the pred edge reads the initializer
  //       `0` AS A HANDLE — and `h0` is a LIVE RAIL in this runtime
  //       (`cqrt_alloc_i1(0) -> h0`), so that is a live-qubit alias, not a null.
  //       The per-activation promoter (`RailBankPromote.cpp`) exists to remove
  //       exactly these reads; a bank it did NOT promote still carries them.
  //
  //   (b) THE WRITE IS TOTAL PER TRIP. C6 above proves `Trips == N` over an
  //       injective `{0,+,1}` index and then its own comment concludes "cells
  //       0…N-1 are each written exactly once". ⚠ THAT SENTENCE WAS TRUE OF THE
  //       PROMOTED SHAPE AND FALSE OF THE RAW ONE — the owner's own program stores
  //       inside the `if (a >= 3)` arm, so a trip whose condition is false writes
  //       NOTHING and that cell reads as handle 0 after the rewrite. Trip count is
  //       not write count. (F-α1's attached finding; corrected here and at C6.)
  //
  // THE PROOF FOR (b), because "obviously executes every iteration" is how a
  // wrong totality claim gets into a Release build:
  //   * `SI`'s block `B` is IN `L` (the entry gate computed `L` as `SI`'s loop);
  //   * `B` DOMINATES the latch. `L` is a NATURAL loop, so its header dominates
  //     every block of `L`; therefore `B` (if not the header) cannot be reached
  //     before the header on any path into the loop. If some header→latch path
  //     avoided `B`, prefixing it with entry→preheader→header would be an
  //     entry→latch path avoiding `B` — contradicting dominance. So EVERY
  //     header→latch path contains `B`, i.e. `B` runs on every trip that reaches
  //     the latch. (If `B` IS the header the conclusion is immediate.)
  //   * the ONLY exiting block is the latch, so the only way to reach the code
  //     AFTER the loop is through the latch. Trips that never reach it (a
  //     `noreturn` call, an `unreachable`, a `ret`/`resume` inside `L`, an
  //     infinite inner loop) do not reach the after-loop reads either, and an
  //     `invoke` whose unwind destination is outside `L` makes its own block
  //     exiting, which `getExitingBlock()` then refuses by returning null.
  // Hence: every cell read after the loop was written by the trip that owned it.
  //
  // ⚠ WHAT `BankRaw` IS AND IS NOT. It is NOT a decline — every clause C1–C6 held,
  // so `outMsg` stays null and the caller keeps the generic `kMsgStore` it would
  // have fired anyway. It is the PROMOTER'S INPUT, and it must NEVER become an
  // accept: `RailBankPromote.cpp`'s B6 requires it, and `TaintPropagation.cpp`'s
  // L8 trigger is now explicit that only `Bank` may ever stop declining.
  //
  // ⚠ RETIREMENT TRIGGER, BOTH DIRECTIONS. (i) The day the promoter is taught to
  // normalise a shape this clause still calls `BankRaw`, this clause must be
  // re-derived against the promoter's NEW postcondition in the same change — the
  // invariant the tree relies on is *promoter input = `BankRaw`, promoter output =
  // `Bank`*, and `railbank_promote_*` pin it from the other side. (ii) The day
  // anything other than the promoter is allowed to produce a `Bank` bank, (a) and
  // (b) are the only two properties the type rewrite may assume; add the third
  // here, not at the consumer.
  BasicBlock *Latch = L->getLoopLatch();
  const bool WriteIsTotalPerTrip =
      Latch && L->getExitingBlock() == Latch &&
      DT.dominates(SI->getParent(), Latch);
  if (AnyReadInsideL || !WriteIsTotalPerTrip)
    return RailBankCarve::BankRaw;
  return RailBankCarve::Bank;
}

}  // namespace

// bd fn1q increment 4, Rule-13 round 1 finding P1 — THE LAUNDERING FENCE.
//
// ⚠ WHY THIS EXISTS. PredMux's E4 classical-table admission is reached EXACTLY
// when `classifyQromReadUnderControl` returned `No`, and the first version of
// that admission claimed its own taint test made the two "disjoint by
// construction". THAT WAS FALSE AND IT WAS A P1. QROM returns `No` for SIX
// reasons, and one of them is the `coherentlyEscapesToReturn` NO-CLONING fence —
// where the load IS a genuine QROM read, refused because its value escapes
// coherently to a `ret`. Such a read's index is often UNTAINTED AT ROUND-1 TAINT
// and becomes tainted only once the flatten turns a region-internal phi into a
// select. The classical arm's `Taint.Tainted.count(...)` test therefore passed,
// the region was claimed and flattened, and `cqrt_qram_load_<W>` was emitted on a
// SUPERPOSED index rail that is never uncomputed and never freed — a
// verify-clean silent miscompile, measured: ORACLE exit 1 with a loud decline,
// subject exit 0 with 0 bytes of stderr.
//
// THAT IS CLAUDE.md's L1 "PREDICATE species" verbatim: a fence asked at ROUND-1
// taint while the lowering decides at FINAL taint. The cure is the standing one —
// ask the question QROM itself asks, by CALLING its predicate rather than
// re-deriving it (Rule 14).
//
// ⚠ AND THE EMITTER-SIDE BACKSTOP DOES NOT COVER IT. By the time `lowerQramReads`
// runs, the select merge is already `cqrt_copy_*_controlled` VOID calls, so
// `coherentlyEscapesToReturn`'s forward SSA walk stops at the merge and never
// reaches the `ret`. The CLAIM-TIME fence is the only effective one.
bool qromShapedReadTaintsIndexAfterFlatten(
    LoadInst *LI, const TaintSet &taint, DominatorTree &DT, LoopInfo &LInfo,
    const SmallPtrSetImpl<BasicBlock *> &Region, const BasicBlock *RegionEntry) {
  auto M = matchQramAccess(LI, taint, DT, LInfo, /*allowTaintedControl=*/true,
                           /*allowUntaintedIndex=*/true);
  if (!M.has_value() || M->IsStore || !M->RawIndex)
    return false;  // not a table-access shape at all — not QROM's business.
  if (taint.Tainted.count(M->RawIndex))
    return true;   // tainted NOW: unambiguously QROM's.
  // Tainted AFTER the flatten — the case the P1 turned on. Same predicate QROM's
  // own index gate uses, so the two cannot drift.
  return indexWillTaintAfterFlatten(M->RawIndex, taint, Region, RegionEntry);
}

// bd fn1q increment 4 — exported wrapper over the SAME known-bits bounds proof
// `classifyQromReadUnderControlImpl` uses for its `Provable` verdict, so
// PredMux's E4 CLASSICAL-table admission and the QROM index gate ask ONE
// question with ONE answer (Rule 14). A second spelling of "is this index in
// bounds" is the drbq Inc-3 (b') defect.
//
// ⚠ WHAT IS DELIBERATELY *NOT* ASKED HERE, and the difference is the whole point
// of the separate entry point: this wrapper does NOT require the index to be
// TAINTED and does NOT require `widthHasQramCell`. Those two are QROM's
// preconditions because QROM mints a `cqrt_qram_load_<W>` on a quantum index.
// The PredMux caller is asking about a CLASSICAL read whose value never becomes
// a qubit — it occupies an `_hl` literal slot (§5.2) — so neither applies.
// Everything that IS asked is the bounds proof itself, unchanged, including its
// pointer-index-width gate and its total (poison-aware) obligation.
bool classicalTableIndexKnownInBounds(LoadInst *LI, const TaintSet &taint,
                                      DominatorTree &DT, LoopInfo &LInfo) {
  auto M = matchQramAccess(LI, taint, DT, LInfo, /*allowTaintedControl=*/true,
                           /*allowUntaintedIndex=*/true);
  if (!M.has_value() || M->IsStore || M->Origin.Kind != OriginResult::Global)
    return false;
  if (!M->Gep || !M->RawIndex || M->Count == 0)
    return false;
  return qromIndexKnownInBounds(M->RawIndex, M->Gep, M->Count,
                                LI->getModule()->getDataLayout());
}

// bd xdu2.4 — a classical runtime VLA can be just as safe to speculate as the
// fixed table above, but LLVM's generic dereferenceability query does not carry
// the relation between `alloca i32, i64 %n` and a separate loop's exact trip
// count.  Prove that relation here beside the shared pointer-origin machinery.
// This deliberately does NOT accept heap provenance, tainted extents/indices,
// fixed allocas, offset bases, non-scalar cells, or an allocation that does not
// dominate the region.  Those are different proof obligations and remain loud
// declines.  No QRAM operation is involved or emitted.
bool classicalRuntimeAllocaReadIsInBounds(
    LoadInst *LI, const TaintSet &taint, DominatorTree &DT, LoopInfo &LInfo,
    ScalarEvolution &SE, const BasicBlock *RegionEntry) {
  if (!LI || !RegionEntry || !LI->isSimple())
    return false;
  Loop *L = LInfo.getLoopFor(const_cast<BasicBlock *>(RegionEntry));
  if (!L || !L->contains(LI->getParent()) || !L->getExitingBlock() ||
      !L->getLoopLatch())
    return false;

  auto *G = dyn_cast<GetElementPtrInst>(LI->getPointerOperand());
  if (!G)
    return false;
  Value *RawIndex = nullptr;
  Type *CellTy = nullptr;
  if (!matchAddressGep(G, taint, RawIndex, CellTy,
                       /*requireTaintedIndex=*/false) ||
      taint.Tainted.count(RawIndex) || LI->getType() != CellTy)
    return false;

  OriginResult Origin =
      walkPtrOrigin(G->getPointerOperand(), /*Depth=*/0,
                    /*AllowDynamicAlloca=*/true);
  if (Origin.Kind != OriginResult::Alloca ||
      !isDirectOriginPtr(G->getPointerOperand(), Origin))
    return false;
  AllocaInst *AI = Origin.AI;
  Value *Extent = AI->isArrayAllocation() ? AI->getArraySize() : nullptr;
  const DataLayout &DL = LI->getModule()->getDataLayout();
  if (!Extent || AI->getAllocatedType() != CellTy ||
      (!CellTy->isIntegerTy() && !CellTy->isFloatingPointTy()) ||
      taint.Tainted.count(Extent) || !DT.dominates(AI, RegionEntry))
    return false;
  const uint64_t CellBytes = DL.getTypeAllocSize(CellTy).getFixedValue();
  if (AI->getAlign() < LI->getAlign() ||
      CellBytes % LI->getAlign().value() != 0)
    return false;

  // The allocation must still be live at the speculation point. A stackrestore
  // can invalidate a dynamic alloca without naming it, and lifetime.end names it
  // only through an intrinsic argument. If either can run after the allocation
  // and before the region entry, the source may avoid the load on its false arm
  // while flattening would execute it, so decline instead of treating source UB
  // on the true arm as a licence to invent UB on the false one.
  if (!indexIsAddressWidth(RawIndex, G->getPointerOperand(), DL))
    return false;
  for (Instruction &I : instructions(*AI->getFunction())) {
    auto *II = dyn_cast<IntrinsicInst>(&I);
    if (!II)
      continue;
    // F-B6: storage that is (re)started after the region entry can be reached
    // is not live there either. Every lifetime.start must precede the hoist.
    if (II->getIntrinsicID() == Intrinsic::lifetime_start &&
        getUnderlyingObject(II->getArgOperand(1)) == AI &&
        !DT.dominates(II, RegionEntry->getTerminator()))
      return false;
    if (!DT.dominates(AI, II) ||
        !instReaches(II, RegionEntry->getTerminator()))
      continue;
    if (II->getIntrinsicID() == Intrinsic::stackrestore &&
        stackRestoreMayFree(II, AI, DT))
      return false;
    if (II->getIntrinsicID() == Intrinsic::lifetime_end &&
        getUnderlyingObject(II->getArgOperand(1)) == AI)
      return false;
  }

  const auto *AR = dyn_cast<SCEVAddRecExpr>(SE.getSCEV(RawIndex));
  if (!AR || AR->getLoop() != L || !AR->isAffine() || !AR->hasNoSelfWrap())
    return false;
  const auto *Start = dyn_cast<SCEVConstant>(AR->getStart());
  const auto *Step = dyn_cast<SCEVConstant>(AR->getStepRecurrence(SE));
  if (!Start || !Start->getAPInt().isZero() || !Step ||
      !Step->getAPInt().isOne())
    return false;

  const SCEV *ExactBTC = SE.getBackedgeTakenCount(L);
  if (isa<SCEVCouldNotCompute>(ExactBTC))
    return false;
  const SCEV *Trips =
      SE.getAddExpr(ExactBTC, SE.getOne(ExactBTC->getType()));
  const SCEV *ExtentS = SE.getSCEV(Extent);
  return !isa<SCEVCouldNotCompute>(ExtentS) &&
         Trips->getType() == ExtentS->getType() &&
         scevEqualInLoop(Trips, ExtentS, L, RegionEntry->getTerminator(), SE);
}

// bd q2wk (3c6m.14 Inc 5) — exported wrapper over the Inc-3 predicate so
// PredMux's E6 gate and the QROM index gate ask the SAME question with the SAME
// answer (Rule 14: one predicate, one meaning). See the definition above for the
// argument; the E6 use is PRD §4.4b rule (B).
bool valueWillTaintAfterFlatten(
    const Value *V, const TaintSet &taint,
    const SmallPtrSetImpl<BasicBlock *> &Region,
    const BasicBlock *RegionEntry) {
  return indexWillTaintAfterFlatten(V, taint, Region, RegionEntry);
}

// bd 20xt.4 — the taint-blind STRUCTURAL const-global QROM-read shape, the shared
// truth for the Phase-6 spec-clone ADMIT paths (`scanBody` in SpecializeReject,
// and — Inc 2 — `isSpeculatableDataflow`/`isSpeculatablePureCalleeBody` in
// PredMuxFlatten). Reuses the SAME structural helpers `matchQramAccess` itself
// calls — `matchAddressGep` (canonical array-decay/flat gep + trailing index) +
// `walkPtrOrigin` (single statically-shaped origin) + `isDirectOriginPtr` (clean
// zero base offset) — plus the identical array/const/width gates, so the admit can
// never STRUCTURALLY diverge from the emitter's `classifyQromRead` (Rule 14, the
// carve/emit non-divergence discipline; the shared `matchQramAccess` fences off a
// silent accept). Deliberately TAINT-BLIND and DT/LInfo-free: the clone-body index
// is not in the module taint (taint stops at the caller→callee boundary), so the
// index-taint proof, the straight-line/loop gates AND the bounds proof are DEFERRED
// — re-proven by the emitter under the clone's own `cloneTaint` (`lowerQramReads`,
// where the seeded index IS tainted and the intra-clone flatten has already masked
// a NeedsMask index). A load whose gep is multi-use, off a non-const/uninitialised
// or non-array global, punned to a different access type, or of an unsupported cell
// width returns false (the safe over-decline stays with the whitelist's catch-all).
// Pure analysis (no mutation, no taint dependence).
bool qromReadShapeInScope(const llvm::LoadInst *LI) {
  if (!LI->isSimple())
    return false;  // volatile/atomic loads are not a QROM read.
  // Pure analysis (no mutation); const_cast to reuse the non-const structural
  // helpers `matchQramAccess` itself calls.
  auto *GEP = dyn_cast<GetElementPtrInst>(
      const_cast<Value *>(LI->getPointerOperand()));
  if (!GEP || !GEP->hasOneUse())
    return false;  // single-use address gep (sole user is this load).
  // `matchAddressGep` needs a `TaintSet` only to test the trailing-index taint,
  // which `requireTaintedIndex=false` waives — an empty set is unread.
  TaintSet Empty;
  Value *RawIndex = nullptr;
  Type *CellTy = nullptr;
  if (!matchAddressGep(GEP, Empty, RawIndex, CellTy,
                       /*requireTaintedIndex=*/false))
    return false;  // non-canonical / off-shape address gep.
  if (LI->getType() != CellTy)
    return false;  // pun fence (38t2): the accessed type must BE the cell type.
  Value *Base = GEP->getPointerOperand();
  OriginResult Origin = walkPtrOrigin(Base);
  if (Origin.Kind != OriginResult::Global)
    return false;  // a QROM table is a GLOBAL (an alloca is Shadow, a different ABI).
  if (!isDirectOriginPtr(Base, Origin))
    return false;  // dynamic / non-zero base offset — index not clean.
  auto *OT = dyn_cast<ArrayType>(Origin.GV->getValueType());
  if (!OT || OT->getElementType() != CellTy || OT->getNumElements() == 0)
    return false;  // origin shape must be `[N x cell]`, N > 0 (a `[0 x _]` decl is OOB).
  Type *E = OT->getElementType();
  if (!E->isIntegerTy() && !E->isFloatingPointTy())
    return false;  // scalar cells only.
  if (!Origin.GV->isConstant() || !Origin.GV->hasInitializer())
    return false;  // a QROM table must be a constant initialized global.
  // Mirror the emitter's element-width gate (`lowerQramReads` L~1175): a cell whose
  // width has no reversible qram copy (fp128 / i128 / …) declines HERE at the admit,
  // so `scanBody` never accepts a shape the clone emitter would loud-decline.
  return widthHasQramCell(abiWidthFromType(E));
}

// The single carve entry point for `declineTaintEscapes` (Inc 3, replacing the
// per-family `isAccepted*` predicates). For a tainted-pointer `load`/`store`/`gep`
// returns Accept (the emitter owns it), Decline (with `outMsg`, a pattern-naming
// diagnostic the caller fires source-located), or NotQram (fall to the generic
// taint-escape decline). The emitter classifiers (`classifyQromRead` /
// `classifyShadowAccess`) share the same `matchQramAccess`, so carve and emit can
// never diverge.
QramCarve qramCarveVerdict(const llvm::Instruction *I, const TaintSet &taint,
                           DominatorTree &DT, LoopInfo &LInfo,
                           const char *&outMsg) {
  return classifyQramCarve(I, taint, DT, LInfo, outMsg);
}

// bd `xdu2` / L-1a W1 — the SINGLE rail-bank verdict (see QramLowering.h for the
// clause table, the staging constraint and both retirement triggers). Consulted by
// `declineTaintEscapes` AFTER `qramCarveVerdict` has answered `NotQram`, and — once
// it lands — by the per-activation promoter, so the two can never diverge.
RailBankCarve railBankCarveVerdict(const llvm::StoreInst *SI,
                                   const TaintSet &taint, DominatorTree &DT,
                                   LoopInfo &LI, ScalarEvolution &SE,
                                   const char *&outMsg,
                                   RailBankShape *outShape) {
  return railBankCarveVerdictImpl(const_cast<StoreInst *>(SI), taint, DT, LI, SE,
                                  outMsg, outShape);
}

bool guardedShadowStoreShape(StoreInst *SI, const TaintSet &taint,
                             DominatorTree &DT, LoopInfo &LInfo) {
  return guardedShadowStoreShapeImpl(SI, taint, DT, LInfo);
}

QromClaim classifyQromReadUnderControl(
    LoadInst *LI, const TaintSet &taint, DominatorTree &DT, LoopInfo &LInfo,
    uint64_t *OutCount, const llvm::SmallPtrSetImpl<llvm::BasicBlock *> *Region,
    bool inBennettClone, bool *OutIndexBecomesOpaque) {
  return classifyQromReadUnderControlImpl(LI, taint, DT, LInfo, OutCount, Region,
                                          inBennettClone, OutIndexBecomesOpaque);
}

// 3c6m.14 Inc 3 — volatile-const global-load fold (see QramLowering.h). Pure
// module-local curation of the openlibm anti-const-fold idiom; every gate below
// is load-bearing (external linkage / a store / an escaping user / an atomic /
// an unfoldable offset+type each leave the global untouched for the existing
// loud declines — over-declining is safe, a wrong fold would be a silent
// wrong-value miscompile in the classical remainder).
bool foldVolatileConstGlobalLoads(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  for (GlobalVariable &G : M.globals()) {
    if (!G.hasLocalLinkage() || !G.hasDefinitiveInitializer())
      continue;
    // Never-stored / address-never-escaping proof: every transitive user
    // (through gep/bitcast — instruction or constexpr — chains) is a plain
    // non-atomic load. Any other user (store, call, ptrtoint, cmp, phi/select,
    // …) forfeits the fold for the WHOLE global.
    SmallVector<const User *, 16> Work(G.user_begin(), G.user_end());
    SmallPtrSet<const User *, 16> Seen;
    SmallVector<LoadInst *, 8> VolLoads;
    bool Clean = true;
    while (!Work.empty() && Clean) {
      const User *U = Work.pop_back_val();
      if (!Seen.insert(U).second)
        continue;
      if (const auto *LI = dyn_cast<LoadInst>(U)) {
        if (LI->isAtomic()) {
          Clean = false;
          break;
        }
        if (LI->isVolatile())
          VolLoads.push_back(const_cast<LoadInst *>(LI));
        continue;  // a plain load neither stores nor escapes the address.
      }
      if (isa<GEPOperator>(U) || isa<BitCastOperator>(U)) {
        Work.append(U->user_begin(), U->user_end());
        continue;
      }
      Clean = false;
    }
    if (!Clean || VolLoads.empty())
      continue;
    for (LoadInst *LI : VolLoads) {
      // Fold only a load whose pointer strips to G through CONSTANT offsets
      // (the direct `@twom1000` load: offset 0; the `&atanlo[3]` constexpr
      // byte-gep: offset 24). A variable-index gep load stays live — that is
      // the QROM read's domain, never the fold's.
      APInt Off(DL.getIndexTypeSizeInBits(LI->getPointerOperand()->getType()),
                0);
      Value *Base = LI->getPointerOperand()->stripAndAccumulateConstantOffsets(
          DL, Off, /*AllowNonInbounds=*/true);
      if (Base != &G)
        continue;
      // In-bounds proof BEFORE folding: `AllowNonInbounds=true` admits negative
      // or past-the-end constant offsets, and `ConstantFoldLoadFromConst` treats
      // bytes past the initializer as POISON (a non-null constant), so an
      // out-of-bounds volatile read would silently fold to poison instead of
      // riding the existing decline. An OOB access is UB in C and never fires on
      // the injected openlibm bodies (twom1000 @0, atanlo[3] @24 are exactly
      // in-bounds), but leave it standing anyway (over-declining is safe): the
      // whole `[Off, Off+loadSize)` byte range must lie inside the initializer.
      uint64_t GBytes = DL.getTypeAllocSize(G.getValueType());
      uint64_t LdBytes = DL.getTypeStoreSize(LI->getType());
      if (Off.isNegative() || Off.getActiveBits() > 63 ||
          Off.getZExtValue() > GBytes || GBytes - Off.getZExtValue() < LdBytes)
        continue;  // out-of-bounds constant offset — never fold to poison.
      Constant *C =
          ConstantFoldLoadFromConst(G.getInitializer(), LI->getType(), Off, DL);
      if (!C)
        continue;  // offset/type the initializer cannot produce — leave.
      LI->replaceAllUsesWith(C);
      LI->eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}

// bd etiq — volatile-const LOCAL fold: the alloca sibling of
// foldVolatileConstGlobalLoads (see QramLowering.h). Same curation target (the
// openlibm anti-const-fold idiom, here `volatile double vd2 = 0x1.0p32;` in
// s_cbrtl.c), same deliberate volatile-fold choice. The local proof is
// NARROWER than the global one — direct users only, exact-type reads, and
// per-load DOMINANCE by the single constant store (an alloca has no
// initializer, so an undominated load reads uninitialized memory and folding
// it would invent a value; the global fold has no such hazard). Every gate
// forfeits the WHOLE alloca untouched — the unfolded volatile access then
// rides the existing loud declines (over-declining is safe; a wrong fold
// would be a silent wrong-value miscompile in the classical remainder).
bool foldVolatileConstAllocaLoads(Module &M, const TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Built lazily, at most once per function; erasing non-terminator
    // instructions changes no CFG edge, so it stays valid across folds.
    std::optional<DominatorTree> DT;
    // Static allocas live in the entry block (clang -O1). Snapshot the
    // candidates first — the fold below erases from this very block.
    SmallVector<AllocaInst *, 8> Cands;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (A->isStaticAlloca())
          Cands.push_back(A);
    for (AllocaInst *A : Cands) {
      // Whole-alloca user scan: EXACTLY one non-atomic store of a Constant
      // with A as the pointer operand, any number of non-atomic loads and
      // lifetime markers, nothing else. Any other user — a call, a gep (even
      // offset 0), a ptrtoint/cmp/phi/select, A as a store's VALUE operand —
      // is an escape or an off-idiom view and forfeits the fold.
      StoreInst *TheStore = nullptr;
      SmallVector<LoadInst *, 4> Loads;
      SmallVector<IntrinsicInst *, 4> Lifetimes;
      bool Clean = true, SawVolatile = false;
      for (User *U : A->users()) {
        if (auto *LI = dyn_cast<LoadInst>(U)) {
          if (LI->isAtomic()) {
            Clean = false;
            break;
          }
          SawVolatile |= LI->isVolatile();
          Loads.push_back(LI);
          continue;
        }
        if (auto *SI = dyn_cast<StoreInst>(U)) {
          if (SI->getValueOperand() == A || SI->isAtomic() || TheStore) {
            Clean = false;  // address stored away / atomic / a second store.
            break;
          }
          SawVolatile |= SI->isVolatile();
          TheStore = SI;
          continue;
        }
        if (auto *II = dyn_cast<IntrinsicInst>(U)) {
          if (II->getIntrinsicID() == Intrinsic::lifetime_start ||
              II->getIntrinsicID() == Intrinsic::lifetime_end) {
            Lifetimes.push_back(II);
            continue;
          }
        }
        Clean = false;
        break;
      }
      // Target the idiom only: at least one VOLATILE access (an all-plain
      // single-store alloca was mem2reg's to claim at -O1, never ours).
      if (!Clean || !TheStore || Loads.empty() || !SawVolatile)
        continue;
      auto *C = dyn_cast<Constant>(TheStore->getValueOperand());
      if (!C)
        continue;  // runtime value — and a TAINTED value is never a Constant,
                   // so quantum shadow allocas are structurally excluded.
      // In-slot proof (the Rule-13 posture-symmetry gate with the global
      // fold's in-bounds check): a store that overruns its alloca is UB IR —
      // unreachable from legal C at -O1, but decline rather than refine.
      const DataLayout &DL = M.getDataLayout();
      std::optional<TypeSize> Slot = A->getAllocationSize(DL);
      if (!Slot || Slot->isScalable() ||
          DL.getTypeStoreSize(C->getType()).getFixedValue() >
              Slot->getFixedValue())
        continue;
      // Exact-type reads only, each dominated by the single store (so every
      // dynamic execution of a load is preceded by ≥1 execution of the one
      // store, which always writes the same Constant). Two documented
      // conventions ride along: a load in an UNREACHABLE block is "dominated
      // by everything" and folds — sound, it never executes; and the fold is
      // single-pass in entry order, so a cascade (alloca A's store value fed
      // by alloca B's folded load) completes only when B precedes A — the
      // unfolded remainder rides PredMux E4's loud decline, an over-decline
      // only. The taint membership checks are belt-and-braces (see the
      // Constant gate): a tainted load RAUW'd to a constant would silently
      // drop quantum data.
      bool Foldable = !taint.Tainted.count(A);
      for (LoadInst *LI : Loads) {
        if (!Foldable)
          break;
        if (LI->getType() != C->getType() || taint.Tainted.count(LI)) {
          Foldable = false;
          break;
        }
        if (!DT)
          DT.emplace(F);
        if (!DT->dominates(TheStore, LI))
          Foldable = false;
      }
      if (!Foldable)
        continue;
      // Fold. Unlike the global fold (whose global carries no code and may
      // stay), the store / lifetime markers / alloca must be ERASED with the
      // loads — a surviving volatile store would still block the PredMux
      // claim (E4) exactly as before.
      for (LoadInst *LI : Loads) {
        LI->replaceAllUsesWith(C);
        LI->eraseFromParent();
      }
      TheStore->eraseFromParent();
      for (IntrinsicInst *II : Lifetimes)
        II->eraseFromParent();
      A->eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}

bool eraseDeadVolatileScalarStores(Module &M, const TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Static allocas live in the entry block at -O1. Snapshot first — the erase
    // below removes from this very block.
    SmallVector<AllocaInst *, 8> Cands;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (A->isStaticAlloca())
          Cands.push_back(A);
    for (AllocaInst *A : Cands) {
      // SCALAR only, and the name means it: one first-class int/fp slot, no
      // array allocation. The idiom this stage exists for is a one-line local;
      // an aggregate or a `[N x T]` is the QRAM Shadow path's shape, not ours.
      Type *Ty = A->getAllocatedType();
      if (A->isArrayAllocation() ||
          !(Ty->isFloatingPointTy() || Ty->isIntegerTy()))
        continue;
      // Belt-and-braces with the Ty gate above: never touch an alloca the taint
      // pass has claimed. A store-only shadow cell is not a shape we understand,
      // and the Prime Directive says leave what we cannot prove.
      if (taint.Tainted.count(A))
        continue;
      // Whole-alloca user scan, and it is the escape proof: EVERY user must be a
      // direct non-atomic exact-type store with `A` as the POINTER operand, or a
      // lifetime marker. Any other user — a load, a call, a gep (even offset 0),
      // a ptrtoint/cmp/phi/select, or `A` as a store's VALUE operand — means the
      // address is read, escapes, or is viewed off-type, and forfeits.
      SmallVector<StoreInst *, 4> Stores;
      SmallVector<IntrinsicInst *, 4> Lifetimes;
      bool Clean = true, SawVolatile = false;
      for (User *U : A->users()) {
        if (auto *SI = dyn_cast<StoreInst>(U)) {
          if (SI->getValueOperand() == A || SI->isAtomic() ||
              SI->getValueOperand()->getType() != Ty) {
            Clean = false;
            break;
          }
          SawVolatile |= SI->isVolatile();
          Stores.push_back(SI);
          continue;
        }
        if (auto *II = dyn_cast<IntrinsicInst>(U)) {
          if (II->getIntrinsicID() == Intrinsic::lifetime_start ||
              II->getIntrinsicID() == Intrinsic::lifetime_end) {
            Lifetimes.push_back(II);
            continue;
          }
        }
        Clean = false;  // a LOAD lands here too — see the zero-loads note above.
        break;
      }
      // At least one VOLATILE access, or this is not the idiom: a plain
      // store-only alloca is ordinary dead code that -O1 already removed, and
      // claiming it here would widen this stage into a general DSE it is not.
      if (!Clean || Stores.empty() || !SawVolatile)
        continue;
      // Erase the STORES, the markers, and the alloca. THIS STAGE does not touch
      // the stored VALUE — but do not read that as "the computation survives".
      // Once its only consumer is gone the value is trivially dead, and inside a
      // PredMux region the pre-existing cleanup at PredMuxFlatten.cpp:2618 takes
      // it; the shipped `slice_libm_ld80_nexttowardf` trace has ZERO `fmul_f32`.
      // That outcome is what the fenv ruling actually licenses (an op whose only
      // purpose is raising a flag has no observable effect), and the owner
      // re-affirmed it on the measured facts after the ruling was first requested
      // on the tidier, false summary. Outside a region the dead product is
      // instead lowered, uncomputed and freed — harmless, and pinned by
      // lowering_volatile_scalar_deadstore.ll.
      for (StoreInst *SI : Stores)
        SI->eraseFromParent();
      for (IntrinsicInst *II : Lifetimes)
        II->eraseFromParent();
      A->eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}

namespace {

// bd zco4 — undef-safety proof for a promotion candidate: every load of `A` must
// be preceded on EVERY path from function entry by a store to `A`, so
// PromoteMemToReg never materializes an `undef` reaching definition (reading an
// uninitialized scalar is UB in C and never appears in a real accumulator body;
// promoting it would silently invent a garbage value — the Prime-Directive
// decline, mirroring the etiq per-load dominance gate but generalized to the
// multi-store accumulator where NO single store dominates a post-merge load yet
// every path still stores first). A block is "undef-on-entry" iff some path
// entry→B carries no intervening store to `A`; a load reads a defined value iff
// its block is not undef-on-entry, OR a store to `A` precedes it within its own
// block. `Stores`/`Loads` are `A`'s direct accesses (the caller's exact-type,
// non-escaping scan). Small forward fixpoint over the CFG.
bool everyLoadIsStoreDefined(AllocaInst *A, ArrayRef<LoadInst *> Loads,
                             ArrayRef<StoreInst *> Stores, Function &F) {
  SmallPtrSet<const BasicBlock *, 16> StoreBlocks;
  for (StoreInst *S : Stores)
    StoreBlocks.insert(S->getParent());
  // undefOnEntry(B) = (B == entry) OR ∃ pred P: undefOnEntry(P) AND P has no
  // store to A (a store in P defines A before control leaves P).
  SmallPtrSet<const BasicBlock *, 16> UndefIn;
  UndefIn.insert(&F.getEntryBlock());
  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (BasicBlock &B : F) {
      if (UndefIn.count(&B))
        continue;
      for (const BasicBlock *P : predecessors(&B)) {
        if (UndefIn.count(P) && !StoreBlocks.count(P)) {
          UndefIn.insert(&B);
          Changed = true;
          break;
        }
      }
    }
  }
  for (LoadInst *L : Loads) {
    BasicBlock *B = L->getParent();
    if (!UndefIn.count(B))
      continue;  // every path into B stores A first — defined.
    bool StoreBefore = false;
    for (Instruction &I : *B) {
      if (&I == L)
        break;
      if (auto *S = dyn_cast<StoreInst>(&I))
        if (S->getPointerOperand() == A) {
          StoreBefore = true;
          break;
        }
    }
    if (!StoreBefore)
      return false;  // a store-free path reaches L — promotion would read undef.
  }
  return true;
}

}  // namespace

// bd zco4 — volatile scalar-local SSA promotion (see QramLowering.h for the full
// gate list + soundness). ACCEPT-ONLY: an alloca short of ANY gate is left
// byte-untouched for the existing loud declines (no diagnostic emitted here).
bool promoteVolatileScalarLocals(Module &M, const TaintSet &taint) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // A returns_twice/setjmp caller relies on `volatile` to keep the scalar in
    // memory across a longjmp (a non-volatile local is indeterminate after
    // longjmp — that is WHY the idiom needs volatile); promoting it to a register
    // would drop the value longjmp must restore. Decline the WHOLE function
    // (over-declining is safe; a pure libm body never calls setjmp).
    if (F.callsFunctionThatReturnsTwice())
      continue;
    // Static entry-block allocas only (clang -O1). Snapshot up front — promotion
    // erases from this very block.
    SmallVector<AllocaInst *, 8> Cands;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        if (A->isStaticAlloca())
          Cands.push_back(A);
    if (Cands.empty())
      continue;

    std::optional<DominatorTree> DT;
    SmallVector<AllocaInst *, 4> ToPromote;
    for (AllocaInst *A : Cands) {
      // Gate 1 — a single INTEGER/FP SCALAR. An array/struct is the
      // Shadow/MUX-EXCH domain; a vector is an angle-vector; a pointer scalar has
      // no reversible-copy story. Each is left for its own owner.
      Type *AllocTy = A->getAllocatedType();
      if (!(AllocTy->isIntegerTy() || AllocTy->isFloatingPointTy()))
        continue;
      // Gates 2-4 — whole-alloca user scan: the address NEVER escapes (every user
      // a direct non-atomic load/store of A at the EXACT allocated type, or a
      // lifetime/droppable intrinsic), and ≥1 access is VOLATILE (else clang
      // mem2reg already claimed it). ANY other user (gep — even offset 0 —,
      // call-arg, ptrtoint, cast, cmp, phi/select, A as a store's VALUE operand,
      // an atomic, a mismatched-type access) forfeits the WHOLE alloca.
      SmallVector<LoadInst *, 8> Loads;
      SmallVector<StoreInst *, 8> Stores;
      bool Clean = true, SawVolatile = false;
      for (User *U : A->users()) {
        if (auto *LI = dyn_cast<LoadInst>(U)) {
          if (LI->isAtomic() || LI->getType() != AllocTy) {
            Clean = false;
            break;
          }
          SawVolatile |= LI->isVolatile();
          Loads.push_back(LI);
          continue;
        }
        if (auto *SI = dyn_cast<StoreInst>(U)) {
          if (SI->getPointerOperand() != A || SI->isAtomic() ||
              SI->getValueOperand()->getType() != AllocTy) {
            Clean = false;  // address stored away / atomic / mismatched type.
            break;
          }
          SawVolatile |= SI->isVolatile();
          Stores.push_back(SI);
          continue;
        }
        if (auto *II = dyn_cast<IntrinsicInst>(U))
          if (II->isLifetimeStartOrEnd() || II->isDroppable())
            continue;  // lifetime/assume markers — PromoteMemToReg strips them.
        Clean = false;
        break;
      }
      if (!Clean || !SawVolatile || Loads.empty() || Stores.empty())
        continue;
      // Belt-and-braces: a tainted alloca POINTER would be a shadow-QRAM handle,
      // never a plain scalar accumulator — exclude it structurally (the address
      // is a classical stack slot; only the stored VALUE is ever tainted).
      if (taint.Tainted.count(A))
        continue;
      // Gate 5 — every load proven store-defined (no undef reaching def).
      if (!everyLoadIsStoreDefined(A, Loads, Stores, F))
        continue;
      // Clear volatile so the alloca is promotable, then defer the promotion
      // until all of F's candidates are collected (one PromoteMemToReg per
      // function). The stricter scan above guarantees isAllocaPromotable now.
      for (LoadInst *LI : Loads)
        LI->setVolatile(false);
      for (StoreInst *SI : Stores)
        SI->setVolatile(false);
      assert(isAllocaPromotable(A) &&
             "zco4: scanned volatile scalar must be promotable after unvolatile");
      ToPromote.push_back(A);
    }
    if (ToPromote.empty())
      continue;
    if (!DT)
      DT.emplace(F);
    PromoteMemToReg(ToPromote, *DT);
    Changed = true;
  }
  return Changed;
}

void lowerQramReads(Module &M, WidthDispatch &wd, TaintSet &taint,
                    bool inBennettClone) {
  // 1. Collect accepted reads (pure analysis; do not mutate while walking the IR).
  struct Accepted {
    LoadInst *Load;
    GetElementPtrInst *Gep;
    GlobalVariable *GV;
    StringRef ElemAbi;
    uint64_t Count;
    Value *RawIndex;
  };
  SmallVector<Accepted, 8> Reads;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LInfo;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          if (!DT) {
            DT.emplace(F);
            LInfo.emplace(*DT);
          }
          if (auto QR = classifyQromRead(LI, taint, *DT, *LInfo))
            Reads.push_back({LI, QR->Gep, QR->GV, QR->ElemAbi, QR->Count,
                             QR->RawIndex});
        }
  }
  if (Reads.empty())
    return;

  Type *I32 = Type::getInt32Ty(M.getContext());
  // Lazy array-handle birth, ONE per (function, global): a const table read N
  // times in a function shares one array handle (PRD-7.5 §2.6). The handle is a
  // CLASSICAL resource token — NOT tainted (the uncompute spine ignores it).
  DenseMap<std::pair<Function *, GlobalVariable *>, Value *> ArrayHandle;
  SmallVector<Instruction *, 16> ToErase;

  for (Accepted &R : Reads) {
    // Coherent-return no-cloning fence (Inc-1 QROM regression; memory
    // 7-5-qram-coherent-return-nocloning): `return tbl[q]` (non-`main`) returns a
    // value entangled with the LOCAL index `q`; with `q` uncomputed/leaked the
    // returned carrier is dephased to a classical mixture (verify-clean silent
    // miscompile). DECLINE — a coherent qRAM-load value cannot escape once its
    // local address is erased. A MEASURE collapses it first (immune); `main`'s ret
    // is the process-exit observation.
    if (!inBennettClone && R.Load->getFunction()->getName() != "main" &&
        coherentlyEscapesToReturn(R.Load)) {
      diagnose(R.Load, kMsgQramCohEscape);
      continue;
    }
    // bd 20xt.4 Inc 2 (blocker c Rule-13 fix): a SPECULATED clone read must be
    // in-bounds on EVERY basis state (see kMsgQramCloneUnbounded). A read that
    // reaches here NOT provably in-bounds is a straight-line clone read on an
    // unmasked speculated argument — the caller hoisted the call past its bounding
    // guard, so the read is driven OOB on the excluded basis states (out-of-contract
    // for the frozen QROM ABI: idx ∈ [0,N), OOB undefined). The direct under-control
    // read masks-or-declines exactly this; the straight-line clone emitter never runs
    // that discipline, so DECLINE here (over-declining is safe). It shares the SAME
    // `qromIndexKnownInBounds` proof the under-control claim uses (Rule 14). The
    // accept surface today is a SOURCE-masked / const / known-bits-bounded index; the
    // clone-internal-flatten-masked path (atanl's `and id, N-1`) is deferred
    // clone-control work (declines upstream at SpecializeReject today), and this fence
    // is forward-compatible — a masked i64 index that reaches here IS provably
    // in-bounds and passes. Top-level reads (inBennettClone=false) are the actual
    // program access — bounds are the source's obligation, left untouched (Inc-1).
    if (inBennettClone &&
        !qromIndexKnownInBounds(R.Gep->getOperand(R.Gep->getNumOperands() - 1),
                                R.Gep, R.Count, M.getDataLayout())) {
      diagnose(R.Load, kMsgQramCloneUnbounded);
      continue;
    }
    // Element-width gate — the carve accepted the structural shape; a cell whose
    // element width has no reversible copy DECLINES LOUDLY here, so the carve is
    // never a silent accept (§6.9). `widthHasQramCell` is int {i1,i8,i16,i32,i64}
    // + fp {f16,f32,f64,f80} (bd 38t2 — an fp cell is a faithful bit-pattern
    // CNOT-copy, NOT an angle; the f64-angle fence stays declineTaintedAngle). An
    // i128 / fp128 / unsupported cell still declines (no cqrt_qram_*_i128, no
    // sound f128 c_type).
    if (!widthHasQramCell(R.ElemAbi)) {
      diagnose(R.Load, kMsgQramCell);
      continue;
    }
    FunctionCallee AllocFn = wd.qramAllocFn(R.ElemAbi);
    FunctionCallee LoadFn = wd.qramLoadFn(R.ElemAbi);
    if (!AllocFn || !LoadFn) {
      // widthHasQramCell already proved a supported cell width, so a null here is
      // unreachable — guard defensively rather than mint a null call.
      diagnose(R.Load, kMsgQramCell);
      continue;
    }

    Function *F = R.Load->getFunction();
    auto Key = std::make_pair(F, R.GV);
    Value *Arr = ArrayHandle.lookup(Key);
    if (!Arr) {
      IRBuilder<> AB(&*F->getEntryBlock().getFirstInsertionPt());
      CallInst *A = AB.CreateCall(AllocFn, {ConstantInt::get(I32, R.Count)}, "arr");
      if (DebugLoc DL = R.Load->getDebugLoc())
        A->setDebugLoc(DL);
      Arr = A;
      ArrayHandle[Key] = A;
    }

    // bd gyc9: re-read the index FRESH from the LIVE gep's trailing operand, NOT
    // the captured `R.RawIndex` — the nested `tbl2[tbl1[q]]` read's inner-load
    // RAUW (below, an earlier loop iteration) bypasses the classify-time capture,
    // which would leave the outer call referencing the erased inner load
    // (dangling operand → verifier UAF SIGSEGV; the Shadow-side twin is the
    // self-referential store web). `matchAddressGep` proved the index is the
    // trailing gep operand, so the fresh read is the same value modulo RAUW.
    //
    // Then resolve the index handle: strip the mandatory `-O1` widening sext/zext
    // so the index is the i32 handle (Rule 15 — the widening is irrelevant to the
    // symbol). The cross-type RAUW launders the operand to its i32 handle later,
    // EXACTLY like the I/O tape-write `src` (RotationLowering §1). If the cast is
    // single-use (the gep was its only user) it dies here; otherwise it is left
    // for `lowerOps` and the source value is still the right index.
    Value *Idx = R.Gep->getOperand(R.Gep->getNumOperands() - 1);
    Instruction *DeadCast = nullptr;
    if (auto *CI = dyn_cast<CastInst>(Idx))
      if ((isa<SExtInst>(CI) || isa<ZExtInst>(CI)) &&
          taint.Tainted.count(CI->getOperand(0))) {
        Idx = CI->getOperand(0);
        if (CI->hasOneUse())
          DeadCast = CI;
      }

    IRBuilder<> B(R.Load);
    CallInst *Out = B.CreateCall(LoadFn, {Arr, Idx});
    if (DebugLoc DL = R.Load->getDebugLoc())
      Out->setDebugLoc(DL);
    // The loaded value is a tainted data producer (a copy-out): record its element
    // width (the 7.1 HandleWidth discipline) and a BirthOrder slot for stable LIFO
    // uncompute ordering, exactly like a `cq_template_*` result.
    taint.Tainted.insert(Out);
    taint.HandleWidth[Out] = R.ElemAbi;
    taint.BirthOrder[Out] = taint.NextBirth++;

    R.Load->replaceAllUsesWith(Out);
    ToErase.push_back(R.Load);  // erased first — drops the gep's only use
    ToErase.push_back(R.Gep);   // then the now-dead address-gen
    if (DeadCast) {
      taint.Tainted.erase(DeadCast);
      taint.BirthOrder.erase(DeadCast);
      ToErase.push_back(DeadCast);  // then the now-dead widening cast
    }
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

namespace {

// Phase 7.5 (bug sxuk): method-B copy-out for a load result whose SOLE, DIRECT user
// is a `cq_measure_*` sink in a non-`main` function. WITHOUT it the load result is
// the SOLE tainted data terminal, FreePoint classifies it Measured, and the
// whole-DAG reversal — INCLUDING the LOCAL array's stores — is skipped (the
// `InsertTerms.empty()` bail): the measured value stays entangled with the leaked
// local scratch array. The copy makes `Out` a NON-escaped terminal whose load+store
// chain uncomputes via the EXISTING dead-array reversal (the spine treats
// `cqrt_copy` reading src as a source-preserving sink, ChainWalk::isCopyOutSink),
// while the copy DESTINATION is the kept measured carrier — and the local array's
// stores reverse to |0>.
//
// THE INDEX RAILS ARE NO LONGER FREED (bd 5pio, owner ruling 2026-08-11). This
// comment used to continue "The reversal frees the LOCAL index rails, which is sound
// HERE precisely because the value is MEASURED: the collapse makes the index-free
// unobservable and the diagonal is the correct measurement distribution" — that
// MEASUREMENT-IMMUNITY argument is still valid on its own terms, but it is no longer
// what the compiler does. `isCopyOutSink` now seeds the 261j record freeze, the
// correlation propagates BACKWARD to the copy source's ancestors, and an index root
// whose gate is `cqrt_ry_` fails `preservesBasisUnderRecord` and is FROZEN: fully
// reverse-played, then LEFT ALLOCATED rather than freed (Rule 6's fallback).
//
// So the freeze SUPERSEDES this carve-out rather than coexisting with it, and that is
// a deliberate loss of resource cleanliness for a uniform rule — the ruling preferred
// one source-side invariant over two independent justifications, since
// measurement-immunity is a different claim from "the rail is |0>" and only the
// latter is what Rule 6 licenses. The six shipped QRAM goldens were regenerated for
// exactly these lines. (bd memory [bennett-copyout-destination-2026-08-11].) A COHERENT `ret`/`cq_invert` escape is NOT
// handled here — it is loud-declined upstream (kMsgQramCohEscape) since no-cloning
// forbids returning a clean coherent `arr[p]` once its local index is erased.
//
// Scope: `Out`'s SOLE, DIRECT user is a `cq_measure_*`. A taped load
// (cqrt_tape_write) already uncomputes (isOutputSink), so its sole user is not a
// measure here; `main` escapes anyway (process exit reclaims); an indirect
// (cast/arith-then-measure) or fan-out measure is left as-is (a Rule-6 safe leak —
// correct under measurement immunity, just not resource-cleaned). Runs AFTER the
// load's RAUW so `Out` carries the original users.
void emitCopyOutIfDirectMeasure(CallInst *Out, StringRef ElemAbi, WidthDispatch &wd,
                                TaintSet &taint) {
  if (Out->getFunction()->getName() == "main" || !Out->hasOneUse())
    return;
  auto *CI = dyn_cast<CallInst>(*Out->user_begin());
  if (!CI)
    return;  // a coherent `ret` user is declined upstream (kMsgQramCohEscape).
  const Function *Callee = CI->getCalledFunction();
  if (!Callee || !Callee->getName().starts_with("cq_measure_"))
    return;  // only a direct measure sink — measurement immunity makes the REVERSAL
             // sound; everything else leaks safely. (It used to make "and its index
             // frees" sound too; since bd 5pio those index roots are frozen and left
             // allocated, so only the store/load reversal is still bought here.)
  Instruction *U = CI;
  FunctionCallee Alloc = wd.allocFn(ElemAbi);
  // bd 38t2: `copyFnCell` (NOT the integer-only `copyFn`) so an fp cell load's
  // direct-measure copy-out mints `cqrt_copy_f<W>` — the live consumer that keeps
  // the uncontrolled fp copy from being dead ABI. Cell-local (fp cannot leak to
  // the value-arm copy paths).
  FunctionCallee Copy = wd.copyFnCell(ElemAbi);
  Type *RailTy = wd.llvmWidthType(ElemAbi);
  if (!Alloc || !Copy || !RailTy)
    return;  // no reversible copy at this cell width — leave as-is (the caller
             // already proved widthHasQramCell, so this is a defensive guard).
  IRBuilder<> B(U);  // the carrier alloc + copy land right before the escape.
  CallInst *Ret = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "qret");
  CallInst *Cp = B.CreateCall(Copy, {Out, Ret});
  if (DebugLoc DL = U->getDebugLoc()) {
    Ret->setDebugLoc(DL);
    Cp->setDebugLoc(DL);
  }
  taint.Tainted.insert(Ret);
  taint.HandleWidth[Ret] = ElemAbi;
  taint.BirthOrder[Ret] = taint.NextBirth++;
  U->replaceUsesOfWith(Out, Ret);  // the escape now carries the copy, not Out.
}

// Lower (or loud-decline) ONE candidate alloca-backed array and all its accepted
// tainted-index accesses (Phase 7.5 Inc 2). `Accesses` are in program order. The
// alloca-WIDE invariants — element width (§2.10), single-origin / no aliasing
// escape + classical initializer modeling (§2.6, §2.8(iv)), and the §2.8(iii)
// mid-sequence-observation guard — are checked here; any failure loud-declines the
// WHOLE alloca (its per-access-well-formed accesses were already carved, so opt
// exits non-zero regardless — the Inc-1 carve/emit-consistency discipline, §6.9).
void processShadowAlloca(AllocaInst *AI, ArrayRef<ShadowAccess> Accesses,
                         WidthDispatch &wd, TaintSet &taint, DominatorTree &DT) {
  StringRef ElemAbi = Accesses.front().ElemAbi;
  uint64_t Count = Accesses.front().Count;
  Instruction *Anchor = Accesses.front().MemOp;  // a real access for the !dbg.

  // Element-width gate (§2.10): a cell whose element width has no reversible copy
  // → loud decline, so the carve is never a silent accept (§6.9). `widthHasQramCell`
  // is int {i1,i8,i16,i32,i64} + fp {f16,f32,f64,f80} (bd 38t2 — an fp cell is a
  // faithful bit-pattern CNOT-copy, NOT an angle; the f64-angle fence stays
  // declineTaintedAngle). An i128 / fp128 / unsupported cell still declines.
  if (!widthHasQramCell(ElemAbi)) {
    diagnose(Anchor, kMsgQramCell);
    return;
  }
  FunctionCallee AllocFn = wd.qramAllocFn(ElemAbi);
  FunctionCallee LoadFn = wd.qramLoadFn(ElemAbi);
  FunctionCallee StoreFn = wd.qramStoreFn(ElemAbi);
  if (!AllocFn || !LoadFn || !StoreFn) {
    diagnose(Anchor, kMsgQramCell);  // unreachable past the width gate; defensive.
    return;
  }

  SmallPtrSet<Value *, 8> AccessGeps;
  for (const ShadowAccess &A : Accesses)
    AccessGeps.insert(A.Gep);

  // §2.8(iv) provenance / no-aliasing + §2.6 initializer modeling: EVERY use of the
  // alloca must be one of (a) an accepted tainted-index access gep, (b) the
  // classical initializer (`llvm.memset` — its contents are classical metadata,
  // only the count reaches the alloc), or (c) a lifetime marker. A classical-index
  // gep on the SAME alloca is a mixed access (§6.6) — the stub model cannot keep a
  // quantum array register and a classical pointer view of the same memory
  // coherent, so DECLINE (a fully-classical SEPARATE array is never a candidate and
  // is left untouched — the "no spurious taint" property). Any other use (the
  // alloca pointer captured by a call, `ptrtoint`, a non-memset initializer) →
  // pointer/heap escape, DECLINE.
  SmallVector<Instruction *, 4> InitErase;
  for (User *U : AI->users()) {
    auto *UI = dyn_cast<Instruction>(U);
    if (!UI) {
      diagnose(AI, kMsgQramEscape);
      return;
    }
    if (isa<GetElementPtrInst>(UI)) {
      if (AccessGeps.count(UI))
        continue;  // an accepted tainted-index access.
      diagnose(UI, kMsgQramMixed);  // a classical-index / unaccepted gep.
      return;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(UI)) {
      Intrinsic::ID Id = II->getIntrinsicID();
      if (Id == Intrinsic::lifetime_start || Id == Intrinsic::lifetime_end) {
        InitErase.push_back(II);
        continue;
      }
      if (Id == Intrinsic::memset) {
        // §2.6/§6.5 (Rule-13 fix): the model is |0⟩-init, so ONLY a constant
        // ZERO-fill memset is representable; a non-zero / non-constant fill seeds
        // classical contents `cqrt_qram_alloc_<W>` (count-only) drops → a later
        // load of an un-overwritten cell reads 0 in the trace while the true value
        // is the fill (verify-clean WRONG DATA). Decline loudly (over-declining is
        // safe; the silent drop is the unforgivable bug). `memset.inline` shares
        // the same arg-1 fill-byte ABI.
        auto *Fill = dyn_cast<ConstantInt>(II->getArgOperand(1));
        if (!Fill || !Fill->isZero()) {
          diagnose(II, kMsgQramInit);
          return;
        }
        InitErase.push_back(II);
        continue;
      }
    }
    diagnose(UI, kMsgQramEscape);
    return;
  }

  // §2.8(iii) mid-sequence observation: a load whose value is OBSERVED (measured /
  // returned) with a store to this array AFTER it (program order) reads an
  // intermediate state a later store-reversal would corrupt → loud decline (owner
  // decision 6 — an unprovable reversal invariant is a loud decline, never a silent
  // leak). The array may Escape ONLY after its last store.
  for (const ShadowAccess &L : Accesses) {
    if (L.IsStore || !isObservedValue(L.MemOp))
      continue;
    for (const ShadowAccess &S : Accesses) {
      if (!S.IsStore)
        continue;
      bool After = (S.MemOp->getParent() == L.MemOp->getParent())
                       ? L.MemOp->comesBefore(S.MemOp)
                       : DT.dominates(L.MemOp, S.MemOp);
      if (After) {
        diagnose(S.MemOp, kMsgQramMidSeq);
        return;
      }
    }
  }

  // Coherent-return no-cloning fence (bug test_C_libtooling-l6xk + the sxuk
  // direct-return regression; VERIFIED physics, memory
  // 7-5-qram-coherent-return-nocloning). A loaded value that flows COHERENTLY
  // (`coherentlyEscapesToReturn` — through tainted reversible ops, NOT through a
  // measure/tape collapse sink) into a `ret`/`cq_invert` of a NON-`main` function
  // is entangled with this array's LOCAL (`cq_theta`) index. The whole-DAG reversal
  // would uncompute and FREE that index rail — a dirty free (hidden measurement,
  // Rule 6) that DEPHASES the returned carrier (verify-clean silent miscompile). By
  // no-cloning a clean coherent `arr[p]` is impossible once its local address is
  // erased, and leaving the index allocated only DEFERS the collapse — so DECLINE
  // the whole alloca. A MEASURE collapses the value first (immune — the load+store
  // DAG still uncomputes via the direct-measure copy-out below); `main`'s `ret` is
  // the process-exit observation. (Mirrors the §2.8(iii) mid-seq guard structure.)
  if (AI->getFunction()->getName() != "main")
    for (const ShadowAccess &A : Accesses)
      if (!A.IsStore && coherentlyEscapesToReturn(A.MemOp)) {
        diagnose(A.MemOp, kMsgQramCohEscape);
        return;
      }

  // All invariants hold → emit. Array-handle birth: ONE `cqrt_qram_alloc_<W>(N)` at
  // entry. TAINTED — an alloca-backed mutable array is an in-place-mutated register
  // the whole-DAG uncompute spine reverses (a dead scratch array's stores reverse
  // in LIFO; an escaped/measured array reverses nothing); the handle is a CLASSICAL
  // resource token NEVER freed (§2.9; unlike a const-global QROM array, Inc 1, this
  // one is tainted so the spine treats it as a register).
  Module &M = *AI->getModule();
  Type *I32 = Type::getInt32Ty(M.getContext());
  IRBuilder<> AB(&*AI->getFunction()->getEntryBlock().getFirstInsertionPt());
  CallInst *Arr = AB.CreateCall(AllocFn, {ConstantInt::get(I32, Count)}, "arr");
  if (DebugLoc DL = Anchor->getDebugLoc())
    Arr->setDebugLoc(DL);
  taint.Tainted.insert(Arr);
  taint.BirthOrder[Arr] = taint.NextBirth++;

  SmallVector<Instruction *, 16> ToErase;
  for (const ShadowAccess &A : Accesses) {
    // bd gyc9 (the 7z9k.3 fresh-value-read's INDEX twin): re-read the index FRESH
    // from the LIVE gep's trailing operand, NOT the captured `A.RawIndex`. When an
    // earlier-processed load access RAUW'd its original load to the new
    // `cqrt_qram_load` and this access's index IS that load result directly (the
    // self-referential `arr[v]=v` web; a widening cast in between stays live and
    // is fixed up by the RAUW), the captured pointer is the STALE pre-RAUW load —
    // the new call would reference a soon-erased value (dangling operand →
    // verifier UAF SIGSEGV). `matchAddressGep` proved the index is the trailing
    // gep operand, so the fresh read is the same value modulo intervening RAUW.
    //
    // Then resolve the index handle: strip the mandatory `-O1` widening sext/zext
    // so the index is the i32 handle (Rule 15) — the cross-type RAUW launders it
    // later, EXACTLY like Inc 1's read and the I/O tape-write `src`.
    Value *Idx = A.Gep->getOperand(A.Gep->getNumOperands() - 1);
    Instruction *DeadCast = nullptr;
    if (auto *CI = dyn_cast<CastInst>(Idx))
      if ((isa<SExtInst>(CI) || isa<ZExtInst>(CI)) &&
          taint.Tainted.count(CI->getOperand(0))) {
        Idx = CI->getOperand(0);
        if (CI->hasOneUse())
          DeadCast = CI;
      }

    IRBuilder<> B(A.MemOp);
    if (A.IsStore) {
      // Resolve the value handle. A tainted value is its OWN handle (RAUW'd to i32
      // later). A classical value is materialized into a basis-state handle via
      // `cqrt_alloc_<W>` so the (arr, idx, val) trace stays all-handles (the
      // resolved OPEN decision, §2.5); that handle is a CLASSICAL resource token
      // (untainted) — left allocated, never freed (a bounded safe-leak, like the
      // array handle itself, §2.9).
      //
      // Inc 3 (bd 7z9k.3 over-decline hardening #2): re-read the value operand
      // FRESH from the original store, NOT the captured `A.StoreVal`. When an
      // EARLIER-processed load access to this array RAUW'd its original load to the
      // new `cqrt_qram_load` (and queued the original for erase), `A.StoreVal` — the
      // store's value captured at classify time — is the STALE pre-RAUW load; the
      // new store would then reference a soon-erased value (a dangling operand:
      // a verify-fail / crash masked as `kMsgDivergentArm`, the `arr[p]=arr[q]`
      // dead-load-then-store case). Reading the live operand picks up the RAUW so
      // the new store consumes the NEW load — §6.2 ACCEPT.
      Value *Val = cast<StoreInst>(A.MemOp)->getValueOperand();
      if (!taint.Tainted.count(Val)) {
        FunctionCallee Alloc = wd.allocFn(ElemAbi);
        CallInst *VH = B.CreateCall(Alloc, {Val}, "qval");
        if (DebugLoc DL = A.MemOp->getDebugLoc())
          VH->setDebugLoc(DL);
        Val = VH;
      }
      // iw81.7 — a GuardedStoreArm store (recorded by the control emitter that
      // flattened its diamond) lowers to the GUARDED symbol
      // `cqrt_qram_store_<W>_controlled(flag, arr, idx, val)` — the flag (path
      // predicate) is arg 0, kept LIVE for the whole-DAG LIFO `..._controlled_unc`.
      auto GsIt = taint.GuardedStores.find(cast<StoreInst>(A.MemOp));
      CallInst *St;
      if (GsIt != taint.GuardedStores.end()) {
        FunctionCallee GStoreFn = wd.qramStoreControlledFn(ElemAbi);
        St = B.CreateCall(GStoreFn, {GsIt->second, Arr, Idx, Val});
      } else {
        St = B.CreateCall(StoreFn, {Arr, Idx, Val});
      }
      if (DebugLoc DL = A.MemOp->getDebugLoc())
        St->setDebugLoc(DL);
      ToErase.push_back(A.MemOp);  // the store
    } else {
      CallInst *Out = B.CreateCall(LoadFn, {Arr, Idx});
      if (DebugLoc DL = A.MemOp->getDebugLoc())
        Out->setDebugLoc(DL);
      // A loaded value is a tainted reversible data producer (copy-out): record its
      // width + a BirthOrder slot, exactly like a `cq_template_*` result and Inc 1.
      taint.Tainted.insert(Out);
      taint.HandleWidth[Out] = ElemAbi;
      taint.BirthOrder[Out] = taint.NextBirth++;
      A.MemOp->replaceAllUsesWith(Out);
      // sxuk: if this loaded value's sole direct user is a `cq_measure` in a
      // non-main fn, copy it out to a kept carrier so the LOCAL array's stores
      // uncompute (the index rails themselves are FROZEN and left allocated since
      // bd 5pio — measurement immunity no longer buys their frees). No-op for the
      // dead / taped / main / indirect cases; a COHERENT return was declined above.
      emitCopyOutIfDirectMeasure(Out, ElemAbi, wd, taint);
      ToErase.push_back(A.MemOp);  // the load
    }
    ToErase.push_back(A.Gep);  // the now-dead address-gen
    if (DeadCast) {
      taint.Tainted.erase(DeadCast);
      taint.BirthOrder.erase(DeadCast);
      ToErase.push_back(DeadCast);  // the now-dead widening cast
    }
  }

  // Erase memops + geps + dead casts FIRST (drops the alloca's gep uses), then the
  // initializer (memset / lifetime markers), then the alloca LAST (no uses remain).
  for (Instruction *I : ToErase)
    I->eraseFromParent();
  for (Instruction *I : InitErase)
    I->eraseFromParent();
  AI->eraseFromParent();
}

}  // namespace

void lowerShadowMemory(Module &M, WidthDispatch &wd, TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    std::optional<DominatorTree> DT;
    std::optional<LoopInfo> LInfo;
    // Collect every well-formed tainted-index access, grouped by its origin alloca,
    // in program order. First-seen alloca order keeps the emission deterministic
    // (FileCheck-stable), and the per-alloca vector is in program order because the
    // BB/instruction walk is.
    SmallVector<AllocaInst *, 4> Order;
    DenseMap<AllocaInst *, SmallVector<ShadowAccess, 8>> ByAlloca;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (!isa<LoadInst>(&I) && !isa<StoreInst>(&I))
          continue;
        if (!DT) {
          DT.emplace(F);
          LInfo.emplace(*DT);
        }
        if (auto A = classifyShadowAccess(&I, taint, *DT, *LInfo)) {
          if (!ByAlloca.count(A->Alloca))
            Order.push_back(A->Alloca);
          ByAlloca[A->Alloca].push_back(*A);
        }
      }
    for (AllocaInst *AI : Order)
      processShadowAlloca(AI, ByAlloca[AI], wd, taint, *DT);
  }
}

}  // namespace cq
