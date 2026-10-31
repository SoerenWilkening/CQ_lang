// cq-trip-facts: static proofs that a loop never runs a target trip count (cq-97oj; checker/cqcheck/gaps.py).
//
//   opt -load-pass-plugin=libCQOracle.so -passes=cq-trip-facts -disable-output [-cq-trip-max=T] in.O1.ll
//
// Prints one line per proved (loop, target) pair, targets 1..T (default 5 = K + 1):
//   cq-trip-fact <TAB> <fn>:<header> <TAB> <target> <TAB> <kind> <TAB> <reason>
// The loop key is the checker's (sampling.Instrumenter: the function name and the header block as
// the .O1.ll spells it). The trip count is the C oracle's (OracleInstr.cpp, trip counters): per
// activation, the header executions, less one when the final header run leaves through the header's
// test region (that region is computed here exactly as there); a quantum-exit loop the oracle cuts at
// K reports any count above K as a capped record, so for such a loop a target above K is "more than K
// trips". Both kinds reason with LLVM's semantics on the unmodified .O1.ll (whatever LLVM does, we do:
// an input on which the loop's exit test reads poison is undefined, outside the domain).
//
// Kind "value-set" (decision on cq-97oj, kind 1): ScalarEvolution's exact backedge-taken count B of the
// loop gives H = B + 1 header executions on every activation that enters it; the target is impossible
// when no value H can take gives it: H's unsigned range (ScalarEvolution, ValueTracking's
// computeConstantRange), H a power of two (ValueTracking isKnownToBeAPowerOfTwo through min/max), or
// H's KnownBits contradict it.
//
// Kind "domain" (cq-97oj, kind 2): an exit of the loop whose block runs on every trip has an exit count
// E (ScalarEvolution) that bounds the trips: the target needs E >= m. When E depends on one integer
// argument a of the function, the argument's range is split until each piece either cannot give
// E >= m (ConstantRange evaluation of E) or makes every input in it undefined before the loop: a load
// or store that every path to the loop's header executes, at an offset (ScalarEvolution; for an
// access in an earlier top-level loop, its affine AddRec at the loop's last iteration, the loop
// entered on every such a and run to completion) out of its object's range (getObjectSize). Any
// piece left undecided leaves the target unproved: nothing is printed for it.

#include "cq/Loops.h"
#include "cq/Taint.h"

#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/MemoryBuiltins.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/raw_ostream.h"

#include <optional>
#include <tuple>
#include <string>
#include <vector>

using namespace llvm;

static cl::opt<unsigned> TripMax("cq-trip-max", cl::init(5), cl::desc("cq-trip-facts: the largest target"));

namespace {

std::string operandName(const Value *V) {
  std::string s;
  raw_string_ostream os(s);
  V->printAsOperand(os, false);
  return os.str();
}

std::string text(const Value *V) {
  std::string s;
  raw_string_ostream os(s);
  V->print(os);
  StringRef r(s);
  return r.trim().str();
}

std::string scevText(const SCEV *S) {
  std::string s;
  raw_string_ostream os(s);
  S->print(os);
  return os.str();
}

// OracleInstr.cpp, trip counters: the header's test region and whether it holds an exit.
struct Region {
  SmallPtrSet<BasicBlock *, 4> blocks;
  bool exits = false;
};

Region headerRegion(Loop *L) {
  Region R;
  BasicBlock *H = L->getHeader();
  SmallVector<BasicBlock *, 4> work{H};
  R.blocks.insert(H);
  while (!work.empty()) {
    BasicBlock *B = work.pop_back_val();
    if (L->isLoopExiting(B))
      R.exits = true;
    for (BasicBlock *S : successors(B)) {
      if (!L->contains(S) || S == H || R.blocks.count(S) || S->getSinglePredecessor() != B ||
          L->isLoopLatch(S) || !L->isLoopExiting(S))
        continue;
      bool pure = true;
      for (Instruction &I : *S)
        if (I.mayWriteToMemory() || isa<CallBase>(I) || isa<PHINode>(I))
          pure = false;
      if (pure) {
        R.blocks.insert(S);
        work.push_back(S);
      }
    }
  }
  if (L->isLoopLatch(H))
    R.exits = false;
  return R;
}

// CR §0 K for the loops of F as the oracle resolves it without flags: CQ_K(f, k), else 4.
unsigned kOf(const Function &F) {
  if (const GlobalVariable *GV = F.getParent()->getGlobalVariable(("__cq_k_" + F.getName()).str(), true))
    if (GV->hasInitializer())
      if (auto *CI = dyn_cast<ConstantInt>(GV->getInitializer()))
        if (CI->getZExtValue() > 0)
          return unsigned(CI->getZExtValue());
  return 4;
}

struct Facts {
  Function &F;
  ScalarEvolution &SE;
  DominatorTree &DT;
  LoopInfo &LI;
  AssumptionCache &AC;
  const TargetLibraryInfo &TLI;
  const DataLayout &DL;

