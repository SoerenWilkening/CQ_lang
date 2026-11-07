// Module taint: rule 3 forward taint, rule 18 specializations, rule 20 host-residency, A1 control dependence. See
// TaintImpl.h for the lattice.
//
// computeTaint builds one fresh Impl and iterates the whole module to a fixed point:
//   1. every defined function that is externally visible or address-taken gets its in-place
//      specialization (the all-classical one, the function's own symbol, rewritten when Q2 says); -cq-roots add
//      library-build roots;
//   2. each specialization is analysed: lanes of every SSA value, control dependence on tainted
//      terminators, the host-residency of its allocas, and the callee specialization of every
//      call (a new key creates a new specialization);
//   3. repeat until nothing changes (lanes, demotions, keys only grow);
//   4. reachability from the roots, twins and _pure variants, masks, names, the published list.
// No state outlives the call: computeTaint is safe to call twice on one module (cq-5k5, option a).
#include "TaintImpl.h"

#include <algorithm>
#include <functional>
#include <numeric>
#include <set>

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/MemoryBuiltins.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/TargetParser/Triple.h"

using namespace llvm;

namespace cq {
struct TaintInfo::Impl : taintimpl::ImplState {};
} // namespace cq

namespace cq::taintimpl {
namespace {

// ---------------------------------------------------------------------------------------------
// Small lattice helpers.


bool orInto(Lanes &dst, const Lanes &src) {
  if (dst.size() < src.size())
    dst.resize(src.size());
  Lanes before = dst;
  Lanes s = src;
  s.resize(dst.size());
  dst |= s;
  return dst != before;
}

Lanes allLanes(unsigned n) {
  Lanes l(n);
  l.set();
  return l;
}

bool anyLane(const Lanes &l) { return l.any(); }


} // namespace



namespace {


// ---------------------------------------------------------------------------------------------
// CQ.h surface and callee recognition.

bool isTheta(const Function *F) { return F && F->getName().starts_with("cq_theta_"); }
bool isMeasure(const Function *F) { return F && F->getName().starts_with("cq_measure_"); }
bool isPhi(const Function *F) { return F && F->getName() == "cq_phi"; }
bool isInvertMarker(const Function *F) {
  return F && (F->getName() == "__cq_invert_begin" || F->getName() == "__cq_invert_end");
}

// LLVM math intrinsics that rule 18 routes to the libm function of the same name (175, 184); the same
// set as spine's isLibmIntrinsic (Classify.cpp), which sends each to calls::lowerLifted. The
// templates (CR §1.2) cover the rest (fabs, sqrt, floor, fma, ...), which stay ordinary opcodes.
std::optional<std::string> libmNameOf(const Function *F) {
  if (!F || !F->isIntrinsic() || F->arg_empty())
    return std::nullopt;
  static const std::map<Intrinsic::ID, const char *> names = {
      {Intrinsic::exp, "exp"},     {Intrinsic::exp2, "exp2"},   {Intrinsic::exp10, "exp10"},
      {Intrinsic::log, "log"},     {Intrinsic::log2, "log2"},   {Intrinsic::log10, "log10"},
      {Intrinsic::pow, "pow"},     {Intrinsic::sin, "sin"},     {Intrinsic::cos, "cos"},
      {Intrinsic::tan, "tan"},     {Intrinsic::asin, "asin"},   {Intrinsic::acos, "acos"},
      {Intrinsic::atan, "atan"},   {Intrinsic::sinh, "sinh"},   {Intrinsic::cosh, "cosh"},
      {Intrinsic::tanh, "tanh"},   {Intrinsic::ldexp, "ldexp"}, {Intrinsic::frexp, "frexp"},
      {Intrinsic::nearbyint, "nearbyint"}, {Intrinsic::roundeven, "roundeven"},
      {Intrinsic::lround, "lround"},       {Intrinsic::llround, "llround"},
      {Intrinsic::lrint, "lrint"},         {Intrinsic::llrint, "llrint"},
      {Intrinsic::minimum, "fminimum"},    {Intrinsic::maximum, "fmaximum"},
  };
  Type *T = F->getFunctionType()->getParamType(0);
  if (F->getIntrinsicID() == Intrinsic::powi) {
    // No C name: LLVM's own libcall for it is compiler-rt's __powi<m>f2 (the bundle's library).
    if (T->isFloatTy())
      return std::string("__powisf2");
    if (T->isDoubleTy())
      return std::string("__powidf2");
    if (T->isX86_FP80Ty())
      return std::string("__powixf2");
    return std::nullopt;
  }
  auto it = names.find(F->getIntrinsicID());
  if (it == names.end())
    return std::nullopt;
  std::string n = it->second;
  if (T->isFloatTy())
    n += "f";
  else if (T->isX86_FP80Ty())
    n += "l";
  else if (!T->isDoubleTy())
    return std::nullopt;
  return n;
}

// Q2 (rulings): a call for rule 19's "no call": any call site except a rule-4 opcode intrinsic (templates or opcodes)
// and a lifetime, debug, assume or noalias-scope intrinsic.
bool countsAsCall(const CallBase &CB) {
  const Function *G = CB.getCalledFunction();
  if (!G || !G->isIntrinsic())
    return true;
  if (isa<MemIntrinsic>(CB))
    return true;
  switch (G->getIntrinsicID()) {
  case Intrinsic::vastart:
  case Intrinsic::vacopy:
  case Intrinsic::vaend:
    return true;
  default:
    return libmNameOf(G).has_value();
  }
}

// Rule 24: every use of the object is, through getelementptrs with untainted indices, a load or a store through it
// (lifetime and debug intrinsics aside).
bool onlyAccessedThrough(const Value &Obj, function_ref<bool(const Value *)> tainted, bool *stored = nullptr) {
  SmallVector<const Value *, 8> work{&Obj};
  SmallPtrSet<const Value *, 16> seen;
  while (!work.empty()) {
    const Value *V = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    for (const Use &Us : V->uses()) {
      const User *U = Us.getUser();
      if (auto *G = dyn_cast<GEPOperator>(U); G && Us.getOperandNo() == 0) {
        for (const Use &Idx : G->indices())
          if (tainted(Idx.get()))
            return false;
        work.push_back(U);
      } else if (isa<LoadInst>(U)) {
        continue;
      } else if (auto *SI = dyn_cast<StoreInst>(U)) {
        if (SI->getPointerOperand() != V)
          return false;
        if (stored)
          *stored = true;
      } else if (auto *II = dyn_cast<IntrinsicInst>(U); II && (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II))) {
        continue;
      } else {
        return false;
      }
    }
  }
  return true;
}

// Rule 20 (a) with rule 24's case: a constant global, or an internal global only loaded through (48).
bool hostGlobal(const GlobalVariable &GV) {
  if (GV.isConstant())
    return true;
  bool stored = false;
  return GV.hasLocalLinkage() && GV.hasInitializer() &&
         onlyAccessedThrough(GV, [](const Value *) { return false; }, &stored) && !stored;
}

// <fenv.h> (C17 7.6): the floating-point environment calls rule 23 splits into host and rail parts.
bool isFenvCall(StringRef n) {
  static const char *names[] = {"feclearexcept", "fegetexceptflag", "feraiseexcept",
                                "fesetexceptflag", "fetestexcept",  "fegetround",
                                "fesetround",      "fegetenv",      "feholdexcept",
                                "fesetenv",        "feupdateenv"};   // not the trap-enable extensions: rule 27 (CR rule 23)
  for (const char *x : names)
    if (n == x)
      return true;
  return false;
}

} // namespace

// ---------------------------------------------------------------------------------------------
// The analysis.

class Analyzer {
public:
  explicit Analyzer(ImplState &S) : st(S) {}
  void run();

  // Lanes of a type.
  unsigned lanesOf(Type *T);
  unsigned laneOffset(Type *Agg, ArrayRef<unsigned> idx);
  FnInfo &fn(const Function *F);

private:
  ImplState &st;
  SpecState *cur = nullptr;
  bool localChanged = false;

  // Rule 23 (cq-pu8b): the environment state (fenvstate encoding, symbolic over cur's entry state)
  // before the instruction being transferred, and its transfer.
  uint8_t fenvCur = 0;
  uint8_t fenvNow() const { return fenvstate::eval(fenvCur, cur->fenvIn); }
  void fenvAssign(unsigned k, uint8_t n) {
    fenvCur = fenvstate::withNib(fenvCur, k, n);
    if (!(cur->fenvWrites & (1u << k))) {
      cur->fenvWrites |= uint8_t(1u << k);
      st.changed = true;
    }
  }
  void fenvRecord(const Instruction &I, uint8_t before) { cur->fenvAt[&I] = {before, fenvCur}; }
  void transferFenvCall(CallBase &CB, StringRef cname, ArrayRef<Value *> actuals, unsigned rn);
  void fenvAfterCall(CallBase &CB);

  // Specializations.
  bool eventPrecedes(const CallBase &CB);
  void propagateEvents();
  SpecState *getSpec(Function *F, std::vector<Lanes> formal, std::vector<Type *> tys, bool ctl, bool pure,
                     std::vector<uint64_t> bounds, std::vector<unsigned> boundFormals = {}, bool plain = false, bool table = false);
  void analyze(SpecState &S);

  // Per-value access within cur.
  //
  // Rule 14 exit reads (cq-1v3i): a value defined in a loop whose next trip is decided by a tainted
  // terminator is, when read outside that loop, the exit value merged over the quantum exit trip,
  // so the read is quantum whatever the instruction reading it (phi, select, store, call actual,
  // return, branch condition), a pointer like any other (rule 21: a pointer is an integer, one rail).
  // L(V) applies this to the instruction whose operands are being read (curUser).
  const Instruction *curUser = nullptr;
  bool exitRead(const Value *V);
  // Rule 2 (cq-41y3): "dominated uses of the measured SSA value denote the outcome", and a value
  // computed only from measured rails and classical values is classical. L(V) reads V as classical
  // in curUser when every use of V in curUser is dominated by a cq_measure_* call of this function
  // whose operand is V. A rail read before its measurement keeps its taint (cq-r6bc, open). A
  // rule 14 exit read wins: the carried value merged over a quantum exit trip stays quantum.
  bool measuredRead(const Value *V);
  void computeExitQ(SpecState &S);
  Lanes L(const Value *V);
  bool setL(const Value *V, const Lanes &l);

  void computeCDT(SpecState &S);
  bool blockCT(const BasicBlock *BB) const;
  bool edgeChosen(const BasicBlock *from, const BasicBlock *to);
  const DenseMap<const BasicBlock *, SmallVector<const BasicBlock *, 4>> &joinEdgeCD(const BasicBlock *J);
  bool chosenAtDependentJoin(const PHINode &PN);
  void loopHeaderRule(SpecState &S, const BasicBlock *H, SmallPtrSetImpl<const PHINode *> &quantum);
  // Rule 14 re-roll by SCEV, rules 20/21 (cq-0hdy, 189, 190): a pointer header phi advanced by a
  // fixed classical GEP each trip is a function of the classical trip index j (start + j * step),
  // not a carried value: its offset is classical in the loop even when the exit is quantum.
  bool classicalInduction(const PHINode &PN);

