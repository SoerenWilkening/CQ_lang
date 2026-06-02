// SwitchNormalization.cpp — see header. WP15 (PRD §8.2): rewrite a
// tainted-scrutinee value-merge `switch` into `icmp eq` flags + a nested
// `select` chain, then let the existing select-mux path lower it.
//
// Algorithm (value-merge form — the common case):
//   1. Gate on a tainted scrutinee (`taint.Tainted.count(Sw->getCondition())`);
//      a classical-scrutinee switch is left for the classical backend.
//   2. Require the value-merge shape: every case dest AND the default dest is a
//      DISTINCT block whose UNIQUE predecessor is the switch block and whose
//      body is exactly an unconditional `br merge` (an empty arm); all arms
//      reconverge to one common merge block; the merge carries ≥1 `φ` and has
//      NO predecessor other than the arm blocks. Decline (→ WP12) otherwise.
//   3. For each case value `v_k` mint `f_k = icmp eq %q, v_k` (inserted in the
//      switch block, marked tainted). For each merge `φ`, fold a nested chain
//      `acc = A_default; acc = select f_k, A_k, acc` (per case) and RAUW the
//      `φ` with the final `acc`. Eq-flags are mutually exclusive, so the
//      nesting is order-independent and correct (PRD §8.2 note).
//   4. Replace the `switch` with `br merge` and delete the now-dead arm blocks.
//
// Because the arms are empty, every `φ` incoming value dominates the switch
// block, so hoisting the selects into the switch block is sound. Downstream
// (`detectControlRegions` → `dissolveSelect`) is UNCHANGED: each chain select
// is a tainted-condition select that reduces to the eq-flag mux template.

#include "SwitchNormalization.h"

#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"  // predecessors
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"  // ArrayType
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"  // DeleteDeadBlock

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// Is `Arm` a clean EMPTY value-merge arm — its unique predecessor is `SwBB` and
// its body is exactly an unconditional branch? On a match, returns the merge
// block it falls through to; null otherwise. `getUniquePredecessor` (not
// `getSinglePredecessor`) tolerates a switch with several case values targeting
// the same arm block (multiple pred EDGES, one pred BLOCK).
BasicBlock *valueMergeArmTarget(BasicBlock *Arm, BasicBlock *SwBB) {
  if (Arm->getUniquePredecessor() != SwBB)
    return nullptr;
  // Empty arm: the first instruction IS the terminator (no side-effecting body
  // — that is the gated-cascade shape `-aht.3`, left to the WP12 diagnostic).
  if (&Arm->front() != Arm->getTerminator())
    return nullptr;
  auto *Br = dyn_cast<BranchInst>(Arm->getTerminator());
  if (!Br || Br->isConditional())
    return nullptr;
  BasicBlock *Merge = Br->getSuccessor(0);
  if (Merge == Arm)
    return nullptr;  // a degenerate self-loop, not a forward merge.
  return Merge;
}

// Attempt the WP15 value-merge normalization on one tainted-scrutinee switch.
// Returns true if it rewrote the switch (and `Sw` is now erased); false if it
// declined (the switch is left untouched for the WP12 diagnostic).
bool tryNormalizeSwitch(SwitchInst *Sw, TaintSet &taint) {
  BasicBlock *SwBB = Sw->getParent();
  BasicBlock *Default = Sw->getDefaultDest();

  // The arm blocks (default + every distinct case dest) and the common merge.
  SmallPtrSet<BasicBlock *, 8> ArmBlocks;
  BasicBlock *Merge = valueMergeArmTarget(Default, SwBB);
  if (!Merge)
    return false;
  ArmBlocks.insert(Default);
  for (auto Case : Sw->cases()) {
    BasicBlock *CB = Case.getCaseSuccessor();
    BasicBlock *M2 = valueMergeArmTarget(CB, SwBB);
    if (!M2 || M2 != Merge)
      return false;  // not all arms reconverge on one merge.
    ArmBlocks.insert(CB);
  }

  // The merge must carry ≥1 `φ` (else there is no value to select — a no-op or
  // gated switch; leave it for WP12) and must have NO predecessor other than
  // the arm blocks (an extra edge would feed the `φ` a value from outside the
  // switch — not the clean value-merge shape).
  if (!isa<PHINode>(&Merge->front()))
    return false;
  for (BasicBlock *Pred : predecessors(Merge))
    if (!ArmBlocks.count(Pred))
      return false;

  // ── Rewrite. All `φ` incomings dominate `SwBB` (arms are empty), so the
  // eq-flags + selects are sound to insert before the switch terminator. ──
  Value *Scrut = Sw->getCondition();
  IRBuilder<> B(Sw);

  // Mint the eq-flags once (shared across every merge `φ`). Each is a fresh
  // tainted-condition compare so detection lowers it as a control flag.
  SmallVector<std::pair<Value *, BasicBlock *>, 8> CaseFlags;
  for (auto Case : Sw->cases()) {
    Value *Flag = B.CreateICmpEQ(Scrut, Case.getCaseValue(), "sw_eq");
    taint.Tainted.insert(Flag);
    CaseFlags.push_back({Flag, Case.getCaseSuccessor()});
  }

  // Fold each merge `φ` into a nested select chain rooted at the default value.
  for (PHINode &P : make_early_inc_range(Merge->phis())) {
    Value *Acc = P.getIncomingValueForBlock(Default);
    for (auto &CF : CaseFlags) {
      Value *Ak = P.getIncomingValueForBlock(CF.second);
      Acc = B.CreateSelect(CF.first, Ak, Acc, "sw_sel");
    }
    P.replaceAllUsesWith(Acc);
    P.eraseFromParent();
  }

  // Drop the switch; the switch block now falls straight through to the merge.
  // Deleting the (now predecessor-less) arm blocks drops their `br merge`
  // edges, leaving the merge single-predecessor (`SwBB`).
  Sw->eraseFromParent();
  BranchInst::Create(Merge, SwBB);
  for (BasicBlock *Arm : ArmBlocks)
    DeleteDeadBlock(Arm);
  return true;
}

