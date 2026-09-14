// RailBankCarveShim.cpp — bd `xdu2` / L-1a: A TEMPORARY TRACK-B STAND-IN FOR
// TRACK A'S RAIL-BANK CARVE CLASSIFIER.
//
// ⚠⚠ READ `RailBankCarve.h` FIRST. THIS FILE IS DELETED WHEN TRACK A'S BRANCH
// MERGES, AND IT IS BUILT SO THAT FAILING TO DELETE IT IS A LINK ERROR, NOT A
// SILENT SECOND SPELLING. ⚠⚠
//
// Track A SHIPPED the classifier (branch `railbank-carve`, tip `44ba3345`) in the
// QRAM TU, where it calls the file-local `walkPtrOrigin` / `isDirectOriginPtr` /
// `matchAddressGep` without exporting them (`SCOPE_L1a.md` §0 H4). Track B is
// developed in a parallel worktree that does not have that branch, so the
// promoter would otherwise have nothing to call. This file implements the
// PUBLISHED contract (`trackA/SIGNATURE.md`, including its same-day ADDENDUM),
// narrowed the same way, so the promoter's one call site is FINAL and the merge
// is a pure deletion.
//
// ⚠ It is NOT Track A's implementation and its verdicts are NOT evidence about
// Track A's. Everything this file measures about the promoter's accept surface
// must be RE-MEASURED against the real classifier at the merge gate. `IMPL_B.md`
// §8 says so in the words the merge agent needs.
//
// ── WHAT THIS STAND-IN DELIBERATELY IS, AND IS NOT ──────────────────────────
//
// It is NOT an attempt at Track A's classifier. It is the SUBSET of it that the
// PROMOTER'S OWN SOUNDNESS depends on, written to be NARROW (over-declining is
// safe; over-accepting is the unforgivable bug — Prime Directive):
//
//   * C1  non-escaping bounded `[N x T]` alloca, every user recognised, and the
//         per-cell seed PROVEN: a whole-alloca constant-zero `llvm.memset`, or
//         NO initializer at all (owner ruling D1 — see the disclosure below).
//   * C2  the cell index is CLASSICAL. A tainted index is 7.5's, and this
//         returns `NotBank` so it keeps 7.5's own string (`BRIEF_A` §1.2 C2:
//         "the axes are already separated; keep them so").
//   * C2' INJECTIVITY: the index is an affine `{0,+,1}` add-recurrence of the
//         store's own loop, and the loop's EXACT backedge-taken count is a
//         constant. Load-bearing for the promoter and not merely for the later
//         type rewrite: if two activations can write one cell, a later trip's
//         SEED load reads a previously-stored value and the promotion forwards
//         the initializer where a live rail belongs.
//   * C3  the stored VALUE is tainted and the cell width has a reversible copy
//         (`widthHasReversibleCopy`, NEVER `abiWidthFromType(..).empty()` —
//         `OpcodeSupport.h:88-91` is explicit that i128 has a width string and
//         no copy). The taint half is also what CONFINES THE PROMOTER'S BLAST
//         RADIUS to programs that decline `kMsgStore` today.
//   * C4  no aliasing fan-out: every access gep has exactly one user, and that
//         user is the memop.
//   * C6  TOTALITY, in its cheap half: the constant trip count equals N and the
//         loop's exit condition is classical.
//
// It does NOT implement the per-clause DECLINE MATRIX as a shipped diagnostic
// surface — `outMsg` is written, but nothing consults it this session, because
// the carve switch in `declineTaintEscapes` is Track A's edit and not Track B's.
// It does not attempt the `DeferControl`-style interaction with 7.5 either.
//
// ── OWNER RULING D1, AND THE DISCLOSURE IT CARRIES ──────────────────────────
//
// `$SES/DECISIONS.md` D1: an uninitialized `bool b0[3];` is ADMITTED, and its
// per-cell seed normalizes to the type's CONCRETE ZERO AT THE ALLOCATION — the
// same rule bd `z9t1` already ships for a scalar `undef` seed at a SOURCE
// `cq_theta` (`normalizeUndefRotationSeed`, `RotationLowering.cpp`). Without it
// C1's "constant-zero memset" clause would refuse the owner's literal file,
// which is an over-decline of the very program the increment exists to compile
// (owner, 2026-09-11: "our end-goal is to not decline any code that will lead to
// a valid quantum circuit").
//
// The disclosure that ruling owes, in the two halves `CLAUDE.md` §4c requires:
//
//   THE RIVAL READING, STATED AS A PROGRAM. `bool b[3]; for (i…) { if (a>=3)
//   b[i] = cq_theta(b[i], .5); … }` reads a cell the source never wrote. The C
//   program's author may have meant "whatever was on the stack", and the
//   compiler now reads it as `0` — one specific value out of 2^8.
//
//   WHY THE RIVAL HAS NO LOWERING TO BE ROBBED OF. On the ORACLE the
//   uninitialized bank is a LOUD DECLINE (`trackL/probes/L7_array_uninit.c`
//   takes the same `kMsgStore`), so there is no circuit for the other reading
//   and nothing is displaced. And the accept it now moves toward is a
//   REFINEMENT, not a choice between two circuits: LangRef lets a read of
//   uninitialized memory stand for any value of its type, so `0` at the seed is
//   a value the source ALREADY LICENSED, and the emitted module is identical to
//   what a written `= {0}` produces. No fence is deceived about a value the
//   program actually wrote.
//
//   NO WARNING IS ADDED, deliberately, for the same reason `CLAUDE.md` §4 gives
//   for the F2 narrowing: it would fire on the owner's own ruled spelling
//   (owner, 2026-09-14: "both codes are supposed to compie!! also no warnings.").
//
// ⚠ bd `z9t1`'s THREE RETIREMENT TRIGGERS (`CLAUDE.md` §4c) now have a SECOND
// CUSTOMER, and trigger (ii) is the composition's only load-bearing fact as
// well: *the clause rewrites anything that is not `isa<UndefValue>`, or `undef`
// stops being uniqued per type*. This file's version of (ii) is narrower and
// therefore states itself: the seed is manufactured ONLY when the alloca has NO
// initializing user at all or a proven whole-alloca constant-zero memset — a
// NON-zero or PARTIAL initializer is `RejectShape`, never rewritten. The day
// that clause admits a third case, re-derive the disclosure from scratch.

