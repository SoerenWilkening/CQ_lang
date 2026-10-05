// Specialization.cpp — the Phase 6 specialization driver (step 14, DD-1).

#include "Specialization.h"

#include "BennettWrap.h"
#include "CompareLowering.h"
#include "CondLiteral.h"      // condLiteralAdmissible / emitCondLiteralNode (bd p3kd.3)
#include "DeadValueLiveness.h"
#include "ControlledSymbols.h"
#include "IntrinsicLowering.h"
#include "LiteralIntegrity.h"  // findUndefOperandInBody (bd xy9n — the twin dup)
#include "OpcodeLowering.h"
#include "OpcodeSupport.h"
#include "PredMuxFlatten.h"
#include "QramLowering.h"      // lowerQramReads (bd 20xt.4 spec-callee QROM read)
#include "SelectClassify.h"    // collectCondTree / CondTree (5po2 I2 compound cond)
#include "SelectMergeEmit.h"   // materializeCopySource (5po2 I2 classical arm)
#include "SpecializeClone.h"
#include "SpecializePlan.h"
#include "SpecializeReject.h"
#include "SpecializeSeed.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <algorithm>
#include <optional>
#include <string>
#include <utility>
#include <vector>

using namespace llvm;

namespace cq {

// bd `test_C_libtooling-vsfp` — see Specialization.h. Mirrored
// character-for-character by `spec_reject_phantom_arg_read*.ll`. Asked by
// `resolvePhantomCloneArgReads` (module level) and, since bd `nlfd`, by
// `buildClone` (the same rule one clone level down).
static constexpr char kMsgPhantomArgRead[] =
    "cq specialization: quantum argument to a parameter the lifted callee never "
    "reads";

namespace {

// A forward `cq_template_*` data call minted into the clone (exclude the void
// `_unc` / fresh-minting `_inv` adjoint twins, though none exist at capture time
// — BennettWrap mints them after). Used to build the forward stream + scratch
// rails for the Bennett wrap.
bool isForwardTemplate(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return false;
  StringRef N = F->getName();
  return N.starts_with("cq_template_") && !N.ends_with("_unc") &&
         !N.ends_with("_inv");
}

// bd 20xt.4: a forward `cqrt_qram_load_<W>(arr, idx)` minted into the clone by
// `lowerQramReads` — a reversible data producer (Toffoli copy-out) whose result is
// a dead value rail the Bennett wrap reverses (via `cqrt_qram_load_<W>_unc`, which
// un-copies the rail using the preserved cell) and then frees. Captured like an
// `isForwardTemplate` result (ForwardStream + ScratchRails). NOT the array-handle
// `cqrt_qram_alloc_<W>` (a CLASSICAL resource token — never tainted, never reversed
// or freed, matching the top-level `isQramArrayHandle` disposition) and NOT the
// `_unc` twin (a reverse-only op the wrap mints itself).
bool isForwardQramLoad(const CallInst *CI) {
  const Function *F = CI->getCalledFunction();
  if (!F)
    return false;
  StringRef N = F->getName();
  return N.starts_with("cqrt_qram_load_") && !N.ends_with("_unc");
}

// Scrub `V` from every clone taint work-list (mirror of SwapRouteEmit/
// SelectMergeEmit::scrubTaint) so a later stage never dereferences a freed
// pointer after lowerCloneSelect erases the dead condition tree.
void scrubCloneTaint(Instruction *I, TaintSet &ct) {
  ct.Tainted.erase(I);
  ct.BirthOrder.erase(I);
  ct.StaleDeclined.erase(I);
  ct.HandleWidth.erase(I);
}

// 5po2 I2: mint the tainted select's condition NETWORK forward-only inside the
// clone, returning the ROOT flag that gates the copies. Mirrors the top-level
// `emitSelectRegion` step-1 network mint (Rule 14 — same `collectCondTree`
// grammar, same leaf/AND/OR ops), with the ONE clone difference: NOTHING is
// stripped here (no `_inv`, no free) — every leaf flag and node ancilla is kept
// LIVE and captured for the SINGLE Bennett-wrap reverse (H1). Post-order over the
// and/or tree: each `CmpInst` leaf mints its HL flag (`lowerCompareToFlag`, a
// `cq_template_icmp_*` the wrap captures via `isForwardTemplate` automatically),
// each node conjoins onto a fresh |0> i1 ancilla — AND: `toffoli(l,r,g)`; OR:
// `cnot(l,g); cnot(r,g); toffoli(l,r,g)`. The node toffoli/cnot mints join
// `NodeMints` (ForwardStream reverse-only — self-inverse, `cqrt_toffoli`/
// `cqrt_cnot` are in `isInverseEmittable` post-I2) and the i1 ancilla allocs join
// `NodeRails` (ScratchRails — the wrap frees them after the reverse zeroes them).
// A single-leaf tree mints exactly the pre-I2 single flag (no ancilla), so the
// existing one-flag fixtures are byte-identical. bd p3kd.3: a CLASSICAL LITERAL
// child of an `and`/`or` node (`Tree.LiteralLeaves`, collected by
// `lowerCloneSelect` with `condLiteralAdmissible`) is never walked and never
// minted; its node is the top-level 4.4 select's `emitCondLiteralNode`,
// `gl = cq_template_<and|or>_i1_hl(flag, literal)`, a forward data template the
// wrap captures (`isForwardTemplate`) and reverses with the SAME SSA literal.
// Returns null after a diagnosed leaf (unsupported width/predicate, or a per-leaf
// Q+Q compare).
Value *mintCondNetwork(Value *Root, const CondTree &Tree, WidthDispatch &wd,
                       ControlledSymbols &csyms, TaintSet &ct, SelectInst *SI,
                       IRBuilder<> &B, const DebugLoc &DL,
                       SmallPtrSetImpl<CallInst *> &NodeMints,
                       SmallPtrSetImpl<Value *> &NodeRails) {
  auto stamp = [&](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
    return C;
  };
  // Per-leaf taint fence.
  //   * A Q+Q leaf (BOTH operands tainted) mints the QQ compare template when
  //     its shared logical width resolves in-surface (bd adia — the shared
  //     `qqSelectLeafWidth` gate, mirroring the top-level select path); an
  //     off-surface Q+Q (width mismatch, i1/i80/i128) still loud-declines.
  //   * An ALL-CLASSICAL leaf (NEITHER operand tainted) — reachable inside a COMPOUND
  //     tree whose taint comes from a SIBLING leaf (`lowerCloneSelect`'s `CondT` is
  //     true if ANY leaf touches taint) — would fall into `lowerCompareToFlag`'s Q+C
  //     branch with both operands classical, landing the classical runtime value in
  //     the i32 HANDLE slot (`cq_template_icmp_..._hl(i32 %classical, k)`): a phantom
  //     rail ID aliasing an unrelated qubit — a verify-clean WRONG UNITARY (the §5.2
  //     classical-operand-as-handle prohibition; the Rule-13 CONFIRMED finding). The
  //     bd p3kd.3: a classical child of an `and`/`or` node is now a LITERAL (see
  //     above) and never reaches this loop, exactly as at the top level (CondLiteral.h).
  //     What still does is a classical leaf the literal grammar does not offer —
  //     under an `xor` node (no `cq_template_xor_i1_hl`), or in a tree the literal
  //     grammar failed to collect — and the fence keeps refusing it
  //     (spec_reject_clone_classical_leaf_xor.ll).
  for (CmpInst *Leaf : Tree.Leaves) {
    bool T0 = ct.Tainted.count(Leaf->getOperand(0));
    bool T1 = ct.Tainted.count(Leaf->getOperand(1));
    if (T0 && T1) {
      // bd adia (3c6m.55 Lever C): a Q+Q leaf is mintable when its shared logical width
      // resolves in-surface (qqSelectLeafWidth — the same predicate the
      // top-level select path gates on); the QQ mint below then passes the
      // width through. Off-surface Q+Q still declines loudly.
      if (qqSelectLeafWidth(Leaf, ct).empty()) {
        SI->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
            *SI->getFunction(),
            "cq specialization: quantum-quantum compare condition under "
            "quantum lift",
            SI->getDebugLoc()));
        return nullptr;
      }
    }
    if (!T0 && !T1) {
      SI->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
          *SI->getFunction(),
          "cq specialization: classical compare leaf in a quantum condition under "
          "quantum lift",
          SI->getDebugLoc()));
      return nullptr;
    }
  }
  // bd p3kd.3 — a classical LITERAL child, by MEMBERSHIP of the tree the caller
  // collected (the CondTreeEmit `isLit` spelling).
  auto isLit = [&Tree](const Value *V) {
    return llvm::is_contained(Tree.LiteralLeaves, V);
  };
  // The i1 ancilla allocator is resolved only for a node that conjoins two flags
  // (a literal node mints its own rail), so a literal-only network declares none.
  FunctionCallee AllocI1;
  if (llvm::any_of(Tree.Nodes, [&](Instruction *N) {
        return !isLit(N->getOperand(0)) && !isLit(N->getOperand(1));
      })) {
    AllocI1 = wd.allocFn("i1");
    if (!AllocI1)
      return nullptr;  // no i1 ancilla allocator (unreachable — defensive).
  }
  Type *I1Ty = Type::getInt1Ty(SI->getContext());
  DenseMap<Value *, Value *> FlagOf;  // tree value → rail (shared leaf minted once)
  SmallVector<std::pair<Value *, bool>, 8> Stack;
  Stack.push_back({Root, false});
  while (!Stack.empty()) {
    auto [V, ChildrenDone] = Stack.pop_back_val();
    if (ChildrenDone) {
      // AllowLogicalSelect is OFF for this caller (see SelectClassify.h), so
      // every node here is a `BinaryOperator` by construction. bd
      // test_C_libtooling-3qlq Inc 1 part B lifted the SELECT-path network into
      // `CondTreeEmit`; this forward-ONLY clone variant (flags kept LIVE for the
      // single Bennett-wrap reverse, its own `cqq.g` ancilla name, its own
      // NodeMints/NodeRails capture) is deliberately NOT folded into it in this
      // increment — the shapes differ in what they DO NOT emit, and unifying
      // them would move the specialization goldens. Filed as a follow-on.
      auto *BO = cast<BinaryOperator>(V);
      // bd p3kd.3 — a MIXED node: `gl = cq_template_<and|or>_i1_hl(f, lit)` on the
      // other child's flag, the classical bit in the `_hl` literal slot (Rule 15:
      // never a handle). `collectCondTree` offers a literal only under `and`/`or`
      // and never both children, so a miss below is detection/emission drift.
      if (isLit(BO->getOperand(0)) || isLit(BO->getOperand(1))) {
        const bool LitIsL = isLit(BO->getOperand(0));
        Value *Lit = BO->getOperand(LitIsL ? 0 : 1);
        Value *Q = BO->getOperand(LitIsL ? 1 : 0);
        Value *QF = isLit(Q) ? nullptr : FlagOf.lookup(Q);
        CallInst *G = QF ? emitCondLiteralNode(B, BO->getOpcode(), QF, Lit, wd,
                                               ct, DL)
                         : nullptr;
        if (!G) {
          SI->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
              *SI->getFunction(),
              "cq specialization: classical compare leaf in a quantum condition "
              "under quantum lift",
              SI->getDebugLoc()));
          return nullptr;
        }
        // The Bennett wrap reverses G through `emitInverseCall`'s DD-3 adjoint
        // `<forward>_unc(out, f, lit)`, minted with NO call-site attributes, while
        // the runtime takes `bool b_classical` (Clang: `zeroext`; CondLiteral's
        // round-2 F-2 measured garbage high bits without it). `emitCondLiteralNode`
        // stamps the forward call; the adjoint (and every copy of it the twin
        // synthesis makes) gets it from the DECLARATION, which call lowering reads.
        // The type is exactly the one `emitInverseCall` builds, so it reuses this.
        Type *UncParams[] = {G->getType(), QF->getType(), Lit->getType()};
        FunctionCallee Unc = SI->getModule()->getOrInsertFunction(
            (G->getCalledFunction()->getName() + "_unc").str(),
            FunctionType::get(Type::getVoidTy(SI->getContext()), UncParams,
                              /*isVarArg=*/false));
        if (auto *UF = dyn_cast<Function>(Unc.getCallee()))
          UF->addParamAttr(2, Attribute::ZExt);
        FlagOf[V] = G;
        continue;
      }
      Value *L = FlagOf.lookup(BO->getOperand(0));
      Value *Rv = FlagOf.lookup(BO->getOperand(1));
      CallInst *G =
          stamp(B.CreateCall(AllocI1, {Constant::getNullValue(I1Ty)}, "cqq.g"));
      NodeRails.insert(G);
      // *** bd 3c6m.67 — THE XOR NODE MUST BE MIRRORED HERE TOO. ***
      // This is the SECOND consumer of `collectCondTree` (the clone/lift path),
      // and widening that one grammar without this switch would have emitted
      // OR's `toffoli(L,Rv,G)` for an xor node — computing `L ∧ Rv` where the
      // source says `L ⊕ Rv`, verify-clean, with every rail still pairing. The
      // grammar and its emitters are coupled: a future node kind added to
      // `collectCondTree` owes an arm HERE as well as in `SelectMergeEmit`
      // (Rule 14 — one grammar, and every emitter that reads it).
      const auto Opc = BO->getOpcode();
      if (Opc == Instruction::Or || Opc == Instruction::Xor) {
        NodeMints.insert(stamp(B.CreateCall(csyms.cnotFn(), {L, G})));
        NodeMints.insert(stamp(B.CreateCall(csyms.cnotFn(), {Rv, G})));
      }
      if (Opc != Instruction::Xor)
        NodeMints.insert(stamp(B.CreateCall(csyms.toffoliFn(), {L, Rv, G})));
      FlagOf[V] = G;
      continue;
    }
    if (FlagOf.count(V))
      continue;  // shared subtree — its rail is minted once and reused.
    if (auto *Leaf = dyn_cast<CmpInst>(V)) {
      // Rule-13 re-clear note (2026-07-17): a leaf comparing an i1 value (e.g.
      // `icmp eq i1 %innerflag, false` — a NOT over a tainted sub-compare) is
      // accepted here where the top-level `SelectClassify` (SelectClassify.cpp:462)
      // fences it. Sound TODAY: the inner producer lowers independently to a flag
      // handle in the data position, which fills this leaf's handle slot, and the
      // `i1_hl` template + its `_unc` exist and reverse coherently. If compare
      // lowering ever changes how an i1-operand compare is minted, RE-REVIEW this
      // acceptance (it is an asymmetry vs the top level, not a miscompile today).
      // (Track A.1, F-A1R2-1) `Unruled`, and it is inert either way: this mint
      // passes the CLONE's `cloneTaint`, so the record lands in a `TaintSet`
      // `reverifyCmpCondReads` never reads, and `specialize` runs after that
      // stage. Spelled rather than defaulted so the enumeration is complete in
      // the source (IMPL_A1.md §7 O-5).
      Value *F = lowerCompareToFlag(Leaf, wd, ct,
                                    /*qqWidth=*/qqSelectLeafWidth(Leaf, ct),
                                    /*inverse=*/false, /*before=*/SI,
                                    /*negate=*/false,
                                    /*railToStrip=*/nullptr,
                                    /*readKind=*/CondReadKind::Unruled);
      if (!F)
        return nullptr;  // lowerCompareToFlag already diagnosed (width/predicate).
      FlagOf[V] = F;
      continue;
    }
    auto *BO = cast<BinaryOperator>(V);  // grammar proven by collectCondTree.
    Stack.push_back({V, true});
    // A literal child is read by its node's `_hl` mint, never walked: walking it
    // would mint the phantom `cq_template_icmp_*_hl(i32 %classical, k)` the fence
    // above exists to refuse.
    if (!isLit(BO->getOperand(1)))
      Stack.push_back({BO->getOperand(1), false});
    if (!isLit(BO->getOperand(0)))
      Stack.push_back({BO->getOperand(0), false});
  }
  return FlagOf.lookup(Root);
}

