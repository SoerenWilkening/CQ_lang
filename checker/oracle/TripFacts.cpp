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
#include "cq/Loops.h"
#include "cq/Taint.h"

#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
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
      Facts Fx{F, SE, DT, LI, AC, M.getDataLayout()};
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