  // ---------------------------------------------------------------- kind 1: value sets

  bool pow2(const SCEV *S) {
    if (auto *C = dyn_cast<SCEVConstant>(S))
      return C->getAPInt().isPowerOf2();
    if (auto *U = dyn_cast<SCEVUnknown>(S)) {
      const Instruction *Ctx = dyn_cast<Instruction>(U->getValue());
      return isKnownToBeAPowerOfTwo(U->getValue(), DL, /*OrZero=*/false, 0, &AC, Ctx, &DT);
    }
    if (auto *M = dyn_cast<SCEVMinMaxExpr>(S)) {
      for (const SCEV *Op : M->operands())
        if (!pow2(Op))
          return false;
      return true;
    }
    if (auto *Z = dyn_cast<SCEVZeroExtendExpr>(S))
      return pow2(Z->getOperand());
    return false;
  }

  // Why H (header executions, a SCEV of the loop's count type) never equals v, or "".
  std::string never(const SCEV *H, uint64_t v) {
    unsigned W = SE.getTypeSizeInBits(H->getType());
    if (W < 64 && v >> W)
      return "";
    APInt V(W, v);
    ConstantRange R = SE.getUnsignedRange(H);
    if (auto *U = dyn_cast<SCEVUnknown>(H))
      R = R.intersectWith(computeConstantRange(U->getValue(), false, true, &AC,
                                               dyn_cast<Instruction>(U->getValue()), &DT));
    if (!R.contains(V)) {
      std::string s;
      raw_string_ostream os(s);
      os << "its unsigned range is " << R;
      return os.str();
    }
    if (!V.isPowerOf2() && pow2(H))
      return "it is a power of two (ValueTracking isKnownToBeAPowerOfTwo)";
    if (auto *U = dyn_cast<SCEVUnknown>(H)) {
      KnownBits K = computeKnownBits(U->getValue(), DL, 0, &AC, dyn_cast<Instruction>(U->getValue()), &DT);
      if ((K.Zero & V) != 0 || (K.One & ~V) != 0) {
        std::string s;
        raw_string_ostream os(s);
        os << "its known bits (zero " << K.Zero << ", one " << K.One << ") exclude it";
        return os.str();
      }
    }
    return "";
  }

  // Why H > K never holds (a capped record needs more than K header executions), or "".
  std::string neverAbove(const SCEV *H, unsigned K) {
    ConstantRange R = SE.getUnsignedRange(H);
    if (R.getUnsignedMax().ule(K)) {
      std::string s;
      raw_string_ostream os(s);
      os << "its unsigned range is " << R << ", never above K = " << K;
      return os.str();
    }
    return "";
  }

