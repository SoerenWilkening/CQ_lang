// cq-oracle: the C-oracle instrumentation (cq-w0-chk-oracle; CLAUDE.md "The §6 checker", oracle b).
//
//   opt -load-pass-plugin=libCQOracle.so -passes=cq-oracle [-cq-oracle-stubs=FILE] in.bc -o out.bc
//
// Input: a whole program (the example's .O1.ll linked with the generated driver and, when present,
// the injection bundle). Output: the same program with
//   * cq_theta_* / cq_measure_* replaced by the identity, each call site logging a `site` event
//     (fn, site ordinal, kind, angle, register value); a cq_measure of a value CR rule 2's classical
//     collapse made classical logs kind `read`, no measurement (shadows below; cq-y1ll); cq_phi and __cq_invert_begin/end log and vanish;
//   * every loop counting its trips (`trip` event per activation, a guard skip reports 0);
//   * every quantum-exit loop and quantum-depth recursion stopped after K trips (CR §6 at eb8a11a,
//     ruling cq-1di; bead cq-8ay): the trip counter that reaches K+1 trips begun ends the sample with
//     a capped `kloop` record (cq-arch T2), and every activation that ends by itself first gets an
//     uncapped one. Which loops and recursions are quantum is the circuit's own answer: the pass's
//     taint (cq::computeTaint) and rule-14 classification (cq::loops::classify), linked in, run on
//     the pristine module and tracked per specialization at run time (see KInfo);
//   * the operations whose native behaviour differs from CR §2, or is undefined in LLVM, rewritten to
//     their §2 totalization: div/rem by 0 and INT_MIN / -1, shift amounts >= W (mod W), fptosi/fptoui
//     (CR §2 row by row, in the runtime), maxnum/minnum (the measured x86 formula), fmuladd unfused,
//     abs/ctlz/cttz with their poison flag cleared, every poison-generating flag dropped;
//   * memory per CR §6: allocas and lifetime starts zeroed, heap blocks zeroed (realloc growth too),
//     every load/store/memory intrinsic bounds-checked over an object table (globals, allocas, heap,
//     byval parameter copies, the va_start register save and overflow areas):
//     a byte outside every object reads 0, a store to it is dropped;
//   * in a program that touches the fp environment, every non-constrained fp operation run in the
//     default environment (round-to-nearest, its flags discarded; owner ruling on cq-0r1i);
//   * the fenv calls modelled as rule 23 and the references model them (the 5 IEEE flags, no
//     FE_DENORMAL; feraiseexcept(m) raises exactly m; fesetround of an invalid mode returns 1);
//   * threads collapsed (pthread_create runs the start routine to completion, rule 24), noreturn
//     callees, raise and `unreachable` noted in the sample status;
//   * each call of a declared host-effect function (remove, unlink, rename, raise: compare.py
//     HOST_EFFECTS) logged as an `effect` event before it runs (cq-e4jk; cqo_rt.c __cqo_fx_*);
//   * undefined external functions named in -cq-oracle-stubs given the checker's deterministic model.
// The instrumented module is compiled at -O0, so nothing re-optimizes the C program after this pass.
// An IR shape this pass cannot handle is a fatal "cq-oracle: unimplemented: ..." error, never a skip.

#include "cq/Loops.h"
#include "cq/Taint.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/AttributeMask.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

#include <cstdlib>

#include "../rt/cq_standin.h"
#include <functional>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <vector>

using namespace llvm;

static cl::opt<std::string> StubsFile("cq-oracle-stubs",
                                      cl::desc("file of undefined external function names to model"),
                                      cl::init(""));
static cl::list<std::string> Entries("cq-oracle-entries", cl::CommaSeparated,
                                     cl::desc("functions whose results calls in __cqo_* driver functions log"));

static cl::list<std::string> KPerFunction("cq-oracle-k", cl::CommaSeparated, cl::value_desc("fn=k"),
                                          cl::desc("per-function loop cutoff K, as cq-lower's -cq-k"));
static cl::opt<unsigned> KGlobal("cq-oracle-k-default", cl::value_desc("k"),
                                 cl::desc("global loop cutoff K, as cq-lower's -cq-k-default"));

namespace {

[[noreturn]] void unimplemented(const Twine &what, const Value *at = nullptr) {
  std::string s;
  raw_string_ostream os(s);
  os << "cq-oracle: unimplemented: " << what;
  if (at) {
    os << ": ";
    at->print(os);
  }
  report_fatal_error(Twine(os.str()), false);
}

enum SiteKind { KTheta = 0, KPhi = 1, KMeasure = 2, KInvBegin = 3, KInvEnd = 4 };

bool isDriverFn(const Function &F) { return F.getName().starts_with("__cqo_"); }

class Instrumenter {
  Module &M;
  LLVMContext &C;
  const DataLayout &DL;
  Type *I1, *I8, *I32, *I64, *Ptr, *Dbl, *F80, *Void;
  StringMap<Constant *> Strings;

public:
  explicit Instrumenter(Module &M)
      : M(M), C(M.getContext()), DL(M.getDataLayout()) {
    I1 = Type::getInt1Ty(C);
    I8 = Type::getInt8Ty(C);
    I32 = Type::getInt32Ty(C);
    I64 = Type::getInt64Ty(C);
    Ptr = PointerType::get(C, 0);
    Dbl = Type::getDoubleTy(C);
    F80 = Type::getX86_FP80Ty(C);
    Void = Type::getVoidTy(C);
  }

  FunctionCallee hook(StringRef name, Type *ret, ArrayRef<Type *> params) {
    return M.getOrInsertFunction(name, FunctionType::get(ret, params, false));
  }

  Constant *str(StringRef s) {
    auto it = Strings.find(s);
    if (it != Strings.end())
      return it->second;
    Constant *init = ConstantDataArray::getString(C, s, true);
    auto *gv = new GlobalVariable(M, init->getType(), true, GlobalValue::PrivateLinkage, init,
                                  "__cqo_str");
    gv->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
    Strings[s] = gv;
    return gv;
  }

  AllocaInst *entryAlloca(Function &F, Type *T) {
    IRBuilder<> B(&*F.getEntryBlock().getFirstInsertionPt());
    return B.CreateAlloca(T);
  }

  // ---------------------------------------------------------------- the cutoff K (CR §6, rule 14)
  // Which loops and recursions run for a cutoff is the circuit's answer, so the oracle asks the same
  // analysis the pass asks: cq::computeTaint over the pristine module (before any edit here, before
  // the stubs give bodies to declarations), then cq::loops::classify per loop and specialization.
  // A function's body is shared by its specializations, so the C program carries the current one at
  // run time: spec ids 1..N (0: classical, no taint), a frame slot read at entry from the global
  // __cqo_spec_next, which every call stores first (the callee's specialization for this caller's,
  // calleeSpecialization; -1 from the driver means the callee's entry specialization).
  //  - A loop is capped where classify says QuantumExit (ClassicalBound and
  //    ClassicalBoundQuantumExit run to completion; rule 14 gives them no cutoff).
  //  - A recursive call (callee in the caller's call-graph cycle) is a level of a quantum-depth
  //    recursion when taint makes it one: under a quantum predicate, or in a level clone already
  //    (depth > 0). An activation is entered by a call from outside the cycle whose callee
  //    specialization reaches such a level call through the cycle (or by the driver's call of a
  //    cycle member whose entry specialization does).
  // Indirect calls carry 0 (calleeSpecialization is asked for direct calls only).
  struct KInfo {
    bool on = false;
    unsigned N = 0;
    DenseMap<const Function *, unsigned> entry;                 // entry specialization id
    DenseMap<const Function *, bool> entryRec;                  // it is a quantum-depth recursion
    DenseMap<const Function *, bool> hasSpec;
    DenseMap<const BasicBlock *, std::vector<int32_t>> qexit;   // header -> QuantumExit per spec id
    DenseMap<const CallBase *, std::vector<int32_t>> callee;    // call -> callee spec id per spec id
    DenseMap<const CallBase *, std::vector<int32_t>> level;     // call -> recursion level per spec id
    DenseMap<const CallBase *, std::vector<int32_t>> recEntry;  // call -> enters an activation
  } KI;
  GlobalVariable *SpecNext = nullptr;
  DenseMap<Function *, AllocaInst *> specSlots;

  static bool callsCqSurface(const Module &M) {
    for (const Function &F : M) {
      if (siteKind(F.getName()) < 0)
        continue;
      for (const Use &U : F.uses())
        if (const auto *CB = dyn_cast<CallBase>(U.getUser()); CB && CB->isCallee(&U))
          return true;
    }
    return false;
  }

  unsigned resolveK(const Function &F) {
    // CR §0: per-function flag, CQ_K(f, k) (the `used` constant __cq_k_<f>), global flag, 4.
    for (const std::string &item : KPerFunction) {
      auto [fn, k] = StringRef(item).split('=');
      unsigned v = 0;
      if (fn.empty() || k.getAsInteger(10, v) || v == 0)
        report_fatal_error(Twine("cq-oracle: -cq-oracle-k: expected <fn>=<k>, got '") + item + "'", false);
      if (fn == F.getName())
        return v;
    }
    if (const GlobalVariable *GV = M.getGlobalVariable(("__cq_k_" + F.getName()).str(), true))
      if (GV->hasInitializer())
        if (auto *CI = dyn_cast<ConstantInt>(GV->getInitializer()))
          if (CI->getZExtValue() > 0)
            return unsigned(CI->getZExtValue());
    if (KGlobal.getNumOccurrences() && KGlobal > 0)
      return KGlobal;
    return 4;
  }

  static bool directBody(const CallBase &CB) {
    const Function *G = CB.getCalledFunction();
    return G && !G->isDeclaration() && !G->isIntrinsic();
  }

