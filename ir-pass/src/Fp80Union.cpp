// Fp80Union.cpp — the x86_fp80 union-promotion peephole (bd 3c6m.51). See
// Fp80Union.h for the idiom, the placement, and the §4 padding fence.
//
// PURE structural rewrite: it emits STANDARD LLVM `bitcast`/`lshr`/`trunc`/`zext`
// (byte-identical to LLVM's own SROA output for the within-value loads — proven
// against the -O2 fdiml IR), so it is not a bespoke lowering. Every gate is
// load-bearing: an off-pattern union is left untouched (falls to kMsgStore); a
// matched-but-unsound padding observation LOUD-declines (a wrong "padding = 0"
// fold would be a verify-clean silent miscompile — undefined bytes read as a
// definite value the real program never commits to).

#include "Fp80Union.h"

#include "OpcodeSupport.h"      // abiWidthFromType
#include "TaintPropagation.h"   // TaintSet

#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Transforms/Utils/Local.h"  // ConstantFoldTerminator, removeUnreachableBlocks
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

using namespace llvm;

namespace cq {

namespace {

// The x86_fp80 significant width. Its 80 bits occupy bytes [0,10) of a padded
// 16-byte (align-16) storage slot; bytes [10,16) — bits [80,128) — are undefined
// padding the peephole models as 0 (sound only under the mask fence, §4.1).
constexpr unsigned kFp80Bits = 80;

// The loud decline for a matched fp80 union with an UNMASKED padding observation
// (the central §4.1 fence). The negative fixture mirrors this string
// character-for-character (Rule 12): lowering_reject_fp80_union_padding.ll.
constexpr char kMsgFp80Padding[] =
    "cq fp80 union: padding byte observed without a mask";

void diagnoseFp80Padding(Instruction *I) {
  I->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *I->getFunction(), kMsgFp80Padding, I->getDebugLoc()));
}

// One integer word load off the union, with its constant byte offset.
struct WordLoad {
  LoadInst *Load;
  uint64_t ByteOff;
  unsigned Bits;
};

enum class Status { Promote, PaddingDecline, OffPattern };

// Is `C` (the RHS of an `and` masking `L`) a padding-CLEARING mask for a word
// whose meaningful part is the low `meaningfulBits`? True iff `C` has no bit set
// at position >= meaningfulBits — i.e. every padding bit of the masked result is
// forced to 0, so the (undefined, modelled-as-0) padding cannot be observed.
bool clearsPadding(const ConstantInt *C, unsigned meaningfulBits) {
  return C->getValue().getActiveBits() <= meaningfulBits;
}

// PADDING FENCE (§4.1): a load that reads past bit 80 (a padding straddle) is
// sound to model with padding=0 ONLY if every observer masks the padding bits.
// Conservatively require every user to be `and L, C` (or `and C, L`) with a
// padding-clearing constant `C`; a dead load (no users) is vacuously safe. Any
// other user (a compare, a return, a wider arithmetic op, a second unmasked `and`)
// observes an undefined byte → not promotable.
bool everyUserMasksPadding(LoadInst *L, unsigned meaningfulBits) {
  for (User *U : L->users()) {
    auto *BO = dyn_cast<BinaryOperator>(U);
    if (!BO || BO->getOpcode() != Instruction::And)
      return false;
    Value *Other = BO->getOperand(0) == L ? BO->getOperand(1) : BO->getOperand(0);
    auto *C = dyn_cast<ConstantInt>(Other);
    if (!C || !clearsPadding(C, meaningfulBits))
      return false;
  }
  return true;
}