#include "RailBankCarve.h"

#include "OpcodeSupport.h"    // abiWidthFromType / widthHasReversibleCopy (Rule 14)
#include "TaintPropagation.h"

#include "llvm/ADT/APInt.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Value.h"

using namespace llvm;

namespace cq {

namespace {

// The canonical `-O1` cell access: `gep inbounds [N x T], ptr %a, i64 0, i64 %i`.
// A gep at any other source element type, or with any other index shape, is a
// REINTERPRETATION of the object and is refused rather than modelled.
const AllocaInst *allocaOfCellGep(const GetElementPtrInst *G, Value *&IdxOut) {
  auto *A = dyn_cast<AllocaInst>(G->getPointerOperand());
  if (!A)
    return nullptr;
  if (A->isArrayAllocation())
    return nullptr;  // C1 — a VLA has no static cell count.
  auto *AT = dyn_cast<ArrayType>(A->getAllocatedType());
  if (!AT)
    return nullptr;  // C1 — not a bounded array object.
  if (G->getSourceElementType() != AT || G->getNumIndices() != 2)
    return nullptr;
  auto *I0 = dyn_cast<ConstantInt>(G->getOperand(1));
  if (!I0 || !I0->isZero())
    return nullptr;
  IdxOut = G->getOperand(2);
  return A;
}

// C1 + C2 + C4, as one alloca-WIDE scan (the `processShadowAlloca` shape). Every
// user must be an access gep with exactly one memop user, a lifetime marker, or
// the one admitted constant-zero whole-object memset.
RailBankCarve scanAlloca(const AllocaInst *A, const TaintSet &taint,
                         const char *&outMsg) {
  auto *AT = dyn_cast<ArrayType>(A->getAllocatedType());
  if (!AT || A->isArrayAllocation()) {
    outMsg = "cq rail bank: not a bounded non-escaping array object";
    return RailBankCarve::RejectShape;
  }
  Type *CellTy = AT->getElementType();
  const uint64_t Bytes =
      A->getModule()->getDataLayout().getTypeAllocSize(AT).getFixedValue();
  bool SawInit = false;

  const DataLayout &DL = A->getModule()->getDataLayout();
  const uint64_t CellBytes = DL.getTypeStoreSize(CellTy);

  for (const User *U : A->users()) {
    if (auto *II = dyn_cast<IntrinsicInst>(U)) {
      Intrinsic::ID ID = II->getIntrinsicID();
      if (ID == Intrinsic::lifetime_start || ID == Intrinsic::lifetime_end)
        continue;
      if (auto *MS = dyn_cast<MemSetInst>(II)) {
        auto *V = dyn_cast<ConstantInt>(MS->getValue());
        auto *Len = dyn_cast<ConstantInt>(MS->getLength());
        if (SawInit || MS->isVolatile() || MS->getRawDest() != A || !V ||
            !V->isZero() || !Len || Len->getZExtValue() != Bytes) {
          outMsg = "cq rail bank: array initializer is not a proven whole-object zero";
          return RailBankCarve::RejectShape;
        }
        SawInit = true;
        continue;
      }
      outMsg = "cq rail bank: array address reaches an unmodelled intrinsic";
      return RailBankCarve::RejectShape;
    }
    // ⚠ MEASURED CORRECTION TO `SCOPE_L1a.md` §2 C1, which admits only "a
    // constant-zero `llvm.memset`". `clang -O1` writes `bool b[3] = {0}` with a
    // memset and `bool b[2] = {0}` / `bool b[8] = {0}` with a single WHOLE-OBJECT
    // INTEGER STORE (`store i16 0` / `store i64 0`) — so a memset-only clause
    // refuses two of the three sizes the increment's own fixture list names. It
    // is a PROOF of the same fact, not a second manufacture: only the
    // NO-INITIALIZER case (owner ruling D1) invents a value the source never
    // wrote, and only that case carries the bd `z9t1` disclosure above.
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      auto *C = dyn_cast<Constant>(SI->getValueOperand());
      if (SawInit || SI->getPointerOperand() != A || !SI->isSimple() || !C ||
          !C->isNullValue() ||
          DL.getTypeStoreSize(SI->getValueOperand()->getType()) != Bytes) {
        outMsg = "cq rail bank: array initializer is not a proven whole-object zero";
        return RailBankCarve::RejectShape;
      }
      SawInit = true;
      continue;
    }
    // ⚠ AND THE READ SIDE OF THE SAME CORRECTION. `-O1` UNROLLS a short
    // `for (i…) s += cq_measure(b[i])` into `load ptr %a`, `gep i8 ptr %a, 1`,
    // `gep i8 ptr %a, 2` — a direct load and byte-offset geps, none of them the
    // canonical `[N x T], 0, idx` shape. Those are provable in-bounds
    // constant-offset READS of one cell; refusing them refuses the whole bank on
    // account of instructions nothing rewrites.
    if (auto *LI2 = dyn_cast<LoadInst>(U)) {
      if (LI2->getPointerOperand() == A && LI2->isSimple() &&
          LI2->getType() == CellTy && CellBytes <= Bytes)
        continue;
      outMsg = "cq rail bank: array address escapes or is accessed off-shape";
      return RailBankCarve::RejectShape;
    }
    auto *G = dyn_cast<GetElementPtrInst>(U);
    if (!G) {
      // A call argument, an `inttoptr`/`ptrtoint`, a pointer phi/select: the
      // address escapes, or the object is accessed at a shape not modelled here.
      outMsg = "cq rail bank: array address escapes or is accessed off-shape";
      return RailBankCarve::RejectShape;
    }
    Value *Idx = nullptr;
    if (allocaOfCellGep(G, Idx) != A) {
      // A constant-offset gep whose every user is a cell-typed simple LOAD is
      // the unrolled-read spelling above. Anything else is off-shape.
      APInt Off(DL.getIndexTypeSizeInBits(G->getType()), 0);
      bool ReadOnly = !G->use_empty() && G->getPointerOperand() == A &&
                      G->accumulateConstantOffset(DL, Off) && !Off.isNegative() &&
                      Off.getActiveBits() <= 63 &&
                      Off.getZExtValue() + CellBytes <= Bytes;
      if (ReadOnly)
        for (const User *Use : G->users()) {
          auto *LI3 = dyn_cast<LoadInst>(Use);
          if (!LI3 || LI3->getPointerOperand() != G || !LI3->isSimple() ||
              LI3->getType() != CellTy) {
            ReadOnly = false;
            break;
          }
        }
      if (ReadOnly)
        continue;
      outMsg = "cq rail bank: array address escapes or is accessed off-shape";
      return RailBankCarve::RejectShape;
    }
    // C2 — a TAINTED index belongs to 7.5. `NotBank` so the caller falls through
    // to 7.5's owner with 7.5's own string; never a rail-bank one.
    if (taint.Tainted.count(Idx))
      return RailBankCarve::NotBank;
    // C4 — ALIASING FAN-OUT, and the spelling is NOT `GEP->hasOneUse()`.
    //
    // ⚠ MEASURED CORRECTION TO `SCOPE_L1a.md` §2 C4, which names
    // `matchQramAccess`'s `GEP->hasOneUse()` (`QramLowering.cpp:467-469`) as the
    // fence to call: THAT PREDICATE REFUSES THE MOTIVATING CUSTOMER. In
    // `a_loop_n3.c` at `-O1` the arm's gep `%9` has TWO uses — the seed `load`
    // AND the `store` at the same address — and that is not an accident of one
    // probe, it is the very shape §0 H3 exists to describe (the cell is read and
    // written through one address per activation). A literal `hasOneUse()` here
    // would make the whole increment fire on nothing.
    //
    // The property C4 actually needs is "no user of this address is something
    // other than a cell memop we have enumerated", which is what the QRAM fence
    // buys with `hasOneUse()` for ITS single-access shapes. So it is asked
    // directly: EVERY use must be a simple, exact-cell-type load or store with
    // this gep as the POINTER operand. A gep passed as a value operand, compared,
    // `ptrtoint`-ed, phi'd or handed to a call fails it — which is the fan-out
    // the clause is for.
    for (const User *Use : G->users()) {
      if (auto *LI = dyn_cast<LoadInst>(Use)) {
        if (LI->getPointerOperand() == G && LI->isSimple() &&
            LI->getType() == CellTy)
          continue;
      } else if (auto *SI = dyn_cast<StoreInst>(Use)) {
        if (SI->getPointerOperand() == G && SI->isSimple() &&
            SI->getValueOperand()->getType() == CellTy)
          continue;
      }
      outMsg = "cq rail bank: array address has aliasing fan-out";
      return RailBankCarve::RejectAlias;
    }
    if (G->use_empty()) {
      outMsg = "cq rail bank: array address has aliasing fan-out";
      return RailBankCarve::RejectAlias;
    }
  }
  return RailBankCarve::Bank;
}

}  // namespace