  std::string valueSet(Loop *L, unsigned t, const Region &Rg, bool qexit, unsigned K) {
    const SCEV *B = SE.getBackedgeTakenCount(L);
    if (isa<SCEVCouldNotCompute>(B))
      return "";
    const SCEV *H = SE.getAddExpr(B, SE.getOne(B->getType()));
    std::string head = "LLVM ScalarEvolution: every activation that enters " + operandName(L->getHeader()) +
                       " runs H = " + scevText(H) + " header executions; ";
    if (qexit && t > K) {
      // the oracle reports more than K trips as a capped record: needs H > K (H - 1 > K with a region exit)
      std::string w = neverAbove(H, K);
      return w.empty() ? "" : head + "H " + w;
    }
    std::string a = never(H, t);
    if (a.empty())
      return "";
    if (!Rg.exits)
      return head + "the oracle reports H trips, and H is never " + std::to_string(t) + ": " + a;
    std::string b = never(H, t + 1);
    if (b.empty())
      return "";
    return head + "the oracle reports H or H - 1 trips, and H is never " + std::to_string(t) + " (" + a +
           ") nor " + std::to_string(t + 1) + " (" + b + ")";
  }

  // ---------------------------------------------------------------- kind 2: domain

  // The range of S when argument A ranges over I (every other argument and unknown: its full range).
  ConstantRange rangeOf(const SCEV *S, const Argument *A, const ConstantRange &I) {
    unsigned W = SE.getTypeSizeInBits(S->getType());
    if (auto *C = dyn_cast<SCEVConstant>(S))
      return ConstantRange(C->getAPInt());
    if (auto *U = dyn_cast<SCEVUnknown>(S)) {
      if (U->getValue() == A && I.getBitWidth() == W)
        return I;
      return ConstantRange::getFull(W);
    }
    if (auto *X = dyn_cast<SCEVAddExpr>(S)) {
      ConstantRange R = rangeOf(X->getOperand(0), A, I);
      for (unsigned i = 1; i < X->getNumOperands(); ++i)
        R = R.add(rangeOf(X->getOperand(i), A, I));
      return R;
    }
    if (auto *X = dyn_cast<SCEVMulExpr>(S)) {
      ConstantRange R = rangeOf(X->getOperand(0), A, I);
      for (unsigned i = 1; i < X->getNumOperands(); ++i)
        R = R.multiply(rangeOf(X->getOperand(i), A, I));
      return R;
    }
    if (auto *X = dyn_cast<SCEVUDivExpr>(S))
      return rangeOf(X->getLHS(), A, I).udiv(rangeOf(X->getRHS(), A, I));
    if (auto *X = dyn_cast<SCEVZeroExtendExpr>(S))
      return rangeOf(X->getOperand(), A, I).zeroExtend(W);
    if (auto *X = dyn_cast<SCEVSignExtendExpr>(S))
      return rangeOf(X->getOperand(), A, I).signExtend(W);
    if (auto *X = dyn_cast<SCEVTruncateExpr>(S))
      return rangeOf(X->getOperand(), A, I).truncate(W);
    if (auto *X = dyn_cast<SCEVMinMaxExpr>(S)) {
      ConstantRange R = rangeOf(X->getOperand(0), A, I);
      for (unsigned i = 1; i < X->getNumOperands(); ++i) {
        ConstantRange O = rangeOf(X->getOperand(i), A, I);
        switch (X->getSCEVType()) {
        case scSMaxExpr: R = R.smax(O); break;
        case scUMaxExpr: R = R.umax(O); break;
        case scSMinExpr: R = R.smin(O); break;
        case scUMinExpr: R = R.umin(O); break;
        default: return ConstantRange::getFull(W);
        }
      }
      return R;
    }
    return ConstantRange::getFull(W);
  }

  static void args(const SCEV *S, SmallPtrSetImpl<const Argument *> &out, bool &other) {
    struct V {
      SmallPtrSetImpl<const Argument *> &out;
      bool &other;
      bool follow(const SCEV *S) {
        if (auto *U = dyn_cast<SCEVUnknown>(S)) {
          if (auto *A = dyn_cast<Argument>(U->getValue()))
            out.insert(A);
          else
            other = true;
        }
        return true;
      }
      bool isDone() const { return false; }
    } v{out, other};
    SCEVTraversal<V> T(v);
    T.visitAll(S);
  }

  struct Access {
    Instruction *I;
    const SCEV *off;       // the byte offset of the access it makes last before the loop
    uint64_t size, objSize;
    BasicBlock *guard = nullptr;   // the branch that must go toward the earlier loop, if any
    BasicBlock *toward = nullptr;
    const Value *obj;
  };

