// Module taint (cq-w0-taint): rule 3 forward taint, rule 18 specializations, rule 20 memory
// classification, rule 21 provenance, A1 control dependence. See TaintImpl.h for the lattice.
//
// computeTaint builds one fresh Impl and iterates the whole module to a fixed point:
//   1. every defined function that is externally visible or address-taken gets its in-place
//      specialization (the all-classical one, rewritten in place when it is tainted); -cq-roots add
//      library-build roots;
//   2. each specialization is analysed: lanes of every SSA value, control dependence on tainted
//      terminators, memory effects on the module's objects, and the callee specialization of every
//      call (a new key creates a new specialization);
//   3. repeat until nothing changes (lanes, objects, keys only grow);
//   4. reachability from the roots, twins and _pure variants, masks, names, the published list.
// No state outlives the call: computeTaint is safe to call twice on one module (cq-5k5, option a).
#include "TaintImpl.h"

#include <algorithm>
#include <numeric>
#include <set>

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/MemoryBuiltins.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/InlineAsm.h"
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

uint64_t gcd64(uint64_t a, uint64_t b) { return std::gcd(a, b); }

uint64_t absDiff(int64_t a, int64_t b) {
  return a > b ? uint64_t(a) - uint64_t(b) : uint64_t(b) - uint64_t(a);
}

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

void sortUnique(SmallVectorImpl<unsigned> &v) {
  llvm::sort(v);
  v.erase(std::unique(v.begin(), v.end()), v.end());
}

} // namespace

std::optional<int64_t> PtrInfo::mod(uint64_t stride) const {
  if (!init || top || stride == 0)
    return std::nullopt;
  if (g % stride != 0)
    return std::nullopt;
  int64_t s = int64_t(stride);
  return ((c % s) + s) % s;
}

bool PtrInfo::join(const PtrInfo &o) {
  if (!o.init)
    return false;
  if (!init) {
    *this = o;
    return true;
  }
  PtrInfo before = *this;
  SmallVector<unsigned, 4> u(sites.begin(), sites.end());
  u.append(o.sites.begin(), o.sites.end());
  sortUnique(u);
  sites.assign(u.begin(), u.end());
  top = top || o.top;
  if (!top) {
    g = gcd64(gcd64(g, o.g), absDiff(c, o.c));
  }
  return before.sites != sites || before.top != top || before.g != g || before.c != c;
}

bool PtrInfo::sameOffset(const PtrInfo &o) const {
  auto a = exact(), b = o.exact();
  return a && b && *a == *b;
}

bool Object::cellHandle(std::optional<int64_t> off, uint64_t size) const {
  if (qram || anyHandle)
    return true;
  if (!off)
    return !handleCells.empty();
  for (const Range &r : handleCells)
    if (r.off < *off + int64_t(size ? size : 1) && *off < r.off + int64_t(r.size ? r.size : 1))
      return true;
  return false;
}

namespace {

bool overlapsAny(const std::vector<Range> &rs, std::optional<int64_t> off, uint64_t size, bool any) {
  if (any)
    return true;
  if (!off)
    return !rs.empty();
  for (const Range &r : rs)
    if (r.off < *off + int64_t(size ? size : 1) && *off < r.off + int64_t(r.size ? r.size : 1))
      return true;
  return false;
}

bool addRange(std::vector<Range> &rs, int64_t off, uint64_t size) {
  for (const Range &r : rs)
    if (r.off == off && r.size == size)
      return false;
  rs.push_back({off, size});
  return true;
}

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
  if (!F || !F->isIntrinsic())
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
  // CR §1.4, rules 3, 20 (95, 109; cq-prvy): the variadic actuals' save area and va_list copies.
  void transferVaStart(CallBase &CB);
  void transferVaCopy(CallBase &CB);

  // Sites and objects.
  unsigned siteFor(const Value *V, SiteKind k, const Function *owner);
  void splitSite(unsigned s, uint64_t stride, StructType *ST);
  SmallVector<ObjectId, 4> objectsAt(unsigned site, const PtrInfo &p);
  SmallVector<ObjectId, 4> objectsOf(const PtrInfo &p);
  void touchObject() { st.changed = true; }
  // cq-n58p: escaped addresses (ImplState::escaped).
  void escape(const PtrInfo &p) {
    PtrInfo e;
    e.init = true;
    e.top = true;
    for (unsigned s : p.sites)
      if (!llvm::is_contained(st.escaped.sites, s))
        e.sites.push_back(s);
    if (!e.sites.empty() && st.escaped.join(e))
      touchObject();
  }
  void escapeConstants(const Constant *C);
  // The pointer a lost-provenance read in F may hold: any escaped site that may be live in F (an alloca
  // only when its function is F or may be on the stack below F), at an unknown offset; an unknown
  // object named by V when there is none.
  PtrInfo escapedFor(const Value *V, const Function *F);
  bool hasIndirectCall = false, hasReturnsTwice = false;
  // cq-erjd: a store of F that cannot reach a load of F in the CFG cannot reach it in another
  // activation either: F runs at most once per run, or the object is F's own alloca and F never
  // recurses. Otherwise every store of the object reaches the load.
  bool storeOrderHolds(const Function *F, const Site &site);
  std::map<const Function *, int> runOnceMemo; // 0 in progress, 1 yes, 2 no
  bool runOnce(const Function *F);
  bool mayRecurse(const Function *F) {
    return F->hasAddressTaken() || callsReach(F, F);
  }

  // Specializations.
  SpecState *getSpec(Function *F, std::vector<Lanes> formal, std::vector<Type *> tys,
                     std::vector<std::string> cells, bool ctl, bool pure, unsigned depth,
                     std::vector<uint64_t> bounds, std::vector<unsigned> boundFormals = {});
  void analyze(SpecState &S);