  void analyseCutoffs() {
    if (!callsCqSurface(M))
      return;
    Taint = cq::computeTaint(M, cq::TaintOptions{});  // shared with shadows() (rule 2, cq-y1ll)
    const cq::TaintInfo &T = *Taint;
    std::vector<const cq::Specialization *> byId(1, nullptr);
    DenseMap<const cq::Specialization *, unsigned> idOf;
    for (const cq::Specialization &S : T.specializations())
      if (S.F && !S.F->isDeclaration() && !isDriverFn(*S.F)) {
        idOf[&S] = byId.size();
        byId.push_back(&S);
      }
    KI.N = byId.size() - 1;
    if (KI.N == 0)
      return;
    KI.on = true;
    const unsigned W = KI.N + 1;

    DenseMap<const Function *, unsigned> scc;
    {
      CallGraph CG(M);
      unsigned k = 0;
      for (auto I = scc_begin(&CG); !I.isAtEnd(); ++I) {
        if (I->size() < 2 && !I.hasCycle())
          continue;
        ++k;
        for (CallGraphNode *n : *I)
          if (Function *F = n->getFunction())
            scc[F] = k;
      }
    }
    auto recursive = [&](const Function *F, const Function *G) {
      auto a = scc.find(F), b = scc.find(G);
      return a != scc.end() && b != scc.end() && a->second == b->second;
    };

    std::map<const Function *, std::vector<unsigned>> byFn;
    for (unsigned i = 1; i <= KI.N; ++i)
      byFn[byId[i]->F].push_back(i);
    for (auto &[Fc, ids] : byFn) {
      Function &F = *const_cast<Function *>(Fc);
      KI.hasSpec[&F] = true;
      DominatorTree DT(F);
      LoopInfo LI(DT);
      for (unsigned i : ids) {
        const cq::Specialization &S = *byId[i];
        if (S.isEntry())
          KI.entry[&F] = i;
        for (Loop *L : LI.getLoopsInPreorder())
          if (cq::loops::classify(*L, T, S) == cq::loops::Case::QuantumExit) {
            auto &v = KI.qexit[L->getHeader()];
            v.resize(W, 0);
            v[i] = 1;
          }
        for (Instruction &I : instructions(F)) {
          auto *CB = dyn_cast<CallBase>(&I);
          if (!CB || !directBody(*CB))
            continue;
          const Function *G = CB->getCalledFunction();
          const cq::Specialization *cs = T.calleeSpecialization(*CB, S);
          int32_t c = 0;
          if (cs && idOf.count(cs))
            c = idOf[cs];
          bool lvl = recursive(&F, G) && (T.controlTainted(CB->getParent(), S) || S.depth > 0);
          if (lvl && c == 0 && G == &F)
            c = i;  // a level past the clones taint built: the frame keeps its specialization
          if (c) {
            auto &v = KI.callee[CB];
            v.resize(W, 0);
            v[i] = c;
          }
          if (lvl) {
            auto &v = KI.level[CB];
            v.resize(W, 0);
            v[i] = 1;
          }
        }
      }
    }
    // A specialization of a cycle member is a quantum-depth recursion when a level call is reachable
    // from it through calls inside its cycle.
    std::map<unsigned, bool> memo;
    std::function<bool(unsigned, std::set<unsigned> &)> qdepth = [&](unsigned i, std::set<unsigned> &seen) {
      if (memo.count(i))
        return memo[i];
      if (!seen.insert(i).second)
        return false;
      Function *F = byId[i]->F;
      bool r = false;
      for (Instruction &I : instructions(*F)) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || !directBody(*CB) || !recursive(F, CB->getCalledFunction()))
          continue;
        auto l = KI.level.find(CB);
        if (l != KI.level.end() && l->second[i]) {
          r = true;
          break;
        }
        auto c = KI.callee.find(CB);
        if (c != KI.callee.end() && c->second[i] && qdepth(c->second[i], seen)) {
          r = true;
          break;
        }
      }
      return r;
    };
    auto isQDepth = [&](unsigned i) {
      if (!memo.count(i)) {
        std::set<unsigned> seen;
        memo[i] = qdepth(i, seen);
      }
      return memo[i];
    };
    for (auto &[CB, v] : KI.callee) {
      const Function *F = CB->getFunction(), *G = CB->getCalledFunction();
      if (!scc.count(G) || recursive(F, G))
        continue;
      for (unsigned i = 1; i <= KI.N; ++i)
        if (v[i] && isQDepth(v[i])) {
          auto &e = KI.recEntry[CB];
          e.resize(W, 0);
          e[i] = 1;
        }
    }
    for (auto &[F, i] : KI.entry)
      if (scc.count(F) && isQDepth(i))
        KI.entryRec[F] = true;
  }

  // vals[spec id] at run time: a constant when they agree, else a load from a constant table.
  Value *perSpec(IRBuilder<> &B, Function &F, const std::vector<int32_t> &vals) {
    bool same = true;
    for (int32_t v : vals)
      same = same && v == vals[0];
    if (same)
      return B.getInt32(vals.empty() ? 0 : vals[0]);
    auto *AT = ArrayType::get(I32, vals.size());
    std::vector<Constant *> cs;
    for (int32_t v : vals)
      cs.push_back(ConstantInt::get(I32, v));
    auto *gv = new GlobalVariable(M, AT, true, GlobalValue::PrivateLinkage, ConstantArray::get(AT, cs),
                                  "__cqo_spec_tab");
    Value *s = B.CreateLoad(I32, specSlot(F));
    return B.CreateLoad(I32, B.CreateInBoundsGEP(AT, gv, {B.getInt32(0), s}));
  }

  // The frame's specialization id, read once at entry.
  AllocaInst *specSlot(Function &F) {
    auto it = specSlots.find(&F);
    if (it != specSlots.end())
      return it->second;
    AllocaInst *slot = entryAlloca(F, I32);
    IRBuilder<> B(slot->getNextNode());
    Value *s0 = B.CreateLoad(I32, SpecNext);
    Value *fromDriver = B.CreateICmpEQ(s0, B.getInt32(-1));
    Value *s = B.CreateSelect(fromDriver, B.getInt32(KI.entry.lookup(&F)), s0);
    B.CreateStore(s, slot);
    if (KI.entryRec.lookup(&F))
      B.CreateCall(hook("__cqo_rec_enter", Void, {Ptr, I64, I32}),
                   {str((F.getName() + ":recursion").str()), B.getInt64(resolveK(F)),
                    B.CreateZExt(fromDriver, I32)});
    specSlots[&F] = slot;
    return slot;
  }

  // Every call stores the callee's specialization first; recursion levels and activations get their
  // hooks around the call.
  void specFlow(Function &F) {
    if (!KI.on)
      return;
    if (KI.hasSpec.lookup(&F))
      specSlot(F);
    std::vector<CallBase *> calls;
    for (Instruction &I : instructions(F))
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        if (CB->isInlineAsm() || isa<IntrinsicInst>(CB))
          continue;
        if (Function *G = CB->getCalledFunction())
          if (G->getName().starts_with("__cqo_"))
            continue;
        calls.push_back(CB);
      }
    FunctionCallee enter = hook("__cqo_rec_enter", Void, {Ptr, I64, I32});
    FunctionCallee exitH = hook("__cqo_rec_exit", Void, {I32});
    FunctionCallee down = hook("__cqo_rec_down", Void, {I32});
    FunctionCallee up = hook("__cqo_rec_up", Void, {I32});
    for (CallBase *CB : calls) {
      IRBuilder<> B(CB);
      auto c = KI.callee.find(CB);
      B.CreateStore(c == KI.callee.end() ? (Value *)B.getInt32(0) : perSpec(B, F, c->second), SpecNext);
      if (isa<InvokeInst>(CB) || isa<CallBrInst>(CB))
        continue;  // notes() already refused them
      auto e = KI.recEntry.find(CB);
      if (e != KI.recEntry.end()) {
        Function *G = CB->getCalledFunction();
        Value *on = perSpec(B, F, e->second);
        B.CreateCall(enter, {str((G->getName() + ":recursion").str()), B.getInt64(resolveK(*G)), on});
        IRBuilder<> A(CB->getNextNode());
        A.CreateCall(exitH, {on});
      }
      auto l = KI.level.find(CB);
      if (l != KI.level.end()) {
        Value *on = perSpec(B, F, l->second);
        B.CreateCall(down, {on});
        IRBuilder<> A(CB->getNextNode());
        A.CreateCall(up, {on});
      }
    }
  }

  // ---------------------------------------------------------------- rule 2 classical collapse (cq-y1ll)
  // Owner ruling cq-r6bc (CR rule 2): a value computed only from measured rails and classical values
  // is classical (a data-flow condition, not a program-order one), and a cq_measure of such a value is
  // a classical read, no gate. The oracle tracks it per sample: every value the circuit holds as a rail
  // (taint's answer, any specialization of the function) carries a shadow node at run time
  // (cqo_rt.c, rule 2 classical collapse). A cq_theta result is a leaf; any other quantum value is a
  // fresh node over what the circuit computes it from: its operands; for a load, the cells read, the
  // address and every implicit write so far (sh_gm); for a merge (phi) the circuit takes under a
  // quantum condition, the conditions deciding it and every incoming value, where a value of an arm
  // the sample did not run is unknown (SH_OPAQUE: never classical); likewise a function's result
  // merged over several returns. A quantum branch whose arms write memory or touch the fp environment
  // adds its condition and what the arms write (SH_OPAQUE for what the sample cannot know) to sh_gm /
  // sh_gf. Calls pass nodes through argument and result slots; a library call joins its arguments into
  // sh_gf (and, writing through a pointer, sh_gm). cq_measure asks the runtime whether its operand's
  // node is classical (then the site logs kind "read" and counts no measurement), else marks it
  // measured. Wherever the instrumentation cannot see a source it errs to "quantum": that is the
  // measurement the oracle counted before this rule.
  std::optional<cq::TaintInfo> Taint;

  struct Shadow {
    Instrumenter &In;
    Function &F;
    const cq::TaintInfo &T;
    std::vector<const cq::Specialization *> specs;
    DominatorTree DT;
    PostDominatorTree PDT;
    DenseMap<const Value *, Value *> sh;
    SmallPtrSet<const Instruction *, 32> orig;  // the function as clang wrote it: taint knows only these
    Type *I32;

    Shadow(Instrumenter &In, Function &F, const cq::TaintInfo &T) : In(In), F(F), T(T), DT(F), PDT(F) {
      I32 = In.I32;
      for (const cq::Specialization &S : T.specializations())
        if (S.F == &F)
          specs.push_back(&S);
      for (Instruction &I : instructions(F))
        orig.insert(&I);
    }

    bool q(const Value *V) const {
      if (!isa<Instruction>(V) && !isa<Argument>(V))
        return false;
      if (auto *I = dyn_cast<Instruction>(V); I && !orig.count(I))
        return false;
      for (const cq::Specialization *S : specs)
        if (T.isQuantum(V, *S))
          return true;
      return false;
    }
    Value *zero() { return ConstantInt::get(I32, 0); }
    Value *opaque() { return ConstantInt::get(I32, 1); }
    static bool isZero(Value *v) {
      auto *c = dyn_cast<ConstantInt>(v);
      return c && c->isZero();
    }
    Value *get(Value *V) {
      auto it = sh.find(V);
      return it == sh.end() ? zero() : it->second;
    }
    FunctionCallee h(StringRef n, Type *r, ArrayRef<Type *> ps) { return In.hook(n, r, ps); }
    FunctionCallee h3(StringRef n) { return h(n, I32, {I32, I32, I32}); }
    Value *call0(IRBuilder<> &B, StringRef n) { return B.CreateCall(h(n, I32, {}), {}); }

    // a dependency set over vs (0 when all are classical constants)
    Value *join(IRBuilder<> &B, std::vector<Value *> vs) {
      std::vector<Value *> nz;
      for (Value *v : vs)
        if (!isZero(v))
          nz.push_back(v);
      if (nz.empty())
        return zero();
      while (nz.size() > 1) {
        std::vector<Value *> next;
        for (size_t i = 0; i < nz.size(); i += 3) {
          if (i + 1 == nz.size()) {
            next.push_back(nz[i]);
            continue;
          }
          Value *a = nz[i], *b = nz[i + 1], *c = i + 2 < nz.size() ? nz[i + 2] : zero();
          next.push_back(B.CreateCall(h3("__cqo_sh_j"), {a, b, c}));
        }
        nz = next;
      }
      return nz[0];
    }
    // a value's own node over vs
    Value *node(IRBuilder<> &B, std::vector<Value *> vs) {
      Value *d = join(B, vs);
      if (isZero(d))
        return zero();
      return B.CreateCall(h3("__cqo_sh_v"), {d, zero(), zero()});
    }

    // V's node as known where `at` (an instruction) runs; SH_OPAQUE for a quantum value not computed
    // on every path to it.
    Value *availAt(Value *V, Instruction *at) {
      if (isa<Argument>(V))
        return get(V);
      auto *J = dyn_cast<Instruction>(V);
      if (!J || !q(J))
        return zero();
      if (DT.dominates(J, at))
        return get(J);
      return opaque();
    }
    // the same at the top of block B (before its phis' shadows)
    Value *availIn(Value *V, BasicBlock *B) {
      if (isa<Argument>(V))
        return get(V);
      auto *J = dyn_cast<Instruction>(V);
      if (!J || !q(J))
        return zero();
      if (DT.properlyDominates(J->getParent(), B))
        return get(J);
      return opaque();
    }

    // Classical merges (review y1ll-n1): a merge taint holds as a rail but decided by a classical
    // condition takes the node of the incoming the sample ran. When that node is 0 (a constant
    // incoming: trip 0 of a loop, an arm that assigns a constant), the circuit still holds the merge
    // as a rail, so its node is a fresh one over every quantum incoming, each as computed so far in
    // this activation (a frame slot holding node + 1; 0 = not computed yet: SH_OPAQUE), and
    // SH_OPAQUE when there is no quantum incoming at all (__cqo_sh_nz).
    DenseMap<Instruction *, AllocaInst *> slots;
    Value *slotOf(Instruction *J, IRBuilder<> &B) {
      AllocaInst *&a = slots[J];
      if (!a)
        a = In.entryAlloca(F, I32);  // registered and zeroed at entry (memory())
      return B.CreateCall(h("__cqo_sh_slot", I32, {I32}), {B.CreateLoad(I32, a)});
    }
    // V's node as computed so far, where B inserts (dominating `dom` means computed: sh)
    Value *soFar(Value *V, IRBuilder<> &B, std::function<bool(Instruction *)> dominated) {
      if (isa<Argument>(V))
        return get(V);
      auto *J = dyn_cast<Instruction>(V);
      if (!J || !q(J))
        return zero();
      if (dominated(J))
        return get(J);
      return slotOf(J, B);
    }
    void storeSlots() {
      for (auto &[J, a] : slots) {
        Value *v = get(J);
        Instruction *after = isa<Instruction>(v) ? cast<Instruction>(v) : J;
        IRBuilder<> B(isa<PHINode>(after) ? &*after->getParent()->getFirstInsertionPt() : after->getNextNode());
        B.CreateStore(B.CreateAdd(v, B.getInt32(1)), a);
      }
    }
    Value *nonZero(IRBuilder<> &B, Value *s, std::vector<Value *> incomings) {
      return B.CreateCall(h("__cqo_sh_nz", I32, {I32, I32}), {s, join(B, incomings)});
    }

    Value *condOf(Instruction *Term) {
      if (auto *BI = dyn_cast<BranchInst>(Term))
        return BI->isConditional() ? BI->getCondition() : nullptr;
      if (auto *SI = dyn_cast<SwitchInst>(Term))
        return SI->getCondition();
      return nullptr;
    }
    Value *quantumCond(BasicBlock *X) {
      Instruction *Term = X->getTerminator();
      if (!Term || Term->getNumSuccessors() < 2)
        return nullptr;
      Value *c = condOf(Term);
      if (!c) {
        if (isa<IndirectBrInst>(Term) || isa<CallBrInst>(Term))
          unimplemented("rule 2 shadows: a multi-way terminator other than br/switch", Term);
        return nullptr;
      }
      return q(c) ? c : nullptr;
    }

    static bool isAllocator(StringRef n) {
      return n == "malloc" || n == "calloc" || n == "free" || n == "aligned_alloc" || n == "valloc" ||
             n == "posix_memalign" || n == "realloc" || n == "reallocf";
    }
    static bool isCopy(StringRef n) {
      return n == "memcpy" || n == "memmove" || n == "__memcpy_chk" || n == "__memmove_chk";
    }
    static bool isFill(StringRef n) { return n == "memset" || n == "__memset_chk" || n == "bzero"; }
    static bool runsModuleCode(const CallBase &CB) {
      if (const Function *G = CB.getCalledFunction()) {
        StringRef n = G->getName();
        if (n == "raise" || n == "kill" || n == "pthread_kill")
          return true;
      }
      for (const Value *a : CB.args())
        if (isa<Function>(a->stripPointerCasts()))
          return true;
      return false;
    }
    static bool hasPtrArg(const CallBase &CB) {
      for (const Value *a : CB.args())
        if (a->getType()->isPointerTy())
          return true;
      return false;
    }

    // What the arms of the quantum branch ending A may write (memory, the fp environment), as
    // available at A's terminator.
    struct Region {
      bool mem = false, fenv = false, opaque = false, mq = false;
      std::vector<Value *> deps;
    };
    Region region(BasicBlock *A) {
      Region R;
      BasicBlock *stop = nullptr;
      if (DomTreeNode *n = PDT.getNode(A))
        if (DomTreeNode *p = n->getIDom())
          stop = p->getBlock();
      SmallPtrSet<BasicBlock *, 16> seen;
      std::vector<BasicBlock *> work(succ_begin(A), succ_end(A));
      Instruction *at = A->getTerminator();
      auto contrib = [&](Value *v) { R.deps.push_back(availAt(v, at)); };
      while (!work.empty()) {
        BasicBlock *X = work.back();
        work.pop_back();
        if (X == stop || !seen.insert(X).second)
          continue;
        for (BasicBlock *S : successors(X))
          work.push_back(S);
        for (Instruction &I : *X) {
          if (auto *SI = dyn_cast<StoreInst>(&I)) {
            R.mem = true;
            contrib(SI->getValueOperand());
            contrib(SI->getPointerOperand());
          } else if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I)) {
            R.mem = true;
            for (Value *op : I.operands())
              contrib(op);
          } else if (auto *CB = dyn_cast<CallBase>(&I)) {
            Function *G = CB->getCalledFunction();
            if (G && siteKind(G->getName()) >= 0)
              continue;
            if (!G || CB->isInlineAsm()) {
              R.mem = R.fenv = R.opaque = true;
              continue;
            }
            if (G->isIntrinsic()) {
              if (isa<MemIntrinsic>(CB)) {
                R.mem = true;
                for (Value *a : CB->args())
                  contrib(a);
              } else if (isa<ConstrainedFPIntrinsic>(CB)) {
                R.fenv = true;
                for (Value *a : CB->args())
                  contrib(a);
              }
              continue;
            }
            if (!G->isDeclaration()) {
              R.fenv = true;
              for (Value *a : CB->args())
                contrib(a);
              if (!G->doesNotAccessMemory())
                R.mem = R.opaque = true;
              continue;
            }
            StringRef n = G->getName();
            if (isAllocator(n))
              continue;
            R.fenv = true;
            for (Value *a : CB->args())
              contrib(a);
            if (isCopy(n) || isFill(n))
              R.mem = true;
            else if (hasPtrArg(*CB) && !G->onlyReadsMemory())
              R.mem = R.mq = true;
            if (runsModuleCode(*CB))
              R.mem = R.opaque = true;
          } else if (isa<VAArgInst>(I)) {
            // reads its list: no write
          }
        }
      }
      return R;
    }

    void run() {
      if (F.isDeclaration())
        return;
      // entry: the argument slots (every call fills them; reading clears them)
      {
        IRBuilder<> B(&*F.getEntryBlock().getFirstInsertionPt());
        for (Argument &A : F.args()) {
          Value *s = B.CreateCall(h("__cqo_sh_arg", I32, {I32}), {B.getInt32(A.getArgNo())});
          sh[&A] = q(&A) ? s : zero();
          if (A.hasByValAttr())
            B.CreateCall(h("__cqo_sh_byval_in", In.Void, {I32, In.Ptr, In.I64}),
                         {B.getInt32(A.getArgNo()), &A,
                          B.getInt64(In.DL.getTypeAllocSize(A.getParamByValType()).getFixedValue())});
        }
      }
      ReversePostOrderTraversal<Function *> RPOT(&F);
      std::vector<BasicBlock *> order(RPOT.begin(), RPOT.end());
      SmallPtrSet<BasicBlock *, 32> reachable(order.begin(), order.end());

      // phi shadows first (incoming filled at the end)
      std::vector<std::pair<PHINode *, PHINode *>> phis;
      for (BasicBlock *BB : order)
        for (PHINode &P : BB->phis())
          if (q(&P)) {
            PHINode *s = PHINode::Create(I32, P.getNumIncomingValues(), "", BB->getFirstNonPHI());
            phis.push_back({&P, s});
          }
      DenseMap<PHINode *, PHINode *> phiSh(phis.begin(), phis.end());

      // a function's result merged over several returns under quantum control
      std::vector<ReturnInst *> rets;
      std::vector<Value *> qconds;
      for (BasicBlock *BB : order) {
        if (auto *R = dyn_cast<ReturnInst>(BB->getTerminator()))
          if (R->getReturnValue())
            rets.push_back(R);
        if (Value *c = quantumCond(BB))
          qconds.push_back(c);
      }
      bool retMerge = rets.size() > 1 && !qconds.empty();

      for (BasicBlock *BB : order) {
        // the block's phis: a merge under a quantum condition depends on the deciding conditions
        // and on every incoming value
        if (!BB->phis().empty() && phiSh.size()) {
          std::vector<PHINode *> mine;
          for (PHINode &P : BB->phis())
            if (phiSh.count(&P))
              mine.push_back(&P);
          if (!mine.empty()) {
            std::vector<Value *> conds;
            BasicBlock *idom = nullptr;
            if (DomTreeNode *n = DT.getNode(BB))
              if (DomTreeNode *p = n->getIDom())
                idom = p->getBlock();
            SmallPtrSet<BasicBlock *, 16> seen;
            std::vector<BasicBlock *> work(pred_begin(BB), pred_end(BB));
            if (idom)
              work.push_back(idom);
            while (!work.empty()) {
              BasicBlock *X = work.back();
              work.pop_back();
              if (!reachable.count(X) || !seen.insert(X).second)
                continue;
              if (Value *c = quantumCond(X))
                conds.push_back(c);
              if (X != idom)
                for (BasicBlock *P : predecessors(X))
                  work.push_back(P);
            }
            IRBuilder<> B(&*BB->getFirstInsertionPt());
            Value *X = nullptr;
            if (!conds.empty()) {
              std::vector<Value *> deps;
              for (Value *c : conds)
                deps.push_back(availIn(c, BB));
              for (PHINode *P : mine)
                for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
                  if (reachable.count(P->getIncomingBlock(i)))
                    deps.push_back(availIn(P->getIncomingValue(i), BB));
              X = join(B, deps);
            }
            for (PHINode *P : mine) {
              PHINode *s = phiSh[P];
              if (X) {
                sh[P] = B.CreateCall(h3("__cqo_sh_v"), {s, X, zero()});
                continue;
              }
              std::vector<Value *> inc;
              for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
                if (reachable.count(P->getIncomingBlock(i)))
                  inc.push_back(soFar(P->getIncomingValue(i), B, [&](Instruction *J) {
                    return DT.properlyDominates(J->getParent(), BB);
                  }));
              sh[P] = nonZero(B, s, inc);
            }
          }
        }
        std::vector<Instruction *> insts;
        for (Instruction &I : *BB)
          if (!isa<PHINode>(I) && orig.count(&I))
            insts.push_back(&I);
        for (Instruction *I : insts)
          visit(I, retMerge, rets, qconds);
      }

      storeSlots();
      for (auto &[P, s] : phis)
        for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
          s->addIncoming(get(P->getIncomingValue(i)), P->getIncomingBlock(i));
      // tag what was added: the loop analyses below (trips: the header's test region) look at the
      // program as clang wrote it
      MDNode *tag = MDNode::get(F.getContext(), {});
      for (Instruction &I : instructions(F))
        if (!orig.count(&I))
          I.setMetadata("cqo.sh", tag);
    }

    uint64_t bytes(Type *T) { return In.DL.getTypeStoreSize(T).getFixedValue(); }

    void visit(Instruction *I, bool retMerge, const std::vector<ReturnInst *> &rets,
               const std::vector<Value *> &qconds) {
      if (I->isTerminator()) {
        IRBuilder<> B(I);
        if (auto *R = dyn_cast<ReturnInst>(I)) {
          if (Value *v = R->getReturnValue()) {
            Value *s = get(v);
            if (retMerge) {
              std::vector<Value *> deps{s};
              for (ReturnInst *O : rets)
                if (O != R)
                  deps.push_back(availAt(O->getReturnValue(), R));
              for (Value *c : qconds)
                deps.push_back(availAt(c, R));
              s = node(B, deps);
            } else if (rets.size() > 1) {
              bool qret = false;
              for (ReturnInst *O : rets)
                qret |= q(O->getReturnValue());
              if (qret) {
                std::vector<Value *> inc;
                for (ReturnInst *O : rets)
                  inc.push_back(O == R ? s : soFar(O->getReturnValue(), B, [&](Instruction *J) {
                    return DT.dominates(J, R);
                  }));
                s = nonZero(B, s, inc);
              }
            }
            B.CreateCall(h("__cqo_sh_ret_set", In.Void, {I32}), {s});
          }
          return;
        }
        if (Value *c = quantumCond(I->getParent())) {
          Region R = region(I->getParent());
          if (R.mem || R.fenv) {
            std::vector<Value *> deps = R.deps;
            deps.push_back(get(c));
            if (R.opaque)
              deps.push_back(opaque());
            if (R.mq) {
              deps.push_back(call0(B, "__cqo_sh_mq_get"));
              deps.push_back(call0(B, "__cqo_sh_gf_get"));
            }
            Value *d = join(B, deps);
            if (R.mem)
              B.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {d});
            if (R.fenv)
              B.CreateCall(h("__cqo_sh_gf", In.Void, {I32}), {d});
          }
        }
        if (isa<InvokeInst>(I) || isa<CallBrInst>(I))
          unimplemented("rule 2 shadows: invoke/callbr", I);
        return;
      }
      IRBuilder<> B(I->getNextNode());
      if (auto *LI = dyn_cast<LoadInst>(I)) {
        if (q(LI))
          sh[LI] = B.CreateCall(h("__cqo_sh_load", I32, {In.Ptr, In.I64, I32}),
                                {LI->getPointerOperand(), B.getInt64(bytes(LI->getType())),
                                 get(LI->getPointerOperand())});
        return;
      }
      if (auto *SI = dyn_cast<StoreInst>(I)) {
        B.CreateCall(h("__cqo_sh_store", In.Void, {In.Ptr, In.I64, I32, I32}),
                     {SI->getPointerOperand(), B.getInt64(bytes(SI->getValueOperand()->getType())),
                      get(SI->getValueOperand()), get(SI->getPointerOperand())});
        return;
      }
      if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I)) {
        Value *p = isa<AtomicRMWInst>(I) ? cast<AtomicRMWInst>(I)->getPointerOperand()
                                         : cast<AtomicCmpXchgInst>(I)->getPointerOperand();
        Type *VT = isa<AtomicRMWInst>(I) ? cast<AtomicRMWInst>(I)->getValOperand()->getType()
                                         : cast<AtomicCmpXchgInst>(I)->getNewValOperand()->getType();
        Value *old = B.CreateCall(h("__cqo_sh_load", I32, {In.Ptr, In.I64, I32}),
                                  {p, B.getInt64(bytes(VT)), get(p)});
        std::vector<Value *> deps{old};
        for (Value *op : I->operands())
          deps.push_back(get(op));
        Value *n = node(B, deps);
        B.CreateCall(h("__cqo_sh_store", In.Void, {In.Ptr, In.I64, I32, I32}), {p, B.getInt64(bytes(VT)), n, get(p)});
        if (q(I))
          sh[I] = n;
        return;
      }
      if (auto *CB = dyn_cast<CallBase>(I)) {
        visitCall(CB, B);
        return;
      }
      if (isa<AllocaInst>(I))
        return;
      if (isa<VAArgInst>(I)) {
        if (q(I))
          sh[I] = node(B, {call0(B, "__cqo_sh_gm_get"), call0(B, "__cqo_sh_mq_get")});
        return;
      }
      if (I->getType()->isVoidTy() || !q(I))
        return;
      if (auto *Sel = dyn_cast<SelectInst>(I))
        if (!q(Sel->getCondition()) && !Sel->getCondition()->getType()->isVectorTy()) {
          // a classical choice between rails: the chosen rail itself (a classical merge, as a phi's)
          Value *t = get(Sel->getTrueValue()), *f = get(Sel->getFalseValue());
          sh[I] = nonZero(B, B.CreateSelect(Sel->getCondition(), t, f), {t, f});
          return;
        }
      std::vector<Value *> deps;
      for (Value *op : I->operands())
        deps.push_back(get(op));
      sh[I] = node(B, deps);
    }

    void visitCall(CallBase *CB, IRBuilder<> &B) {
      Function *G = CB->getCalledFunction();
      std::vector<Value *> args;
      for (Value *a : CB->args())
        args.push_back(get(a));
      bool hasResult = !CB->getType()->isVoidTy();
      if (G && siteKind(G->getName()) >= 0) {
        int k = siteKind(G->getName());
        if (k == KTheta) {
          sh[CB] = B.CreateCall(h("__cqo_sh_leaf", I32, {}), {});
        } else if (k == KMeasure) {
          IRBuilder<> Bb(CB);
          Bb.CreateCall(h("__cqo_sh_measure", In.Void, {I32}), {args[0]});
          sh[CB] = args[0];  // dominated uses denote the outcome: the measured node, classical now
        }
        return;
      }
      if (CB->isInlineAsm()) {
        IRBuilder<> Ba(CB);
        Value *d = join(Ba, args);
        Ba.CreateCall(h("__cqo_sh_gf", In.Void, {I32}), {d});
        Ba.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {join(Ba, {d, call0(Ba, "__cqo_sh_mq_get")})});
        if (hasResult && q(CB))
          sh[CB] = node(B, {d, call0(B, "__cqo_sh_gm_get"), call0(B, "__cqo_sh_gf_get")});
        return;
      }
      if (G && G->isIntrinsic()) {
        if (auto *MS = dyn_cast<MemSetInst>(CB)) {
          Value *v = get(MS->getValue());
          Value *extra = join(B, {get(MS->getDest()), get(MS->getLength())});
          if (!isZero(v) || !isZero(extra))
            B.CreateCall(h("__cqo_sh_fill", In.Void, {In.Ptr, In.I64, I32}),
                         {MS->getDest(), B.CreateZExtOrTrunc(MS->getLength(), In.I64), join(B, {v, extra})});
          if (!isZero(extra))
            B.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {extra});
          return;
        }
        if (isa<MemTransferInst>(CB)) {
          Value *extra = join(B, args);
          if (!isZero(extra))
            B.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {extra});
          return;
        }
        if (isa<ConstrainedFPIntrinsic>(CB)) {
          // reads the rounding mode, raises into the flags: the result depends on the fp
          // environment as it was (review y1ll-n1)
          Value *env = call0(B, "__cqo_sh_gf_get");
          Value *d = join(B, args);
          if (!isZero(d))
            B.CreateCall(h("__cqo_sh_gf", In.Void, {I32}), {d});
          if (hasResult && q(CB))
            sh[CB] = node(B, {d, env});
          return;
        }
        if (hasResult && q(CB))
          sh[CB] = node(B, args);
        return;
      }
      if (G && !G->isDeclaration() && !isDriverFn(*G)) {
        IRBuilder<> Ba(CB);
        unsigned np = G->getFunctionType()->getNumParams();
        std::vector<Value *> va;
        for (unsigned i = 0; i < args.size(); ++i) {
          if (i >= np) {
            va.push_back(args[i]);
            continue;
          }
          Ba.CreateCall(h("__cqo_sh_arg_set", In.Void, {I32, I32}), {Ba.getInt32(i), args[i]});
          if (CB->isByValArgument(i))
            Ba.CreateCall(h("__cqo_sh_byval_src", In.Void, {I32, In.Ptr}), {Ba.getInt32(i), CB->getArgOperand(i)});
        }
        if (!va.empty()) {
          Value *d = join(Ba, va);
          if (!isZero(d))
            Ba.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {d});
        }
        if (hasResult) {
          Value *r = B.CreateCall(h("__cqo_sh_ret", I32, {}), {});
          if (q(CB))
            sh[CB] = r;
        }
        return;
      }
      if (!G) {
        // indirect: a body reads the slots and sets the result; a library callee leaves the preset
        IRBuilder<> Ba(CB);
        for (unsigned i = 0; i < args.size(); ++i)
          Ba.CreateCall(h("__cqo_sh_arg_set", In.Void, {I32, I32}), {Ba.getInt32(i), args[i]});
        Value *d = join(Ba, {join(Ba, args), call0(Ba, "__cqo_sh_mq_get")});
        Ba.CreateCall(h("__cqo_sh_gf", In.Void, {I32}), {d});
        Ba.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {d});
        Ba.CreateCall(h("__cqo_sh_ret_set", In.Void, {I32}),
                      {node(Ba, {d, call0(Ba, "__cqo_sh_gm_get"), call0(Ba, "__cqo_sh_gf_get")})});
        Value *r = B.CreateCall(h("__cqo_sh_ret", I32, {}), {});
        B.CreateCall(h("__cqo_sh_args_clear", In.Void, {}), {});
        if (hasResult && q(CB))
          sh[CB] = r;
        return;
      }
      // a library function (declared): allocation and memory moves are the runtime's; anything else
      // reads its arguments (and the fp environment), and through a pointer may read or write memory
      StringRef n = G->getName();
      if (isAllocator(n)) {
        if (hasResult && q(CB))
          sh[CB] = node(B, args);
        return;
      }
      if (isCopy(n) || isFill(n)) {
        Value *extra = join(B, isFill(n) && n != "bzero"
                                   ? std::vector<Value *>{args[0], args[2]}
                                   : args);
        if (isFill(n) && n != "bzero" && !isZero(args[1]))
          B.CreateCall(h("__cqo_sh_fill", In.Void, {In.Ptr, In.I64, I32}),
                       {CB->getArgOperand(0), B.CreateZExtOrTrunc(CB->getArgOperand(2), In.I64), join(B, {args[1], extra})});
        if (!isZero(extra))
          B.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {extra});
        if (hasResult && q(CB))
          sh[CB] = node(B, {extra});
        return;
      }
      IRBuilder<> Ba(CB);
      Value *d = join(Ba, args);
      if (!isZero(d))
        Ba.CreateCall(h("__cqo_sh_gf", In.Void, {I32}), {d});
      bool ptr = hasPtrArg(*CB);
      if (ptr && !G->onlyReadsMemory())  // fegetenv, fegetexceptflag: what it writes may be the fp state (y1ll-n1)
        Ba.CreateCall(h("__cqo_sh_gm", In.Void, {I32}),
                      {join(Ba, {d, call0(Ba, "__cqo_sh_mq_get"), call0(Ba, "__cqo_sh_gf_get")})});
      if (hasResult && q(CB)) {
        std::vector<Value *> deps{d, call0(B, "__cqo_sh_gf_get")};
        if (ptr) {
          deps.push_back(call0(B, "__cqo_sh_gm_get"));
          deps.push_back(call0(B, "__cqo_sh_mq_get"));
        }
        sh[CB] = node(B, deps);
      }
    }
  };

  void shadows() {
    if (!Taint)
      return;
    for (Function &F : M)
      if (!F.isDeclaration() && !isDriverFn(F))
        Shadow(*this, F, *Taint).run();
  }

  // ---------------------------------------------------------------- poison and §2 arithmetic
  void dropPoison(Function &F) {
    for (Instruction &I : instructions(F)) {
      I.dropPoisonGeneratingAnnotations();
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        // noundef/nonnull/range/align on call sites and their results promise nothing here.
        CB->removeRetAttrs(AttributeFuncs::getUBImplyingAttributes());
        for (unsigned i = 0; i < CB->arg_size(); ++i)
          CB->removeParamAttrs(i, AttributeFuncs::getUBImplyingAttributes());
      }
      if (isa<LoadInst>(I)) {
        I.setMetadata(LLVMContext::MD_nonnull, nullptr);
        I.setMetadata(LLVMContext::MD_range, nullptr);
        I.setMetadata(LLVMContext::MD_noundef, nullptr);
        I.setMetadata(LLVMContext::MD_align, nullptr);
        I.setMetadata(LLVMContext::MD_dereferenceable, nullptr);
        I.setMetadata(LLVMContext::MD_dereferenceable_or_null, nullptr);
      }
    }
  }

  static bool safeDivisor(Value *d, bool isSigned) {
    auto *ci = dyn_cast<ConstantInt>(d);
    if (!ci || ci->isZero())
      return false;
    return !(isSigned && ci->isMinusOne());
  }

  void rewriteDiv(BinaryOperator *BO) {
    IRBuilder<> B(BO);
    Value *a = BO->getOperand(0), *b = BO->getOperand(1);
    Type *T = BO->getType();
    Value *zero = Constant::getNullValue(T), *one = ConstantInt::get(T, 1);
    Value *bz = B.CreateICmpEQ(b, zero);
    Value *res;
    switch (BO->getOpcode()) {
    case Instruction::UDiv: {
      Value *q = B.CreateUDiv(a, B.CreateSelect(bz, one, b));
      res = B.CreateSelect(bz, Constant::getAllOnesValue(T), q);  // udiv(a,0) = 2^W - 1
      break;
    }
    case Instruction::URem: {
      Value *r = B.CreateURem(a, B.CreateSelect(bz, one, b));
      res = B.CreateSelect(bz, a, r);  // urem(a,0) = a
      break;
    }
    case Instruction::SDiv:
    case Instruction::SRem: {
      Value *ovf = B.CreateAnd(B.CreateICmpEQ(a, ConstantInt::get(T, APInt::getSignedMinValue(
                                                                         T->getScalarSizeInBits()))),
                               B.CreateICmpEQ(b, Constant::getAllOnesValue(T)));
      // INT_MIN / -1 divides by 1 instead: sdiv gives INT_MIN, srem gives 0 (CR §2).
      Value *safe = B.CreateSelect(B.CreateOr(bz, ovf), one, b);
      if (BO->getOpcode() == Instruction::SDiv) {
        Value *q = B.CreateSDiv(a, safe);
        Value *byZero = B.CreateSelect(B.CreateICmpSGE(a, zero), Constant::getAllOnesValue(T), one);
        res = B.CreateSelect(bz, byZero, q);  // sdiv(a,0) = -1 if a >= 0 else +1
      } else {
        Value *r = B.CreateSRem(a, safe);
        res = B.CreateSelect(bz, a, r);  // srem(a,0) = a
      }
      break;
    }
    default:
      llvm_unreachable("not a division");
    }
    BO->replaceAllUsesWith(res);
    res->takeName(BO);
    BO->eraseFromParent();
  }

  void rewriteShift(BinaryOperator *BO) {
    Value *amt = BO->getOperand(1);
    Type *T = BO->getType();
    unsigned W = T->getScalarSizeInBits();
    if (auto *ci = dyn_cast<ConstantInt>(amt))
      if (ci->getValue().ult(W))
        return;
    IRBuilder<> B(BO);
    Value *m = B.CreateURem(amt, ConstantInt::get(T, W));  // amount mod W (CR §2)
    BO->setOperand(1, m);
  }

  void rewriteFpToInt(CastInst *CI) {
    Type *dst = CI->getType(), *src = CI->getOperand(0)->getType();
    if (dst->isVectorTy())
      unimplemented("vector fptosi/fptoui", CI);
    unsigned W = dst->getIntegerBitWidth();
    if (W != 8 && W != 16 && W != 32 && W != 64)
      unimplemented("fptosi/fptoui to a width CR §2 does not tabulate", CI);
    bool sgn = CI->getOpcode() == Instruction::FPToSI;
    IRBuilder<> B(CI);
    Value *r;
    if (src->isX86_FP80Ty()) {
      r = B.CreateCall(hook("__cqo_fpto80", I64, {F80, I32, I32}),
                       {CI->getOperand(0), B.getInt32(W), B.getInt32(sgn)});
    } else if (src->isHalfTy() || src->isBFloatTy() || src->isFloatTy() || src->isDoubleTy()) {
      // f16, bf16 and f32 widen exactly; the table's c32/c64 on the widened value is the same (see runtime).
      Value *x = src->isDoubleTy() ? CI->getOperand(0) : B.CreateFPExt(CI->getOperand(0), Dbl);
      r = B.CreateCall(hook("__cqo_fpto64", I64, {Dbl, I32, I32}), {x, B.getInt32(W), B.getInt32(sgn)});
    } else {
      unimplemented("fptosi/fptoui from this fp type", CI);
    }
    Value *res = W == 64 ? r : B.CreateTrunc(r, dst);
    CI->replaceAllUsesWith(res);
    res->takeName(CI);
    CI->eraseFromParent();
  }

  // uitofp iN -> x86_fp80, N > 128: LLVM 19's ExpandLargeFpConvert sets the sign from the top bit
  // (a miscompile); CR §2 (cq-cqcj) gives the non-negative value, the magnitude (two roundings,
  // 113 bits then f80) being LLVM's. The sign bit is cleared on the integer image, which no fp fold
  // can drop.
  void fixWideUIToF80(CastInst *CI) {
    if (CI->getType()->isVectorTy() || !CI->getType()->isX86_FP80Ty() ||
        CI->getOperand(0)->getType()->getIntegerBitWidth() <= 128)
      return;
    IRBuilder<> B(CI->getNextNode());
    Type *I80 = B.getIntNTy(80);
    Value *bits = B.CreateBitCast(CI, I80);
    Value *pos = B.CreateAnd(bits, ConstantInt::get(I80, APInt::getSignedMaxValue(80)));
    Value *r = B.CreateBitCast(pos, CI->getType());
    CI->replaceUsesWithIf(r, [&](Use &U) { return U.getUser() != bits; });
  }

  void rewriteIntrinsic(IntrinsicInst *II) {
    switch (II->getIntrinsicID()) {
    case Intrinsic::abs:
    case Intrinsic::ctlz:
    case Intrinsic::cttz:
      // abs(INT_MIN) = INT_MIN, ctlz/cttz(0) = W (CR §2): the poison flag off.
      II->setArgOperand(1, ConstantInt::getFalse(C));
      return;
    case Intrinsic::maxnum:
    case Intrinsic::minnum: {
      // isnan(a) ? b : isnan(b) ? a : (b > a ? b : a), min with < (CR §2, measured x86 -O1).
      IRBuilder<> B(II);
      Value *a = II->getArgOperand(0), *b = II->getArgOperand(1);
      Value *pick = II->getIntrinsicID() == Intrinsic::maxnum ? B.CreateFCmpOGT(b, a)
                                                               : B.CreateFCmpOLT(b, a);
      Value *inner = B.CreateSelect(pick, b, a);
      Value *v = B.CreateSelect(B.CreateFCmpUNO(b, b), a, inner);
      v = B.CreateSelect(B.CreateFCmpUNO(a, a), b, v);
      II->replaceAllUsesWith(v);
      II->eraseFromParent();
      return;
    }
    case Intrinsic::fmuladd: {
      // Unfused: fmul then fadd, each rounded (CR §2; the x86-64 baseline has no FMA).
      IRBuilder<> B(II);
      Value *v = B.CreateFAdd(B.CreateFMul(II->getArgOperand(0), II->getArgOperand(1)),
                              II->getArgOperand(2));
      II->replaceAllUsesWith(v);
      II->eraseFromParent();
      return;
    }
    default:
      return;
    }
  }

  void totalize(Function &F) {
    std::vector<Instruction *> work;
    for (Instruction &I : instructions(F))
      work.push_back(&I);
    for (Instruction *I : work) {
      if (auto *BO = dyn_cast<BinaryOperator>(I)) {
        switch (BO->getOpcode()) {
        case Instruction::UDiv:
        case Instruction::URem:
          if (!safeDivisor(BO->getOperand(1), false))
            rewriteDiv(BO);
          break;
        case Instruction::SDiv:
        case Instruction::SRem:
          if (!safeDivisor(BO->getOperand(1), true))
            rewriteDiv(BO);
          break;
        case Instruction::Shl:
        case Instruction::LShr:
        case Instruction::AShr:
          rewriteShift(BO);
          break;
        default:
          break;
        }
      } else if (auto *CI = dyn_cast<CastInst>(I)) {
        if (CI->getOpcode() == Instruction::FPToSI || CI->getOpcode() == Instruction::FPToUI)
          rewriteFpToInt(CI);
        else if (CI->getOpcode() == Instruction::UIToFP)
          fixWideUIToF80(CI);
      } else if (auto *II = dyn_cast<IntrinsicInst>(I)) {
        rewriteIntrinsic(II);
      }
    }
  }

  // ---------------------------------------------------------------- the default environment
  // Owner ruling on cq-0r1i: a non-constrained fp operation (plain fadd, fmul, fcmp, casts, the
  // non-constrained fp intrinsics) means round-to-nearest with no flags raised, as LLVM defines it,
  // whatever mode the program set; only constrained intrinsics and the fenv/library calls see the
  // live environment. In a program that touches the environment (a fe* call, a constrained
  // intrinsic, a strictfp function), every such operation runs between __cqo_fpdfl_enter (save the
  // environment, install FE_DFL_ENV) and __cqo_fpdfl_leave (restore it, so its flags vanish). The
  // module is compiled at -O0, so nothing moves the operation out of the bracket. A program that
  // never touches the environment runs in the default one throughout and is left alone.
  bool touchesFenv() const {
    for (const Function &F : M) {
      if (F.hasFnAttribute(Attribute::StrictFP))
        return true;
      StringRef n = F.getName();
      if (n.starts_with("llvm.experimental.constrained."))
        return true;
      if (F.isDeclaration() && (n.starts_with("fe") || n.starts_with("__cqo_fe")) &&
          (n.contains("except") || n.contains("round") || n.contains("env")))
        return true;
    }
    return false;
  }

  static bool fpTyped(const Instruction &I) {
    if (I.getType()->isFPOrFPVectorTy())
      return true;
    for (const Value *op : I.operands())
      if (op->getType()->isFPOrFPVectorTy())
        return true;
    return false;
  }

  bool nonConstrainedFp(Instruction &I) {
    if (isa<ConstrainedFPIntrinsic>(I))
      return false;
    if (auto *II = dyn_cast<IntrinsicInst>(&I))
      return fpTyped(*II);
    if (auto *CI = dyn_cast<CallInst>(&I)) {
      // the §2 fp -> int rows the totalization put in the runtime
      Function *G = CI->getCalledFunction();
      return G && (G->getName() == "__cqo_fpto64" || G->getName() == "__cqo_fpto80");
    }
    if (isa<UnaryOperator>(I) || isa<BinaryOperator>(I) || isa<FCmpInst>(I) || isa<CastInst>(I))
      return fpTyped(I) && !isa<BitCastInst>(I);
    return false;
  }

  void defaultEnv(Function &F) {
    std::vector<Instruction *> work;
    for (Instruction &I : instructions(F))
      if (nonConstrainedFp(I))
        work.push_back(&I);
    FunctionCallee enter = hook("__cqo_fpdfl_enter", Void, {});
    FunctionCallee leave = hook("__cqo_fpdfl_leave", Void, {});
    for (Instruction *I : work) {
      if (I->getOpcode() == Instruction::FNeg)
        continue;  // a sign flip: no rounding, no flag
      IRBuilder<> B(I);
      B.CreateCall(enter, {});
      B.SetInsertPoint(I->getNextNode());
      B.CreateCall(leave, {});
    }
  }

  // ---------------------------------------------------------------- memory (CR §6)
  Value *allocaBytes(IRBuilder<> &B, AllocaInst *AI) {
    Value *n = B.getInt64(DL.getTypeAllocSize(AI->getAllocatedType()).getFixedValue());
    if (AI->isArrayAllocation())
      n = B.CreateMul(n, B.CreateZExtOrTrunc(AI->getArraySize(), I64));
    return n;
  }

  // The access's object (CR §6: a read outside *its* object reads 0, even where another object lies):
  // the pointer's underlying value through GEPs and casts. The runtime takes the object containing it,
  // or, when it lies in no object (a one-past-the-end pointer carried through a phi), the object
  // containing the accessed address.
  Value *base(Value *ptr) {
    return getUnderlyingObject(ptr, 0);
  }

  void memory(Function &F) {
    std::vector<AllocaInst *> allocas;
    std::vector<Instruction *> accesses, rets;
    for (Instruction &I : instructions(F)) {
      if (auto *AI = dyn_cast<AllocaInst>(&I))
        allocas.push_back(AI);
      else if (isa<LoadInst>(I) || isa<StoreInst>(I) || isa<AtomicRMWInst>(I) ||
               isa<AtomicCmpXchgInst>(I) || isa<CallBase>(I))
        accesses.push_back(&I);
      else if (isa<ReturnInst>(I))
        rets.push_back(&I);
      else if (isa<ResumeInst>(I))
        unimplemented("resume", &I);
    }

    // Frame mark after the leading allocas; every alloca registered (and zeroed) after the mark.
    BasicBlock &E = F.getEntryBlock();
    BasicBlock::iterator ip = E.getFirstInsertionPt();
    while (isa<AllocaInst>(*ip))
      ++ip;
    IRBuilder<> B(&*ip);
    Value *mark = B.CreateCall(hook("__cqo_mark", I64, {}), {});
    Instruction *cursor = cast<Instruction>(mark);
    for (AllocaInst *AI : allocas) {
      if (AI->getParent() == &E && AI->comesBefore(cast<Instruction>(mark))) {
        B.SetInsertPoint(cursor->getNextNode());
        cursor = B.CreateCall(hook("__cqo_alloca", Void, {Ptr, I64}), {AI, allocaBytes(B, AI)});
      } else {
        B.SetInsertPoint(AI->getNextNode());
        B.CreateCall(hook("__cqo_alloca", Void, {Ptr, I64}), {AI, allocaBytes(B, AI)});
      }
    }
    // A byval parameter is the callee's own copy of the argument (CR §6: an object of this frame,
    // holding the caller's value, so registered without zeroing), released with the frame.
    for (Argument &A : F.args())
      if (A.hasByValAttr()) {
        B.SetInsertPoint(cursor->getNextNode());
        cursor = B.CreateCall(hook("__cqo_object", Void, {Ptr, I64}),
                              {&A, B.getInt64(DL.getTypeAllocSize(A.getParamByValType()).getFixedValue())});
      }
    // A variadic function's frame learns its caller's stack-passed variadic bytes at entry (the
    // overflow area va_start points into); va_start registers that area and the register save area.
    VaBytes = nullptr;
    if (F.isVarArg()) {
      B.SetInsertPoint(cursor->getNextNode());
      VaBytes = B.CreateLoad(I64, vaBytesGlobal());
      cursor = cast<Instruction>(VaBytes);
    }
    for (Instruction *R : rets) {
      if (auto *CI = dyn_cast_or_null<CallInst>(R->getPrevNode()))
        if (CI->isMustTailCall())
          unimplemented("musttail call", CI);
      IRBuilder<> RB(R);
      RB.CreateCall(hook("__cqo_release", Void, {I64}), {mark});
    }

    DenseMap<Type *, AllocaInst *> tmps;
    auto tmpFor = [&](Type *T) {
      AllocaInst *&a = tmps[T];
      if (!a)
        a = entryAlloca(F, T);
      return a;
    };
    auto bytes = [&](Type *T) { return DL.getTypeStoreSize(T).getFixedValue(); };

    for (Instruction *I : accesses) {
      if (auto *LI = dyn_cast<LoadInst>(I)) {
        Type *T = LI->getType();
        if (T->isScalableTy())
          unimplemented("scalable load", LI);
        IRBuilder<> LB(LI);
        AllocaInst *t = tmpFor(T);
        LB.CreateCall(hook("__cqo_load", Void, {Ptr, I64, Ptr, Ptr}),
                      {LI->getPointerOperand(), LB.getInt64(bytes(T)), t, base(LI->getPointerOperand())});
        LoadInst *nl = LB.CreateLoad(T, t);
        LI->replaceAllUsesWith(nl);
        nl->takeName(LI);
        LI->eraseFromParent();
      } else if (auto *SI = dyn_cast<StoreInst>(I)) {
        Type *T = SI->getValueOperand()->getType();
        if (T->isScalableTy())
          unimplemented("scalable store", SI);
        IRBuilder<> SB(SI);
        AllocaInst *t = tmpFor(T);
        SB.CreateStore(SI->getValueOperand(), t);
        SB.CreateCall(hook("__cqo_store", Void, {Ptr, I64, Ptr, Ptr}),
                      {SI->getPointerOperand(), SB.getInt64(bytes(T)), t, base(SI->getPointerOperand())});
        SI->eraseFromParent();
      } else if (auto *RMW = dyn_cast<AtomicRMWInst>(I)) {
        IRBuilder<> AB(RMW);
        AB.CreateCall(hook("__cqo_require", Void, {Ptr, I64}),
                      {RMW->getPointerOperand(), AB.getInt64(bytes(RMW->getValOperand()->getType()))});
      } else if (auto *CX = dyn_cast<AtomicCmpXchgInst>(I)) {
        IRBuilder<> AB(CX);
        AB.CreateCall(hook("__cqo_require", Void, {Ptr, I64}),
                      {CX->getPointerOperand(), AB.getInt64(bytes(CX->getNewValOperand()->getType()))});
      } else if (auto *CB = dyn_cast<CallBase>(I)) {
        memoryCall(CB);
      }
    }
  }

  // ---------------------------------------------------------------- varargs (CR §6 objects)
  // x86-64 SysV: va_start points a va_list at the register save area (6 GP + 8 SSE registers, 176
  // bytes, in the callee's frame) and at the overflow area (the caller's stack-passed arguments past
  // the named ones). Neither is an alloca, global or heap block, so the oracle registers both as
  // objects of the variadic frame. The overflow area's size is known only at the call: every call
  // through a variadic function type stores the bytes its variadic arguments take on the stack into
  // __cqo_va_bytes, and the callee reads it at entry.
  Value *VaBytes = nullptr;
  GlobalVariable *VaBytesGV = nullptr;

  GlobalVariable *vaBytesGlobal() {
    if (!VaBytesGV) {
      VaBytesGV = M.getGlobalVariable("__cqo_va_bytes");
      if (!VaBytesGV)
        VaBytesGV = new GlobalVariable(M, I64, false, GlobalValue::ExternalLinkage, nullptr, "__cqo_va_bytes");
    }
    return VaBytesGV;
  }

  // The bytes the variadic arguments of CB occupy in the caller's outgoing stack area: the SysV
  // classification over the IR argument types (clang has already lowered the C types). Named
  // arguments use registers first; a variadic argument that finds no register goes to the stack,
  // 8-byte slots, 16-aligned for a 16-aligned type. A type outside the table is counted as stack.
  uint64_t variadicStackBytes(CallBase *CB) {
    FunctionType *FT = CB->getFunctionType();
    unsigned gp = 0, sse = 0;
    uint64_t off = 0;
    for (unsigned i = 0; i < CB->arg_size(); ++i) {
      Value *a = CB->getArgOperand(i);
      Type *T = a->getType();
      bool variadic = i >= FT->getNumParams();
      bool stack = false;
      uint64_t sz = 0, al = 8;
      if (CB->isByValArgument(i)) {
        Type *BT = CB->getParamByValType(i);
        stack = true;
        sz = DL.getTypeAllocSize(BT).getFixedValue();
        al = std::max<uint64_t>(8, CB->getParamAlign(i).valueOrOne().value());
      } else if (T->isPointerTy() || (T->isIntegerTy() && T->getIntegerBitWidth() <= 64)) {
        if (gp < 6)
          ++gp;
        else
          stack = true, sz = 8;
      } else if (T->isIntegerTy(128)) {
        if (gp < 5)
          gp += 2;
        else
          stack = true, sz = 16, al = 16;
      } else if (T->isFloatTy() || T->isDoubleTy() || T->isHalfTy() || T->isBFloatTy() || T->isFP128Ty() ||
                 (T->isVectorTy() && DL.getTypeAllocSize(T).getFixedValue() <= 16)) {
        if (sse < 8)
          ++sse;
        else
          stack = true, sz = DL.getTypeAllocSize(T).getFixedValue(),
          al = std::max<uint64_t>(8, DL.getABITypeAlign(T).value());
      } else {
        // x86_fp80 and anything else: memory class.
        stack = true;
        sz = DL.getTypeAllocSize(T).getFixedValue();
        al = std::max<uint64_t>(8, DL.getABITypeAlign(T).value());
      }
      if (!stack || !variadic)
        continue;  // a named stack argument lies before the overflow area va_start sees
      off = alignTo(off, al) + alignTo(sz, 8);
    }
    // va_arg may align the area's pointer up by 8 for a 16-aligned type.
    return off ? off + 8 : 0;
  }

  void memoryCall(CallBase *CB) {
    if (CB->getFunctionType()->isVarArg() && !isa<IntrinsicInst>(CB)) {
      IRBuilder<> B(CB);
      B.CreateStore(B.getInt64(variadicStackBytes(CB)), vaBytesGlobal());
    }
    if (auto *MI = dyn_cast<MemIntrinsic>(CB)) {
      IRBuilder<> B(CB);
      Value *n = B.CreateZExtOrTrunc(MI->getLength(), I64);
      if (auto *MS = dyn_cast<MemSetInst>(MI))
        B.CreateCall(hook("__cqo_imemset", Void, {Ptr, I8, I64, Ptr}),
                     {MS->getDest(), MS->getValue(), n, base(MS->getDest())});
      else if (isa<MemMoveInst>(MI))
        B.CreateCall(hook("__cqo_imemmove", Void, {Ptr, Ptr, I64, Ptr, Ptr}),
                     {MI->getDest(), cast<MemTransferInst>(MI)->getSource(), n, base(MI->getDest()),
                      base(cast<MemTransferInst>(MI)->getSource())});
      else if (isa<MemCpyInst>(MI))
        B.CreateCall(hook("__cqo_imemmove", Void, {Ptr, Ptr, I64, Ptr, Ptr}),
                     {MI->getDest(), cast<MemTransferInst>(MI)->getSource(), n, base(MI->getDest()),
                      base(cast<MemTransferInst>(MI)->getSource())});
      else
        unimplemented("memory intrinsic", CB);
      CB->eraseFromParent();
      return;
    }
    if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
      switch (II->getIntrinsicID()) {
      case Intrinsic::lifetime_start: {
        // An object entering its lifetime is indeterminate again: 0 (CR §6).
        IRBuilder<> B(II);
        B.CreateCall(hook("__cqo_zero", Void, {Ptr, I64}), {II->getArgOperand(1), II->getArgOperand(0)});
        return;
      }
      case Intrinsic::vastart: {
        if (!VaBytes)
          unimplemented("va_start outside a variadic function", II);
        IRBuilder<> B(II->getNextNode());
        B.CreateCall(hook("__cqo_va_start", Void, {Ptr, I64}), {II->getArgOperand(0), VaBytes});
        return;
      }
      case Intrinsic::memset_element_unordered_atomic:
      case Intrinsic::memcpy_element_unordered_atomic:
      case Intrinsic::memmove_element_unordered_atomic:
        unimplemented("element-atomic memory intrinsic", CB);
      case Intrinsic::masked_load:
      case Intrinsic::masked_store:
      case Intrinsic::masked_gather:
      case Intrinsic::masked_scatter:
      case Intrinsic::masked_expandload:
      case Intrinsic::masked_compressstore:
        unimplemented("masked memory intrinsic", CB);
      default:
        return;
      }
    }
  }

  // Library allocation, string-memory and thread entry points the runtime replaces wholesale.
  void replaceLibrary() {
    static const char *names[] = {"malloc", "calloc", "realloc", "reallocf", "free", "aligned_alloc",
                                  "posix_memalign", "valloc", "memcpy", "memmove", "memset", "memcmp",
                                  "bcmp", "bzero", "__memcpy_chk", "__memmove_chk", "__memset_chk", "pthread_create", "pthread_join", "pthread_detach",
                                  // fenv as rule 23 models it, not as the host libm does (cq-fvs2)
                                  "fetestexcept", "feclearexcept", "feraiseexcept", "fegetexceptflag",
                                  "fesetexceptflag", "fesetround", "feupdateenv"};
    for (const char *n : names) {
      Function *F = M.getFunction(n);
      if (!F)
        continue;
      if (!F->isDeclaration())
        continue;  // a body in the module (injected source) is instrumented like any code
      std::string repl = std::string("__cqo_") + n;
      FunctionCallee R = M.getOrInsertFunction(repl, F->getFunctionType());
      F->replaceAllUsesWith(R.getCallee());
    }
  }

  void registerGlobals() {
    std::vector<GlobalVariable *> gvs;
    for (GlobalVariable &G : M.globals()) {
      // The instrumentation's own globals (a driver's function-local static is "__cqo_drv_main.<v>",
      // a program object like any other, so the test is by exact prefix).
      if (G.getName().starts_with("llvm.") || G.getName().starts_with("__cqo_str") ||
          G.getName().starts_with("__cqo_spec_tab") || G.getName() == "__cqo_spec_next" ||
          G.getName() == "__cqo_va_bytes")
        continue;
      if (!G.getValueType()->isSized())
        continue;
      if (DL.getTypeAllocSize(G.getValueType()).getFixedValue() == 0)
        continue;
      gvs.push_back(&G);
    }
    Function *ctor = Function::Create(FunctionType::get(Void, false), GlobalValue::InternalLinkage,
                                      "__cqo_register_globals", M);
    IRBuilder<> B(BasicBlock::Create(C, "", ctor));
    FunctionCallee reg = hook("__cqo_global", Void, {Ptr, I64});
    for (GlobalVariable *G : gvs) {
      Value *addr = G;
      if (G->isThreadLocal())
        addr = B.CreateThreadLocalAddress(G);
      B.CreateCall(reg, {addr, B.getInt64(DL.getTypeAllocSize(G->getValueType()).getFixedValue())});
    }
    B.CreateRetVoid();
    appendToGlobalCtors(M, ctor, 0);
  }

  // ---------------------------------------------------------------- sites (cq_theta, cq_phi, ...)
  static int siteKind(StringRef n) {
    if (n.starts_with("cq_theta_"))
      return KTheta;
    if (n.starts_with("cq_measure_"))
      return KMeasure;
    if (n == "cq_phi")
      return KPhi;
    if (n == "__cq_invert_begin")
      return KInvBegin;
    if (n == "__cq_invert_end")
      return KInvEnd;
    return -1;
  }

  unsigned regBits(Type *T, Instruction *at) {
    if (T->isIntegerTy())
      return T->getIntegerBitWidth();
    if (T->isX86_FP80Ty())
      return 80;
    if (T->isHalfTy() || T->isBFloatTy() || T->isFloatTy() || T->isDoubleTy())
      return T->getPrimitiveSizeInBits();
    unimplemented("register type of a cq_theta/cq_measure site", at);
  }

  void sites(Function &F) {
    std::vector<CallInst *> calls;
    for (Instruction &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (Function *callee = CI->getCalledFunction())
          if (siteKind(callee->getName()) >= 0)
            calls.push_back(CI);
    FunctionCallee site = hook("__cqo_site", Void, {Ptr, I32, I32, I64, Ptr, I32});
    Constant *fn = str(F.getName());
    unsigned k = 0;
    for (CallInst *CI : calls) {
      int kind = siteKind(CI->getCalledFunction()->getName());
      IRBuilder<> B(CI);
      Value *angle = B.getInt64(0);
      Value *reg = ConstantPointerNull::get(cast<PointerType>(Ptr));
      unsigned bits = 0;
      AllocaInst *t = nullptr;
      if (kind == KTheta || kind == KMeasure) {
        Value *x = CI->getArgOperand(0);
        bits = regBits(x->getType(), CI);
        t = entryAlloca(F, x->getType());
        B.CreateStore(x, t);
        reg = t;
      }
      if (kind == KTheta || kind == KPhi) {
        Value *a = CI->getArgOperand(kind == KTheta ? 1 : 0);
        if (!a->getType()->isDoubleTy())
          unimplemented("site angle not a double", CI);
        angle = B.CreateBitCast(a, I64);
      }
      B.CreateCall(site, {fn, B.getInt32(k++), B.getInt32(kind), angle, reg, B.getInt32(bits)});
      if (t) {
        Value *v = B.CreateLoad(CI->getType(), t);
        CI->replaceAllUsesWith(v);
      }
      CI->eraseFromParent();
    }
  }

  // ---------------------------------------------------------------- trips
  // Every edge From -> To (a switch may have several) through one new block.
  BasicBlock *splitEdges(BasicBlock *From, BasicBlock *To) {
    BasicBlock *NB = BasicBlock::Create(C, "", From->getParent(), To);
    BranchInst::Create(To, NB);
    Instruction *T = From->getTerminator();
    for (unsigned i = 0; i < T->getNumSuccessors(); ++i)
      if (T->getSuccessor(i) == To)
        T->setSuccessor(i, NB);
    for (PHINode &P : To->phis()) {
      Value *v = P.getIncomingValueForBlock(From);
      while (P.getBasicBlockIndex(From) >= 0)
        P.removeIncomingValue(From, false);
      P.addIncoming(v, NB);
    }
    return NB;
  }

  // Block -> its label spelled as an operand ("%7", "%for.body", "%\"a b\"") in the input text,
  // taken through a ModuleSlotTracker before any pass below edits a function (erasing a non-void
  // call or adding a block renumbers the slots).
  DenseMap<const BasicBlock *, std::string> headerNames;

  void spellBlocks(const std::vector<Function *> &fns) {
    ModuleSlotTracker MST(&M);
    for (Function *F : fns) {
      MST.incorporateFunction(*F);
      for (BasicBlock &BB : *F) {
        std::string s;
        raw_string_ostream OS(s);
        BB.printAsOperand(OS, false, MST);
        headerNames[&BB] = OS.str();
      }
    }
  }

  void trips(Function &F) {
    DominatorTree DT(F);
    LoopInfo LI(DT);
    SmallVector<Loop *, 4> loops = LI.getLoopsInPreorder();
    if (loops.empty())
      return;
    FunctionCallee tick = hook("__cqo_tick", Void, {});
    FunctionCallee trip = hook("__cqo_trip", Void, {Ptr, I64, I32});
    FunctionCallee kcheck = hook("__cqo_kcheck", Void, {Ptr, I64, I64, I32});
    // edge -> [(loop id, counter, minus one, quantum-exit table)]; a nullptr counter is a guard skip.
    struct Rep { Constant *id; AllocaInst *cnt; bool minusOne; const std::vector<int32_t> *kq; };
    std::map<std::pair<BasicBlock *, BasicBlock *>, std::vector<Rep>> edges;
    std::vector<std::pair<std::pair<BasicBlock *, BasicBlock *>, unsigned>> order;
    auto add = [&](BasicBlock *a, BasicBlock *b, Rep r) {
      auto key = std::make_pair(a, b);
      if (!edges.count(key))
        order.push_back({key, (unsigned)order.size()});
      edges[key].push_back(r);
    };
    // The cutoff check (rule 14: the exit test after the K-th body): at the header, or, for a loop
    // that tests at a header that is not a latch, on the header's edges into the loop (a header run
    // that exits begins no trip, T1.2).
    struct Check { Constant *id; AllocaInst *cnt; const std::vector<int32_t> *kq; };
    std::vector<std::pair<BasicBlock *, Check>> headerChecks;
    std::vector<std::pair<std::pair<BasicBlock *, BasicBlock *>, Check>> edgeChecks;
    std::vector<std::pair<BasicBlock *, AllocaInst *>> headers;
    // Counters live in the entry block, zeroed once at function entry, reset on every exit.
    for (Loop *L : loops) {
      // T1.2: "<fn>:<header>", the header spelled as in the input text (captured before any edit).
      auto hn = headerNames.find(L->getHeader());
      if (hn == headerNames.end())
        unimplemented("loop header created by the instrumentation", L->getHeader()->getTerminator());
      Constant *cid = str((F.getName() + ":" + hn->second).str());
      AllocaInst *cnt = entryAlloca(F, I64);
      {
        IRBuilder<> B(cnt->getNextNode());
        B.CreateStore(B.getInt64(0), cnt);
      }
      BasicBlock *H = L->getHeader();
      headers.push_back({H, cnt});
      const std::vector<int32_t> *kq = nullptr;
      if (KI.on) {
        auto q = KI.qexit.find(H);
        if (q != KI.qexit.end())
          kq = &q->second;
      }
      // The header's test region (CR rule 14, header-tested loops 09, 37, 54, 189): the header plus
      // the blocks it reaches through single-predecessor in-loop edges that only compute and test
      // (no memory write, no call), none a latch. When the region holds an exit, a header run that
      // leaves through it only exits, and a trip begins on an edge from the region into the body
      // (54: the two tests x > k and x * c > m are one test split over two blocks).
      SmallPtrSet<BasicBlock *, 4> region;
      bool regionExits = false;
      {
        SmallVector<BasicBlock *, 4> work{H};
        region.insert(H);
        while (!work.empty()) {
          BasicBlock *B = work.pop_back_val();
          if (L->isLoopExiting(B))
            regionExits = true;
          for (BasicBlock *S : successors(B)) {
            if (!L->contains(S) || S == H || region.count(S) || S->getSinglePredecessor() != B ||
                L->isLoopLatch(S) || !L->isLoopExiting(S))
              continue;
            bool pure = true;
            for (Instruction &I : *S)
              if (!I.getMetadata("cqo.sh") &&  // rule 2 shadows (cq-y1ll) are not the program's
                  (I.mayWriteToMemory() || isa<CallBase>(I) || isa<PHINode>(I)))
                pure = false;
            if (pure) {
              region.insert(S);
              work.push_back(S);
            }
          }
        }
        if (L->isLoopLatch(H))
          regionExits = false;
      }
      if (kq) {
        if (regionExits) {
          for (BasicBlock *R : region)
            for (BasicBlock *S : successors(R))
              if (L->contains(S) && !region.count(S) &&
                  !std::count_if(edgeChecks.begin(), edgeChecks.end(), [&](auto &e) {
                    return e.first == std::make_pair(R, S);
                  }))
                edgeChecks.push_back({{R, S}, Check{cid, cnt, kq}});
        } else {
          headerChecks.push_back({H, Check{cid, cnt, kq}});
        }
      }
      SmallVector<Loop::Edge, 4> exits;
      L->getExitEdges(exits);
      for (auto &e : exits) {
        BasicBlock *from = const_cast<BasicBlock *>(e.first), *to = const_cast<BasicBlock *>(e.second);
        if (isa<IndirectBrInst>(from->getTerminator()) || isa<CallBrInst>(from->getTerminator()))
          unimplemented("loop exit from indirectbr/callbr", from->getTerminator());
        // A trip is begun at each header execution, except a final header run that only exits:
        // an exit from the header's test region (above).
        add(from, to, Rep{cid, cnt, regionExits && region.count(from), kq});
      }
      // Guard skip: an entering edge whose branch's other successor is an exit block reports 0.
      SmallVector<BasicBlock *, 4> exitBlocks;
      L->getExitBlocks(exitBlocks);
      // The guard may reach the header through out-of-loop blocks that each have a single
      // predecessor and branch unconditionally on (a preheader): the guard's taken edge is then
      // the only way into that chain, so its not-taken edge bypasses the header.
      for (BasicBlock *P0 : predecessors(H)) {
        if (L->contains(P0))
          continue;
        BasicBlock *to = H, *P = P0;
        SmallPtrSet<BasicBlock *, 8> seen;
        while (P && !L->contains(P) && seen.insert(P).second) {
          auto *br = dyn_cast<BranchInst>(P->getTerminator());
          if (!br)
            break;
          if (br->isConditional()) {
            BasicBlock *other = br->getSuccessor(0) == to ? br->getSuccessor(1) : br->getSuccessor(0);
            if (other != to && is_contained(exitBlocks, other))
              add(P, other, Rep{cid, nullptr, false, kq});
            break;
          }
          to = P;
          P = P->getSinglePredecessor();
        }
      }
    }
    auto kqValue = [&](IRBuilder<> &B, const std::vector<int32_t> *kq) -> Value * {
      return kq ? perSpec(B, F, *kq) : (Value *)B.getInt32(0);
    };
    for (auto &h : headers) {
      IRBuilder<> B(&*h.first->getFirstInsertionPt());
      Value *v = B.CreateLoad(I64, h.second);
      Value *n = B.CreateAdd(v, B.getInt64(1));
      B.CreateStore(n, h.second);
      B.CreateCall(tick, {});
      for (auto &c : headerChecks)
        if (c.first == h.first)
          B.CreateCall(kcheck, {c.second.id, n, B.getInt64(resolveK(F)), kqValue(B, c.second.kq)});
    }
    for (auto &o : order) {
      auto key = o.first;
      BasicBlock *mid = splitEdges(key.first, key.second);
      IRBuilder<> B(mid->getTerminator());
      for (Rep &r : edges[key]) {
        if (!r.cnt) {
          B.CreateCall(trip, {r.id, B.getInt64(0), kqValue(B, r.kq)});
          continue;
        }
        Value *n = B.CreateLoad(I64, r.cnt);
        if (r.minusOne)
          n = B.CreateSub(n, B.getInt64(1));
        B.CreateCall(trip, {r.id, n, kqValue(B, r.kq)});
        B.CreateStore(B.getInt64(0), r.cnt);
      }
    }
    for (auto &c : edgeChecks) {
      BasicBlock *mid = splitEdges(c.first.first, c.first.second);
      IRBuilder<> B(mid->getTerminator());
      B.CreateCall(kcheck, {c.second.id, B.CreateLoad(I64, c.second.cnt), B.getInt64(resolveK(F)),
                            kqValue(B, c.second.kq)});
    }
  }

  // ---------------------------------------------------------------- host effects (cq-e4jk)
  // The host-effect functions both sides log (compare.py HOST_EFFECTS; the evaluator's
  // checker/rt/host_fx.c): {"ev":"effect","name","args"}, a pointer argument read as a C string, an
  // integer at its IR width.
  const StringSet<> hostEffects = {"remove", "unlink", "rename", "raise"};

  void logEffect(CallBase *CB, StringRef name) {
    IRBuilder<> B(CB);
    B.CreateCall(hook("__cqo_fx_begin", Void, {Ptr}), {str(name)});
    for (Value *A : CB->args()) {
      Type *T = A->getType();
      if (T->isPointerTy()) {
        B.CreateCall(hook("__cqo_fx_str", Void, {Ptr}), {A});
      } else if (T->isIntegerTy() && T->getIntegerBitWidth() <= 64) {
        B.CreateCall(hook("__cqo_fx_int", Void, {I64, I32}),
                     {B.CreateZExt(A, I64), B.getInt32(T->getIntegerBitWidth())});
      } else {
        unimplemented("host effect argument type", CB);
      }
    }
    B.CreateCall(hook("__cqo_fx_end", Void, {}), {});
  }

  // ---------------------------------------------------------------- termination notes
  void notes(Function &F) {
    static const StringSet<> jumps = {"longjmp", "_longjmp", "siglongjmp", "__longjmp_chk"};
    std::vector<Instruction *> work;
    for (Instruction &I : instructions(F))
      work.push_back(&I);
    Constant *fn = str(F.getName());
    for (Instruction *I : work) {
      if (isa<UnreachableInst>(I)) {
        IRBuilder<> B(I);
        B.CreateCall(hook("__cqo_unreachable", Void, {Ptr}), {fn});
        continue;
      }
      auto *CB = dyn_cast<CallBase>(I);
      if (!CB)
        continue;
      if (isa<InvokeInst>(CB) || isa<CallBrInst>(CB))
        unimplemented("invoke/callbr", CB);
      Function *callee = CB->getCalledFunction();
      if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
        Intrinsic::ID id = II->getIntrinsicID();
        if (id == Intrinsic::trap || id == Intrinsic::debugtrap || id == Intrinsic::ubsantrap) {
          IRBuilder<> B(CB);
          B.CreateCall(hook("__cqo_noreturn", Void, {Ptr}), {str("llvm.trap")});
        }
        continue;
      }
      if (callee && callee->isDeclaration() && hostEffects.contains(callee->getName()))
        logEffect(CB, callee->getName());
      if (callee && callee->getName() == "raise" && CB->arg_size() == 1) {
        IRBuilder<> B(CB);
        B.CreateCall(hook("__cqo_raise_note", Void, {I32}),
                     {B.CreateZExtOrTrunc(CB->getArgOperand(0), I32)});
        continue;
      }
      bool noret = CB->doesNotReturn() || (callee && callee->doesNotReturn());
      if (!noret)
        continue;
      if (callee && (jumps.contains(callee->getName()) || !callee->isDeclaration() ||
                     callee->getName().starts_with("__cqo_")))
        continue;  // longjmp runs natively (rule 24); a defined callee reaches its own noreturn call
      IRBuilder<> B(CB);
      B.CreateCall(hook("__cqo_noreturn", Void, {Ptr}),
                   {str(callee ? callee->getName() : StringRef("<indirect>"))});
    }
  }

  // ---------------------------------------------------------------- undefined externals
  // The checker's model of a function nothing defines (rule 27 declared clones on the lowered side):
  // h = FNV-1a-64 offset; h = (h ^ b) * P for each byte of the name; then for each non-pointer scalar
  // argument, for each 64-bit word of its bit pattern (low word first, zero-extended):
  // h = (h ^ w) * P. The result is the low W bits of h (fp: as a bit pattern); void: nothing;
  // pointer result: null. No memory effect. One source with the evaluator: checker/rt/cq_standin.h
  // (cq-rft); __cqo_mix in cqo_rt.c is cq_standin_mix.
  void stubs() {
    if (StubsFile.empty())
      return;
    auto buf = MemoryBuffer::getFile(StubsFile);
    if (!buf)
      report_fatal_error(Twine("cq-oracle: cannot read ") + StubsFile, false);
    SmallVector<StringRef, 16> lines;
    (*buf)->getBuffer().split(lines, '\n', -1, false);
    FunctionCallee mix = hook("__cqo_mix", I64, {I64, I64});
    for (StringRef line : lines) {
      StringRef name = line.trim();
      if (name.empty())
        continue;
      Function *F = M.getFunction(name);
      if (!F || !F->isDeclaration())
        continue;
      F->setLinkage(GlobalValue::InternalLinkage);
      IRBuilder<> B(BasicBlock::Create(C, "", F));
      Value *h = B.getInt64(cq_standin_name(name.data(), name.size())); // checker/rt/cq_standin.h
      for (Argument &A : F->args()) {
        Type *T = A.getType();
        if (T->isPointerTy())
          continue;
        if (!T->isIntegerTy() && !T->isFloatingPointTy())
          unimplemented("modelled external with a non-scalar argument", F);
        unsigned bits = T->getPrimitiveSizeInBits();
        Value *v = T->isIntegerTy() ? (Value *)&A : B.CreateBitCast(&A, IntegerType::get(C, bits));
        unsigned words = (bits + 63) / 64;
        Type *wide = IntegerType::get(C, words * 64);
        Value *z = B.CreateZExt(v, wide);
        for (unsigned w = 0; w < words; ++w)
          h = B.CreateCall(mix, {h, B.CreateTrunc(B.CreateLShr(z, w * 64), I64)});
      }
      Type *R = F->getReturnType();
      if (R->isVoidTy())
        B.CreateRetVoid();
      else if (R->isPointerTy())
        B.CreateRet(ConstantPointerNull::get(cast<PointerType>(R)));
      else if (R->isIntegerTy() || R->isFloatingPointTy()) {
        unsigned bits = R->getPrimitiveSizeInBits();
        Value *iv = B.CreateZExtOrTrunc(h, IntegerType::get(C, bits));
        B.CreateRet(R->isIntegerTy() ? iv : B.CreateBitCast(iv, R));
      } else
        unimplemented("modelled external with a non-scalar result", F);
    }
  }

  // ---------------------------------------------------------------- the driver's call results
  // drivers.driver_source discards the result (`(void)fn(args)`): log it at the IR call instead.
  void entryResults(Function &F) {
    StringSet<> names;
    for (auto &e : Entries)
      names.insert(e);
    // In-clang use (CQO_AT_END, see llvmGetPassPluginInfo) passes the list as CQO_ENTRIES.
    if (const char *env = getenv("CQO_ENTRIES")) {
      SmallVector<StringRef, 8> parts;
      StringRef(env).split(parts, ',', -1, false);
      for (StringRef p : parts)
        names.insert(p);
    }
    if (names.empty())
      return;
    std::vector<CallInst *> calls;
    for (Instruction &I : instructions(F))
      if (auto *CI = dyn_cast<CallInst>(&I))
        if (Function *callee = CI->getCalledFunction())
          if (names.contains(callee->getName()))
            calls.push_back(CI);
    FunctionCallee ret = hook("__cqo_ret", Void, {Ptr, I32});
    for (CallInst *CI : calls) {
      IRBuilder<> B(CI->getNextNode());
      Type *T = CI->getType();
      if (T->isVoidTy()) {
        B.CreateCall(ret, {ConstantPointerNull::get(cast<PointerType>(Ptr)), B.getInt32(0)});
        continue;
      }
      unsigned bits = T->isIntegerTy() ? T->getIntegerBitWidth()
                      : T->isX86_FP80Ty() ? 80
                                          : (unsigned)DL.getTypeStoreSizeInBits(T).getFixedValue();
      AllocaInst *t = entryAlloca(F, T);
      B.CreateStore(CI, t);
      B.CreateCall(ret, {t, B.getInt32(bits)});
    }
  }

  void run() {
    analyseCutoffs();  // on the pristine module: taint answers for the program as clang wrote it
    {
      // block labels as the input spells them, before shadows() adds numbered values
      std::vector<Function *> pristine;
      for (Function &F : M)
        if (!F.isDeclaration())
          pristine.push_back(&F);
      spellBlocks(pristine);
    }
    shadows();         // rule 2 collapse, on the pristine module too (before stubs give bodies)
    if (KI.on) {
      SpecNext = M.getGlobalVariable("__cqo_spec_next");
      if (!SpecNext)
        SpecNext = new GlobalVariable(M, I32, false, GlobalValue::ExternalLinkage, nullptr, "__cqo_spec_next");
    }
    stubs();
    std::vector<Function *> defined;
    for (Function &F : M)
      if (!F.isDeclaration())
        defined.push_back(&F);
    for (Function *F : defined) {
      dropPoison(*F);
      totalize(*F);
    }
    if (touchesFenv())
      for (Function *F : defined)
        if (!isDriverFn(*F))
          defaultEnv(*F);
    // cq_* names used other than as a direct callee cannot be replaced by the identity.
    for (Function &F : M)
      if (siteKind(F.getName()) >= 0)
        for (User *U : F.users()) {
          auto *CB = dyn_cast<CallInst>(U);
          if (!CB || CB->getCalledOperand() != &F)
            unimplemented("cq_* function used other than as a direct callee", U);
        }
    for (Function *F : defined)
      if (!isDriverFn(*F))
        sites(*F);
      else
        entryResults(*F);
    for (Function *F : defined)
      memory(*F);
    replaceLibrary();
    for (Function *F : defined)
      notes(*F);
    for (Function *F : defined)
      if (!isDriverFn(*F))
        trips(*F);
    for (Function *F : defined)
      if (!isDriverFn(*F))
        specFlow(*F);
    registerGlobals();
    // The runtime owns `main`; a program's own main stays callable under another name.
    if (Function *Mn = M.getFunction("main"))
      if (!Mn->isDeclaration())
        Mn->setName("__cqo_user_main");
  }
};

struct OraclePass : PassInfoMixin<OraclePass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    Instrumenter(M).run();
    return PreservedAnalyses::none();
  }
};

}  // namespace

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "CQOracle", "0.1", [](PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](StringRef name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
                  if (name != "cq-oracle")
                    return false;
                  MPM.addPass(OraclePass());
                  return true;
                });
            // clang -fpass-plugin with CQO_AT_END=1: the instrumentation after clang's own pipeline,
            // so the driver compiles, instruments and links in one clang invocation.
            PB.registerOptimizerLastEPCallback([](ModulePassManager &MPM, OptimizationLevel) {
              if (getenv("CQO_AT_END"))
                MPM.addPass(OraclePass());
            });
          }};
}