  std::optional<uint64_t> objectSize(const Value *O) {
    uint64_t Sz;
    ObjectSizeOpts Opts;
    if (getObjectSize(O, Sz, DL, &TLI, Opts))
      return Sz;
    return std::nullopt;
  }

  // The accesses every path to H executes (before it), with the offset of their last execution.
  std::vector<Access> dominatingAccesses(Loop *L) {
    std::vector<Access> out;
    BasicBlock *H = L->getHeader();
    for (BasicBlock &BB : F) {
      if (L->contains(&BB))
        continue;
      for (Instruction &I : BB) {
        Value *P = nullptr;
        Type *Ty = nullptr;
        if (auto *Ld = dyn_cast<LoadInst>(&I))
          P = Ld->getPointerOperand(), Ty = Ld->getType();
        else if (auto *St = dyn_cast<StoreInst>(&I))
          P = St->getPointerOperand(), Ty = St->getValueOperand()->getType();
        if (!P)
          continue;
        const Value *O = getUnderlyingObject(P);
        if (!isa<AllocaInst>(O) && !isa<GlobalVariable>(O))
          continue;
        auto Z = objectSize(O);
        if (!Z)
          continue;
        const SCEV *Off = SE.getMinusSCEV(SE.getSCEV(P), SE.getSCEV(const_cast<Value *>(O)));
        if (isa<SCEVCouldNotCompute>(Off))
          continue;
        Access A{&I, nullptr, DL.getTypeStoreSize(Ty).getFixedValue(), *Z, nullptr, nullptr, O};
        Loop *L1 = LI.getLoopFor(&BB);
        if (!L1) {
          if (!DT.dominates(&BB, H))
            continue;
          A.off = Off;
          out.push_back(A);
          continue;
        }
        // an access in an earlier top-level loop L1: its last iteration's offset
        if (L1->getParentLoop() || L1->contains(H))
          continue;
        auto *AR = dyn_cast<SCEVAddRecExpr>(Off);
        if (!AR || AR->getLoop() != L1 || !AR->isAffine())
          continue;
        const SCEV *B1 = SE.getBackedgeTakenCount(L1);
        if (isa<SCEVCouldNotCompute>(B1))
          continue;
        SmallVector<BasicBlock *, 4> exiting;
        L1->getExitingBlocks(exiting);
        bool all = true;
        for (BasicBlock *X : exiting)
          all &= DT.dominates(&BB, X);
        if (!all)
          continue;   // the last iteration may leave before the access
        A.off = AR->evaluateAtIteration(B1, SE);
        // L1 runs to completion before H whenever its preheader is reached; it is reached whenever H is
        // when the preheader dominates H, or when a guard dominating H branches toward it
        BasicBlock *P1 = L1->getLoopPreheader();
        if (!P1)
          continue;
        if (!DT.dominates(P1, H)) {
          std::tie(A.guard, A.toward) = guardOf(L1);
          if (!A.guard || LI.getLoopFor(A.guard) || !DT.dominates(A.guard, H))
            continue;
        }
        out.push_back(A);
      }
    }
    return out;
  }

  // The conditional branch that leads, through blocks of a single predecessor ending in an
  // unconditional branch, to the loop's preheader, and the successor it takes toward it.
  std::pair<BasicBlock *, BasicBlock *> guardOf(Loop *L1) {
    BasicBlock *B = L1->getLoopPreheader();
    if (!B)
      return {nullptr, nullptr};
    while (BasicBlock *Pr = B->getSinglePredecessor()) {
      auto *Br = dyn_cast<BranchInst>(Pr->getTerminator());
      if (!Br)
        break;
      if (Br->isConditional())
        return {Pr, B};
      B = Pr;
    }
    return {nullptr, nullptr};
  }