// 5po2: lower each LIFTABLE tainted `select` in `Clone` to a 4.4 controlled-XOR
// copy, run in `buildClone` AFTER `seedClone`/the inner-clone drain and BEFORE
// `lowerOps` (so the fresh `cq_template_icmp` flag mint is an ordinary data
// template `lowerOps`/the wrap already understand, and the stock `icmp` feeding
// the select is consumed before `lowerOps` would lower a spurious dead compare).
//
// I1 shapes: `select(icmp(param,k), param, 0)` → one controlled copy
// `out = flag ? param : 0`; `select(icmp, derived, derived)` (int or fp) → the
// full 4.4 two-copy stream. I2 GENERALIZES two axes, keeping every emitted call
// FORWARD-ONLY (flags LIVE, no local strip — the Bennett wrap owns the single
// reverse, H1):
//   * COMPOUND condition — the condition is generalized from a single `ICmpInst`
//     to a `collectCondTree` and/or-tree (the PredMux-flattened nested-guard edge
//     predicate `¬g1∧g2`), minted forward-only by `mintCondNetwork` (leaf
//     `cq_template_icmp` flags + `cqrt_toffoli`/`cqrt_cnot` conjunctions).
//   * CLASSICAL arm — a non-tainted (constant sentinel / classical-runtime) arm is
//     materialized into a copy-source rail via `materializeCopySource` (Rule 14).
//     The materialized |const⟩ rail is SEPARABLE classical data — left ALLOCATED,
//     never freed (Rule 6; the SAME behavior the top-level `emitSelectRegion`
//     exhibits, so int/fp are uniform and no fp-`xorc` clean is needed). It is
//     captured into NEITHER stream/rail set (leaked); the copy that reads it IS in
//     `CopyOps` and the Bennett reverse re-reads the still-live |const⟩.
//
// Trichotomy (taint re-proof; the SHAPE gate in SpecializeReject is taint-blind):
//   * condition classical AND both arms classical → whole-classical select, LEAVE
//     for the backend (taint is the only Q/C boundary).
//   * condition classical AND some arm tainted → classical control over quantum
//     data → LOUD decline (the unforgivable mixed shape).
//   * condition tainted → emit; each arm is a handle (tainted, threaded as-is) or a
//     materialized rail (classical). NO decline — a tainted-condition mux over any
//     mix of tainted/classical arms is the 4.4/4.5 data-mux (the sentinel case).
//
// `CopyOps` collects the void controlled copies + the `cqrt_x` ¬flag brackets
// (ForwardStream reverse-only); `OutRails` the out alloc + the i1 network ancilla
// allocs (ScratchRails); `NodeMints` the `cqrt_toffoli`/`cqrt_cnot` network mints
// (ForwardStream reverse-only). The buildClone capture wires each into the wrap.
void lowerCloneSelect(Function &Clone, TaintSet &cloneTaint, WidthDispatch &wd,
                      SmallPtrSetImpl<CallInst *> &CopyOps,
                      SmallPtrSetImpl<Value *> &OutRails,
                      SmallPtrSetImpl<CallInst *> &XBrackets,
                      SmallPtrSetImpl<CallInst *> &NodeMints) {
  ControlledSymbols csyms(*Clone.getParent(), wd);
  SmallVector<SelectInst *, 4> Selects;  // snapshot before mutation
  for (BasicBlock &BB : Clone)
    for (Instruction &I : BB)
      if (auto *SI = dyn_cast<SelectInst>(&I))
        Selects.push_back(SI);

  for (SelectInst *SI : Selects) {
    // The condition must be a `collectCondTree`-recognized `CmpInst` / and/or tree.
    // Anything off-grammar (a bare i1 phi/trunc/xor after a partial flatten) is not
    // a lifted shape — leave it; the buildClone "no tainted select survives" backstop
    // declines a surviving tainted select loudly.
    CondTree Tree;
    // bd 3qlq.4: a tree carrying a RAIL LEAF (a bare `_Bool` register as the
    // condition) is skipped exactly as an off-grammar condition was before the
    // grammar admitted it — this lift mints per COMPARE leaf and has no
    // rail-leaf lowering; the disposition here is deliberately UNCHANGED.
    // bd `boi6` (D-B) / Track M: the same for a REGION-MERGE-φ leaf. `AllowRailPhi`
    // is not passed here, so such a tree is ALREADY off-grammar and this clause is
    // the belt to that braces — but the obligation the `CondTree` header states is
    // that every consumer DECIDE on the field explicitly, and a consumer whose
    // decision is implicit in a defaulted argument is the kind of "absence of a
    // decision that hardened by repetition" this project has been bitten by (the
    // missing `xor i1` node, bd 3c6m.67). The decision is: SKIP.
    if (!collectCondTree(SI->getCondition(), Tree) ||
        !Tree.RailLeaves.empty() || !Tree.RailPhiLeaves.empty())
      continue;
    const bool IsFp = SI->getType()->isFloatingPointTy();

    // Taint trichotomy. `CondT` = ANY leaf compares a tainted operand (the whole
    // network is then a quantum flag); `TrueT`/`FalseT` = arm carries taint.
    bool CondT = false;
    for (CmpInst *Leaf : Tree.Leaves)
      if (cloneTaint.Tainted.count(Leaf->getOperand(0)) ||
          cloneTaint.Tainted.count(Leaf->getOperand(1))) {
        CondT = true;
        break;
      }
    bool TrueT = cloneTaint.Tainted.count(SI->getTrueValue());
    bool FalseT = cloneTaint.Tainted.count(SI->getFalseValue());
    if (!CondT) {
      if (!TrueT && !FalseT)
        continue;  // whole-classical select — leave for the backend.
      // A classical condition selecting a quantum arm is classical control over
      // quantum data — the unforgivable mixed shape (Prime Directive).
      Clone.getContext().diagnose(DiagnosticInfoUnsupported(
          Clone,
          "cq specialization: mixed classical/quantum select under quantum lift",
          SI->getDebugLoc()));
      continue;  // loud decline (opt exits non-zero) — never a partial emit.
    }

    // bd p3kd.3 — the condition is quantum: re-collect it with the top-level 4.4
    // select's LITERAL rule (`condLiteralAdmissible`, CondLiteral.h, asked of the
    // CLONE's taint), so a classical child of an `and`/`or` node is the network's
    // classical input rather than a compare leaf to mint. The trichotomy above keeps
    // reading the plain tree, so every classical-condition verdict is unchanged. A
    // tree the literal grammar does not collect (a node with two literal children,
    // reachable only under an `xor`) keeps the plain tree, whose classical leaf the
    // per-leaf fence in `mintCondNetwork` refuses. The clone's taint is FINAL here:
    // `specialize` runs after the round-2 fixpoint and `declineQuantumCondLiterals`,
    // and the clone's mask is fixed at its build, so no later round can make this
    // literal quantum (L1).
    {
      CondTree LitTree;
      auto IsLit = [&cloneTaint](Value *V) {
        return condLiteralAdmissible(V, cloneTaint);
      };
      if (collectCondTree(SI->getCondition(), LitTree,
                          /*AllowLogicalSelect=*/false, /*AllowRailPhi=*/false,
                          IsLit) &&
          LitTree.RailLeaves.empty() && LitTree.RailPhiLeaves.empty())
        Tree = std::move(LitTree);
    }

    StringRef Abi = abiWidthFromType(SI->getType());  // "i32" | "f16..f80"
    FunctionCallee Alloc = wd.allocFn(Abi);
    Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
    FunctionCallee Copy =
        IsFp ? csyms.copyControlledFpFn(Abi) : csyms.copyControlledFn(Abi);
    if (!Alloc || !RailTy || !Copy)
      continue;  // unsupported width past the gate — leave for the loud backstop.
    const DebugLoc DL = SI->getDebugLoc();
    IRBuilder<> B(SI);  // every stream call lands immediately before the select.
    auto stamp = [&](CallInst *C) {
      if (DL)
        C->setDebugLoc(DL);
    };

    // 1. MINT the condition NETWORK forward-only — kept LIVE (the Bennett reverse
    //    plays its adjoint, NOT a local strip). Reuses `mintCondNetwork`.
    Value *Flag = mintCondNetwork(SI->getCondition(), Tree, wd, csyms, cloneTaint,
                                  SI, B, DL, NodeMints, OutRails);
    if (!Flag)
      continue;  // mintCondNetwork already diagnosed (Q+Q / width / predicate).

    // 2. ALLOC the |0> out rail (i32 or fp). It joins `cloneTaint` so the RAUW'd
    //    select result classifies as a quantum handle / ReturnTainted holds.
    CallInst *Out = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "cqq.sel");
    stamp(Out);
    cloneTaint.Tainted.insert(Out);
    cloneTaint.BirthOrder[Out] = cloneTaint.NextBirth++;
    // bd adia (3c6m.55 Lever C): record the out-rail's LOGICAL ABI width — the p119.6
    // downstream-consumer invariant, clone edition (a later cast/Q+Q compare
    // off the RAUW'd select otherwise reads the laundered i32 and declines).
    cloneTaint.HandleWidth[Out] = Abi;
    OutRails.insert(Out);

    // The increment-1 ONE-COPY fast path: a single-leaf tree, a const-ZERO false
    // arm, and a tainted true arm needs no ¬flag copy (out starts |0>, false→0 is
    // a no-op). Byte-identical to the pre-I2 stream; keeps the I1 fixtures pinned.
    auto *FalseC = dyn_cast<ConstantInt>(SI->getFalseValue());
    const bool OneCopy = !IsFp && Tree.Nodes.empty() && FalseC &&
                         FalseC->isZero() && TrueT;

    // 3. The controlled copies (materialize a classical arm to a copy-source rail).
    //    A tainted arm is threaded AS-IS — the later (taint-gated) `lowerOps` RAUWs
    //    its fp producer (sitofp/fneg) to an i32 handle, so the copy's `src` becomes
    //    well-typed (the deferred-RAUW the top-level 4.4 emitter also relies on). A
    //    materialized |const⟩ rail is separable classical data — left allocated,
    //    NOT captured (leaked; Rule 6), the copy reading it is captured and reversed.
    if (OneCopy) {
      // out = flag ? param : 0 — one copy (false arm is const 0, no ¬flag bracket).
      CallInst *CC = B.CreateCall(Copy, {Flag, SI->getTrueValue(), Out});
      stamp(CC);
      CopyOps.insert(CC);
    } else {
      // out = flag ? T : F — copy T on flag, then the ¬flag `cqrt_x`-bracketed copy
      // of F. The bracket encloses ONLY the second copy (SelectMergeEmit §16.3
      // order); both `cqrt_x` are captured into `XBrackets` so the Bennett reverse
      // re-brackets them (the kmdc dropped-bracket hazard).
      Value *TrueSrc =
          materializeCopySource(SI->getTrueValue(), Alloc, cloneTaint, B, DL);
      CallInst *CopyT = B.CreateCall(Copy, {Flag, TrueSrc, Out});
      stamp(CopyT);
      CopyOps.insert(CopyT);
      CallInst *X1 = B.CreateCall(csyms.xFn(), {Flag});
      stamp(X1);
      XBrackets.insert(X1);
      Value *FalseSrc =
          materializeCopySource(SI->getFalseValue(), Alloc, cloneTaint, B, DL);
      CallInst *CopyF = B.CreateCall(Copy, {Flag, FalseSrc, Out});
      stamp(CopyF);
      CopyOps.insert(CopyF);
      CallInst *X2 = B.CreateCall(csyms.xFn(), {Flag});
      stamp(X2);
      XBrackets.insert(X2);
    }

    // 4. REWIRE + erase the select and cascade-erase the now-dead condition tree
    //    (root-first, use_empty-guarded — a SHARED leaf/node also read as data keeps
    //    its other users, exactly as `emitSelectRegion` step 6). Scrub each from
    //    cloneTaint so `lowerOps`/the capture never deref a freed pointer.
    SI->replaceAllUsesWith(Out);
    scrubCloneTaint(SI, cloneTaint);
    SI->eraseFromParent();
    for (Instruction *N : llvm::reverse(Tree.Nodes))
      if (N->use_empty()) {
        scrubCloneTaint(N, cloneTaint);
        N->eraseFromParent();
      }
    for (CmpInst *Leaf : llvm::reverse(Tree.Leaves))
      if (Leaf->use_empty()) {
        scrubCloneTaint(Leaf, cloneTaint);
        Leaf->eraseFromParent();
      }
  }
}