  void transfer(Instruction &I);
  void transferPhi(PHINode &PN, const SmallPtrSetImpl<const PHINode *> &headerQ);
  void transferSelect(SelectInst &SI);
  void transferBinary(BinaryOperator &BO);
  void transferCast(CastInst &CI);
  void transferGEP(GetElementPtrInst &G);
  // Rule 20: the base of ptr through getelementptrs with untainted indices, as cur sees them.
  const Value *hostBase(const Value *ptr);
  // Rule 20 (b), rule 23's and rule 24's cases: the monotone demotion test, part of the fixed point.
  bool hostAlloca(const AllocaInst *A) const { return !cur->demoted.count(A); }
  bool hostUsersOk(const AllocaInst &A);
  void demoteAllocas(SpecState &S);
  // The host-resident object p reaches, else nullptr (rule 20: no pointer is otherwise resolved).
  const Value *hostObject(const Value *ptr);
  bool quantumScope(const BasicBlock *BB) const { return blockCT(BB) || cur->ctl; }
  // Rule 24's test of a getelementptr index: a value of another function has no answer in this specialization.
  std::function<bool(const Value *)> ownTainted() {
    return [this](const Value *v) {
      auto *I = dyn_cast<Instruction>(v);
      auto *Ar = dyn_cast<Argument>(v);
      return !(I && I->getFunction() != cur->F) && !(Ar && Ar->getParent() != cur->F) && L(v).any();
    };
  }
  void transferLoad(LoadInst &LI);
  void transferStore(Instruction &I, Value *ptr, Value *val);
  void transferMemIntrinsic(MemIntrinsic &MI);
  void transferCall(CallBase &CB);
  void lift(CallBase &CB, Function *G, ArrayRef<Value *> actuals, bool viaIntrinsic);
  void declaredClone(CallBase &CB, Function *G, ArrayRef<Value *> actuals);
  // cq-1c5j (CR rules 18, 20): a call's callee key rises with its actuals' lanes during the fixed point, and a
  // specialization reached on the way (or a non-ctl probe) keeps contributing facts (stores into the caller's
  // objects, its own formals' provenance) although no final call reaches it. The analysis therefore runs a
  // second time from nothing, each call taking at once the key the first run ended with (CalleeMemo): only
  // the specializations the program reaches contribute.
  struct CalleeMemo { std::vector<Lanes> formal; bool ctl; std::vector<uint64_t> bounds; };
  std::map<std::tuple<std::string, const CallBase *, const Function *>, CalleeMemo> calleeMemo;
  void solve();
  void computeReachable();
  void resetAnalysis();
  void recordCallee(CallBase &CB, SpecState *C) {
    auto &v = cur->callees[&CB];
    if (v.size() != 1 || v[0] != C) {
      v.assign(1, C);
      localChanged = true;
    }
  }
  std::optional<uint64_t> rangeBound(const Value *V);
  // Rule 18 (rulings3 F): F mints a register inside a loop, or calls a callee that rotates and returns a result (a void one hands
  // no register, rule 19) inside a loop or on a call cycle with F.
  std::map<const Function *, bool> mintsPerTripCache;
  bool mintsPerTrip(const Function *F) {
    if (F->isDeclaration())
      return false;
    auto [it, fresh] = mintsPerTripCache.try_emplace(F, false);
    if (!fresh)
      return it->second;
    bool found = false;
    const LoopInfo &LI = *fn(F).LI;
    for (const BasicBlock &BB : *F)
      for (const Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (const Function *G = CB->getCalledFunction()) {
            bool loop = LI.getLoopFor(&BB) != nullptr;
            if (G->isDeclaration())
              found = found || (loop && G->getName().starts_with("cq_theta_"));
            else if (!G->getReturnType()->isVoidTy() && (loop || callsReach(G, F)) && rotatesByName(G))
              found = true;
          }
    return mintsPerTripCache[F] = found;
  }
  bool measuresInLoop(const Function *F) {
    if (F->isDeclaration())
      return false;
    const LoopInfo &LI = *fn(F).LI;
    for (const BasicBlock &BB : *F) {
      if (!LI.getLoopFor(&BB))
        continue;
      for (const Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (const Function *G = CB->getCalledFunction())
            if (G->isDeclaration() ? G->getName().starts_with("cq_measure_") : measuresByName(G))
              return true;
    }
    return false;
  }
  bool measuresByName(const Function *F) {
    SmallPtrSet<const Function *, 16> seen{F};
    SmallVector<const Function *, 16> work{F};
    while (!work.empty()) {
      const Function *X = work.pop_back_val();
      for (const BasicBlock &BB : *X)
        for (const Instruction &I : BB)
          if (auto *CB = dyn_cast<CallBase>(&I))
            if (const Function *G = CB->getCalledFunction()) {
              if (G->isDeclaration() && G->getName().starts_with("cq_measure_"))
                return true;
              if (!G->isDeclaration() && seen.insert(G).second)
                work.push_back(G);
            }
    }
    return false;
  }
  // F's body rotates, itself or through a callee by name.
  bool rotatesByName(const Function *F) {
    SmallPtrSet<const Function *, 16> seen{F};
    SmallVector<const Function *, 16> work{F};
    while (!work.empty()) {
      const Function *X = work.pop_back_val();
      for (const BasicBlock &BB : *X)
        for (const Instruction &I : BB)
          if (auto *CB = dyn_cast<CallBase>(&I))
            if (const Function *G = CB->getCalledFunction()) {
              if (G->getName().starts_with("cq_theta_"))
                return true;
              if (!G->isDeclaration() && seen.insert(G).second)
                work.push_back(G);
            }
    }
    return false;
  }
  // G reaches F through direct calls of defined functions (recursion, rule 14).
  std::map<std::pair<const Function *, const Function *>, bool> reachCache;
  bool callsReach(const Function *G, const Function *F) {
    auto key = std::make_pair(G, F);
    auto it = reachCache.find(key);
    if (it != reachCache.end())
      return it->second;
    SmallPtrSet<const Function *, 16> seen;
    SmallVector<const Function *, 16> work{G};
    bool found = false;
    while (!work.empty() && !found) {
      const Function *X = work.pop_back_val();
      if (X->isDeclaration())
        continue;
      for (const BasicBlock &BB : *X)
        for (const Instruction &I : BB)
          if (auto *CB = dyn_cast<CallBase>(&I))
            if (const Function *C = CB->getCalledFunction()) {
              if (C == F) {
                found = true;
                break;
              }
              if (seen.insert(C).second)
                work.push_back(C);
            }
    }
    reachCache[key] = found;
    return found;
  }

  // Post-fixpoint.
  void finish();
  std::string buildMask(SpecState &S);
};

FnInfo &Analyzer::fn(const Function *F) {
  auto it = st.fns.find(F);
  if (it != st.fns.end())
    return *it->second;
  auto info = std::make_unique<FnInfo>();
  Function &MF = const_cast<Function &>(*F);
  info->DT = std::make_unique<DominatorTree>(MF);
  info->PDT = std::make_unique<PostDominatorTree>(MF);
  info->LI = std::make_unique<LoopInfo>(*info->DT);
  ReversePostOrderTraversal<Function *> RPOT(&MF);
  for (BasicBlock *BB : RPOT)
    info->rpo.push_back(BB);
  // Direct control dependence (Ferrante et al.): for an edge A -> S of a branching A, every block on
  // the post-dominator tree path from S up to (excluding) ipdom(A) is control dependent on A.
  //
  // Dead ends (DeadEnd.h, cq-820w): an edge into a dead end does not restrict its siblings. For a
  // block that reaches a return, post-dominance is taken over the paths to a return only (the
  // live subgraph), and a branch counts only through its live successors: a branch whose live
  // successors are all one block makes nothing live control dependent on it. A dead end keeps the
  // ordinary answer (it stays control dependent on the branch into it).
  info->dead = taint_detail::DeadEnds(MF);
  const taint_detail::DeadEnds &dead = info->dead;
  auto addParent = [&](const BasicBlock *X, const BasicBlock *A) {
    auto &v = info->cdParents[X];
    if (llvm::find(v, A) == v.end())
      v.push_back(A);
  };
  for (const BasicBlock *A : info->rpo) {
    SmallSetVector<const BasicBlock *, 4> succs;
    for (const BasicBlock *S : successors(A))
      succs.insert(S);
    if (succs.size() < 2)
      continue;
    DomTreeNode *AN = info->PDT->getNode(A);
    DomTreeNode *stop = AN ? AN->getIDom() : nullptr;
    for (const BasicBlock *S : succs) {
      DomTreeNode *X = info->PDT->getNode(S);
      while (X && X != stop) {
        if (BasicBlock *XB = X->getBlock())
          if (dead.isDeadEnd(XB))
            addParent(XB, A);
        X = X->getIDom();
      }
    }
  }
  // Post-dominance over the live subgraph: pdom(Y) = {Y} | AND over Y's live successors of pdom(s).
  std::vector<const BasicBlock *> liveBlocks;
  DenseMap<const BasicBlock *, unsigned> liveIdx;
  for (const BasicBlock *B : info->rpo)
    if (!dead.isDeadEnd(B)) {
      liveIdx[B] = liveBlocks.size();
      liveBlocks.push_back(B);
    }
  unsigned nLive = liveBlocks.size();
  std::vector<BitVector> pdom(nLive, BitVector(nLive, true));
  for (unsigned i = 0; i < nLive; ++i)
    if (taint_detail::DeadEnds::returns(liveBlocks[i])) {
      pdom[i].reset();
      pdom[i].set(i);
    }
  for (bool ch = true; ch;) {
    ch = false;
    for (unsigned i = nLive; i-- > 0;) {
      const BasicBlock *Y = liveBlocks[i];
      if (taint_detail::DeadEnds::returns(Y))
        continue;
      BitVector nv(nLive, true);
      bool any = false;
      for (const BasicBlock *S : successors(Y)) {
        auto it = liveIdx.find(S);
        if (it == liveIdx.end())
          continue;   // a dead end, or a block unreachable from the entry (no path to it from Y)
        nv &= pdom[it->second];
        any = true;
      }
      if (!any)
        internalError("taint: a block that reaches a return has no live successor", Y->getTerminator());
      nv.set(i);
      if (nv != pdom[i]) {
        pdom[i] = std::move(nv);
        ch = true;
      }
    }
  }
  for (unsigned a = 0; a < nLive; ++a) {
    const BasicBlock *A = liveBlocks[a];
    SmallVector<unsigned, 4> liveSuccs;
    for (const BasicBlock *S : successors(A)) {
      auto it = liveIdx.find(S);
      if (it != liveIdx.end() && llvm::find(liveSuccs, it->second) == liveSuccs.end())
        liveSuccs.push_back(it->second);
    }
    if (liveSuccs.size() < 2)
      continue;
    for (unsigned s : liveSuccs)
      for (unsigned x : pdom[s].set_bits())
        if (x == a || !pdom[a].test(x))   // x post-dominates s and not strictly A
          addParent(liveBlocks[x], A);
  }
  auto *raw = info.get();
  st.fns[F] = std::move(info);
  return *raw;
}

unsigned Analyzer::lanesOf(Type *T) {
  auto it = st.laneCount.find(T);
  if (it != st.laneCount.end())
    return it->second;
  unsigned n = 0;
  if (auto *IT = dyn_cast<IntegerType>(T))
    n = std::max(1u, (IT->getBitWidth() + 7) / 8);
  else if (T->isFloatingPointTy())
    n = 1;
  else if (T->isPointerTy())
    n = 1;   // rule 3: one 64-bit address rail
  else if (auto *ST = dyn_cast<StructType>(T)) {
    for (Type *E : ST->elements())
      n += lanesOf(E);
  } else if (auto *AT = dyn_cast<ArrayType>(T))
    n = unsigned(AT->getNumElements()) * lanesOf(AT->getElementType());
  else if (auto *VT = dyn_cast<FixedVectorType>(T))
    n = VT->getNumElements() * lanesOf(VT->getElementType());
  else if (T->isVoidTy() || T->isLabelTy() || T->isMetadataTy() || T->isTokenTy())
    n = 0;
  else
    internalError("taint: IR the pinned pipeline cannot emit (CR §0, rule 25): lanes of a value of a type C on x86-64 has no counterpart for");
  st.laneCount[T] = n;
  return n;
}

unsigned Analyzer::laneOffset(Type *Agg, ArrayRef<unsigned> idx) {
  unsigned off = 0;
  Type *T = Agg;
  for (unsigned i : idx) {
    if (auto *ST = dyn_cast<StructType>(T)) {
      for (unsigned k = 0; k < i; ++k)
        off += lanesOf(ST->getElementType(k));
      T = ST->getElementType(i);
    } else if (auto *AT = dyn_cast<ArrayType>(T)) {
      off += i * lanesOf(AT->getElementType());
      T = AT->getElementType();
    } else if (auto *VT = dyn_cast<FixedVectorType>(T)) {
      off += i * lanesOf(VT->getElementType());
      T = VT->getElementType();
    } else {
      internalError("taint: laneOffset into a non-aggregate");
    }
  }
  return off;
}


// ---------------------------------------------------------------------------------------------
// Specializations.

std::string lanesStr(const Lanes &l) {
  std::string s;
  for (unsigned i = 0; i < l.size(); ++i)
    s += l.test(i) ? '1' : '0';
  return s;
}


static SmallVector<unsigned, 4> intFields(const Argument *A);

SpecState *Analyzer::getSpec(Function *F, std::vector<Lanes> formal, std::vector<Type *> tys, bool ctl, bool pure,
                             std::vector<uint64_t> bounds, std::vector<unsigned> boundFormals, bool plain, bool table) {
  // Rule 18, §1.4: a clone exists once per taint mask of its scalar formals, and a quantum scalar formal is one rail. Byte
  // lanes of an integer actual (x & 4095) never split a mask digit: its whole field is the rail, so calls whose actuals
  // differ only in their quantum bytes reach one clone.
  for (unsigned i = 0; i < formal.size() && i < tys.size(); ++i) {
    if (!tys[i]->isIntegerTy() || formal[i].none())
      continue;
    if (i >= F->arg_size() || F->isDeclaration() || !F->getArg(i)->getType()->isIntegerTy()) {
      formal[i].set();
      continue;
    }
    SmallVector<unsigned, 4> b = intFields(F->getArg(i));
    for (unsigned k = 0; k + 1 < b.size(); ++k) {
      unsigned lo = b[k] / 8, hi = std::min<unsigned>((b[k + 1] + 7) / 8, formal[i].size());
      bool q = false;
      for (unsigned lane = lo; lane < hi; ++lane)
        q = q || formal[i].test(lane);
      if (q)
        for (unsigned lane = lo; lane < hi; ++lane)
          formal[i].set(lane);
    }
  }
  // A bound with no formal named (a library-build root read from its name): the quantum integer formals
  // in order, the reading §1.4's name gives.
  if (boundFormals.size() != bounds.size()) {
    boundFormals.clear();
    for (unsigned i = 0; i < formal.size() && boundFormals.size() < bounds.size(); ++i)
      if (i < tys.size() && tys[i]->isIntegerTy() && tys[i]->getIntegerBitWidth() > 1 && formal[i].any())
        boundFormals.push_back(i);
    if (boundFormals.size() != bounds.size())
      internalError("taint: a clone's bounds outnumber its quantum integer formals", F);
  }
  std::string key = F->getName().str();
  key += "|";
  for (unsigned i = 0; i < formal.size(); ++i)
    key += lanesStr(formal[i]) + ",";
  key += "|" + std::to_string(ctl) + std::to_string(pure) + std::to_string(plain) + (table ? "t" : "");
  for (size_t i = 0; i < bounds.size(); ++i)
    key += ":b" + std::to_string(boundFormals[i]) + "=" + std::to_string(bounds[i]);
  auto it = st.byKey.find(key);
  if (it != st.byKey.end())
    return it->second;
  auto S = std::make_unique<SpecState>();
  S->F = F;
  S->formal = std::move(formal);
  S->formalTy = std::move(tys);
  S->ctl = ctl;
  S->pure = pure;
  S->bounds = std::move(bounds);
  S->boundFormals = std::move(boundFormals);
  S->declared = F->isDeclaration();
  S->plain = plain;
  S->table = table;
  bool zero = !ctl && !pure && !plain && !table && S->bounds.empty();
  for (const Lanes &l : S->formal)
    zero = zero && l.none();
  S->inPlace = zero && !S->declared;
  S->key = key;
  S->ret = Lanes(lanesOf(F->getReturnType()));
  SpecState *raw = S.get();
  st.byKey[key] = raw;
  st.specs.push_back(std::move(S));
  st.changed = true;
  return raw;
}

Lanes Analyzer::L(const Value *V) {
  Type *T = V->getType();
  if (isa<Constant>(V) || isa<BasicBlock>(V) || isa<MetadataAsValue>(V) || isa<InlineAsm>(V))
    return Lanes(lanesOf(T));
  if (exitRead(V))
    return allLanes(lanesOf(T));
  if (measuredRead(V))
    return Lanes(lanesOf(T));
  if (auto *A = dyn_cast<Argument>(V)) {
    if (A->getParent() != cur->F)
      internalError("taint: argument of another function", V);
    return cur->formal[A->getArgNo()];
  }
  auto it = cur->lanes.find(V);
  if (it != cur->lanes.end())
    return it->second;
  return Lanes(lanesOf(T));
}

bool Analyzer::exitRead(const Value *V) {
  if (!curUser || cur->exitQ.empty())
    return false;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getFunction() != curUser->getFunction())
    return false;
  for (const Loop *Lp = fn(cur->F).LI->getLoopFor(I->getParent()); Lp; Lp = Lp->getParentLoop())
    if (!Lp->contains(curUser) && cur->exitQ.count(Lp))
      return true;
  return false;
}

bool Analyzer::measuredRead(const Value *V) {
  if (!curUser || curUser->getFunction() != cur->F)
    return false;
  if (auto *A = dyn_cast<Argument>(V)) {
    if (A->getParent() != cur->F)
      return false;
  } else if (auto *I = dyn_cast<Instruction>(V)) {
    if (I->getFunction() != cur->F)
      return false;
  } else {
    return false;
  }
  // Rule 19: inside a _ctl clone the measured rail is a controlled copy; `h` is not collapsed where the predicate is 0 and rule 2's
  // classical collapse does not apply to it, so a later read of it is still quantum.
  if (cur->ctl)
    return false;
  // Rules 2, 14 (owner, cq-2z29a): a loop-carried value with a rail among its incoming values is a rail in every trip. Rule 2's "computed only
  // from measured rails and classical values" speaks of a value whose every operand is such; a phi with a rail incoming is not.
  if (auto *P = dyn_cast<PHINode>(V))
    if (const Loop *Lp = fn(cur->F).LI->getLoopFor(P->getParent()); Lp && Lp->getHeader() == P->getParent())
      return false;
  SmallVector<const CallBase *, 2> meas;
  for (const User *U : V->users())
    if (auto *CB = dyn_cast<CallBase>(U))
      if (CB != curUser && CB->getFunction() == cur->F && isMeasure(CB->getCalledFunction()) &&
          CB->arg_size() >= 1 && CB->getArgOperand(0) == V)
        meas.push_back(CB);
  if (meas.empty())
    return false;
  const DominatorTree &DT = *fn(cur->F).DT;
  bool any = false;
  for (const Use &U : V->uses()) {
    if (U.getUser() != curUser)
      continue;
    any = true;
    bool dom = false;
    for (const CallBase *M : meas)
      if (DT.dominates(M, U)) {
        dom = true;
        break;
      }
    if (!dom)
      return false;
  }
  return any;
}

// The loops of S whose header is control dependent on a tainted terminator inside the loop.
void Analyzer::computeExitQ(SpecState &S) {
  FnInfo &fi = fn(S.F);
  for (const BasicBlock *BB : fi.rpo) {
    Loop *Lp = fi.LI->getLoopFor(BB);
    if (!Lp || Lp->getHeader() != BB || S.exitQ.count(Lp))
      continue;
    auto hit = S.cdt.find(BB);
    if (hit == S.cdt.end())
      continue;
    for (const BasicBlock *T : hit->second)
      if (Lp->contains(T)) {
        // A terminator read in this round's computeCDT may have missed it: one more round.
        S.exitQ.insert(Lp);
        localChanged = true;
        break;
      }
  }
}


bool Analyzer::setL(const Value *V, const Lanes &l) {
  Lanes &dst = cur->lanes[V];
  if (dst.size() == 0)
    dst.resize(lanesOf(V->getType()));
  if (orInto(dst, l)) {
    localChanged = true;
    return true;
  }
  return false;
}


// ---------------------------------------------------------------------------------------------
// Control dependence on tainted terminators (A1).

static const Value *terminatorCondition(const Instruction *T) {
  if (auto *BI = dyn_cast<BranchInst>(T))
    return BI->isConditional() ? BI->getCondition() : nullptr;
  if (auto *SI = dyn_cast<SwitchInst>(T))
    return SI->getCondition();
  if (auto *IB = dyn_cast<IndirectBrInst>(T))
    return IB->getAddress();
  return nullptr;
}

void Analyzer::computeCDT(SpecState &S) {
  FnInfo &fi = fn(S.F);
  S.taintedTerm.clear();
  for (const BasicBlock *BB : fi.rpo) {
    const Value *c = terminatorCondition(BB->getTerminator());
    curUser = BB->getTerminator();
    if (c && anyLane(L(c)))
      S.taintedTerm.insert(BB);
    curUser = nullptr;
  }
  S.cdt.clear();
  bool ch = true;
  while (ch) {
    ch = false;
    for (const BasicBlock *BB : fi.rpo) {
      auto pit = fi.cdParents.find(BB);
      if (pit == fi.cdParents.end())
        continue;
      SmallVector<const BasicBlock *, 4> v;
      for (const BasicBlock *A : pit->second) {
        if (S.taintedTerm.count(A))
          v.push_back(A);
        auto ait = S.cdt.find(A);
        if (ait != S.cdt.end())
          v.append(ait->second.begin(), ait->second.end());
      }
      llvm::sort(v);
      v.erase(std::unique(v.begin(), v.end()), v.end());
      auto &dst = S.cdt[BB];
      if (dst.size() != v.size() || !std::equal(v.begin(), v.end(), dst.begin())) {
        dst.assign(v.begin(), v.end());
        ch = true;
      }
    }
  }
}

bool Analyzer::blockCT(const BasicBlock *BB) const {
  auto it = cur->cdt.find(BB);
  return it != cur->cdt.end() && !it->second.empty();
}

// The edge from -> to is decided by a tainted terminator that `to` itself does not depend on.
bool Analyzer::edgeChosen(const BasicBlock *from, const BasicBlock *to) {
  SmallVector<const BasicBlock *, 4> E;
  auto fit = cur->cdt.find(from);
  if (fit != cur->cdt.end())
    E.append(fit->second.begin(), fit->second.end());
  if (cur->taintedTerm.count(from)) {
    // An edge into a dead end does not restrict its siblings (cq-820w): from chooses the edge into
    // a live block only when it has two live successors.
    const taint_detail::DeadEnds &dead = fn(cur->F).dead;
    SmallPtrSet<const BasicBlock *, 4> succs;
    for (const BasicBlock *S : successors(from))
      if (dead.isDeadEnd(to) || !dead.isDeadEnd(S))
        succs.insert(S);
    if (succs.size() >= 2)
      E.push_back(from);
  }
  auto tit = cur->cdt.find(to);
  for (const BasicBlock *T : E) {
    if (tit == cur->cdt.end() || llvm::find(tit->second, T) == tit->second.end())
      return true;
  }
  return false;
}

// cq-bxc4. Control dependence of J's incoming edges within the paths that end in J: the graph G_J
// of the blocks other than J that reach a predecessor edge of J without passing through J, each edge
// P -> J a sink of its own, every sink into one virtual exit. The edge P -> J is control dependent on
// a branching A of G_J (Ferrante et al., transitively) iff, once J is reached, which edge entered it
// depends on A's choice. Blocks that cannot reach J (a return or a dead end) are not in G_J, so a
// branch whose other successors never reach J does not choose among J's edges, and DeadEnd.h's
// semantics (cq-820w) carry over: a dead end never reaches J.
const DenseMap<const BasicBlock *, SmallVector<const BasicBlock *, 4>> &
Analyzer::joinEdgeCD(const BasicBlock *J) {
  FnInfo &fi = fn(cur->F);
  auto it = fi.joinEdgeCD.find(J);
  if (it != fi.joinEdgeCD.end())
    return it->second;
  // Nodes: 0..k-1 the sinks (one per distinct predecessor), then the blocks of G_J.
  SmallVector<const BasicBlock *, 8> preds;
  for (const BasicBlock *P : predecessors(J))
    if (llvm::find(preds, P) == preds.end())
      preds.push_back(P);
  unsigned k = preds.size();
  DenseMap<const BasicBlock *, unsigned> id;
  std::vector<const BasicBlock *> blocks;
  SmallVector<const BasicBlock *, 16> work;
  for (const BasicBlock *P : preds)
    if (P != J && id.try_emplace(P, k + blocks.size()).second) {
      blocks.push_back(P);
      work.push_back(P);
    }
  while (!work.empty()) {
    const BasicBlock *B = work.pop_back_val();
    for (const BasicBlock *Q : predecessors(B))
      if (Q != J && id.try_emplace(Q, k + blocks.size()).second) {
        blocks.push_back(Q);
        work.push_back(Q);
      }
  }
  unsigned n = k + blocks.size();
  std::vector<SmallVector<unsigned, 4>> succ(n);
  for (const BasicBlock *B : blocks) {
    auto &v = succ[id[B]];
    for (const BasicBlock *S : successors(B)) {
      unsigned s;
      if (S == J)
        s = unsigned(llvm::find(preds, B) - preds.begin());
      else if (auto sit = id.find(S); sit != id.end())
        s = sit->second;
      else
        continue;
      if (llvm::find(v, s) == v.end())
        v.push_back(s);
    }
  }
  // Post-dominator sets (every node of G_J reaches a sink).
  std::vector<BitVector> pdom(n, BitVector(n, true));
  for (unsigned i = 0; i < k; ++i) {
    pdom[i].reset();
    pdom[i].set(i);
  }
  bool ch = true;
  while (ch) {
    ch = false;
    for (unsigned i = n; i-- > k;) {
      BitVector v(n, true);
      for (unsigned s : succ[i])
        v &= pdom[s];
      v.set(i);
      if (v != pdom[i]) {
        pdom[i] = std::move(v);
        ch = true;
      }
    }
  }
  // Direct control dependence, then its transitive closure.
  std::vector<BitVector> cd(n, BitVector(n));
  for (unsigned a = k; a < n; ++a) {
    if (succ[a].size() < 2)
      continue;
    for (unsigned s : succ[a])
      for (unsigned y : pdom[s].set_bits())
        if (y == a || !pdom[a].test(y))
          cd[y].set(a);
  }
  ch = true;
  while (ch) {
    ch = false;
    for (unsigned y = 0; y < n; ++y) {
      BitVector v = cd[y];
      for (unsigned a : cd[y].set_bits())
        v |= cd[a];
      if (v != cd[y]) {
        cd[y] = std::move(v);
        ch = true;
      }
    }
  }
  auto &res = fi.joinEdgeCD[J];
  for (unsigned i = 0; i < k; ++i) {
    auto &v = res[preds[i]];
    for (unsigned a : cd[i].set_bits())
      v.push_back(blocks[a - k]);
  }
  return res;
}

// cq-bxc4 (rules 9, 13): a phi whose join J depends on a tainted terminator T is still chosen by T
// when, given that J is reached, which incoming edge entered J depends on T (a switch case block
// shared by two cases or entered by a fallthrough, an if/else-if join whose last arm returns). The
// other tainted terminators are edgeChosen's. A loop header's entry/latch choice is rule 14's
// (loopHeaderRule), not this.
bool Analyzer::chosenAtDependentJoin(const PHINode &PN) {
  const BasicBlock *J = PN.getParent();
  auto jit = cur->cdt.find(J);
  if (jit == cur->cdt.end() || jit->second.empty())
    return false;
  if (fn(cur->F).LI->isLoopHeader(J))
    return false;
  const auto &cdE = joinEdgeCD(J);
  for (const BasicBlock *P : PN.blocks()) {
    auto eit = cdE.find(P);
    if (eit == cdE.end())
      continue;
    for (const BasicBlock *T : eit->second)
      if (cur->taintedTerm.count(T) && llvm::find(jit->second, T) != jit->second.end())
        return true;
  }
  return false;
}

// Classical leaves of an exit condition that force the exit on their own (polarity: the value of C
// that takes the exit edge). cq-s7c4 (CR rule 14): a classical leaf of a quantum exit test counts only
// when it bounds the trip count (`known`, spine loops::classify alike); `stop || q` with `stop`
// loop-invariant bounds nothing, the loop is a K-loop and every carried value is quantum.
static void forcingLeaves(const Value *C, bool exitOn, Analyzer &A,
                          function_ref<bool(const Value *)> quantum,
                          SmallVectorImpl<const Value *> &out,
                          function_ref<bool(const Value *, bool)> known) {
  using namespace PatternMatch;
  const Value *a, *b;
  if (!quantum(C)) {
    if (known(C, exitOn))
      out.push_back(C);
    return;
  }
  if (match(C, m_LogicalOr(m_Value(a), m_Value(b)))) {
    if (exitOn) {
      forcingLeaves(a, true, A, quantum, out, known);
      forcingLeaves(b, true, A, quantum, out, known);
    }
    return;
  }
  if (match(C, m_LogicalAnd(m_Value(a), m_Value(b)))) {
    if (!exitOn) {
      forcingLeaves(a, false, A, quantum, out, known);
      forcingLeaves(b, false, A, quantum, out, known);
    }
    return;
  }
  if (match(C, m_Not(m_Value(a)))) {
    forcingLeaves(a, !exitOn, A, quantum, out, known);
    return;
  }
  // cq-wxch: the negated-condition selects, as spine's loops::classify splits them (cq-dtvp):
  // select c, t, true is !c | t and select c, false, f is !c & f. -O1 writes `i + 1 >= n || q` as
  // select(i + 1 < n, q, true).
  if (auto *Sel = dyn_cast<SelectInst>(C); Sel && Sel->getType()->isIntegerTy(1)) {
    const Value *c = Sel->getCondition(), *t = Sel->getTrueValue(), *f = Sel->getFalseValue();
    if (match(f, m_One())) {
      if (exitOn) {
        forcingLeaves(c, false, A, quantum, out, known);
        forcingLeaves(t, true, A, quantum, out, known);
      }
      return;
    }
    if (match(t, m_Zero())) {
      if (!exitOn) {
        forcingLeaves(c, true, A, quantum, out, known);
        forcingLeaves(f, false, A, quantum, out, known);
      }
      return;
    }
  }
}

// Rule 14: a loop whose next trip depends on a tainted terminator advances every carried value by a
// select on the trip predicate, so its header phis are quantum; with a classical bound (case 3) the
// phis the classical exit test reads stay classical (the loop runs classically over them).
void Analyzer::loopHeaderRule(SpecState &S, const BasicBlock *H,
                              SmallPtrSetImpl<const PHINode *> &quantum) {
  FnInfo &fi = fn(S.F);
  Loop *Lp = fi.LI->getLoopFor(H);
  if (!Lp || Lp->getHeader() != H)
    return;
  auto hit = S.cdt.find(H);
  bool qexit = false;
  if (hit != S.cdt.end())
    for (const BasicBlock *T : hit->second)
      if (Lp->contains(T))
        qexit = true;
  if (!qexit)
    return;
  auto isQ = [&](const Value *V) { return anyLane(L(V)); };
  SmallVector<const Value *, 4> leaves;
  SmallVector<BasicBlock *, 4> exiting;
  Lp->getExitingBlocks(exiting);
  for (BasicBlock *X : exiting) {
    auto *BI = dyn_cast<BranchInst>(X->getTerminator());
    if (!BI || !BI->isConditional())
      continue;
    bool trueExits = !Lp->contains(BI->getSuccessor(0));
    bool falseExits = !Lp->contains(BI->getSuccessor(1));
    if (trueExits == falseExits)
      continue;
    if (!isQ(BI->getCondition())) {
      // cq-z6q1 (CR rule 14; 189): a classical exit test bounds the loop only when LLVM computes its exit
      // count (spine loops::classify alike); otherwise the loop is a K-loop and every carried value is.
      auto key = std::make_pair(H, (const BasicBlock *)X);
      auto it = fi.exitKnown.find(key);
      if (it == fi.exitKnown.end())
        it = fi.exitKnown.emplace(key, exitCountKnown(*H, *X)).first;
      if (!it->second)
        continue;
    }
    auto known = [&](const Value *C, bool exitOn) {
      if (C == BI->getCondition())
        return true;   // a classical exit test, checked above
      auto key = std::make_pair(C, exitOn);
      auto it = fi.condKnown.find(key);
      if (it == fi.condKnown.end())
        it = fi.condKnown.emplace(key, exitCondCountKnown(*H, *C, exitOn)).first;
      return it->second;
    };
    curUser = BI;
    forcingLeaves(BI->getCondition(), trueExits, *this, isQ, leaves, known);
    curUser = nullptr;
  }
  // Header phis the classical leaves depend on, through the loop body.
  SmallPtrSet<const PHINode *, 8> driving;
  SmallVector<const Value *, 16> work(leaves.begin(), leaves.end());
  SmallPtrSet<const Value *, 32> seen;
  while (!work.empty()) {
    const Value *V = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !Lp->contains(I))
      continue;
    if (auto *PN = dyn_cast<PHINode>(I)) {
      if (PN->getParent() == H)
        driving.insert(PN);
    }
    for (const Use &U : I->operands())
      work.push_back(U.get());
  }
  for (const PHINode &PN : H->phis()) {
    bool invariant = true;
    for (const Value *In : PN.incoming_values())
      if (In != PN.getIncomingValue(0) && In != &PN)
        invariant = false;
    if (invariant)
      continue;
    if (!leaves.empty() && driving.count(&PN))
      continue;
    if (classicalInduction(PN))
      continue;
    quantum.insert(&PN);
  }
}