// Strip a zext/sext to recover the underlying index value (clang widens the i32
// table index to i64 for the `getelementptr`). Returns `V` unchanged if it is
// not such a cast.
Value *stripIntCast(Value *V) {
  if (auto *Z = dyn_cast<ZExtInst>(V))
    return Z->getOperand(0);
  if (auto *S = dyn_cast<SExtInst>(V))
    return S->getOperand(0);
  return V;
}

// Recognize + rewrite ONE jump-table angle diamond rooted at the conditional
// branch terminating `Pred` (test_C_libtooling-5zu). The exact `-O1` shape:
//   Pred:   %idx   = add i32 %q, K            ; (or %idx == %q, K = 0)
//           %bound = icmp ult i32 %idx, N
//           br i1 %bound, label %Lookup, label %Merge
//   Lookup: %z   = zext/sext i32 %idx to i64  ; (optional)
//           %gep = getelementptr inbounds [N' x T], ptr @G, i64 0, i64 %z
//           %a   = load T, ptr %gep
//           br label %Merge
//   Merge:  %phi = phi T [ %a, %Lookup ], [ %base, %Pred ]   ; bound ? table[idx] : base
// where `@G` is a constant array of ≥N angle constants and `%q` is a tainted
// handle. On a match, replace `%phi` with the eq-flag select chain
// `select([q==i−K], table[i], …select(…, base))` (i ∈ [0,N), constants read at
// compile time), collapse the diamond (Pred → Merge unconditional, delete
// Lookup), and erase the dead bound/idx. Returns true if rewritten.
//
// The map `q ↦ q+K` is a bijection mod 2³², so the unsigned in-bounds set
// `{q : (q+K) ∈ [0,N)}` is EXACTLY `{i−K mod 2³² : i ∈ [0,N)}` — the eq-flag
// constants — and any other `q` falls through to `base`. So the select chain is
// exact even under wraparound. STRICT recognition (canonical `ult`, 2-index gep
// with a zero first index, constant global, single 2-incoming φ, tainted
// scrutinee); any deviation declines, leaving the memory-escape guard to
// diagnose.
bool tryNormalizeJumpTableAngle(BranchInst *Br, TaintSet &taint) {
  if (!Br->isConditional())
    return false;
  BasicBlock *Pred = Br->getParent();

  // Bound check: `icmp ult %idx, N` (the in-bounds test); Lookup is the TRUE
  // (in-bounds) successor, Merge the FALSE (out-of-bounds → base) successor.
  auto *Bound = dyn_cast<ICmpInst>(Br->getCondition());
  if (!Bound || Bound->getPredicate() != ICmpInst::ICMP_ULT)
    return false;
  auto *NC = dyn_cast<ConstantInt>(Bound->getOperand(1));
  if (!NC)
    return false;
  Value *Idx = Bound->getOperand(0);
  BasicBlock *Lookup = Br->getSuccessor(0);
  BasicBlock *Merge = Br->getSuccessor(1);
  if (Lookup == Merge || Lookup->getSinglePredecessor() != Pred)
    return false;
  auto *LBr = dyn_cast<BranchInst>(Lookup->getTerminator());
  if (!LBr || LBr->isConditional() || LBr->getSuccessor(0) != Merge)
    return false;

  // The table load: a `load T` from a `getelementptr` into a constant global
  // array indexed by (a cast of) `%idx`.
  LoadInst *Load = nullptr;
  for (Instruction &I : *Lookup)
    if (auto *LD = dyn_cast<LoadInst>(&I)) {
      Load = LD;
      break;
    }
  if (!Load)
    return false;
  // The load must be plain (no volatile/atomic semantics to preserve) and used
  // ONLY by the merge φ — otherwise deleting the Lookup arm below would drop a
  // side effect or strand a live external use of the loaded value (a broken
  // module). (adversarial review, 2026-06-03.)
  if (!Load->isSimple() || !Load->hasOneUse())
    return false;
  auto *Gep = dyn_cast<GetElementPtrInst>(Load->getPointerOperand());
  if (!Gep || !Gep->hasOneUse() || Gep->getNumIndices() != 2)
    return false;  // need `gep [N' x T], ptr, 0, idx` (the canonical array gep).
  auto *I0 = dyn_cast<ConstantInt>(Gep->getOperand(1));
  if (!I0 || !I0->isZero())
    return false;  // first gep index must be 0 (array base).
  if (stripIntCast(Gep->getOperand(2)) != Idx)
    return false;  // the element index must be the bounded `%idx`.
  auto *G = dyn_cast<GlobalVariable>(Gep->getPointerOperand());
  if (!G || !G->isConstant() || !G->hasInitializer())
    return false;
  auto *ArrTy = dyn_cast<ArrayType>(G->getValueType());
  if (!ArrTy || Gep->getSourceElementType() != ArrTy)
    return false;
  Type *ElemTy = ArrTy->getElementType();
  // ONLY a `double` ANGLE table is in scope (5zu). The CQ rotation surface takes
  // a `double` angle (`cq_phi_<sfx>(i32, double)` → `cqrt_rz_<W>(i32, double)`)
  // for EVERY width, so the angle constants must be `double`; an `f32` table
  // would feed a `float` to the double-typed `cqrt_rz` (a broken module), and a
  // non-FP table (e.g. `[N x i32]`, clang's lowering of a DATA `switch`) is not a
  // rotation-angle dispatch at all. Either way decline so the tainted-memory-
  // escape guard diagnoses it — never mislower or emit a broken module.
  // (adversarial review, 2026-06-03.)
  if (!ElemTy->isDoubleTy())
    return false;
  uint64_t ArrLen = ArrTy->getNumElements();
  uint64_t N = NC->getZExtValue();
  if (N == 0 || N > ArrLen)
    return false;  // bound out of range — not the canonical table dispatch.

  // The Lookup arm must contain NOTHING but the (optional) index cast, the gep,
  // the load, and the unconditional terminator — collapsing the diamond DELETES
  // this block, so any other instruction (a `store`, a `call`, a second load)
  // would be silently dropped (a miscompile). (adversarial review.)
  SmallPtrSet<const Instruction *, 4> AllowedInLookup;
  AllowedInLookup.insert(Gep);
  AllowedInLookup.insert(Load);
  AllowedInLookup.insert(LBr);
  if (auto *Cast = dyn_cast<Instruction>(Gep->getOperand(2)))
    if (Cast->getParent() == Lookup) {
      if (!Cast->hasOneUse())
        return false;  // the cast must feed only the gep.
      AllowedInLookup.insert(Cast);
    }
  for (Instruction &I : *Lookup)
    if (!AllowedInLookup.count(&I))
      return false;  // an unexpected (possibly side-effecting) instruction.

  // The scrutinee + affine offset: `%idx == %q` (K=0) or `%idx = add %q, K`.
  Value *Q = Idx;
  int64_t K = 0;
  if (auto *Bin = dyn_cast<BinaryOperator>(Idx)) {
    if (Bin->getOpcode() != Instruction::Add)
      return false;
    auto *KC = dyn_cast<ConstantInt>(Bin->getOperand(1));
    if (!KC)
      return false;
    Q = Bin->getOperand(0);
    K = KC->getSExtValue();
  }
  if (!taint.Tainted.count(Q))
    return false;  // the scrutinee must be a quantum handle.
  Type *IdxTy = Q->getType();
  if (!IdxTy->isIntegerTy())
    return false;

  // The merge angle `φ`: EXACTLY one φ, 2 incomings `[load, Lookup]` and
  // `[base, Pred]`, of the table element type. (A multi-φ / handle-reconverging
  // merge is a different shape — decline.)
  PHINode *Phi = nullptr;
  for (PHINode &P : Merge->phis()) {
    if (Phi)
      return false;  // more than one φ.
    Phi = &P;
  }
  if (!Phi || Phi->getType() != ElemTy || Phi->getNumIncomingValues() != 2)
    return false;
  int Li = Phi->getBasicBlockIndex(Lookup);
  int Pi = Phi->getBasicBlockIndex(Pred);
  if (Li < 0 || Pi < 0 || Phi->getIncomingValue(Li) != Load)
    return false;
  Value *Base = Phi->getIncomingValue(Pi);
  // Merge must reconverge ONLY the two diamond edges (no extra predecessor).
  for (BasicBlock *P : predecessors(Merge))
    if (P != Pred && P != Lookup)
      return false;
  // The dispatched value must feed ONLY rotation ANGLES (`cq_phi` arg 1) — the
  // angle dispatch this transform targets. An FP `φ` consumed elsewhere is not a
  // rotation-angle table; decline so the memory-escape guard diagnoses it rather
  // than rewriting a shape the WP16 angle-chain path will not lower. (Mirrors
  // detection's `usersAreAngleFeeds`; adversarial review, 2026-06-03.)
  for (User *U : Phi->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      return false;
    const Function *Cal = CI->getCalledFunction();
    if (!Cal || !Cal->getName().starts_with("cq_phi_"))
      return false;
    if (CI->arg_size() < 2 || CI->getArgOperand(1) != Phi ||
        CI->getArgOperand(0) == Phi)
      return false;
  }

  // Read the N table constants at compile time.
  Constant *Init = G->getInitializer();
  SmallVector<Constant *, 8> Angles;
  for (uint64_t i = 0; i < N; ++i) {
    Constant *C = Init->getAggregateElement((unsigned)i);
    if (!C || C->getType() != ElemTy)
      return false;  // non-constant / type-mismatched entry — decline.
    Angles.push_back(C);
  }

  // ── Rewrite. Build the eq-flag select chain in `Merge` (co-located with the
  // φ's consumers, so the WP16 angle-chain detection's single-block invariant
  // holds), replace the φ, then collapse the diamond. ──
  IRBuilder<> B(Merge->getFirstNonPHI());
  Value *Acc = Base;
  for (uint64_t i = 0; i < N; ++i) {
    // q == i − K (truncated to the scrutinee width — matches the unsigned
    // in-bounds q for table index i, even under add wraparound).
    Constant *EqVal = ConstantInt::get(IdxTy, (uint64_t)((int64_t)i - K));
    Value *Flag = B.CreateICmpEQ(Q, EqVal, "jt_eq");
    taint.Tainted.insert(Flag);  // a tainted-condition select for detection.
    Acc = B.CreateSelect(Flag, Angles[i], Acc, "jt_sel");
  }
  Phi->replaceAllUsesWith(Acc);
  Phi->eraseFromParent();

  // Collapse: Pred → Merge unconditionally; delete the (now predecessor-less)
  // Lookup arm, which erases the dead gep/load/cast with it.
  Br->eraseFromParent();
  BranchInst::Create(Merge, Pred);
  DeleteDeadBlock(Lookup);
  // Erase the now-dead bound + affine index in Pred.
  if (Bound->use_empty())
    Bound->eraseFromParent();
  if (auto *IdxI = dyn_cast<Instruction>(Idx))
    if (IdxI->use_empty())
      IdxI->eraseFromParent();
  return true;
}

}  // namespace

