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
#include "../../pass/lib/calls/LibCalls.h"
#include "cq/SetjmpPair.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SetVector.h"
#include "cq/Taint.h"
// cq/Common.h routes the pass's unimplemented()/internalError() through site-naming macros; the oracle has its own.
#undef unimplemented
#undef internalError

#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/ADT/SCCIterator.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/CFG.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Analysis/VectorUtils.h"
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
  //    recursion when taint makes it one: under a quantum predicate, or in a `_ctl` clone already.
  //    An activation is entered by a call from outside the cycle whose callee specialization
  //    reaches such a level call through the cycle (or by the driver's call of a cycle member whose
  //    entry specialization does). Rule 14: only `_ctl` activations count, per function (cqo_rt.c
  //    __cqo_rec_down), so an entry under a quantum predicate is the first one counted (cq-rdsdj).
  //  - An indirect call is always a call of a table clone (rule 19): it stores -2 (`_t`) or -3
  //    (`_t_ctl`: a predicate in scope or an address rail), the frame takes its function's table
  //    specialization, and K is the caller's (__cqo_ptr_enter; cq-2in7d).
  struct KInfo {
    bool on = false;
    unsigned N = 0;
    DenseMap<const cq::Specialization *, unsigned> idOf;
    DenseMap<const Function *, unsigned> entry;                 // entry specialization id
    DenseMap<const Function *, bool> entryRec;                  // it is a quantum-depth recursion
    DenseMap<const Function *, bool> hasSpec;
    DenseMap<const BasicBlock *, std::vector<int32_t>> qexit;   // header -> QuantumExit per spec id
    DenseMap<const CallBase *, std::vector<int32_t>> callee;    // call -> callee spec id per spec id
    DenseMap<const CallBase *, std::vector<int32_t>> level;     // call -> recursion level per spec id
    DenseMap<const CallBase *, std::vector<int32_t>> recEntry;  // call -> enters an activation
    DenseMap<const CallBase *, std::vector<int32_t>> entryCtl;  // that entry's callee is a `_ctl` clone
    DenseMap<const CallBase *, std::vector<int32_t>> viaPtr;    // indirect call -> -2 or -3 per spec id
    DenseMap<const Function *, unsigned> tableT, tableCtl;      // the table specializations' ids
    DenseMap<const Function *, bool> tableRec;                  // reached through a row it is a quantum-depth recursion
  } KI;
  GlobalVariable *SpecNext = nullptr;
  DenseMap<Function *, AllocaInst *> specSlots;
  // Rule 20 per clone: a load one specialization holds as a rail and another as a classical host-resident load (an externally
  // visible function's table clone takes every formal as a handle, so its objects are bus-resident). The frame's specialization
  // answers at run time; id 0 (reached by a call that names none: through a pointer) takes any of them. Its flag operand is
  // set at the end of run(), when the frame slots stay put.
  struct RailLoad { CallInst *call; Function *F; std::vector<int32_t> vals; unsigned arg = 3; };
  std::vector<RailLoad> railLoads;

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
    DenseMap<const cq::Specialization *, unsigned> &idOf = KI.idOf;
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
        if (S.table)
          (S.ctl ? KI.tableCtl : KI.tableT)[&F] = i;
        for (Loop *L : LI.getLoopsInPreorder())
          if (cq::loops::classify(*L, T, S) == cq::loops::Case::QuantumExit) {
            auto &v = KI.qexit[L->getHeader()];
            v.resize(W, 0);
            v[i] = 1;
          }
        for (Instruction &I : instructions(F)) {
          auto *CB = dyn_cast<CallBase>(&I);
          if (CB && !CB->getCalledFunction() && !CB->isInlineAsm()) {
            auto &v = KI.viaPtr[CB];
            v.resize(W, -2);
            if (S.ctl || T.controlTainted(CB->getParent(), S) || T.isQuantum(CB->getCalledOperand(), S))
              v[i] = -3;
          }
          if (!CB || !directBody(*CB))
            continue;
          const Function *G = CB->getCalledFunction();
          const cq::Specialization *cs = T.calleeSpecialization(*CB, S);
          int32_t c = 0;
          if (cs && idOf.count(cs))
            c = idOf[cs];
          bool lvl = recursive(&F, G) && (S.ctl || T.controlTainted(CB->getParent(), S));
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
          auto &ec = KI.entryCtl[CB];
          ec.resize(W, 0);
          ec[i] = byId[v[i]]->ctl;
        }
    }
    for (auto &[F, i] : KI.entry)
      if (scc.count(F) && isQDepth(i))
        KI.entryRec[F] = true;
    for (auto *tab : {&KI.tableT, &KI.tableCtl})
      for (auto &[F, i] : *tab)
        if (scc.count(F) && isQDepth(i))
          KI.tableRec[F] = true;
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
    // through a pointer: its table clone (rule 19), of either kind where the other has no row
    unsigned idT = KI.tableT.lookup(&F), idC = KI.tableCtl.lookup(&F);
    Value *viaT = B.CreateICmpEQ(s0, B.getInt32(-2)), *viaC = B.CreateICmpEQ(s0, B.getInt32(-3));
    s = B.CreateSelect(viaT, B.getInt32(idT ? idT : idC), s);
    s = B.CreateSelect(viaC, B.getInt32(idC ? idC : idT), s);
    B.CreateStore(s, slot);
    Value *on = KI.entryRec.lookup(&F) ? fromDriver : B.getFalse();
    if (KI.tableRec.lookup(&F))
      on = B.CreateOr(on, B.CreateOr(viaT, viaC));
    if (KI.entryRec.lookup(&F) || KI.tableRec.lookup(&F))
      B.CreateCall(hook("__cqo_rec_enter", Void, {Ptr, I32, I32}),
                   {str((F.getName() + ":recursion").str()), B.CreateZExt(on, I32), B.CreateZExt(viaC, I32)});
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
    FunctionCallee enter = hook("__cqo_rec_enter", Void, {Ptr, I32, I32});
    FunctionCallee exitH = hook("__cqo_rec_exit", Void, {I32});
    FunctionCallee down = hook("__cqo_rec_down", Void, {Ptr, I64, I32});
    FunctionCallee up = hook("__cqo_rec_up", Void, {Ptr, I32});
    FunctionCallee ptrEnter = hook("__cqo_ptr_enter", I64, {I64});
    FunctionCallee ptrLeave = hook("__cqo_ptr_leave", Void, {I64});
    FunctionCallee pathEnter = hook("__cqo_path_enter", I64, {I64});
    FunctionCallee pathLeave = hook("__cqo_path_leave", Void, {I64});
    uint64_t site = hash_value(F.getName());
    for (CallBase *CB : calls) {
      IRBuilder<> B(CB);
      // the call sites an activation is reached through name it (cqo_rt.c next_act); a host call reaches none
      ++site;
      if (!isa<InvokeInst>(CB) && !isa<CallBrInst>(CB) && (!CB->getCalledFunction() || directBody(*CB))) {
        Value *savedPath = B.CreateCall(pathEnter, {B.getInt64(site * 0x9E3779B97F4A7C15ULL)});
        IRBuilder<> A(CB->getNextNode());
        A.CreateCall(pathLeave, {savedPath});
      }
      auto c = KI.callee.find(CB);
      auto vp = KI.viaPtr.find(CB);
      bool indirect = !CB->getCalledFunction() && !CB->isInlineAsm();
      Value *next = c != KI.callee.end() ? perSpec(B, F, c->second)
                    : vp != KI.viaPtr.end() ? perSpec(B, F, vp->second)
                    : indirect ? (Value *)B.getInt32(-2) : (Value *)B.getInt32(0);
      B.CreateStore(next, SpecNext);
      if (isa<InvokeInst>(CB) || isa<CallBrInst>(CB))
        continue;  // notes() already refused them
      if (indirect) {
        Value *saved = B.CreateCall(ptrEnter, {B.getInt64(resolveK(F))});
        IRBuilder<> A(CB->getNextNode());
        A.CreateCall(ptrLeave, {saved});
      }
      auto e = KI.recEntry.find(CB);
      if (e != KI.recEntry.end()) {
        Function *G = CB->getCalledFunction();
        Value *on = perSpec(B, F, e->second);
        B.CreateCall(enter, {str((G->getName() + ":recursion").str()), on, perSpec(B, F, KI.entryCtl[CB])});
        IRBuilder<> A(CB->getNextNode());
        A.CreateCall(exitH, {on});
      }
      auto l = KI.level.find(CB);
      if (l != KI.level.end()) {
        Value *on = perSpec(B, F, l->second);
        Function *G = CB->getCalledFunction();
        Constant *gn = str((G->getName() + ":recursion").str());
        B.CreateCall(down, {gn, B.getInt64(resolveK(*G)), on});
        IRBuilder<> A(CB->getNextNode());
        A.CreateCall(up, {gn, on});
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
  // The function's body is shared by its specializations (cq-gsms2): what taint holds as a rail in some of them and as
  // classical in the frame's is that frame's classical value (CR rule 2: "`cq_measure` of a value that never was a rail is
  // that value: no gate"), its node 0, and a condition quantum only in another specialization decides no quantum merge or
  // implicit write here. The frame's specialization answers at run time (railPick).
  // Rulings Q3: the measurement sites, numbered as sites() numbers them ("fn:ordinal", the C side's site key), and the
  // sites each function reaches through its calls (a call through a pointer: every address-taken function's).
  std::vector<std::string> msiteNames;
  DenseMap<const CallBase *, unsigned> msiteIdx;
  DenseMap<const Function *, BitVector> msiteReach;
  BitVector msiteTaken;
  bool msiteAny = false;
  void measureSites() {
    std::vector<Function *> fns;
    for (Function &F : M)
      if (!F.isDeclaration() && !isDriverFn(F))
        fns.push_back(&F);
    for (Function *F : fns) {
      unsigned k = 0;
      for (Instruction &I : instructions(*F))
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (Function *g = CI->getCalledFunction(); g && siteKind(g->getName()) >= 0) {
            if (siteKind(g->getName()) == KMeasure)
              msiteIdx[CI] = msiteNames.size(), msiteNames.push_back((F->getName() + ":" + Twine(k)).str());
            ++k;
          }
    }
    msiteAny = !msiteNames.empty();
    if (!msiteAny)
      return;
    unsigned N = msiteNames.size();
    for (Function *F : fns) {
      BitVector b(N);
      for (Instruction &I : instructions(*F))
        if (auto it = msiteIdx.find(dyn_cast<CallBase>(&I)); isa<CallBase>(&I) && it != msiteIdx.end())
          b.set(it->second);
      msiteReach[F] = b;
    }
    msiteTaken = BitVector(N);
    for (bool changed = true; changed;) {
      changed = false;
      BitVector taken(N);
      for (Function *F : fns)
        if (F->hasAddressTaken())
          taken |= msiteReach[F];
      if (taken != msiteTaken)
        msiteTaken = taken, changed = true;
      for (Function *F : fns) {
        BitVector b = msiteReach[F];
        for (Instruction &I : instructions(*F))
          if (auto *CB = dyn_cast<CallBase>(&I))
            b |= calleeSites(*CB);
        if (b != msiteReach[F])
          msiteReach[F] = b, changed = true;
      }
    }
  }
  BitVector calleeSites(const CallBase &CB) {
    BitVector none(msiteNames.size());
    if (CB.isInlineAsm())
      return none;
    const Function *G = CB.getCalledFunction();
    if (!G)
      return msiteTaken.size() ? msiteTaken : none;
    auto it = msiteReach.find(G);
    return it == msiteReach.end() ? none : it->second;
  }
  std::optional<cq::TaintInfo> Taint;

  struct Shadow {
    Instrumenter &In;
    Function &F;
    const cq::TaintInfo &T;
    std::vector<const cq::Specialization *> specs;
    DominatorTree DT;
    PostDominatorTree PDT;
    LoopInfo LI;
    DenseMap<const Value *, Value *> sh;
    DenseMap<const Value *, Value *> carriedIn;  // a loop header's phi -> the shadow of the incoming it took
    SmallPtrSet<const Instruction *, 32> orig;  // the function as clang wrote it: taint knows only these
    Type *I32;
    // Values taint calls classical that still carry a shadow (cq-425g): a read of a variadic
    // actual through the va_list's save areas (clang -O1 expands va_arg into loads from the
    // reg_save_area / overflow_arg_area, which taint does not see as reading the actuals), the
    // result of a call whose callee returns such a value (`retCarried`), and every value computed
    // from one. Their shadow is the plain data flow (no rail semantics: taint holds them as no rail).
    const DenseSet<const Function *> &retCarried;
    SmallPtrSet<const Value *, 32> extra;

    Shadow(Instrumenter &In, Function &F, const cq::TaintInfo &T, const DenseSet<const Function *> &rc)
        : In(In), F(F), T(T), DT(F), PDT(F), LI(DT), retCarried(rc) {
      I32 = In.I32;
      for (const cq::Specialization &S : T.specializations())
        if (S.F == &F)
          specs.push_back(&S);
      for (Instruction &I : instructions(F))
        orig.insert(&I);
      closeExtra();
    }

    // an alloca va_start or va_copy initializes
    static bool isVaList(const Value *P) {
      P = P->stripInBoundsConstantOffsets();
      if (!isa<AllocaInst>(P))
        return false;
      for (const User *U : P->users())
        if (auto *II = dyn_cast<IntrinsicInst>(U))
          if (II->getIntrinsicID() == Intrinsic::vastart || II->getIntrinsicID() == Intrinsic::vacopy)
            return true;
      return false;
    }
    // a load through a pointer read from a va_list (a save area), moved by GEPs and merged by
    // phis/selects: clang's expansion of va_arg
    static bool isVaRead(const LoadInst *L) {
      SmallPtrSet<const Value *, 16> seen;
      std::vector<const Value *> work{L->getPointerOperand()};
      while (!work.empty()) {
        const Value *V = work.back();
        work.pop_back();
        if (!seen.insert(V).second)
          continue;
        if (auto *G = dyn_cast<GEPOperator>(V))
          work.push_back(G->getPointerOperand());
        else if (auto *P = dyn_cast<PHINode>(V))
          for (const Value *in : P->incoming_values())
            work.push_back(in);
        else if (auto *S = dyn_cast<SelectInst>(V))
          work.push_back(S->getTrueValue()), work.push_back(S->getFalseValue());
        else if (auto *X = dyn_cast<LoadInst>(V)) {
          if (isVaList(X->getPointerOperand()))
            return true;
        }
      }
      return false;
    }
    void closeExtra() {
      std::vector<const Value *> work;
      auto add = [&](const Value *V) {
        if (!q(V) && extra.insert(V).second)
          work.push_back(V);
      };
      for (Instruction &I : instructions(F)) {
        if (auto *L = dyn_cast<LoadInst>(&I); L && isVaRead(L))
          add(L);
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (Function *G = CB->getCalledFunction(); G && retCarried.count(G) && !CB->getType()->isVoidTy())
            add(CB);
      }
      while (!work.empty()) {
        const Value *V = work.back();
        work.pop_back();
        for (const User *U : V->users()) {
          auto *I = dyn_cast<Instruction>(U);
          if (!I || !orig.count(I) || I->isTerminator() || I->getType()->isVoidTy())
            continue;
          if (auto *CB = dyn_cast<CallBase>(I)) {
            Function *G = CB->getCalledFunction();
            // a body's result is the callee's (retCarried); a site's is its own
            if (!G || !G->isDeclaration() || siteKind(G->getName()) >= 0)
              continue;
          }
          add(I);
        }
      }
    }
    bool carried(const Value *V) const { return q(V) || extra.count(V); }
    // a returned value carried only through `extra`: callers' results carry it too
    bool returnsExtra() const {
      for (const BasicBlock &BB : F)
        if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
          if (Value *v = R->getReturnValue(); v && extra.count(v))
            return true;
      return false;
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
    // The frame's specialization chooses: `a` where some value of `vs` is quantum in it (id 0, a frame no call named: `a`),
    // else `b`. Plainly `a` when that holds in every specialization.
    Value *railPick(IRBuilder<> &B, ArrayRef<const Value *> vs, Value *a, Value *b) {
      if (!In.KI.on)
        return a;
      std::vector<int32_t> rail(In.KI.N + 1, 0);
      rail[0] = 1;
      bool mixed = false;
      for (const cq::Specialization *S : specs) {
        auto id = In.KI.idOf.find(S);
        if (id == In.KI.idOf.end())
          continue;
        rail[id->second] = any_of(vs, [&](const Value *v) { return T.isQuantum(v, *S); });
        mixed |= !rail[id->second];
      }
      if (!mixed)
        return a;
      auto *c = B.CreateCall(h("__cqo_sh_pick", I32, {I32, I32, I32}), {a, b, B.getInt32(1)});
      In.railLoads.push_back({c, &F, std::move(rail), 2});
      return c;
    }
    // Rulings Q3 (2026-11-11, part 2): the conditions by which the C run leaves the path to a measurement site. A conditional
    // branch (br, switch) at b decides the arms between b and its immediate post-dominator J (an arm: the blocks a successor
    // reaches before J or b; a loop's exit test: the remaining trips). Where the arms not taken hold measurement sites (in
    // their blocks, or in the functions their calls reach, In.msiteReach) that the taken arm does not, the run logs them with
    // whether the condition is quantum there (its node not classical under rule 2's static collapse, cqo_rt.c __cqo_skip):
    // the circuit runs a quantum branch's arms all, unconditionally (rule 2), and a classical one's taken arm only (rule 8).
    void skips(const std::vector<BasicBlock *> &order) {
      if (!In.msiteAny || !In.msiteReach.count(&F) || In.msiteReach[&F].none())
        return;
      unsigned N = In.msiteNames.size();
      DenseMap<const BasicBlock *, BitVector> local;
      for (BasicBlock *BB : order) {
        BitVector b(N);
        for (Instruction &I : *BB)
          if (auto *CB = dyn_cast<CallBase>(&I); CB && orig.count(CB)) {
            if (auto it = In.msiteIdx.find(CB); it != In.msiteIdx.end())
              b.set(it->second);
            b |= In.calleeSites(*CB);
          }
        local[BB] = b;
      }
      auto arm = [&](BasicBlock *b, BasicBlock *s, BasicBlock *J) {
        BitVector r(N);
        SmallPtrSet<BasicBlock *, 32> seen;
        SmallVector<BasicBlock *, 16> w{s};
        while (!w.empty()) {
          BasicBlock *x = w.pop_back_val();
          if (x == J || !seen.insert(x).second)
            continue;
          if (auto l = local.find(x); l != local.end())
            r |= l->second;   // b itself, reached again: the next trip's part of it before its test
          if (x == b)
            continue;
          for (BasicBlock *y : successors(x))
            w.push_back(y);
        }
        return r;
      };
      for (BasicBlock *BB : order) {
        Instruction *Tm = BB->getTerminator();
        if (!orig.count(Tm) || Tm->getNumSuccessors() < 2 || !(isa<BranchInst>(Tm) || isa<SwitchInst>(Tm)))
          continue;
        BasicBlock *J = PDT.getNode(BB) && PDT.getNode(BB)->getIDom() ? PDT.getNode(BB)->getIDom()->getBlock() : nullptr;
        std::vector<BitVector> arms;
        BitVector all(N);
        for (unsigned k = 0; k < Tm->getNumSuccessors(); ++k)
          arms.push_back(arm(BB, Tm->getSuccessor(k), J)), all |= arms.back();
        if (all.none())
          continue;
        std::vector<std::pair<Value *, unsigned>> lists;   // per successor index: (list, length)
        bool anyList = false;
        for (unsigned k = 0; k < Tm->getNumSuccessors(); ++k) {
          BitVector d = all;
          d.reset(arms[k]);
          std::vector<Constant *> names;
          for (unsigned i : d.set_bits())
            names.push_back(In.str(In.msiteNames[i]));
          anyList |= !names.empty();
          if (names.empty()) {
            lists.push_back({ConstantPointerNull::get(cast<PointerType>(In.Ptr)), 0});
            continue;
          }
          auto *AT = ArrayType::get(In.Ptr, names.size());
          auto *gv = new GlobalVariable(In.M, AT, true, GlobalValue::PrivateLinkage, ConstantArray::get(AT, names),
                                        "__cqo_skip_list");
          lists.push_back({gv, (unsigned)names.size()});
        }
        if (!anyList)
          continue;
        IRBuilder<> B(Tm);
        Value *cond = condOf(Tm);
        Value *list, *n;
        if (auto *BI = dyn_cast<BranchInst>(Tm)) {
          list = B.CreateSelect(cond, lists[0].first, lists[1].first);
          n = B.CreateSelect(cond, B.getInt32(lists[0].second), B.getInt32(lists[1].second));
        } else {
          auto *SI = cast<SwitchInst>(Tm);
          list = lists[0].first, n = B.getInt32(lists[0].second);   // successor 0: the default
          for (auto &c : SI->cases()) {
            unsigned k = c.getSuccessorIndex();
            Value *hit = B.CreateICmpEQ(cond, c.getCaseValue());
            list = B.CreateSelect(hit, lists[k].first, list);
            n = B.CreateSelect(hit, B.getInt32(lists[k].second), n);
          }
        }
        B.CreateCall(h("__cqo_skip", In.Void, {I32, In.Ptr, I32}), {get(cond), list, n});
      }
    }
    // CR rule 2, 406-408 (cq-ndtt): collapse is STATIC, "it applies to a value whose quantum sources are measured on EVERY
    // path reaching it". The runtime marks the measured node at the measurement and every later reader of the sample sees it
    // classical, so a measurement M of root v may mark only when no reader it reaches is reached from v's definition by a
    // path that measures nothing (pm_join: y measured in a classical arm, y * 3 read after the join, stays a rail on every
    // path). Readers: the cq_measure sites and the branches whose operand depends on v by SSA (through memory not seen:
    // known limit). A path ends at v's definition (a new instance) and at a measurement of v; a quantum branch is no choice
    // (rule 2: a measurement in its region runs on every path through it), as in the pass's cq::measuredOnEveryPath. A
    // formal or a loaded value is the caller's or the cell's rail: it collapses only when also measured on every path to a
    // return (cq::measuredOnEveryPath; CR 406-410: a clone measuring a rail on some paths leaves the caller's rail alone).
    // `of`: the value judged instead of M's operand (a header phi's incoming M reads this trip, below); M itself is then no
    // measurement of it, and its readers through the measured phi are M's own (covered by M): only its other readers count
    // (measure_carried: x0 read by x's header phi and so by the exit test; cq-2z29a's v0 read through v's phi alone).
    bool staticCollapse(const CallBase *M, function_ref<bool(const Value *)> isQ, const Value *of = nullptr) {
      auto strip = [](const Value *x) {
        while (auto *f = dyn_cast<FreezeInst>(x))
          x = f->getOperand(0);
        return x;
      };
      const Value *root = strip(of ? of : M->getArgOperand(0));
      if (!isa<Argument>(root) && !isa<Instruction>(root))
        return true;
      auto isMeas = [&](const Instruction &I) {
        auto *c = dyn_cast<CallInst>(&I);
        return c && orig.count(c) && c->getCalledFunction() && c->getCalledFunction()->getName().starts_with("cq_measure") &&
               c->arg_size() == 1 && strip(c->getArgOperand(0)) == root;
      };
      const auto *defI = isa<LoadInst>(root) || isa<AtomicRMWInst>(root) || isa<AtomicCmpXchgInst>(root) ||
                                 (isa<ExtractValueInst>(root) &&
                                  isa<AtomicCmpXchgInst>(cast<ExtractValueInst>(root)->getAggregateOperand()))
                             ? nullptr
                             : dyn_cast<Instruction>(root);
      if (!defI && !cq::measuredOnEveryPath(isQ, root, of ? nullptr : M))
        return false;
      BasicBlock *D = defI ? const_cast<BasicBlock *>(defI->getParent()) : &F.getEntryBlock();
      // the readers of v: values depending on it by SSA, and the cq_measure calls and branches reading one of them
      SmallPtrSet<const Value *, 32> dep;
      std::vector<const Value *> w{root};
      dep.insert(root);
      while (!w.empty()) {
        const Value *x = w.back();
        w.pop_back();
        for (const User *U : x->users())
          if (auto *I = dyn_cast<Instruction>(U); I && orig.count(I) && !I->getType()->isVoidTy() &&
                                                  !(of && I == M->getArgOperand(0)) && dep.insert(I).second)
            w.push_back(I);
      }
      auto reader = [&](const Instruction &I) {
        if (!orig.count(&I))
          return false;
        if (auto *c = dyn_cast<CallInst>(&I); c && c->getCalledFunction() &&
                                              c->getCalledFunction()->getName().starts_with("cq_measure"))
          return dep.count(c->getArgOperand(0)) > 0;
        if (I.isTerminator() && I.getNumSuccessors() > 1)
          if (Value *c = condOf(const_cast<Instruction *>(&I)))
            return dep.count(c) > 0;
        return false;
      };
      // A block's entry is uncovered when a path from v's definition reaches it measuring nothing.
      auto quantumBranch = [&](const BasicBlock *b) {
        Value *c = condOf(const_cast<Instruction *>(b->getTerminator()));
        return c && b->getTerminator()->getNumSuccessors() > 1 && isQ(c);
      };
      auto measuredIn = [&](const BasicBlock *b) { return any_of(*b, isMeas); };
      // The pass's region rule (cq::measuredOnEveryPath): a quantum branch whose region up to its post-dominator holds a
      // measurement reached through quantum branches (a classical branch inside passed at its post-dominator).
      auto sureMeasured = [&](const BasicBlock *b) {
        const BasicBlock *J = PDT.getNode(b) && PDT.getNode(b)->getIDom() ? PDT.getNode(b)->getIDom()->getBlock() : nullptr;
        SmallPtrSet<const BasicBlock *, 16> reg, sure;
        SmallVector<const BasicBlock *, 16> ws(succ_begin(b), succ_end(b));
        while (!ws.empty()) {
          const BasicBlock *x = ws.pop_back_val();
          if (x == J || x == b || !reg.insert(x).second)
            continue;
          for (const BasicBlock *s : successors(x))
            ws.push_back(s);
        }
        ws.assign(succ_begin(b), succ_end(b));
        while (!ws.empty()) {
          const BasicBlock *x = ws.pop_back_val();
          if (x == J || x == b || !reg.count(x) || !sure.insert(x).second)
            continue;
          if (measuredIn(x))
            return true;
          const Instruction *t = x->getTerminator();
          if (t->getNumSuccessors() > 1 && !quantumBranch(x))
            if (auto *n = PDT.getNode(x); n && n->getIDom() && n->getIDom()->getBlock()) {
              ws.push_back(n->getIDom()->getBlock());
              continue;
            }
          for (const BasicBlock *s : successors(x))
            ws.push_back(s);
        }
        return false;
      };
      SmallPtrSet<const BasicBlock *, 32> unc;
      {
        // from the definition to the end of D
        for (const Instruction *I = defI ? defI->getNextNode() : &D->front(); I; I = I->getNextNode())
          if (isMeas(*I))
            return true;   // every path from the definition passes this measurement
        SmallVector<const BasicBlock *, 16> ws;
        auto from = [&](const BasicBlock *b) {
          if (quantumBranch(b) && sureMeasured(b))
            return;
          for (const BasicBlock *s : successors(b))
            ws.push_back(s);
        };
        from(D);
        while (!ws.empty()) {
          const BasicBlock *x = ws.pop_back_val();
          if (x == D || !unc.insert(x).second || measuredIn(x))
            continue;
          from(x);
        }
      }
      // the readers M reaches (up to v's next definition): none may be uncovered
      auto uncoveredReader = [&](const BasicBlock *b, const Instruction *after) {
        bool covered = !unc.count(b) || after;
        for (const Instruction &I : *b) {
          if (after && (&I == after || I.comesBefore(after)))
            continue;
          if (isMeas(I))
            covered = true;
          else if (!covered && reader(I))
            return true;
        }
        return false;
      };
      SmallPtrSet<const BasicBlock *, 32> seen;
      SmallVector<const BasicBlock *, 16> ws(succ_begin(M->getParent()), succ_end(M->getParent()));
      while (!ws.empty()) {
        const BasicBlock *x = ws.pop_back_val();
        if (x == D || !seen.insert(x).second)
          continue;
        if (uncoveredReader(x, nullptr))
          return false;
        for (const BasicBlock *s : successors(x))
          ws.push_back(s);
      }
      return true;
    }
    // The frame's specialization answers at run time; a frame no call named (id 0, through a pointer) collapses when some
    // specialization does. None collapses in a _ctl clone (rule 19's controlled copy) or a table clone (§1.4: a kept copy is
    // measured). Computed on the function as clang wrote it (orig; Shadow adds instructions, no blocks).
    // `of` empty: M's operand; else every value of `of` (the incomings of a measured header phi, for __cqo_sh_mark).
    Value *collapses(IRBuilder<> &B, CallBase *CB, ArrayRef<const Value *> of = {}) {
      std::vector<int32_t> vals(In.KI.on ? In.KI.N + 1 : 1, 0);
      bool any = false, all = true;
      auto judge = [&](function_ref<bool(const Value *)> isQ) {
        if (of.empty())
          return staticCollapse(CB, isQ);
        return all_of(of, [&](const Value *v) { return staticCollapse(CB, isQ, v); });
      };
      for (const cq::Specialization *S : specs) {
        bool e = !S->table && !S->ctl && judge([&](const Value *x) { return T.isQuantum(x, *S); });
        any |= e, all &= e;
        if (In.KI.on)
          if (auto id = In.KI.idOf.find(S); id != In.KI.idOf.end())
            vals[id->second] = e;
      }
      if (specs.empty())
        any = all = judge([](const Value *) { return false; });
      if (all == any || !In.KI.on)
        return B.getInt32(any);
      vals[0] = any;
      auto *c = B.CreateCall(h("__cqo_sh_pick", I32, {I32, I32, I32}), {B.getInt32(1), B.getInt32(0), B.getInt32(1)});
      In.railLoads.push_back({c, &F, std::move(vals), 2});
      return c;
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
      if (!J || !carried(J))
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
      if (!J || !carried(J))
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
      if (!J || !carried(J))
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
      // CR rule 13 (b137e75): a computed goto is a switch on its address.
      if (auto *IB = dyn_cast<IndirectBrInst>(Term))
        return IB->getAddress();
      return nullptr;
    }
    Value *quantumCond(BasicBlock *X) {
      Instruction *Term = X->getTerminator();
      if (!Term || Term->getNumSuccessors() < 2)
        return nullptr;
      Value *c = condOf(Term);
      if (!c) {
        if (isa<CallBrInst>(Term))
          unimplemented("rule 2 shadows: asm goto (callbr): inline asm (rule 27) waits for its CQ_spec example", Term);
        return nullptr;
      }
      if (!q(c) && exitLoop(c, Term))
        unimplemented("rule 2 shadows: a branch after a quantum-exit loop on a classical value of the loop "
                      "(an exit read, CR rule 14)",
                      Term);
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
    static bool deliversSignal(const CallBase &CB) {
      const Function *G = CB.getCalledFunction();
      if (!G)
        return false;
      StringRef n = G->getName();
      return n == "raise" || n == "kill" || n == "pthread_kill";
    }
    static bool runsModuleCode(const CallBase &CB) {
      if (deliversSignal(CB))
        return true;
      for (const Value *a : CB.args())
        if (isa<Function>(a->stripPointerCasts()))
          return true;
      return false;
    }
    // A module function whose every write is a function of its arguments (cq-vo6v): it loads
    // nothing and calls nothing but debug/lifetime/assume intrinsics, so what it writes, had the arm
    // run it, is known from what the call passes (the region's deps), not opaque.
    static bool writesFromArgs(const Function &G) {
      if (G.isDeclaration())
        return false;
      for (const Instruction &I : instructions(G)) {
        if (isa<LoadInst>(I) || isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<VAArgInst>(I))
          return false;
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (!isa<DbgInfoIntrinsic>(CB) && !isa<AssumeInst>(CB) && !CB->isLifetimeStartOrEnd())
            return false;
      }
      return true;
    }
    // the handlers a signal delivery may run: every defined function whose address is taken; their
    // argument is the signal number (an argument of the delivering call)
    bool handlersWriteFromArgs() const {
      for (const Function &G : *F.getParent())
        if (!G.isDeclaration() && !isDriverFn(G) && G.hasAddressTaken() && !writesFromArgs(G))
          return false;
      return true;
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
                R.mem = true, R.opaque |= !writesFromArgs(*G);
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
              R.mem = true, R.opaque |= !(deliversSignal(*CB) && handlersWriteFromArgs());
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
          if (carried(&P)) {
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
            // Owner, cq-47f8h (rules 2, 14): a loop-carried value with a rail incoming is a rail: its trips run under the loop's predicate chain,
            // seeded by the arm flag, so the conditions the loop's entry depends on decide it too. Only a value of measured rails and classical
            // values alone is classical; a quantum b1 in a loop's condition keeps it a rail, and each trip's cq_measure a measurement.
            if (Loop *HL = LI.getLoopFor(BB); HL && HL->getHeader() == BB)
              for (DomTreeNode *a = DT.getNode(BB) ? DT.getNode(BB)->getIDom() : nullptr; a; a = a->getIDom())
                if (BasicBlock *A = a->getBlock(); reachable.count(A) && !PDT.dominates(BB, A))
                  if (Value *c = quantumCond(A); c && !is_contained(conds, c))
                    conds.push_back(c);
            IRBuilder<> B(&*BB->getFirstInsertionPt());
            Value *X = nullptr;
            std::vector<const Value *> condVals(conds.begin(), conds.end());
            if (!conds.empty()) {
              std::vector<Value *> deps;
              // At a loop's header a value of the loop is last trip's, as computed so far; on the first trip nothing depends on it (no node).
              // `read` on a later trip needs it (owner, cq-2z29a: `while (v & 1)` re-reads what is computed from the measured rail alone).
              Loop *HL = LI.getLoopFor(BB);
              bool header = HL && HL->getHeader() == BB;
              auto dep = [&](Value *v) -> Value * {
                auto *J = dyn_cast<Instruction>(v);
                if (!header || !J || !carried(J) || DT.properlyDominates(J->getParent(), BB))
                  return availIn(v, BB);
                AllocaInst *&a = slots[J];
                if (!a)
                  a = In.entryAlloca(F, I32);
                return B.CreateCall(h("__cqo_sh_slot0", I32, {I32}), {B.CreateLoad(I32, a)});
              };
              for (Value *c : conds)
                deps.push_back(dep(c));
              for (PHINode *P : mine)
                for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
                  if (reachable.count(P->getIncomingBlock(i)))
                    deps.push_back(dep(P->getIncomingValue(i)));
              X = join(B, deps);
            }
            for (PHINode *P : mine) {
              PHINode *s = phiSh[P];
              if (Loop *HL = LI.getLoopFor(BB); HL && HL->getHeader() == BB)
                carriedIn[P] = s;
              Value *merge = X ? B.CreateCall(h3("__cqo_sh_v"), {s, X, zero()}) : nullptr;
              Value *chosen = s;   // carried only (extra): the incoming the sample ran
              if (q(P)) {
                std::vector<Value *> inc;
                for (unsigned i = 0; i < P->getNumIncomingValues(); ++i)
                  if (reachable.count(P->getIncomingBlock(i)))
                    inc.push_back(soFar(P->getIncomingValue(i), B, [&](Instruction *J) {
                      return DT.properlyDominates(J->getParent(), BB);
                    }));
                chosen = nonZero(B, s, inc);
              }
              Value *n = merge ? railPick(B, condVals, merge, chosen) : chosen;
              sh[P] = q(P) ? railPick(B, {P}, n, zero()) : n;
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
      skips(order);

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

    // Exit reads (CR rule 14 f981c89, cq-rmaf, cq-4asj). Taint (Analyzer::exitRead) makes a value V
    // defined in a loop whose exit is quantum quantum to every reader outside that loop (neither V
    // nor the reader a pointer), also where V itself is classical in the loop (an affine induction:
    // its exit value is the carried rail the circuit builds for the read). The quantum-exit loops are
    // the pass's own rule-14 classification (loops::classify, which the trip caps use too): any
    // specialization in which the loop is not ClassicalBound. Such a read of a V that carries no
    // shadow of its own reads a fresh node over SH_OPAQUE: the circuit selects the exit rail by the
    // exit test of every trip it computes, the trips the sample did not run included (whose values
    // the sample cannot know, as an arm not run at a merge under a quantum condition), so it is
    // classical only once measured itself. One node per V serves every read it dominates, so a
    // measured exit value is classical to later reads.
    DenseMap<const Loop *, bool> qexitMemo;
    bool quantumExit(const Loop *Lp) {
      auto [it, fresh] = qexitMemo.try_emplace(Lp, false);
      if (fresh)
        for (const cq::Specialization *S : specs)
          if (cq::loops::classify(*Lp, T, *S) != cq::loops::Case::ClassicalBound) {
            it->second = true;
            break;
          }
      return it->second;
    }
    DenseMap<const Value *, std::vector<std::pair<Instruction *, Value *>>> exitNodes;
    // the outermost quantum-exit loop U reads V's exit value of (nullptr: no exit read, or V is carried)
    const Loop *exitLoop(const Value *V, const Instruction *U) {
      auto *J = dyn_cast<Instruction>(V);
      if (!J || !orig.count(J) || carried(J) || J->getFunction() != &F || V->getType()->isPointerTy() ||
          U->getType()->isPointerTy())
        return nullptr;
      const Loop *outer = nullptr;
      for (const Loop *Lp = LI.getLoopFor(J->getParent()); Lp; Lp = Lp->getParentLoop())
        if (!Lp->contains(U) && quantumExit(Lp))
          outer = Lp;
      return outer;
    }
    Value *exitRead(Value *V, Instruction *U, IRBuilder<> &B) {
      const Loop *outer = exitLoop(V, U);
      if (!outer)
        return nullptr;
      auto &known = exitNodes[V];
      for (auto &[at, n] : known)
        if (DT.dominates(at, U))
          return n;
      Value *n = node(B, {opaque()});
      known.push_back({U, n});
      return n;
    }

    void visit(Instruction *I, bool retMerge, const std::vector<ReturnInst *> &rets,
               const std::vector<Value *> &qconds) {
      // an exit read's operand denotes the exit value (exitRead): its node while I is shadowed
      std::vector<std::pair<Value *, std::optional<Value *>>> saved;
      {
        IRBuilder<> B(I);
        for (Value *V : I->operands())
          if (none_of(saved, [&](auto &e) { return e.first == V; }))
            if (Value *n = exitRead(V, I, B)) {
              auto it = sh.find(V);
              saved.push_back({V, it == sh.end() ? std::nullopt : std::optional<Value *>(it->second)});
              sh[V] = n;
            }
      }
      visitOne(I, retMerge, rets, qconds);
      if (!I->isTerminator() && !I->getType()->isVoidTy() && q(I))
        if (auto it = sh.find(I); it != sh.end() && !isZero(it->second)) {
          // after its node when visitOne just made it, which then lies right after I
          auto *at = dyn_cast<Instruction>(it->second);
          bool fresh = at && at->getParent() == I->getParent() && I->comesBefore(at);
          IRBuilder<> B(fresh ? at->getNextNode() : I->getNextNode());
          Value *n = railPick(B, {I}, it->second, zero());
          sh[I] = n;
        }
      for (auto it = saved.rbegin(); it != saved.rend(); ++it) {
        if (it->second)
          sh[it->first] = *it->second;
        else
          sh.erase(it->first);
      }
    }

    void visitOne(Instruction *I, bool retMerge, const std::vector<ReturnInst *> &rets,
                  const std::vector<Value *> &qconds) {
      if (I->isTerminator()) {
        IRBuilder<> B(I);
        if (auto *R = dyn_cast<ReturnInst>(I)) {
          if (Value *v = R->getReturnValue()) {
            Value *s = get(v), *s0 = s;
            if (rets.size() > 1) {
              bool qret = false;
              for (ReturnInst *O : rets)
                qret |= q(O->getReturnValue());
              if (qret) {
                std::vector<Value *> inc;
                for (ReturnInst *O : rets)
                  inc.push_back(O == R ? s : soFar(O->getReturnValue(), B, [&](Instruction *J) {
                    return DT.dominates(J, R);
                  }));
                s0 = nonZero(B, s, inc);
              }
            }
            if (retMerge) {
              std::vector<Value *> deps{s};
              for (ReturnInst *O : rets)
                if (O != R)
                  deps.push_back(availAt(O->getReturnValue(), R));
              for (Value *c : qconds)
                deps.push_back(availAt(c, R));
              std::vector<const Value *> cs(qconds.begin(), qconds.end());
              s = railPick(B, cs, node(B, deps), s0);
            } else {
              s = s0;
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
            if (!isZero(d))
              d = railPick(B, {c}, d, zero());
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
        if (!carried(LI))
          return;
        // a rail taint holds (q) reads its cells as the rail itself (__cqo_sh_qload: a node
        // over no rail is a fresh one, never classical; cq-425g); a variadic actual read
        // through the save areas depends on what the call passed (sh_gm, as VAArgInst)
        bool va = !q(LI) && isVaRead(LI);
        Value *n;
        if (q(LI) && In.KI.on && llvm::any_of(specs, [&](const cq::Specialization *S) { return !T.isQuantum(LI, *S); })) {
          std::vector<int32_t> rail(In.KI.N + 1, 0);
          rail[0] = 1;
          for (const cq::Specialization *S : specs)
            if (auto id = In.KI.idOf.find(S); id != In.KI.idOf.end())
              rail[id->second] = T.isQuantum(LI, *S);
          auto *c = B.CreateCall(h("__cqo_sh_rload", I32, {In.Ptr, In.I64, I32, I32}),
                                 {LI->getPointerOperand(), B.getInt64(bytes(LI->getType())),
                                  get(LI->getPointerOperand()), B.getInt32(1)});
          In.railLoads.push_back({c, &F, std::move(rail)});
          n = c;
        } else {
          n = B.CreateCall(h(q(LI) ? "__cqo_sh_qload" : "__cqo_sh_load", I32, {In.Ptr, In.I64, I32}),
                           {LI->getPointerOperand(), B.getInt64(bytes(LI->getType())),
                            get(LI->getPointerOperand())});
        }
        sh[LI] = va ? node(B, {n, call0(B, "__cqo_sh_mq_get")}) : n;
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
        // the new cell and the result are distinct values (cq-vo6v, 94): measuring the cell's later
        // load must not make the result ({loaded, equal} of a cmpxchg) classical. An atomicrmw's
        // result is the old cell itself (the same rail, as a lossless cast).
        Value *cell = node(B, deps);
        B.CreateCall(h("__cqo_sh_store", In.Void, {In.Ptr, In.I64, I32, I32}), {p, B.getInt64(bytes(VT)), cell, get(p)});
        if (carried(I))
          sh[I] = isa<AtomicRMWInst>(I) ? old : node(B, deps);
        return;
      }
      if (auto *CB = dyn_cast<CallBase>(I)) {
        visitCall(CB, B);
        return;
      }
      if (isa<AllocaInst>(I))
        return;
      if (isa<VAArgInst>(I)) {
        if (carried(I))
          sh[I] = node(B, {call0(B, "__cqo_sh_gm_get"), call0(B, "__cqo_sh_mq_get")});
        return;
      }
      if (I->getType()->isVoidTy() || !carried(I))
        return;
      // cq-d1cd (CR rule 2, "cq_measure of a value that never was a rail is that value"): a vector is lowered lane by lane, so
      // a lane computed from classical lanes alone is no rail, though the vector is one value to taint.
      if (auto *EE = dyn_cast<ExtractElementInst>(I))
        if (auto *ci = dyn_cast<ConstantInt>(EE->getIndexOperand()); ci && ci->getValue().ult(64) && !specs.empty()) {
          // the frame's specialization answers (a lane may be classical in one and a rail in another)
          std::vector<int32_t> rail(In.KI.on ? In.KI.N + 1 : 1, 0);
          rail[0] = 1;
          bool any = false, all = true;
          for (const cq::Specialization *S : specs) {
            bool r = !laneClassical(EE->getVectorOperand(), ci->getZExtValue(), 0,
                                    [&](const Value *v) { return T.isQuantum(v, *S) || extra.count(v); });
            any |= r, all &= r;
            if (In.KI.on)
              if (auto id = In.KI.idOf.find(S); id != In.KI.idOf.end())
                rail[id->second] = r;
          }
          if (!all) {
            Value *n = node(B, {get(EE->getVectorOperand()), get(EE->getIndexOperand())});
            if (!any || !In.KI.on) {
              sh[I] = any ? n : zero();
            } else {
              auto *c = B.CreateCall(h("__cqo_sh_pick", I32, {I32, I32, I32}), {n, zero(), B.getInt32(1)});
              In.railLoads.push_back({c, &F, std::move(rail), 2});
              sh[I] = c;
            }
            return;
          }
        }
      if (auto *Sel = dyn_cast<SelectInst>(I))
        if (q(Sel) && !carried(Sel->getCondition()) && !Sel->getCondition()->getType()->isVectorTy()) {
          // a classical choice between rails: the chosen rail itself (a classical merge, as a phi's)
          Value *t = get(Sel->getTrueValue()), *f = get(Sel->getFalseValue());
          sh[I] = nonZero(B, B.CreateSelect(Sel->getCondition(), t, f), {t, f});
          return;
        }
      // a cast that loses nothing (its operand is a function of its value) denotes the same rail:
      // the same node, so measuring either measures both (cq-425g: 59's trunc of a loaded bool)
      if (isa<FreezeInst>(I) || (isa<CastInst>(I) && lossless(cast<CastInst>(I)))) {
        sh[I] = get(I->getOperand(0));
        return;
      }
      std::vector<Value *> deps;
      for (Value *op : I->operands())
        deps.push_back(get(op));
      sh[I] = node(B, deps);
    }

    // Lane i of vector value V is computed from classical values alone: a constant lane, a classical scalar inserted there, or a
    // lane-wise operation (arithmetic, compare, cast, a lane-wise intrinsic such as a constrained fp op, a select on a classical
    // scalar condition) over classical lanes i of its operands, through insertelement and shufflevector.
    bool laneClassical(const Value *V, uint64_t i, unsigned depth, function_ref<bool(const Value *)> carried) {
      if (depth > 32)
        return false;
      if (isa<Constant>(V) || !(isa<Instruction>(V) || isa<Argument>(V)))
        return true;
      if (auto *J = dyn_cast<Instruction>(V); J && !orig.count(J))
        return false;
      if (!carried(V))
        return true;
      auto *VT = dyn_cast<FixedVectorType>(V->getType());
      if (!VT || i >= VT->getNumElements())
        return false;
      if (auto *IE = dyn_cast<InsertElementInst>(V)) {
        auto *ci = dyn_cast<ConstantInt>(IE->getOperand(2));
        if (!ci)
          return false;
        if (ci->getZExtValue() == i)
          return isa<Constant>(IE->getOperand(1)) || !carried(IE->getOperand(1));
        return laneClassical(IE->getOperand(0), i, depth + 1, carried);
      }
      if (auto *SV = dyn_cast<ShuffleVectorInst>(V)) {
        int m = SV->getMaskValue(i);
        if (m < 0)
          return true;
        unsigned n = cast<FixedVectorType>(SV->getOperand(0)->getType())->getNumElements();
        return (unsigned)m < n ? laneClassical(SV->getOperand(0), m, depth + 1, carried)
                               : laneClassical(SV->getOperand(1), m - n, depth + 1, carried);
      }
      auto lanes = [&](const User *U, unsigned nops) {
        for (unsigned k = 0; k < nops; ++k) {
          const Value *o = U->getOperand(k);
          if (o->getType()->isMetadataTy())
            continue;
          if (o->getType()->isVectorTy() ? !laneClassical(o, i, depth + 1, carried) : carried(o))
            return false;
        }
        return true;
      };
      if (isa<BinaryOperator>(V) || isa<UnaryOperator>(V) || isa<CmpInst>(V) || isa<SelectInst>(V))
        return lanes(cast<User>(V), cast<User>(V)->getNumOperands());
      if (auto *C = dyn_cast<CastInst>(V);
          C && C->getSrcTy()->isVectorTy() &&
          cast<FixedVectorType>(C->getSrcTy())->getNumElements() == VT->getNumElements())
        return lanes(C, 1);
      if (auto *II = dyn_cast<IntrinsicInst>(V); II && (isa<ConstrainedFPIntrinsic>(II) ||
                                                        isTriviallyVectorizable(II->getIntrinsicID())))
        if (all_of(II->args(), [&](const Use &a) {
              return !a->getType()->isVectorTy() ||
                     cast<FixedVectorType>(a->getType())->getNumElements() == VT->getNumElements();
            }))
          return lanes(II, II->arg_size());
      return false;
    }

    bool lossless(CastInst *C) {
      Type *S = C->getSrcTy(), *D = C->getDestTy();
      switch (C->getOpcode()) {
      case Instruction::ZExt:
      case Instruction::SExt:
      case Instruction::BitCast:
      case Instruction::AddrSpaceCast:
        return true;
      case Instruction::PtrToInt:
      case Instruction::IntToPtr:
        return In.DL.getTypeSizeInBits(S) == In.DL.getTypeSizeInBits(D);
      case Instruction::Trunc: {
        if (S->isVectorTy())
          return false;
        unsigned lost = S->getScalarSizeInBits() - D->getScalarSizeInBits();
        Value *X = C->getOperand(0);
        return computeKnownBits(X, In.DL).countMinLeadingZeros() >= lost ||
               ComputeNumSignBits(X, In.DL) > lost;
      }
      default:
        return false;
      }
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
          auto *m = Bb.CreateCall(h("__cqo_sh_measure", I32, {I32, I32}), {args[0], collapses(Bb, CB)});
          // A loop-carried value's rail this trip is the incoming it took: that one is measured too (owner, cq-2z29a: the later trips re-read
          // what is computed from it alone), but only under the same static test as any collapse (CR 406-408): an incoming another
          // value reads unmeasured (measure_carried: x0, read by x's header phi and the exit test) stays a rail; the loop-carried
          // value with a rail incoming is a rail in every trip (owner 2026-11-07, cq-2z29a).
          if (auto ci = carriedIn.find(CB->getArgOperand(0)); ci != carriedIn.end()) {
            std::vector<const Value *> ins;
            if (auto *P = dyn_cast<PHINode>(CB->getArgOperand(0)))
              for (const Value *v : P->incoming_values())
                ins.push_back(v);
            Bb.CreateCall(h("__cqo_sh_mark", In.Void, {I32, I32}), {ci->second, collapses(Bb, CB, ins)});
          }
          sh[CB] = m;  // dominated uses denote the outcome: classical (the measured node, or its basis copy's)
        }
        return;
      }
      if (CB->isInlineAsm()) {
        IRBuilder<> Ba(CB);
        Value *d = join(Ba, args);
        Ba.CreateCall(h("__cqo_sh_gf", In.Void, {I32}), {d});
        Ba.CreateCall(h("__cqo_sh_gm", In.Void, {I32}), {join(Ba, {d, call0(Ba, "__cqo_sh_mq_get")})});
        if (hasResult && carried(CB))
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
          if (hasResult && carried(CB))
            sh[CB] = node(B, {d, env});
          return;
        }
        if (hasResult && carried(CB))
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
          if (carried(CB))
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
        if (hasResult && carried(CB))
          sh[CB] = r;
        return;
      }
      // a library function (declared): allocation and memory moves are the runtime's; anything else
      // reads its arguments (and the fp environment), and through a pointer may read or write memory
      StringRef n = G->getName();
      if (isAllocator(n)) {
        if (hasResult && carried(CB))
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
        if (hasResult && carried(CB))
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
      if (hasResult && carried(CB)) {
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
    // functions returning a value carried only through Shadow::extra, to a fixpoint (cq-425g)
    DenseSet<const Function *> rc;
    for (bool changed = true; changed;) {
      changed = false;
      for (Function &F : M)
        if (!F.isDeclaration() && !isDriverFn(F) && !rc.count(&F) && Shadow(*this, F, *Taint, rc).returnsExtra())
          rc.insert(&F), changed = true;
    }
    for (Function &F : M)
      if (!F.isDeclaration() && !isDriverFn(F))
        Shadow(*this, F, *Taint, rc).run();
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
        CallInst *lc = LB.CreateCall(hook("__cqo_load", Void, {Ptr, I64, Ptr, Ptr}),
                                     {LI->getPointerOperand(), LB.getInt64(bytes(T)), t, base(LI->getPointerOperand())});
        LoadInst *nl = LB.CreateLoad(T, t);
        // A shadow's slot access is no access of the program: the trips' test region (below) must not see it.
        if (MDNode *sh = LI->getMetadata("cqo.sh")) {
          lc->setMetadata("cqo.sh", sh);
          nl->setMetadata("cqo.sh", sh);
        }
        LI->replaceAllUsesWith(nl);
        nl->takeName(LI);
        LI->eraseFromParent();
      } else if (auto *SI = dyn_cast<StoreInst>(I)) {
        Type *T = SI->getValueOperand()->getType();
        if (T->isScalableTy())
          unimplemented("scalable store", SI);
        IRBuilder<> SB(SI);
        AllocaInst *t = tmpFor(T);
        StoreInst *ts = SB.CreateStore(SI->getValueOperand(), t);
        CallInst *sc = SB.CreateCall(hook("__cqo_store", Void, {Ptr, I64, Ptr, Ptr}),
                                     {SI->getPointerOperand(), SB.getInt64(bytes(T)), t, base(SI->getPointerOperand())});
        if (MDNode *sh = SI->getMetadata("cqo.sh")) {
          ts->setMetadata("cqo.sh", sh);
          sc->setMetadata("cqo.sh", sh);
        }
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
      else if (unsigned period = cq::calls::patternPeriod(*MI))
        B.CreateCall(hook("__cqo_imempattern", Void, {Ptr, Ptr, I64, I64, Ptr, Ptr}),
                     {MI->getDest(), cast<MemTransferInst>(MI)->getSource(), n, B.getInt64(period), base(MI->getDest()),
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
      case Intrinsic::stacksave: {
        // cq-t3kb: a restore ends the allocas made since its save (__cqo_stackrestore)
        IRBuilder<> B(II->getNextNode());
        B.CreateCall(hook("__cqo_stacksave", Void, {Ptr}), {II});
        return;
      }
      case Intrinsic::stackrestore: {
        IRBuilder<> B(II);
        B.CreateCall(hook("__cqo_stackrestore", Void, {Ptr}), {II->getArgOperand(0)});
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
      std::string repl = std::string("__cqo_") + n;
      // Darwin's asm-label spelling is the same function (<pthread.h>: @"\01_pthread_join"; cq-cj4r)
      for (std::string spelled : {std::string(n), std::string("\x01_") + n}) {
        Function *F = M.getFunction(spelled);
        if (!F || !F->isDeclaration())
          continue;  // a body in the module (injected source) is instrumented like any code
        FunctionCallee R = M.getOrInsertFunction(repl, F->getFunctionType());
        F->replaceAllUsesWith(R.getCallee());
      }
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

  // CR rules 2, 19: which functions this input enters, for a measurement of the lowered program's that the C program does
  // not reach (compare._meas_extra): an arm's measurement hoisted in its own function is legal, one in a function the input
  // never enters is not. Only the functions with a cq_measure or a direct call chain to one, where a rule-2 re-read can land.
  void enters(ArrayRef<Function *> defined) {
    DenseSet<const Function *> reach;
    for (bool changed = true; changed;) {
      changed = false;
      for (Function *F : defined) {
        if (reach.count(F) || isDriverFn(*F))
          continue;
        for (Instruction &I : instructions(*F)) {
          auto *CB = dyn_cast<CallBase>(&I);
          const Function *G = CB ? CB->getCalledFunction() : nullptr;
          if (G && (G->getName().starts_with("cq_measure_") || reach.count(G))) {
            reach.insert(F);
            changed = true;
            break;
          }
        }
      }
    }
    FunctionCallee enter = hook("__cqo_enter", Void, {Ptr});
    for (Function *F : defined)
      if (reach.count(F)) {
        BasicBlock &E = F->getEntryBlock();
        IRBuilder<> B(&E, E.getFirstInsertionPt());
        B.CreateCall(enter, {str(F->getName())});
      }
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
  // CR rule 13 (b137e75): a computed goto is a switch whose scrutinee is its address, the case of each distinct
  // destination its blockaddress, the last destination the complement (an address outside the list is
  // undefined). Rewritten as that switch (the same successors, so loops and dominance are unchanged) where an
  // edge out of it must be split.
  void gotoAsSwitch(IndirectBrInst *IB) {
    BasicBlock *From = IB->getParent();
    Function *F = From->getParent();
    SmallVector<BasicBlock *, 4> ds;
    DenseMap<BasicBlock *, unsigned> count;
    for (BasicBlock *s : successors(IB))
      if (count[s]++ == 0)
        ds.push_back(s);
    IRBuilder<> B(IB);
    Value *x = B.CreatePtrToInt(IB->getAddress(), I64);
    Value *pos = B.getInt32(ds.size() - 1);
    for (unsigned k = ds.size() - 1; k-- > 0;)
      pos = B.CreateSelect(
          B.CreateICmpEQ(x, ConstantExpr::getPtrToInt(BlockAddress::get(F, ds[k]), I64)), B.getInt32(k), pos);
    SwitchInst *SW = B.CreateSwitch(pos, ds.back(), ds.size() - 1);
    for (unsigned k = 0; k + 1 < ds.size(); ++k)
      SW->addCase(B.getInt32(k), ds[k]);
    for (BasicBlock *d : ds)   // one edge per destination now: one phi entry each
      for (PHINode &P : d->phis())
        for (unsigned extra = count[d] - 1; extra-- > 0;)
          P.removeIncomingValue(From, false);
    IB->eraseFromParent();
  }

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
      // (54: the two tests x > k and x * c > m are one test split over two blocks). Only a live exit counts, as for
      // the circuit (pass/lib/loops/cutoff: testRegion, exits::unitOf): an exit into a noreturn arm or an effect-free
      // dead end ends no test (cq-2dxe). A live exit outside the region is a second exit test per trip: the circuit
      // ends at the K-th latch test and makes no header test of a (K+1)-th trip (ruling Q15, 189), so a header run
      // begins a trip whatever it does.
      SmallPtrSet<BasicBlock *, 4> region;
      bool regionExits = false;
      {
        auto liveExit = [&](BasicBlock *X) {
          SmallVector<BasicBlock *, 8> work{X};
          SmallPtrSet<BasicBlock *, 8> seen{X};
          while (!work.empty()) {
            BasicBlock *B = work.pop_back_val();
            if (L->contains(B) || isa<ReturnInst>(B->getTerminator()))
              return true;
            for (BasicBlock *S : successors(B))
              if (seen.insert(S).second)
                work.push_back(S);
          }
          return false;
        };
        auto exiting = [&](BasicBlock *B) {
          return any_of(successors(B), [&](BasicBlock *S) { return !L->contains(S) && liveExit(S); });
        };
        SmallVector<BasicBlock *, 4> work{H};
        region.insert(H);
        while (!work.empty()) {
          BasicBlock *B = work.pop_back_val();
          if (exiting(B))
            regionExits = true;
          for (BasicBlock *S : successors(B)) {
            if (!L->contains(S) || S == H || region.count(S) || S->getSinglePredecessor() != B ||
                L->isLoopLatch(S) || !exiting(S))
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
        for (BasicBlock *B : L->blocks())
          if (!region.count(B) && exiting(B))
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
        if (auto *IB = dyn_cast<IndirectBrInst>(from->getTerminator()))
          gotoAsSwitch(IB);   // CR rule 13: a computed goto is a switch on its address (same edges)
        if (isa<CallBrInst>(from->getTerminator()))
          unimplemented("loop exit from callbr: inline asm (rule 27) waits for its CQ_spec example", from->getTerminator());
        // A trip is begun at each header execution, except a final header run that only exits:
        // an exit from the header's test region (above).
        add(from, to, Rep{cid, cnt, regionExits && region.count(from), kq});
      }
      // Guard skip: an entering edge whose branch's other successor is an exit block, or the block an exit block goes on to
      // unconditionally (a store of a carried value sinks there: the guard's skip joins after it, cq-2in7d), reports 0: the
      // circuit runs the guarded loop's activation under the arm flag (rule 14), so it has its record and a_K whatever the guard.
      SmallVector<BasicBlock *, 4> exitBlocks;
      L->getExitBlocks(exitBlocks);
      for (size_t x = 0; x < exitBlocks.size(); ++x)
        if (BasicBlock *next = exitBlocks[x]->getSingleSuccessor();
            next && !L->contains(next) && !is_contained(exitBlocks, next))
          exitBlocks.push_back(next);
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

  // CR rule 24: a longjmp outside the one pairing under a quantum predicate is rule 16's noreturn arm: the sample
  // ends there, on the pristine module (the pairing and the predicate as clang wrote them). The predicate is the running
  // specialization's: the same longjmp on a classical path of the frame runs natively (rule 24; a table clone's
  // every formal is a rail, cq-li3wr); id 0 (a frame no call named: host code's) takes any of them.
  // Asked of taint on the pristine module, instrumented once shadows() is past (it asks taint of every instruction it meets).
  MapVector<CallBase *, std::vector<int32_t>> ArmJumps;
  void armLongjmps() {
    if (!Taint)
      return;
    for (const cq::Specialization &S : Taint->specializations()) {
      if (!S.F || S.F->isDeclaration())
        continue;
      for (Instruction &I : instructions(*S.F))
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (cq::conc::isLongjmpCall(*CB)) {
            auto *buf = dyn_cast<GlobalVariable>(CB->getArgOperand(0));
            if (!(buf && cq::conc::isPairedJmpBuf(*buf)) && Taint->controlTainted(CB->getParent(), S)) {
              auto &v = ArmJumps[CB];
              v.resize(KI.N + 1, 0);
              v[0] = 1;
              if (auto id = KI.idOf.find(&S); id != KI.idOf.end())
                v[id->second] = 1;
            }
          }
    }
  }

  void instrumentRule24() {
    for (auto &[CB, vals] : ArmJumps) {
      IRBuilder<> B(CB);
      CallInst *arm = B.CreateCall(hook("__cqo_longjmp_arm", Void, {I32}), {B.getInt32(1)});
      railLoads.push_back({arm, CB->getFunction(), vals, 0});
    }
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
        continue;  // a longjmp with no quantum predicate runs natively (rule 24); a defined callee reaches its own noreturn call
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
    // The pass's own first step (rules 16, 22, 24), so taint answers for the program the pass lowers.
    if (callsCqSurface(M))
      cq::calls::canonicalizeLibCalls(M);
    analyseCutoffs();  // on the pristine module: taint answers for the program as clang wrote it
    armLongjmps();
    {
      // block labels as the input spells them, before shadows() adds numbered values
      std::vector<Function *> pristine;
      for (Function &F : M)
        if (!F.isDeclaration())
          pristine.push_back(&F);
      spellBlocks(pristine);
    }
    measureSites();
    shadows();         // rule 2 collapse, on the pristine module too (before stubs give bodies)
    instrumentRule24();
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
    enters(defined);
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
    for (RailLoad &R : railLoads) {
      IRBuilder<> B(R.call);
      R.call->setArgOperand(R.arg, perSpec(B, *R.F, R.vals));
    }
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

// cq-8bq66 (CR rule 16): "a body the bundle has for one of [the stream calls] is never lifted for the call", which is the
// host boundary. -passes=cq-oracle-host-streams makes every such function a declaration, recognised by name and signature
// exactly as cq-lower recognises it (cq::streamCallee), so the C program calls the host's function, as the backend
// performs the entry (BACKEND_ABI §1.11: "with the host C library ..., never with a lowered symbol"). oracle.py
// host_streams runs it before the direct host calls are sent to their stand-ins (drivers.effect_callees).
//
// cq-xkmrm: the declaration is the host C library's function as a C header declares it, so nothing of the module's own
// definition stays on it: external linkage, default visibility and DLL storage, not dso_local (the host library is
// another image: a dso_local RIP-relative reference to it cannot be bound, the probe link of 8 printf-family rows), no
// comdat, section, alignment, unnamed_addr or GC; the C calling convention (a host libc function's, also at every call
// site). Of its attributes only what the C prototype gives the ABI stays (signext, zeroext, inreg, byval, sret, byref,
// inalloca, preallocated, their alignment, noundef) and nounwind (C has no exceptions); every fact LLVM inferred from the
// module's body (memory(...), willreturn, nofree, nosync, nocapture, readonly, nonnull, returned, ...) is dropped, at the
// call sites too, since it describes a body that is no longer what the call runs.
static AttributeSet hostABIAttrs(LLVMContext &C, AttributeSet S) {
  bool byPtr = S.hasAttribute(Attribute::ByVal) || S.hasAttribute(Attribute::ByRef) ||
               S.hasAttribute(Attribute::StructRet) || S.hasAttribute(Attribute::InAlloca) ||
               S.hasAttribute(Attribute::Preallocated);
  AttrBuilder B(C);
  for (Attribute A : S) {
    if (A.isStringAttribute())
      continue;
    switch (A.getKindAsEnum()) {
    case Attribute::SExt:
    case Attribute::ZExt:
    case Attribute::InReg:
    case Attribute::ByVal:
    case Attribute::ByRef:
    case Attribute::StructRet:
    case Attribute::InAlloca:
    case Attribute::Preallocated:
    case Attribute::NoUndef:
      B.addAttribute(A);
      break;
    case Attribute::Alignment:
      if (byPtr)
        B.addAttribute(A);
      break;
    default:
      break;
    }
  }
  return AttributeSet::get(C, B);
}

static AttributeList hostABIList(LLVMContext &C, AttributeList L, unsigned nargs, AttributeSet fn) {
  SmallVector<AttributeSet, 8> params;
  for (unsigned i = 0; i < nargs; ++i)
    params.push_back(hostABIAttrs(C, L.getParamAttrs(i)));
  return AttributeList::get(C, fn, hostABIAttrs(C, L.getRetAttrs()), params);
}

// cq-tgl3i: then what only the dropped bodies reached goes (musl's __stdin_FILE, its buffer and locks: the host library's
// objects, CR rule 16, no named output of the program's), as it goes from the lowered module, where the checker's llvm-link
// (run.py's canon) keeps only what the external definitions reach, and what rule 19's clone table reaches: every function
// whose address the module takes is registered there, so it is kept with what it reaches. Its roots here are the same: the
// non-local definitions, the llvm.used lists and the functions whose address the module took before the bodies went.
static void globalsIn(const Value *V, SmallVectorImpl<GlobalValue *> &out, SmallPtrSetImpl<const Constant *> &seen) {
  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    out.push_back(const_cast<GlobalValue *>(GV));
    return;
  }
  auto *C = dyn_cast<Constant>(V);
  if (!C || !seen.insert(C).second)
    return;
  for (const Value *Op : C->operands())
    globalsIn(Op, out, seen);
}

static void dropUnreached(Module &M, const SmallPtrSetImpl<Function *> &taken) {
  SmallPtrSet<GlobalValue *, 32> live;
  SmallVector<GlobalValue *, 64> work;
  auto root = [&](GlobalValue *G) {
    if (live.insert(G).second)
      work.push_back(G);
  };
  for (GlobalValue &G : M.global_values())
    if (!G.hasLocalLinkage() && !G.isDeclaration())
      root(&G);
  for (Function *F : taken)
    root(F);
  for (const char *n : {"llvm.used", "llvm.compiler.used", "llvm.global_ctors", "llvm.global_dtors"})
    if (GlobalVariable *U = M.getNamedGlobal(n))
      root(U);
  SmallPtrSet<const Constant *, 32> seen;
  while (!work.empty()) {
    GlobalValue *G = work.pop_back_val();
    SmallVector<GlobalValue *, 16> refs;
    if (auto *GVar = dyn_cast<GlobalVariable>(G)) {
      if (GVar->hasInitializer())
        globalsIn(GVar->getInitializer(), refs, seen);
    } else if (auto *GA = dyn_cast<GlobalAlias>(G)) {
      globalsIn(GA->getAliasee(), refs, seen);
    } else if (auto *F = dyn_cast<Function>(G)) {
      for (Instruction &I : instructions(*F))
        for (const Value *Op : I.operands())
          globalsIn(Op, refs, seen);
    }
    for (GlobalValue *R : refs)
      root(R);
  }
  SmallVector<GlobalValue *, 32> dead;
  for (GlobalValue &G : M.global_values())
    if (G.hasLocalLinkage() && !live.count(&G))
      dead.push_back(&G);
  for (GlobalValue *G : dead)
    G->dropAllReferences();
  for (GlobalValue *G : dead) {
    G->replaceAllUsesWith(PoisonValue::get(G->getType()));
    G->eraseFromParent();
  }
}

struct HostStreamsPass : PassInfoMixin<HostStreamsPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool changed = false;
    SmallPtrSet<Function *, 32> taken;
    for (Function &F : M)
      if (!F.isDeclaration() && !cq::streamCallee(F) && F.hasAddressTaken())
        taken.insert(&F);
    for (Function &F : M)
      if (!F.isDeclaration() && cq::streamCallee(F)) {
        LLVMContext &C = M.getContext();
        F.deleteBody();
        F.setLinkage(GlobalValue::ExternalLinkage);
        F.setVisibility(GlobalValue::DefaultVisibility);
        F.setDLLStorageClass(GlobalValue::DefaultStorageClass);
        F.setDSOLocal(false);
        F.setComdat(nullptr);
        F.setSection("");
        F.setAlignment(MaybeAlign());
        F.setUnnamedAddr(GlobalValue::UnnamedAddr::None);
        F.clearGC();
        F.setCallingConv(CallingConv::C);
        AttrBuilder fnB(C);
        fnB.addAttribute(Attribute::NoUnwind);
        F.setAttributes(hostABIList(C, F.getAttributes(), F.arg_size(), AttributeSet::get(C, fnB)));
        for (User *U : F.users())
          if (auto *CB = dyn_cast<CallBase>(U))
            if (CB->getCalledOperand() == &F) {
              CB->setCallingConv(CallingConv::C);
              AttributeList L = CB->getAttributes();
              AttributeMask drop;
              for (Attribute::AttrKind k : {Attribute::Memory, Attribute::WillReturn, Attribute::NoFree, Attribute::NoSync,
                                            Attribute::ReadNone, Attribute::ReadOnly, Attribute::WriteOnly,
                                            Attribute::Speculatable, Attribute::NoRecurse, Attribute::MustProgress,
                                            Attribute::NoCallback})
                drop.addAttribute(k);
              AttributeSet fn = L.getFnAttrs().removeAttributes(C, drop);
              CB->setAttributes(hostABIList(C, L, CB->arg_size(), fn));
            }
        changed = true;
      }
    if (changed)
      dropUnreached(M, taken);
    return changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

}  // namespace

void cqRegisterTripFacts(PassBuilder &PB);   // TripFacts.cpp: -passes=cq-trip-facts (cq-97oj)

extern "C" LLVM_ATTRIBUTE_WEAK PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "CQOracle", "0.1", [](PassBuilder &PB) {
            cqRegisterTripFacts(PB);
            PB.registerPipelineParsingCallback(
                [](StringRef name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
                  if (name == "cq-oracle-host-streams") {
                    MPM.addPass(HostStreamsPass());
                    return true;
                  }
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
