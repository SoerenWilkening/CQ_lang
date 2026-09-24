// CondLiteral.cpp — see header (bd `test_C_libtooling-xdu2.13`).
//
// Correctness rests on analytic basis-state reasoning, not on `opt -verify`
// (Rule 2). The forward `gl = cq_template_<op>_i1_hl(f, c)` is the ABI's
// out-of-place shape `gl(fresh |0>) ^= f <op> c`; `c` is a classical bit read
// from ONE SSA value, so the forward and the `_unc` see the same bit on every
// basis branch and the `_unc` returns `gl` to |0> exactly before its free.
// `f` is a rail the network minted (a compare flag or a node ancilla, never a
// user register — the classifier refuses a rail sibling), so nothing here reads
// or writes a register the whole-DAG spine could also claim.

#include "CondLiteral.h"

#include "ControlPlan.h"        // diagnoseUnderControl
#include "EmitInverse.h"        // emitInverseCall (the `_unc`, Rule 14)
#include "TaintPropagation.h"   // TaintSet
#include "TemplateName.h"       // Shape
#include "WidthDispatch.h"      // dataTemplateFn / freeFn

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"

using namespace llvm;

namespace cq {

namespace {

// Budget for one i1 cone walk. A PredMux edge literal is a De Morgan tree over
// one branch condition (depth ≤ 16 by `isSupportedCondTree`), so real cones are
// a handful of nodes; exhaustion is reported and both callers fail SAFE.
constexpr unsigned kConeBudget = 64;

// `Root` and every `i1` Instruction reachable backwards through operands.
// Returns false on budget exhaustion (`Out` then holds a prefix).
bool collectI1Cone(Value *Root, SmallVectorImpl<Instruction *> &Out) {
  SmallPtrSet<Value *, 16> Seen;
  SmallVector<Value *, 16> Work{Root};
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !I->getType()->isIntegerTy(1) || !Seen.insert(I).second)
      continue;
    if (Out.size() == kConeBudget)
      return false;
    Out.push_back(I);
    for (Value *Op : I->operands())
      Work.push_back(Op);
  }
  return true;
}

// bd `test_C_libtooling-xdu2.13` Rule-13 round 2 F-1 — taint does NOT cross a
// call RETURN (pre-existing, bd `test_C_libtooling-3jru`): `r = g(m)` with
// `g` returning `cq_theta(...)` is UNTAINTED in the caller although it is a
// quantum register's handle id. A literal must never read one. The taint set
// is MODULE-wide (`propagate` seeds every defined function), so the precise
// question is answerable: does any `ret` operand of a DEFINED callee — or,
// recursively, of a defined function IT calls on that return's cone — carry a
// tainted value? An INDIRECT call is undecidable and answers yes. A
// declaration answers no (external classical code; a cross-TU quantum return
// is bd 3jru's class, not fenced here). Budget/depth exhaustion answers yes.
constexpr unsigned kCallDepth = 8;
constexpr unsigned kFullConeBudget = 256;

bool fullConeReachesQuantumReturn(Value *Root, const TaintSet &taint,
                                  unsigned Depth);

bool returnsQuantum(const Function &F, const TaintSet &taint, unsigned Depth) {
  if (Depth > kCallDepth)
    return true;
  for (const BasicBlock &BB : F)
    if (const auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      if (Value *RV = R->getReturnValue())
        if (fullConeReachesQuantumReturn(RV, taint, Depth + 1))
          return true;
  return false;
}

// `Root`'s whole backward operand cone (every type): true iff some member is
// tainted (only asked below a call — the literal's own cone is untainted by
// conjunct (b)'s caller contract, and a tainted member there is refused too)
// or a call that `returnsQuantum`.
bool fullConeReachesQuantumReturn(Value *Root, const TaintSet &taint,
                                  unsigned Depth) {
  SmallPtrSet<Value *, 32> Seen;
  SmallVector<Value *, 32> Work{Root};
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !Seen.insert(I).second)
      continue;
    if (Seen.size() > kFullConeBudget)
      return true;
    if (taint.Tainted.count(I))
      return true;
    if (auto *CB = dyn_cast<CallBase>(I)) {
      const Function *Callee = CB->getCalledFunction();
      if (!Callee)
        return true;  // indirect: undecidable.
      if (!Callee->isDeclaration() && returnsQuantum(*Callee, taint, Depth))
        return true;
      // A call's ARGUMENTS are not walked: a tainted argument taints the call
      // itself (forward propagation), caught above — EXCEPT at a sink
      // (`cq_measure`, whose result is classical by Rule 3 and must stay a
      // legal literal) and the angle slot, neither of which is a quantum id.
      continue;
    }
    for (Value *Op : I->operands())
      Work.push_back(Op);
  }
  return false;
}

}  // namespace