  // Per-value access within cur.
  //
  // Rule 14 exit reads (cq-1v3i): a value defined in a loop whose next trip is decided by a tainted
  // terminator is, when read outside that loop, the exit value merged over the quantum exit trip,
  // so the read is quantum whatever the instruction reading it (phi, select, store, call actual,
  // return, branch condition). L(V) applies this to the instruction whose operands are being read
  // (curUser). Two exceptions keep 121: a pointer V, and a reader that computes an address (pointer
  // type), are evaluated per trip in the exit block under that trip's exit predicate, so they stay
  // classical-offset; the reader's non-pointer users are made quantum by the post-loop rule in
  // analyze().
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
  PtrInfo P(const Value *V);
  bool setL(const Value *V, const Lanes &l);
  bool setP(const Value *V, const PtrInfo &p);

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
  void transferLoad(Instruction &I, Value *ptr, Type *T);
  void transferStore(Instruction &I, Value *ptr, Value *val, Type *T);
  void transferMemIntrinsic(MemIntrinsic &MI);
  void transferCall(CallBase &CB);
  void lift(CallBase &CB, Function *G, ArrayRef<Value *> actuals, bool viaIntrinsic);
  void declaredClone(CallBase &CB, Function *G, ArrayRef<Value *> actuals);
  SmallVector<SpecState *, 4> *collect = nullptr; // indirect call: gather every candidate
  // cq-s2zz (CR rule 19): a call through a quantum function pointer (a QROM of callee tags): every candidate
  // runs under its quantum predicate tag == k, so a candidate with a non-pure gate is its _ctl clone.
  bool candidateUnderQ = false;
  // cq-1c5j (CR rules 18, 20): a call's callee key rises with its actuals' lanes during the fixed point, and a
  // specialization reached on the way (or a non-ctl probe) keeps contributing facts (stores into the caller's
  // objects, its own formals' provenance) although no final call reaches it. The analysis therefore runs a
  // second time from nothing, each call taking at once the key the first run ended with (CalleeMemo): only
  // the specializations the program reaches contribute.
  struct CalleeMemo { std::vector<Lanes> formal; std::vector<std::string> cells; bool ctl; std::vector<uint64_t> bounds; };
  std::map<std::tuple<std::string, const CallBase *, const Function *>, CalleeMemo> calleeMemo;
  void solve();
  void computeReachable();
  void resetAnalysis();
  void recordCallee(CallBase &CB, SpecState *C) {
    if (collect) {
      if (!llvm::is_contained(*collect, C))
        collect->push_back(C);
      return;
    }
    auto &v = cur->callees[&CB];
    if (v.size() != 1 || v[0] != C) {
      v.assign(1, C);
      localChanged = true;
    }
  }
  void recordWrite(Instruction &I, const PtrInfo &p, uint64_t size, bool handle, Type *T,
                   const PtrInfo *storedPtr, const Lanes *storedLanes);
  // cq-n58p, cq-0y74, cq-kuuf: a non-pointer write of a value that may carry an address.
  void recordIntWrite(const PtrInfo &p, uint64_t size);
  std::string cellDigits(CallBase &CB, Function *G, unsigned argNo, const Value *actual);
  bool writtenBefore(const Object &O, std::optional<int64_t> off, uint64_t size, const CallBase &CB);
  std::optional<uint64_t> rangeBound(const Value *V);
  unsigned resolveK(const Function &F);
  std::map<int64_t, SmallVector<Function *, 2>> signalHandlers; // signal(sig, h) calls of the module
  static constexpr int64_t kAnySignal = INT64_MIN;                // installed under a run-time signal number
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
  bool calleeDerivesFat(SpecState &S, unsigned argNo);
  bool calleeLoadsThrough(SpecState &S, unsigned argNo);
  bool accessInQuantumExitLoop(SpecState &S, unsigned argNo);
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
    SmallPtrSet<const BasicBlock *, 4> succs;
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
    n = 2;
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
// Sites and objects.

unsigned Analyzer::siteFor(const Value *V, SiteKind k, const Function *owner) {
  // cq-i9wk, cq-1c5j: a site of the running function's own activation is per specialization
  // (ImplState::siteOfFrame).
  bool frameCtx = owner && cur && cur->F == owner && k != SiteKind::Function && k != SiteKind::Global;
  auto &map = frameCtx ? st.siteOfFrame[cur] : st.siteOf;
  auto it = map.find(V);
  if (it != map.end())
    return it->second;
  unsigned id = st.sites.size();
  Site s;
  s.kind = k;
  s.v = V;
  s.owner = owner;
  st.sites.push_back(s);
  map[V] = id;
  if (k != SiteKind::Function) {
    Object o;
    o.site = id;
    st.sites[id].objects.push_back(st.objects.size());
    st.objects.push_back(o);
  }
  // An array of structs is one object per scalar field column (rule 20).
  Type *T = nullptr;
  if (auto *AI = dyn_cast<AllocaInst>(V))
    T = AI->getAllocatedType();
  else if (auto *GV = dyn_cast<GlobalVariable>(V))
    T = GV->getValueType();
  if (T)
    if (auto *AT = dyn_cast<ArrayType>(T))
      if (auto *ST = dyn_cast<StructType>(AT->getElementType()))
        splitSite(id, st.DL->getTypeAllocSize(ST), ST);
  // Global initializers: the pointers they hold (function tables, 97).
  if (auto *GV = dyn_cast<GlobalVariable>(V)) {
    if (GV->hasInitializer()) {
      SmallVector<const Constant *, 8> work{GV->getInitializer()};
      PtrInfo stored;
      bool any = false;
      while (!work.empty()) {
        const Constant *C = work.pop_back_val();
        if (auto *G = dyn_cast<GlobalValue>(C)) {
          PtrInfo p;
          p.init = true;
          p.top = true;
          p.sites.push_back(siteFor(G, isa<Function>(G) ? SiteKind::Function : SiteKind::Global,
                                    nullptr));
          stored.join(p);
          any = true;
          continue;
        }
        for (const Use &U : C->operands())
          if (auto *CC = dyn_cast<Constant>(U.get()))
            work.push_back(CC);
      }
      if (any) {
        for (ObjectId o : st.sites[id].objects) {
          st.objects[o].stored.join(stored);
          st.objects[o].anyPtr = true;
        }
        escape(stored);
      }
    }
  }
  return id;
}

void Analyzer::splitSite(unsigned s, uint64_t stride, StructType *ST) {
  Site &site = st.sites[s];
  if (site.stride)
    return;
  const StructLayout *SL = st.DL->getStructLayout(ST);
  SmallVector<int64_t, 4> cols;
  for (unsigned i = 0; i < ST->getNumElements(); ++i) {
    Type *E = ST->getElementType(i);
    if (E->isAggregateType() || E->isVectorTy())
      return; // nested aggregates: kept whole (no example needs more)
    cols.push_back(int64_t(SL->getElementOffset(i)));
  }
  if (cols.size() < 2)
    return;
  site.stride = stride;
  site.columns.assign(cols.begin(), cols.end());
  // Replace the single object by one per column. The first keeps its id.
  ObjectId first = site.objects.front();
  site.objects.clear();
  for (unsigned c = 0; c < cols.size(); ++c) {
    ObjectId id;
    if (c == 0) {
      id = first;
    } else {
      id = st.objects.size();
      Object o = st.objects[first];
      st.objects.push_back(o);
    }
    st.objects[id].column = int(c);
    st.sites[s].objects.push_back(id);
  }
  st.changed = true;
}

SmallVector<ObjectId, 4> Analyzer::objectsAt(unsigned s, const PtrInfo &p) {
  const Site &site = st.sites[s];
  if (site.kind == SiteKind::Function)
    return {};
  if (!site.stride)
    return {site.objects.front()};
  if (auto m = p.mod(site.stride)) {
    for (unsigned c = site.columns.size(); c-- > 0;)
      if (site.columns[c] <= *m)
        return {site.objects[c]};
  }
  return SmallVector<ObjectId, 4>(site.objects.begin(), site.objects.end());
}

SmallVector<ObjectId, 4> Analyzer::objectsOf(const PtrInfo &p) {
  SmallVector<ObjectId, 4> out;
  for (unsigned s : p.sites)
    for (ObjectId o : objectsAt(s, p))
      out.push_back(o);
  return out;
}

// cq-n58p: a ptrtoint constant expression (an instruction operand, a global initializer) escapes the
// address it converts.
void Analyzer::escapeConstants(const Constant *C) {
  SmallVector<const Constant *, 8> work{C};
  SmallPtrSet<const Constant *, 16> seen;
  while (!work.empty()) {
    const Constant *X = work.pop_back_val();
    if (!seen.insert(X).second || isa<GlobalValue>(X))
      continue;
    if (auto *CE = dyn_cast<ConstantExpr>(X))
      if (CE->getOpcode() == Instruction::PtrToInt) {
        APInt off(64, 0);
        const Value *base =
            CE->getOperand(0)->stripAndAccumulateConstantOffsets(*st.DL, off, /*AllowNonInbounds=*/true);
        if (auto *G = dyn_cast<GlobalValue>(base)) {
          PtrInfo p;
          p.init = true;
          p.sites.push_back(siteFor(G, isa<Function>(G) ? SiteKind::Function : SiteKind::Global, nullptr));
          escape(p);
        }
      }
    for (const Use &U : X->operands())
      if (auto *CC = dyn_cast<Constant>(U.get()))
        work.push_back(CC);
  }
}

PtrInfo Analyzer::escapedFor(const Value *V, const Function *F) {
  PtrInfo q;
  q.init = true;
  q.top = true;
  for (unsigned s : st.escaped.sites) {
    const Site &site = st.sites[s];
    if (site.kind == SiteKind::Alloca && site.owner != F && !hasIndirectCall &&
        !callsReach(site.owner, F))
      continue;
    q.sites.push_back(s);
  }
  // An address no escaped object can explain has no provenance (LLVM: a dereference is UB); an
  // unknown object names it so the pointer is never bottom.
  if (q.sites.empty())
    q.sites.push_back(siteFor(V, SiteKind::External, F));
  sortUnique(q.sites);
  return q;
}

bool Analyzer::runOnce(const Function *F) {
  auto it = runOnceMemo.find(F);
  if (it != runOnceMemo.end())
    return it->second == 1;
  runOnceMemo[F] = 0; // a cycle through the callers: not once
  bool once = !hasReturnsTwice && !F->hasAddressTaken() && !callsReach(F, F);
  const CallBase *site = nullptr;
  unsigned calls = 0;
  if (once)
    for (const User *U : F->users()) {
      auto *CB = dyn_cast<CallBase>(U);
      if (!CB || CB->getCalledFunction() != F) {
        once = false;
        break;
      }
      ++calls;
      site = CB;
    }
  if (once && calls > 1)
    once = false;
  if (once && site) {
    // The one call site runs once: its function runs once and the call is in no CFG cycle.
    const BasicBlock *BB = site->getParent();
    const Function *G = BB->getParent();
    for (const BasicBlock *S : successors(BB))
      if (isPotentiallyReachable(S, BB))
        once = false;
    if (once)
      once = runOnce(G);
  }
  runOnceMemo[F] = once ? 1 : 2;
  return once;
}

bool Analyzer::storeOrderHolds(const Function *F, const Site &site) {
  if (hasReturnsTwice)
    return false; // a longjmp re-enters a block after the setjmp (rule 24)
  if (runOnce(F))
    return true;
  return site.kind == SiteKind::Alloca && site.owner == F && !mayRecurse(F);
}

// ---------------------------------------------------------------------------------------------
// Specializations.

std::string lanesStr(const Lanes &l) {
  std::string s;
  for (unsigned i = 0; i < l.size(); ++i)
    s += l.test(i) ? '1' : '0';
  return s;
}

SpecState *Analyzer::getSpec(Function *F, std::vector<Lanes> formal, std::vector<Type *> tys,
                             std::vector<std::string> cells, bool ctl, bool pure,
                             unsigned depth, std::vector<uint64_t> bounds, std::vector<unsigned> boundFormals) {
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
  for (unsigned i = 0; i < formal.size(); ++i) {
    key += lanesStr(formal[i]);
    if (i < cells.size() && !cells[i].empty())
      key += "[" + cells[i] + "]";
    key += ",";
  }
  key += "|" + std::to_string(ctl) + std::to_string(pure) + ":" +
         std::to_string(depth);
  for (size_t i = 0; i < bounds.size(); ++i)
    key += ":b" + std::to_string(boundFormals[i]) + "=" + std::to_string(bounds[i]);
  auto it = st.byKey.find(key);
  if (it != st.byKey.end())
    return it->second;
  auto S = std::make_unique<SpecState>();
  S->F = F;
  S->formal = std::move(formal);
  S->formalTy = std::move(tys);
  S->cells = std::move(cells);
  S->cells.resize(S->formal.size());
  S->formalPtr.resize(S->formal.size());
  S->ctl = ctl;
  S->pure = pure;
  S->depth = depth;
  S->bounds = std::move(bounds);
  S->boundFormals = std::move(boundFormals);
  S->declared = F->isDeclaration();
  bool zero = !ctl && !pure && depth == 0 && S->bounds.empty();
  for (const Lanes &l : S->formal)
    zero = zero && l.none();
  for (const std::string &c : S->cells)
    zero = zero && c.find('1') == std::string::npos;
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
  if (!curUser || cur->exitQ.empty() || curUser->getType()->isPointerTy() ||
      V->getType()->isPointerTy())
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

PtrInfo Analyzer::P(const Value *V) {
  auto it = cur->ptr.find(V);
  if (it != cur->ptr.end())
    return it->second;
  PtrInfo p;
  const Value *base = V;
  if (auto *C = dyn_cast<Constant>(V)) {
    APInt off(64, 0);
    base = V->stripAndAccumulateConstantOffsets(*st.DL, off, /*AllowNonInbounds=*/true);
    // CR rule 13 (b137e75): a code address is an integer, never a data pointer: no object, no provenance.
    if (isa<ConstantPointerNull>(base) || isa<UndefValue>(base) || isa<BlockAddress>(base)) {
      p.init = true;
      return p;
    }
    if (auto *G = dyn_cast<GlobalValue>(base)) {
      p.init = true;
      p.c = off.getSExtValue();
      p.sites.push_back(siteFor(G, isa<Function>(G) ? SiteKind::Function : SiteKind::Global, nullptr));
      return p;
    }
    // Other constants (inttoptr of a literal address): an unknown external object.
    (void)C;
    p.init = true;
    p.top = true;
    p.sites.push_back(siteFor(V, SiteKind::External, nullptr));
    return p;
  }
  if (auto *A = dyn_cast<Argument>(V)) {
    if (A->getParent() == cur->F && A->getArgNo() < cur->formalPtr.size())
      return cur->formalPtr[A->getArgNo()];
  }
  return p; // bottom
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

bool Analyzer::setP(const Value *V, const PtrInfo &p) {
  PtrInfo &dst = cur->ptr[V];
  if (dst.join(p)) {
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
  if (PN.getType()->isPointerTy()) {
    PtrInfo p;
    for (const Value *In : PN.incoming_values())
      p.join(P(In));
    setP(&PN, p);
    if (chosen) {
      // Tag quantum iff the incomings may point into different objects; idx iff their offsets may
      // differ (rule 21).
      PtrInfo first = P(PN.getIncomingValue(0));
      bool tag = false, idx = false;
      for (const Value *In : PN.incoming_values()) {
        if (In == &PN)
          continue;
        PtrInfo q = P(In);
        if (q.sites != first.sites)
          tag = true;
        if (!q.sameOffset(first))
          idx = true;
      }
      if (tag)
        l.set(0);
      if (idx)
        l.set(1);
    }
  } else if (chosen) {
    l = allLanes(n);
  }
  setL(&PN, l);
}

void Analyzer::transferSelect(SelectInst &SI) {
  unsigned n = lanesOf(SI.getType());
  Lanes l(n);
  orInto(l, L(SI.getTrueValue()));
  orInto(l, L(SI.getFalseValue()));
  bool condQ = anyLane(L(SI.getCondition()));
  bool same = SI.getTrueValue() == SI.getFalseValue();
  if (SI.getType()->isPointerTy()) {
    PtrInfo a = P(SI.getTrueValue()), b = P(SI.getFalseValue());
    PtrInfo p = a;
    p.join(b);
    setP(&SI, p);
    if (condQ && !same) {
      if (a.sites != b.sites)
        l.set(0);
      if (!a.sameOffset(b))
        l.set(1);
    }
  } else if (condQ && !same) {
    if (SI.getCondition()->getType()->isVectorTy())
      l = allLanes(n);
    else
      l = allLanes(n);
  }
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
    escape(P(Src));
    setL(&CI, s.any() ? allLanes(n) : Lanes(n));
    return;
  case Instruction::IntToPtr: {
    // inttoptr of an integer derived from ptrtoint(p) keeps p's provenance (rule 21, LLVM's rule):
    // tag = p's tag, idx from the integer arithmetic. An integer of unknown origin is decoded over
    // unknown objects.
    struct Walk {
      const Value *p = nullptr;
      int64_t c = 0;
      uint64_t g = 0;
      bool bad = false;
    } w;
    std::function<void(const Value *, int64_t)> go = [&](const Value *V, int64_t scale) {
      using namespace PatternMatch;
      const APInt *K;
      const Value *X, *Y;
      if (auto *PI = dyn_cast<PtrToIntInst>(V)) {
        if (w.p || scale != 1)
          w.bad = true;
        w.p = PI->getOperand(0);
        return;
      }
      if (match(V, m_APInt(K))) {
        w.c += scale * K->getSExtValue();
        return;
      }
      if (match(V, m_Add(m_Value(X), m_Value(Y))) ||
          match(V, m_DisjointOr(m_Value(X), m_Value(Y)))) {
        go(X, scale);
        go(Y, scale);
        return;
      }
      if (match(V, m_Sub(m_Value(X), m_APInt(K)))) {
        go(X, scale);
        w.c -= scale * K->getSExtValue();
        return;
      }
      if (match(V, m_ZExtOrSExt(m_Value(X)))) {
        go(X, scale);
        return;
      }
      if (match(V, m_Shl(m_Value(X), m_APInt(K))) && K->ult(63)) {
        w.g = gcd64(w.g, uint64_t(std::abs(scale)) << K->getZExtValue());
        return;
      }
      if (match(V, m_Mul(m_Value(X), m_APInt(K)))) {
        w.g = gcd64(w.g, uint64_t(std::abs(scale * K->getSExtValue())));
        return;
      }
      w.g = gcd64(w.g, uint64_t(std::abs(scale)));
    };
    go(Src, 1);
    Lanes l(2);
    if (w.p && !w.bad) {
      Lanes pl = L(w.p);
      PtrInfo pp = P(w.p);
      PtrInfo q = pp;
      if (q.init && !q.top) {
        q.c += w.c;
        q.g = gcd64(q.g, w.g);
      }
      setP(&CI, q);
      if (pl.test(0))
        l.set(0);
      if (pl.test(1) || s.any())
        l.set(1);
    } else {
      // Provenance lost (cq-n58p): an unknown object, or any object whose address escaped.
      setP(&CI, escapedFor(&CI, cur->F));
      if (s.any())
        l.set();
    }
    setL(&CI, l);
    return;
  }
  case Instruction::BitCast:
  case Instruction::AddrSpaceCast:
    if (CI.getType()->isPointerTy())
      setP(&CI, P(Src));
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
  Value *Base = G.getPointerOperand();
  PtrInfo p = P(Base);
  Lanes bl = L(Base);
  Lanes l(lanesOf(G.getType()));
  if (!G.getType()->isPointerTy())
    internalError("taint: IR the pinned pipeline cannot emit (CR §0, rule 25): a vector getelementptr (a pointer vector)", &G);
  if (bl.size() >= 2) {
    if (bl.test(0))
      l.set(0);
    if (bl.test(1))
      l.set(1);
  }
  PtrInfo q = p;
  if (q.init && !q.top) {
    for (gep_type_iterator GTI = gep_type_begin(G), E = gep_type_end(G); GTI != E; ++GTI) {
      Value *Idx = GTI.getOperand();
      if (StructType *ST = GTI.getStructTypeOrNull()) {
        unsigned f = unsigned(cast<ConstantInt>(Idx)->getZExtValue());
        q.c += int64_t(st.DL->getStructLayout(ST)->getElementOffset(f));
        continue;
      }
      uint64_t sz = GTI.getSequentialElementStride(*st.DL);
      if (auto *CIdx = dyn_cast<ConstantInt>(Idx)) {
        q.c += CIdx->getSExtValue() * int64_t(sz);
      } else {
        q.g = gcd64(q.g, sz);
        if (anyLane(L(Idx)))
          l.set(1);
      }
    }
  } else {
    for (auto &Idx : G.indices())
      if (anyLane(L(Idx.get())))
        l.set(1);
  }
  // A struct element stride over a variable index marks an array of structs: split the sites into
  // field columns (rule 20, 78).
  {
    gep_type_iterator GTI = gep_type_begin(G);
    for (unsigned i = 0; GTI != gep_type_end(G); ++GTI, ++i) {
      Value *Idx = GTI.getOperand();
      if (GTI.isSequential() && !isa<ConstantInt>(Idx)) {
        Type *Elt = GTI.getIndexedType();
        if (auto *ST = dyn_cast<StructType>(Elt))
          for (unsigned s : p.sites)
            if (st.sites[s].kind != SiteKind::Function)
              splitSite(s, st.DL->getTypeAllocSize(ST), ST);
      }
    }
  }
  setP(&G, q);
  setL(&G, l);
}

// Record a write (store, memset/memcpy destination, callee store) into the objects of p.
void Analyzer::recordWrite(Instruction &I, const PtrInfo &p, uint64_t size, bool handle, Type *T,
                           const PtrInfo *storedPtr, const Lanes *storedLanes) {
  auto ex = p.exact();
  bool unknownCell = !ex;
  for (unsigned s : p.sites) {
    const Site &site = st.sites[s];
    if (site.kind == SiteKind::Function)
      continue;
    for (ObjectId oid : objectsAt(s, p)) {
      Object &O = st.objects[oid];
      if (handle) {
        if (unknownCell) {
          if (!O.anyHandle) {
            O.anyHandle = true;
            touchObject();
          }
        } else if (addRange(O.handleCells, *ex, size)) {
          touchObject();
        }
      }
      if (T && T->isPointerTy()) {
        if (unknownCell) {
          if (!O.anyPtr) {
            O.anyPtr = true;
            touchObject();
          }
        } else if (addRange(O.ptrCells, *ex, size)) {
          touchObject();
        }
        if (storedPtr) {
          escape(*storedPtr);
          // A store instruction's pointers are seen only by loads it may reach (88: a pointer
          // stored after a load is not in that load's provenance); memcpy and initializers are
          // merged unconditionally.
          if (isa<StoreInst>(&I) || isa<AtomicRMWInst>(&I) || isa<AtomicCmpXchgInst>(&I)) {
            PtrInfo &slot = O.storedBy[&I];
            if (slot.join(*storedPtr))
              touchObject();
          } else if (O.stored.join(*storedPtr)) {
            touchObject();
          }
        }
        if (storedLanes && storedLanes->size() >= 2) {
          if (storedLanes->test(0) && !O.storedTagQ) {
            O.storedTagQ = true;
            touchObject();
          }
          if (storedLanes->test(1) && !O.storedIdxQ) {
            O.storedIdxQ = true;
            touchObject();
          }
        }
      }
    }
  }
}

// A stored non-pointer value may carry (part of) an address unless it is a constant built from no
// global's address (a literal integer, null, undef, a float).
static bool mayCarryAddress(const Value *V) {
  auto *C = dyn_cast<Constant>(V);
  if (!C)
    return true;
  SmallVector<const Constant *, 8> work{C};
  while (!work.empty()) {
    const Constant *X = work.pop_back_val();
    if (isa<GlobalValue>(X) || isa<BlockAddress>(X) || isa<DSOLocalEquivalent>(X) ||
        isa<NoCFIValue>(X))
      return true;
    for (const Use &U : X->operands())
      if (auto *CC = dyn_cast<Constant>(U.get()))
        work.push_back(CC);
  }
  return false;
}

void Analyzer::recordIntWrite(const PtrInfo &p, uint64_t size) {
  auto ex = p.exact();
  for (unsigned s : p.sites) {
    if (st.sites[s].kind == SiteKind::Function)
      continue;
    for (ObjectId oid : objectsAt(s, p)) {
      Object &O = st.objects[oid];
      if (!ex || !size) {
        if (!O.anyInt) {
          O.anyInt = true;
          touchObject();
        }
      } else if (addRange(O.intCells, *ex, size)) {
        touchObject();
      }
    }
  }
}

void Analyzer::transferLoad(Instruction &I, Value *ptr, Type *T) {
  PtrInfo p = P(ptr);
  Lanes pl = L(ptr);
  unsigned n = lanesOf(T);
  uint64_t size = st.DL->getTypeStoreSize(T);
  bool fat = pl.any();
  bool q = fat;
  auto ex = p.exact();
  PtrInfo loaded;
  bool tagQ = false, idxQ = false, intPun = false;
  for (unsigned s : p.sites) {
    for (ObjectId oid : objectsAt(s, p)) {
      Object &O = st.objects[oid];
      if (pl.size() >= 2 && pl.test(1) && O.mayHoldHandle() && !O.qram) {
        O.qram = true; // quantum-offset load of an object that may hold a handle (rule 20)
        touchObject();
      }
      if (O.cellHandle(ex, size))
        q = true;
      if (T->isPointerTy()) {
        loaded.join(O.stored);
        for (auto &[SI, sp] : O.storedBy) {
          if (SI->getFunction() != I.getFunction() ||
              !storeOrderHolds(I.getFunction(), st.sites[O.site])) {
            loaded.join(sp);
            continue;
          }
          FnInfo &fi = fn(I.getFunction());
          if (isPotentiallyReachable(SI, &I, nullptr, fi.DT.get(), fi.LI.get()))
            loaded.join(sp);
        }
        tagQ = tagQ || O.storedTagQ;
        idxQ = idxQ || O.storedIdxQ;
        if (O.cellHandle(ex, size))
          idxQ = true; // a handle cell of pointer kind holds (tag, idx) rails (107)
        if (overlapsAny(O.intCells, ex, size, O.anyInt)) {
          // A cell written as an integer (a pointer punned, copied byte-wise, compare-exchanged as
          // i64): the pointer read back has lost its provenance (cq-n58p, cq-0y74, cq-kuuf).
          intPun = true;
          if (O.cellHandle(ex, size))
            tagQ = idxQ = true;
        }
      }
    }
  }
  if (T->isPointerTy()) {
    if (intPun)
      loaded.join(escapedFor(&I, cur->F));
    if (!loaded.init || loaded.sites.empty()) {
      // Pointer of unknown origin: an external object named by this load.
      PtrInfo e;
      e.init = true;
      e.top = true;
      e.sites.push_back(siteFor(&I, SiteKind::External, cur->F));
      loaded.join(e);
    }
    setP(&I, loaded);
    Lanes l(2);
    if (tagQ || (fat && loaded.sites.size() > 1))
      l.set(0);
    if (idxQ || (fat && !loaded.exact()))
      l.set(1);
    if (pl.size() >= 2 && pl.test(1)) {
      l.set(0);
      l.set(1);
    }
    setL(&I, l);
    return;
  }
  if (q)
    setL(&I, allLanes(n));
  else
    setL(&I, Lanes(n));
}

void Analyzer::transferStore(Instruction &I, Value *ptr, Value *val, Type *T) {
  PtrInfo p = P(ptr);
  Lanes pl = L(ptr);
  Lanes vl = L(val);
  bool handle = vl.any() || pl.any() || blockCT(I.getParent()) || cur->ctl;
  if (pl.size() >= 2 && pl.test(1)) {
    for (ObjectId oid : objectsOf(p))
      if (!st.objects[oid].qram) {
        st.objects[oid].qram = true; // quantum-offset store (rule 20)
        touchObject();
      }
  }
  PtrInfo sp;
  const PtrInfo *spp = nullptr;
  Lanes ctlLanes;
  const Lanes *slp = &vl;
  if (T->isPointerTy()) {
    sp = P(val);
    spp = &sp;
    if (handle && !vl.any()) {
      ctlLanes = Lanes(2);
      if (blockCT(I.getParent()) || cur->ctl)
        ctlLanes.set();
      slp = &ctlLanes;
    }
  }
  recordWrite(I, p, st.DL->getTypeStoreSize(T), handle, T, spp, slp);
  if (!T->isPointerTy() && mayCarryAddress(val))
    recordIntWrite(p, st.DL->getTypeStoreSize(T));
  if (!p.sites.empty()) {
    for (unsigned s : p.sites) {
      const Site &site = st.sites[s];
      if (!(site.kind == SiteKind::Alloca && site.owner == cur->F))
        cur->writesOuter = true;
    }
  }
  if (handle)
    cur->anyQuantum = true;
  // A classical store into a slot cell materializes a seed rail (rule 20 homogeneity, rule 7).
  for (ObjectId oid : objectsOf(p))
    if (st.objects[oid].cellHandle(p.exact(), st.DL->getTypeStoreSize(T)))
      cur->anyQuantum = true;
}

void Analyzer::transferMemIntrinsic(MemIntrinsic &MI) {
  PtrInfo d = P(MI.getRawDest());
  Lanes dl = L(MI.getRawDest());
  Lanes nl = L(MI.getLength());
  bool ctlQ = blockCT(MI.getParent()) || cur->ctl || nl.any() || dl.any();
  std::optional<uint64_t> len;
  if (auto *C = dyn_cast<ConstantInt>(MI.getLength()))
    len = C->getZExtValue();
  if (dl.size() >= 2 && dl.test(1))
    for (ObjectId oid : objectsOf(d))
      if (!st.objects[oid].qram) {
        st.objects[oid].qram = true;
        touchObject();
      }
  for (unsigned s : d.sites) {
    const Site &site = st.sites[s];
    if (!(site.kind == SiteKind::Alloca && site.owner == cur->F))
      cur->writesOuter = true;
  }
  if (auto *MS = dyn_cast<MemSetInst>(&MI)) {
    bool handle = ctlQ || L(MS->getValue()).any();
    recordWrite(MI, d, len.value_or(0), handle, nullptr, nullptr, nullptr);
    if (!len && handle) {
      PtrInfo u = d;
      u.top = true;
      recordWrite(MI, u, 0, true, nullptr, nullptr, nullptr);
    }
    return;
  }
  auto *MT = cast<MemTransferInst>(&MI);
  PtrInfo s = P(MT->getRawSource());
  Lanes sl = L(MT->getRawSource());
  auto sx = s.exact();
  auto dx = d.exact();
  bool srcAny = false;
  std::vector<Range> moved;
  bool movedPtr = false, movedInt = false;
  PtrInfo storedPtr;
  bool sTag = false, sIdx = false;
  for (unsigned site : s.sites) {
    for (ObjectId oid : objectsAt(site, s)) {
      Object &O = st.objects[oid];
      if (sl.size() >= 2 && sl.test(1) && O.mayHoldHandle() && !O.qram) {
        O.qram = true;
        touchObject();
      }
      if (O.anyPtr || !O.ptrCells.empty()) {
        movedPtr = true;
        storedPtr.join(O.stored);
        for (auto &[SI, sp] : O.storedBy)
          storedPtr.join(sp);
        sTag = sTag || O.storedTagQ;
        sIdx = sIdx || O.storedIdxQ;
      }
      if (O.anyInt || !O.intCells.empty())
        movedInt = true;
      if (!O.mayHoldHandle())
        continue;
      if (O.anyHandle || O.qram || !sx || !dx || !len) {
        srcAny = true;
        continue;
      }
      for (const Range &r : O.handleCells)
        if (r.off < *sx + int64_t(*len) && *sx < r.off + int64_t(r.size))
          moved.push_back({r.off - *sx + *dx, r.size});
    }
  }
  if (sl.any())
    srcAny = true;
  if (ctlQ || srcAny) {
    PtrInfo u = d;
    if (!len || srcAny || !dx) {
      u.top = !len || !dx ? true : u.top;
    }
    if (len && dx && !srcAny)
      recordWrite(MI, d, *len, true, nullptr, nullptr, nullptr);
    else {
      PtrInfo uu = d;
      uu.top = true;
      recordWrite(MI, uu, 0, true, nullptr, nullptr, nullptr);
    }
  }
  for (const Range &r : moved) {
    PtrInfo at = d;
    at.c = r.off;
    at.g = 0;
    recordWrite(MI, at, r.size, true, nullptr, nullptr, nullptr);
  }
  if (movedInt) {
    PtrInfo uu = d;
    uu.top = true;
    recordIntWrite(uu, 0);
  }
  if (movedPtr) {
    Lanes pl(2);
    if (sTag)
      pl.set(0);
    if (sIdx)
      pl.set(1);
    PtrInfo uu = d;
    uu.top = true;
    PointerType *PT = PointerType::get(MI.getContext(), 0);
    recordWrite(MI, uu, 8, false, PT, &storedPtr, &pl);
  }
}

// ---------------------------------------------------------------------------------------------
// Variadic functions (CR §1.4, rules 3 and 20; 95, 109; cq-prvy).
//
// A variadic clone is specialised per call-site arity, so cur's formals past F's fixed parameters are
// the variadic actuals. llvm.va_start(ap) is the target ABI's spill of them (x86-64 SysV: va_list is
// { i32 gp_offset, i32 fp_offset, ptr overflow_arg_area, ptr reg_save_area }): one object of this
// frame, named by the va_start call, that both area pointers point into. -O1's own va_arg code reads
// the actuals back through those pointers at classical run-time offsets, so the object is uniform: when
// any variadic actual is quantum every cell holds a handle (the classical actuals are promoted to
// rails, 95's reference), and its pointer actuals are the pointers it may hold.
static constexpr int64_t kVaOverflowOff = 8, kVaRegSaveOff = 16, kVaListSize = 24;

void Analyzer::transferVaStart(CallBase &CB) {
  const Triple TT(st.M->getTargetTriple());
  if (TT.getArch() != Triple::x86_64)
    internalError("taint: IR the pinned pipeline cannot emit (CR §0, rule 25): llvm.va_start on a target other than x86-64 SysV", &CB);
  unsigned area = siteFor(&CB, SiteKind::Alloca, cur->F);
  bool anyQ = false, anyPtr = false;
  PtrInfo held;
  Lanes heldLanes(2);
  for (unsigned i = cur->F->arg_size(); i < cur->formal.size(); ++i) {
    if (cur->formal[i].any())
      anyQ = true;
    if (i < cur->formalTy.size() && cur->formalTy[i] && cur->formalTy[i]->isPointerTy()) {
      anyPtr = true;
      if (i < cur->formalPtr.size())
        held.join(cur->formalPtr[i]);
      if (cur->formal[i].size() >= 2) {
        if (cur->formal[i].test(0))
          heldLanes.set(0);
        if (cur->formal[i].test(1))
          heldLanes.set(1);
      }
    }
  }
  PtrInfo cells;
  cells.init = true;
  cells.top = true;
  cells.sites.push_back(area);
  if (anyQ) {
    recordWrite(CB, cells, 0, true, nullptr, nullptr, nullptr);
    cur->anyQuantum = true;
  }
  PointerType *PT = PointerType::get(CB.getContext(), 0);
  if (anyPtr && held.init)
    recordWrite(CB, cells, 8, false, PT, &held, &heldLanes);
  // ap's two area pointers point into the area (classical: the offsets are the ABI's).
  PtrInfo ap = P(CB.getArgOperand(0));
  Lanes classical(2);
  for (int64_t off : {kVaOverflowOff, kVaRegSaveOff}) {
    PtrInfo at = ap;
    if (auto e = ap.exact())
      at.c = *e + off;
    else
      at.top = true;
    recordWrite(CB, at, 8, false, PT, &cells, &classical);
  }
}

void Analyzer::transferVaCopy(CallBase &CB) {
  // va_copy(dst, src): src's va_list cells into dst's, pointer cell by pointer cell.
  PtrInfo dst = P(CB.getArgOperand(0)), src = P(CB.getArgOperand(1));
  PointerType *PT = PointerType::get(CB.getContext(), 0);
  for (int64_t off = 0; off < kVaListSize; off += 8) {
    PtrInfo s = src, d = dst;
    if (auto e = src.exact())
      s.c = *e + off;
    else
      s.top = true;
    if (auto e = dst.exact())
      d.c = *e + off;
    else
      d.top = true;
    PtrInfo moved;
    bool any = false, tagQ = false, idxQ = false;
    for (ObjectId oid : objectsOf(s)) {
      Object &O = st.objects[oid];
      // The va_list's cells hold what va_start wrote (two classical offsets, two pointers into the save
      // and overflow areas): a handle in one of them is a store into the opaque va_list's bytes, which
      // makes the later va_arg undefined (C17 7.16.1), outside the domain. Handles elsewhere in the
      // object (a va_list inside a struct with quantum fields) are not moved by va_copy.
      if (!(O.anyPtr || !O.ptrCells.empty()))
        continue;
      any = true;
      moved.join(O.stored);
      for (auto &[SI, sp] : O.storedBy)
        moved.join(sp);
      tagQ = tagQ || O.storedTagQ;
      idxQ = idxQ || O.storedIdxQ;
    }
    if (!any)
      continue;
    Lanes pl(2);
    if (tagQ)
      pl.set(0);
    if (idxQ)
      pl.set(1);
    recordWrite(CB, d, 8, false, PT, &moved, &pl);
  }
}

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

unsigned Analyzer::resolveK(const Function &F) {
  // CR §0 chain: per-function flag, CQ_K(f, k), global flag, default 4. The flags do not reach
  // computeTaint (TaintOptions carries none; see the report), so this is CQ_K, then the default.
  if (const GlobalVariable *GV = st.M->getGlobalVariable(("__cq_k_" + F.getName()).str(), true))
    if (GV->hasInitializer())
      if (auto *CI = dyn_cast<ConstantInt>(GV->getInitializer()))
        if (CI->getZExtValue() > 0)
          return unsigned(CI->getZExtValue());
  return 4;
}

bool Analyzer::writtenBefore(const Object &O, std::optional<int64_t> off, uint64_t size,
                             const CallBase &CB) {
  const Site &site = st.sites[O.site];
  const Function *F = CB.getFunction();
  if (site.owner != F || site.kind == SiteKind::External)
    return true;
  FnInfo &fi = fn(F);
  for (const BasicBlock *BB : fi.rpo)
    for (const Instruction &I : *BB) {
      if (&I == &CB)
        continue;
      const Value *ptr = nullptr;
      uint64_t sz = 0;
      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        ptr = SI->getPointerOperand();
        sz = st.DL->getTypeStoreSize(SI->getValueOperand()->getType());
      } else if (auto *MI = dyn_cast<MemIntrinsic>(&I)) {
        ptr = MI->getRawDest();
        if (auto *C = dyn_cast<ConstantInt>(MI->getLength()))
          sz = C->getZExtValue();
      } else if (auto *C2 = dyn_cast<CallBase>(&I)) {
        if (isa<IntrinsicInst>(C2))
          continue;
        for (const Use &A : C2->args())
          if (A->getType()->isPointerTy()) {
            PtrInfo p = P(A.get());
            if (llvm::is_contained(p.sites, O.site) &&
                isPotentiallyReachable(&I, &CB, nullptr, fi.DT.get(), fi.LI.get()))
              return true;
          }
        continue;
      } else {
        continue;
      }
      PtrInfo p = P(ptr);
      if (!llvm::is_contained(p.sites, O.site))
        continue;
      auto ex = p.exact();
      bool overl = !ex || !off || sz == 0 || (*ex < *off + int64_t(size) && *off < *ex + int64_t(sz));
      if (!overl)
        continue;
      if (isPotentiallyReachable(&I, &CB, nullptr, fi.DT.get(), fi.LI.get()))
        return true;
    }
  return false;
}

// The callee's accesses through formal argNo: byte offsets of the cells it touches, or nullopt for a
// runtime-length register (a variable offset).
static std::optional<std::vector<std::pair<int64_t, uint64_t>>>
accessedCells(Function *G, unsigned argNo, const DataLayout &DL) {
  if (G->isDeclaration() || argNo >= G->arg_size())
    return std::nullopt;
  std::vector<std::pair<int64_t, uint64_t>> out;
  // (pointer, offset from the formal; nullopt once a variable offset was added)
  SmallVector<std::pair<const Value *, std::optional<int64_t>>, 8> work{{G->getArg(argNo), 0}};
  SmallPtrSet<const Value *, 16> seen;
  bool runtime = false;
  auto access = [&](std::optional<int64_t> off, uint64_t size) {
    if (off)
      out.push_back({*off, size});
    else
      runtime = true;
  };
  while (!work.empty()) {
    auto [V, off] = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    for (const User *U : V->users()) {
      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        APInt o(64, 0);
        if (off && GEP->accumulateConstantOffset(DL, o))
          work.push_back({GEP, *off + o.getSExtValue()});
        else
          work.push_back({GEP, std::nullopt});
      } else if (auto *LI = dyn_cast<LoadInst>(U)) {
        access(off, DL.getTypeStoreSize(LI->getType()));
      } else if (auto *SI = dyn_cast<StoreInst>(U)) {
        if (SI->getPointerOperand() == V)
          access(off, DL.getTypeStoreSize(SI->getValueOperand()->getType()));
        else
          runtime = true; // the pointer itself escapes into memory
      } else if (isa<BitCastOperator>(U)) {
        work.push_back({U, off});
      } else if (isa<SelectInst>(U) || isa<PHINode>(U)) {
        work.push_back({U, std::nullopt});
      } else if (isa<ReturnInst>(U) || isa<ICmpInst>(U) || isa<PtrToIntInst>(U)) {
        continue; // no access by the callee
      } else if (auto *II = dyn_cast<IntrinsicInst>(U)) {
        if (II->isLifetimeStartOrEnd())
          continue;
        runtime = true;
      } else {
        runtime = true;
      }
    }
  }
  if (runtime)
    return std::nullopt;
  llvm::sort(out);
  out.erase(std::unique(out.begin(), out.end(),
                        [](auto &a, auto &b) { return a.first == b.first; }),
            out.end());
  return out;
}

// Naming information of a pointer actual (CR §1.4), recorded in the key:
//   A<d>      one digit: any pointee cell holds a handle at the call
//   S<d...>   sret/byval: one digit per scalar field of the attribute type
//   O<d...>;  per object in provenance (site order), one digit per accessed cell (two for a cell of
//             pointer kind); "Q" for a QRAM object (no digits); "R<d>" for a runtime-length access.
// T4 (190): the formal is walked at a run-time offset (a pointer phi, a GEP by a non-constant index) and
// every access through it and its derived pointers is a load or store of one size: that size. A store of
// the pointer itself, a call or any other use: nullopt (not a walk this record describes).
static std::optional<uint64_t> walkAccessSize(Function *G, unsigned argNo, const DataLayout &DL) {
  if (G->isDeclaration() || argNo >= G->arg_size())
    return std::nullopt;
  SmallVector<std::pair<const Value *, bool>, 8> work{{G->getArg(argNo), false}};
  SmallPtrSet<const Value *, 16> seen;
  std::optional<uint64_t> size;
  bool varying = false;
  auto access = [&](uint64_t s, bool var) {
    varying = varying || var;
    if (size && *size != s)
      return false;
    size = s;
    return true;
  };
  while (!work.empty()) {
    auto [V, var] = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    for (const User *U : V->users()) {
      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        work.push_back({GEP, var || !GEP->hasAllConstantIndices()});
      } else if (isa<PHINode>(U) || isa<SelectInst>(U)) {
        work.push_back({U, true});
      } else if (auto *LI = dyn_cast<LoadInst>(U)) {
        if (!access(DL.getTypeStoreSize(LI->getType()), var))
          return std::nullopt;
      } else if (auto *SI = dyn_cast<StoreInst>(U)) {
        if (SI->getPointerOperand() != V || !access(DL.getTypeStoreSize(SI->getValueOperand()->getType()), var))
          return std::nullopt;
      } else if (isa<ICmpInst>(U) || isa<ReturnInst>(U)) {
        continue;
      } else if (auto *II = dyn_cast<IntrinsicInst>(U); II && II->isLifetimeStartOrEnd()) {
        continue;
      } else {
        return std::nullopt;
      }
    }
  }
  if (!varying || !size)
    return std::nullopt;
  return size;
}

// The byte size of a site's object when it is a fixed-size local or global.
static std::optional<uint64_t> fixedObjectBytes(const Site &site, const DataLayout &DL) {
  if (auto *AI = dyn_cast<AllocaInst>(site.v)) {
    if (auto s = AI->getAllocationSize(DL); s && !s->isScalable())
      return s->getFixedValue();
    return std::nullopt;
  }
  if (auto *GV = dyn_cast<GlobalVariable>(site.v))
    return DL.getTypeAllocSize(GV->getValueType()).getFixedValue();
  return std::nullopt;
}

std::string Analyzer::cellDigits(CallBase &CB, Function *G, unsigned argNo, const Value *actual) {
  PtrInfo p = P(actual);
  auto ex = p.exact();
  std::string out = "A";
  bool any = false;
  for (ObjectId oid : objectsOf(p)) {
    const Object &O = st.objects[oid];
    if (O.mayHoldHandle() && writtenBefore(O, std::nullopt, 0, CB))
      any = true;
  }
  out += any ? '1' : '0';
  Type *AT = nullptr;
  if (G && !G->isDeclaration() && argNo < G->arg_size()) {
    if (G->hasParamAttribute(argNo, Attribute::StructRet))
      AT = G->getParamStructRetType(argNo);
    else if (G->hasParamAttribute(argNo, Attribute::ByVal))
      AT = G->getParamByValType(argNo);
  }
  if (AT) {
    out += "S";
    SmallVector<std::pair<int64_t, uint64_t>, 8> leaves;
    std::function<void(Type *, int64_t)> walk = [&](Type *T, int64_t base) {
      if (auto *ST = dyn_cast<StructType>(T)) {
        const StructLayout *SL = st.DL->getStructLayout(ST);
        for (unsigned i = 0; i < ST->getNumElements(); ++i)
          walk(ST->getElementType(i), base + int64_t(SL->getElementOffset(i)));
      } else if (auto *ArT = dyn_cast<ArrayType>(T)) {
        uint64_t es = st.DL->getTypeAllocSize(ArT->getElementType());
        for (uint64_t i = 0; i < ArT->getNumElements(); ++i)
          walk(ArT->getElementType(), base + int64_t(i * es));
      } else {
        leaves.push_back({base, st.DL->getTypeStoreSize(T)});
      }
    };
    walk(AT, 0);
    for (auto [off, sz] : leaves) {
      bool d = false;
      for (ObjectId oid : objectsOf(p)) {
        const Object &O = st.objects[oid];
        std::optional<int64_t> at = ex ? std::optional<int64_t>(*ex + off) : std::nullopt;
        if (O.cellHandle(at, sz) && writtenBefore(O, at, sz, CB))
          d = true;
      }
      out += d ? '1' : '0';
    }
  }
  auto cells = G ? accessedCells(G, argNo, *st.DL) : std::nullopt;
  for (unsigned s : p.sites) {
    for (ObjectId oid : objectsAt(s, p)) {
      const Object &O = st.objects[oid];
      out += "O";
      if (O.qram) {
        out += "Q;";
        continue;
      }
      if (!cells && G) {
        // T4 (190): a walk at a run-time offset into a fixed-size object: one digit per cell from the
        // pointer handed over to the object's end, at the walk's access size (the triple with its cell
        // count, rule 21).
        auto ws = walkAccessSize(G, argNo, *st.DL);
        auto bytes = fixedObjectBytes(st.sites[s], *st.DL);
        if (ws && *ws && bytes && ex && *ex >= 0 && O.column < 0 && uint64_t(*ex) <= *bytes &&
            (*bytes - uint64_t(*ex)) % *ws == 0) {
          out += "W";
          for (uint64_t at = uint64_t(*ex); at < *bytes; at += *ws) {
            bool d = O.cellHandle(int64_t(at), *ws) && writtenBefore(O, int64_t(at), *ws, CB);
            out += d ? '1' : '0';
          }
          out += ";";
          continue;
        }
      }
      if (!cells) {
        bool d = O.mayHoldHandle() && writtenBefore(O, std::nullopt, 0, CB);
        out += "R";
        out += d ? '1' : '0';
        out += ";";
        continue;
      }
      for (auto [off, sz] : *cells) {
        std::optional<int64_t> at = ex ? std::optional<int64_t>(*ex + off) : std::nullopt;
        bool d = O.cellHandle(at, sz) && writtenBefore(O, at, sz, CB);
        bool ptrKind = overlapsAny(O.ptrCells, at, sz, O.anyPtr && !O.ptrCells.empty() ? false : O.anyPtr);
        out += d ? '1' : '0';
        if (ptrKind)
          out += d ? '1' : '0';
      }
      out += ";";
    }
  }
  return out;
}

void Analyzer::lift(CallBase &CB, Function *G, ArrayRef<Value *> actuals, bool viaIntrinsic) {
  // Key of the callee specialization from the actuals' lanes (rule 18).
  std::vector<Lanes> formal;
  std::vector<Type *> tys;
  std::vector<std::string> cells;
  bool anyQ = false;
  for (unsigned i = 0; i < actuals.size(); ++i) {
    Value *A = actuals[i];
    Lanes l = L(A);
    formal.push_back(l);
    tys.push_back(A->getType());
    anyQ = anyQ || l.any();
    if (A->getType()->isPointerTy()) {
      std::string c = cellDigits(CB, G, i, A);
      if (c.find('1') != std::string::npos)
        anyQ = true;
      cells.push_back(c);
    } else {
      cells.push_back("");
    }
  }
  bool underQ = blockCT(CB.getParent()) || cur->ctl || candidateUnderQ;
  // Depth recursion (rule 14): a recursive call under a quantum predicate.
  unsigned depth = 0;
  bool recursive = false;
  if (!G->isDeclaration()) {
    recursive = callsReach(G, cur->F);
  }
  if (recursive && (blockCT(CB.getParent()) || cur->depth > 0)) {
    depth = cur->depth + 1;
    unsigned cut = cur->depthCut;
    if (cut == 0)
      cut = resolveK(*G);
    if (depth > cut) {
      cur->cutCalls.insert(&CB);
      cur->callees.erase(&CB);
      if (!CB.getType()->isVoidTy())
        setL(&CB, allLanes(lanesOf(CB.getType())));
      return;
    }
  }
  // cq-1c5j: the second run takes the first run's final key of this call at once, when it covers what the
  // actuals give now (lanes and cell digits only rise during the fixed point).
  const CalleeMemo *memo = nullptr;
  if (!calleeMemo.empty() && !collect) {
    auto it = calleeMemo.find({cur->key, &CB, G});
    if (it != calleeMemo.end() && it->second.formal.size() == formal.size() && it->second.cells.size() >= cells.size()) {
      const CalleeMemo &m = it->second;
      bool covers = true;
      for (unsigned i = 0; i < formal.size() && covers; ++i) {
        covers = m.formal[i].size() == formal[i].size() && !formal[i].test(m.formal[i]);
        const std::string &a = cells[i], &b = m.cells[i];
        if (covers && !a.empty() && !b.empty()) {
          covers = a.size() == b.size();
          for (size_t k = 0; covers && k < a.size(); ++k)
            covers = a[k] == b[k] || (a[k] == '0' && b[k] == '1');
        } else if (covers) {
          covers = a.empty() == b.empty() || b.find('1') == std::string::npos;
        }
      }
      if (covers)
        memo = &m;
    }
  }
  if (memo) {
    formal = memo->formal;
    for (unsigned i = 0; i < cells.size(); ++i)
      if (!memo->cells[i].empty() || !cells[i].empty())
        cells[i] = memo->cells[i];
    bool inPlace = !memo->ctl && depth == 0 && memo->bounds.empty() &&
                   llvm::none_of(formal, [](const Lanes &l) { return l.any(); }) &&
                   llvm::none_of(cells, [](const std::string &c) { return c.find('1') != std::string::npos; });
    if (!inPlace) {
      SpecState *C = getSpec(G, formal, tys, cells, memo->ctl, false, depth, memo->bounds);
      if (depth > 0) {
        unsigned want = cur->depthCut ? cur->depthCut : resolveK(*G);
        if (C->depthCut == 0 || want < C->depthCut) {
          C->depthCut = want;
          st.changed = true;
        }
      }
      if (depth == 0 && !G->isDeclaration() && callsReach(G, G) && C->depthCut == 0) {
        memo = nullptr;   // the depth cutoff below derives from the actuals: take the ordinary path
      } else {
        recordCallee(CB, C);
        for (unsigned i = 0; i < actuals.size(); ++i)
          if (actuals[i]->getType()->isPointerTy() && i < C->formalPtr.size())
            if (C->formalPtr[i].join(P(actuals[i])))
              st.changed = true;
        if (!CB.getType()->isVoidTy()) {
          Lanes r = C->ret;
          if (C->declared)
            r = allLanes(lanesOf(CB.getType()));
          setL(&CB, r);
          if (CB.getType()->isPointerTy())
            setP(&CB, C->retPtr);
        }
        cur->anyQuantum = true;
        return;
      }
    }
  }
  if (!anyQ && !underQ && depth == 0) {
    // Classical call: the in-place specialization of the callee.
    std::vector<Lanes> z;
    for (Type *T : tys)
      z.push_back(Lanes(lanesOf(T)));
    // The in-place specialization is the function as it is: no cell digits (its key is the root's, so a
    // function has one in-place specialization whether a root or a classical call reaches it; cq-i9wk).
    std::vector<std::string> zc(cells.size());
    SpecState *C = getSpec(G, z, tys, zc, false, false, 0, {});
    recordCallee(CB, C);
    for (unsigned i = 0; i < actuals.size(); ++i)
      if (actuals[i]->getType()->isPointerTy() && i < C->formalPtr.size())
        if (C->formalPtr[i].join(P(actuals[i])))
          st.changed = true;
    if (!CB.getType()->isVoidTy()) {
      setL(&CB, C->ret);
      if (CB.getType()->isPointerTy())
        setP(&CB, C->retPtr);
    }
    if (C->effectful || C->hasTheta || C->hasPhi)
      cur->hasEffect = cur->hasEffect || C->hasEffect;
    return;
  }
  // _ctl iff under a quantum predicate and the callee's body has a non-pure gate (rule 19). The
  // test reads the callee's specialization without the flag.
  bool ctl = false;
  if (underQ) {
    SpecState *probe = getSpec(G, formal, tys, cells, false, false, depth, {});
    if (probe->nonPure || probe->hasTheta || probe->hasPhi || probe->hasEffect || probe->writesOuter)
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
  if (depth > 0) {
    bounds = cur->bounds; // a level clone carries the bounds of its level-0 clone (98: _b3_d1)
    boundFormals = cur->boundFormals;
  }
  if (viaIntrinsic) {
    bounds.clear();
    boundFormals.clear();
  }
  SpecState *C = getSpec(G, formal, tys, cells, ctl, false, depth, bounds, boundFormals);
  if (depth > 0) {
    // Several level-(d-1) clones may reach one level-d clone (a stale key from an earlier round
    // too): the cutoff is the smallest any of them carries.
    unsigned want = cur->depthCut ? cur->depthCut : resolveK(*G);
    if (C->depthCut == 0 || want < C->depthCut) {
      C->depthCut = want;
      st.changed = true;
    }
  }
  // The B of a quantum-depth recursion: the bound of the formal the recursive call decrements.
  if (depth == 0 && !G->isDeclaration()) {
    if (callsReach(G, G) && C->depthCut == 0) {
      std::optional<uint64_t> B;
      for (BasicBlock &BB : *G)
        for (Instruction &I : BB)
          if (auto *RC = dyn_cast<CallBase>(&I))
            if (RC->getCalledFunction() == G)
              for (unsigned i = 0; i < RC->arg_size() && i < actuals.size(); ++i) {
                using namespace PatternMatch;
                if (match(RC->getArgOperand(i), m_Add(m_Specific(G->getArg(i)), m_AllOnes())))
                  if (auto b = rangeBound(actuals[i]))
                    B = B ? std::min(*B, *b) : *b;
              }
      unsigned K = resolveK(*G);
      unsigned cut = B ? unsigned(std::min<uint64_t>(K, *B)) : K;
      C->depthCut = cut;
    }
  }
  recordCallee(CB, C);
  for (unsigned i = 0; i < actuals.size(); ++i)
    if (actuals[i]->getType()->isPointerTy() && i < C->formalPtr.size())
      if (C->formalPtr[i].join(P(actuals[i])))
        st.changed = true;
  if (!CB.getType()->isVoidTy()) {
    Lanes r = C->ret;
    if (C->declared)
      r = allLanes(lanesOf(CB.getType()));
    setL(&CB, r);
    if (CB.getType()->isPointerTy())
      setP(&CB, C->retPtr);
  }
  cur->anyQuantum = true;
}

// cq-wskg (rule 24): a function with a body from which a direct call of longjmp may be reached through
// direct calls of functions with bodies.
static bool mayReachLongjmp(const Function *G) {
  SmallPtrSet<const Function *, 8> seen;
  SmallVector<const Function *, 8> work{G};
  while (!work.empty()) {
    const Function *F = work.pop_back_val();
    if (F->isDeclaration() || !seen.insert(F).second)
      continue;
    for (const BasicBlock &BB : *F)
      for (const Instruction &I : BB)
        if (auto *C = dyn_cast<CallBase>(&I))
          if (const Function *H = C->getCalledFunction()) {
            if (H->isDeclaration() && H->getName().contains("longjmp"))
              return true;
            work.push_back(H);
          }
  }
  return false;
}

// Whether a call may write through its argument operand argNo, by the call's attributes: the
// parameter's readonly/readnone, and the call's memory effects on argument memory.
static bool mayWriteThroughArg(const CallBase &CB, unsigned argNo) {
  if (!CB.getArgOperand(argNo)->getType()->isPointerTy())
    return false;
  if (!isModSet(CB.getMemoryEffects().getModRef(IRMemLocation::ArgMem)))
    return false;
  return !CB.onlyReadsMemory(argNo);
}

// Rule 16, recognised by the callee's attributes and semantics, never by name: a call that may act
// on the host beyond its pointer arguments. It may write memory other than its arguments' (a
// stream, errno, a global the library owns), throw, or not return. A call whose only writes go
// through its pointer arguments (frexp, modf, remquo: memory(argmem: write)) computes into the
// caller's memory: with a quantum argument it is a declared clone (rule 27), not a tape entry.
static bool hostEffectBeyondArgs(const CallBase &CB) {
  MemoryEffects ME = CB.getMemoryEffects().getWithoutLoc(IRMemLocation::ArgMem);
  return !ME.onlyReadsMemory() || CB.mayThrow() || !CB.willReturn();
}

void Analyzer::declaredClone(CallBase &CB, Function *G, ArrayRef<Value *> actuals) {
  lift(CB, G, actuals, false);
  // Rule 27: the clone may overwrite cells of a pointee object with handles it minted (rule 3,
  // through memory and calls). With no body the cells it writes are unknown: every object a pointer
  // argument the call may write through can reach holds a handle at an unknown cell after the call.
  for (unsigned i = 0; i < actuals.size(); ++i) {
    if (!mayWriteThroughArg(CB, i))
      continue;
    PtrInfo p = P(actuals[i]);
    if (!p.init)
      continue;
    p.top = true;
    recordWrite(CB, p, 0, true, nullptr, nullptr, nullptr);
    for (unsigned s : p.sites) {
      const Site &site = st.sites[s];
      if (site.kind != SiteKind::Function && !(site.kind == SiteKind::Alloca && site.owner == cur->F))
        cur->writesOuter = true;
    }
  }
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
  auto savedIn = [&](Value *ptr) {
    uint8_t b = 0;
    if (ptr->getType()->isPointerTy())
      for (ObjectId o : objectsOf(P(ptr))) {
        auto it = st.fenvSaved.find(o);
        if (it != st.fenvSaved.end())
          b |= it->second;
      }
    return b;
  };
  auto saveTo = [&](Value *ptr, uint8_t bits) {
    if (!ptr->getType()->isPointerTy())
      return;
    for (ObjectId o : objectsOf(P(ptr))) {
      uint8_t &x = st.fenvSaved[o];
      if ((x | bits) != x) {
        x |= bits;
        touchObject();
      }
    }
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
    fenvAssign(1, rail ? 1 : (nib(fenvCur, 1) | bit(savedIn(actuals[0]) & 2)));
  } else if (cname == "fegetenv" || cname == "feholdexcept") {
    saveTo(actuals[0], now | (q ? 3 : 0));
    if (cname == "feholdexcept")
      fenvAssign(1, bit(rail));
  } else if (cname == "fesetenv" || cname == "feupdateenv") {
    // fesetenv: the state := the object's saved part; feupdateenv: MODE := its mode, FLAGS := its
    // flags | FLAGS. An object never saved (FE_DFL_ENV) has an empty part.
    uint8_t sv = savedIn(actuals[0]);
    fenvAssign(0, rail ? 1 : bit(sv & 1));
    uint8_t f = bit(sv & 2);
    if (cname == "feupdateenv")
      f |= nib(fenvCur, 1);
    fenvAssign(1, rail ? 1 : f);
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
  if (it == cur->callees.end() || it->second.empty() || cur->cutCalls.count(&CB))
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
    // Indirect call (rule 19): every candidate of the called pointer's provenance.
    Value *Callee = CB.getCalledOperand();
    PtrInfo p = P(Callee);
    SmallVector<Function *, 4> cands;
    for (unsigned s : p.sites)
      if (st.sites[s].kind == SiteKind::Function)
        cands.push_back(const_cast<Function *>(cast<Function>(st.sites[s].v)));
    if (cands.empty())
      for (Function &F : *st.M)
        if (F.hasAddressTaken() && F.getFunctionType() == CB.getFunctionType())
          cands.push_back(&F);
    if (cands.empty()) {
      // Rules 19, 27 (cq-sd95): no in-module candidate: a function outside the program. With a quantum argument
      // (a lane, or a pointee cell holding a handle) or under a quantum predicate it is the call of its
      // registered all-handles clone (clone_resolve), opaque like a declared clone: every result a handle.
      bool anyQ = blockCT(CB.getParent()) || cur->ctl;
      for (Value *A : actuals) {
        anyQ = anyQ || L(A).any();
        if (A->getType()->isPointerTy())
          for (ObjectId o : objectsOf(P(A)))
            anyQ = anyQ || st.objects[o].mayHoldHandle();
      }
      if (anyQ) {
        if (rn)
          setL(&CB, allLanes(rn));
        cur->anyQuantum = true;
        cur->hasEffect = true;   // opaque, as a declared clone (analyze)
      }
      return;
    }
    SmallVector<SpecState *, 4> all;
    bool calleeQ = L(Callee).any();
    collect = &all;
    candidateUnderQ = calleeQ;
    for (Function *C : cands)
      lift(CB, C, actuals, false);
    candidateUnderQ = false;
    collect = nullptr;
    // Keep every candidate's specialization.
    SmallVector<SpecState *, 4> uniq;
    for (SpecState *S : all)
      if (!llvm::is_contained(uniq, S))
        uniq.push_back(S);
    auto &v = cur->callees[&CB];
    if (v.size() != uniq.size() || !std::equal(v.begin(), v.end(), uniq.begin())) {
      v.assign(uniq.begin(), uniq.end());
      localChanged = true;
    }
    if (calleeQ && rn)
      setL(&CB, allLanes(rn));
    if (calleeQ)
      cur->anyQuantum = true;
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
      transferVaStart(CB);
      return;
    case Intrinsic::vacopy:
      transferVaCopy(CB);
      return;
    case Intrinsic::stacksave: {
      PtrInfo q;
      q.init = true;
      q.top = true;
      q.sites.push_back(siteFor(&CB, SiteKind::External, cur->F));
      setP(&CB, q);
      setL(&CB, Lanes(rn));
      return;
    }
    case Intrinsic::threadlocal_address:
      setP(&CB, P(actuals[0]));
      setL(&CB, L(actuals[0]));
      return;
    case Intrinsic::ptrmask: {
      setP(&CB, P(actuals[0]));
      Lanes l = L(actuals[0]);
      if (L(actuals[1]).any())
        l.set(1);
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
        if (Function *Body = st.M->getFunction(*lib); Body && !Body->isDeclaration())
          lift(CB, Body, actuals, true);
        else
          lift(CB, G, actuals, true); // declared clone named after the libm function
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
    if (CB.getType()->isPointerTy()) {
      PtrInfo e;
      e.init = true;
      e.top = true;
      e.sites.push_back(siteFor(&CB, SiteKind::External, cur->F));
      setP(&CB, e);
    }
    return;
  }
  // Allocation, deallocation (rule 16): heap objects.
  if (isAllocationFn(&CB, st.TLI.get())) {
    if (Value *Old = getReallocatedOperand(&CB)) {
      setP(&CB, P(Old));
      setL(&CB, L(Old));
      return;
    }
    PtrInfo q;
    q.init = true;
    q.sites.push_back(siteFor(&CB, SiteKind::Heap, cur->F));
    setP(&CB, q);
    setL(&CB, Lanes(rn));
    return;
  }
  if (getFreedOperand(&CB, st.TLI.get()))
    return;
  if (CB.hasFnAttr(Attribute::ReturnsTwice)) {
    // setjmp (rule 24): a longjmp under a quantum predicate makes its result an escaped flag.
    if (st.longjmpUnderQuantum && rn)
      setL(&CB, allLanes(rn));
    return;
  }
  if (CB.doesNotReturn()) {
    // abort_i1 / the longjmp flag (rules 16, 24): neither a gate nor a tape entry, so not a non-pure
    // body for rule 19.
    // cq-wskg: a defined noreturn callee that may reach longjmp (a wrapper) longjmps here too.
    if ((G->getName().contains("longjmp") || mayReachLongjmp(G)) && (blockCT(CB.getParent()) || cur->ctl) &&
        !st.longjmpUnderQuantum) {
      st.longjmpUnderQuantum = true;
      st.changed = true;
    }
    return;
  }
  if (G->getName() == "raise" && actuals.size() == 1) {
    // <signal.h>: raise(sig) runs the handler the module installed for sig (102): a call of h(sig); under a
    // quantum predicate its _ctl clone (rule 19). The candidates: the handlers of the constant sig and those
    // installed under a run-time signal number; every handler for a run-time sig.
    SmallVector<Function *, 4> cands;
    auto *Sig = dyn_cast<ConstantInt>(actuals[0]);
    for (auto &[k, hs] : signalHandlers)
      if (!Sig || k == kAnySignal || k == Sig->getSExtValue())
        for (Function *H : hs)
          if (!llvm::is_contained(cands, H))
            cands.push_back(H);
    {
      if (!cands.empty()) {
        SmallVector<SpecState *, 4> all;
        collect = &all;
        for (Function *H : cands)
          lift(CB, H, actuals, false);
        collect = nullptr;
        auto &v = cur->callees[&CB];
        if (v.size() != all.size() || !std::equal(v.begin(), v.end(), all.begin())) {
          v.assign(all.begin(), all.end());
          localChanged = true;
        }
        return;
      }
    }
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
  // A body-less callee: host effect (a library function the target knows, with side effects beyond
  // its pointer arguments when the call is quantum: hostEffectBeyondArgs), or a declared clone
  // (rule 27) when the call is quantum.
  // Darwin spells some libc symbols "\01_name" (99: fwrite, fputs): the C name is what the target
  // library knows.
  LibFunc LF;
  StringRef cname = G->getName();
  if (cname.starts_with("\x01_"))
    cname = cname.drop_front(2);
  bool known = st.TLI->getLibFunc(cname, LF);
  if (isFenvCall(cname)) {
    transferFenvCall(CB, cname, actuals, rn);
    return;
  }
  bool readNone = G->doesNotAccessMemory() || G->onlyReadsMemory();
  bool quantumCall = false;
  for (Value *A : actuals) {
    if (L(A).any())
      quantumCall = true;
    else if (A->getType()->isPointerTy())
      for (ObjectId o : objectsOf(P(A)))
        if (st.objects[o].mayHoldHandle())
          quantumCall = true;
  }
  if (known && !readNone && !(quantumCall && !hostEffectBeyondArgs(CB))) {
    cur->hasEffect = true; // tape entry (rule 16) when quantum or under a quantum predicate
    if (quantumCall)
      cur->anyQuantum = true;
    if (CB.getType()->isPointerTy()) {
      PtrInfo e;
      e.init = true;
      e.top = true;
      e.sites.push_back(siteFor(&CB, SiteKind::External, cur->F));
      setP(&CB, e);
    }
    return;
  }
  if (quantumCall) {
    declaredClone(CB, G, actuals);
    return;
  }
  if (!readNone)
    cur->hasEffect = true;
  if (CB.getType()->isPointerTy()) {
    PtrInfo e;
    e.init = true;
    e.top = true;
    e.sites.push_back(siteFor(&CB, SiteKind::External, cur->F));
    setP(&CB, e);
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
    return transferLoad(I, LI->getPointerOperand(), LI->getType());
  if (auto *SI = dyn_cast<StoreInst>(&I))
    return transferStore(I, SI->getPointerOperand(), SI->getValueOperand(),
                         SI->getValueOperand()->getType());
  if (auto *CB = dyn_cast<CallBase>(&I))
    return transferCall(*CB);
  if (auto *AI = dyn_cast<AllocaInst>(&I)) {
    PtrInfo q;
    q.init = true;
    q.sites.push_back(siteFor(AI, SiteKind::Alloca, cur->F));
    setP(AI, q);
    setL(AI, Lanes(n));
    if (anyLane(L(AI->getArraySize())))
      setL(AI, Lanes(n)); // a quantum size allocates at its upper bound: the pointer stays classical
    return;
  }
  if (isa<CmpInst>(&I) || isa<UnaryOperator>(&I) || isa<FreezeInst>(&I)) {
    bool q = false;
    for (const Use &U : I.operands())
      q = q || L(U.get()).any();
    if (auto *FI = dyn_cast<FreezeInst>(&I)) {
      setL(FI, L(FI->getOperand(0)));
      if (FI->getType()->isPointerTy())
        setP(FI, P(FI->getOperand(0)));
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
    if (EV->getType()->isPointerTy())
      setP(EV, escapedFor(EV, cur->F));
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
    transferLoad(I, RMW->getPointerOperand(), RMW->getType());
    transferStore(I, RMW->getPointerOperand(), RMW->getValOperand(), RMW->getType());
    if (L(RMW->getValOperand()).any())
      setL(&I, allLanes(n));
    return;
  }
  if (auto *CX = dyn_cast<AtomicCmpXchgInst>(&I)) {
    Type *T = CX->getNewValOperand()->getType();
    transferStore(I, CX->getPointerOperand(), CX->getNewValOperand(), T);
    PtrInfo p = P(CX->getPointerOperand());
    bool q = L(CX->getCompareOperand()).any() || L(CX->getNewValOperand()).any() ||
             L(CX->getPointerOperand()).any();
    for (ObjectId o : objectsOf(p))
      if (st.objects[o].cellHandle(p.exact(), st.DL->getTypeStoreSize(T)))
        q = true;
    if (q)
      setL(&I, allLanes(n));
    return;
  }
  if (isa<FenceInst>(&I) || isa<UnreachableInst>(&I) || isa<BranchInst>(&I) ||
      isa<SwitchInst>(&I) || isa<IndirectBrInst>(&I))
    return;
  if (auto *RI = dyn_cast<ReturnInst>(&I)) {
    if (Value *V = RI->getReturnValue()) {
      if (orInto(cur->ret, L(V)))
        st.changed = true;
      if (V->getType()->isPointerTy() && cur->retPtr.join(P(V)))
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
  // Pointer formals of an externally reachable in-place specialization point at unknown objects.
  if (S.inPlace && (!S.F->hasLocalLinkage() || S.F->hasAddressTaken()))
    for (Argument &A : S.F->args())
      if (A.getType()->isPointerTy() && A.getArgNo() < S.formalPtr.size()) {
        PtrInfo e;
        e.init = true;
        e.sites.push_back(siteFor(&A, SiteKind::External, S.F));
        if (S.formalPtr[A.getArgNo()].join(e))
          st.changed = true;
      }
  for (unsigned i = 0; i < S.formalPtr.size(); ++i)
    if (i < S.F->arg_size() && S.F->getArg(i)->getType()->isPointerTy() && !S.formalPtr[i].init) {
      // Not called yet with this key (a root): an unknown object.
      PtrInfo e;
      e.init = true;
      e.sites.push_back(siteFor(S.F->getArg(i), SiteKind::External, S.F));
      S.formalPtr[i].join(e);
    }
  unsigned rounds = 0;
  do {
    localChanged = false;
    computeCDT(S);
    computeExitQ(S);
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
    // reader's transfer does not pass operand lanes to its result (a call). A reader that computes
    // an address stays classical-offset (121). Several returns chosen by a tainted branch merge
    // their values.
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
          calleeMemo[{S->key, CB, C->F}] = CalleeMemo{C->formal, C->cells, C->ctl, C->bounds};
    }
    resetAnalysis();
    solve();
  }
  finish();
}

void Analyzer::resetAnalysis() {
  st.sites.clear();
  st.siteOf.clear();
  st.siteOfFrame.clear();
  st.objects.clear();
  st.specs.clear();
  st.byKey.clear();
  st.changed = false;
  st.longjmpUnderQuantum = false;
  st.fenvSaved.clear();
  st.escaped = PtrInfo();
  cur = nullptr;
  localChanged = false;
  fenvCur = 0;
  collect = nullptr;
  candidateUnderQ = false;
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

  // The module's signal table (rule 16): signal/bsd_signal/sigset(sig, h) with h a defined function, keyed by
  // the constant sig (kAnySignal for a run-time one); a module that calls sigaction may install any defined
  // void(int) function whose address it takes (its sa_handler), under any signal.
  bool viaSigaction = false;
  auto addHandler = [&](int64_t sig, Function *H) {
    if (!H->isDeclaration() && !llvm::is_contained(signalHandlers[sig], H))
      signalHandlers[sig].push_back(H);
  };
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (const Function *G = CB->getCalledFunction()) {
            StringRef n = G->getName();
            if (n == "sigaction")
              viaSigaction = true;
            if ((n == "signal" || n == "bsd_signal" || n == "sigset") && CB->arg_size() == 2)
            {
              // The handler operand's candidate functions (a select or phi of handlers: each arm).
              SmallVector<const Value *, 4> objs;
              getUnderlyingObjects(CB->getArgOperand(1), objs);
              auto *Sig = dyn_cast<ConstantInt>(CB->getArgOperand(0));
              for (const Value *o : objs)
                if (auto *H = dyn_cast<Function>(const_cast<Value *>(o)->stripPointerCasts()))
                  addHandler(Sig ? Sig->getSExtValue() : kAnySignal, H);
            }
          }
  if (viaSigaction)
    for (Function &H : M)
      if (!H.isDeclaration() && H.hasAddressTaken() && H.getReturnType()->isVoidTy() && H.arg_size() == 1 &&
          H.getArg(0)->getType()->isIntegerTy(32))
        addHandler(kAnySignal, &H);

  // cq-n58p, cq-erjd: module facts for lost provenance and store order.
  for (Function &F : M) {
    if (F.hasAddressTaken())
      hasIndirectCall = true;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (CB->isIndirectCall())
            hasIndirectCall = true;
          if (CB->hasFnAttr(Attribute::ReturnsTwice))
            hasReturnsTwice = true;
        }
        for (const Use &U : I.operands())
          if (auto *C = dyn_cast<Constant>(U.get()))
            escapeConstants(C);
      }
  }
  for (GlobalVariable &GV : M.globals())
    if (GV.hasInitializer())
      escapeConstants(GV.getInitializer());

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
      SpecState *R = getSpec(&F, z, tys, {}, false, false, 0, {});
      R->reachable = R->isRoot = true;
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
    SpecState *RS = getSpec(F, z, tys, {}, R.ctl, R.pure, R.depth, R.bounds);
    RS->reachable = RS->isRoot = true;
  }

  unsigned iter = 0;
  do {
    st.changed = false;
    for (size_t i = 0; i < st.specs.size(); ++i) {
      SpecState &S = *st.specs[i];
      analyze(S);
    }
    // Transitive gate facts (rule 19's non-pure test, effects).
    for (auto &S : st.specs) {
      bool np = S->hasTheta || S->hasPhi || S->hasEffect || S->writesOuter;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          np = np || C->nonPure;
      if (np != S->nonPure) {
        S->nonPure = np;
        st.changed = true;
      }
      bool ef = S->hasPhi || S->hasEffect;
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

// T4: some load or store through formal argNo (or a pointer derived from it) lies in a loop of S whose
// exit is quantum (rule 14 cutoff).
bool Analyzer::accessInQuantumExitLoop(SpecState &S, unsigned argNo) {
  if (S.declared || argNo >= S.F->arg_size() || S.exitQ.empty())
    return false;
  FnInfo &fi = fn(S.F);
  SmallVector<const Value *, 8> work{S.F->getArg(argNo)};
  SmallPtrSet<const Value *, 16> seen;
  while (!work.empty()) {
    const Value *V = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    for (const User *U : V->users()) {
      if (isa<LoadInst>(U) || isa<StoreInst>(U)) {
        for (const Loop *Lp = fi.LI->getLoopFor(cast<Instruction>(U)->getParent()); Lp; Lp = Lp->getParentLoop())
          if (S.exitQ.count(Lp))
            return true;
      } else if (isa<GetElementPtrInst>(U) || isa<PHINode>(U) || isa<SelectInst>(U) || isa<BitCastInst>(U)) {
        work.push_back(U);
      }
    }
  }
  return false;
}

// T4: the callee loads through formal argNo or a pointer derived from it.
bool Analyzer::calleeLoadsThrough(SpecState &S, unsigned argNo) {
  if (S.declared || argNo >= S.F->arg_size())
    return false;
  SmallVector<const Value *, 8> work{S.F->getArg(argNo)};
  SmallPtrSet<const Value *, 16> seen;
  while (!work.empty()) {
    const Value *V = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    for (const User *U : V->users()) {
      if (auto *LI = dyn_cast<LoadInst>(U); LI && LI->getPointerOperand() == V)
        return true;
      if (isa<GetElementPtrInst>(U) || isa<PHINode>(U) || isa<SelectInst>(U) || isa<BitCastInst>(U))
        work.push_back(U);
    }
  }
  return false;
}

bool Analyzer::calleeDerivesFat(SpecState &S, unsigned argNo) {
  if (S.declared || argNo >= S.F->arg_size())
    return false;
  SmallVector<const Value *, 8> work{S.F->getArg(argNo)};
  SmallPtrSet<const Value *, 16> seen;
  while (!work.empty()) {
    const Value *V = work.pop_back_val();
    if (!seen.insert(V).second)
      continue;
    auto it = S.lanes.find(V);
    if (it != S.lanes.end() && it->second.any())
      return true;
    for (const User *U : V->users())
      if (isa<GetElementPtrInst>(U) || isa<PHINode>(U) || isa<SelectInst>(U) || isa<BitCastInst>(U))
        work.push_back(U);
  }
  return false;
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
      const std::string &c = S.cells[i];
      bool tag = l.size() >= 2 && l.test(0), idx = l.size() >= 2 && l.test(1);
      // Fields of the naming record (see cellDigits).
      char anyD = '0';
      std::string sret;
      std::vector<std::string> objs;
      bool hasS = false;
      size_t p = 0;
      while (p < c.size()) {
        char k = c[p++];
        if (k == 'A') {
          anyD = c[p++];
        } else if (k == 'S') {
          hasS = true;
          while (p < c.size() && (c[p] == '0' || c[p] == '1'))
            sret += c[p++];
        } else if (k == 'O') {
          size_t e = c.find(';', p);
          objs.push_back(c.substr(p, e - p));
          p = e + 1;
        }
      }
      bool qramObj = false, multi = false, ptrHandles = false;
      if (i < S.formalPtr.size()) {
        auto os = objectsOf(S.formalPtr[i]);
        multi = S.formalPtr[i].sites.size() > 1;
        for (ObjectId o : os) {
          qramObj = qramObj || st.objects[o].qram;
          const Object &O = st.objects[o];
          if ((O.storedTagQ || O.storedIdxQ) && O.mayHoldHandle())
            ptrHandles = true;
        }
      }
      // A walk record (190) makes a triple only when the walk runs in a quantum-exit loop of the clone:
      // its cut trips execute the accesses whatever the program does, so they need the cell count
      // (rule 21: 'the body stays safe for any cutoff'). A walk the program itself bounds (52's
      // classical loop) stays a raw pointer.
      bool walk = false;
      for (const std::string &o : objs)
        walk = walk || (!o.empty() && o[0] == 'W');
      walk = walk && accessInQuantumExitLoop(S, i);
      bool triple = S.declared || tag || idx || qramObj || multi || ptrHandles || walk ||
                    calleeDerivesFat(S, i);
      // T4: the pointee's class over the formal's objects.
      bool anyQ = false, anyS = false, anyC = false;
      if (i < S.formalPtr.size())
        for (ObjectId o : objectsOf(S.formalPtr[i])) {
          const Object &O = st.objects[o];
          if (O.qram)
            anyQ = true;
          else if (O.mayHoldHandle())
            anyS = true;
          else
            anyC = true;
        }
      if (S.ptrFormal.size() < S.formal.size()) {
        S.ptrFormal.resize(S.formal.size(), cq::PtrFormal{cq::PtrAbi::Raw, cq::ObjClass::Classical, 0});
        S.mixedPointee.resize(S.formal.size(), false);
      }
      S.mixedPointee[i] = anyQ && (anyS || anyC);
      cq::ObjClass pointee = anyQ ? cq::ObjClass::Qram : anyS ? cq::ObjClass::Slot : cq::ObjClass::Classical;
      size_t before = m.size();
      auto noteFormal = [&](cq::PtrAbi abi) {
        S.ptrFormal[i] = cq::PtrFormal{abi, pointee, unsigned(m.size() - before)};
      };
      if (!triple) {
        // A slot pointer: one digit per field of an sret/byval record, else one per pointee cell
        // the callee accesses (106), else one for a runtime-length register (117).
        if (hasS)
          m += sret;
        else if (objs.size() == 1 && !objs[0].empty() && objs[0][0] != 'R' && objs[0][0] != 'W' && objs[0] != "Q")
          m += objs[0];
        else
          m += anyD;
        noteFormal(cq::PtrAbi::Raw);
        continue;
      }
      m += tag ? '1' : '0';
      m += idx ? '1' : '0';
      // Rule 21: the object's cell count follows the triple when the callee loads through it from a
      // slot or host object (a QRAM reads 0 out of range by §2); rule 27 always passes it.
      bool count = S.declared || (pointee != cq::ObjClass::Qram && calleeLoadsThrough(S, i));
      if (S.declared) {
        m += anyD;
        noteFormal(cq::PtrAbi::TripleCount);
        continue;
      }
      for (const std::string &o : objs) {
        if (o == "Q")
          continue;
        if (!o.empty() && o[0] == 'W' && !walk)
          m += anyD;
        else if (!o.empty() && (o[0] == 'R' || o[0] == 'W'))
          m += o.substr(1);
        else
          m += o;
      }
      noteFormal(count ? cq::PtrAbi::TripleCount : cq::PtrAbi::Triple);
      continue;
    }
    if (auto *IT = dyn_cast<IntegerType>(T)) {
      if (i < S.F->arg_size() && !S.declared) {
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
  // Twins: a call whose quantum result is consumed by something other than a measurement (rule 18);
  // a declared clone always has one (rule 27).
  for (auto &S : st.specs) {
    if (!S->reachable)
      continue;
    for (auto &[CB, v] : S->callees) {
      if (CB->getType()->isVoidTy())
        continue;
      auto it = S->lanes.find(CB);
      if (it == S->lanes.end() || it->second.none())
        continue;
      bool other = false;
      for (const User *U : CB->users()) {
        if (auto *UC = dyn_cast<CallBase>(U))
          if (isMeasure(UC->getCalledFunction()))
            continue;
        if (isa<ReturnInst>(U) && S->inPlace)
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
          C->needsTwin = true;
    }
  }
  // _pure: what a twin recomputes through when the callee has effects (119).
  std::vector<SpecState *> pureNeeded;
  {
    SmallPtrSet<SpecState *, 16> seen;
    SmallVector<SpecState *, 16> w;
    for (auto &S : st.specs) {
      // cq-s2zz (rule 18): an effectful clone whose own result needs its twin recomputes through its _pure.
      if (S->reachable && S->needsTwin && S->effectful && !S->declared && !S->inPlace)
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
  for (auto &S : st.specs) {
    if (!S->reachable)
      continue;
    S->mask = buildMask(*S);
  }
  auto publish = [&](SpecState *S, bool pure) {
    Specialization P;
    P.F = S->F;
    P.mask = S->mask;
    P.ctl = S->ctl;
    P.pure = pure;
    P.depth = S->depth;
    P.bounds = S->bounds;
    P.boundFormals = S->boundFormals;
    st.published.push_back(P);
    st.publishedState.push_back(S);
  };
  for (auto &S : st.specs) {
    if (!S->reachable)
      continue;
    if (S->inPlace) {
      bool tainted = S->anyQuantum;
      for (auto &[CB, v] : S->callees)
        for (SpecState *C : v)
          if (!C->inPlace)
            tainted = true;
      if (!S->cutCalls.empty())
        tainted = true;
      if (!tainted)
        continue;
    }
    publish(S.get(), false);
    st.tainted.insert(S->F);
  }
  for (SpecState *S : pureNeeded)
    if (S->reachable && !S->inPlace)
      publish(S, true);
}

} // namespace cq::taintimpl

// =============================================================================================
// Public interface.

namespace cq {
using namespace taintimpl;

bool Specialization::isEntry() const {
  if (!F || F->isDeclaration() || ctl || pure || depth || !bounds.empty() || kept)
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
  // A kept clone (cq-i9wk) is answered by the in-place specialization of its F: kept is not compared.
  for (size_t k = 0; k < I.published.size(); ++k) {
    const Specialization &P = I.published[k];
    if (P.F == S.F && P.mask == S.mask && P.ctl == S.ctl && P.pure == S.pure &&
        P.depth == S.depth && P.bounds == S.bounds && P.boundFormals == S.boundFormals)
      return I.publishedState[k];
  }
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

bool TaintInfo::isQuantum(const llvm::Value *V, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  return lanesOfValue(I, *stateOf(I, S), V).any();
}

llvm::SmallVector<bool, 4> TaintInfo::fieldMask(const llvm::Value *V, const Specialization &S) const {
  // One entry per scalar leaf of V's type (an aggregate's fields, a vector's lanes; a pointer is one
  // leaf, quantum when its tag or idx is).
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
      else if (T->isPointerTy())
        n = 2;
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
        unsigned n = T->isIntegerTy() ? std::max(1u, (T->getIntegerBitWidth() + 7) / 8)
                                      : T->isPointerTy() ? 2 : 1;
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
const llvm::Value *objectSiteValue(const llvm::Value *site) {
  // Rule 24, 108: one thread, so llvm.threadlocal.address(@g) is the base of @g's one object (a
  // classical host intrinsic returning the object's address; its provenance is @g's).
  if (auto *TL = dyn_cast<llvm::IntrinsicInst>(site);
      TL && TL->getIntrinsicID() == llvm::Intrinsic::threadlocal_address)
    site = TL->getArgOperand(0)->stripPointerCasts();
  return site;
}
ObjectId soleObjectOfSite(const ImplState &I, unsigned id, const llvm::Value *site) {
  const Site &s = I.sites[id];
  if (s.objects.size() != 1)
    internalError("taint: an array-of-structs site is one object per field column; use provenance",
                  site);
  return s.objects.front();
}
} // namespace

ObjectId TaintInfo::objectOf(const llvm::Value *site) const {
  const ImplState &I = needImpl(impl);
  site = objectSiteValue(site);
  std::optional<unsigned> found;
  auto note = [&](unsigned id) {
    if (found && *found != id)
      internalError("taint: a site of several activations (clones of its function); use objectOf(site, S)", site);
    found = id;
  };
  if (auto it = I.siteOf.find(site); it != I.siteOf.end())
    note(it->second);
  for (const auto &[SS, m] : I.siteOfFrame)
    if (auto it = m.find(site); it != m.end())
      note(it->second);
  if (!found)
    internalError("taint: not a memory site of this module", site);
  return soleObjectOfSite(I, *found, site);
}

ObjectId TaintInfo::objectOf(const llvm::Value *site, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  site = objectSiteValue(site);
  // cq-i9wk, cq-1c5j: a site of S's own activation is S's frame.
  if (auto fr = I.siteOfFrame.find(stateOf(I, S)); fr != I.siteOfFrame.end())
    if (auto ip = fr->second.find(site); ip != fr->second.end())
      return soleObjectOfSite(I, ip->second, site);
  auto it = I.siteOf.find(site);
  if (it == I.siteOf.end())
    internalError("taint: not a memory site of this module", site);
  return soleObjectOfSite(I, it->second, site);
}

bool TaintInfo::uniformCells(ObjectId id) const {
  const ImplState &I = needImpl(impl);
  if (id >= I.objects.size())
    internalError("taint: unknown object id");
  const Object &O = I.objects[id];
  const Site &site = I.sites[O.site];
  if (O.column >= 0 || site.stride)
    return true;   // one field column of an array of structs: one scalar per element (rule 20)
  llvm::Type *ty = nullptr;
  if (auto *AI = dyn_cast<llvm::AllocaInst>(site.v))
    ty = AI->getAllocatedType();
  else if (auto *GV = dyn_cast<llvm::GlobalVariable>(site.v))
    ty = GV->getValueType();
  else if (auto *AR = dyn_cast<llvm::Argument>(site.v); AR && (AR->hasByValAttr() || AR->hasStructRetAttr()))
    ty = AR->hasByValAttr() ? AR->getParamByValType() : AR->getParamStructRetType();
  while (ty && (ty->isArrayTy() || ty->isVectorTy()))
    ty = ty->isArrayTy() ? ty->getArrayElementType() : cast<llvm::VectorType>(ty)->getElementType();
  return !ty || !ty->isStructTy();
}

ObjClass TaintInfo::classOf(ObjectId id) const {
  const ImplState &I = needImpl(impl);
  if (id >= I.objects.size())
    internalError("taint: unknown object id");
  const Object &O = I.objects[id];
  if (O.qram)
    return ObjClass::Qram;
  if (O.mayHoldHandle())
    return ObjClass::Slot;
  return ObjClass::Classical;
}

bool TaintInfo::mayHoldHandle(ObjectId id) const {
  const ImplState &I = needImpl(impl);
  if (id >= I.objects.size())
    internalError("taint: unknown object id");
  return I.objects[id].mayHoldHandle();
}

static const llvm::Value *accessPointer(const llvm::Instruction *I, bool *isMemIntr) {
  *isMemIntr = false;
  if (auto *L = dyn_cast<llvm::LoadInst>(I))
    return L->getPointerOperand();
  if (auto *S = dyn_cast<llvm::StoreInst>(I))
    return S->getPointerOperand();
  if (auto *R = dyn_cast<llvm::AtomicRMWInst>(I))
    return R->getPointerOperand();
  if (auto *X = dyn_cast<llvm::AtomicCmpXchgInst>(I))
    return X->getPointerOperand();
  if (auto *M = dyn_cast<llvm::MemIntrinsic>(I)) {
    *isMemIntr = true;
    return M->getRawDest();
  }
  internalError("taint: offsetKind of an instruction that is not a memory access", I);
}

OffsetKind TaintInfo::offsetKind(const llvm::Instruction *access, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, S);
  bool mi = false;
  const llvm::Value *p = accessPointer(access, &mi);
  Lanes l = lanesOfValue(I, *SS, p);
  bool q = l.size() >= 2 && l.test(1);
  if (mi)
    if (auto *MT = dyn_cast<llvm::MemTransferInst>(access)) {
      Lanes s = lanesOfValue(I, *SS, MT->getRawSource());
      q = q || (s.size() >= 2 && s.test(1));
    }
  return q ? OffsetKind::Quantum : OffsetKind::Classical;
}

namespace {
SmallVector<ObjectId, 4> objectsFor(const ImplState &I, const PtrInfo &p) {
  SmallVector<ObjectId, 4> out;
  for (unsigned s : p.sites) {
    const Site &site = I.sites[s];
    if (site.kind == SiteKind::Function)
      continue;
    if (!site.stride) {
      out.push_back(site.objects.front());
      continue;
    }
    if (auto m = p.mod(site.stride)) {
      for (unsigned c = site.columns.size(); c-- > 0;)
        if (site.columns[c] <= *m) {
          out.push_back(site.objects[c]);
          break;
        }
      continue;
    }
    out.append(site.objects.begin(), site.objects.end());
  }
  return out;
}

const PtrInfo &ptrOrDie(const ImplState &I, const SpecState &SS, const llvm::Value *V,
                        PtrInfo &tmp) {
  auto it = SS.ptr.find(V);
  if (it != SS.ptr.end())
    return it->second;
  if (auto *A = dyn_cast<llvm::Argument>(V))
    if (A->getParent() == SS.F && A->getArgNo() < SS.formalPtr.size())
      return SS.formalPtr[A->getArgNo()];
  if (auto *C = dyn_cast<llvm::Constant>(V)) {
    llvm::APInt off(64, 0);
    const llvm::Value *base =
        C->stripAndAccumulateConstantOffsets(I.M->getDataLayout(), off, true);
    tmp = PtrInfo();
    tmp.init = true;
    tmp.c = off.getSExtValue();
    auto sit = I.siteOf.find(base);
    if (sit != I.siteOf.end())
      tmp.sites.push_back(sit->second);
    return tmp;
  }
  internalError("taint: no provenance answer for this pointer (cq-5k5)", V);
}
} // namespace

// T2 (cq-arch 2026-11-01; CR rules 18, 20): the cells of the object formal argNo points to that the
// clone S may store a handle into, ascending. A store through the formal (constant offsets from it)
// writes a handle when the cell is a slot cell of the pointee (rule 20 homogeneity: a classical value
// becomes a seed rail), or when its value, its address or its block's control is quantum, or S is _ctl
// (as transferStore records it). The cell index is the byte offset from the object's root over the
// store's size. Unimplemented: a write through the formal at a variable offset, by a memory
// intrinsic, an atomic or a call, an escape of the formal, a pointee offset that differs between the
// callers, stores of several sizes, or an offset that is not a multiple of the size.
namespace {
// The load L when SI stores back a chain of cq_theta of a load of the cell it stores to: a rotation
// of the rail the cell holds, in place (124's step: *r = cq_theta(*r); 61's prep: the second
// *x = cq_theta(*x) forwarded by -O1 as cq_theta(cq_theta(load)), cq-kwmu). The handle stored is L's.
const llvm::LoadInst *inPlaceRoot(const llvm::StoreInst *SI, bool bools = false) {
  const llvm::Value *V = SI->getValueOperand();
  // bools (T2 at a variable offset, 117): also a _Bool cell's round trip, zext i1 -> i8 of the rotation of
  // the trunc i8 -> i1 of its load (the i1 rail's view).
  bool boolView = false;
  if (auto *Z = dyn_cast<llvm::ZExtInst>(V); bools && Z && Z->getSrcTy()->isIntegerTy(1)) {
    V = Z->getOperand(0);
    boolView = true;
  }
  bool rotated = false;
  for (unsigned depth = 0; depth < 64; ++depth) {
    auto *C = dyn_cast<llvm::CallInst>(V);
    const llvm::Function *G = C ? C->getCalledFunction() : nullptr;
    if (!G || !G->getName().starts_with("cq_theta_") || C->arg_size() < 1)
      break;
    rotated = true;
    V = C->getArgOperand(0);
  }
  if (boolView) {
    auto *Tr = dyn_cast<llvm::TruncInst>(V);
    if (!Tr || !Tr->getDestTy()->isIntegerTy(1))
      return nullptr;
    V = Tr->getOperand(0);
  }
  auto *L = dyn_cast<llvm::LoadInst>(V);
  if (!rotated || !L || L->getPointerOperand() != SI->getPointerOperand() ||
      L->getType() != SI->getValueOperand()->getType())
    return nullptr;
  return L;
}

// The key of a clone in ImplState::pastPointee: its function and taint mask (the formal's objects follow them).
std::string pastKey(const Specialization &S) {
  return S.F->getName().str() + "|" + std::string(S.mask) + (S.ctl ? "c" : "") + (S.pure ? "p" : "") + "|" + std::to_string(S.depth);
}

// T2 cellsWritten (rotated = false) and T3 cellsRotated (rotated = true): one walk over the formal.
llvm::SmallVector<unsigned, 4> formalCells(const ImplState &I, const TaintInfo &T, const Specialization &S,
                                           unsigned argNo, bool rotated) {
  SpecState *SS = stateOf(I, S);
  llvm::Function *F = SS->F;
  if (argNo >= F->arg_size() || !F->getArg(argNo)->getType()->isPointerTy())
    return {};
  const llvm::Argument *A = F->getArg(argNo);
  const llvm::DataLayout &DL = F->getDataLayout();
  PtrInfo tmp;
  const PtrInfo &fp = ptrOrDie(I, *SS, A, tmp);
  SmallVector<ObjectId, 4> objs = objectsFor(I, fp);
  auto refuse = [&](const llvm::Twine &why, const llvm::Value *at) {
    unimplemented(("taint: " + llvm::Twine(rotated ? "cellsRotated" : "cellsWritten") + ": " + why +
                   (rotated ? " (T3, a clone's rotations through a pointer formal)"
                            : " (T2, a clone's writes through a pointer formal)"))
                      .str(),
                  at);
  };
  // A write through the formal: a store (st) in SS or, through the formal handed on to a call (cq-1c5j: musl's
  // frexp hands its int *e to its own recursive call; 31/163's slot parameter), in a callee's specialization ss;
  // or a memory intrinsic or an atomic writing the cells (rules 22, 24), `handle` deciding it.
  struct W { int64_t off; uint64_t size; const llvm::StoreInst *st; const SpecState *ss = nullptr; bool handle = false;
             const llvm::Instruction *at = nullptr; };
  SmallVector<W, 4> writes;
  SmallVector<const llvm::StoreInst *, 2> varInPlace;   // T2: in-place round trips at a variable offset
  // cq-ee23: every value derived from the formal is followed: pointers (GEP, casts, freeze, phi,
  // select), the integers ptrtoint makes of them (a constant add or sub keeps the offset, any other
  // arithmetic makes it variable) and the pointers inttoptr makes back, and aggregates holding it (the
  // index path where it sits). Only a load, a comparison or a return ends a path; a store of a derived
  // value or a call taking one is the escape, unimplemented.
  struct Item { const llvm::Value *v; std::optional<int64_t> off; SmallVector<unsigned, 2> path;
                const SpecState *ss = nullptr; };
  SmallVector<Item, 8> work{{A, 0, {}, SS}};
  std::set<std::tuple<const llvm::Value *, SmallVector<unsigned, 2>, const SpecState *>> seen;
  // A callee's formal reached at two offsets (a recursion advancing the pointer) is walked at an unknown one.
  std::map<std::pair<const llvm::Value *, const SpecState *>, std::optional<int64_t>> formalOff;
  auto blockCT = [](const SpecState *ss, const llvm::BasicBlock *BB) {
    auto it = ss->cdt.find(BB);
    return it != ss->cdt.end() && !it->second.empty();
  };
  auto isPrefix = [](llvm::ArrayRef<unsigned> a, llvm::ArrayRef<unsigned> b) {
    return a.size() <= b.size() && std::equal(a.begin(), a.end(), b.begin());
  };
  while (!work.empty()) {
    Item it = work.pop_back_val();
    const llvm::Value *V = it.v;
    std::optional<int64_t> off = it.off;
    const SpecState *ss = it.ss;
    if (!seen.insert({V, it.path, ss}).second)
      continue;
    for (const llvm::User *U : V->users()) {
      if (!it.path.empty()) {
        // V is an aggregate holding the formal (or a value derived from it) at it.path.
        if (auto *EV = dyn_cast<llvm::ExtractValueInst>(U)) {
          llvm::ArrayRef<unsigned> ix = EV->getIndices();
          if (isPrefix(ix, it.path))
            work.push_back({U, off, SmallVector<unsigned, 2>(it.path.begin() + ix.size(), it.path.end()), ss});
          else if (!isPrefix(it.path, ix))
            continue; // another field
          else
            refuse("a field inside the formal's slot of an aggregate", U);
        } else if (auto *IV = dyn_cast<llvm::InsertValueInst>(U); IV && IV->getAggregateOperand() == V) {
          if (!isPrefix(IV->getIndices(), it.path))
            work.push_back({U, off, it.path, ss});
          // else: the formal's slot is overwritten
          if (IV->getInsertedValueOperand() == V)
            refuse("an aggregate holding the formal inserted into itself", U);
        } else if (auto *IV2 = dyn_cast<llvm::InsertValueInst>(U)) {
          SmallVector<unsigned, 2> p(IV2->getIndices().begin(), IV2->getIndices().end());
          p.append(it.path.begin(), it.path.end());
          work.push_back({U, off, p, ss});
        } else if (isa<llvm::PHINode>(U) || isa<llvm::SelectInst>(U) || isa<llvm::FreezeInst>(U)) {
          if (auto *Sel = dyn_cast<llvm::SelectInst>(U); Sel && Sel->getCondition() == V)
            continue;
          work.push_back({U, std::nullopt, it.path, ss});
        } else if (isa<llvm::ReturnInst>(U)) {
          continue;
        } else {
          refuse("an aggregate holding the formal escapes (stored, passed or reinterpreted)", U);
        }
        continue;
      }
      if (auto *GEP = dyn_cast<llvm::GEPOperator>(U)) {
        llvm::APInt o(64, 0);
        if (off && GEP->getPointerOperand() == V && GEP->accumulateConstantOffset(DL, o))
          work.push_back({GEP, *off + o.getSExtValue(), {}, ss});
        else
          work.push_back({GEP, std::nullopt, {}, ss});
      } else if (isa<llvm::BitCastOperator>(U) || isa<llvm::AddrSpaceCastOperator>(U) ||
                 isa<llvm::FreezeInst>(U) || isa<llvm::PtrToIntOperator>(U) ||
                 (isa<llvm::Operator>(U) && cast<llvm::Operator>(U)->getOpcode() == llvm::Instruction::IntToPtr)) {
        work.push_back({U, off, {}, ss});
      } else if (auto *BO = dyn_cast<llvm::BinaryOperator>(U)) {
        // An integer made from the formal's address.
        std::optional<int64_t> o2;
        const llvm::Value *other = BO->getOperand(0) == V ? BO->getOperand(1) : BO->getOperand(0);
        auto *C = dyn_cast<llvm::ConstantInt>(other);
        bool disjointOr = BO->getOpcode() == llvm::Instruction::Or && cast<llvm::PossiblyDisjointInst>(BO)->isDisjoint();
        if (off && C && C->getBitWidth() <= 64 &&
            (BO->getOpcode() == llvm::Instruction::Add || disjointOr))
          o2 = *off + C->getSExtValue();
        else if (off && C && C->getBitWidth() <= 64 && BO->getOpcode() == llvm::Instruction::Sub &&
                 BO->getOperand(0) == V)
          o2 = *off - C->getSExtValue();
        work.push_back({U, o2, {}, ss});
      } else if (auto *IV = dyn_cast<llvm::InsertValueInst>(U)) {
        if (IV->getInsertedValueOperand() == V)
          work.push_back({U, off, SmallVector<unsigned, 2>(IV->getIndices().begin(), IV->getIndices().end()), ss});
        else
          refuse("an aggregate built over a value derived from the formal", U);
      } else if (isa<llvm::LoadInst>(U) || isa<llvm::ICmpInst>(U) || isa<llvm::ReturnInst>(U)) {
        continue;
      } else if (auto *SI = dyn_cast<llvm::StoreInst>(U)) {
        if (SI->getPointerOperand() != V)
          refuse("the formal escapes into memory", SI);
        if (!V->getType()->isPointerTy())
          internalError("taint: cellsWritten: a store through a non-pointer", SI);
        if (!off) {
          // 117: T2 at a variable offset: a store back of a rotation of the cell's own quantum load (an
          // in-place cq_theta on a runtime-indexed cell) leaves the handle in the cell; allowed when every
          // write through the formal is such a round trip (checked below).
          // T3 (cq-budv, 117): such a round trip rotates the rail of whichever cell the offset names at
          // run time: any cell (kAnyCell).
          const llvm::LoadInst *r = inPlaceRoot(SI, true);
          if (!r || !lanesOfValue(I, *ss, r).any())
            refuse("a store through the formal at a variable offset", SI);
          varInPlace.push_back(SI);
          continue;
        }
        writes.push_back({*off, DL.getTypeStoreSize(SI->getValueOperand()->getType()), SI, ss});
      } else if (auto *II = dyn_cast<llvm::IntrinsicInst>(U); II && II->isLifetimeStartOrEnd()) {
        continue;
      } else if (auto *Sel = dyn_cast<llvm::SelectInst>(U); Sel && Sel->getCondition() == V) {
        continue; // the formal decides, its value does not flow
      } else if (isa<llvm::SelectInst>(U) || isa<llvm::PHINode>(U)) {
        work.push_back({U, std::nullopt, {}, ss});
      } else if (auto *Ins = dyn_cast<llvm::Instruction>(U);
                 Ins && !Ins->mayWriteToMemory() && !isa<llvm::CallBase>(Ins) && !Ins->getType()->isVoidTy()) {
        work.push_back({U, std::nullopt, {}, ss}); // any other value computed from it (casts, arithmetic)
      } else if (auto *MI = dyn_cast<llvm::MemIntrinsic>(U)) {
        // Rule 22: a memory intrinsic writes the destination's cells; reading through the formal writes none.
        if (MI->getRawDest() != V)
          continue;
        auto *len = dyn_cast<llvm::ConstantInt>(MI->getLength());
        if (!off || !len)
          refuse("a memory intrinsic through the formal at a variable offset or of a run-time length", U);
        bool h = ss->ctl || blockCT(ss, MI->getParent()) || lanesOfValue(I, *ss, MI->getLength()).any() ||
                 lanesOfValue(I, *ss, MI->getRawDest()).any();
        if (auto *MS = dyn_cast<llvm::MemSetInst>(MI))
          h = h || lanesOfValue(I, *ss, MS->getValue()).any();
        if (auto *MT = dyn_cast<llvm::MemTransferInst>(MI)) {
          PtrInfo t2;
          const PtrInfo &sp = ptrOrDie(I, *ss, MT->getRawSource(), t2);
          h = h || lanesOfValue(I, *ss, MT->getRawSource()).any();
          for (ObjectId o : objectsFor(I, sp))
            h = h || I.objects[o].mayHoldHandle();
        }
        if (len->getZExtValue())
          writes.push_back({*off, len->getZExtValue(), nullptr, ss, h, MI});
      } else if (isa<llvm::AtomicRMWInst>(U) || isa<llvm::AtomicCmpXchgInst>(U)) {
        // Rule 24: an atomic is a read and a write of its cell.
        auto *RMW = dyn_cast<llvm::AtomicRMWInst>(U);
        auto *CX = dyn_cast<llvm::AtomicCmpXchgInst>(U);
        const llvm::Value *ptr = RMW ? RMW->getPointerOperand() : CX->getPointerOperand();
        if (ptr != V)
          refuse("the formal escapes into memory through an atomic", U);
        if (!off)
          refuse("an atomic through the formal at a variable offset", U);
        const llvm::Value *val = RMW ? RMW->getValOperand() : CX->getNewValOperand();
        bool h = ss->ctl || blockCT(ss, cast<llvm::Instruction>(U)->getParent()) ||
                 lanesOfValue(I, *ss, val).any() || lanesOfValue(I, *ss, ptr).any() ||
                 (CX && lanesOfValue(I, *ss, CX->getCompareOperand()).any());
        writes.push_back({*off, DL.getTypeStoreSize(val->getType()), nullptr, ss, h, cast<llvm::Instruction>(U)});
      } else if (auto *CB = dyn_cast<llvm::CallBase>(U); CB && CB->getCalledFunction() &&
                                                       !CB->getCalledFunction()->isDeclaration() &&
                                                       !isa<llvm::IntrinsicInst>(CB)) {
        // Rule 18: the formal handed on to a call of a function with a body: the callee's writes through its
        // own formal are this clone's, at the same cells (the specialization the call takes in ss).
        if (CB->getCalledOperand() == V)
          refuse("a call through the formal", U);
        if (ss->cutCalls.count(CB))
          continue;   // rule 14: a depth-recursion call past the cutoff runs nothing (its result is |0>)
        auto cit = ss->callees.find(CB);
        if (cit == ss->callees.end() || cit->second.empty())
          refuse("a call handed the formal that taint did not lift", U);
        for (unsigned j = 0; j < CB->arg_size(); ++j) {
          if (CB->getArgOperand(j) != V)
            continue;
          for (const SpecState *C : cit->second) {
            if (C->declared || j >= C->F->arg_size())
              refuse("the formal handed to a function with no body", U);
            const llvm::Argument *CA = C->F->getArg(j);
            auto [fo, fresh] = formalOff.try_emplace({CA, C}, off);
            std::optional<int64_t> at = off;
            if (!fresh && fo->second != off) {
              if (fo->second) {
                fo->second = std::nullopt;
                seen.erase({CA, SmallVector<unsigned, 2>{}, C});
              }
              at = std::nullopt;
            }
            work.push_back({CA, at, {}, C});
          }
        }
      } else {
        refuse("a write through the formal by a call of a function with no body or through a pointer", U);
      }
    }
  }
  // cq-lv9a: a cell is a scalar leaf of the pointee object's C type (an int[4] has four 4-byte cells,
  // a struct one cell per scalar field at its offset); a store names every cell it overlaps. In every object
  // the formal may point to it names the same cell indices. An object with no C type (a heap block) falls back
  // to cells of the store size (all stores of one size, at multiples of it).
  // Each object's leaves; objects of different layouts name a written byte range by their own indices,
  // which must agree for every write (a readonly formal over tables of different lengths names none: musl
  // __polevll's coefficient arrays).
  std::vector<std::vector<Range>> objLeaves;
  bool typed = !objs.empty();
  for (ObjectId o : objs) {
    const Site &site = I.sites[I.objects[o].site];
    llvm::Type *ty = nullptr;
    if (auto *AI = dyn_cast<llvm::AllocaInst>(site.v); AI && !AI->isArrayAllocation())
      ty = AI->getAllocatedType();
    else if (auto *GV = dyn_cast<llvm::GlobalVariable>(site.v))
      ty = GV->getValueType();
    else if (auto *AR = dyn_cast<llvm::Argument>(site.v); AR && (AR->hasByValAttr() || AR->hasStructRetAttr()))
      ty = AR->hasByValAttr() ? AR->getParamByValType() : AR->getParamStructRetType();
    if (!ty || site.stride != 0) {
      typed = false;
      break;
    }
    std::vector<Range> lv;
    std::function<void(llvm::Type *, int64_t)> walk = [&](llvm::Type *t, int64_t at) {
      if (auto *ST = dyn_cast<llvm::StructType>(t)) {
        const llvm::StructLayout *SL = DL.getStructLayout(ST);
        for (unsigned k = 0; k < ST->getNumElements(); ++k)
          walk(ST->getElementType(k), at + int64_t(SL->getElementOffset(k)));
      } else if (auto *AT = dyn_cast<llvm::ArrayType>(t)) {
        uint64_t es = DL.getTypeAllocSize(AT->getElementType());
        for (uint64_t k = 0; k < AT->getNumElements(); ++k)
          walk(AT->getElementType(), at + int64_t(k * es));
      } else if (auto *VT = dyn_cast<llvm::FixedVectorType>(t)) {
        uint64_t es = DL.getTypeAllocSize(VT->getElementType());
        for (unsigned k = 0; k < VT->getNumElements(); ++k)
          walk(VT->getElementType(), at + int64_t(k * es));
      } else {
        lv.push_back({at, DL.getTypeStoreSize(t)});
      }
    };
    walk(ty, 0);
    objLeaves.push_back(std::move(lv));
  }
  if (!typed)
    objLeaves.clear();
  // The cells of every object a write of [at, at + size) overlaps, as indices; the same in every object.
  auto overlapped = [&](int64_t at, uint64_t sz, const llvm::Value *where) {
    std::optional<SmallVector<unsigned, 4>> agreed;
    for (const std::vector<Range> &lv : objLeaves) {
      SmallVector<unsigned, 4> ks;
      for (unsigned k = 0; k < lv.size(); ++k)
        if (at < lv[k].off + int64_t(lv[k].size) && lv[k].off < at + int64_t(sz))
          ks.push_back(k);
      if (ks.empty())
        continue;   // past this object's cells: undefined where it runs, no cell of it
      if (agreed && *agreed != ks)
        refuse("a write naming different cells of pointee objects of different layouts", where);
      agreed = std::move(ks);
    }
    return agreed.value_or(SmallVector<unsigned, 4>{});
  };
  // A round trip at a variable offset may hit any cell: every other write must be a round trip too (each
  // then stores back the handle the cell holds, so no cell's handle changes).
  if (!varInPlace.empty())
    for (const W &w : writes) {
      const llvm::LoadInst *r = w.st ? inPlaceRoot(w.st, true) : nullptr;
      if (!r || !lanesOfValue(I, *w.ss, r).any())
        refuse("a store through the formal beside an in-place rotation at a variable offset", w.st ? w.st : w.at);
    }
  if (rotated && !varInPlace.empty())
    return {TaintInfo::kAnyCell};
  SmallVector<unsigned, 4> out;
  uint64_t size = 0;
  for (const W &w : writes) {
    std::optional<int64_t> base = fp.exact();
    // A store past every cell of every object the formal may point to is undefined where it runs (an access
    // past an object, outside the domain): it writes no cell (rule 21; mem-slots lowers it as nothing). musl
    // __rem_pio2_large's y[1], y[2] for prec 0 into __rem_pio2f's double ty[1] (cq-4e6m). A write of a callee
    // the formal is handed to is that callee's own (its formalCells records it).
    if (typed && base && overlapped(*base + w.off, w.size, w.st ? (const llvm::Value *)w.st : w.at).empty()) {
      if (w.st && w.ss == SS)
        I.pastPointee.insert({pastKey(S), w.st});
      continue;
    }
    bool handle = w.st ? w.ss->ctl || lanesOfValue(I, *w.ss, w.st->getValueOperand()).any() ||
                             lanesOfValue(I, *w.ss, w.st->getPointerOperand()).any() || blockCT(w.ss, w.st->getParent())
                       : w.handle;
    for (ObjectId o : objs)
      if (I.objects[o].cellHandle(base ? std::optional<int64_t>(*base + w.off) : std::nullopt, w.size))
        handle = true;
    // T3: a store of a rotation of the cell's loaded rail is the rotated cell (the gate acts on the rail
    // the cell held at the load; a classical value loaded is minted instead, a write). T2: it is no handle write when every write of the cell stores back
    // the handle of the same load of it (the load precedes them all: they store its value), so the cell
    // holds that handle throughout; otherwise it writes the handle back over another (cq-kwmu).
    // A rotation of a classical cell's value mints a rail (rule 2): a handle write, never in place.
    const llvm::LoadInst *root = w.st ? inPlaceRoot(w.st) : nullptr;
    if (root && !lanesOfValue(I, *w.ss, root).any())
      root = nullptr;
    bool inPlace = root && all_of(writes, [&](const W &o) {
      return o.off + int64_t(o.size) <= w.off || w.off + int64_t(w.size) <= o.off ||
             (o.off == w.off && o.size == w.size && o.st && inPlaceRoot(o.st) == root);
    });
    if (rotated ? !root : inPlace)
      continue;
    if (!handle && !rotated)
      continue;
    if (!base)
      refuse("a pointee offset that differs between the clone's callers", w.st ? w.st : w.at);
    if (typed) {
      SmallVector<unsigned, 4> ks = overlapped(*base + w.off, w.size, w.st ? (const llvm::Value *)w.st : w.at);
      for (unsigned k : ks)
        if (!is_contained(out, k))
          out.push_back(k);
      if (ks.empty())
        internalError("taint: formalCells: a store past the pointee's cells reached the cell count", w.st ? w.st : w.at);
      continue;
    }
    if (size && w.size != size)
      refuse("stores of several sizes through the formal", w.st ? w.st : w.at);
    size = w.size;
    int64_t at = *base + w.off;
    if (at < 0 || !size || at % int64_t(size))
      refuse("a store at an offset that is not a multiple of its size", w.st ? w.st : w.at);
    unsigned cell = unsigned(at / int64_t(size));
    if (!is_contained(out, cell))
      out.push_back(cell);
  }
  llvm::sort(out);
  return out;
}
} // namespace

llvm::SmallVector<unsigned, 4> TaintInfo::cellsWritten(const Specialization &S, unsigned argNo) const {
  return formalCells(needImpl(impl), *this, S, argNo, false);
}

bool TaintInfo::writesPastPointee(const Specialization &S, unsigned argNo, const llvm::StoreInst &st) const {
  const ImplState &I = needImpl(impl);
  formalCells(I, *this, S, argNo, false);
  return I.pastPointee.count({pastKey(S), &st}) != 0;
}

// T5 (109): see Taint.h. Structural over the clone's body; the narrow shape only.
int TaintInfo::cellForward(const Specialization &S, unsigned argNo, unsigned cell) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, S);
  llvm::Function *F = SS->F;
  if (S.ctl || F->isDeclaration() || argNo >= F->arg_size() ||
      !F->getArg(argNo)->getType()->isPointerTy())
    return -1;
  const llvm::Argument *A = F->getArg(argNo);
  const llvm::DataLayout &DL = F->getDataLayout();
  const llvm::StoreInst *only = nullptr;
  int64_t onlyOff = 0;
  // Every use of A: a store through A (or a constant GEP of it, used only by stores and loads), or a load.
  SmallVector<std::pair<const llvm::Value *, int64_t>, 4> ptrs{{A, 0}};
  for (unsigned k = 0; k < ptrs.size(); ++k) {
    auto [P, off] = ptrs[k];
    for (const llvm::User *U : P->users()) {
      if (auto *L = dyn_cast<llvm::LoadInst>(U); L && L->getPointerOperand() == P && L->isSimple())
        continue;
      if (auto *St = dyn_cast<llvm::StoreInst>(U); St && St->getPointerOperand() == P && St->isSimple() &&
                                                    St->getValueOperand() != P) {
        if (only)
          return -1;
        only = St;
        onlyOff = off;
        continue;
      }
      if (auto *G = dyn_cast<llvm::GetElementPtrInst>(U); G && G->getPointerOperand() == P) {
        llvm::APInt o(64, 0);
        if (!G->accumulateConstantOffset(DL, o))
          return -1;
        ptrs.push_back({G, off + o.getSExtValue()});
        continue;
      }
      return -1;
    }
  }
  if (!only || only->getParent() != &F->getEntryBlock())
    return -1;
  auto *J = dyn_cast<llvm::Argument>(only->getValueOperand());
  if (!J || J->getParent() != F || J->getArgNo() == argNo || !J->hasOneUse() ||
      !(J->getType()->isIntegerTy() || J->getType()->isFloatingPointTy()) || !isQuantum(J, S))
    return -1;
  uint64_t size = DL.getTypeStoreSize(J->getType()).getFixedValue();
  if (onlyOff < 0 || onlyOff % int64_t(size) != 0 || uint64_t(onlyOff) / size != cell)
    return -1;
  return int(J->getArgNo());
}

// T3 (cq-arch 2026-11-01; CR rules 5, 18, 20): the cells of the object formal argNo points to that the
// clone S may apply a non-diagonal gate to: a store back of cq_theta(load of the same cell) through the
// formal (constant offsets from it), the rotation in place of the rail the cell holds. The same walk and
// refusals as cellsWritten; a pointer passed on to a call is unimplemented there (no transitive answer).
llvm::SmallVector<unsigned, 4> TaintInfo::cellsRotated(const Specialization &S, unsigned argNo) const {
  return formalCells(needImpl(impl), *this, S, argNo, true);
}

llvm::ArrayRef<ObjectId> TaintInfo::provenance(const llvm::Value *ptr, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, S);
  if (!ptr->getType()->isPointerTy())
    internalError("taint: provenance of a non-pointer", ptr);
  PtrInfo tmp;
  const PtrInfo &p = ptrOrDie(I, *SS, ptr, tmp);
  // The answer must outlive the call: cache it on the (mutable) state.
  static_assert(sizeof(ObjectId) == sizeof(unsigned), "ObjectId");
  auto *self = const_cast<ImplState *>(&I);
  auto out = objectsFor(I, p);
  self->provCache.emplace_back(out.begin(), out.end());
  return self->provCache.back();
}

// T6 (cq-hfah, CR rule 20 per cell): ptr names only globals (no other site kind), and the bytes [off, off + bytes)
// past it hold a handle in none of them (Object::cellHandle, the answer the loads' taint uses): every access of
// those bytes is classical program-wide and the global keeps its layout, so the cells stay host memory.
bool TaintInfo::globalHostCell(const llvm::Value *ptr, int64_t off, uint64_t bytes, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  SpecState *SS = stateOf(I, S);
  if (!ptr->getType()->isPointerTy())
    internalError("taint: globalHostCell of a non-pointer", ptr);
  PtrInfo tmp;
  const PtrInfo &p = ptrOrDie(I, *SS, ptr, tmp);
  if (p.sites.empty())
    return false;
  for (unsigned s : p.sites)
    if (I.sites[s].kind != SiteKind::Global)
      return false;
  std::optional<int64_t> ex = p.exact();
  if (ex)
    *ex += off;
  for (ObjectId o : objectsFor(I, p))
    if (I.objects[o].cellHandle(ex, bytes))
      return false;
  return true;
}

bool TaintInfo::isFatPointer(const llvm::Value *ptr, const Specialization &S) const {
  const ImplState &I = needImpl(impl);
  return lanesOfValue(I, *stateOf(I, S), ptr).any();
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
    C.depth = P.depth;
    std::string n = abi::name(C);
    (void)SS;
    return n;
  };
  for (size_t k = 0; k < I.published.size(); ++k) {
    const Specialization &P = I.published[k];
    os << "cq-taint: spec " << specName(k) << " fn=@" << P.F->getName() << " mask=" << P.mask
       << " entry=" << P.isEntry() << " declared=" << P.F->isDeclaration() << "\n";
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
      os << "  debug " << specName(k) << " key=" << SS->key << " cut=" << SS->depthCut << "\n";
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
  for (ObjectId id = 0; id < I.objects.size(); ++id) {
    const Object &O = I.objects[id];
    const Site &s = I.sites[O.site];
    const char *cls = O.qram ? "Qram" : O.mayHoldHandle() ? "Slot" : "Classical";
    os << "cq-taint: object #" << id << " site=";
    if (s.v->hasName())
      os << s.v->getName();
    else
      s.v->printAsOperand(os, false);
    if (s.owner)
      os << " in @" << s.owner->getName();
    os << " col=" << O.column << " class=" << cls << "\n";
  }
  // QRAM allocation sites per published specialization (each materializes its own copy) and QROM
  // loads (a quantum-offset load of a classical object, one per object of its provenance).
  for (size_t k = 0; k < I.published.size(); ++k) {
    const Specialization &P = I.published[k];
    SpecState *SS = I.publishedState[k];
    if (P.F->isDeclaration())
      continue;
    for (const llvm::BasicBlock &BB : *P.F)
      for (const llvm::Instruction &Ins : BB) {
        if (auto *LI = dyn_cast<llvm::LoadInst>(&Ins)) {
          auto it = SS->lanes.find(LI->getPointerOperand());
          Lanes l;
          if (it != SS->lanes.end())
            l = it->second;
          if (!(l.size() >= 2 && l.test(1)))
            continue;
          PtrInfo tmp;
          const PtrInfo &pi = ptrOrDie(I, *SS, LI->getPointerOperand(), tmp);
          for (ObjectId o : objectsFor(I, pi))
            if (!I.objects[o].mayHoldHandle())
              os << "cq-taint: qrom " << specName(k) << " object #" << o << "\n";
        }
      }
  }
  for (ObjectId id = 0; id < I.objects.size(); ++id) {
    const Object &O = I.objects[id];
    if (!O.qram)
      continue;
    const Site &s = I.sites[O.site];
    // A QRAM of pointer cells is two QRAMs at the same cell index: the tag half and the idx half
    // (rule 21's fat pointer is a pair of rails, 88).
    int halves = (O.anyPtr || !O.ptrCells.empty()) ? 2 : 1;
    for (int h = 0; h < halves; ++h) {
      const char *half = halves == 2 ? (h == 0 ? " tag-half" : " idx-half") : "";
      if (s.kind == SiteKind::Global || !s.owner) {
        os << "cq-taint: qram-alloc object #" << id << half << "\n";
        continue;
      }
      for (size_t k = 0; k < I.published.size(); ++k)
        if (I.published[k].F == s.owner)
          os << "cq-taint: qram-alloc object #" << id << half << " in " << specName(k) << "\n";
    }
  }
}

// ---- CR rule 13: code addresses ----
namespace {
// 1: a code address; 0: neutral (null, undef, poison, a cycle back); -1: something else.
int codeSource(const Value *v, SmallPtrSetImpl<const Value *> &seen);

int combine(int a, int b) { return a < 0 || b < 0 ? -1 : std::max(a, b); }

int constantCells(const Constant *c) {
  if (isa<BlockAddress>(c->stripPointerCasts()))
    return 1;
  if (c->getType()->isPointerTy())
    return c->isNullValue() || isa<UndefValue>(c) ? 0 : -1;
  if (isa<ConstantData>(c) && !c->getType()->isAggregateType() && !c->getType()->isVectorTy())
    return 0;   // a non-pointer leaf (an integer or fp cell) stores no address
  if (isa<ConstantAggregateZero>(c) || isa<UndefValue>(c))
    return 0;
  int r = 0;
  if (isa<ConstantAggregate>(c) || isa<ConstantDataSequential>(c)) {
    for (unsigned i = 0, n = c->getNumOperands(); i < n; ++i)
      r = combine(r, constantCells(cast<Constant>(c->getOperand(i))));
    return r;
  }
  return -1;
}

int objectCells(const Value *root, SmallPtrSetImpl<const Value *> &seen) {
  int r = 0;
  if (auto *gv = dyn_cast<GlobalVariable>(root)) {
    if (!gv->hasDefinitiveInitializer())
      return -1;
    r = constantCells(gv->getInitializer());
    if (r < 0)
      return -1;
    if (gv->isConstant())
      return r;
    if (!gv->hasLocalLinkage())
      return -1;   // another unit may store any pointer
  } else if (!isa<AllocaInst>(root)) {
    return -1;
  }
  SmallVector<const Value *, 8> work{root};
  SmallPtrSet<const Value *, 16> vis;
  while (!work.empty()) {
    const Value *p = work.pop_back_val();
    if (!vis.insert(p).second)
      continue;
    for (const Use &U : p->uses()) {
      const User *u = U.getUser();
      if (isa<GetElementPtrInst>(u) || isa<BitCastInst>(u) || isa<AddrSpaceCastInst>(u) ||
          (isa<ConstantExpr>(u) && cast<ConstantExpr>(u)->getOpcode() == Instruction::GetElementPtr)) {
        work.push_back(u);
        continue;
      }
      if (isa<LoadInst>(u))
        continue;
      if (auto *st = dyn_cast<StoreInst>(u)) {
        if (U.getOperandNo() != st->getPointerOperandIndex())
          return -1;   // the object's address escapes into memory
        const Value *v = st->getValueOperand();
        if (v->getType()->isPointerTy())
          r = combine(r, codeSource(v, seen));
        else if (auto *c = dyn_cast<Constant>(v))
          r = combine(r, c->isNullValue() ? 0 : -1);
        else
          return -1;   // an integer stored over an address cell
        if (r < 0)
          return -1;
        continue;
      }
      if (auto *ms = dyn_cast<MemSetInst>(u); ms && U.getOperandNo() == 0)
        if (auto *k = dyn_cast<ConstantInt>(ms->getValue()); k && k->isZero())
          continue;   // zero-initialized cells hold null
      if (auto *ii = dyn_cast<IntrinsicInst>(u))
        if (ii->isLifetimeStartOrEnd() || isa<DbgInfoIntrinsic>(ii))
          continue;
      return -1;
    }
  }
  return r;
}

int codeSource(const Value *v, SmallPtrSetImpl<const Value *> &seen) {
  v = v->stripPointerCasts();
  if (isa<BlockAddress>(v))
    return 1;
  if (!v->getType()->isPointerTy())
    return -1;
  if (isa<ConstantPointerNull>(v) || isa<UndefValue>(v))
    return 0;
  if (!seen.insert(v).second)
    return 0;   // a cycle: what the other sources say
  if (auto *sel = dyn_cast<SelectInst>(v))
    return combine(codeSource(sel->getTrueValue(), seen), codeSource(sel->getFalseValue(), seen));
  if (auto *phi = dyn_cast<PHINode>(v)) {
    int r = 0;
    for (const Value *in : phi->incoming_values())
      if ((r = combine(r, codeSource(in, seen))) < 0)
        return -1;
    return r;
  }
  if (auto *ld = dyn_cast<LoadInst>(v)) {
    SmallVector<const Value *, 4> roots;
    getUnderlyingObjects(ld->getPointerOperand(), roots, nullptr, 0);
    int r = roots.empty() ? -1 : 0;
    for (const Value *root : roots)
      if ((r = combine(r, objectCells(root, seen))) < 0)
        return -1;
    return r;
  }
  return -1;
}
} // namespace

bool isCodeAddress(const Value *v) {
  if (!v || !v->getType()->isPointerTy())
    return false;
  SmallPtrSet<const Value *, 16> seen;
  return codeSource(v, seen) > 0;
}

bool codeAddressCells(const Value *root) {
  SmallPtrSet<const Value *, 16> seen;
  return objectCells(root, seen) > 0;
}

TaintInfo computeTaint(llvm::Module &M, const TaintOptions &opts) {
  TaintInfo T;
  T.impl = std::make_shared<TaintInfo::Impl>();
  T.impl->M = &M;
  T.impl->opts = opts;
  taintimpl::Analyzer A(*T.impl);
  A.run();
  return T;
}
} // namespace cq

namespace cq {
// T4 (cq-arch 2026-11-01): stub until taint builds it.
PtrFormal TaintInfo::pointerFormal(const Specialization &callee, unsigned argNo) const {
  const auto &I = needImpl(impl);
  auto *SS = stateOf(I, callee);
  if (argNo >= SS->formalTy.size() || !SS->formalTy[argNo]->isPointerTy())
    internalError("taint: pointerFormal of a formal that is not a pointer", callee.F);
  if (argNo >= SS->ptrFormal.size())
    internalError("taint: pointerFormal before the clone's mask was built", callee.F);
  if (SS->mixedPointee[argNo])
    unimplemented("taint: a pointer formal whose objects are a QRAM and a slot or host object (T4)",
                  argNo < callee.F->arg_size() ? static_cast<const llvm::Value *>(callee.F->getArg(argNo))
                                               : callee.F);
  return SS->ptrFormal[argNo];
}
} // namespace cq