// Rebuild `ct.Tainted` from the persistent tainted params via the SAME forward
// transitive-user closure `seedClone` uses (Rule 14). A full rebuild
// (clear-then-seed) is required after a PredMux flatten, not a merge: the flatten
// ERASED the diamond blocks, so the pre-flatten `ct.Tainted` holds dangling
// instruction pointers — reading their `users()` would be a use-after-free. The
// tainted params are never erased, and every clone-body taint derives
// (transitively) from them, so a param-rooted re-closure recovers the full set.
// `HandleWidth`/`BirthOrder` are keyed on persistent params/rails (never the
// erased body values), so they are preserved untouched.
void reseedCloneTaintFromParams(Function &Clone,
                                ArrayRef<Argument *> TaintedParams,
                                TaintSet &ct) {
  ct.Tainted.clear();
  std::vector<Value *> WL;
  for (Argument *A : TaintedParams)
    if (ct.Tainted.insert(A).second)
      WL.push_back(A);
  while (!WL.empty()) {
    Value *V = WL.back();
    WL.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || I->getFunction() != &Clone)
        continue;
      if (ct.Tainted.insert(I).second)
        WL.push_back(I);
    }
  }
}

// 5po2 I2: normalize genuine multi-EXIT `ret` control — N `ret`s in distinct
// blocks (the synthetic `if(g)return C; … return f(x)` early-return ladder, and a
// robustness guard for any front-end that does NOT pre-merge the way `clang -O1`
// does) — into a single-exit merge-phi block, so the scoped PredMux flatten below
// sees the SAME merge-phi diamond `clang -O1` already produces from an early-return
// ladder. A rotation-free value clone: the merge is a pure phi + one `ret` (NO
// controlled gates — the 65wb controlled-return substrate specialized to a value
// body; the phi becomes a chained select under PredMux, then the 4.4/4.5
// controlled-copy mux under `lowerCloneSelect`). Identities (returns, their values,
// the parents) are captured BEFORE the first mutation (Rule 9 / H3). Idempotent: a
// single-`ret` body (the common `clang -O1` shape) is left byte-untouched. Purely
// structural — the new phi's taint is recovered by `reseedCloneTaintFromParams`
// after the flatten (as in I1); PredMux roots at the UNCHANGED tainted guard `br`s.
void normalizeReturnMerge(Function &Clone) {
  SmallVector<ReturnInst *, 4> Rets;
  for (BasicBlock &BB : Clone)
    if (auto *R = dyn_cast<ReturnInst>(BB.getTerminator()))
      Rets.push_back(R);
  if (Rets.size() < 2)
    return;  // already single-exit (the common clang -O1 shape) — nothing to do.
  // Only VALUE returns merge into a phi; a void return has no value. `scanBody`
  // proved a non-void (i32 / reversible-fp) return, so every `ret` here carries a
  // value — bail defensively if not (leave for the size!=1 backstop).
  Type *RetTy = Clone.getReturnType();
  for (ReturnInst *R : Rets)
    if (!R->getReturnValue() || R->getReturnValue()->getType() != RetTy)
      return;
  LLVMContext &Ctx = Clone.getContext();
  BasicBlock *Merge = BasicBlock::Create(Ctx, "cqq.retmerge", &Clone);
  PHINode *Phi = PHINode::Create(RetTy, Rets.size(), "cqq.ret", Merge);
  ReturnInst::Create(Ctx, Phi, Merge);
  for (ReturnInst *R : Rets) {
    Phi->addIncoming(R->getReturnValue(), R->getParent());  // (value, block) captured
    BranchInst::Create(Merge, R);  // `br merge` before the `ret`…
    R->eraseFromParent();          // …then drop the `ret`.
  }
}

// 5po2 I1: flatten any PredMux-claimable acyclic tainted VALUE diamond in the
// rotation-free clone body into straight-line `select` muxes, BEFORE the inner
// drain / `lowerCloneSelect` / `lowerOps`. Reuses the module PredMux flattener
// (`flattenPredMuxRegions`, Rule 14) driven with the DISJOINT `cloneTaint`: it
// only claims a function whose terminator is tainted UNDER THAT set
// (PredMuxFlatten.cpp:795), so only THIS clone's diamonds flatten and every other
// function (caller, sibling clones) is left byte-untouched. One region per call +
// a scoped param-rooted re-propagate, mirroring the module driver's fixpoint
// (CQLoweringPass.cpp:155). A clone body is rotation-free (`scanBody` rejects
// cq_theta/cq_phi), so a claimed diamond is ALWAYS a value/data-mux — never a
// phase arm. After the fixpoint NO tainted control may survive: a surviving
// tainted conditional `br` is an off-pattern shape PredMux declined to claim
// (multi-exit — the I2 controlled-return shape; compound; a loop shape E2 still
// refuses — ⚠ since bd fn1q increment 3 "loop" is NOT a blanket member of this
// list: E2 admits a region strictly inside one loop body, so with `claimAll=true`
// (which bypasses the W witness) a clone body containing a loop now gets its
// in-loop diamonds FLATTENED. The verdict is unchanged — the `Clone.size() != 1`
// backstop below still declines any clone whose body does not collapse to one
// block, and round 2 measured a clone hosting an in-loop diamond emitting a gate
// stream BYTE-IDENTICAL to the oracle's, 103 calls — but the ENUMERATION was
// wrong and is corrected here rather than in a record, per CLAUDE.md L7)
// — LOUD-decline it
// source-located (Prime Directive; never a partial clone). Returns true on a
// clean flatten (or a body with no tainted control at all), false if control
// survives (the caller declines + retargets to keep the site consistent).
bool lowerCloneControl(Function &Clone, Module &M, TaintSet &ct) {
  // Capture the tainted params ONCE — they persist across every flatten erasure.
  SmallVector<Argument *, 8> TaintedParams;
  for (Argument &A : Clone.args())
    if (ct.Tainted.count(&A))
      TaintedParams.push_back(&A);

  // 5po2 I2: fold any genuine multi-EXIT `ret` control into a single-exit merge-phi
  // FIRST, so a controlled-return ladder reduces to the merge-phi diamond the
  // scoped PredMux fixpoint claims (with `claimAll` — inside a clone every acyclic
  // SESE tainted diamond must flatten). Idempotent on a single-`ret` body.
  normalizeReturnMerge(Clone);

  // bd `test_C_libtooling-woa0` — the SEVENTH `flattenPredMuxRegions` call site,
  // and it gets its OWN cross-claim record + its OWN re-ask rather than a
  // `nullptr` and an argument.
  //
  // ⚠ THE ARGUMENT FOR A `nullptr` HERE IS AVAILABLE AND IS DELIBERATELY NOT
  // TAKEN. It goes: `SpecializeReject`'s `buildIntrinsicSets` rejects any
  // candidate whose body holds a `taint.{Theta,Phase,Measure}Calls` pointer, so
  // `isCondRailLeaf` — a `cq_theta_i1` CALL — can never be true inside a clone
  // body; the only φ `isStructuralRailPhi` can match here is therefore the
  // ALL-CONSTANT `i1` one, which `convertPhis` takes down the boolean-algebra
  // path, which is not the hazard. That argument is almost certainly sound and
  // it is exactly the species CLAUDE.md's L7 says hardens into a ruling because
  // nobody rules on it — and this bead exists because a different unwritten
  // argument in the same predicate was the ground a P1 stood on. Four lines of
  // fence cost less than the next round re-deriving it.
  //
  // It also closes the OTHER half, which the argument above does not reach at
  // all: this driver runs with the DISJOINT `cloneTaint`, so it is argued never
  // to claim in a non-clone function and therefore never to convert a φ the
  // module-level record holds. Same species of argument, same disposition.
  PredMuxRailPhiRecord cloneRailPhiRec;
  while (flattenPredMuxRegions(M, ct, /*claimAll=*/true, &cloneRailPhiRec))
    reseedCloneTaintFromParams(Clone, TaintedParams, ct);
  // The re-ask, immediately after this driver's own fixpoint — the only slot
  // that can, since `specialize()` runs after `detectControlRegions` and after
  // `repropagateControlMerges`, so the module-level re-ask is long past. Loud;
  // the `false` return is what the caller's existing decline+retarget path
  // expects, and it matters only on a host whose diagnostic handler does not
  // exit (`opt`'s does — bd `br4a`).
  if (declineConvertedRailPhiLeaves(cloneRailPhiRec))
    return false;

  // PredMux replaces the merge phis with selects and rewrites the branch to an
  // UNCONDITIONAL edge into the (surviving) merge block, so a flattened diamond is
  // 2+ straight-line blocks joined by unconditional `br`s — not yet the single
  // block the Bennett wrap requires (it reads the ENTRY block's terminator as the
  // `ret`). Fold every unconditional-br chain into one block
  // (`MergeBlockIntoPredecessor` merges a block whose sole predecessor has this
  // block as its sole successor — it never touches a CONDITIONAL br, so real
  // control is preserved for the backstop). No reseed needed: folding moves
  // instructions without changing SSA identity or creating/erasing tainted values.
  bool Merged = true;
  while (Merged) {
    Merged = false;
    for (BasicBlock &BB : llvm::make_early_inc_range(Clone))
      if (&BB != &Clone.getEntryBlock() && MergeBlockIntoPredecessor(&BB))
        Merged = true;
  }

  // Rule-9 lifetime hygiene: `MergeBlockIntoPredecessor` RAUWs+erases a folded
  // block's single-incoming PHI. Were that phi tainted, its freed pointer would
  // linger in `ct.Tainted` and be carried (as a stale pointer) into every later
  // stage — the exact block-lifetime hazard class this codebase treats as
  // unforgivable. One final param-rooted reseed drops any freed pointer and
  // recovers the full live set (every clone value is param-derived). Cheap and
  // unconditional so the invariant "no stage after this reads a freed `ct` entry"
  // holds by construction, not by the fold's incidental non-reuse of the slot.
  reseedCloneTaintFromParams(Clone, TaintedParams, ct);

  // Backstop: a FULLY-flattened acyclic value region now collapses to exactly ONE
  // straight-line block. Any surviving block is unflattened control PredMux
  // declined to claim — multi-exit (the I2 controlled-return shape), a loop
  // (classical OR tainted condition — the size check catches BOTH, where a
  // tainted-only conditional-br check would miss a classical loop), or a compound
  // shape. ⚠ THIS BACKSTOP IS WHY THE LOOP HALF IS STILL SOUND after bd fn1q
  // increment 3 gave E2 an in-loop admission: PredMux may now flatten a diamond
  // INSIDE a clone's loop, but the loop itself survives, so `Clone.size() != 1`
  // still fires. It is the SIZE check that holds the line, not E2 (Rule-13 round
  // 1 F-1). Round 2 DID probe it: a clone hosting an in-loop diamond emits a
  // gate stream byte-identical to the oracle's (103 calls), and both
  // `spec_reject_clone_loop.ll` and `lowering_ctlz_idiom_reject_callee_arg_taint.ll`
  // still decline.
  //
  // LOUD-decline (Prime Directive; never a partial clone). Point at a
  // surviving conditional `br` for the best `!dbg`, else the entry terminator.
  if (Clone.size() != 1) {
    Instruction *Where = nullptr;
    for (BasicBlock &BB : Clone)
      if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator()))
        if (BI->isConditional()) {
          Where = BI;
          break;
        }
    if (!Where)
      Where = Clone.getEntryBlock().getTerminator();
    Clone.getContext().diagnose(DiagnosticInfoUnsupported(
        Clone,
        "cq specialization: callee contains tainted control flow under quantum "
        "lift",
        Where->getDebugLoc()));
    return false;
  }
  return true;
}