bool Analyzer::classicalInduction(const PHINode &PN) {
  // CR rule 14 (f981c89, cq-rmaf): an affine induction {start,+,step} -- a loop-invariant start and an
  // unconditional classical step -- is not carried; in trip j its value is start + j*step, classical
  // when the start is classical. Pointers step by GEPs, integers by add/sub of a classical invariant.
  if (PN.getNumIncomingValues() != 2)
    return false;
  bool ptr = PN.getType()->isPointerTy();
  if (!ptr && !PN.getType()->isIntegerTy())
    return false;
  FnInfo &fi = fn(cur->F);
  Loop *Lp = fi.LI->getLoopFor(PN.getParent());
  if (!Lp || Lp->getHeader() != PN.getParent())
    return false;
  const Value *start = nullptr, *next = nullptr;
  const BasicBlock *latch = nullptr;
  for (unsigned i = 0; i < 2; ++i) {
    if (Lp->contains(PN.getIncomingBlock(i))) {
      next = PN.getIncomingValue(i);
      latch = PN.getIncomingBlock(i);
    } else {
      start = PN.getIncomingValue(i);
    }
  }
  if (!start || !next || anyLane(L(start)))
    return false;
  auto invariantClassical = [&](const Value *X) {
    if (isa<Constant>(X))
      return true;
    auto *XI = dyn_cast<Instruction>(X);
    return !(XI && Lp->contains(XI)) && !anyLane(L(X));
  };
  // next = a chain of steps from PN, each in a block every trip reaching the latch runs (it dominates
  // the latch: the step is unconditional).
  const DominatorTree &DT = *fi.DT;
  const Value *V = next;
  unsigned steps = 0;
  while (V != &PN) {
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !Lp->contains(I) || !DT.dominates(I->getParent(), latch))
      return false;
    if (ptr) {
      auto *G = dyn_cast<GetElementPtrInst>(I);
      if (!G)
        return false;
      for (const Use &U : G->indices())
        if (!invariantClassical(U.get()))
          return false;
      V = G->getPointerOperand();
    } else {
      auto *BO = dyn_cast<BinaryOperator>(I);
      if (!BO || (BO->getOpcode() != Instruction::Add && BO->getOpcode() != Instruction::Sub))
        return false;
      if (BO->getOpcode() == Instruction::Add && invariantClassical(BO->getOperand(0)) &&
          !invariantClassical(BO->getOperand(1)))
        V = BO->getOperand(1);
      else if (invariantClassical(BO->getOperand(1)))
        V = BO->getOperand(0);
      else
        return false;
    }
    ++steps;
  }
  return steps > 0;
}

// ---------------------------------------------------------------------------------------------
// Transfer functions.

void Analyzer::transferPhi(PHINode &PN, const SmallPtrSetImpl<const PHINode *> &headerQ) {
  unsigned n = lanesOf(PN.getType());
  Lanes l(n);
  for (const Value *In : PN.incoming_values())
    orInto(l, L(In));
  bool allSame = true;
  for (const Value *In : PN.incoming_values())
    if (In != PN.getIncomingValue(0))
      allSame = false;
  bool chosen = headerQ.count(&PN) > 0;
  if (!allSame && !chosen)
    for (unsigned i = 0; i < PN.getNumIncomingValues(); ++i)
      if (edgeChosen(PN.getIncomingBlock(i), PN.getParent())) {
        chosen = true;
        break;
      }
  if (!allSame && !chosen)
    chosen = chosenAtDependentJoin(PN);
  if (chosen && classicalInduction(PN))
    chosen = false; // the trip index chooses it, a classical value (cq-0hdy)
  if (chosen)
    l = allLanes(n);
  setL(&PN, l);
}

void Analyzer::transferSelect(SelectInst &SI) {
  unsigned n = lanesOf(SI.getType());
  Lanes l(n);
  orInto(l, L(SI.getTrueValue()));
  orInto(l, L(SI.getFalseValue()));
  bool condQ = anyLane(L(SI.getCondition()));
  bool same = SI.getTrueValue() == SI.getFalseValue();
  if (condQ && !same)
    l = allLanes(n);
  setL(&SI, l);
}

void Analyzer::transferBinary(BinaryOperator &BO) {
  unsigned n = lanesOf(BO.getType());
  Lanes a = L(BO.getOperand(0)), b = L(BO.getOperand(1));
  a.resize(n);
  b.resize(n);
  if (a.none() && b.none())
    return;
  Type *T = BO.getType();
  auto *IT = dyn_cast<IntegerType>(T);
  if (!IT) {
    // Vectors elementwise, fp whole.
    if (auto *VT = dyn_cast<FixedVectorType>(T)) {
      unsigned per = lanesOf(VT->getElementType());
      Lanes l(n);
      for (unsigned e = 0; e < VT->getNumElements(); ++e) {
        bool q = false;
        for (unsigned k = 0; k < per; ++k)
          q = q || a.test(e * per + k) || b.test(e * per + k);
        if (q)
          for (unsigned k = 0; k < per; ++k)
            l.set(e * per + k);
      }
      setL(&BO, l);
      return;
    }
    setL(&BO, allLanes(n));
    return;
  }
  const APInt *C = nullptr;
  using namespace PatternMatch;
  unsigned W = IT->getBitWidth();
  switch (BO.getOpcode()) {
  case Instruction::And:
  case Instruction::Or:
  case Instruction::Xor: {
    Lanes l = a;
    l |= b;
    if (match(BO.getOperand(1), m_APInt(C)) && (W % 8 == 0)) {
      for (unsigned i = 0; i < n; ++i) {
        uint64_t byte = C->extractBitsAsZExtValue(8, i * 8);
        if ((BO.getOpcode() == Instruction::And && byte == 0) ||
            (BO.getOpcode() == Instruction::Or && byte == 0xff))
          l.reset(i);
      }
    }
    setL(&BO, l);
    return;
  }
  case Instruction::Shl:
  case Instruction::LShr:
  case Instruction::AShr: {
    if (b.none() && match(BO.getOperand(1), m_APInt(C)) && C->ult(W) && W % 8 == 0) {
      unsigned sh = unsigned(C->getZExtValue());
      unsigned q = sh / 8, r = sh % 8;
      Lanes l(n);
      for (unsigned j = 0; j < n; ++j) {
        if (BO.getOpcode() == Instruction::Shl) {
          if (j >= q && a.test(j - q))
            l.set(j);
          if (r && j >= q + 1 && a.test(j - q - 1))
            l.set(j);
        } else {
          if (j + q < n && a.test(j + q))
            l.set(j);
          if (r && j + q + 1 < n && a.test(j + q + 1))
            l.set(j);
          if (BO.getOpcode() == Instruction::AShr && j + q >= n - 1 && a.test(n - 1))
            l.set(j);
        }
      }
      setL(&BO, l);
      return;
    }
    setL(&BO, allLanes(n));
    return;
  }
  default:
    setL(&BO, allLanes(n));
    return;
  }
}

void Analyzer::transferCast(CastInst &CI) {
  Value *Src = CI.getOperand(0);
  Lanes s = L(Src);
  unsigned n = lanesOf(CI.getType());
  switch (CI.getOpcode()) {
  case Instruction::Trunc:
  case Instruction::ZExt:
  case Instruction::SExt: {
    if (!CI.getType()->isIntegerTy()) {
      setL(&CI, s.any() ? allLanes(n) : Lanes(n));
      return;
    }
    Lanes l(n);
    unsigned sn = s.size();
    unsigned srcBits = Src->getType()->getIntegerBitWidth();
    for (unsigned i = 0; i < n && i < sn; ++i)
      if (s.test(i))
        l.set(i);
    if (CI.getOpcode() == Instruction::SExt && sn && s.test(sn - 1))
      for (unsigned i = sn; i < n; ++i)
        l.set(i);
    (void)srcBits;
    setL(&CI, l);
    return;
  }
  case Instruction::PtrToInt:
  case Instruction::IntToPtr:
    // Rule 3: identity (a pointer is an i64).
    setL(&CI, s.any() ? allLanes(n) : Lanes(n));
    return;
  case Instruction::BitCast:
  case Instruction::AddrSpaceCast:
    // Rules 3, 26: a bitcast between vectors of one element count maps element to element (<2 x float> to <2 x i32>,
    // the spine lowers it per lane): a classical element stays classical.
    if (auto *SV = dyn_cast<FixedVectorType>(Src->getType()), *DV = dyn_cast<FixedVectorType>(CI.getType());
        SV && DV && SV->getNumElements() == DV->getNumElements()) {
      unsigned e = SV->getNumElements(), sp = unsigned(s.size()) / e, dp = n / e;
      Lanes l(n);
      for (unsigned k = 0; k < e; ++k)
        for (unsigned i = 0; i < sp; ++i)
          if (s.test(k * sp + i)) {
            for (unsigned j = 0; j < dp; ++j)
              l.set(k * dp + j);
            break;
          }
      setL(&CI, l);
      return;
    }
    if (lanesOf(Src->getType()) == n && CI.getType()->isPointerTy() == Src->getType()->isPointerTy()) {
      Lanes l = s;
      l.resize(n);
      // Bit reinterpretation between differently laid-out types smears.
      if (Src->getType()->isIntegerTy() && CI.getType()->isIntegerTy())
        setL(&CI, l);
      else
        setL(&CI, s.any() ? allLanes(n) : Lanes(n));
    } else {
      setL(&CI, s.any() ? allLanes(n) : Lanes(n));
    }
    return;
  default: // fp casts, int <-> fp
    setL(&CI, s.any() ? allLanes(n) : Lanes(n));
    return;
  }
}

void Analyzer::transferGEP(GetElementPtrInst &G) {
  if (!G.getType()->isPointerTy())
    internalError("taint: IR the pinned pipeline cannot emit (CR §0, rule 25): a vector getelementptr (a pointer vector)", &G);
  // Rule 3: tainted iff computed from a rail. A tainted pointer is one 64-bit address rail; nothing is decoded.
  Lanes l(lanesOf(G.getType()));
  bool q = L(G.getPointerOperand()).any();
  for (auto &Idx : G.indices())
    q = q || L(Idx.get()).any();
  if (q)
    l.set();
  setL(&G, l);
}


const Value *Analyzer::hostBase(const Value *p) {
  for (;;) {
    if (auto *G = dyn_cast<GEPOperator>(p)) {
      for (const Use &U : G->indices())
        if (L(U.get()).any())
          return nullptr;
      p = G->getPointerOperand();
      continue;
    }
    return p;
  }
}

