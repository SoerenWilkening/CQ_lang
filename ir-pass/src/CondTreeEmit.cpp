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
#include "CondLiteral.h"         // emitCondLiteralNode (bd xdu2.13)
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
  //
  // bd `4aiu` (Track P) — A REGION-MERGE φ CONTROL IS RECORDED TOO, and this is
  // the L2 row the widening owes: `emitCondNetwork` widened the set of values
  // that may BE a flag, and this is the OTHER set computed over that same
  // closure. At the PHASE kickback the φ is still a `PHINode` when the node's
  // `cqrt_toffoli`/`cqrt_cnot` reads it (the prep is emitted after — the bd
  // `hcrg` chain edge), so an `isCondRailLeaf`-only test would have left the
  // user's register read by a control gate with NO record, and
  // `reverifyRailCondReads` would never re-ask the ladder on it after round 2.
  //
  // The SHAPE predicate is the right one HERE (rather than tree membership as in
  // `emitCondNetwork`): this function has no `CondTree`.
  //
  // ⚠ AND THE REASON IS *NOT* "over-recording only ever declines more" — that
  // sentence shipped here and it is FALSE (Rule-13 round-1 finding F-P1-5). A
  // record whose value is still a `PHINode` at `reverifyRailCondReads` is
  // SKIPPED by that loop's `dyn_cast_or_null<CallInst>`, so an over-recorded φ
  // declines NOTHING — it is inert, not conservative. The reason the shape test
  // is safe here is a MEMBERSHIP identity: `N.L`/`N.R` can only be a `PHINode`
  // when it is a `RailPhiLeaves` member, because `FlagOf[V] = V` (the `isRailFlag`
  // arm of the walk in `emitCondNetwork`) is the ONLY path that maps a value to
  // itself, and that arm asks membership. Shape ≡ membership at this site; the
  // two predicates cannot disagree about a value that reaches here.
  //
  // WHY THE SKIP DOES NOT LEAVE A HOLE TODAY: in the shipped order M-β has
  // RAUW'd the φ to the hoisted theta CALL before the re-verification runs, and
  // the `WeakTrackingVH` the record is stored in FOLLOWS that RAUW (bd `boi6`
  // site 12), so the register IS re-asked. See `TaintPropagation.h`'s
  // `RailCondReads` block for the three cases that loop distinguishes and for
  // the retirement trigger on this premise.
  auto record = [&](CallInst *C) {
    if (!taint || Inverse)
      return;
    for (Value *Ctl : {N.L, N.R})
      if (Ctl && (isCondRailLeaf(Ctl) || isCondRailPhiShape(Ctl)) &&
          C->hasArgument(Ctl))
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
                            CondNetwork &Out, bool CopyRailRoot,
                            bool LeafWireRuled) {
  if (!Root || !Before)
    return CondNetDisp::Malformed;
  // bd `4aiu` (Track P) — "IS THIS VALUE ALREADY ITS OWN FLAG?", the ONE spelling
  // inside this file. A `cq_theta_i1` RAIL always is (bd 3qlq.4). A REGION-MERGE
  // φ is too, but ONLY when the CALLER's own `collectCondTree` admitted it into
  // THIS tree (`AllowRailPhi`) — asked by MEMBERSHIP of `Tree.RailPhiLeaves`,
  // never by re-running `isCondRailPhiShape` here.
  //
  // ⚠ MEMBERSHIP IS THE ENFORCEMENT, exactly as the field's ELEMENT TYPE is in
  // `SelectClassify.h` (bd `boi6` H-3). This file serves four consumers (the flat
  // kickback, the depth-2 nest, the 4.4 select and `Specialization`'s forward-only
  // copy); three of them pass `AllowRailPhi = false`, so their trees carry no φ,
  // their `RailPhiLeaves` is empty, and a φ reaching them still falls through to
  // `decomposeCondNode` and returns `Malformed` — the loud decline they have
  // today. A shape predicate here would have silently handed every one of them a
  // capability none of them proved.
  //
  // The 4.4 select never exercises the φ arm in practice: by the time
  // `SelectMergeEmit` re-derives its tree, M-β has already RAUW'd the φ to a
  // `cq_theta_i1` call, so `isCondRailLeaf` fires first. The PHASE kickback is
  // the opposite — it is emitted BEFORE the prep (the bd `hcrg` chain edge), so
  // its φ is still a `PHINode` here and this clause is what makes it a control.
  //
  // ⚠ WHICH OF THE THREE `isRailFlag` USES ACTUALLY HAS A φ SUBJECT — ONE
  // (Rule-13 round-1 finding F-P1-4, correcting the record, not the code). Only
  // the in-walk `FlagOf[V] = V` below can be reached with a φ. `CopyRoot`
  // (`CopyRailRoot && isRailFlag(Root)`) and `Out.RootIsRail` cannot, and the
  // ground is stronger than "no caller does it today": `collectCondTree` records
  // a φ ROOT as a leaf and returns, so such a tree has NO nodes, so the flat
  // kickback's `IsTree` is false, so its `emitCondNetwork` call — the ONE call
  // site that passes `AllowRailPhi = true`, and it passes `CopyRailRoot = false`
  // — is not made at all. The other three call sites pass `AllowRailPhi = false`
  // and their `RailPhiLeaves` is empty by construction.
  //
  // ⚠ AND THE HAZARD NARRATIVE THAT USED TO JUSTIFY WIDENING `Out.RootIsRail`
  // WAS WRONG: "a φ root reaching this function would return `RootIsRail=false`
  // and the kickback would `cqrt_x`-BRACKET the user's register" could not
  // happen through this field. `emitPhaseKickbackRegion` computes
  // `FlagIsRail = IsTree ? Net.RootIsRail : (RailCond || RailPhiCond)`, and a φ
  // root takes the `!IsTree` arm, which never reads `Net.RootIsRail` at all. The
  // widening is still right in DIRECTION and stays (one spelling of "is this
  // value already its own flag", Rule 14) — it is defence in depth with no
  // subject, and saying so is the point: an overstated justification is how a
  // real guard gets deleted later as dead.
  //
  // RULE 7 HERE IS MEASURED, NOT ARGUED: across EVERY shipped φ PHASE accept
  // (`control_phase_kickback_mergephi_*.ll` + `…_rail_after_prep.ll`, 11 of them
  // when this was written) the emitted IR contains ZERO `call void @cqrt_x(`,
  // and on the φ SELECT accepts every `cqrt_x` targets the network's own fresh
  // `cqrt_alloc_i1(0)` root ancilla, never a prepped register (which appears
  // only in `cqrt_toffoli`/`cqrt_cnot` CONTROL slots and is never freed). Count
  // the family rather than trusting the number — the glob is the invariant.
  auto isRailFlag = [&Tree](const Value *V) {
    if (isCondRailLeaf(V))
      return true;
    const auto *P = dyn_cast<PHINode>(V);
    return P && llvm::is_contained(Tree.RailPhiLeaves, P);
  };
  // bd `test_C_libtooling-xdu2.13` — a classical LITERAL child, by MEMBERSHIP of
  // the caller's tree (empty for every caller but the 4.4 data select).
  auto isLit = [&Tree](const Value *V) {
    return llvm::is_contained(Tree.LiteralLeaves, V);
  };
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
  const bool CopyRoot = CopyRailRoot && isRailFlag(Root);
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
      // bd `test_C_libtooling-xdu2.13` — a MIXED node: one child is a classical
      // LITERAL (`CondLiteral.h`), minted by the `_hl` template on the other
      // child's flag. That flag must be one this network minted, never a rail.
      if (isLit(L) || isLit(R)) {
        Value *Q = isLit(L) ? R : L;
        N.L = FlagOf.lookup(Q);
        if (isLit(Q) || !N.L || isRailFlag(Q))
          return CondNetDisp::Malformed;
        N.Tpl = emitCondLiteralNode(B, Opc, N.L, isLit(L) ? L : R, wd, taint, DL);
        if (!N.Tpl)
          return CondNetDisp::Malformed;
        N.G = N.Tpl;
        FlagOf[V] = N.G;
        Out.Nodes.push_back(N);
        continue;
      }
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
    if (isRailFlag(V)) {
      FlagOf[V] = V;
      continue;
    }
    if (auto *Leaf = dyn_cast<CmpInst>(V)) {
      // (Track A.1, F-A1R2-1) The leaf's record carries the CALLER's answer to
      // "did a classifier walk this compare's wire at round 1?" — this file
      // serves four consumers and cannot tell which one is asking.
      Value *F = lowerCompareToFlag(
          Leaf, wd, taint,
          /*qqWidth=*/AllowQQLeaves ? qqSelectLeafWidth(Leaf, taint)
                                    : StringRef(),
          /*inverse=*/false, /*before=*/Before, /*negate=*/false,
          /*railToStrip=*/nullptr,
          /*readKind=*/LeafWireRuled ? CondReadKind::WireRuled
                                     : CondReadKind::Unruled);
      if (!F)
        return CondNetDisp::MintDiagnosed;  // lowerCompareToFlag was LOUD.
      FlagOf[V] = F;
      Out.Leaves.push_back({Leaf, F});
      continue;
    }
    if (!decomposeCondNode(V, Opc, L, R, /*AllowLogicalSelect=*/true))
      return CondNetDisp::Malformed;
    Stack.push_back({V, true});
    if (!isLit(R))
      Stack.push_back({R, false});
    if (!isLit(L))
      Stack.push_back({L, false});  // left child visits first.
  }
  Out.Root = FlagOf.lookup(Root);
  Out.RootIsRail = isRailFlag(Root);
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

// `stripCondNetwork` — the exact LIFO strip — lives in `CondTreeStrip.cpp`
// (moved verbatim by bd xdu2.13 to keep this file inside its line budget).

}  // namespace cq