void normalizeTaintedSwitches(Module &M, TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Collect first: rewriting mutates the CFG, so do not normalize while
    // iterating the function's block list.
    SmallVector<SwitchInst *, 4> Candidates;
    for (BasicBlock &BB : F)
      if (auto *Sw = dyn_cast<SwitchInst>(BB.getTerminator()))
        if (taint.Tainted.count(Sw->getCondition()))
          Candidates.push_back(Sw);
    for (SwitchInst *Sw : Candidates)
      tryNormalizeSwitch(Sw, taint);
  }
}

void normalizeJumpTableAngle(Module &M, TaintSet &taint) {
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Collect candidate conditional branches first (rewriting mutates the CFG).
    // A jump-table angle diamond is rooted at a tainted-bound conditional `br`
    // (the bound `icmp ult %idx, N` is tainted because `%idx` derives from the
    // quantum scrutinee).
    SmallVector<BranchInst *, 4> Candidates;
    for (BasicBlock &BB : F)
      if (auto *Br = dyn_cast<BranchInst>(BB.getTerminator()))
        if (Br->isConditional() && taint.Tainted.count(Br->getCondition()))
          Candidates.push_back(Br);
    for (BranchInst *Br : Candidates)
      tryNormalizeJumpTableAngle(Br, taint);
  }
}

}  // namespace cq