const Value *Analyzer::hostObject(const Value *ptr) {
  const Value *b = hostBase(ptr);
  if (!b)
    return nullptr;
  if (auto *GV = dyn_cast<GlobalVariable>(b))
    return hostGlobal(*GV) ? b : nullptr;
  if (auto *AI = dyn_cast<AllocaInst>(b))
    return AI->getFunction() == cur->F && hostAlloca(AI) ? b : nullptr;
  return nullptr;
}

// Rule 23: an alloca whose every user is a recognised fenv call taking the alloca itself (lifetime and debug
// intrinsics aside) is host-resident, its quantum part carried as SSA values (82).
static bool confinedFenvObject(const AllocaInst &A) {
  bool any = false;
  for (const User *U : A.users()) {
    auto *CB = dyn_cast<CallBase>(U);
    if (!CB)
      return false;
    if (auto *II = dyn_cast<IntrinsicInst>(CB); II && (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II)))
      continue;
    const Function *G = CB->getCalledFunction();
    if (!G || !isFenvCall(G->getName()))
      return false;
    any = true;
  }
  return any;
}

FenvObject fenvObjectKindOf(const Value *ptr) {
  if (auto *A = dyn_cast<AllocaInst>(ptr); A && confinedFenvObject(*A))
    return FenvObject::Confined;
  if (isa<Constant>(ptr)) {
    auto *G = dyn_cast<GlobalVariable>(getUnderlyingObject(ptr));
    if (!G || G->isConstant())
      return FenvObject::Constant;
  }
  return FenvObject::Memory;
}

bool observableVolatile(const Value *ptr, function_ref<bool(const Value *)> tainted);
bool neverLoaded(const Value *ptr);

// Rule 20 (b): every transitive user of the alloca through getelementptrs with untainted indices.
bool Analyzer::hostUsersOk(const AllocaInst &A) {
  if (L(A.getArraySize()).any())
    return false;
  if (confinedFenvObject(A))
    return true;
  SmallVector<const Value *, 8> work{&A};
  SmallPtrSet<const Value *, 16> seen;
  while (!work.empty()) {
    const Value *V = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    for (const Use &Us : V->uses()) {
      const User *U = Us.getUser();
      if (auto *G = dyn_cast<GetElementPtrInst>(U)) {
        if (Us.getOperandNo() != GetElementPtrInst::getPointerOperandIndex())
          return false;
        for (const Use &Idx : G->indices())
          if (L(Idx.get()).any())
            return false;
        work.push_back(G);
        continue;
      }
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        return false;
      if (isa<ICmpInst>(I))
        continue;
      // Rule 24 (cq-6b2i1): an observable volatile access is a bus access, so the object is on the bus.
      if ((isa<LoadInst>(I) && cast<LoadInst>(I)->isVolatile()) || (isa<StoreInst>(I) && cast<StoreInst>(I)->isVolatile()))
        if (getLoadStorePointerOperand(I) == V && observableVolatile(V, ownTainted()))
          return false;
      if (isa<LoadInst>(I)) {
        if (quantumScope(I->getParent()))
          return false;
        continue;
      }
      if (auto *SI = dyn_cast<StoreInst>(I)) {
        // Rules 19, 24: a dead local's volatile store is nothing, so it demotes nothing.
        if (SI->getPointerOperand() == V && SI->isVolatile() && !observableVolatile(V, ownTainted()) && neverLoaded(V))
          continue;
        if (SI->getPointerOperand() != V || L(SI->getValueOperand()).any() || quantumScope(I->getParent()))
          return false;
        continue;
      }
      if (auto *MI = dyn_cast<MemIntrinsic>(I)) {
        if (L(MI->getLength()).any() || quantumScope(I->getParent()))
          return false;
        if (auto *MS = dyn_cast<MemSetInst>(MI)) {
          if (L(MS->getValue()).any())
            return false;
          continue;
        }
        auto *MT = cast<MemTransferInst>(MI);
        if (!hostObject(MT->getRawSource()) || !hostObject(MT->getRawDest()))
          return false;
        continue;
      }
      if (auto *II = dyn_cast<IntrinsicInst>(I); II && (II->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(II)))
        continue;
      return false;
    }
  }
  return true;
}

// The one monotone fixpoint with taint (rule 20): a failing user demotes the alloca, its loads become rails.
void Analyzer::demoteAllocas(SpecState &S) {
  for (const BasicBlock *BB : fn(S.F).rpo)
    for (const Instruction &I : *BB)
      if (auto *A = dyn_cast<AllocaInst>(&I); A && !S.demoted.count(A) && !hostUsersOk(*A)) {
        S.demoted.insert(A);
        localChanged = true;
      }
}

// Rule 24: a volatile access is unobservable when its pointer operand is, through getelementptrs with untainted
// indices, an alloca or an internal global whose every use is, through such getelementptrs, a load or a store through
// it; every other volatile access is observable.
bool observableVolatile(const Value *ptr, function_ref<bool(const Value *)> tainted) {
  const Value *b = ptr;
  while (auto *G = dyn_cast<GEPOperator>(b)) {
    for (const Use &Idx : G->indices())
      if (tainted(Idx.get()))
        return true;
    b = G->getPointerOperand();
  }
  auto *GV = dyn_cast<GlobalVariable>(b);
  if (!isa<AllocaInst>(b) && !(GV && GV->hasLocalLinkage()))
    return true;
  return !onlyAccessedThrough(*b, tainted);
}

// Rule 19, rule 24: nothing loads the object `ptr` points into. An unobservable volatile store into such an object (a dead
// local) is nothing: no bus store, no memory version change, no effect (169's FORCE_EVAL in ilogb; rule 23 gives that
// logb clone a twin).
bool neverLoaded(const Value *ptr) {
  const Value *obj = getUnderlyingObject(ptr, /*MaxLookup=*/0);
  // Rule 24 drops a dead *local*'s store (rule 19). A global outlives the function: its final value is memory the
  // program leaves behind (CR §6 item 1), so a store to it is rule 20's ordinary one (cq-1jvr6, musl signal's
  // __eintr_valid_flag).
  if (!isa<AllocaInst>(obj))
    return false;
  SmallVector<const Value *, 8> work{obj};
  SmallPtrSet<const Value *, 16> seen{obj};
  while (!work.empty()) {
    const Value *v = work.pop_back_val();
    for (const User *usr : v->users()) {
      if (isa<LoadInst>(usr))
        return false;
      if ((isa<GEPOperator>(usr) || isa<BitCastOperator>(usr) || isa<AddrSpaceCastOperator>(usr) || isa<PHINode>(usr) ||
           isa<SelectInst>(usr)) &&
          seen.insert(usr).second)
        work.push_back(usr);
    }
  }
  return true;
}

void Analyzer::transferLoad(LoadInst &LI) {
  unsigned n = lanesOf(LI.getType());
  const Value *ptr = LI.getPointerOperand();
  // Rule 3: every load is a bus load and its result a rail, except a load of a host-resident object with no quantum
  // predicate in scope (rule 20). An observable volatile load is a bus load whatever its object (cq-6b2i1).
  bool host = hostObject(ptr) && !quantumScope(LI.getParent()) &&
              !(LI.isVolatile() && observableVolatile(ptr, ownTainted()));
  if (!host)
    cur->busLoad = true;
  setL(&LI, host ? Lanes(n) : allLanes(n));
}

void Analyzer::transferStore(Instruction &I, Value *ptr, Value *val) {
  auto *SI = dyn_cast<StoreInst>(&I);
  bool observable = SI && SI->isVolatile() && observableVolatile(ptr, ownTainted());
  if (SI && !observable && hostObject(ptr) && !L(val).any() && !quantumScope(I.getParent()))
    return;   // a plain store into a host-resident object (rule 20)
  if (SI && !observable && SI->isVolatile() && neverLoaded(ptr))
    return;   // rules 19, 24: a dead local, nothing
  cur->writesOuter = true;   // a bus store (rule 5)
  cur->anyQuantum = true;
}

void Analyzer::transferMemIntrinsic(MemIntrinsic &MI) {
  // Rule 22, host-resident destination: the intrinsic stays (the alloca's user test decided).
  if (hostObject(MI.getRawDest()) && !quantumScope(MI.getParent()) && !L(MI.getLength()).any()) {
    if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
      if (!L(MS->getValue()).any())
        return;
    } else if (hostObject(cast<MemTransferInst>(&MI)->getRawSource())) {
      return;
    }
  }
  cur->writesOuter = true;
  cur->anyQuantum = true;
}

// ---------------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------------
// Calls.

std::optional<uint64_t> Analyzer::rangeBound(const Value *V) {
  if (!V->getType()->isIntegerTy())
    return std::nullopt;
  ConstantRange R = computeConstantRange(V, /*ForSigned=*/false, /*UseInstrInfo=*/true);
  // The known bits too (190: memcmp(.., x & 3)'s length is `zext nneg (x & 3) to i64`, a cast
  // computeConstantRange does not look through): both are LLVM's range facts of V.
  R = R.intersectWith(ConstantRange::fromKnownBits(computeKnownBits(V, st.M->getDataLayout()), /*IsSigned=*/false),
                      ConstantRange::Unsigned);
  if (R.isFullSet() || R.isWrappedSet())
    return std::nullopt;
  APInt hi = R.getUnsignedMax();
  if (hi.isMaxValue() || hi.getActiveBits() > 64)
    return std::nullopt;
  return hi.getZExtValue();
}




void Analyzer::lift(CallBase &CB, Function *G, ArrayRef<Value *> actualsIn, bool viaIntrinsic) {
  // Key of the callee specialization from the actuals' lanes (rule 18). A pointer actual is one scalar digit.
  std::vector<Lanes> formal;
  std::vector<Type *> tys;
  bool anyQ = false;
  // §1.4, rule 16: a variadic clone's formals are the fixed ones and the block (stored by the caller, the bus's); rule
  // 26: a byval actual is the caller's fresh copy, a classical ptr. Both forms are spelled by the grammar and are bus
  // stores of the caller, under the predicate like the call.
  bool plain = !G->isDeclaration() && !viaIntrinsic && (G->isVarArg() || llvm::any_of(G->args(), [](const Argument &A) {
                 return A.hasByValAttr();
               }));
  ArrayRef<Value *> actuals = actualsIn;
  if (G->isVarArg() && !G->isDeclaration() && actuals.size() > G->arg_size())
    actuals = actuals.take_front(G->arg_size());
  if (plain) {
    cur->writesOuter = true;
    cur->anyQuantum = true;
  }
  for (unsigned i = 0; i < actuals.size(); ++i) {
    Lanes l = L(actuals[i]);
    if (plain && i < G->arg_size() && G->getArg(i)->hasByValAttr())
      l.reset();
    formal.push_back(l);
    tys.push_back(actuals[i]->getType());
    anyQ = anyQ || l.any();
  }
  bool underQ = blockCT(CB.getParent()) || cur->ctl;
  // cq-1c5j: the second run takes the first run's final key of this call at once, when it covers what the
  // actuals give now (lanes only rise during the fixed point).
  if (!calleeMemo.empty()) {
    auto it = calleeMemo.find({cur->key, &CB, G});
    if (it != calleeMemo.end() && it->second.formal.size() == formal.size()) {
      const CalleeMemo &m = it->second;
      bool covers = true;
      for (unsigned i = 0; i < formal.size() && covers; ++i)
        covers = m.formal[i].size() == formal[i].size() && !formal[i].test(m.formal[i]);
      bool inPlace = !plain && !m.ctl && m.bounds.empty() &&
                     llvm::none_of(m.formal, [](const Lanes &l) { return l.any(); });
      if (covers && !inPlace) {
        SpecState *C = getSpec(G, m.formal, tys, m.ctl, false, m.bounds, {}, plain);
        recordCallee(CB, C);
        if (!CB.getType()->isVoidTy())
          setL(&CB, C->declared ? allLanes(lanesOf(CB.getType())) : C->ret);
        cur->anyQuantum = true;
        return;
      }
      if (covers)
        formal = m.formal;
    }
  }
  if (!anyQ && !underQ && !plain) {
    // Classical call: the in-place specialization of the callee (the function's own symbol, §1.4).
    std::vector<Lanes> z;
    for (Type *T : tys)
      z.push_back(Lanes(lanesOf(T)));
    SpecState *C = getSpec(G, z, tys, false, false, {});
    recordCallee(CB, C);
    if (!CB.getType()->isVoidTy())
      setL(&CB, C->ret);
    if (C->effectful || C->hasTheta || C->hasPhi)
      cur->hasEffect = cur->hasEffect || C->hasEffect;
    return;
  }
  // _ctl iff under a quantum predicate and the callee's body has a non-pure gate (rule 19). The
  // test reads the callee's specialization without the flag.
  bool ctl = false;
  if (underQ) {
    SpecState *probe = getSpec(G, formal, tys, false, false, {}, {}, plain);
    // Rule 19: ... or a call cycle through itself (rule 14: the one clone with its activation counter). §1.4 _ctl, rule 5:
    // a bus access under a quantum predicate is the _controlled form, a load included ("no bus access is hoisted or
    // speculated"), so a callee that loads takes the predicate. A measurement is no template either: rule 19's controlled
    // copy, so the register is not collapsed where the predicate is 0 (§1.4, rule 2).
    if (plain || probe->nonPure || probe->hasTheta || probe->hasPhi || probe->hasEffect || probe->writesOuter ||
        probe->measuresRail || probe->busLoadT || callsReach(G, G))
      ctl = true;
  }
  std::vector<uint64_t> bounds;
  std::vector<unsigned> boundFormals;
  for (unsigned i = 0; i < actuals.size(); ++i)
    if (actuals[i]->getType()->isIntegerTy() && formal[i].any())
      if (auto b = rangeBound(actuals[i])) {
        unsigned W = actuals[i]->getType()->getIntegerBitWidth();
        if (W > 1 && (W >= 64 || *b < ((uint64_t(1) << W) - 1))) {
          bounds.push_back(*b);
          boundFormals.push_back(i);
        }
      }
  // §1.4: one clone per function, mask and kind, whatever the recursion depth: a call on a cycle carries no bound (204).
  if (viaIntrinsic || callsReach(G, cur->F)) {
    bounds.clear();
    boundFormals.clear();
  }
  SpecState *C = getSpec(G, formal, tys, ctl, false, bounds, boundFormals, plain);
  recordCallee(CB, C);
  if (!CB.getType()->isVoidTy()) {
    Lanes r = C->ret;
    if (C->declared)
      r = allLanes(lanesOf(CB.getType()));
    setL(&CB, r);
  }
  cur->anyQuantum = true;
}

void Analyzer::declaredClone(CallBase &CB, Function *G, ArrayRef<Value *> actuals) { lift(CB, G, actuals, false); }

// Rule 16's stream calls: every <stdio.h> function, input and output alike, and the POSIX descriptor calls, except the
// string formatters (injected and lifted when the bundle has them).
static bool streamCall(StringRef n) {
  static const char *names[] = {
      "fopen",    "freopen",  "fclose",  "fflush",   "setbuf",   "setvbuf", "fprintf", "printf",  "vfprintf", "vprintf",
      "fscanf",   "scanf",    "vfscanf", "vscanf",   "fgetc",    "getc",    "getchar", "fgets",   "gets",     "fputc",
      "putc",     "putchar",  "fputs",   "puts",     "ungetc",   "fread",   "fwrite",  "fgetpos", "fseek",    "fsetpos",
      "ftell",    "rewind",   "clearerr","feof",     "ferror",   "perror",  "remove",  "rename",  "tmpfile",  "tmpnam",
      "open",     "close",    "read",    "write",    "lseek",    "getline", "getdelim","fdopen",  "fileno",   "popen",
      "pclose",   "fseeko",   "ftello",  "dprintf",  "vdprintf", "flockfile","funlockfile"};
  for (const char *x : names)
    if (n == x)
      return true;
  return false;
}

// <fenv.h> (C17 7.6) as rule 23 rail operations (eff-fenv), never a declared clone. Point-wise:
// fenvCur is the state before the call and becomes the state after it. A change of a fact by a
// quantum operand or under a quantum predicate makes it a rail (select(p, new, old) is one); a
// classical change outside quantum control sets it to what it writes when that is known.
void Analyzer::transferFenvCall(CallBase &CB, StringRef cname, ArrayRef<Value *> actuals,
                                unsigned rn) {
  using namespace fenvstate;
  bool q = false;
  for (Value *A : actuals)
    q = q || L(A).any();
  bool underQ = blockCT(CB.getParent()) || cur->ctl;
  bool rail = q || underQ;
  uint8_t before = fenvCur, now = fenvNow();
  bool resQ = false;
  // Rule 23: only a confined object's quantum part is SSA (these facts); a constant one has an empty part; any other
  // object holds the environment in its bytes: a save merges the part through the bus, a restore loads two fields
  // from the bus as the new flags rail and mode, and copies the object for its host call (bus stores).
  auto kindOf = [](Value *ptr) { return fenvObjectKindOf(ptr); };
  auto savedIn = [&](Value *ptr) {
    auto it = st.fenvSaved.find(ptr);
    return it == st.fenvSaved.end() ? uint8_t(0) : it->second;
  };
  auto saveTo = [&](Value *ptr, uint8_t bits) {
    if (kindOf(ptr) != FenvObject::Confined) {
      if (bits) {
        cur->writesOuter = true;
        cur->anyQuantum = true;
      }
      return;
    }
    uint8_t &x = st.fenvSaved[ptr];
    if ((x | bits) != x) {
      x |= bits;
      st.changed = true;
    }
  };
  auto restoreMemory = [&](Value *ptr) {
    if (kindOf(ptr) != FenvObject::Memory)
      return false;
    cur->writesOuter = true;
    cur->anyQuantum = true;
    return true;
  };
  auto bit = [](bool b) { return uint8_t(b ? 1 : 0); };
  if (cname == "fegetround") {
    resQ = now & 1;
  } else if (cname == "fesetround") {
    // MODE := r when r is a valid FE_* constant ((r & ~0xC00) == 0); an invalid r changes nothing,
    // a classical r of unknown validity may leave a rail in place.
    auto *c = actuals.empty() ? nullptr : dyn_cast<ConstantInt>(actuals[0]);
    if (rail)
      fenvAssign(0, 1);
    else if (c && (c->getZExtValue() & ~uint64_t(0xC00) & 0xffffffffu) == 0)
      fenvAssign(0, 0);
    else
      fenvAssign(0, nib(fenvCur, 0));
    resQ = q;
  } else if (cname == "feraiseexcept" || cname == "feclearexcept") {
    fenvAssign(1, rail ? 1 : nib(fenvCur, 1));
  } else if (cname == "fetestexcept") {
    resQ = q || (now & 2);
  } else if (cname == "fegetexceptflag") {
    saveTo(actuals[0], (now & 2) | (q ? 2 : 0));
  } else if (cname == "fesetexceptflag") {
    fenvAssign(1, restoreMemory(actuals[0]) || rail ? 1 : (nib(fenvCur, 1) | bit(savedIn(actuals[0]) & 2)));
  } else if (cname == "fegetenv" || cname == "feholdexcept") {
    saveTo(actuals[0], now | (q ? 3 : 0));
    if (cname == "feholdexcept")
      fenvAssign(1, bit(rail));
  } else if (cname == "fesetenv" || cname == "feupdateenv") {
    // fesetenv: the state := the object's saved part; feupdateenv: MODE := its mode, FLAGS := its
    // flags | FLAGS. An object never saved (FE_DFL_ENV) has an empty part.
    bool mem = restoreMemory(actuals[0]);
    uint8_t sv = savedIn(actuals[0]);
    fenvAssign(0, mem || rail ? 1 : bit(sv & 1));
    uint8_t f = bit(sv & 2);
    if (cname == "feupdateenv")
      f |= nib(fenvCur, 1);
    fenvAssign(1, mem || rail ? 1 : f);
  } else {
    // fegetexcept, feenableexcept, fedisableexcept: host calls, trapping is not modelled on rails
    // (eff-fenv); no environment fact changes.
    if (rn && q)
      setL(&CB, allLanes(rn));
    cur->anyQuantum = cur->anyQuantum || q;
    return;
  }
  fenvRecord(CB, before);
  if (rn && resQ)
    setL(&CB, allLanes(rn));
  cur->anyQuantum = cur->anyQuantum || q;
}