RailBankCarve railBankCarveVerdict(const StoreInst *SI, const TaintSet &taint,
                                   DominatorTree &DT, LoopInfo &LI,
                                   ScalarEvolution &SE, const char *&outMsg,
                                   RailBankShape *outShape) {
  outMsg = nullptr;
  // ⚠ API PRECONDITION, not an optimization (Track A's ADDENDUM, the
  // `LazyValueInfo` SIGSEGV precedent): never ask the DomTree about a block it
  // has no node for.
  if (!DT.isReachableFromEntry(SI->getParent()))
    return RailBankCarve::NotBank;
  auto *G = dyn_cast<GetElementPtrInst>(SI->getPointerOperand());
  if (!G)
    return RailBankCarve::NotBank;
  Value *Idx = nullptr;
  const AllocaInst *A = allocaOfCellGep(G, Idx);
  if (!A)
    return RailBankCarve::NotBank;

  // C3, taint half — FIRST, and it is what CONFINES THE WHOLE STAGE. An
  // untainted store is `NotBank`, so no classical array anywhere in the corpus
  // is ever a promotion candidate and the observable blast radius is exactly the
  // set of programs that decline `kMsgStore` today.
  if (!taint.Tainted.count(const_cast<Value *>(SI->getValueOperand())))
    return RailBankCarve::NotBank;

  // C1, ADDENDUM: the bank object must be a single function-lifetime allocation.
  // An `alloca` in a loop body is a fresh object per outer trip and is not a bank.
  if (!A->isStaticAlloca()) {
    outMsg = "cq rail bank: not a bounded non-escaping array object";
    return RailBankCarve::RejectShape;
  }

  // C3, width half.
  auto *AT = cast<ArrayType>(A->getAllocatedType());
  if (!widthHasReversibleCopy(abiWidthFromType(AT->getElementType()))) {
    outMsg = "cq rail bank: cell width has no reversible copy";
    return RailBankCarve::RejectWidth;
  }

  if (RailBankCarve V = scanAlloca(A, taint, outMsg); V != RailBankCarve::Bank)
    return V;

  // C2' — INJECTIVITY. One activation writes one cell, and no two activations
  // write the same one.
  //
  // ⚠ `getSmallConstantMaxTripCount` is NOT used, and `CLAUDE.md` Rule 18 says
  // why: it returns `4294967295` on some vacuous bounds and `0` on others, so
  // NEITHER RETURN VALUE DISTINGUISHES VACUITY. The EXACT backedge-taken count
  // is asked instead — `CouldNotCompute` is not a `SCEVConstant`, so a loop
  // whose trip count SCEV cannot decide is refused by the same test that reads
  // the bound — and the APInt is read AT ITS OWN WIDTH.
  //
  // ⚠ `hasFiniteClassicalTripBound` (`LoopLowering.cpp:1239`) is CITED, NOT
  // CALLED: it is the 7.4 `break` path, it asks
  // `getSymbolicMaxBackedgeTakenCount`, and it answers a different question
  // (`BRIEF_A` §1.2 C2').
  Loop *L = LI.getLoopFor(SI->getParent());
  outMsg = "cq rail bank: cell index is not an injective per-activation add-recurrence";
  if (!L)
    return RailBankCarve::RejectIndex;
  // ⚠ ADDENDUM CONJUNCT, AND IT IS LOAD-BEARING FOR TRACK B RATHER THAN FOR THE
  // CARVE. THE WALK LOOP MUST BE OUTERMOST. An enclosing loop RE-EXECUTES the
  // whole cell walk, so the SECOND OUTER TRIP'S SEED LOAD READS A
  // PREVIOUSLY-STORED HANDLE — C2''s own hazard one activation level up — and
  // the promoter would forward it as a classical zero. Track A measured
  // `for (k…) for (i…) b[i] = …` as `Bank` before this line existed, by its own
  // adversarial self-attack, AFTER 18 green fixtures and a clean corpus sweep.
  if (L->getParentLoop())
    return RailBankCarve::RejectIndex;
  auto *AR = dyn_cast<SCEVAddRecExpr>(SE.getSCEV(Idx));
  if (!AR || AR->getLoop() != L || !AR->isAffine() || !AR->getStart()->isZero())
    return RailBankCarve::RejectIndex;
  // ADDENDUM: a recurrence that WRAPS revisits cells, so injectivity fails even
  // with the right start and step.
  if (!AR->hasNoSelfWrap())
    return RailBankCarve::RejectIndex;
  auto *Step = dyn_cast<SCEVConstant>(AR->getStepRecurrence(SE));
  if (!Step || !Step->getAPInt().isOne())
    return RailBankCarve::RejectIndex;
  auto *BTC = dyn_cast<SCEVConstant>(SE.getBackedgeTakenCount(L));
  if (!BTC)
    return RailBankCarve::RejectIndex;
  const APInt &B = BTC->getAPInt();
  if (B.getActiveBits() > 32)
    return RailBankCarve::RejectIndex;
  const uint64_t Trip = B.getZExtValue() + 1;

  // C6 — TOTALITY, cheap half: the trip count is exactly the cell count, the
  // loop leaves through ONE exiting block, and that exit is CLASSICAL (the
  // `taintedExit` half, `LoopLowering.cpp:1073`, asked directly rather than
  // called — it is file-local there).
  outMsg = "cq rail bank: not every cell is written before any cell is read";
  if (Trip != AT->getNumElements())
    return RailBankCarve::RejectTotality;
  const BasicBlock *Exiting = L->getExitingBlock();
  if (!Exiting)
    return RailBankCarve::RejectTotality;
  if (auto *BI = dyn_cast<BranchInst>(Exiting->getTerminator()))
    if (BI->isConditional() && taint.Tainted.count(BI->getCondition()))
      return RailBankCarve::RejectTotality;

  outMsg = nullptr;
  if (outShape) {
    outShape->Alloca = const_cast<AllocaInst *>(A);
    outShape->L = L;
    outShape->RawIndex = Idx;
    outShape->CellTy = AT->getElementType();
    outShape->ElemAbi = abiWidthFromType(AT->getElementType());
    outShape->Count = AT->getNumElements();
    outShape->Trips = Trip;
  }
  return RailBankCarve::Bank;
}

}  // namespace cq