// Erase `V` and its forward cone of consumers that lose ALL taint once `V` is
// scrubbed (§2.7 return-taint correction for a ReturnTainted=false clone). A
// consumer that still reads an independently-tainted operand keeps its taint.
void scrubForwardCone(Value *Root, TaintSet &taint,
                      const SmallPtrSetImpl<const Value *> &TaintedSources) {
  std::vector<Value *> Worklist;
  auto scrub = [&](Value *V) {
    if (taint.Tainted.count(V))
      taint.ScrubbedByReturnTaint.emplace_back(V);  // bd l3oi: the record.
    taint.Tainted.erase(V);
    taint.BirthOrder.erase(V);
    if (auto *I = dyn_cast<Instruction>(V))
      taint.StaleDeclined.erase(I);
  };
  scrub(Root);
  Worklist.push_back(Root);
  while (!Worklist.empty()) {
    Value *V = Worklist.back();
    Worklist.pop_back();
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !taint.Tainted.count(I))
        continue;
      // A value that is its OWN taint source — a primary `cq_theta` result, or
      // another specialized-call result that legitimately carries taint — must
      // never be scrubbed transitively (its taint does NOT derive from the
      // scrubbed root). Stopping here also prunes its whole downstream cone from
      // the walk, so a fresh `cq_theta(%r, θ)` seeded from a scrubbed classical
      // `%r` keeps the qubit and every consumer of it tainted (the over-scrub
      // the Rule-13 axis-(g) probe caught). NOT `cq_phi`: it is not a source
      // (pre-3qlq a register-form one on a now-classical operand was scrubbed).
      if (TaintedSources.count(I))
        continue;
      bool HasOtherTaintedOperand = false;
      for (Value *Op : I->operands())
        if (taint.Tainted.count(Op)) {
          HasOtherTaintedOperand = true;
          break;
        }
      if (HasOtherTaintedOperand)
        continue;  // tainted via another path — keep.
      scrub(I);
      Worklist.push_back(I);
    }
  }
}

// Synthesize the void uncompute TWIN of a Bennett-wrapped clone (Phase 6.3).
// `Clone` realizes the reversible embedding `|x⟩|0⟩_out → |x⟩|f(x)⟩_out` (forward
// gates → `out = cqrt_alloc_<W>(0)` → `cqrt_copy(result, out)` → reverse → free
// scratch → `ret out`). Its adjoint, needed when `Clone` is called inside another
// clone, is the void `@<clone>_unc(i32 out, <clone params>)` that runs
// `out ^= f(x)` (recompute scratch → `cqrt_copy(result, out_param)` → reverse →
// free scratch → `ret void`): since the passed `out` already holds `f(x)`, the
// XOR-copy zeroes it, the borrowed inputs are read-only-preserved, and the
// twin's own scratch is allocated-and-freed internally. The twin is the wrapped
// `Clone` with exactly two edits — the internal `out` alloc is replaced by the
// new leading `out` parameter, and the `ret <handle>` becomes `ret void`. A
// nested clone call inside `Clone` rides along: its forward call + its own twin
// call (already emitted by `Clone`'s wrap) are cloned verbatim, so the adjoint
// composes to any depth. Only ever called for a `ReturnTainted` clone (the
// `out`-alloc is then guaranteed present, DD-3).
Function *synthUncomputeTwin(Function &Clone) {
  Module *M = Clone.getParent();
  LLVMContext &Ctx = Clone.getContext();

  SmallVector<Type *, 4> ParamTys;
  ParamTys.push_back(Clone.getReturnType());  // out: the clone's i32 return type.
  for (Argument &A : Clone.args())
    ParamTys.push_back(A.getType());
  FunctionType *FT =
      FunctionType::get(Type::getVoidTy(Ctx), ParamTys, /*isVarArg=*/false);
  Function *Twin = Function::Create(FT, GlobalValue::InternalLinkage,
                                    (Clone.getName() + "_unc").str(), M);

  // Map Clone's args → Twin's args[1..]; Twin arg0 is the new `out`.
  ValueToValueMapTy VMap;
  auto TwinArg = Twin->arg_begin();
  TwinArg->setName("out");
  ++TwinArg;
  for (Argument &A : Clone.args()) {
    TwinArg->setName(A.getName());
    VMap[&A] = &*TwinArg;
    ++TwinArg;
  }
  SmallVector<ReturnInst *, 1> Returns;
  CloneFunctionInto(Twin, &Clone, VMap,
                    CloneFunctionChangeType::LocalChangesOnly, Returns);
  // The twin inherits `Clone`'s attributes via the clone; `Clone` was already
  // stripped by `cloneFor`, but re-strip defensively (the twin is void/side-
  // effecting and must never be treated as a deletable pure call).
  stripStaleClassicalAttrs(Twin);

  // The wrapped clone returns its `out` alloc; in the twin, redirect that alloc
  // to the `out` parameter and drop it, then make the terminator `ret void`.
  ReturnInst *Ret = Returns.front();
  if (auto *OutAlloc = dyn_cast<CallInst>(Ret->getReturnValue())) {
    OutAlloc->replaceAllUsesWith(Twin->getArg(0));
    OutAlloc->eraseFromParent();
  }
  ReturnInst::Create(Ctx, /*retVal=*/nullptr, Ret);
  Ret->eraseFromParent();
  return Twin;
}

// Idempotently ensure `Clone`'s void uncompute twin exists (synthesize once,
// reuse across every outer clone that calls `Clone`). Always runs BEFORE the
// outer wrap's `emitInverseChain` mints the `@<clone>_unc` call, so the symbol
// resolves to this definition, never a dangling declaration.
void ensureTwin(Function *Clone) {
  // bd xy9n — the DUPLICATION fence, and it lives HERE rather than inside
  // `synthUncomputeTwin` for a measured reason.
  //
  // *** AN EARLIER DRAFT PUT IT IN `synthUncomputeTwin` AND THE RULE-13 DELTA ROUND
  // SHIPPED THE FULL MISCOMPILE PAST IT. *** The short-circuit below returns as soon
  // as a `<clone>_unc` DEFINITION already exists, so the fence was never reached
  // when the twin was pre-supplied — and the outer wrap then calls a forward clone
  // and an adjoint twin whose bodies each carry their OWN copy of the
  // undef-bearing computation. `opt` exit 0, verify clean, free_pairing_check
  // 4/4 verified. This is the choke point; the short-circuit is not.
  //
  // WHY THE FENCE EXISTS AT ALL: guard 1 (`declineUnpairedUndefLiterals`) counts
  // literal undef/poison SLOTS on emitted calls, so it is blind to an `undef` sitting
  // ONE classical instruction ABOVE the slot — `%c = xor i32 undef, 7` feeding
  // `cq_template_mul_i32_hl(%a, %c)` counts ZERO. Harmless anywhere else, because one
  // register is read twice with one value; but the twin is a VERBATIM COPY of the
  // clone body, so the computation is DUPLICATED and each copy reads `undef`
  // independently. Measured: forward `mul_i32_hl(h0, 73903)`, twin
  // `mul_i32_hl(h0, 7)`, deterministic across runs — the adjoint inverts a different
  // multiplier, the rail is dirty AND entangled, and the `cqrt_free` that follows is
  // a hidden measurement (Rules 6, 8).
  //
  // Do NOT instead widen guard 1 to "an argument defined by an instruction with an
  // undef operand": that over-declines every `clang -O1` dead-edge phi/select,
  // `slice_libm_ld80_nexttoward`'s whole family included, for no pairing gain.
  // Fencing at the DUPLICATION is the exact parallel of bd 7udx's fence at the ERASE.
  //
  // Rule-12 mirror, character-for-character: spec_reject_twin_undef_dup.ll (fence
  // present) and spec_reject_twin_undef_dup_pretwin.ll (the pre-supplied-twin shape
  // that pins THIS placement rather than the old one).
  if (const Instruction *Bad = findUndefOperandInBody(*Clone)) {
    Clone->getContext().diagnose(DiagnosticInfoUnsupported(
        *Clone,
        "cq literal integrity: undef/poison operand duplicated into the "
        "uncompute twin",
        Bad->getDebugLoc()));
    return;
  }
  std::string TName = (Clone->getName() + "_unc").str();
  if (Function *F = Clone->getParent()->getFunction(TName))
    if (!F->isDeclaration())
      return;
  synthUncomputeTwin(*Clone);
}

// Retarget `Site` to `Clone`. USUALLY `setCalledFunction` suffices — but when the
// clone's RETURN type differs from the call's own result type (an fp-tainted return
// rewritten to an i32 handle, bd 3c6m.54), the `CallInst`'s Value type is IMMUTABLE
// (`setCalledFunction` updates only the called operand + FunctionType), so a stale
// fp result would flow to the consumer (e.g. `cq_measure_f64` reads an fp, not an
// i32 handle). Replace the call with a fresh i32-returning one and cross-type RAUW
// the old fp result → the new i32 result (laundered by the downstream measure/op
// lowering, exactly like the theta handle RAUW). The arg operands are carried
// verbatim (a still-fp arg becomes its i32 handle later, via lowerRotations/
// lowerOps — the same transient-mismatch the plain `setCalledFunction` arg path
// already relies on). Updates `Site` in place to the live call.
void retargetSite(CallInst *&Site, Function *Clone) {
  if (Site->getType() == Clone->getReturnType()) {
    Site->setCalledFunction(Clone);
    return;
  }
  SmallVector<Value *, 8> Args(Site->args());
  IRBuilder<> B(Site);
  CallInst *NewCall = B.CreateCall(Clone, Args);
  if (DebugLoc DL = Site->getDebugLoc())
    NewCall->setDebugLoc(DL);
  Site->replaceAllUsesWith(NewCall);  // cross-type: old fp result → new i32 handle.
  NewCall->takeName(Site);
  Site->eraseFromParent();
  Site = NewCall;
}

// Forward decl — `buildClone` and `resolveSite` are mutually recursive (the
// depth-first transitive worklist).
SpecRecord buildClone(CallInst *&Site, Function *Callee, SpecMask Mask, Module &M,
                      WidthDispatch &wd, TaintSet &taint, SpecPlan &plan);