// The state after a call of defined callees (cur->callees): each callee's exit state composed with
// the state before the call, joined over the candidates. The callee's entry state joins this call's.
// Under a quantum predicate a callee that is not a _ctl clone still changes the environment only on
// the predicate's branch, so every fact it may change is a rail after the call.
void Analyzer::fenvAfterCall(CallBase &CB) {
  using namespace fenvstate;
  auto it = cur->callees.find(&CB);
  if (it == cur->callees.end() || it->second.empty())
    return;
  uint8_t before = fenvCur, E = fenvNow(), out = 0, writes = 0;
  bool underQ = blockCT(CB.getParent()) || cur->ctl;
  for (SpecState *C : it->second) {
    if ((C->fenvIn | E) != C->fenvIn) {
      C->fenvIn |= E;
      st.changed = true;
    }
    if (C->declared) {
      out |= before; // a declared clone (rule 27) is opaque: no rail operation
      continue;
    }
    uint8_t o = compose(C->fenvExit, before);
    for (unsigned k = 0; k < 2; ++k)
      if (underQ && !C->ctl && (C->fenvWrites & (1u << k)))
        o = withNib(o, k, nib(o, k) | 1);
    out |= o;
    writes |= C->fenvWrites;
  }
  if ((cur->fenvWrites | writes) != cur->fenvWrites) {
    cur->fenvWrites |= writes;
    st.changed = true;
  }
  fenvCur = out;
  if (writes || E)
    fenvRecord(CB, before);
}

void Analyzer::transferCall(CallBase &CB) {
  if (CB.isInlineAsm()) {
    for (const Use &A : CB.args())
      if (L(A.get()).any())
        unimplemented("taint: inline asm with a quantum operand (build step: rule 27 inline asm, waits for its "
                      "CQ_spec example)",
                      &CB);
    return;
  }
  Function *G = CB.getCalledFunction();
  SmallVector<Value *, 8> actuals(CB.arg_begin(), CB.arg_end());
  unsigned rn = lanesOf(CB.getType());
  if (!G) {
    // Rule 19: always a call of a table clone, resolved from the table at run time: which functions the pointer can
    // denote is never analysed. Every result is a handle, and the call is opaque to the caller: rule 19's _ctl test, a
    // memory version change (bus::versionChange), no twin for the function that makes it (bus::writesMemory).
    if (rn)
      setL(&CB, allLanes(rn));
    cur->anyQuantum = true;
    cur->hasEffect = true;
    return;
  }
  if (isTheta(G)) {
    setL(&CB, allLanes(rn));
    cur->hasTheta = true;
    cur->anyQuantum = true;
    return;
  }
  if (isMeasure(G)) {
    cur->hasMeasure = true;
    cur->measuresRail = cur->measuresRail || L(actuals[0]).any();
    // A measurement moved after a loop's trips (Plugin's measureAfterTrips) merges with the paths past it under a quantum choice: tainted too.
    if (blockCT(CB.getParent()) || cur->ctl || CB.getMetadata("cq.after.trips"))
      cur->taintedMeasure = true;   // rule 18: a measurement whose outcome is tainted; a classical-path one keeps the twin (rule 2)
    // Rule 19: inside a _ctl clone the measured rail is a controlled copy: the outcome is tainted, the rail is the value.
    if (cur->ctl && L(actuals[0]).any())
      setL(&CB, allLanes(rn));
    cur->anyQuantum = true;
    return;
  }
  if (isPhi(G)) {
    cur->hasPhi = true;
    cur->anyQuantum = true;
    return;
  }
  if (isInvertMarker(G)) {
    cur->anyQuantum = true;
    return;
  }
  // A program that spells a cqrt_/cq_template_ name itself gets what the link gives (CR §1.1, cq-oa67):
  // the call is analysed like any other call to that symbol.
  if (auto *MI = dyn_cast<MemIntrinsic>(&CB)) {
    transferMemIntrinsic(*MI);
    return;
  }
  if (G->isIntrinsic()) {
    Intrinsic::ID id = G->getIntrinsicID();
    switch (id) {
    case Intrinsic::lifetime_start:
    case Intrinsic::lifetime_end:
    case Intrinsic::assume:
    case Intrinsic::dbg_declare:
    case Intrinsic::dbg_value:
    case Intrinsic::dbg_label:
    case Intrinsic::experimental_noalias_scope_decl:
    case Intrinsic::invariant_start:
    case Intrinsic::invariant_end:
    case Intrinsic::vaend:
    case Intrinsic::stackrestore:
    case Intrinsic::donothing:
    case Intrinsic::trap:
    case Intrinsic::debugtrap:
    case Intrinsic::ubsantrap:
      if (id == Intrinsic::trap || id == Intrinsic::ubsantrap)
        cur->hasEffect = true;
      return;
    case Intrinsic::vastart:
    case Intrinsic::vacopy:
      // Rules 16, 22: bus stores into the va_list (bus-resident: a call argument demotes its alloca).
      cur->anyQuantum = true;
      cur->writesOuter = true;
      return;
    case Intrinsic::stacksave:
      setL(&CB, Lanes(rn));
      return;
    case Intrinsic::threadlocal_address:
      setL(&CB, L(actuals[0]));
      return;
    case Intrinsic::ptrmask: {
      Lanes l = L(actuals[0]);
      if (L(actuals[1]).any())
        l.set();
      setL(&CB, l);
      return;
    }
    default:
      break;
    }
    if (auto lib = libmNameOf(G)) {
      bool q = false;
      for (Value *A : actuals)
        q = q || L(A).any();
      if (q) {
        Function *Body = st.M->getFunction(*lib);
        if (Body && !Body->isDeclaration()) {
          lift(CB, Body, actuals, true);
          return;
        }
        if (llvm::is_contained(st.opts.listed, *lib)) {
          lift(CB, G, actuals, true);   // rule 27: named after the libm function
          return;
        }
        // Q5: no body after injection and on no root list: rule 16's effect entry of the libm name.
        if (cur->effectEntries.insert(&CB).second)
          st.changed = true;
        cur->hasEffect = true;
        cur->anyQuantum = true;
        if (rn && !CB.use_empty()) {
          setL(&CB, allLanes(rn));
          cur->readsEffect = true;
        }
        return;
      }
    }
    // Every other intrinsic is a template or a pure computation over its operands.
    bool q = false;
    for (Value *A : actuals)
      q = q || L(A).any();
    if (auto *CFP = dyn_cast<ConstrainedFPIntrinsic>(&CB)) {
      // Rule 23: an op rounding in the dynamic mode while MODE is a rail is quantum. An op that
      // raises makes FLAGS non-empty when it is quantum or runs under a quantum predicate (its bits
      // are then quantum); otherwise it raises into the host flags only.
      uint8_t before = fenvCur;
      std::optional<RoundingMode> rmode = CFP->getRoundingMode();
      if (rmode && *rmode == RoundingMode::Dynamic && (fenvNow() & 1))
        q = true;
      // Only fpexcept.strict raises observably (rule 23 ruling 2026-11-02): ignore and maytrap raise nothing.
      std::optional<fp::ExceptionBehavior> eb = CFP->getExceptionBehavior();
      if (eb && *eb == fp::ebStrict) {
        bool underQ = blockCT(CB.getParent()) || cur->ctl;
        fenvAssign(1, (q || underQ) ? 1 : fenvstate::nib(fenvCur, 1));
      }
      fenvRecord(CB, before);
    }
    if (id == Intrinsic::get_rounding) {
      // llvm.get.rounding reads the mode as fegetround does.
      q = q || (fenvNow() & 1);
      fenvRecord(CB, fenvCur);
    }
    if (id == Intrinsic::set_rounding) {
      // llvm.set.rounding writes the mode as fesetround does (LLVM's encoding: 0 to 3 are modes).
      uint8_t before = fenvCur;
      bool underQ = blockCT(CB.getParent()) || cur->ctl;
      auto *c = dyn_cast<ConstantInt>(actuals[0]);
      if (q || underQ)
        fenvAssign(0, 1);
      else if (c && c->getZExtValue() <= 3)
        fenvAssign(0, 0);
      else
        fenvAssign(0, fenvstate::nib(fenvCur, 0));
      fenvRecord(CB, before);
    }
    if (q && rn)
      setL(&CB, allLanes(rn));
    return;
  }
  // Allocation, deallocation (rule 16): heap objects.
  if (isAllocationFn(&CB, st.TLI.get())) {
    if (Value *Old = getReallocatedOperand(&CB)) {
      setL(&CB, L(Old));
      cur->anyQuantum = true;   // rule 16 realloc: __cq_alloc and the rule-22 copy
      return;
    }
    setL(&CB, Lanes(rn));
    cur->anyQuantum = true;   // __cq_alloc (rule 16)
    return;
  }
  if (getFreedOperand(&CB, st.TLI.get()))
    return;
  // setjmp and longjmp outside rule 24's pairing are host calls: a classical result, no gate and no tape entry
  // (abort_i1 under a quantum predicate); the pairing is rewritten before the final taint.
  if (CB.hasFnAttr(Attribute::ReturnsTwice))
    return;
  if (CB.doesNotReturn()) {
    if (!cur->hasNoreturn) {
      cur->hasNoreturn = true;
      st.changed = true;
    }
    if ((blockCT(CB.getParent()) || cur->ctl) && cur->aborts.insert(&CB).second)
      st.changed = true;   // rule 16: an abort event
    if (G->isDeclaration() && !blockCT(CB.getParent()) && !cur->ctl) {
      bool q = false;
      for (Value *A : actuals)
        q = q || L(A).any();
      if (q && cur->effectEntries.insert(&CB).second)   // rule 16: the effect entry of its name, then abort_i1
        st.changed = true;
    }
    return;
  }
  // Rule 16 Signal table: signal is the bus load of the cell and the bus store of the handler; raise loads the cell and
  // calls through the loaded address rail by rule 19. No handler is tracked.
  if (G->isDeclaration() && G->getName() == "signal" && actuals.size() == 2) {
    setL(&CB, allLanes(rn));
    cur->busLoad = true;
    cur->writesOuter = true;
    cur->anyQuantum = true;
    return;
  }
  if (G->isDeclaration() && G->getName() == "raise" && actuals.size() == 1) {
    if (rn && !CB.use_empty()) {
      setL(&CB, allLanes(rn));
      cur->readsEffect = true;
    }
    if (cur->effectEntries.insert(&CB).second)
      st.changed = true;
    cur->busLoad = true;
    cur->hasEffect = true;
    cur->anyQuantum = true;
    return;
  }
  // Rule 24: join and the mutexes are nothing (collapseThreads), whatever a pthread_t reads as.
  {
    StringRef pn = G->getName();
    if (pn.starts_with("\x01_"))
      pn = pn.drop_front(2);
    if (G->isDeclaration() && (pn == "pthread_join" || pn == "pthread_mutex_lock" || pn == "pthread_mutex_unlock" ||
                               pn == "pthread_mutex_trylock" || pn == "pthread_mutex_init" || pn == "pthread_mutex_destroy"))
      return;
  }
  if (G->getName() == "pthread_create" && actuals.size() == 4) {
    // Single-thread collapse (rule 24): a direct call of the start routine with its argument.
    if (auto *Start = dyn_cast<Function>(actuals[2]->stripPointerCasts()))
      if (!Start->isDeclaration()) {
        Value *arg[1] = {actuals[3]};
        lift(CB, Start, arg, false);
        // The call's own result (an int status) stays classical.
        return;
      }
  }
  if (!G->isDeclaration()) {
    lift(CB, G, actuals, false);
    return;
  }
  // A callee with no body (rule 16; a listed one is rule 27's, whatever its arguments).
  StringRef cname = G->getName();
  if (cname.starts_with("\x01_"))
    cname = cname.drop_front(2);
  if (isFenvCall(cname)) {
    transferFenvCall(CB, cname, actuals, rn);
    return;
  }
  if (llvm::is_contained(st.opts.listed, cname)) {
    declaredClone(CB, G, actuals);
    return;
  }
  bool qArg = false, ptrArg = false;
  for (Value *A : actuals) {
    qArg = qArg || L(A).any();
    ptrArg = ptrArg || A->getType()->isPtrOrPtrVectorTy();
  }
  bool qPred = blockCT(CB.getParent()) || cur->ctl;
  // Pure: with classical arguments under a quantum predicate it is executed unguarded and merged (rule 9).
  if (CB.doesNotAccessMemory() && CB.willReturn() && !qArg)
    return;
  // Ordinary host call: made as it stands.
  if (!qArg && !qPred && !(streamCall(cname) && ptrArg) && !eventPrecedes(CB))
    return;
  // Effect entry (a format entry for printf). Its result the program reads is the _<W> entry's rail, KEPT.
  if (cur->effectEntries.insert(&CB).second)
    st.changed = true;
  cur->hasEffect = true;
  cur->anyQuantum = true;
  if (rn && !CB.use_empty()) {
    setL(&CB, allLanes(rn));
    cur->readsEffect = true;
  }
}

// Rule 16: may a tape or abort event precede the call? One from which the call is reachable in its function's CFG, or
// its function is called after an event (propagateEvents).
bool Analyzer::eventPrecedes(const CallBase &CB) {
  // Rule 16: inside a table clone every function is called after an event, always: its caller is not in view.
  if (cur->table || st.calledAfter.count(cur->F))
    return true;
  auto hasEvent = [&](const CallBase &X) {
    if (cur->effectEntries.count(&X) || cur->aborts.count(&X))
      return true;
    auto it = cur->callees.find(&X);
    if (it != cur->callees.end())
      for (SpecState *C : it->second)
        if (C->hasEventT)
          return true;
    if (const Function *G = X.getCalledFunction(); G && G->isDeclaration() && llvm::is_contained(st.opts.listed, G->getName()))
      return true;   // a declared clone counts
    if (!X.getCalledFunction() && !X.isInlineAsm())
      return true;   // an indirect callee counts
    return false;
  };
  FnInfo &fi = fn(CB.getFunction());
  for (const BasicBlock *BB : fi.rpo)
    for (const Instruction &I : *BB)
      if (auto *X = dyn_cast<CallBase>(&I); X && X != &CB && hasEvent(*X) && isPotentiallyReachable(X, &CB, nullptr, fi.DT.get(), fi.LI.get()))
        return true;
  // A call of itself on a cycle: an entry of this very call precedes it on the next trip.
  return cur->effectEntries.count(&CB) != 0;
}

// Rule 16: the facts of the least fixpoint, per round: which specializations have an event (themselves or through a
// callee), whether the module has one, and which functions are called after one.
void Analyzer::propagateEvents() {
  bool any = false;
  for (auto &S : st.specs) {
    bool ev = S->hasEventT || !S->effectEntries.empty() || !S->aborts.empty();
    for (auto &[CB, v] : S->callees)
      for (SpecState *C : v)
        ev = ev || C->hasEventT;
    if (!S->declared)
      for (const BasicBlock &BB : *S->F)
        for (const Instruction &I : BB)
          if (auto *X = dyn_cast<CallBase>(&I)) {
            if (const Function *G = X->getCalledFunction()) {
              if (G->isDeclaration() && llvm::is_contained(st.opts.listed, G->getName()))
                ev = true;
            } else if (!X->isInlineAsm()) {
              ev = true;
            }
          }
    if (ev != S->hasEventT) {
      S->hasEventT = ev;
      st.changed = true;
    }
    any = any || (ev && !S->table);   // the module's events are its code's; a table clone's run only when dispatched
  }
  if (any && !st.moduleHasEvent) {
    st.moduleHasEvent = true;
    st.changed = true;
  }
  auto add = [&](const Function *F) {
    if (st.calledAfter.insert(F).second)
      st.changed = true;
  };
  // Inside a table clone every function is called after an event, always (rule 16; rulings3 H): the fact is the function's, so a
  // by-name callee of a table clone and what it reaches have it, event in the module or not.
  for (auto &S : st.specs) {
    if (S->declared || !(S->table || st.calledAfter.count(S->F)))
      continue;
    for (auto &[CB, v] : S->callees)
      for (SpecState *C : v)
        if (!C->declared)
          add(C->F);
  }
  if (!st.moduleHasEvent)
    return;
  for (Function &F : *st.M)
    if (!F.isDeclaration() && (!F.hasLocalLinkage() || F.hasAddressTaken()))
      add(&F);
  for (auto &S : st.specs) {
    if (S->declared)
      continue;
    SpecState *saved = cur;
    cur = S.get();
    for (auto &[CB, v] : S->callees)
      for (SpecState *C : v)
        if (!C->declared && (st.calledAfter.count(S->F) || eventPrecedes(*CB)))
          add(C->F);
    cur = saved;
  }
}