  // Every a in I makes the guard's branch go toward `toward` (want) or away from it (!want).
  bool branchAlways(BasicBlock *guard, BasicBlock *toward, bool want, const Argument *Arg, const ConstantRange &I) {
    auto *Br = cast<BranchInst>(guard->getTerminator());
    if (Br->getSuccessor(0) == Br->getSuccessor(1))
      return want;
    auto *Cmp = dyn_cast<ICmpInst>(Br->getCondition());
    if (!Cmp || !SE.isSCEVable(Cmp->getOperand(0)->getType()))
      return false;
    ConstantRange L = rangeOf(SE.getSCEV(Cmp->getOperand(0)), Arg, I);
    ConstantRange R = rangeOf(SE.getSCEV(Cmp->getOperand(1)), Arg, I);
    CmpInst::Predicate P = Cmp->getPredicate();
    if ((Br->getSuccessor(0) == toward) != want)
      P = CmpInst::getInversePredicate(P);
    return L.icmp(P, R);
  }

  // Every a in I takes A's guard toward its loop.
  bool guardTaken(const Access &A, const Argument *Arg, const ConstantRange &I) {
    return !A.guard || branchAlways(A.guard, A.toward, true, Arg, I);
  }

  // Every a in I makes A out of its object's range.
  bool outOfRange(const Access &A, const Argument *Arg, const ConstantRange &I) {
    if (!guardTaken(A, Arg, I))
      return false;
    ConstantRange O = rangeOf(A.off, Arg, I);
    if (O.isFullSet() || O.isEmptySet())
      return false;
    unsigned W = O.getBitWidth();
    if (W > 64)
      return false;
    // past the end: offset + size > objSize for every offset (signed), or below 0
    int64_t lo = O.getSignedMin().getSExtValue(), hi = O.getSignedMax().getSExtValue();
    return lo > int64_t(A.objSize) - int64_t(A.size) || hi < 0;
  }