// Get-or-create the clone for `(Callee, Mask)`, retarget `Site` (updating it in
// place if the retarget rebuilt the call — see `retargetSite`), and return the
// FINALIZED record. A cache HIT reuses an existing clone (C7) — and because the
// drain is depth-first, every HIT reads a record whose `ReturnTainted` was
// finalized before the recursion returned (closing the 6.2 drain-ordering hazard
// the placeholder `ReturnTainted=false` would otherwise expose, [[6-3-drain-ordering-varargs-recheck]]).
SpecRecord resolveSite(CallInst *&Site, Function *Callee, SpecMask Mask, Module &M,
                       WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {
  SpecKey Key{Callee, Mask};
  auto It = plan.Cache.find(Key);
  if (It != plan.Cache.end()) {
    retargetSite(Site, It->second.Clone);
    return It->second;
  }
  return buildClone(Site, Callee, Mask, M, wd, taint, plan);
}

SpecRecord buildClone(CallInst *&Site, Function *Callee, SpecMask Mask, Module &M,
                      WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {
  SpecKey Key{Callee, Mask};
  Function *Clone = cloneFor(SpecCandidate{Site, Callee, Mask});
  // Insert the (incomplete) record up front so a self/dedup reference resolves.
  plan.Cache[Key] = SpecRecord{Clone, false};
  // bd l3oi F-R7-1: the specializer's own record of the clone's handle slots.
  taint.SpecHandleArgMask[Clone] = Mask;

  TaintSet cloneTaint = seedClone(Clone, Mask);

  // fp-ABI param HandleWidth (bd 3c6m.54): a tainted fp param rewritten to i32 in
  // `cloneFor` carries an fp logical width the clone body needs when a CAST reads
  // it directly (`getSrcTy()` reads the laundered i32; the width is recovered from
  // `HandleWidth`, exactly the theta-handle mechanism RotationLowering uses). Record
  // it here so `lowerOps` on the clone body resolves `fptrunc`/`bitcast fp<->i80`/…
  // off an fp param to the correct `cq_template_<op>_f<W>_...` rather than declining.
  for (unsigned i = 0, n = Callee->arg_size(); i < n; ++i) {
    StringRef OrigW = abiWidthFromType(Callee->getArg(i)->getType());
    if (Clone->getArg(i)->getType()->isIntegerTy(32) &&
        abiWidthHasReversibleFpCopy(OrigW))
      cloneTaint.HandleWidth[Clone->getArg(i)] = OrigW;
  }

  // 5po2 I1: flatten a PredMux-claimable tainted VALUE diamond in the clone body
  // to straight-line selects FIRST — before the inner drain, `lowerCloneSelect`,
  // and `lowerOps` all see a flattened straight-line body. An off-pattern control
  // shape (multi-exit / loop / non-claimable) LOUD-declines here; retarget the
  // site (keeping it consistent so no secondary crash precedes the DS_Error) and
  // return — `opt` exits non-zero on the diagnostic and the module is rejected.
  if (!lowerCloneControl(*Clone, M, cloneTaint)) {
    plan.Cache[Key].ReturnTainted = false;
    retargetSite(Site, Clone);
    return SpecRecord{Clone, false};
  }

  // Depth-first transitive worklist (3.3): specialize each inner tainted-arg call
  // INSIDE this clone — and synthesize its uncompute twin — BEFORE this clone's
  // own data lowering, stream capture, and Bennett wrap. So the inner retargeted
  // call is an ordinary handle op in this clone's forward stream, and its twin is
  // already defined when the wrap reverses it. Each level lowers under its OWN
  // disjoint `cloneTaint` (C-Taint), so no gate is double-adjointed (3.6).
  SmallPtrSet<CallInst *, 4> TaintedCloneCalls;
  SmallVector<CallInst *, 4> InnerCalls;  // snapshot before mutation
  for (BasicBlock &BB : *Clone)
    for (Instruction &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I))
        InnerCalls.push_back(CI);
  for (CallInst *Inner : InnerCalls) {
    Function *InnerCallee = Inner->getCalledFunction();
    if (!InnerCallee)
      continue;  // indirect call with classical args — left as a classical subcall.
    // A curated reversible llvm.* idiom intrinsic (Phase 7.1-E) is a tainted
    // DATA OP lowered IN PLACE by the `lowerOps(M, …)` below (to a
    // `cq_template_<op>_<W>` producer the wrap then captures via
    // `isForwardTemplate`), NEVER a nested specialization candidate. Its callee
    // is an llvm INTRINSIC DECLARATION with no body, so it must be skipped here
    // BEFORE `classifyCandidate`/`scanBody` — those require a visible definition
    // (`!isDeclaration()`, see the SpecializeReject.h contract) and would
    // dereference a null entry block on the bodiless intrinsic. This is the FIRST
    // place a declaration-callee inner call can appear: pre-7.1-E-follow-up,
    // `scanBody` rejected any body containing a declaration-only call, so the
    // clone never held one; now that detection accepts a curated intrinsic in the
    // body, this loop must mirror that — lower it in place, do not recurse.
    // [[7-1-E-intrinsics-frozen-clearance]]
    if (isCuratedReversibleIntrinsic(Inner))
      continue;
    // p119: a DIRECT-libm call in a clone body is a LIBRARY function (removed from
    // recognition). It has no visible body, so it falls through to the loud
    // declaration-only "nested call" decline below — the correct outcome (it must
    // be source-injected to lower, never recognized by name).
    // The inner's taint mask is read from THIS clone's seeded `cloneTaint`, after
    // any earlier sibling's classical-result scrub (process in program order so a
    // downstream inner sees the corrected taint).
    SpecMask InnerMask = taintArgMask(Inner, cloneTaint);
    if (InnerMask == 0)
      continue;  // all-classical args — an ordinary classical subcall, not lifted.

    // Classify with the inner's REAL mask (the per-Site ABI + a re-walk of the
    // body/cycle). A non-Accept inner is a LOUD decline at its offending
    // instruction (opt exits non-zero, the module is rejected) — never a silent
    // un-retargeted handle call (Prime Directive).
    SpecCandidate InnerCand{Inner, InnerCallee, InnerMask};
    Instruction *Where = nullptr;
    std::string Kind;
    SpecReject Why = classifyCandidate(InnerCand, taint, wd, Where, Kind);
    if (Why != SpecReject::Accept) {
      diagnoseReject(Where, Why, Kind);
      continue;
    }

    CallInst *OldInner = Inner;
    StringRef InnerOrigW = abiWidthFromType(Inner->getType());  // pre-rebuild width.
    SpecRecord Rec =
        resolveSite(Inner, InnerCallee, InnerMask, M, wd, taint, plan);
    // fp-ABI intra-clone taint migration (bd 3c6m.54): if retargeting REBUILT the
    // inner call (an fp-tainted return rewritten to an i32 handle), the fresh
    // `CallInst` is a NEW value absent from THIS outer clone's `cloneTaint` —
    // `seedClone` tainted the OLD, now-erased call. Without migration the outer
    // body's ops read the inner result as UNTAINTED, so `ArithLowering` picks the
    // wrong template shape (an i32 handle lands in an fp literal slot → a broken
    // module, the Rule-13 finding). Mirror the module-level re-seed `specialize`
    // does for a top-level rebuilt result: register the new call as a tainted i32
    // handle and record its fp logical width in `HandleWidth` so a later outer
    // op/cast off it resolves the right `cq_template_*_f<W>`. The integer path
    // never rebuilds (`setCalledFunction` keeps the pointer), so this is inert
    // there.
    //
    // ⚠ TWO STATEMENTS WERE DELETED HERE, AND WHY (bd 8e5r, Rule-13 r1A F-EA-7):
    //   * `cloneTaint.Tainted.erase(OldInner)` — `OldInner` was already
    //     `eraseFromParent`'d inside `retargetSite`, so this erased by a DEAD
    //     pointer. `cloneTaint.Tainted` is self-cleaning (`ScrubOnDelete.h`): the
    //     key was dropped at the deletion itself, so the erase is redundant — and
    //     it was a latent HAZARD, because an erase by a dead address removes
    //     whatever LIVE object has since been revived at that address (safe only
    //     while nothing allocates between `retargetSite`'s erase and here; the
    //     r1B F-EB-9 shape).
    //   * the `BirthOrder` migration of `OldInner` onto `Inner` — DEAD BY
    //     CONSTRUCTION, on every binary: `cloneTaint.BirthOrder` is written only
    //     by `lowerCloneSelect` / `lowerQramReads` / `lowerOps`, all of which run
    //     AFTER this loop, so it never holds an inner call here (r1A's I1 logged
    //     no lookup hit at it on the corpus). A lookup MOVED before the erase would
    //     be dead too, so it is deleted rather than moved; the stream is unchanged
    //     by construction (and measured: corpus A/B, TRACK_8E5R.md §13).
    if (Inner != OldInner) {
      cloneTaint.Tainted.insert(Inner);
      if (Rec.ReturnTainted && abiWidthHasReversibleFpCopy(InnerOrigW))
        cloneTaint.HandleWidth[Inner] = InnerOrigW;
    }
    if (Rec.ReturnTainted) {
      // A quantum-handle result, entangled with the borrowed inputs: the outer
      // wrap MUST uncompute it (via the twin) before freeing it, else freeing a
      // dirty rail collapses the caller's qubit (Rule 6/8). Include it in the
      // forward stream and guarantee the twin exists.
      ensureTwin(Rec.Clone);
      // bd l3oi F-R7-1: the twin's handle slots — `out` (arg 0) + the clone's.
      if (Function *Twin = M.getFunction((Rec.Clone->getName() + "_unc").str()))
        taint.SpecHandleArgMask[Twin] = (InnerMask << 1) | 1;
      TaintedCloneCalls.insert(Inner);
    } else {
      // A classical-derived result (inner restored its own borrowed inputs and
      // left no quantum output): scrub it and its now-classical cone from
      // `cloneTaint` so its consumers stay classical (intra-clone §2.7). Roots
      // that must never be scrubbed: this clone's seeded params and any
      // already-tainted inner clone-call result.
      SmallPtrSet<const Value *, 8> Roots;
      for (Argument &A : Clone->args())
        if (cloneTaint.Tainted.count(&A))
          Roots.insert(&A);
      for (CallInst *T : TaintedCloneCalls)
        Roots.insert(T);
      scrubForwardCone(Inner, cloneTaint, Roots);
    }
  }

  // bd `test_C_libtooling-vsfp` round 2 — THE SPECIALIZER'S DEAD-SLOT RECORD,
  // taken with the pass's ONE liveness predicate (`DeadValueLiveness.h`) on the
  // clone body as it is HERE: control flattened (`lowerCloneControl`), inner
  // tainted-arg calls retargeted to their own clones (whose records this
  // predicate's call-slot rule already consults), and every read still a STOCK
  // OPCODE. Not later: `lowerCloneSelect`/`lowerOps` turn reads into runtime
  // calls, which are roots, and would make every parameter live. A slot recorded
  // here is one no LIVE ROOT of the clone reads — and, since bd vsfp round 4 (bd
  // sqjq), one whose VALUE the built clone never observes, because the dead cone
  // below is deleted right after the record (⚠ round 3 wrote "never reads" of the
  // record alone, and a dead-but-lowered op on the slot falsified it, r3A F-XA-2).
  // ⚠ Since bd `nlfd` the parameter may still be an OPERAND: forwarded as-is into
  // an inner clone's unread scalar slot that the rewrite may not null
  // (`isUnreadScalarSlot`) — passed along, never read. It is the question the
  // phantom-read resolution, M-C arm (d0) and M-A ask (by CALLING
  // `isRecordedDeadSlot` / `isRewritableDeadSlot`). A dead
  // parameter that reaches this point at all is one the dead-argument drop could
  // not predict from the ORIGINAL callee (the clone's own flatten removed its
  // last read — e.g. a condition-only use of an empty diamond — or a drop
  // precondition refused the slot).
  const FunctionLiveness Existence(*Clone, taint);
  const uint64_t DeadSlots = deadParamMask(*Clone, Existence);
  taint.SpecDeadArgMask[Clone] = DeadSlots;
  // bd `test_C_libtooling-vaep` (Rule-13 r1A F-r1A-1): strip the value constraints
  // of every recorded-dead parameter HERE, at the clone's own record — before any
  // SYNTHESIZED `_unc` twin of it exists (`ensureTwin` runs in the ENCLOSING clone's
  // inner-call loop after this build returns), so every synthesized twin copies the
  // stripped set. ⚠ NOT a pre-supplied twin (Rule-13 r2 F-r2-3): `ensureTwin`
  // short-circuits on an existing `<clone>_unc` DEFINITION and uses it verbatim, so
  // its parameters keep whatever `range`/`nofpclass` the input gave them (measured:
  // r2 `probes/pt_pretwin.ll` receives `i32 0` into `noundef range(i32 1, 100)`, on
  // `main` and here alike). The attribute is the least of it — a pre-supplied twin
  // with a wrong body is used as the adjoint unchecked: bd `test_C_libtooling-9oob`
  // (P1, PRE-EXISTING); strip or refuse it there, not here. A caller's null
  // (neutralised at module level, inherited by an inner call, or forwarded through a
  // dead parameter) reaches the forward clone AND its twin; before this, the twin
  // kept `noundef range(…)` / `nofpclass(…)` on the slot the null arrived in.
  for (Argument &Arg : Clone->args())
    if (Arg.getArgNo() < 64 && ((DeadSlots >> Arg.getArgNo()) & 1))
      stripParamValueConstraints(*Clone, Arg.getArgNo());
  // bd `test_C_libtooling-nlfd` (vsfp Rule-13 r6 F-R6-1) — THE RULE OF
  // `resolvePhantomCloneArgReads` step 1, ONE CLONE LEVEL DOWN. A HANDLE parameter
  // (`Mask`) that the record calls LIVE only because a surviving INSTRUCTION feeds
  // an unread scalar slot the rewrite may not null (a recorded-dead inner slot with
  // an attribute outside `nullSafeSlot`'s allowlist) is kept alive by a
  // computation whose result nothing observes — `SlotReads::Value` calls it dead.
  // Its caller's slot then stays a phantom read, and it cannot be neutralised either:
  // the surviving instruction would then be lowered on runtime handle 0 (bd sqjq's
  // hazard). On `main` 9a230646, for a DERIVED caller operand (`p = q*3`), the
  // phantom read was bd tzfa's wrong unitary (the module-level spine saw an extra
  // consumer of `p`'s rail) and neither accept was the twin's; for a `cq_theta` SOURCE
  // operand the keep-the-slot accept already was the twin's unitary (Rule-13 r1A
  // F-r1A-2, bd `test_C_libtooling-w109`). ⚠ SINCE bd rhk5 (9ad22639) THE PREMISE IS
  // FALSE FOR EVERY MEMBER MEASURED (bd `test_C_libtooling-ur72`): the spine now
  // discharges a derived chain whose rail a clone call only reads, so the keep-the-slot
  // accept is the twin's circuit plus an identity compute/uncompute pair on a scratch
  // rail (2b clean) for the derived operands too — this fence is an IR-only
  // OVER-DECLINE of programs `main` compiles correctly, kept pending the owner's
  // decision on bd ur72 / bd uyhx (a clone is shared by every caller of its
  // `(callee, mask)` and cannot see its callers' operands, so it cannot be narrowed to
  // the harmful members from here). It DECLINES with the module-level string. IR-only as measured: clang-19 `-O1` puts only allowlisted
  // attributes on an int/fp parameter that CAN BE RECORDED DEAD (it does infer
  // `returned` on a returned — hence live — parameter; r1A F-r1A-3). An ARGUMENT
  // forwarded into such a slot needs no fence: the liveness call-slot rule does not
  // count it (`isUnreadScalarSlot`), the record calls the parameter dead, and the
  // caller's null-safe slot is neutralised (value constraints stripped above).
  // RETIREMENT TRIGGER (L8): the day `nullSafeSlot` admits string/unknown attributes
  // (owner question bd `test_C_libtooling-uyhx`), this fence and step 1's decline
  // both shrink to what is left outside it.
  if (const uint64_t HandleLive = Mask & ~DeadSlots) {
    const FunctionLiveness Value(*Clone, taint, SlotReads::Value);
    if (deadParamMask(*Clone, Value) & HandleLive) {
      // Only the diagnostic's LOCATION (the verdict is decided above): the first call
      // with an argument operand live under Existence and dead under Value — the
      // frontier where the SAME two answers diverge (r1A F-r1A-4: the first spelling
      // re-derived the slot predicate here, a second spelling of the condition).
      DebugLoc Where;
      for (Instruction &I : instructions(*Clone))
        if (auto *CB = dyn_cast<CallBase>(&I); CB && !Where)
          for (const Use &U : CB->args())
            if (Existence.isLive(U.get()) && !Value.isLive(U.get())) {
              Where = CB->getDebugLoc();
              break;
            }
      Clone->getContext().diagnose(
          DiagnosticInfoUnsupported(*Clone, kMsgPhantomArgRead, Where));
      plan.Cache[Key].ReturnTainted = false;
      retargetSite(Site, Clone);
      return SpecRecord{Clone, false};
    }
  }
  // …AND MAKE THE RECORD EXACT FOR THE BUILT CLONE (bd `test_C_libtooling-sqjq`,
  // Rule-13 r3A F-XA-2). "Dead" means no live root reads the parameter — not that
  // no instruction does. A dead instruction still standing here (the chain of a
  // compare the clone's own flatten deleted, `t = a*3; if (t > 3) {}`; or `a+1`
  // passed into an inner clone's dead slot) would be lowered by `lowerOps` below
  // and so READ the parameter at run time — and once `resolvePhantomCloneArgReads`
  // neutralises the caller's slot to `0`, that read addresses runtime handle h0, a
  // register the caller never passed (at the wrong width when h0 is a `_Bool`).
  // Delete that dead cone now, with the same predicate that took the record: the
  // parameter's value is then genuinely unobserved (its only remaining uses are
  // inner unread scalar slots, bd `nlfd`), and an inner clone call inherits the dead
  // slot (its operand becomes a constant, `deleteDeadCones` step 3). Deleting
  // rather than recording later (after `lowerOps`) keeps the record on the
  // stock-opcode body, where every read is still visible as a stock use. The clone
  // is ONE BLOCK here (`lowerCloneControl`'s backstop), so `deleteDeadCones`' arm
  // fold cannot fire and no tainted value is created: the call deletes dead
  // instructions, whose `cloneTaint` keys self-scrub (`ScrubOnDelete.h`), none of
  // them in `TaintedCloneCalls` (a clone call is a liveness root), and REWRITES a
  // live inner call's rewritable dead-slot operand to a constant (step 3 — a
  // shrink, never a growth; r4A F-YA-3 corrected "only deletes").
  if (DeadSlots) {
    SmallVector<Value *, 8> DeadUsers;
    for (Argument &Arg : Clone->args())
      if (Arg.getArgNo() < 64 && ((DeadSlots >> Arg.getArgNo()) & 1))
        for (User *U : Arg.users())
          if (isa<Instruction>(U))
            DeadUsers.push_back(U);
    if (!DeadUsers.empty())
      deleteDeadCones(*Clone, DeadUsers, taint, "clone-dead-slot");
    // A dead PARAMETER passed straight into an inner clone call's dead slot (the
    // instruction case is `deleteDeadCones` step 3): the inner call inherits it.
    // A slot the rewrite may NOT null (bd `nlfd`: an unread scalar slot outside
    // `nullSafeSlot`'s allowlist — the only other way a dead parameter can still
    // have a use, see `isUnreadScalarSlot`) keeps the parameter as its operand; the
    // caller's neutralised `0` reaches it through the parameter, so the two value
    // constraints a null can violate are stripped there too — the CALL-SITE half
    // matters (the inner callee's parameter, and so its `_unc` twin, was already
    // stripped at the inner clone's own record, bd `vaep`).
    for (Argument &Arg : Clone->args())
      if (Arg.getArgNo() < 64 && ((DeadSlots >> Arg.getArgNo()) & 1))
        for (Use &U : make_early_inc_range(Arg.uses()))
          if (!rewriteRecordedDeadSlotUse(U, taint))
            if (auto *CB = dyn_cast<CallBase>(U.getUser());
                CB && CB->isArgOperand(&U) &&
                isUnreadScalarSlot(*CB, CB->getArgOperandNo(&U), taint))
              stripUnreadSlotValueConstraints(*CB, CB->getArgOperandNo(&U));
  }

  // 5po2: lift any LIFTABLE tainted `select` in the clone body to a 4.4
  // controlled-XOR copy BEFORE `lowerOps` — so the fresh `cq_template_icmp` flag
  // mint is an ordinary data template the wrap captures/reverses, and the stock
  // `icmp` feeding the select is consumed before `lowerOps` would lower a dead
  // compare. `SelectCopyOps` (the void controlled copies) and `SelectOutRails`
  // (the out allocs) steer the Bennett capture below.
  SmallPtrSet<CallInst *, 4> SelectCopyOps;
  SmallPtrSet<Value *, 4> SelectOutRails;
  // kmdc: the fp two-arm select's ¬flag `cqrt_x` brackets — ForwardStream-only
  // reverse-only ops the Bennett reverse must re-play (they mint no rail). Held
  // separately because `isForwardTemplate` matches only `cq_template_` names, so
  // without this set the reverse would DROP them → dirty out-rail / hidden measure.
  SmallPtrSet<CallInst *, 4> SelectXBrackets;
  // 5po2 I2: the compound-condition network's `cqrt_toffoli`/`cqrt_cnot` conjunction
  // mints — ForwardStream-only reverse-only ops (self-inverse; their i1 ancilla
  // allocs land in `SelectOutRails` as ScratchRails). Same NON-`cq_template_` reason
  // as `SelectXBrackets`: without this set the Bennett reverse drops them → a dirty
  // ancilla free (Rule 6) / a wrong-flag replay of the copies.
  SmallPtrSet<CallInst *, 4> SelectNodeMints;
  lowerCloneSelect(*Clone, cloneTaint, wd, SelectCopyOps, SelectOutRails,
                   SelectXBrackets, SelectNodeMints);

  // 5po2 I1 over-accept backstop: after select lowering NO tainted `select` may
  // survive. A PredMux-flattened mux at an unsupported width / off-shape that
  // `lowerCloneSelect` could not lower (it `continue`s past an unrecognized shape)
  // would otherwise reach the Bennett wrap as a raw select — a broken / verify-
  // dirty clone. LOUD-decline it source-located (Prime Directive; retarget to keep
  // the site consistent before the DS_Error exits opt non-zero).
  for (BasicBlock &BB : *Clone)
    for (Instruction &I : BB)
      if (auto *SI = dyn_cast<SelectInst>(&I))
        if (cloneTaint.Tainted.count(SI)) {
          Clone->getContext().diagnose(DiagnosticInfoUnsupported(
              *Clone,
              "cq specialization: callee contains tainted control flow under "
              "quantum lift",
              SI->getDebugLoc()));
          plan.Cache[Key].ReturnTainted = false;
          retargetSite(Site, Clone);
          return SpecRecord{Clone, false};
        }

  // bd 20xt.4: lower any const-global tainted-index QROM read in the clone body to
  // `cqrt_qram_alloc_<W>` (array-handle birth, at the clone entry) + `cqrt_qram_load
  // _<W>` (Toffoli copy-out). The module-level `lowerQramReads` (CQLoweringPass) ran
  // BEFORE `specialize`, so the clone (created just now) still holds raw gep+loads;
  // lower them HERE, scoped by `cloneTaint` (only the clone's tainted-index reads
  // match — every other function's reads are already lowered or untainted here), and
  // BEFORE `lowerOps` so the load result is an i32 handle when its arith consumers
  // lower. `inBennettClone=true` skips the top-level coherent-return no-cloning
  // fence: the Bennett wrap below copies the return out to a fresh basis rail and
  // uncomputes the WHOLE forward stream (the qram load `_unc` AND the index), so the
  // escape is sound (Bennett) — the fence is vacuous in a clone. The lowered load
  // result joins `cloneTaint` (a reversible producer the wrap captures); the array
  // handle is a CLASSICAL resource token (never tainted, never captured/freed).
  lowerQramReads(M, wd, cloneTaint, /*inBennettClone=*/true);

  // Scoped data lowering: `lowerOps` walks all of `M` but lowers only the
  // instructions in `cloneTaint` (C25). Inner clone calls are not stock opcodes,
  // so they are untouched; already-lowered sibling clones are in disjoint
  // `cloneTaint`s, so they are untouched too.
  // `inBennettClone=true` (bd test_C_libtooling-6uqc Inc 2a): the M-C in-place
  // reassignment must NOT fire inside a clone body. The wrap below captures the
  // forward stream by SCANNING for `isForwardTemplate`/clone-call/select-op
  // members, and a void `cqrt_addc_<W>` is none of them — it would be silently
  // omitted from `ForwardStream`, never reversed, and would leave a BORROWED
  // clone argument permanently shifted, breaking `|x>|0> -> |x>|f(x)>` for every
  // caller AND the synthesized `_unc` twin. Out-of-place inside a clone is
  // correct and is what ships today.
  lowerOps(M, wd, cloneTaint, /*inBennettClone=*/true);

  // Capture the forward stream + scratch rails in program order: data templates
  // AND the `ReturnTainted` inner clone calls (each a reversible rail the wrap
  // reverses via its twin and frees). 5po2 adds two off-1:1 kinds: a controlled
  // copy (`SelectCopyOps`) is a REVERSE-ONLY forward op (played self-inverse to
  // zero the out rail, mints no rail → ForwardStream only), and the select out
  // alloc (`SelectOutRails`) is a rail to FREE but not a forward op (zeroed by
  // that copy's reverse → ScratchRails only).
  SmallVector<CallInst *, 8> ForwardStream;
  SmallVector<Value *, 8> ScratchRails;
  for (BasicBlock &BB : *Clone)
    for (Instruction &I : BB)
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (isForwardTemplate(CI) || TaintedCloneCalls.count(CI) ||
            isForwardQramLoad(CI)) {
          // bd 20xt.4: a `cqrt_qram_load_<W>` joins the data-template/inner-clone
          // family — a reversible producer the wrap reverses (its `_unc`) then frees
          // (the value rail). Its array-handle `cqrt_qram_alloc_<W>` is neither
          // `isForwardTemplate` nor a select op, so it is naturally EXCLUDED here
          // (a classical resource token — never reversed or freed).
          ForwardStream.push_back(CI);
          ScratchRails.push_back(CI);
        } else if (SelectCopyOps.count(CI) || SelectXBrackets.count(CI) ||
                   SelectNodeMints.count(CI)) {
          // A controlled copy, an fp-select ¬flag `cqrt_x` bracket, OR (5po2 I2) a
          // compound-condition `cqrt_toffoli`/`cqrt_cnot` network mint: reverse-only
          // (self-inverse, mints no rail) → ForwardStream, never ScratchRails.
          ForwardStream.push_back(CI);
        } else if (SelectOutRails.count(CI)) {
          // The select out rail AND (5po2 I2) the i1 network ancilla allocs: a rail
          // to FREE, zeroed by the reverse (the copy/node adjoint) → ScratchRails.
          ScratchRails.push_back(CI);
        }
      }

  auto *Ret = dyn_cast<ReturnInst>(Clone->getEntryBlock().getTerminator());
  Value *RV = Ret ? Ret->getReturnValue() : nullptr;
  bool ReturnTainted = RV && cloneTaint.Tainted.count(RV);
  Value *ResultRail = ReturnTainted ? RV : nullptr;
  // The copy-out width is the ORIGINAL callee return width (e.g. "f80"), NOT the
  // clone's declared return type: a tainted fp return had its clone signature
  // rewritten to i32 in `cloneFor`, so `Clone->getReturnType()` is i32, but the
  // ResultRail is an fp-width quantum value that must copy out via `cqrt_copy_f<W>`
  // (bd 3c6m.54). For an int/void return this equals the clone's own width.
  StringRef RetW = abiWidthFromType(Callee->getReturnType());

  // fp-ABI mispredict guard (bd 3c6m.54): `cloneFor` rewrote a reversible-fp
  // return to an i32 handle ONLY when `predictReturnTainted` (a sound over-approx)
  // said tainted. The single gap is a `predict==true`/`actual==false` mispredict —
  // an inner tainted-arg clone that returns classical, feeding the whole return
  // (unreachable in the always-inlined census cells: no inner calls). Then the
  // clone declares i32 but the return value is a classical fp — a broken module.
  // Decline LOUDLY, source-located, before any copy-out emission — never a silent
  // miscompile (and, absent this guard, LLVM's own verifier rejects the mistyped
  // `ret`; this house decline is the Rule-1 loud-and-located form). Over-decline
  // is safe (Prime Directive): a classical-fp-return-with-fp-args clone is outside
  // the shipped target shape.
  if (!ReturnTainted && Clone->getReturnType()->isIntegerTy(32) &&
      abiWidthHasReversibleFpCopy(RetW)) {
    Clone->getContext().diagnose(DiagnosticInfoUnsupported(
        *Clone,
        "cq specialization: floating-point return-taint could not be proven "
        "under quantum lift",
        Ret ? Ret->getDebugLoc() : DebugLoc()));
    // Retarget (keeping the call-site consistent so no SECONDARY crash precedes
    // the DS_Error) and return; opt exits non-zero on the diagnostic and the
    // module is rejected regardless of the clone's transient (broken `ret`) state.
    plan.Cache[Key].ReturnTainted = ReturnTainted;
    retargetSite(Site, Clone);
    return SpecRecord{Clone, ReturnTainted};
  }

  // 5po2 I2 SYMMETRIC fp-ABI mispredict guard (predict-FALSE / actual-TRUE, the
  // Rule-13 CONFIRMED-finding backstop): a tainted-controlled return that
  // `predictReturnTainted` UNDER-predicted classical (so `cloneFor` kept the fp
  // return type) but `lowerCloneSelect` DID mint a tainted i32 out rail — the clone
  // declares an fp return yet `emitBennettWrap` would set `ret i32` (a mistyped,
  // broken module, exit 134, NO house diagnostic). The `predictReturnTainted`
  // tainted-terminator over-approximation now precludes this (any tainted diamond →
  // predict true → i32 signature), so this is defense-in-depth: decline LOUDLY,
  // never emit a broken `ret`. Over-decline safe (Prime Directive).
  if (ReturnTainted && !Clone->getReturnType()->isIntegerTy(32) &&
      abiWidthHasReversibleFpCopy(abiWidthFromType(Clone->getReturnType()))) {
    Clone->getContext().diagnose(DiagnosticInfoUnsupported(
        *Clone,
        "cq specialization: floating-point return-taint could not be proven "
        "under quantum lift",
        Ret ? Ret->getDebugLoc() : DebugLoc()));
    plan.Cache[Key].ReturnTainted = ReturnTainted;
    retargetSite(Site, Clone);
    return SpecRecord{Clone, ReturnTainted};
  }

  emitBennettWrap(*Clone, ForwardStream, ResultRail, ScratchRails, RetW, wd,
                  cloneTaint);

  // Finalize the record BEFORE returning — any later cache HIT (sibling or outer)
  // must read the true `ReturnTainted`, never the up-front placeholder.
  plan.Cache[Key].ReturnTainted = ReturnTainted;
  retargetSite(Site, Clone);
  // The rebuilt fp result's HandleWidth is recorded by the CALLER (the drain loop
  // for an inner call, into `cloneTaint`; `specialize` for a top-level call, into
  // module `taint` — covering the cache-hit path too), where the correct taint set
  // and the pre-retarget fp width are in scope. Not here: `buildClone`'s `taint` is
  // always the MODULE taint, wrong for an inner call.
  return SpecRecord{Clone, ReturnTainted};
}

}  // namespace

