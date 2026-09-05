// CondTreeEmit.cpp — see header. The condition-tree flag NETWORK, lifted OUT of
// `SelectMergeEmit.cpp` steps 1 and 5 (bd test_C_libtooling-3qlq Inc 1 part B,
// PRD `retire-swap-route-PRD.md` §6.2 row P3) so the register-free BRANCH PHASE
// gets the same network instead of a third copy of it.
//
// THE LIFT IS A REFACTOR AND THE 4.4 LAYER IS THE WITNESS. With
// `AllowQQLeaves = true` and every `Neg*` false — exactly how `SelectMergeEmit`
// calls it — the walk, the traversal order, the emitted symbols, the operand
// order, the `!dbg` stamping and even the ancilla NAME (`g`) are the pre-lift
// code verbatim, so `control_swap_select_{and2,or2,or3_tree,xor2,…}.ll` and the
// `slice_control_select_*` / `slice_select_*` goldens must be byte-identical
// across the change. They are (measured — see the increment's progress record).
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2):
// every ancilla is minted at |0>, written by a permutation of read-only controls,
// and returned to |0> by the exact adjoint of that permutation before it is
// freed — so each `cqrt_free` here is a clean reset and never a hidden
// measurement (Rule 6). Nothing in this file copies a superposed source, so
// Rule 8 has no subject.

#include "CondTreeEmit.h"

#include "CompareLowering.h"     // lowerCompareToFlag / qqSelectLeafWidth
#include "ControlledSymbols.h"   // cnotFn / toffoliFn / xFn
#include "SelectClassify.h"      // CondTree / decomposeCondNode (the grammar)
#include "TaintPropagation.h"    // TaintSet
#include "WidthDispatch.h"       // allocFn / freeFn

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// The `cqrt_x` polarity bracket, emitted around a node's gates so a NEGATED
// control reads as its complement. `cqrt_x` is self-inverse and the flag is left
// exactly as it was found, which is what makes the bracket composable with the
// LIFO strip (the strip re-emits the same bracket).
void bracket(const CondNetwork::Node &N, ControlledSymbols &csyms,
             IRBuilder<> &B, const DebugLoc &DL) {
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };
  if (N.NegL)
    stamp(B.CreateCall(csyms.xFn(), {N.L}));
  if (N.NegR)
    stamp(B.CreateCall(csyms.xFn(), {N.R}));
}

}  // namespace

void emitCondNode(const CondNetwork::Node &N, ControlledSymbols &csyms,
                  IRBuilder<> &B, const DebugLoc &DL, bool Inverse) {
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };
  bracket(N, csyms, B, DL);
  // bd 3c6m.67 — XOR is the OR network MINUS its toffoli. Emitting OR's toffoli
  // on an xor node would compute `L ∨ R` and still verify, still pair every
  // free, and still print a plausible trace: the textbook verify-clean silent
  // miscompile. Pinned by the whole-file `WHOLE-NOT: cqrt_toffoli` in
  // control_swap_select_xor2.ll.
  if (!Inverse) {
    if (N.Opc == Instruction::Or || N.Opc == Instruction::Xor) {
      stamp(B.CreateCall(csyms.cnotFn(), {N.L, N.G}));
      stamp(B.CreateCall(csyms.cnotFn(), {N.R, N.G}));
    }
    if (N.Opc != Instruction::Xor)
      stamp(B.CreateCall(csyms.toffoliFn(), {N.L, N.R, N.G}));
  } else {
    // The EXACT adjoint: the same self-inverse gates in reverse order. (For AND
    // that is the single toffoli; for OR the toffoli then the two CNOTs in
    // reverse; for XOR the two CNOTs in reverse.) G returns to |0> exactly.
    if (N.Opc != Instruction::Xor)
      stamp(B.CreateCall(csyms.toffoliFn(), {N.L, N.R, N.G}));
    if (N.Opc == Instruction::Or || N.Opc == Instruction::Xor) {
      stamp(B.CreateCall(csyms.cnotFn(), {N.R, N.G}));
      stamp(B.CreateCall(csyms.cnotFn(), {N.L, N.G}));
    }
  }
  bracket(N, csyms, B, DL);
}