  std::string domain(Loop *L, unsigned t, const Region &Rg) {
    SmallVector<BasicBlock *, 4> exiting;
    L->getExitingBlocks(exiting);
    BasicBlock *Latch = L->getLoopLatch();
    if (!Latch)
      return "";
    bool allRegion = Rg.exits;
    for (BasicBlock *X : exiting)
      allRegion &= Rg.blocks.count(X) > 0;
    std::vector<Access> acc;
    bool accDone = false;
    for (BasicBlock *X : exiting) {
      if (!DT.dominates(X, Latch) && X != Latch)
        continue;
      const SCEV *E = SE.getExitCount(L, X);
      if (isa<SCEVCouldNotCompute>(E))
        continue;
      // reported trips <= E + 1 (header executions), <= E when every exit leaves the test region
      uint64_t need = allRegion ? t : t - 1;   // E >= need
      unsigned W = SE.getTypeSizeInBits(E->getType());
      if (W > 64)
        continue;
      SmallPtrSet<const Argument *, 2> as;
      bool other = false;
      args(E, as, other);
      if (other || as.size() != 1)
        continue;
      const Argument *Arg = *as.begin();
      if (!Arg->getType()->isIntegerTy())
        continue;
      unsigned AW = Arg->getType()->getIntegerBitWidth();
      if (!accDone)
        acc = dominatingAccesses(L), accDone = true;
      if (acc.empty())
        return "";
      auto [Lguard, Ltoward] = guardOf(L);
      if (Lguard && !DT.dominates(Lguard, L->getHeader()))
        Lguard = nullptr;
      // split the argument's range until each piece is decided
      std::vector<ConstantRange> work{ConstantRange::getFull(AW)};
      std::vector<std::pair<ConstantRange, const Access *>> ub;
      unsigned budget = 4096;
      bool ok = true;
      while (!work.empty() && ok) {
        ConstantRange I = work.back();
        work.pop_back();
        if (!budget--) {
          ok = false;
          break;
        }
        ConstantRange ER = rangeOf(E, Arg, I);
        if (ER.getUnsignedMax().ult(need))
          continue;   // no a here gives E >= need
        if (Lguard && branchAlways(Lguard, Ltoward, false, Arg, I))
          continue;   // no a here enters the loop (E counts only an entered loop)
        const Access *hit = nullptr;
        for (const Access &A : acc)
          if (outOfRange(A, Arg, I)) {
            hit = &A;
            break;
          }
        if (hit) {
          ub.push_back({I, hit});
          continue;
        }
        if (I.isSingleElement()) {
          ok = false;
          break;
        }
        // halve (as unsigned bit patterns; the full set first at its sign boundary)
        APInt lo = I.getLower(), hi = I.getUpper();   // [lo, hi)
        if (I.isFullSet()) {
          APInt m = APInt::getSignedMinValue(AW);
          work.push_back(ConstantRange(APInt::getZero(AW), m));
          work.push_back(ConstantRange(m, APInt::getZero(AW)));
          continue;
        }
        APInt size = hi - lo;   // modular size of a wrapped range too
        APInt mid = lo + size.lshr(1);
        work.push_back(ConstantRange(lo, mid));
        work.push_back(ConstantRange(mid, hi));
      }
      if (!ok || ub.empty())
        continue;
      std::string s;
      raw_string_ostream os(s);
      os << "outside the domain: " << t << " trips of " << operandName(L->getHeader())
         << " need the exit count of " << operandName(X) << " (LLVM ScalarEvolution: " << scevText(E) << ") >= "
         << need << ", and every value of " << operandName(Arg) << " that gives it makes an access before the loop "
         << "leave its object (getObjectSize), e.g. " << operandName(Arg) << " in " << ub[0].first << ": '"
         << text(ub[0].second->I) << "' at offset " << rangeOf(ub[0].second->off, Arg, ub[0].first)
         << " of a " << ub[0].second->objSize << "-byte object";
      return os.str();
    }
    return "";
  }
};

struct TripFactsPass : PassInfoMixin<TripFactsPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM) {
    auto &FAM = MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
    // which loops the oracle cuts at K (OracleInstr.cpp analyseCutoffs: the pass's own classification)
    std::optional<cq::TaintInfo> Taint;
    bool surface = false;
    for (Function &G : M)
      if (G.isDeclaration() && (G.getName().starts_with("cq_theta_") || G.getName() == "cq_phi" ||
                                G.getName().starts_with("cq_measure_")) && !G.use_empty())
        surface = true;
    if (surface)
      Taint = cq::computeTaint(M, cq::TaintOptions{});
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      auto &SE = FAM.getResult<ScalarEvolutionAnalysis>(F);
      auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
      auto &LI = FAM.getResult<LoopAnalysis>(F);
      auto &AC = FAM.getResult<AssumptionAnalysis>(F);
      auto &TLI = FAM.getResult<TargetLibraryAnalysis>(F);
      Facts Fx{F, SE, DT, LI, AC, TLI, M.getDataLayout()};
      unsigned K = kOf(F);
      for (Loop *L : LI.getLoopsInPreorder()) {
        bool qexit = false;
        if (Taint)
          for (const cq::Specialization &S : Taint->specializations())
            if (S.F == &F && cq::loops::classify(*L, *Taint, S) == cq::loops::Case::QuantumExit)
              qexit = true;
        Region Rg = headerRegion(L);
        std::string key = F.getName().str() + ":" + operandName(L->getHeader());
        for (unsigned t = 1; t <= TripMax; ++t) {
          std::string why = Fx.valueSet(L, t, Rg, qexit, K);
          std::string kind = "value-set";
          if (why.empty()) {
            // a capped record needs more than K trips: the target is K + 1 trips at least
            why = Fx.domain(L, qexit && t > K ? K + 1 : t, Rg);
            kind = "domain";
          }
          if (!why.empty())
            outs() << "cq-trip-fact\t" << key << "\t" << t << "\t" << kind << "\t" << why << "\n";
        }
      }
    }
    return PreservedAnalyses::all();
  }
};

} // namespace

void cqRegisterTripFacts(PassBuilder &PB) {
  PB.registerPipelineParsingCallback(
      [](StringRef name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
        if (name != "cq-trip-facts")
          return false;
        MPM.addPass(TripFactsPass());
        return true;
      });
}