bool shouldSpecialize(const CallInst *CI, const SpecPlan &plan) {
  for (const SpecCandidate &C : plan.Pending)
    if (C.Site == CI)
      return true;
  return false;
}

// (`kMsgPhantomArgRead` is defined at the top of this file since bd `nlfd`:
// `buildClone` asks it too.)

// bd `test_C_libtooling-cepm` — the check on the propagation-time classical
// prediction (`specialize()`); see there.
static constexpr char kMsgPredictedClassicalQuantum[] =
    "cq specialization: lifted callee returns a quantum register where "
    "propagation predicted a classical result";

namespace {

// Is `V` a caller-side QUANTUM value at this slot: tainted, or a rail a control
// emitter minted and recorded (the round-1 and round-2 `%out` rails are in
// `Tainted` too — r1B measured it; the rail sets are asked as well so the answer
// does not depend on that).
bool isQuantumCallerValue(const Value *V, const TaintSet &taint) {
  Value *NV = const_cast<Value *>(V);
  return taint.Tainted.count(NV) || taint.ControlOwnedRails.count(NV) ||
         taint.UntaintedMergeRails.count(NV) || taint.OutputRails.count(NV);
}

bool isRuntimeCall(const CallBase &CB) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cqrt_") || N.starts_with("cq_template_");
}

