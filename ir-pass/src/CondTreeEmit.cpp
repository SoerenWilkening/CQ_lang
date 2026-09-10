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

#include "ArmAnalysis.h"       // markRailCondRead (bd r9e5 1b-B.1 round 2)
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
void bracket(const CondNetwork::Node &N, const ControlledSymbols &csyms,
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

void emitCondNode(const CondNetwork::Node &N, const ControlledSymbols &csyms,
                  IRBuilder<> &B, const DebugLoc &DL, bool Inverse,
                  TaintSet *taint) {
  // bd test_C_libtooling-r9e5 (1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1) — THE
  // ONE PLACE A NODE'S CONTROL READ OF A USER REGISTER IS RECORDED. `N.L`/`N.R`
  // may be a RAIL LEAF (the register is its own flag: `FlagOf[rail] = rail`,
  // nothing minted) or a level ROOT that is one (the 4.3 nest's conjunction), so
  // both callers of this function need the record and neither can be trusted to
  // remember it separately — the `markBranchPhaseGate` lesson, one epic later.
  // FORWARD only: the inverse network re-reads the same register at the strip,
  // which proves nothing new and would double the entries.
  auto record = [&](CallInst *C) {
    if (!taint || Inverse)
      return;
    for (Value *Ctl : {N.L, N.R})
      if (Ctl && isCondRailLeaf(Ctl) && C->hasArgument(Ctl))
        markRailCondRead(*taint, Ctl, C);
  };
  auto stamp = [&DL, &record](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    record(C);
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

CondNetDisp emitCondNetwork(Value *Root, const CondTree &Tree,
                            WidthDispatch &wd,
                            const ControlledSymbols &csyms,
                            TaintSet &taint, Instruction *Before,
                            const DebugLoc &DL, bool AllowQQLeaves,
                            CondNetwork &Out, bool CopyRailRoot) {
  if (!Root || !Before)
    return CondNetDisp::Malformed;
  IRBuilder<> B(Before);
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  // bd test_C_libtooling-r9e5 (1b-B.1) — a BARE RAIL ROOT the caller asked to
  // COPY. Decided here, before anything is emitted, because it changes what the
  // i1 allocator is needed for: such a tree has NO nodes and NO compare leaves
  // (`collectCondTree` records the rail and returns), so the copy flag is the
  // only thing this network mints.
  const bool CopyRoot = CopyRailRoot && isCondRailLeaf(Root);
  // The i1 ancilla allocator is resolved BEFORE the walk, so a resolution
  // failure is a clean "emitted nothing" rather than a half-built network.
  FunctionCallee AllocI1;
  if (!Tree.Nodes.empty() || CopyRoot) {
    AllocI1 = wd.allocFn("i1");
    if (!AllocI1)
      return CondNetDisp::Malformed;
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
        return CondNetDisp::Malformed;  // detection/emission drift.
      CondNetwork::Node N;
      N.Opc = Opc;
      N.L = FlagOf.lookup(L);
      N.R = FlagOf.lookup(R);
      if (!N.L || !N.R)
        return CondNetDisp::Malformed;  // a child with no rail.
      N.G = stamp(B.CreateCall(AllocI1, {Constant::getNullValue(I1Ty)}, "g"));
      // bd test_C_libtooling-r9e5 (1b-B.1, F-B1R2-1) — `&taint` makes the node
      // emission RECORD its control read of a RAIL leaf (a non-root rail is read
      // by this node's cnots/toffoli and nothing is minted for it), for the
      // round-2 re-verification. The recording lives in `emitCondNode` and not
      // here so that the 4.3 nest's CONJUNCTION node — which calls it directly,
      // with a level ROOT that may itself be a rail — is covered by the same
      // line rather than by a second one that can be forgotten.
      emitCondNode(N, csyms, B, DL, /*Inverse=*/false, &taint);
      FlagOf[V] = N.G;
      Out.Nodes.push_back(N);
      continue;
    }
    if (FlagOf.count(V))
      continue;  // shared subtree — its rail is minted once and reused.
    // bd 3qlq.4 — a RAIL LEAF is its own flag: the register's rail is READ as
    // a control by the node gates and NOTHING is minted for it, so it is not
    // recorded in `Out.Leaves` and `stripCondNetwork` never strips or frees it
    // (the register is the user's). Same predicate the grammar used
    // (`isCondRailLeaf`, Rule 14), so detection and emission cannot drift.
    if (isCondRailLeaf(V)) {
      FlagOf[V] = V;
      continue;
    }
    if (auto *Leaf = dyn_cast<CmpInst>(V)) {
      Value *F = lowerCompareToFlag(
          Leaf, wd, taint,
          /*qqWidth=*/AllowQQLeaves ? qqSelectLeafWidth(Leaf, taint)
                                    : StringRef(),
          /*inverse=*/false, /*before=*/Before);
      if (!F)
        return CondNetDisp::MintDiagnosed;  // lowerCompareToFlag was LOUD.
      FlagOf[V] = F;
      Out.Leaves.push_back({Leaf, F});
      continue;
    }
    if (!decomposeCondNode(V, Opc, L, R, /*AllowLogicalSelect=*/true))
      return CondNetDisp::Malformed;
    Stack.push_back({V, true});
    Stack.push_back({R, false});
    Stack.push_back({L, false});  // left child visits first.
  }
  Out.Root = FlagOf.lookup(Root);
  Out.RootIsRail = isCondRailLeaf(Root);
  // bd test_C_libtooling-r9e5 (1b-B.1) — THE RAIL-ROOT COPY, minted LAST (so the
  // LIFO strip un-copies it FIRST) and only on the caller's explicit request.
  //
  // `f = |0>` then `cqrt_cnot(rail, f)` leaves the pair in `Σ α_x |x⟩_b |x⟩_f`
  // — a basis-label copy of a register that STAYS LIVE, not a move, so Rule 8's
  // no-cloning prohibition (which forbids FREEING a superposed source by
  // copy+uncompute) has no subject here: nothing about the register is freed or
  // disturbed. `rail` sits in the CONTROL slot of both cnots, exactly the
  // read-only position the node emissions already put a rail in, so no
  // non-diagonal gate is ever emitted ON the user's register (bd memory
  // [diagonal-only-on-user-registers-3qlq4]). The caller may then bracket `f`
  // with `cqrt_x` freely — it is an ancilla this network owns.
  if (CopyRoot && Out.Root) {
    Value *Rail = Out.Root;
    CallInst *F =
        stamp(B.CreateCall(AllocI1, {Constant::getNullValue(I1Ty)}, "bf"));
    CallInst *Cn = stamp(B.CreateCall(csyms.cnotFn(), {Rail, F}));
    // bd test_C_libtooling-r9e5 (1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1) —
    // THIS cnot is the 4.4 select's control read of the user's register, and it
    // is what the round-2 re-verification re-asks the §14.3 ladder against. The
    // select itself cannot be the anchor: `emitSelectRegion` step 6 erases it.
    markRailCondRead(taint, Rail, Cn);
    Out.RailRoot = Rail;
    Out.RailRootFlag = F;
    Out.Root = F;
    Out.RootIsRail = false;  // the root handed back is an ANCILLA now.
  }
  return Out.Root ? CondNetDisp::Ok : CondNetDisp::Malformed;
}

void stripCondNetwork(const CondNetwork &Net, WidthDispatch &wd,
                      const ControlledSymbols &csyms, TaintSet &taint,
                      Instruction *Before, const DebugLoc &DL,
                      bool AllowQQLeaves,
                      SmallVectorImpl<CallInst *> *StripsOut) {
  IRBuilder<> B(Before);
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };
  // bd test_C_libtooling-r9e5 (1b-B.1) — THE RAIL-ROOT COPY FLAG FIRST, because
  // it was minted LAST (exact LIFO). `cqrt_cnot` is an involution, so re-emitting
  // it returns `f` to `x ⊕ x = 0` on EVERY basis branch — a proven-|0> free
  // (Rule 6), and the register it reads is left exactly as the forward found it
  // (the merge's controlled copies write `%out`, never the condition rail; the
  // `cqrt_x` brackets act on `f`). Vacuous for every other caller: `RailRootFlag`
  // is null unless `CopyRailRoot` was asked for and the root was a rail.
  if (Net.RailRootFlag) {
    stamp(B.CreateCall(csyms.cnotFn(), {Net.RailRoot, Net.RailRootFlag}));
    stamp(B.CreateCall(wd.freeFn(), {Net.RailRootFlag}));
  }
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
    auto *Strip = dyn_cast_or_null<CallInst>(lowerCompareToFlag(
        LF.first, wd, taint,
        /*qqWidth=*/AllowQQLeaves ? qqSelectLeafWidth(LF.first, taint)
                                  : StringRef(),
        /*inverse=*/true, /*before=*/Before, /*negate=*/false,
        /*railToStrip=*/LF.second));
    if (StripsOut && Strip)
      StripsOut->push_back(Strip);
    stamp(B.CreateCall(wd.freeFn(), {LF.second}));
  }
}

}  // namespace cq