void markPredictedTaintCone(Value *Root) {
  auto *RI = dyn_cast_or_null<Instruction>(Root);
  if (!RI)
    return;  // an Argument/Constant condition: nothing the flatten can re-taint.
  LLVMContext &Ctx = RI->getContext();
  MDNode *Mark = MDNode::get(Ctx, {});
  SmallVector<Instruction *, 16> Cone;
  if (!collectI1Cone(Root, Cone))
    RI->getFunction()->setMetadata(kPredMuxPredictedOverflowMD, Mark);
  for (Instruction *I : Cone)
    I->setMetadata(kPredMuxPredictedMD, Mark);
}

bool condLiteralAdmissible(Value *V, const TaintSet &taint) {
  // (a) a runtime classical bit with ONE SSA identity.
  if (!V || !V->getType()->isIntegerTy(1) || isa<Constant>(V))
    return false;
  Function *F = nullptr;
  if (auto *I = dyn_cast<Instruction>(V))
    F = I->getFunction();
  else if (auto *A = dyn_cast<Argument>(V))
    F = A->getParent();
  else
    return false;
  // (b) classical at the classifier's taint (re-asked at FINAL taint later).
  if (taint.Tainted.count(V))
    return false;
  // (c) not a PredMux rule-(B) residue.
  if (F && F->getMetadata(kPredMuxPredictedOverflowMD))
    return false;
  SmallVector<Instruction *, 16> Cone;
  if (!collectI1Cone(V, Cone))
    return false;
  for (Instruction *I : Cone)
    if (I->getMetadata(kPredMuxPredictedMD))
      return false;
  // (d) Rule-13 round 2 F-1: no quantum register id returned through a call.
  if (fullConeReachesQuantumReturn(V, taint, /*Depth=*/0))
    return false;
  return true;
}

CallInst *emitCondLiteralNode(IRBuilder<> &B, Instruction::BinaryOps Opc,
                              Value *Flag, Value *Lit, WidthDispatch &wd,
                              TaintSet &taint, const DebugLoc &DL) {
  if (Opc != Instruction::And && Opc != Instruction::Or)
    return nullptr;
  // The SAME resolver `lowerOps` mints a data `and i1`/`or i1` Q+C op through,
  // so the declaration cannot disagree with a data-path use in the same module.
  FunctionCallee Fn = wd.dataTemplateFn(
      Opc == Instruction::And ? "and" : "or", "i1", Shape::HL);
  if (!Fn)
    return nullptr;
  CallInst *G = B.CreateCall(Fn, {Flag, Lit}, "gl");
  if (DL)
    G->setDebugLoc(DL);
  // Rule-13 round 2 F-2: the runtime takes `bool b_classical`, which Clang's
  // ABI passes `zeroext`. Without the attribute an `i1` literal reaches the C
  // body with garbage high bits (MEASURED from C at -O1: a toggled `_Bool` in a
  // rolled loop printed 2/254/253 — a non-0/1 `bool`, UB). Call-site attribute
  // on the forward and on its `_unc` (below). The DATA path's `_hl` mints
  // (bd ix2v) are NOT changed here.
  G->addParamAttr(1, Attribute::ZExt);
  taint.CondLiteralGates.emplace_back(G);
  return G;
}

void stripCondLiteralNode(IRBuilder<> &B, CallInst *Tpl, WidthDispatch &wd,
                          TaintSet &taint) {
  // A `cq_template_*` forward always has a `_unc`; were it ever refused, the
  // rail is LEFT ALLOCATED (a Rule-6 leak), never freed dirty.
  if (!emitInverseCall(B, Tpl, wd, /*CurHandle=*/nullptr, &taint.SpineOps))
    return;
  // The `_unc` just minted sits immediately before the insertion point; its
  // literal is arg 2 (`_unc(out, h, lit)`) — same `zeroext` as the forward.
  if (auto *Unc = dyn_cast<CallInst>(&*std::prev(B.GetInsertPoint())))
    if (Unc->arg_size() == 3 && Unc->getArgOperand(2) == Tpl->getArgOperand(1))
      Unc->addParamAttr(2, Attribute::ZExt);
  CallInst *Free = B.CreateCall(wd.freeFn(), {Tpl});
  if (DebugLoc DL = Tpl->getDebugLoc())
    Free->setDebugLoc(DL);
}

bool declineQuantumCondLiterals(Module &M, TaintSet &taint) {
  (void)M;  // module-wide record; each gate names its own function.
  for (const WeakVH &H : taint.CondLiteralGates) {
    auto *G = dyn_cast_or_null<CallInst>(static_cast<Value *>(H));
    if (!G || !G->getFunction() || G->arg_size() != 2)
      continue;  // erased: no literal left to read.
    if (taint.Tainted.count(G->getArgOperand(1))) {
      diagnoseUnderControl(G, "classical condition literal became quantum-derived");
      return true;
    }
  }
  return false;
}

void stripPredMuxPredictedMarks(Module &M) {
  LLVMContext &Ctx = M.getContext();
  const unsigned Kind = Ctx.getMDKindID(kPredMuxPredictedMD);
  const unsigned OverflowKind = Ctx.getMDKindID(kPredMuxPredictedOverflowMD);
  for (Function &F : M) {
    F.setMetadata(OverflowKind, nullptr);
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        I.setMetadata(Kind, nullptr);
  }
}

}  // namespace cq