void Analyzer::transfer(Instruction &I) {
  unsigned n = lanesOf(I.getType());
  if (auto *BO = dyn_cast<BinaryOperator>(&I))
    return transferBinary(*BO);
  if (auto *CI = dyn_cast<CastInst>(&I))
    return transferCast(*CI);
  if (auto *SI = dyn_cast<SelectInst>(&I))
    return transferSelect(*SI);
  if (auto *G = dyn_cast<GetElementPtrInst>(&I))
    return transferGEP(*G);
  if (auto *LI = dyn_cast<LoadInst>(&I))
    return transferLoad(*LI);
  if (auto *SI = dyn_cast<StoreInst>(&I))
    return transferStore(I, SI->getPointerOperand(), SI->getValueOperand());
  if (auto *CB = dyn_cast<CallBase>(&I))
    return transferCall(*CB);
  if (auto *AI = dyn_cast<AllocaInst>(&I)) {
    setL(AI, Lanes(n));   // a pointer is classical (a rail size allocates K2, rule 16)
    if (!hostAlloca(AI))
      cur->anyQuantum = true;   // __cq_alloc (rules 16, 20)
    return;
  }
  if (isa<CmpInst>(&I) || isa<UnaryOperator>(&I) || isa<FreezeInst>(&I)) {
    bool q = false;
    for (const Use &U : I.operands())
      q = q || L(U.get()).any();
    if (auto *FI = dyn_cast<FreezeInst>(&I)) {
      setL(FI, L(FI->getOperand(0)));
      return;
    }
    if (auto *UO = dyn_cast<UnaryOperator>(&I)) {
      if (UO->getType()->isVectorTy()) {
        setL(UO, L(UO->getOperand(0)));
        return;
      }
    }
    if (q)
      setL(&I, allLanes(n));
    return;
  }
  if (auto *EV = dyn_cast<ExtractValueInst>(&I)) {
    Lanes a = L(EV->getAggregateOperand());
    unsigned off = laneOffset(EV->getAggregateOperand()->getType(), EV->getIndices());
    Lanes l(n);
    for (unsigned i = 0; i < n; ++i)
      if (a.test(off + i))
        l.set(i);
    setL(EV, l);
    // A pointer read out of an aggregate (a pointer compare-exchange's old value, an aggregate load
    // or call result): its provenance is not tracked through aggregates (cq-kuuf).
    return;
  }
  if (auto *IV = dyn_cast<InsertValueInst>(&I)) {
    Lanes a = L(IV->getAggregateOperand());
    Lanes v = L(IV->getInsertedValueOperand());
    unsigned off = laneOffset(IV->getType(), IV->getIndices());
    a.resize(n);
    for (unsigned i = 0; i < v.size(); ++i)
      a.reset(off + i);
    for (unsigned i = 0; i < v.size(); ++i)
      if (v.test(i))
        a.set(off + i);
    // Monotone: the previous result's lanes are kept by setL.
    setL(IV, a);
    return;
  }
  if (auto *EE = dyn_cast<ExtractElementInst>(&I)) {
    Lanes a = L(EE->getVectorOperand());
    if (auto *CIdx = dyn_cast<ConstantInt>(EE->getIndexOperand())) {
      unsigned per = n;
      unsigned off = unsigned(CIdx->getZExtValue()) * per;
      Lanes l(n);
      for (unsigned i = 0; i < n; ++i)
        if (off + i < a.size() && a.test(off + i))
          l.set(i);
      setL(EE, l);
    } else if (a.any() || L(EE->getIndexOperand()).any()) {
      setL(EE, allLanes(n));
    }
    return;
  }
  if (auto *IE = dyn_cast<InsertElementInst>(&I)) {
    Lanes a = L(IE->getOperand(0));
    Lanes v = L(IE->getOperand(1));
    a.resize(n);
    if (auto *CIdx = dyn_cast<ConstantInt>(IE->getOperand(2))) {
      unsigned per = v.size();
      unsigned off = unsigned(CIdx->getZExtValue()) * per;
      for (unsigned i = 0; i < per; ++i) {
        a.reset(off + i);
        if (v.test(i))
          a.set(off + i);
      }
      setL(IE, a);
    } else if (a.any() || v.any() || L(IE->getOperand(2)).any()) {
      setL(IE, allLanes(n));
    }
    return;
  }
  if (auto *SV = dyn_cast<ShuffleVectorInst>(&I)) {
    Lanes a = L(SV->getOperand(0)), b = L(SV->getOperand(1));
    auto *VT = cast<FixedVectorType>(SV->getOperand(0)->getType());
    unsigned per = lanesOf(VT->getElementType());
    unsigned nIn = VT->getNumElements();
    Lanes l(n);
    for (unsigned e = 0; e < SV->getShuffleMask().size(); ++e) {
      int m = SV->getMaskValue(e);
      if (m < 0)
        continue;
      const Lanes &src = unsigned(m) < nIn ? a : b;
      unsigned se = unsigned(m) < nIn ? unsigned(m) : unsigned(m) - nIn;
      for (unsigned k = 0; k < per; ++k)
        if (src.test(se * per + k))
          l.set(e * per + k);
    }
    setL(SV, l);
    return;
  }
  if (auto *VA = dyn_cast<VAArgInst>(&I)) {
    // A variadic clone is specialized per call-site arity (§1.4): va_arg reads the variadic actuals.
    bool q = false;
    for (unsigned i = cur->F->arg_size(); i < cur->formal.size(); ++i)
      q = q || cur->formal[i].any();
    if (q)
      setL(VA, allLanes(n));
    return;
  }
  if (auto *RMW = dyn_cast<AtomicRMWInst>(&I)) {
    transferStore(I, RMW->getPointerOperand(), RMW->getValOperand());
    setL(&I, allLanes(n));   // rule 4: a bus load, the templates, a bus store
    return;
  }
  if (auto *CX = dyn_cast<AtomicCmpXchgInst>(&I)) {
    transferStore(I, CX->getPointerOperand(), CX->getNewValOperand());
    setL(&I, allLanes(n));   // rule 4: a bus load, the templates, a bus store
    return;
  }
  if (isa<FenceInst>(&I) || isa<UnreachableInst>(&I) || isa<BranchInst>(&I) ||
      isa<SwitchInst>(&I) || isa<IndirectBrInst>(&I))
    return;
  if (auto *RI = dyn_cast<ReturnInst>(&I)) {
    if (Value *V = RI->getReturnValue()) {
      if (orInto(cur->ret, L(V)))
        st.changed = true;
      // Rule 19 (cq-stmvu): an own symbol's quantum integer result is ONE handle in the C return type, so every lane of it
      // reads that rail, also where the body leaves the lane classical (a small struct coerced to an integer, rule 26).
      if (cur->inPlace && V->getType()->isIntegerTy() && cur->ret.any() && orInto(cur->ret, allLanes(cur->ret.size())))
        st.changed = true;
    }
    return;
  }
  if (isa<PHINode>(&I))
    return;
  internalError("taint: IR the pinned pipeline cannot emit (CR §0, rule 25): an instruction C on x86-64 at -O1 never produces (invoke/landingpad/resume, va_arg, ...)", &I);
}

void Analyzer::analyze(SpecState &S) {
  cur = &S;
  if (S.declared) {
    // A declared clone: every result is a handle (rule 27).
    S.ret = allLanes(lanesOf(S.F->getReturnType()));
    S.fenvExit = fenvstate::kIdentity;
    S.analyzedOnce = true;
    S.hasEffect = true;
    return;
  }
  FnInfo &fi = fn(S.F);
  unsigned rounds = 0;
  do {
    localChanged = false;
    computeCDT(S);
    computeExitQ(S);
    demoteAllocas(S);
    // Loop-header phis made quantum by a tainted next-trip decision.
    SmallPtrSet<const PHINode *, 16> headerQ;
    for (const BasicBlock *BB : fi.rpo)
      loopHeaderRule(S, BB, headerQ);
    uint8_t exit = 0;
    for (const BasicBlock *BB : fi.rpo) {
      // Rule 23: the environment state entering the block, joined over its predecessors.
      fenvCur = BB->isEntryBlock() ? fenvstate::kIdentity : 0;
      for (const BasicBlock *Pr : predecessors(BB))
        fenvCur |= S.fenvOut.lookup(Pr);
      for (const Instruction &CI : *BB) {
        Instruction &I = const_cast<Instruction &>(CI);
        curUser = &I;
        if (auto *PN = dyn_cast<PHINode>(&I))
          transferPhi(*PN, headerQ);
        else
          transfer(I);
        curUser = nullptr;
        if (auto *CB = dyn_cast<CallBase>(&I))
          fenvAfterCall(*CB);
      }
      uint8_t &o = S.fenvOut[BB];
      if ((o | fenvCur) != o) {
        o |= fenvCur;
        localChanged = true;
      }
      if (isa<ReturnInst>(BB->getTerminator()))
        exit |= o;
    }
    if ((S.fenvExit | exit) != S.fenvExit) {
      S.fenvExit |= exit;
      st.changed = true;
    }
    // A value defined in a loop with a tainted exit and read after it is the select-merged carried
    // value (rule 14): L() reads it as quantum in any reader outside the loop (exitRead). The
    // reader's result is quantum too, also where V is a pointer or the reader reads it through
    // addresses computed after the loop (the load of an address evaluated per trip, 121), or the
    // reader's transfer does not pass operand lanes to its result (a call). A pointer is an integer (rule 21): a
    // pointer exit value and an address computed from it are rails too. Several returns chosen by a tainted branch
    // merge their values.
    for (const BasicBlock *BB : fi.rpo)
      for (const Loop *Lp = fi.LI->getLoopFor(BB); Lp; Lp = Lp->getParentLoop()) {
        if (!S.exitQ.count(Lp))
          continue;
        for (const Instruction &I : *BB) {
          if (I.getType()->isVoidTy() || (isa<PHINode>(&I) && headerQ.count(cast<PHINode>(&I))))
            continue;
          // Through addresses computed outside the loop to their non-pointer readers (a load of
          // the element at the exit index).
          SmallVector<const Instruction *, 8> work{&I};
          SmallPtrSet<const Instruction *, 8> seen;
          while (!work.empty()) {
            const Instruction *D = work.pop_back_val();
            for (const User *U : D->users())
              if (auto *UI = dyn_cast<Instruction>(U))
                if (!Lp->contains(UI) && !UI->getType()->isVoidTy()) {
                  if (!UI->getType()->isPointerTy())
                    setL(UI, allLanes(lanesOf(UI->getType())));
                  else if (seen.insert(UI).second)
                    work.push_back(UI);
                }
          }
        }
      }
    SmallVector<const ReturnInst *, 4> rets;
    for (const BasicBlock *BB : fi.rpo)
      if (auto *RI = dyn_cast<ReturnInst>(BB->getTerminator()))
        if (RI->getReturnValue())
          rets.push_back(RI);
    if (rets.size() > 1) {
      bool differ = false, chosen = false;
      for (const ReturnInst *RI : rets) {
        if (RI->getReturnValue() != rets[0]->getReturnValue())
          differ = true;
        if (blockCT(RI->getParent()))
          chosen = true;
      }
      if (differ && chosen && orInto(S.ret, allLanes(S.ret.size())))
        st.changed = true;
    }
    if (localChanged)
      st.changed = true;
    if (++rounds > 1000)
      internalError("taint: per-function fixed point does not converge");
  } while (localChanged);
  if (!S.taintedTerm.empty())
    S.anyQuantum = true;
  for (const BasicBlock *BB : fi.rpo)
    for (const Instruction &I : *BB)
      if (auto *CB = dyn_cast<CallBase>(&I); CB && countsAsCall(*CB))
        S.hasCall = true;
  for (auto &[V, l] : S.lanes)
    if (l.any())
      S.anyQuantum = true;
  S.analyzedOnce = true;
  cur = nullptr;
}

// ---------------------------------------------------------------------------------------------
// Driver.

void Analyzer::run() {
  Module &M = *st.M;
  st.DL = &M.getDataLayout();
  st.TLII = std::make_unique<TargetLibraryInfoImpl>(Triple(M.getTargetTriple()));
  st.TLI = std::make_unique<TargetLibraryInfo>(*st.TLII);
  solve();
  computeReachable();
  bool stale = false;
  for (auto &S : st.specs)
    stale = stale || !S->reachable;
  if (stale) {
    // cq-1c5j: the second run (CalleeMemo). Each reachable specialization's final direct callees.
    for (auto &S : st.specs) {
      if (!S->reachable)
        continue;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          calleeMemo[{S->key, CB, C->F}] = CalleeMemo{C->formal, C->ctl, C->bounds};
    }
    resetAnalysis();
    solve();
  }
  finish();
}

void Analyzer::resetAnalysis() {
  st.specs.clear();
  st.byKey.clear();
  st.changed = false;
  st.calledAfter.clear();
  st.moduleHasEvent = false;
  st.fenvSaved.clear();
  cur = nullptr;
  localChanged = false;
  fenvCur = 0;
}

void Analyzer::computeReachable() {
  SmallVector<SpecState *, 32> work;
  for (auto &S : st.specs) {
    S->reachable = false;
    if (S->inPlace && (!S->F->hasLocalLinkage() || S->F->hasAddressTaken()))
      work.push_back(S.get());
    else if (S->isRoot)
      work.push_back(S.get());
  }
  while (!work.empty()) {
    SpecState *S = work.pop_back_val();
    if (S->reachable)
      continue;
    S->reachable = true;
    for (auto &[CB, v] : S->callees)
      for (SpecState *C : v)
        work.push_back(C);
  }
}

void Analyzer::solve() {
  Module &M = *st.M;

  // Roots: in-place specializations of every externally reachable function; library-build roots.
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    if (!F.hasLocalLinkage() || F.hasAddressTaken()) {
      std::vector<Lanes> z;
      std::vector<Type *> tys;
      for (Argument &A : F.args()) {
        z.push_back(Lanes(lanesOf(A.getType())));
        tys.push_back(A.getType());
      }
      SpecState *R = getSpec(&F, z, tys, false, false, {});
      R->reachable = R->isRoot = true;
      // Rule 19, §1.4: every address-taken or externally visible function has its row: _t and _t_ctl, every scalar
      // formal a handle (a variadic function's block stays the classical digit 0).
      std::vector<Lanes> all;
      for (Argument &A : F.args())
        all.push_back(allLanes(lanesOf(A.getType())));
      for (bool ctl : {false, true}) {
        SpecState *TC = getSpec(&F, all, tys, ctl, false, {}, {}, F.isVarArg(), /*table=*/true);
        TC->reachable = TC->isRoot = true;
      }
    }
  }
  for (const abi::CloneSpec &R : st.opts.roots) {
    Function *F = M.getFunction(R.fn);
    if (!F || F->isDeclaration())
      unimplemented("taint: -cq-roots names a function with no body in the module (build step: rule 27's "
                    "library-build mode, not reached): " + R.fn);
    if (R.mask.size() != F->arg_size())
      unimplemented("taint: -cq-roots mask over aggregate or pointer formals (build step: rule 27's library-build "
                    "mode, not reached): " + R.fn);
    std::vector<Lanes> z;
    std::vector<Type *> tys;
    for (Argument &A : F->args()) {
      Lanes l(lanesOf(A.getType()));
      if (R.mask[A.getArgNo()] == '1')
        l.set();
      z.push_back(l);
      tys.push_back(A.getType());
    }
    SpecState *RS = getSpec(F, z, tys, R.ctl, R.pure, R.bounds);
    RS->reachable = RS->isRoot = true;
  }

  // cq-e0tq (cq-1c5j): a round analyzes the specializations the program reaches over the current callee maps,
  // and those the round itself creates. A specialization a rising key left behind (its caller now calls the
  // one of the risen key, which covers it) keeps the facts it already contributed but adds none: analyzed
  // every round, the specializations left behind on the way cost as much as the reached ones (musl
  // strftime's and the scanf family's hundreds of memcpy/sn_write/__fwritex keys). A round ends the fixed
  // point only when every specialization reached after it was analyzed in it.
  auto reached = [&]() {
    DenseSet<SpecState *> live;
    SmallVector<SpecState *, 32> work;
    for (auto &S : st.specs)
      if (S->isRoot || (S->inPlace && (!S->F->hasLocalLinkage() || S->F->hasAddressTaken())))
        work.push_back(S.get());
    while (!work.empty()) {
      SpecState *S = work.pop_back_val();
      if (!live.insert(S).second)
        continue;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          work.push_back(C);
    }
    return live;
  };
  unsigned iter = 0;
  do {
    st.changed = false;
    DenseSet<SpecState *> live = reached(), done;
    size_t before = st.specs.size();
    for (size_t i = 0; i < st.specs.size(); ++i) {
      SpecState &S = *st.specs[i];
      if (i < before && !live.count(&S))
        continue;
      done.insert(&S);
      analyze(S);
    }
    for (SpecState *S : reached())
      if (!done.count(S))
        st.changed = true;
    propagateEvents();
    // Transitive gate facts (rule 19's non-pure test, effects).
    for (auto &S : st.specs) {
      bool bl = S->busLoad, nt = S->taintedMeasure || S->readsEffect;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v) {
          bl = bl || C->busLoadT;
          nt = nt || C->noTwinT;
        }
      if (bl != S->busLoadT || nt != S->noTwinT) {
        S->busLoadT = bl;
        S->noTwinT = nt;
        st.changed = true;
      }
      // A table clone's measured copy is a rail it mints (cq-t2jj2): per trip, no finite list holds them.
      bool pt = mintsPerTrip(S->F) || (S->table && !S->ctl && S->nonPure && measuresInLoop(S->F));
      for (auto &[CB, v] : S->callees)
        if (!CB->getType()->isVoidTy())
          for (SpecState *C : v)
            pt = pt || C->rotatesPerTrip;
      if (pt != S->rotatesPerTrip) {
        S->rotatesPerTrip = pt;
        st.changed = true;
      }
      // Rule 19: "a tape or abort event". A noreturn call on a classical path of the callee counts: under the caller's predicate
      // it is abort_i1 of that predicate, the host call would end programs C lets continue.
      bool np = S->hasTheta || S->hasPhi || S->hasEffect || S->writesOuter || S->measuresRail || S->hasNoreturn;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          np = np || C->nonPure;
      if (np != S->nonPure) {
        S->nonPure = np;
        st.changed = true;
      }
      // Rule 18: the twin "repeats no phase and no tape or abort event": an abort arm recomputes through _pure.
      bool ef = S->hasPhi || S->hasEffect || !S->aborts.empty() || !S->effectEntries.empty();
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          ef = ef || C->effectful;
      if (ef != S->effectful) {
        S->effectful = ef;
        st.changed = true;
      }
    }
    if (++iter > 200)
      internalError("taint: module fixed point does not converge");
  } while (st.changed);
}