// Analyze one alloca as a candidate x86_fp80 bit-pattern union. On Promote it
// fills `Seed`/`SeedVal`/`Loads`/`StoreBacks`/`Geps`/`Lifetimes`. On
// PaddingDecline the shape matched but a straddle word is observed unmasked.
// Otherwise OffPattern (leave untouched → kMsgStore).
Status analyze(AllocaInst *A, const DataLayout &DL, TaintSet &taint,
               StoreInst *&Seed, Value *&SeedVal,
               SmallVectorImpl<WordLoad> &Loads,
               SmallVectorImpl<StoreInst *> &StoreBacks,
               SmallVectorImpl<GetElementPtrInst *> &Geps,
               SmallVectorImpl<IntrinsicInst *> &Lifetimes) {
  Seed = nullptr;
  SeedVal = nullptr;
  const unsigned PtrBits = DL.getIndexTypeSizeInBits(A->getType());

  // Every transitive pointer user of A must be a simple integer load into the
  // union, a store into it (fp80 seed or integer store-back), a constant-offset
  // gep whose users we follow, or a lifetime marker. ANY other user (a call
  // reading the address, ptrtoint, an icmp/phi/select on the pointer, a
  // non-constant gep, the address stored as a VALUE) forfeits the WHOLE union.
  SmallVector<Value *, 8> Work{A};
  SmallPtrSet<Value *, 16> Seen;
  auto offsetFromA = [&](Value *Ptr, uint64_t &Off) -> bool {
    APInt AP(PtrBits, 0);
    Value *Base = Ptr->stripAndAccumulateConstantOffsets(DL, AP,
                                                         /*AllowNonInbounds=*/true);
    if (Base != A || AP.isNegative() || AP.getActiveBits() > 63)
      return false;
    Off = AP.getZExtValue();
    return true;
  };
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        return Status::OffPattern;  // a constexpr user of a stack slot — bail.
      if (auto *LI = dyn_cast<LoadInst>(I)) {
        if (!LI->isSimple() || !LI->getType()->isIntegerTy())
          return Status::OffPattern;
        unsigned Bits = LI->getType()->getIntegerBitWidth();
        // Only word widths the trunc/zext grid can extract (≤ 64, a shipped int
        // width). A wider or off-grid load is Inc-2+/off-pattern.
        if (Bits > 64 || abiWidthFromType(LI->getType()).empty())
          return Status::OffPattern;
        uint64_t Off;
        if (!offsetFromA(LI->getPointerOperand(), Off))
          return Status::OffPattern;
        Loads.push_back({LI, Off, Bits});
      } else if (auto *SI = dyn_cast<StoreInst>(I)) {
        // The address must be the POINTER operand, never the stored VALUE (an
        // address escape), and the store must be simple (no volatile/atomic).
        if (SI->getValueOperand() == V || SI->getPointerOperand() != V ||
            !SI->isSimple())
          return Status::OffPattern;
        uint64_t Off;
        if (!offsetFromA(SI->getPointerOperand(), Off))
          return Status::OffPattern;
        Type *VT = SI->getValueOperand()->getType();
        if (VT->isX86_FP80Ty()) {
          if (Seed || Off != 0)
            return Status::OffPattern;  // >1 seed, or a seed not at offset 0.
          Seed = SI;
          SeedVal = SI->getValueOperand();
        } else if (VT->isIntegerTy()) {
          StoreBacks.push_back(SI);  // deadness proven below.
        } else {
          return Status::OffPattern;  // storing a non-fp80/non-int (e.g. a vector).
        }
      } else if (auto *GEP = dyn_cast<GetElementPtrInst>(I)) {
        uint64_t Off;
        if (!offsetFromA(GEP, Off))  // rejects non-constant / aliasing geps.
          return Status::OffPattern;
        Geps.push_back(GEP);
        if (Seen.insert(GEP).second)
          Work.push_back(GEP);
      } else if (auto *II = dyn_cast<IntrinsicInst>(I);
                 II && II->isLifetimeStartOrEnd()) {
        Lifetimes.push_back(II);
      } else {
        return Status::OffPattern;  // any other user escapes the address.
      }
    }
  }

  if (!Seed || Loads.empty())
    return Status::OffPattern;  // not an fp80 extraction union.

  // Only the seed value's kind we support: a tainted handle (the quantum cell) or
  // a Constant (the classical isnan(const) cell, which folds to dead code). A
  // runtime-classical seed is not the target idiom — leave it untouched.
  if (!taint.Tainted.count(SeedVal) && !isa<Constant>(SeedVal))
    return Status::OffPattern;

  // STRAIGHT-LINE requirement: the seed store and every load / store-back live in
  // ONE block, and the seed dominates every load (comesBefore in that block). A
  // multi-block union is Inc-2+/off-pattern. (Lifetime markers may sit in
  // successor blocks; they are erased regardless.)
  BasicBlock *BB = Seed->getParent();
  for (const WordLoad &W : Loads)
    if (W.Load->getParent() != BB || !Seed->comesBefore(W.Load))
      return Status::OffPattern;
  for (StoreInst *SB : StoreBacks)
    if (SB->getParent() != BB)
      return Status::OffPattern;

  // STORE-BACK DEADNESS: a masked store-back is erasable ONLY if no load reads the
  // bytes it wrote (a LIVE store-back is a genuine RMW — Inc 2). Since all are in
  // one block, "a load reads it" = a load that comesBefore-after the store-back
  // whose byte range overlaps. Bail (off-pattern) on any live store-back.
  for (StoreInst *SB : StoreBacks) {
    uint64_t SOff;
    offsetFromA(SB->getPointerOperand(), SOff);  // succeeded above.
    uint64_t SBytes = DL.getTypeStoreSize(SB->getValueOperand()->getType());
    for (const WordLoad &W : Loads) {
      if (!SB->comesBefore(W.Load))
        continue;  // load precedes the store-back → reads the seed, not it.
      uint64_t LBytes = DL.getTypeStoreSize(W.Load->getType());
      bool Disjoint = W.ByteOff + LBytes <= SOff || SOff + SBytes <= W.ByteOff;
      if (!Disjoint)
        return Status::OffPattern;  // live RMW store-back — Inc 2.
    }
  }

  // PADDING FENCE (§4.1): every padding-straddle word must have all its observers
  // mask the padding bits. A matched union that fails this is UNSOUND to promote —
  // loud-decline (NOT leave-untouched: the shape IS the target idiom, so a silent
  // skip would look like "covered" while a future looser matcher could promote it).
  for (const WordLoad &W : Loads) {
    unsigned BitOff = static_cast<unsigned>(W.ByteOff * 8);
    unsigned Meaningful = BitOff >= kFp80Bits ? 0 : std::min(W.Bits, kFp80Bits - BitOff);
    if (Meaningful >= W.Bits)
      continue;  // wholly within the 80-bit value — no padding read.
    // The intermediate meaningful width must be a shipped int width (else the
    // `trunc i80 -> i<meaningful>` has no template) — off-grid ⇒ leave untouched.
    if (Meaningful == 0 ||
        abiWidthFromType(IntegerType::get(A->getContext(), Meaningful)).empty())
      return Status::OffPattern;
    if (!everyUserMasksPadding(W.Load, Meaningful))
      return Status::PaddingDecline;
  }

  return Status::Promote;
}

