// ClassicalRailMux.cpp — bd dm7f.15 / dm7f.16. See ClassicalRailMux.h for the
// lowering, the soundness argument and the fence.

#include "ClassicalRailMux.h"

#include "ClassicalRailMuxFence.h"      // the fence (pure analysis)
#include "CloneRailSelect.h"            // rewriteRailSelects (L4's; called, not copied)
#include "OpcodeSupport.h"              // abiWidthFromType
#include "SelectMergeEmit.h"            // materializeCopySource (the one materializer)
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueHandle.h"

#include <functional>
#include <vector>

using namespace llvm;

namespace cq {

namespace {

// The backstop for a recorded router the rewrite could not lower. Argued
// unreachable (the record proves a muxable type with an allocator, `lowerOps`
// leaves every surviving quantum arm an i32 handle or has already declined, and
// nothing between the record and the rewrite erases a select/phi), so no fixture
// reaches it; the string names it if one ever does. Never a silent skip (R1).
constexpr char kMsgRailMuxUnlowered[] =
    "cq taint escape: internal invariant: classical-condition mux over a quantum "
    "value has no rail handle";

struct RailMuxRecord {
  WeakVH Mux;   // the select/phi; nulled if erased (a WeakVH: identity, not RAUW)
  WeakVH Fn;    // its function, for a diagnostic after the mux is gone
  DebugLoc DL;
};

// The module's record, written by `recordClassicalRailMux` and read once by
// `rewriteClassicalRailMuxes` (the `copySourceLedger` precedent, SelectMergeEmit:
// no new `TaintSet` member). `beginClassicalRailMuxRecord` clears it per module.
std::vector<RailMuxRecord> &railMuxLedger() {
  static std::vector<RailMuxRecord> Ledger;
  return Ledger;
}

// The routers the rewrite BUILT (the i32 select/phi), asked by
// `isClassicalRailMuxRouter`. `WeakVH`: a deleted router nulls, so a reused
// address can never alias a member.
std::vector<WeakVH> &builtRouters() {
  static std::vector<WeakVH> Built;
  return Built;
}

void diagnoseUnlowered(const RailMuxRecord &Rec, Module &M) {
  auto *F = cast_or_null<Function>(static_cast<Value *>(Rec.Fn));
  if (!F)
    for (Function &G : M)
      if (!G.isDeclaration()) {
        F = &G;
        break;
      }
  if (!F)
    return;
  F->getContext().diagnose(
      DiagnosticInfoUnsupported(*F, kMsgRailMuxUnlowered, Rec.DL));
}

}  // namespace

void beginClassicalRailMuxRecord() {
  railMuxLedger().clear();
  builtRouters().clear();
}

bool isClassicalRailMuxRouter(const Value *V) {
  if (!V)
    return false;
  for (const WeakVH &H : builtRouters())
    if (static_cast<const Value *>(H) == V)
      return true;
  return false;
}

bool isClassicalRailMuxValue(const Value *V) {
  if (!V)
    return false;
  for (const RailMuxRecord &R : railMuxLedger())
    if (static_cast<const Value *>(R.Mux) == V)
      return true;
  return isClassicalRailMuxRouter(V);
}

bool recordClassicalRailMux(Instruction *Mux, const TaintSet &taint) {
  if (!classicalRailMuxFenceHolds(Mux, taint))
    return false;
  railMuxLedger().push_back(
      {WeakVH(Mux), WeakVH(Mux->getFunction()), Mux->getDebugLoc()});
  return true;
}

bool rewriteClassicalRailMuxes(Module &M, TaintSet &taint, WidthDispatch &wd) {
  std::vector<RailMuxRecord> Recs;
  Recs.swap(railMuxLedger());  // read once; the next module starts empty.
  if (Recs.empty())
    return false;

  Type *I32 = Type::getInt32Ty(M.getContext());
  // A routed value is QUANTUM iff it is tainted at THIS taint (the L1 re-ask: a
  // scrubbed arm is classical now) — and then it must be an i32 handle.
  auto quantum = [&](Value *V) { return taint.Tainted.count(V) != 0; };

  DenseMap<Instruction *, size_t> Index;
  for (size_t K = 0; K < Recs.size(); ++K)
    if (auto *I = dyn_cast_or_null<Instruction>(static_cast<Value *>(Recs[K].Mux)))
      Index[I] = K;
  enum class Disp { Pending, InProgress, Rewritten, Classical, Failed };
  std::vector<Disp> State(Recs.size(), Disp::Pending);

  // Rewrite record K, after every recorded router among its operands (an inner
  // router must be an i32 handle before the outer one reads it).
  std::function<void(size_t)> rewrite = [&](size_t K) {
    if (State[K] != Disp::Pending)
      return;
    auto *R = dyn_cast_or_null<Instruction>(static_cast<Value *>(Recs[K].Mux));
    if (!R) {
      State[K] = Disp::Failed;  // erased since the record: nothing proves why.
      return;
    }
    State[K] = Disp::InProgress;
    for (Value *V : classicalRailMuxValues(R))
      if (auto *Inner = dyn_cast<Instruction>(V))
        if (auto It = Index.find(Inner); It != Index.end())
          rewrite(It->second);
    // Re-read the operands: an inner rewrite RAUW'd them.
    bool AnyQ = false, BadQ = false;
    for (Value *V : classicalRailMuxValues(R))
      if (quantum(V)) {
        AnyQ = true;
        if (V->getType() != I32)
          BadQ = true;
      }
    if (!AnyQ) {
      State[K] = Disp::Classical;  // a classical select/phi now: the backend's.
      return;
    }
    const StringRef Abi = abiWidthFromType(R->getType());
    FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
    if (BadQ || !Alloc) {
      State[K] = Disp::Failed;
      return;
    }
    if (auto *S = dyn_cast<SelectInst>(R)) {
      // A classical undef/poison arm is dead on every execution that selects
      // it; refine it to zero so the materialized literal is a defined value.
      for (unsigned OpI : {1u, 2u})
        if (!quantum(S->getOperand(OpI)) && isa<UndefValue>(S->getOperand(OpI)))
          S->setOperand(OpI, Constant::getNullValue(S->getType()));
      RailSelectRecord RS{WeakVH(S), quantum(S->getTrueValue()),
                          quantum(S->getFalseValue())};
      // Read the BUILT router back after the call: `rewriteRailSelects` inserts
      // it immediately before `S` (its builder's insertion point) and then RAUWs
      // and erases `S`, so it is the instruction just before `S`'s successor; a
      // live `S`'s first reader must then read exactly that value.
      Instruction *After = S->getNextNode();
      User *Reader = S->use_empty() ? nullptr : S->use_begin()->getUser();
      const unsigned ReaderOp =
          S->use_empty() ? 0 : S->use_begin()->getOperandNo();
      // Pre-validated above, so `rewriteRailSelects`' own (clone-worded)
      // decline cannot fire here.
      if (!After ||
          !rewriteRailSelects(ArrayRef<RailSelectRecord>(RS), taint, wd)) {
        State[K] = Disp::Failed;
        return;
      }
      // Postcondition: the original select is gone, an i32 tainted select stands
      // in its place, and its reader reads it.
      Value *Built = After->getPrevNode();
      if (static_cast<Value *>(Recs[K].Mux) || !Built ||
          !isa<SelectInst>(Built) || Built->getType() != I32 ||
          !taint.Tainted.count(Built) ||
          (Reader && Reader->getOperand(ReaderOp) != Built)) {
        State[K] = Disp::Failed;
        return;
      }
      builtRouters().emplace_back(Built);
      State[K] = Disp::Rewritten;
      return;
    }
    // A phi KEEPS its classical branch: a phi of i32 rail handles, a classical
    // incoming materialized at the end of its own incoming block (where it is
    // available: it dominates that edge). One rail per incoming BLOCK, since a
    // phi lists a block once per edge with one value.
    auto *P = cast<PHINode>(R);
    const unsigned N = P->getNumIncomingValues();
    PHINode *H = PHINode::Create(I32, N, "cqq.rphi", P->getIterator());
    H->setDebugLoc(P->getDebugLoc());
    DenseMap<BasicBlock *, Value *> PerBlock;
    for (unsigned In = 0; In < N; ++In) {
      BasicBlock *B = P->getIncomingBlock(In);
      Value *V = P->getIncomingValue(In);
      Value *&Rail = PerBlock[B];
      if (!Rail) {
        if (quantum(V)) {
          Rail = V;
        } else {
          if (isa<UndefValue>(V))
            V = Constant::getNullValue(P->getType());
          IRBuilder<> Bld(B->getTerminator());
          Rail = materializeCopySource(V, Alloc, taint, Bld, P->getDebugLoc(),
                                       "cqq.rphi.arm");
        }
      }
      H->addIncoming(Rail, B);
    }
    taint.Tainted.insert(H);
    taint.BirthOrder[H] = taint.NextBirth++;
    taint.HandleWidth[H] = Abi;
    P->replaceAllUsesWith(H);  // cross-type: the source-typed phi → i32 handle.
    taint.Tainted.erase(P);
    taint.BirthOrder.erase(P);
    taint.StaleDeclined.erase(P);
    taint.HandleWidth.erase(P);
    P->eraseFromParent();
    builtRouters().emplace_back(H);
    State[K] = Disp::Rewritten;
  };
  for (size_t K = 0; K < Recs.size(); ++K)
    rewrite(K);

  // THE GATE SET (L3): recorded − (rewritten ∪ classical) must be empty.
  for (size_t K = 0; K < Recs.size(); ++K)
    if (State[K] != Disp::Rewritten && State[K] != Disp::Classical) {
      diagnoseUnlowered(Recs[K], M);
      return true;
    }
  return false;
}

}  // namespace cq