// Integer formal split into fields by its unpacking (an ABI-coerced struct, 159): a trunc to C bits
// and an lshr by C, with C a multiple of 8. Returns field bit boundaries.
static SmallVector<unsigned, 4> intFields(const Argument *A) {
  unsigned W = A->getType()->getIntegerBitWidth();
  SmallVector<unsigned, 4> cuts;
  bool other = false;
  SmallVector<unsigned, 4> truncs, shifts;
  for (const User *U : A->users()) {
    using namespace PatternMatch;
    const APInt *C;
    if (auto *T = dyn_cast<TruncInst>(U))
      truncs.push_back(T->getType()->getIntegerBitWidth());
    else if (match(U, m_LShr(m_Specific(A), m_APInt(C))) || match(U, m_AShr(m_Specific(A), m_APInt(C))))
      shifts.push_back(unsigned(C->getZExtValue()));
    else
      other = true;
  }
  if (!other)
    for (unsigned s : shifts)
      if (s % 8 == 0 && s > 0 && s < W && llvm::is_contained(truncs, s))
        cuts.push_back(s);
  llvm::sort(cuts);
  cuts.erase(std::unique(cuts.begin(), cuts.end()), cuts.end());
  SmallVector<unsigned, 4> b{0};
  b.append(cuts.begin(), cuts.end());
  b.push_back(W);
  return b;
}

std::string Analyzer::buildMask(SpecState &S) {
  std::string m;
  for (unsigned i = 0; i < S.formal.size(); ++i) {
    Type *T = S.formalTy[i];
    const Lanes &l = S.formal[i];
    if (T->isPointerTy()) {
      m += l.any() ? '1' : '0';   // CR §1.4: one digit, the pointer's own taint (rule 3: one 64-bit rail)
      continue;
    }
    if (auto *IT = dyn_cast<IntegerType>(T)) {
      if (i < S.F->arg_size() && !S.declared && !S.table) {
        auto b = intFields(S.F->getArg(i));
        for (unsigned k = 0; k + 1 < b.size(); ++k) {
          bool q = false;
          for (unsigned lane = b[k] / 8; lane < (b[k + 1] + 7) / 8 && lane < l.size(); ++lane)
            q = q || l.test(lane);
          m += q ? '1' : '0';
        }
        continue;
      }
      (void)IT;
      m += l.any() ? '1' : '0';
      continue;
    }
    if (T->isAggregateType() || T->isVectorTy()) {
      // One digit per scalar leaf.
      std::function<void(Type *, unsigned &)> walk = [&](Type *U, unsigned &lane) {
        if (auto *ST = dyn_cast<StructType>(U)) {
          for (Type *E : ST->elements())
            walk(E, lane);
        } else if (auto *AT = dyn_cast<ArrayType>(U)) {
          for (uint64_t k = 0; k < AT->getNumElements(); ++k)
            walk(AT->getElementType(), lane);
        } else if (auto *VT = dyn_cast<FixedVectorType>(U)) {
          for (unsigned k = 0; k < VT->getNumElements(); ++k)
            walk(VT->getElementType(), lane);
        } else {
          unsigned nl = lanesOf(U);
          bool q = false;
          for (unsigned k = 0; k < nl; ++k)
            q = q || l.test(lane + k);
          lane += nl;
          m += q ? '1' : '0';
        }
      };
      unsigned lane = 0;
      walk(T, lane);
      continue;
    }
    m += l.any() ? '1' : '0';
  }
  if (S.plain && S.F->isVarArg())
    m += '0';   // §1.4: the block, a classical ptr
  return m;
}

void Analyzer::finish() {
  // cq-0ia: after the fixed point, every non-void instruction of an analysed body has an answer.
  // One setL never touched is classical (all lanes 0), so a missing key means only "created after
  // computeTaint", which stays an internal error (cq-5k5). Unreachable blocks are covered too: they
  // are not in fi.rpo, and nothing in them depends on a cq_theta result.
  for (auto &S : st.specs) {
    if (S->declared)
      continue;
    for (const BasicBlock &BB : *S->F)
      for (const Instruction &I : BB)
        if (!I.getType()->isVoidTy())
          S->lanes.try_emplace(&I, Lanes(lanesOf(I.getType())));
  }
  // Reachability from the roots over the final callee maps.
  SmallVector<SpecState *, 32> work;
  for (auto &S : st.specs) {
    bool root = S->reachable;
    S->reachable = false;
    if (root)
      work.push_back(S.get());
  }
  // Roots are recomputed: in-place specs of externally reachable functions and option roots.
  for (auto &S : st.specs)
    if (S->inPlace && (!S->F->hasLocalLinkage() || S->F->hasAddressTaken()))
      work.push_back(S.get());
  while (!work.empty()) {
    SpecState *S = work.pop_back_val();
    if (S->reachable)
      continue;
    S->reachable = true;
    for (auto &[CB, v] : S->callees)
      for (SpecState *C : v)
        work.push_back(C);
  }
  // §5: what only a table clone reaches (a corpus example omits it for a function whose address it never takes).
  {
    for (auto &S : st.specs)
      S->rowOnly = true;
    SmallVector<SpecState *, 32> code;
    for (auto &S : st.specs)
      if (S->reachable && !S->table && (S->isRoot || (S->inPlace && (!S->F->hasLocalLinkage() || S->F->hasAddressTaken()))))
        code.push_back(S.get());
    while (!code.empty()) {
      SpecState *S = code.pop_back_val();
      if (!S->rowOnly)
        continue;
      S->rowOnly = false;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          code.push_back(C);
    }
    for (auto &S : st.specs)
      if (S->table && S->F->hasAddressTaken())
        S->rowOnly = false;
  }
  // Twins: a call whose quantum result is consumed by something other than a measurement (rule 18);
  // a declared clone always has one (rule 27). To a fixpoint: an own symbol that returns a callee's result hands the rail on, but
  // when its own twin runs (through its _pure clone) that result is its garbage, so the callee needs a twin too.
  for (bool grew = true; grew;) {
  grew = false;
  for (auto &S : st.specs) {
    if (!S->reachable)
      continue;
    if (S->table)
      S->needsTwin = true;   // §1.4: a table clone's twin always exists
    for (auto &[CB, v] : S->callees) {
      if (CB->getType()->isVoidTy())
        continue;
      auto it = S->lanes.find(CB);
      if (it == S->lanes.end() || it->second.none())
        continue;
      bool other = false;
      for (const User *U : CB->users()) {
        // Rules 2, 18, 19: only a measurement of the result itself leaves no twin to run. A table or _ctl clone and a value
        // measured on some classical paths measure a copy, and the result is then uncomputed like any other (lowerMeasure).
        if (auto *UC = dyn_cast<CallBase>(U))
          if (isMeasure(UC->getCalledFunction()) && !S->table && !S->ctl &&
              measuredOnEveryPath(
                  [&](const Value *x) {
                    if (auto *A = dyn_cast<Argument>(x))
                      return S->formal[A->getArgNo()].any();
                    auto l = S->lanes.find(x);
                    return l != S->lanes.end() && l->second.any();
                  },
                  CB))
            continue;
        if (isa<ReturnInst>(U) && S->inPlace && !S->needsTwin)
          continue;
        other = true;
      }
      // cq-s2zz (rule 19): through a quantum function pointer every candidate's result is an arm of a select
      // merge, garbage whatever consumes the merge.
      if (!CB->getCalledFunction())
        if (auto c = S->lanes.find(CB->getCalledOperand()); c != S->lanes.end() && c->second.any())
          other = true;
      if (other)
        for (SpecState *C : v)
          if (!C->needsTwin) {
            C->needsTwin = true;
            grew = true;
          }
    }
  }
  }
  // _pure: what a twin recomputes through when the callee has effects (119).
  std::vector<SpecState *> pureNeeded;
  {
    SmallPtrSet<SpecState *, 16> seen;
    SmallVector<SpecState *, 16> w;
    for (auto &S : st.specs) {
      // Rule 18: a function that measures or reads the result rail of an effect entry has no twin, so nothing recomputes
      // through a _pure of it, whatever consumes its result (its effect's result rail exists only in the clone).
      if (S->noTwinT || S->rotatesPerTrip)
        continue;
      // cq-s2zz (rule 18): an effectful clone whose own result needs its twin recomputes through its _pure.
      // Rule 18, §1.4: an own symbol's twin always recomputes through its _pure clone (the own symbol returns its rail).
      if (S->reachable && S->needsTwin && (S->effectful || S->inPlace) && !S->declared)
        w.push_back(S.get());
      if (S->reachable && S->needsTwin && !S->declared)
        for (auto &[CB, v] : S->callees)
          for (SpecState *C : v)
            if (C->effectful && !C->declared)
              w.push_back(C);
    }
    while (!w.empty()) {
      SpecState *C = w.pop_back_val();
      if (!seen.insert(C).second)
        continue;
      pureNeeded.push_back(C);
      for (auto &[CB, v] : C->callees)
        for (SpecState *D : v)
          if (D->effectful && !D->declared)
            w.push_back(D);
    }
  }
  // Publish.
  for (auto &S : st.specs)
    if (S->reachable)
      S->mask = buildMask(*S);
  auto publish = [&](SpecState *S, bool pure) {
    Specialization P;
    P.F = S->F;
    P.mask = S->mask;
    P.ctl = S->ctl;
    P.pure = pure;
    P.bounds = S->bounds;
    P.boundFormals = S->boundFormals;
    P.plain = S->plain;
    P.table = S->table;
    st.published.push_back(P);
    st.publishedState.push_back(S);
  };
  for (auto &S : st.specs) {
    if (!S->reachable)
      continue;
    if (S->table) {
      publish(S.get(), false);
      st.cloned.insert(S->F);   // the own symbol stays what Q2 says
      continue;
    }
    if (S->inPlace) {
      // Q2 (rulings): F is its own lowering iff it has no bus access, no cq_* call and no call (rule 19).
      bool tainted = S->anyQuantum || S->hasCall;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          if (!C->inPlace)
            tainted = true;
      if (!tainted)
        continue;
    }
    publish(S.get(), false);
    st.tainted.insert(S->F);
    st.cloned.insert(S->F);
  }
  for (SpecState *S : pureNeeded)
    if (S->reachable)
      publish(S, true);
}

} // namespace cq::taintimpl

// =============================================================================================
// Public interface.

namespace cq {
using namespace taintimpl;

// CR rule 2, spine::measuredOnEveryPath: taint asks it before TaintInfo is published (rule 18, its twins).
bool measuredOnEveryPath(function_ref<bool(const Value *)> isQuantum, const Value *v, const Instruction *also) {
  auto strip = [](const Value *v) {
    while (auto *f = dyn_cast<FreezeInst>(v))
      v = f->getOperand(0);
    return v;
  };
  const Value *root = strip(v);
  if (!isa<Argument>(root) && !isa<Instruction>(root))
    return true;
  const Function &F = *(also ? also->getFunction()
                             : isa<Argument>(root) ? cast<Argument>(root)->getParent()
                                                   : cast<Instruction>(root)->getFunction());
  SmallPtrSet<const BasicBlock *, 8> mblocks;
  for (const Instruction &I : instructions(F))
    if (auto *c = dyn_cast<CallInst>(&I); c && c->getCalledFunction() &&
                                          c->getCalledFunction()->getName().starts_with("cq_measure") &&
                                          c->arg_size() == 1 && strip(c->getArgOperand(0)) == root)
      mblocks.insert(I.getParent());
  if (also)
    mblocks.insert(also->getParent());
  // A value read from memory names a rail stored before it (rules 20, 21): its paths begin at the entry.
  const auto *defI = isa<LoadInst>(root) || isa<AtomicRMWInst>(root) || isa<AtomicCmpXchgInst>(root) ||
                             (isa<ExtractValueInst>(root) && isa<AtomicCmpXchgInst>(cast<ExtractValueInst>(root)->getAggregateOperand()))
                         ? nullptr
                         : dyn_cast<Instruction>(root);
  const BasicBlock *D = defI ? defI->getParent() : &F.getEntryBlock();
  // A measurement after the definition in its own block covers every path.
  if (mblocks.count(D))
    for (const Instruction *I = defI ? defI->getNextNode() : &D->front(); I; I = I->getNextNode())
      if (auto *c = dyn_cast<CallInst>(I); c && c->getCalledFunction() &&
                                           c->getCalledFunction()->getName().starts_with("cq_measure") &&
                                           c->arg_size() == 1 && strip(c->getArgOperand(0)) == root)
        return true;
  if (also && also->getParent() == D && (!defI || defI->comesBefore(also)))
    return true;
  PostDominatorTree PDT(const_cast<Function &>(F));
  auto quantumBranch = [&](const BasicBlock *b) {
    const Instruction *t = b->getTerminator();
    if (auto *br = dyn_cast<BranchInst>(t); br && br->isConditional())
      return isQuantum(br->getCondition());
    if (auto *sw = dyn_cast<SwitchInst>(t))
      return isQuantum(sw->getCondition());
    if (auto *ib = dyn_cast<IndirectBrInst>(t))
      return isQuantum(ib->getAddress());   // rule 13: a switch on the address
    return false;
  };
  // Walk the classical choices from the end of D; a block holding a measurement ends the path (measured);
  // reaching D again starts a new instance (its paths are this walk's); a return reached ends it unmeasured.
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work;
  auto push = [&](const BasicBlock *b) {
    if (b != D && seen.insert(b).second)
      work.push_back(b);
  };
  auto next = [&](const BasicBlock *b) -> bool {   // false: an unmeasured return
    if (isa<ReturnInst>(b->getTerminator()))
      return false;
    if (!quantumBranch(b)) {
      for (const BasicBlock *s : successors(b))
        push(s);
      return true;
    }
    // The region of a quantum branch, up to its post-dominator: every block of it runs on this path.
    const BasicBlock *J = PDT.getNode(b) && PDT.getNode(b)->getIDom() ? PDT.getNode(b)->getIDom()->getBlock() : nullptr;
    SmallPtrSet<const BasicBlock *, 16> reg;
    SmallVector<const BasicBlock *, 16> w(succ_begin(b), succ_end(b));
    bool measured = false, ret = false;
    while (!w.empty()) {
      const BasicBlock *x = w.pop_back_val();
      if (x == J || x == b || !reg.insert(x).second)
        continue;
      measured = measured || mblocks.count(x);
      ret = ret || isa<ReturnInst>(x->getTerminator());
      for (const BasicBlock *s : successors(x))
        w.push_back(s);
    }
    if (measured)
      return true;
    if (ret)
      return false;
    if (J)
      push(J);
    return true;
  };
  if (!next(D))
    return false;
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    if (mblocks.count(b))
      continue;
    if (!next(b))
      return false;
  }
  return true;
}

bool Specialization::isEntry() const {
  if (!F || F->isDeclaration() || ctl || pure || plain || table || !bounds.empty())
    return false;
  return mask.find('1') == std::string::npos;
}

bool Specialization::wholeIntResult() const {
  if (!F || F->isDeclaration() || ctl || plain || table || !bounds.empty())
    return false;
  return mask.find('1') == std::string::npos;
}

namespace {
template <class P> const ImplState &needImpl(const P &p) {
  if (!p)
    internalError("taint: TaintInfo used before computeTaint");
  return *p;
}

SpecState *stateOf(const ImplState &I, const Specialization &S) {
  for (size_t k = 0; k < I.published.size(); ++k)
    if (&I.published[k] == &S)
      return I.publishedState[k];
  internalError("taint: not a specialization of this TaintInfo");
}

const Lanes &lanesOrDie(const SpecState &SS, const llvm::Value *V) {
  auto it = SS.lanes.find(V);
  if (it == SS.lanes.end())
    internalError("taint: no taint answer for this value (cq-5k5)", V);
  return it->second;
}

Lanes lanesOfValue(const ImplState &I, const SpecState &SS, const llvm::Value *V) {
  if (isa<Constant>(V) || isa<BasicBlock>(V) || isa<MetadataAsValue>(V) || isa<InlineAsm>(V))
    return Lanes();
  if (auto *A = dyn_cast<Argument>(V)) {
    if (A->getParent() != SS.F)
      internalError("taint: argument of another function", V);
    return SS.formal[A->getArgNo()];
  }
  if (auto *Ins = dyn_cast<Instruction>(V)) {
    if (Ins->getFunction() != SS.F)
      internalError("taint: value of another function", V);
    if (Ins->getType()->isVoidTy())
      return Lanes();
    return lanesOrDie(SS, V);
  }
  internalError("taint: no taint answer for this value", V);
}
} // namespace

FenvObject fenvObjectKind(const llvm::Value *ptr) { return taintimpl::fenvObjectKindOf(ptr); }

bool TaintInfo::isQuantum(const llvm::Value *V, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  return lanesOfValue(I, *stateOf(I, S), V).any();
}

llvm::SmallVector<bool, 4> TaintInfo::fieldMask(const llvm::Value *V, const Specialization &S) const {
  // One entry per scalar leaf of V's type (an aggregate's fields, a vector's lanes; a pointer is one leaf, rule 3).
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, S);
  Lanes l = lanesOfValue(I, *SS, V);
  llvm::SmallVector<bool, 4> out;
  std::function<void(llvm::Type *, unsigned &)> walk = [&](llvm::Type *T, unsigned &lane) {
    if (auto *ST = dyn_cast<llvm::StructType>(T)) {
      for (llvm::Type *E : ST->elements())
        walk(E, lane);
    } else if (auto *AT = dyn_cast<llvm::ArrayType>(T)) {
      for (uint64_t k = 0; k < AT->getNumElements(); ++k)
        walk(AT->getElementType(), lane);
    } else if (auto *VT = dyn_cast<llvm::FixedVectorType>(T)) {
      for (unsigned k = 0; k < VT->getNumElements(); ++k)
        walk(VT->getElementType(), lane);
    } else {
      unsigned n = 0;
      if (auto *IT = dyn_cast<llvm::IntegerType>(T))
        n = std::max(1u, (IT->getBitWidth() + 7) / 8);
      else
        n = 1;
      bool q = false;
      for (unsigned k = 0; k < n; ++k)
        q = q || (lane + k < l.size() && l.test(lane + k));
      lane += n;
      out.push_back(q);
    }
  };
  unsigned lane = 0;
  if (!V->getType()->isVoidTy())
    walk(V->getType(), lane);
  return out;
}

bool TaintInfo::isTainted(const llvm::Function &F) const {
  return needImpl(impl).tainted.count(&F) > 0;
}

bool TaintInfo::hasClone(const llvm::Function &F) const { return needImpl(impl).cloned.count(&F) != 0; }

bool TaintInfo::controlTainted(const llvm::BasicBlock *BB, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, S);
  if (BB->getParent() != SS->F)
    internalError("taint: block of another function", BB);
  auto it = SS->cdt.find(BB);
  if (it == SS->cdt.end()) {
    // Blocks with no control-dependence parent (entry, post-dominating joins) are recorded only
    // when they have one; any block of the analysed function is answerable.
    return false;
  }
  return !it->second.empty();
}

llvm::ArrayRef<Specialization> TaintInfo::specializations() const { return needImpl(impl).published; }