// Build the register-resident extraction of the word `[byteOff, byteOff+bits)`
// from the i80 value `Bc`: `[lshr i80 Bc, byteOff*8] + trunc i80 -> iN`, or, for a
// padding straddle, `+ trunc i80 -> i<meaningful> + zext -> iN` (padding = 0).
Value *extractWord(IRBuilder<> &B, Value *Bc, uint64_t ByteOff, unsigned Bits) {
  LLVMContext &Ctx = Bc->getContext();
  Type *I80 = Bc->getType();
  unsigned BitOff = static_cast<unsigned>(ByteOff * 8);
  unsigned Meaningful = BitOff >= kFp80Bits ? 0 : std::min(Bits, kFp80Bits - BitOff);
  Value *Sh = Bc;
  if (BitOff > 0)
    Sh = B.CreateLShr(Bc, ConstantInt::get(I80, BitOff), "u_hi");
  Type *DstTy = IntegerType::get(Ctx, Bits);
  if (Meaningful >= Bits)
    return B.CreateTrunc(Sh, DstTy, "u_word");
  if (Meaningful == 0)
    return ConstantInt::get(DstTy, 0);  // wholly padding (fence proved masked).
  Value *M = B.CreateTrunc(Sh, IntegerType::get(Ctx, Meaningful), "u_mean");
  return B.CreateZExt(M, DstTy, "u_word");  // padding bits modelled as 0.
}

// Rewrite one proven union to register-resident form and erase the memory.
void promote(AllocaInst *A, StoreInst *Seed, Value *SeedVal,
             ArrayRef<WordLoad> Loads, ArrayRef<StoreInst *> StoreBacks,
             ArrayRef<GetElementPtrInst *> Geps,
             ArrayRef<IntrinsicInst *> Lifetimes) {
  // The single `bitcast x86_fp80 %seed to i80`, positioned right before the seed
  // store so it dominates every (later, same-block) load. For a constant seed the
  // IRBuilder folds it (and the whole classical union) to constants.
  IRBuilder<> B(Seed);
  Type *I80 = IntegerType::get(A->getContext(), kFp80Bits);
  Value *Bc = B.CreateBitCast(SeedVal, I80, "u_bits");
  if (auto *BcI = dyn_cast<Instruction>(Bc))
    if (DebugLoc DL = Seed->getDebugLoc())
      BcI->setDebugLoc(DL);

  for (const WordLoad &W : Loads) {
    IRBuilder<> LB(W.Load);
    Value *Word = extractWord(LB, Bc, W.ByteOff, W.Bits);
    if (auto *WI = dyn_cast<Instruction>(Word))
      if (DebugLoc DL = W.Load->getDebugLoc())
        WI->setDebugLoc(DL);
    W.Load->replaceAllUsesWith(Word);
  }

  // Erase in dependency order: loads (RAUW'd) + store-backs + seed store +
  // lifetime markers first (all now use-free), then geps (their only users were
  // those), then the alloca.
  for (const WordLoad &W : Loads)
    W.Load->eraseFromParent();
  for (StoreInst *SB : StoreBacks)
    SB->eraseFromParent();
  Seed->eraseFromParent();
  for (IntrinsicInst *LM : Lifetimes)
    LM->eraseFromParent();
  for (GetElementPtrInst *G : Geps)
    if (G->use_empty())
      G->eraseFromParent();
  if (A->use_empty())
    A->eraseFromParent();
}