// Is use `U` the DESTINATION operand of a basis copy — the one slot a control
// emitter writes while it BUILDS its own `%out` rail? `cqrt_copy_<W>(src, dst)`
// and `cqrt_copy_<W>_controlled(ctl, src, dst)` both write their LAST argument
// and read every other one (`tools/free_pairing_check.py`'s `classify()`:
// `writes=(1,)` / `writes=(2,)`). bd `test_C_libtooling-xh17` (Rule-13 r3A
// F-XA-3): round 3 skipped EVERY runtime call on an emitter rail as
// "construction", so a 4.4 `%out` read in the SOURCE slot of a later select's
// controlled copy counted as unread and a correct program declined (the oracle
// compiles it trace-identical to its twin).
//
// ⚠ RETIREMENT TRIGGER (L8; bd vsfp Rule-13 r4A F-YA-3). The test is NAME-keyed
// (`cqrt_copy_` + the last argument) and sound by ENUMERATION: every emitter rail
// that exists when `resolvePhantomCloneArgReads` asks is built by
// `cqrt_copy_<W>[_controlled]` with the destination last (`SelectMergeEmit`,
// `ClassicalCallArmEmit`, `SwitchValueEmit`'s preload and controlled copies,
// `SwitchDataMuxEmit`, the `IOSinkLowering` value mux); `BreakReversePlay`'s copies
// are minted later, and the tape-write / abort-park `OutputRails` have no users.
// The day an emitter builds a user-visible rail with `cqrt_cswap` / `cqrt_cnot` /
// `cqrt_toffoli` / `cqrt_x` (or a copy whose destination is not last) BEFORE this
// point, that traffic will read as a REAL read of the rail and a phantom-only rail
// will be accepted: widen this test to that emitter's write slots IN THE SAME CHANGE.
bool isCopyDestination(const Use &U) {
  const auto *CB = dyn_cast<CallBase>(U.getUser());
  if (!CB || !CB->isArgOperand(&U))
    return false;
  const Function *Callee = CB->getCalledFunction();
  if (!Callee || !Callee->getName().starts_with("cqrt_copy_"))
    return false;
  return CB->getArgOperandNo(&U) + 1 == CB->arg_size();
}

// Does the USER PROGRAM read `V` — i.e. does the hand-inlined twin compute `V`
// too? Asked AFTER every recorded-dead slot was neutralised, so no phantom read
// is left among `V`'s uses. Asked positively (Prime Directive direction: a use we
// cannot name as a reader is NOT one, so the answer errs toward declining).
// A READER is: a front-end `cq_measure`, or a `cq_theta` taking `V` as arg-0 (by
// membership — the user reads it); a READ slot of a clone call; a `ret`; any
// control-emitted runtime call that READS `V` (a compare a tainted condition
// mints, or the SOURCE/control slot of a controlled copy — the twin has the same
// emitter calls, because the user wrote the same regions); or a LIVE instruction
// under the liveness predicate. ⚠ NOT a reader: the DESTINATION slot of a basis
// copy (`isCopyDestination`), which is how an emitter builds its own `%out`. That
// slot-exact rule replaced round 3's "every runtime call on an emitter rail is
// construction", which declined a `%out` read by a later select's copy (bd
// `xh17`).
// ⚠ THE ROUND-2 VERSION OF THIS PREDICATE WAS UNSOUND AS AN ACCEPT (bd tzfa; bd
// vsfp Rule-13 r2B F-WB-1): it asked "is `V` live for a reason of its own?" while
// the phantom read was still IN the use list, and a live `V` was accepted with the
// phantom read left in place — the uncompute spine then saw an extra CONSUMER of
// `V`'s template rail and did not discharge it (r2B `k19`: `h1 = 3q` never
// uncomputed, `q` fully dephased across the phase oracle). It is only sound now
// because the phantom read is GONE before the question is asked.
bool userProgramReads(const Value *V, const FunctionLiveness &L,
                      const TaintSet &taint) {
  for (const Use &U : V->uses()) {
    const auto *UI = dyn_cast<Instruction>(U.getUser());
    if (!UI)
      continue;  // not a reader we can name.
    if (const auto *CB = dyn_cast<CallBase>(UI)) {
      if (const auto *CI = dyn_cast<CallInst>(CB)) {
        if (taint.MeasureCalls.contains(CI))
          return true;
        if (taint.ThetaCalls.contains(CI) && CI->arg_size() >= 1 &&
            CI->getArgOperand(0) == V)
          return true;
      }
      if (const Function *Callee = CB->getCalledFunction())
        if (taint.SpecHandleArgMask.count(Callee))
          return true;  // a READ slot of a clone (dead slots were neutralised).
      if (isRuntimeCall(*CB)) {
        if (isCopyDestination(U))
          continue;  // an emitter building its own rail: construction.
        return true;  // any other runtime slot reads `V`.
      }
    }
    if (isa<ReturnInst>(UI))
      return true;
    if (L.isLive(UI))
      return true;
  }
  return false;
}

}  // namespace