const Specialization *TaintInfo::calleeSpecialization(const llvm::CallBase &CB,
                                                      const Specialization &caller) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, caller);
  auto it = SS->callees.find(&CB);
  if (it == SS->callees.end() || it->second.empty())
    return nullptr;
  if (it->second.size() > 1)
    internalError("taint: calleeSpecialization of an indirect call with several candidates", &CB);
  SpecState *C = it->second.front();
  bool wantPure = caller.pure && C->effectful;
  for (size_t k = 0; k < I.published.size(); ++k)
    if (I.publishedState[k] == C && I.published[k].pure == wantPure)
      return &I.published[k];
  if (C->inPlace)
    return nullptr; // an untainted callee: an ordinary call of the original
  internalError("taint: callee specialization not published", &CB);
}

llvm::SmallVector<std::pair<llvm::Function *, const Specialization *>, 4>
TaintInfo::calleeCandidates(const llvm::CallBase &CB, const Specialization &caller) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, caller);
  llvm::SmallVector<std::pair<llvm::Function *, const Specialization *>, 4> out;
  auto it = SS->callees.find(&CB);
  if (it == SS->callees.end())
    return out;
  for (SpecState *C : it->second) {
    bool wantPure = caller.pure && C->effectful;
    const Specialization *found = nullptr;
    for (size_t k = 0; k < I.published.size() && !found; ++k)
      if (I.publishedState[k] == C && I.published[k].pure == wantPure)
        found = &I.published[k];
    if (!found && !C->inPlace)
      internalError("taint: candidate specialization not published", &CB);
    out.push_back({C->F, found});
  }
  return out;
}

bool TaintInfo::resultQuantum(const Specialization &S, unsigned field) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, S);
  if (SS->table)
    return true;   // §1.4: every scalar result a handle (a classical result as a seed rail)
  llvm::Type *RT = SS->F->getReturnType();
  // Fields: an aggregate's scalar leaves; an integer packed from narrower fields (159) by its
  // zext/shl/or-disjoint pattern; otherwise the whole value.
  std::vector<std::pair<unsigned, unsigned>> ranges; // lane ranges
  if (RT->isAggregateType() || RT->isVectorTy()) {
    // The packing cut of each integer leaf, at the insertvalue each return puts there last (or
    // disjoint (shl (zext X), C), (zext Y), C a whole number of bytes).
    std::vector<std::vector<unsigned>> leafCut;
    std::vector<unsigned> leafLanes;
    {
      std::function<void(llvm::Type *, std::vector<llvm::Type *> &)> leavesOf = [&](llvm::Type *T,
                                                                                  std::vector<llvm::Type *> &o) {
        if (auto *ST = dyn_cast<llvm::StructType>(T)) {
          for (llvm::Type *E : ST->elements())
            leavesOf(E, o);
        } else if (auto *AT = dyn_cast<llvm::ArrayType>(T)) {
          for (uint64_t k = 0; k < AT->getNumElements(); ++k)
            leavesOf(AT->getElementType(), o);
        } else if (auto *VT = dyn_cast<llvm::FixedVectorType>(T)) {
          for (unsigned k = 0; k < VT->getNumElements(); ++k)
            o.push_back(VT->getElementType());
        } else {
          o.push_back(T);
        }
      };
      std::vector<llvm::Type *> leaves;
      leavesOf(RT, leaves);
      leafCut.resize(leaves.size());
      auto leafIndex = [&](llvm::ArrayRef<unsigned> idx) {
        llvm::Type *T = RT;
        unsigned first = 0;
        for (unsigned i : idx) {
          for (unsigned j = 0; j < i; ++j) {
            std::vector<llvm::Type *> l;
            leavesOf(T->isStructTy() ? T->getStructElementType(j) : T->getArrayElementType(), l);
            first += unsigned(l.size());
          }
          T = T->isStructTy() ? T->getStructElementType(i) : T->getArrayElementType();
        }
        return first;
      };
      if (RT->isStructTy() || RT->isArrayTy())
        for (llvm::BasicBlock &BB : *SS->F)
          if (auto *RI = dyn_cast<llvm::ReturnInst>(BB.getTerminator()))
            if (llvm::Value *V = RI->getReturnValue()) {
              std::vector<bool> seen(leaves.size(), false);
              for (llvm::Value *v = V; auto *IV = dyn_cast<llvm::InsertValueInst>(v); v = IV->getAggregateOperand()) {
                llvm::Value *X = IV->getInsertedValueOperand();
                unsigned k = leafIndex(IV->getIndices());
                if (!X->getType()->isIntegerTy() || k >= leaves.size() || seen[k])
                  continue;
                seen[k] = true;
                using namespace llvm::PatternMatch;
                llvm::Value *A, *B;
                const llvm::APInt *C;
                if ((match(X, m_DisjointOr(m_Shl(m_ZExt(m_Value(A)), m_APInt(C)), m_ZExt(m_Value(B)))) ||
                     match(X, m_DisjointOr(m_ZExt(m_Value(B)), m_Shl(m_ZExt(m_Value(A)), m_APInt(C))))) &&
                    C->getZExtValue() % 8 == 0 && C->getZExtValue() > 0 &&
                    C->getZExtValue() < X->getType()->getIntegerBitWidth()) {
                  // cq-jkq8 (rule 26): the fields are the union of the returns' packings (one rail per
                  // field of every packing a return makes; a return packing coarser splits its value).
                  unsigned c = unsigned(C->getZExtValue());
                  if (std::find(leafCut[k].begin(), leafCut[k].end(), c) == leafCut[k].end()) {
                    leafCut[k].push_back(c);
                    std::sort(leafCut[k].begin(), leafCut[k].end());
                  }
                }
              }
            }
    }
    std::function<void(llvm::Type *, unsigned &)> walk = [&](llvm::Type *T, unsigned &lane) {
      if (auto *ST = dyn_cast<llvm::StructType>(T)) {
        for (llvm::Type *E : ST->elements())
          walk(E, lane);
      } else if (auto *AT = dyn_cast<llvm::ArrayType>(T)) {
        for (uint64_t k = 0; k < AT->getNumElements(); ++k)
          walk(AT->getElementType(), lane);
      } else if (auto *VT = dyn_cast<llvm::FixedVectorType>(T)) {
        for (unsigned k = 0; k < VT->getNumElements(); ++k)
          walk(VT->getElementType(), lane);
      } else {
        unsigned n = T->isIntegerTy() ? std::max(1u, (T->getIntegerBitWidth() + 7) / 8) : 1;
        // cq-0umd (166, rule 26): an integer leaf the returns pack from fields (the coerced inner
        // struct of { i64, double }) is one field per packed field, as for a packed integer result.
        unsigned leaf = unsigned(leafLanes.size());
        leafLanes.push_back(lane);
        unsigned lo = 0;
        if (leaf < leafCut.size())
          for (unsigned c : leafCut[leaf]) {
            ranges.push_back({lane + lo / 8, lane + c / 8});
            lo = c;
          }
        ranges.push_back({lane + lo / 8, lane + n});
        lane += n;
      }
    };
    unsigned lane = 0;
    walk(RT, lane);
  } else if (RT->isIntegerTy()) {
    unsigned W = RT->getIntegerBitWidth();
    std::vector<unsigned> cuts;
    for (llvm::BasicBlock &BB : *SS->F)
      if (auto *RI = dyn_cast<llvm::ReturnInst>(BB.getTerminator()))
        if (llvm::Value *V = RI->getReturnValue()) {
          using namespace llvm::PatternMatch;
          llvm::Value *X, *Y;
          const llvm::APInt *C;
          if (match(V, m_DisjointOr(m_Shl(m_ZExt(m_Value(X)), m_APInt(C)), m_ZExt(m_Value(Y)))) ||
              match(V, m_DisjointOr(m_ZExt(m_Value(Y)), m_Shl(m_ZExt(m_Value(X)), m_APInt(C)))))
            if (C->getZExtValue() % 8 == 0 && C->getZExtValue() > 0 && C->getZExtValue() < W &&
                std::find(cuts.begin(), cuts.end(), unsigned(C->getZExtValue())) == cuts.end()) {
              cuts.push_back(unsigned(C->getZExtValue()));   // cq-jkq8: the union over the returns
              std::sort(cuts.begin(), cuts.end());
            }
        }
    unsigned lo = 0;
    for (unsigned c : cuts) {
      ranges.push_back({lo / 8, c / 8});
      lo = c;
    }
    ranges.push_back({lo / 8, std::max(1u, (W + 7) / 8)});
  } else if (!RT->isVoidTy()) {
    ranges.push_back({0, std::max(1u, unsigned(SS->ret.size()))});
  }
  if (field >= ranges.size())
    internalError("taint: resultQuantum field out of range");
  for (unsigned k = ranges[field].first; k < ranges[field].second; ++k)
    if (k < SS->ret.size() && SS->ret.test(k))
      return true;
  return false;
}

namespace {
// One getelementptr-with-untainted-indices step of rule 20's walk, as a query after the fixed point.
const llvm::Value *walkHostBase(const ImplState &I, const SpecState &SS, const llvm::Value *p) {
  for (;;) {
    if (auto *G = dyn_cast<llvm::GEPOperator>(p)) {
      for (const llvm::Use &U : G->indices())
        if (!isa<llvm::Constant>(U.get()) && lanesOfValue(I, SS, U.get()).any())
          return nullptr;
      p = G->getPointerOperand();
      continue;
    }
    return p;
  }
}
} // namespace

bool TaintInfo::hostResident(const llvm::Value *obj, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  const SpecState *SS = stateOf(I, S);
  if (auto *GV = dyn_cast<llvm::GlobalVariable>(obj))
    return I.hostGlobals.count(GV);
  if (auto *AI = dyn_cast<llvm::AllocaInst>(obj))
    return AI->getFunction() == SS->F && !SS->demoted.count(AI);
  return false;
}

bool TaintInfo::observableVolatile(const llvm::Instruction &access, const Specialization &S) const {
  const SpecState *SS = stateOf(needImpl(impl), S);
  auto it = SS->volObservable.find(&access);
  return it == SS->volObservable.end() || it->second;
}

bool TaintInfo::neverLoaded(const llvm::Value *ptr) { return taintimpl::neverLoaded(ptr); }

bool TaintInfo::deadVolatileStore(const llvm::Instruction &I) const {
  auto *SI = dyn_cast<llvm::StoreInst>(&I);
  if (!SI || !SI->isVolatile() || !taintimpl::neverLoaded(SI->getPointerOperand()) ||
      taintimpl::observableVolatile(SI->getPointerOperand(), [](const llvm::Value *) { return false; }))
    return false;
  for (const Specialization &S : specializations())
    if (S.F == SI->getFunction() && observableVolatile(I, S))
      return false;
  return true;
}

const llvm::Value *TaintInfo::hostObjectOf(const llvm::Value *p, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  const SpecState *SS = stateOf(I, S);
  if (!p->getType()->isPointerTy())
    return nullptr;
  const llvm::Value *base = walkHostBase(I, *SS, p);
  return base && hostResident(base, S) ? base : nullptr;
}

const llvm::Value *TaintInfo::hostObjectOf(const llvm::Instruction &access, const Specialization &S) const {
  const llvm::Value *p = nullptr;
  if (auto *LI = dyn_cast<llvm::LoadInst>(&access))
    p = LI->getPointerOperand();
  else if (auto *SI = dyn_cast<llvm::StoreInst>(&access))
    p = SI->getPointerOperand();
  else if (auto *MI = dyn_cast<llvm::MemIntrinsic>(&access))
    p = MI->getRawDest();
  else if (auto *CB = dyn_cast<llvm::CallBase>(&access))
    p = CB->arg_size() ? CB->getArgOperand(0) : nullptr;   // rule 23: a recognised fenv call taking the object itself
  return p ? hostObjectOf(p, S) : nullptr;
}

bool TaintInfo::afterEvent(const llvm::CallBase &CB, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  const SpecState *SS = stateOf(I, S);
  return SS->effectEntries.count(&CB) || I.calledAfter.count(SS->F);
}

bool TaintInfo::isEffectEntry(const llvm::CallBase &CB, const Specialization &S) const {
  return stateOf(needImpl(impl), S)->effectEntries.count(&CB) != 0;
}

bool TaintInfo::listedRoot(const llvm::Function &F) const {
  if (!F.isDeclaration())
    return false;
  llvm::StringRef n = F.getName();
  if (n.starts_with("\x01_"))
    n = n.drop_front(2);
  return llvm::is_contained(needImpl(impl).opts.listed, n);
}

bool TaintInfo::loadsBus(const Specialization &S) const { return stateOf(needImpl(impl), S)->busLoadT; }

bool TaintInfo::noTwinByEffects(const Specialization &S) const {
  const SpecState *SS = stateOf(needImpl(impl), S);
  return SS->noTwinT || SS->rotatesPerTrip;
}

bool TaintInfo::needsTwin(const Specialization &S) const { return stateOf(needImpl(impl), S)->needsTwin; }

bool TaintInfo::needsCtl(const llvm::Function &F) const {
  const ImplState &I = needImpl(impl);
  for (size_t k = 0; k < I.published.size(); ++k)
    if (I.published[k].F == &F && I.publishedState[k]->nonPure)
      return true;
  return false;
}

void TaintInfo::print(llvm::raw_ostream &os) const {
  const ImplState &I = needImpl(impl);
  auto specName = [&](size_t k) {
    const Specialization &P = I.published[k];
    SpecState *SS = I.publishedState[k];
    if (P.isEntry())
      return ("@" + P.F->getName()).str();
    std::string fnName = P.F->getName().str();
    if (auto lib = libmNameOf(P.F))
      fnName = *lib;
    abi::CloneSpec C;
    C.fn = fnName;
    C.mask = P.mask;
    C.bounds = P.bounds;
    C.ctl = P.ctl;
    C.pure = P.pure;
    C.table = P.table;
    if (P.F->isDeclaration()) {
      // Rule 27: the declared clone is the table clone, every scalar actual a handle.
      C.mask = std::string(P.mask.size(), '1');
      C.table = true;
    }
    std::string n = abi::name(C);
    (void)SS;
    return n;
  };
  for (size_t k = 0; k < I.published.size(); ++k) {
    const Specialization &P = I.published[k];
    os << "cq-taint: spec " << specName(k) << " fn=@" << P.F->getName() << " mask=" << P.mask
       << " entry=" << P.isEntry() << " declared=" << P.F->isDeclaration()
       << " rowonly=" << I.publishedState[k]->rowOnly << "\n";
  }
  // Rule 23 (cq-pu8b): the environment state before and after every instruction that reads or
  // changes it, per specialization (MODE 'M' when the mode is a rail, FLAGS 'F' when the flags rail
  // is not empty, '-' otherwise), and whether the instruction's result is quantum.
  auto envStr = [](uint8_t c) {
    std::string r = (c & 1) ? "M" : "-";
    r += (c & 2) ? "F" : "-";
    return r;
  };
  for (size_t k = 0; k < I.published.size(); ++k) {
    SpecState *SS = I.publishedState[k];
    if (SS->declared || SS->fenvAt.empty())
      continue;
    os << "cq-taint: fenv " << specName(k) << " entry=" << envStr(SS->fenvIn)
       << " exit=" << envStr(fenvstate::eval(SS->fenvExit, SS->fenvIn))
       << " writes=" << envStr(SS->fenvWrites) << "\n";
    for (const llvm::BasicBlock &BB : *SS->F)
      for (const llvm::Instruction &Ins : BB) {
        auto it = SS->fenvAt.find(&Ins);
        if (it == SS->fenvAt.end())
          continue;
        auto lit = SS->lanes.find(&Ins);
        bool q = lit != SS->lanes.end() && lit->second.any();
        std::string text;
        llvm::raw_string_ostream ts(text);
        Ins.print(ts);
        llvm::StringRef t = llvm::StringRef(text).trim();
        os << "cq-taint: fenv " << specName(k) << "   "
           << envStr(fenvstate::eval(it->second.first, SS->fenvIn)) << " -> "
           << envStr(fenvstate::eval(it->second.second, SS->fenvIn)) << " q=" << q << "  " << t
           << "\n";
      }
  }
  if (getenv("CQ_TAINT_DEBUG"))
    for (size_t k = 0; k < I.published.size(); ++k) {
      SpecState *SS = I.publishedState[k];
      os << "  debug " << specName(k) << " key=" << SS->key << "\n";
      if (SS->declared)
        continue;
      for (const llvm::BasicBlock &BB : *SS->F) {
        auto cit = SS->cdt.find(&BB);
        if (cit != SS->cdt.end() && !cit->second.empty())
          os << "    ct block " << (BB.hasName() ? BB.getName() : "") << " "
             << &BB << "\n";
        for (const llvm::Instruction &Ins : BB) {
          auto it = SS->lanes.find(&Ins);
          if (it != SS->lanes.end() && it->second.any())
            os << "    q[" << lanesStr(it->second) << "] " << Ins << "\n";
        }
      }
    }
  for (const llvm::Function &F : *I.M)
    if (!F.isDeclaration())
      os << "cq-taint: function @" << F.getName() << " tainted=" << (I.tainted.count(&F) ? 1 : 0)
         << "\n";
}


TaintInfo computeTaint(llvm::Module &M, const TaintOptions &opts) {
  TaintInfo T;
  T.impl = std::make_shared<TaintInfo::Impl>();
  T.impl->M = &M;
  T.impl->opts = opts;
  taintimpl::Analyzer A(*T.impl);
  A.run();
  // The answers that read a global's uses, taken now: the module the pass then builds beside the bodies uses them too.
  for (const llvm::GlobalVariable &GV : M.globals())
    if (taintimpl::hostGlobal(GV))
      T.impl->hostGlobals.insert(&GV);
  for (auto &SS : T.impl->specs) {
    if (!SS->F || SS->F->isDeclaration())
      continue;
    auto tainted = [&](const llvm::Value *v) {
      auto *In = dyn_cast<llvm::Instruction>(v);
      auto *Ar = dyn_cast<llvm::Argument>(v);
      if ((In && In->getFunction() != SS->F) || (Ar && Ar->getParent() != SS->F))
        return false;
      return lanesOfValue(*T.impl, *SS, v).any();
    };
    for (const llvm::BasicBlock &BB : *SS->F)
      for (const llvm::Instruction &X : BB) {
        const llvm::LoadInst *LI = dyn_cast<llvm::LoadInst>(&X);
        const llvm::StoreInst *St = dyn_cast<llvm::StoreInst>(&X);
        if ((LI && LI->isVolatile()) || (St && St->isVolatile()))
          SS->volObservable[&X] = taintimpl::observableVolatile(llvm::getLoadStorePointerOperand(&X), tainted);
      }
  }
  return T;
}
} // namespace cq