// Fold the all-constant cone a CLASSICAL (const-seed) union promotion exposes,
// and collapse the resulting constant-conditioned branch — the `isnan(0.5L)` ->
// dead-branch fold the PRD §5 depends on. This is EXACTLY the instcombine/
// simplifycfg cleanup the f64 sibling gets for free at clang -O1 (SROA promotes
// its union there, so the branches fold before cq-lowering ever runs); the fp80
// union stays in memory past clang -O1, so the peephole must do it. Constant
// folding is semantics-preserving and touches ONLY all-constant instructions —
// a tainted (theta-derived) value is never all-constant, so the tainted isnan/
// exponent control is left byte-untouched; only the classical dead branch
// collapses, so PredMux's E6 (every internal terminator TAINTED) then holds.
bool foldConstantConeAndBranches(Function &F, const DataLayout &DL) {
  bool Any = false;
  bool Changed = true;
  while (Changed) {
    Changed = false;
    // Fold every all-constant-operand instruction to its constant value.
    for (BasicBlock &BB : F)
      for (Instruction &I : llvm::make_early_inc_range(BB)) {
        if (isa<PHINode>(&I) || I.isTerminator())
          continue;  // phis fold via the terminator pass; terminators below.
        if (Constant *C = ConstantFoldInstruction(&I, DL)) {
          I.replaceAllUsesWith(C);
          if (llvm::isInstructionTriviallyDead(&I))
            I.eraseFromParent();
          Changed = Any = true;
        }
      }
    // Collapse any now-constant-conditioned branch (deletes the dead edge +
    // updates the dead successor's phis).
    for (BasicBlock &BB : llvm::make_early_inc_range(F))
      if (ConstantFoldTerminator(&BB, /*DeleteDeadConditionalBranches=*/true))
        Changed = Any = true;
  }
  if (Any)
    removeUnreachableBlocks(F);  // reap the now-unreachable classical dead arm.
  return Any;
}

}  // namespace

bool promoteFp80Union(Module &M, TaintSet &taint) {
  const DataLayout &DL = M.getDataLayout();
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Collect candidate allocas up front (analysis + rewrite mutate the IR).
    SmallVector<AllocaInst *, 8> Candidates;
    for (Instruction &I : F.getEntryBlock())
      if (auto *A = dyn_cast<AllocaInst>(&I))
        Candidates.push_back(A);
    bool PromotedInF = false;
    for (AllocaInst *A : Candidates) {
      StoreInst *Seed = nullptr;
      Value *SeedVal = nullptr;
      SmallVector<WordLoad, 4> Loads;
      SmallVector<StoreInst *, 2> StoreBacks;
      SmallVector<GetElementPtrInst *, 4> Geps;
      SmallVector<IntrinsicInst *, 4> Lifetimes;
      Status St = analyze(A, DL, taint, Seed, SeedVal, Loads, StoreBacks, Geps,
                          Lifetimes);
      if (St == Status::OffPattern)
        continue;  // not the idiom — leave untouched (falls to kMsgStore).
      if (St == Status::PaddingDecline) {
        diagnoseFp80Padding(Seed);  // §4.1 loud fence; lower nothing.
        continue;
      }
      promote(A, Seed, SeedVal, Loads, StoreBacks, Geps, Lifetimes);
      Changed = PromotedInF = true;
    }
    // Collapse the classical-union dead branch (isnan(const) -> dead), so the
    // residual tainted control is PredMux-eligible (E6: all terminators tainted).
    if (PromotedInF)
      foldConstantConeAndBranches(F, DL);
  }
  return Changed;
}

}  // namespace cq