bool resolvePhantomCloneArgReads(Module &M, const TaintSet &taint) {
  // 1. NEUTRALISE. Every recorded-dead slot of every call to a clone in a
  //    non-clone function that is NULL-SAFE (an int/fp scalar with allowlisted
  //    attributes — `nullSafeSlot`; never the drop's POLICY, bd `w7nm` — whose
  //    `musttail` refusal bd ev3m has since retired)
  //    gets a null constant with the `range`/`nofpclass` strip, asked with the SAME predicate's record
  //    (`isRecordedDeadSlot`). ⚠ Round 4 said "exactly the drop's rewrite" and
  //    applied none of the drop's eligibility — it nulled pointer and `byval`
  //    slots (bd `91k9`, r4A F-YA-1); an ineligible slot is now left in place, and
  //    declined when its operand is quantum. From here on no stage — the uncompute spine's
  //    terminal selection and free points, M-C, M-A's hop walk, stage 2b — can
  //    see a read the clone never performs: the operand's consumer set is the
  //    hand-inlined twin's. One rewrite at the one point the record exists, rather
  //    than a `isRecordedDeadSlot` exemption in every consumer (Rule 14; L3's
  //    mirror — a consumer that forgot the exemption would re-open bd tzfa).
  struct Neutralised {
    Function *F;
    CallBase *CB;
    Value *Op;
  };
  SmallVector<Neutralised, 8> Done;
  for (Function &F : M) {
    if (F.isDeclaration() || taint.SpecHandleArgMask.count(&F))
      continue;  // a clone / `_unc` twin body: its own Bennett wrap discharges.
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || !taint.SpecDeadArgMask.count(Callee))
          continue;
        // EVERY slot the record calls dead, not only the detection mask's.
        for (unsigned A = 0, E = CB->arg_size(); A < E; ++A) {
          if (!isRecordedDeadSlot(*CB, A, taint))
            continue;
          Value *Op = CB->getArgOperand(A);
          // The ONE rewrite (`rewriteRecordedDeadSlotUse`): a null of the CLONE
          // PARAMETER's type, never the caller operand's (bd `f061`, bd vsfp Rule-13
          // r3A F-XA-1 — a verifier ABORT, exit 134: after `retargetSite` a tainted
          // fp slot of an fp-ABI clone is an `i32` HANDLE parameter while the
          // caller's operand is still the stock `float`/`double`/`x86_fp80` value,
          // which `lowerRotations`/`lowerOps` RAUW later — a constant never is).
          if (isa<Constant>(Op))
            continue;  // already a constant.
          if (!rewriteRecordedDeadSlotUse(CB->getArgOperandUse(A), taint)) {
            // A slot that is not NULL-SAFE (bd `91k9`, round 5: a pointer, a
            // `byval`, an attribute outside the allowlist) is left in place. This
            // is where their difference is resolved AT MODULE LEVEL (one clone
            // level down it is `buildClone`'s bd `nlfd` fence and the liveness
            // rule's unread-scalar-slot clause). A
            // classical value there is harmless — no rail, no consumer set, no
            // spine. A QUANTUM one would stay a phantom read, exactly bd `tzfa`'s
            // extra consumer, so it declines (the same string as step 2).
            if (!isQuantumCallerValue(Op, taint))
              continue;
            F.getContext().diagnose(DiagnosticInfoUnsupported(
                F, kMsgPhantomArgRead, CB->getDebugLoc()));
            return true;
          }
          Done.push_back({&F, CB, Op});
        }
      }
  }
  // 2. DECLINE what the spine still cannot discharge like the twin. A neutralised
  //    QUANTUM operand the user program still reads is computed by the twin too,
  //    and now has the twin's consumer set — the spine discharges it (or keeps
  //    it) exactly as the twin's. One the user program does NOT read is a
  //    computation the twin does not have: a control-emitted rail minted for the
  //    phantom (a 4.4 `%out` — a which-path rail no stage uncomputes) or a dead
  //    tainted op (lowered as a forward template; a dead chain is not reliably
  //    uncomputed — CLAUDE.md fenv, bd vsfp §R2.6). Declined.
  //    The one exemption is a `cq_theta` RESULT: the user's own register, which
  //    the twin computes and keeps too (`cq_theta` is never deleted; validated by
  //    Rule-13 r1B on nine shapes, mutant B2).
  DenseMap<Function *, std::unique_ptr<FunctionLiveness>> Live;
  for (const Neutralised &N : Done) {
    if (!isQuantumCallerValue(N.Op, taint))
      continue;  // a classical value costs nothing: no rail, no entanglement.
    if (auto *OpCI = dyn_cast<CallInst>(N.Op);
        OpCI && taint.ThetaCalls.contains(OpCI))
      continue;
    auto &L = Live[N.F];
    if (!L)
      L = std::make_unique<FunctionLiveness>(*N.F, taint);
    if (userProgramReads(N.Op, *L, taint))
      continue;
    N.F->getContext().diagnose(DiagnosticInfoUnsupported(
        *N.F, kMsgPhantomArgRead, N.CB->getDebugLoc()));
    return true;
  }
  return false;
}

void specialize(Module &M, WidthDispatch &wd, TaintSet &taint, SpecPlan &plan) {
  // Each retargeted TOP-LEVEL site + whether its clone returns a tainted handle
  // (read post-drain for the §2.7 return-taint re-seed). Inner sites live inside
  // clones (disjoint `cloneTaint`) and are NOT module-level — `buildClone` owns
  // their retargeting and intra-clone taint, so they never enter `Retargeted`.
  SmallVector<std::pair<CallInst *, bool>, 4> Retargeted;

  // Drain the proven-Accept top candidates. `resolveSite` recurses depth-first
  // into each clone's inner tainted-arg calls (the transitive worklist),
  // synthesizing each distinct `(callee, mask)` once via the shared cache (3.4)
  // and terminating on the finite key space of the acyclic accepted subset (3.6).
  // `Pending` holds only the module-level tops (the carve-out's membership domain)
  // and never grows here — inner specialization is the recursion, not a push.
  for (size_t i = 0; i < plan.Pending.size(); ++i) {
    SpecCandidate Cand = plan.Pending[i];
    StringRef OrigW = abiWidthFromType(Cand.Site->getType());  // pre-retarget width.
    // bd `test_C_libtooling-cepm` — asked on the site AS PROPAGATION LEFT IT, i.e.
    // before `resolveSite` can rebuild it (an fp-return retarget erases the call and
    // the new one is not in `Tainted`).
    const bool ResultWasTainted =
        Cand.Site->getType()->isVoidTy() || taint.Tainted.count(Cand.Site);
    SpecRecord Rec =
        resolveSite(Cand.Site, Cand.Callee, Cand.Mask, M, wd, taint, plan);
    // THE CHECK ON THE PROPAGATION-TIME PREDICTION (bd cepm / bd 3zr4). Propagation
    // leaves a site's RESULT classical when `predictReturnTainted` says the clone
    // returns a classical value (`specCallResultPredictedClassical`), and every stage
    // since — both control rounds, the IO/QRAM/Shadow lowerings, the classical-mux
    // guard and its lifts — has read the result as an ordinary integer. A clone that
    // returns a REGISTER after all would make every one of those readings wrong, and
    // the re-mark below (`taint.Tainted.insert`) would taint the call but none of its
    // consumers: the handle id read as data, verify-clean. ⚠ WHAT REACHES THIS (round
    // 1b; Rule-13 r1A F-r1A-3 corrected the earlier text here, which called the check
    // "argued UNREACHABLE" because "nothing between propagation and here is known to
    // change a callee body" — the wrong mechanism): the predictor is a sound
    // over-approximation FOR A FIXED MASK (SpecializeClone.h), but the clone is built
    // with `Cand.Mask`, which a later round can GROW (`replanReseedSpecialization`).
    // The propagation drain's SETTLE step taints such a site at round 1 whenever
    // `LaterTaintOracle` foresees the growth; a site it does not foresee stays
    // classical under the STICKY rule, and THIS CHECK is that rule's designated
    // backstop — reached by a REPLANNED MASK, with the callee body untouched
    // (measured: mutants that disable the settle step or blind the oracle make the
    // round-2 mask-growth fixtures decline here). It is LOUD, never a silent re-mark.
    // `LLVMContext::diagnose` exits on the `DS_Error` in
    // `opt` (bd br4a), so nothing any window stage did reaches the output; on a host
    // whose handler returns, the drain carries on (the site is retargeted and
    // re-marked below, as every other specializer decline leaves its site).
    if (Rec.ReturnTainted && !ResultWasTainted)
      M.getContext().diagnose(DiagnosticInfoUnsupported(
          *Cand.Site->getFunction(), kMsgPredictedClassicalQuantum,
          Cand.Site->getDebugLoc()));
    Retargeted.push_back({Cand.Site, Rec.ReturnTainted});
    // fp-ABI result HandleWidth (bd 3c6m.54): a tainted fp return is an i32 handle
    // at the call site (`retargetSite` rebuilt the call to i32), but its logical
    // width is the ORIGINAL fp width captured above. Record it so a caller CAST off
    // the result — `(int)coshl(q)` → `fptosi f<W> %r to i32` — recovers the fp
    // source width (the theta-handle parity) instead of declining "no template for
    // fptosi i32". Recorded HERE (not in `buildClone`) so BOTH the build AND the
    // cache-HIT path are covered (a cache hit skips `buildClone` — the Rule-13
    // cache-hit gap). A caller fp ARITH / MEASURE reads the width from its own type
    // and never consults this; harmless there.
    if (Rec.ReturnTainted && abiWidthHasReversibleFpCopy(OrigW))
      taint.HandleWidth[Cand.Site] = OrigW;
  }

  // §2.7 return-taint re-seed. `propagate` taints a specialized-call result
  // CONSERVATIVELY whenever `predictReturnTainted` says the clone MAY return a
  // register — ⚠ since bd cepm NOT "every specialized-call result" (that was the
  // text here, and it stopped being true): a site predicted classical was never
  // tainted, is skipped by both branches below, and its prediction was checked
  // above. The clone's post-lowering `ReturnTainted` is the precise verdict:
  //   * true  → the result is genuine quantum data; leave it tainted (already in
  //     `taint`, downstream already propagated) — the caller's `:115` uncompute
  //     owns it (C-Taint).
  //   * false → the conservative taint was wrong (the predictor over-approximated:
  //     e.g. an inner clone that returns classical, or a tainted branch the clone's
  //     flatten removes); scrub the result and the forward cone that loses all
  //     taint, so a downstream caller op stays CLASSICAL (WI-1.9) — and bd l3oi's
  //     fence refuses whatever an emitter already read as a register.
  // Never-scrub roots: every value whose taint is INDEPENDENT of a scrubbed
  // call result — the primary `cq_theta` sources (a theta result is quantum
  // regardless of its arg-0 seed, Rule 3) and every genuinely-tainted
  // specialized-call result. The walk stops at these, pruning their downstream
  // cones (axis-(g) over-scrub fix). `cq_phi` is deliberately absent — it is
  // not a source (pre-3qlq a register-form one on a classical operand was scrubbed).
  SmallPtrSet<const Value *, 8> TaintedSources;
  for (auto &R : Retargeted)
    if (R.second)
      TaintedSources.insert(R.first);
  for (const CallInst *Theta : taint.ThetaCalls)
    TaintedSources.insert(Theta);
  for (auto &R : Retargeted) {
    CallInst *Site = R.first;
    bool ReturnTainted = R.second;
    if (ReturnTainted) {
      taint.Tainted.insert(Site);  // robustness; usually already present.
    } else if (taint.Tainted.count(Site)) {
      scrubForwardCone(Site, taint, TaintedSources);
    }
  }
}

}  // namespace cq