bool emitCondNetwork(Value *Root, const CondTree &Tree, WidthDispatch &wd,
                     ControlledSymbols &csyms, TaintSet &taint,
                     Instruction *Before, const DebugLoc &DL,
                     bool AllowQQLeaves, CondNetwork &Out) {
  if (!Root || !Before)
    return false;
  IRBuilder<> B(Before);
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  // The i1 ancilla allocator is resolved BEFORE the walk, so a resolution
  // failure is a clean "emitted nothing" rather than a half-built network.
  FunctionCallee AllocI1;
  if (!Tree.Nodes.empty()) {
    AllocI1 = wd.allocFn("i1");
    if (!AllocI1)
      return false;
  }
  Type *I1Ty = Type::getInt1Ty(Before->getContext());

  // Left-to-right POST-ORDER, the SAME two-phase stack `collectCondTree` walks
  // with (a (value, childrenDone) pair): each leaf mints its flag at FIRST visit
  // — a shared leaf mints ONCE, and the network's controls are read-only, so
  // sharing is safe by construction — and each node allocates its |0> ancilla
  // and computes onto it after both children exist. Flags and ancillas are NOT
  // added to `taint.Tainted`: their only users are `cqrt_*` calls, so
  // `uncompute` never selects them as terminals (the same treatment the single
  // pre-tree flag has always had).
  DenseMap<Value *, Value *> FlagOf;
  SmallVector<std::pair<Value *, bool>, 8> Stack;
  Stack.push_back({Root, false});
  while (!Stack.empty()) {
    auto [V, ChildrenDone] = Stack.pop_back_val();
    Instruction::BinaryOps Opc;
    Value *L = nullptr;
    Value *R = nullptr;
    if (ChildrenDone) {
      // The grammar is re-asked through `decomposeCondNode` rather than
      // re-derived here (Rule 14 — one spelling). `AllowLogicalSelect` is TRUE
      // unconditionally at this point: whatever the CALLER's grammar admitted is
      // already in `Tree`, and a node that is not decomposable cannot be in it.
      if (!decomposeCondNode(V, Opc, L, R, /*AllowLogicalSelect=*/true))
        return false;  // detection/emission drift — the caller declines loudly.
      CondNetwork::Node N;
      N.Opc = Opc;
      N.L = FlagOf.lookup(L);
      N.R = FlagOf.lookup(R);
      if (!N.L || !N.R)
        return false;  // a child with no rail — off-grammar past detection.
      N.G = stamp(B.CreateCall(AllocI1, {Constant::getNullValue(I1Ty)}, "g"));
      emitCondNode(N, csyms, B, DL, /*Inverse=*/false);
      FlagOf[V] = N.G;
      Out.Nodes.push_back(N);
      continue;
    }
    if (FlagOf.count(V))
      continue;  // shared subtree — its rail is minted once and reused.
    if (auto *Leaf = dyn_cast<CmpInst>(V)) {
      Value *F = lowerCompareToFlag(
          Leaf, wd, taint,
          /*qqWidth=*/AllowQQLeaves ? qqSelectLeafWidth(Leaf, taint)
                                    : StringRef(),
          /*inverse=*/false, /*before=*/Before);
      if (!F)
        return false;  // already diagnosed (unsupported width / predicate).
      FlagOf[V] = F;
      Out.Leaves.push_back({Leaf, F});
      continue;
    }
    if (!decomposeCondNode(V, Opc, L, R, /*AllowLogicalSelect=*/true))
      return false;
    Stack.push_back({V, true});
    Stack.push_back({R, false});
    Stack.push_back({L, false});  // left child visits first.
  }
  Out.Root = FlagOf.lookup(Root);
  return Out.Root != nullptr;
}

void stripCondNetwork(const CondNetwork &Net, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint,
                      Instruction *Before, const DebugLoc &DL,
                      bool AllowQQLeaves) {
  IRBuilder<> B(Before);
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };
  // NODES first, in REVERSE post-order — a parent un-computes while its
  // children's rails are STILL ALLOCATED, which is the whole reason the order is
  // load-bearing: the inverse network READS L and R, so freeing a child before
  // its parent's undo would be a use-after-free of a rail whose value the undo
  // needs (§5 of the pre-lift SelectMergeEmit; the 4.3 nest's §12.3 in
  // miniature).
  //
  // bd urlv audit — NO KEPT-CARRIER RECORD REACHES ANYTHING FREED HERE. Every
  // rail is minted BY `emitCondNetwork` at |0> and returned to |0> on the line
  // above its free; none is an operand of a gate writing a carrier the reversal
  // does not touch, and this TU mints NO `cqrt_tape_write_*`.
  for (const CondNetwork::Node &N : llvm::reverse(Net.Nodes)) {
    emitCondNode(N, csyms, B, DL, /*Inverse=*/true);
    stamp(B.CreateCall(wd.freeFn(), {N.G}));
  }
  // LEAVES second, in reverse MINT order: the `_unc` strip recomputes the
  // predicate on the leaf's ORIGINAL operands and XORs it back onto that leaf's
  // own rail (so it MUST run before the caller erases the tree), then the rail
  // is freed at a proven |0>.
  for (const auto &LF : llvm::reverse(Net.Leaves)) {
    lowerCompareToFlag(LF.first, wd, taint,
                       /*qqWidth=*/AllowQQLeaves
                           ? qqSelectLeafWidth(LF.first, taint)
                           : StringRef(),
                       /*inverse=*/true, /*before=*/Before, /*negate=*/false,
                       /*railToStrip=*/LF.second);
    stamp(B.CreateCall(wd.freeFn(), {LF.second}));
  }
}

}  // namespace cq
