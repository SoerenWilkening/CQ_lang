// ControlDetection.cpp — Pure-analysis recovery of controlled regions from
// the realized `-O1` control surface (PRD §2.2/§2.5/§2.7, IMPLEMENTATION §5.1).
// WP3 recognizes the `br`-diamond + merge-`φ` shape; WP4 adds the classical-arm
// `select i1` shape; WP5 adds the `&&`/`||` flag-combination select idiom and
// the un-flattened nested `if(a){if(b)…}` shape (both fold into the single-flag
// conjunction model).
//
// Detection keys STRICTLY on taint membership of the branch condition (§1.3):
// a tainted-condition `br i1` over a (possibly nested) diamond is a controlled
// region; a classical-condition branch has no physical content and is ignored.
// No IR is mutated — the plan is consumed downstream (`RotationLowering` skips
// the in-shadow `cq_phi`; `ControlledLowering` lowers the region). The escape
// guard (ret/measure/out-of-region br in the arm) emits the loud diagnostic and
// skips the region (PRD §5; cousin of the prototype's `computeFreePoint`).

#include "ControlPlan.h"

#include "OpcodeSupport.h"  // abiWidthFromType
#include "TaintPropagation.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/CFG.h"  // predecessors
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// Loud "unsupported under quantum control" diagnostic, on the same
// `DiagnosticInfoUnsupported(DS_Error)` surface the rest of the pass uses
// (mirrors `diagnoseNoTemplate` / RotationLowering's `diagnoseUnsupported`).
// `What` names the escape so a fixture can FileCheck it. The offending
// instruction's `!dbg` is attached so the rejection is SOURCE-LOCATED (WP17,
// PRD §8.6 / backend.md §7 "source-location precision via !dbg") — `clang`
// then prints `file:line:col:` at the `return`/`break`/`measure` site; an
// instruction without debug info falls back to the function-level location.
void diagnoseEscape(Instruction *Where, StringRef What) {
  std::string Msg =
      ("cq controlled lowering: " + What + " under quantum control").str();
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// A `@cq_measure_<sfx>` (front-end) or `@cqrt_measure_<W>` (already lowered)
// call — measurement collapses the controlled state and is an escape. Detection
// runs before measure lowering so only the `cq_measure_` form is live, but
// accepting both keeps the rule honest.
bool isMeasureCall(const Instruction &I) {
  const auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cq_measure_") || N.starts_with("cqrt_measure_");
}

// A `@cq_phi_<sfx>` gate-body call (the in-shadow op WP3 lowers controlled).
bool isPhiCall(const Instruction &I) {
  const auto *CI = dyn_cast<CallInst>(&I);
  if (!CI)
    return false;
  const Function *Callee = CI->getCalledFunction();
  return Callee && Callee->getName().starts_with("cq_phi_");
}

// Is EVERY user of `V` a `cq_phi` rotation that takes `V` as the classical ANGLE
// (arg 1), never the arg-0 handle? On success fills `Consumers` with the rotation
// calls (in use order). Shared by the WP10 select-form angle guard and the
// cwk-fix-(b) diamond/switch-form angle guard — the SSA shape of the angle feed
// is identical whether `V` is a `select` or a merge `φ`.
//
// `cq_phi` ONLY (not `cq_theta`): the controlled-rotation-by-difference lowering
// (`reduceAngleSelect`/`reduceAngleDiamondPhi` → `emitRz`) reads the width off a
// `cq_phi_` callee and emits `cqrt_rz[_controlled]`. A `cq_theta` (the Ry-prep
// rotation) is NOT lowerable that way — accepting it here would build a region
// `emitRz` then fails to lower, leaving the rotation standing and the angle `φ`
// dangling (a broken module). Excluding it routes a `cq_theta`-fed angle to the
// loud "rotation angle" diagnostic instead (no silent miscompile).
bool usersAreAngleFeeds(Value *V, SmallVectorImpl<Instruction *> &Consumers) {
  if (V->use_empty())
    return false;
  // The angle source is always an instruction (a `SelectInst` or merge `PHINode`).
  // The controlled-rotation-by-difference reducers anchor the flag uncompute
  // after the BLOCK-LAST consumer (`anchorAfterLastConsumer`), which scans a
  // SINGLE block — so every consumer MUST be co-located with the source. A
  // consumer in a different block would have its controlled rotation emitted
  // AFTER the uncompute (which lands in the source's block), firing on an
  // already-uncomputed flag — a verify-clean SILENT miscompile (adversarial
  // review, 2026-06-03). Require single-block co-location; a cross-block angle
  // feed is NOT cleanly lowerable and is left to the loud "rotation angle"
  // diagnostic (no region built).
  auto *VI = dyn_cast<Instruction>(V);
  if (!VI)
    return false;
  BasicBlock *HomeBB = VI->getParent();
  for (User *U : V->users()) {
    auto *CI = dyn_cast<CallInst>(U);
    if (!CI)
      return false;
    const Function *Callee = CI->getCalledFunction();
    if (!Callee)
      return false;
    if (!Callee->getName().starts_with("cq_phi_"))
      return false;
    // `V` must be the angle (arg 1), never the arg-0 handle.
    if (CI->arg_size() < 2 || CI->getArgOperand(1) != V ||
        CI->getArgOperand(0) == V)
      return false;
    if (CI->getParent() != HomeBB)
      return false;  // cross-block consumer — not single-block-anchorable.
    Consumers.push_back(CI);
  }
  return true;
}

// WP10 (Family B2): is `Sel` a CLEAN rotation-parameter feed — a select used
// EXCLUSIVELY as the classical ANGLE (arg 1) of one or more `cq_phi`/`cq_theta`
// rotations? `-O1` sinks `if(q){rz(u,a);}else{rz(u,b);}` into
// `rz(u, select(cmp, a, b))`; that select is the rotation angle and lowers as
// controlled-rotation-by-difference. A select used anywhere else (a non-rotation
// op, or the arg-0 handle) is NOT cleanly lowerable and stays a B1 diagnostic.
// On a clean match, fills `Consumers` with the rotation calls (in use order).
bool isCleanAngleSelect(SelectInst *Sel,
                        SmallVectorImpl<Instruction *> &Consumers) {
  return usersAreAngleFeeds(Sel, Consumers);
}

// cwk fix (b) (test_C_libtooling-byx): classify a diamond's merge `φ` for the
// angle-lowering path. The `br`-diamond / gated-switch analog of
// `isCleanAngleSelect`, generalized to the WHOLE merge so a mixed merge is never
// partially lowered. For each `φ` in `MergeBB`:
//   * supported integer-data width (the WP4/WP7 classical mux) → skip
//     (`dissolveBranchPhi` lowers it);
//   * a gate-handle `φ` (any tainted incoming) → skip (dissolved by RAUW);
//   * a wholly-classical SCALAR-FP `φ` whose users are all clean `cq_phi` angle
//     feeds → LOWERABLE: append to `AnglePhi` and its rotations to `Consumers`
//     (these join `plan.InShadow`; `reduceAngleDiamondPhi` lowers them as
//     base + controlled-difference);
//   * ANY OTHER wholly-classical `φ` (a `<2 x double>` vector / `i128` / `ptr`,
//     or a scalar-FP angle feeding a non-rotation, or a `cq_theta`) is NOT
//     lowerable → return it so the caller DIAGNOSES the whole region.
// Returning the first unlowerable `φ` (rather than short-circuiting on the first
// lowerable one) is load-bearing: a merge carrying a lowerable angle `φ` AND an
// unlowerable sibling `φ` must be rejected wholesale — building the region would
// leave the sibling to `reduceClassicalMux`/linearization (the cwk-fix-(a)
// miscompile/broken module). Returns null iff every classical `φ` is lowerable
// (possibly with `AnglePhi` empty — an ordinary gate/data region).
PHINode *classifyAngleMerge(BasicBlock *MergeBB, TaintSet &taint,
                            SmallVectorImpl<PHINode *> &AnglePhi,
                            SmallVectorImpl<Instruction *> &Consumers) {
  for (PHINode &P : MergeBB->phis()) {
    // The legitimate integer-data mux (WP4/WP7) — leave it to dissolveBranchPhi.
    if (P.getType()->isIntegerTy() && !abiWidthFromType(P.getType()).empty())
      continue;
    // A gate-handle (tainted-incoming) φ is dissolved by RAUW, not lowered here.
    bool AnyTainted = false;
    for (Value *In : P.incoming_values())
      if (taint.Tainted.count(In)) {
        AnyTainted = true;
        break;
      }
    if (AnyTainted)
      continue;
    // A wholly-classical φ. Lowerable iff a scalar-FP clean `cq_phi` angle feed.
    SmallVector<Instruction *, 4> Cons;
    if (P.getType()->isFloatingPointTy() && usersAreAngleFeeds(&P, Cons)) {
      AnglePhi.push_back(&P);
      for (Instruction *C : Cons)
        Consumers.push_back(C);
      continue;
    }
    return &P;  // unlowerable (vec/i128/ptr, non-rotation use, cq_theta, …).
  }
  return nullptr;
}

// Safety guard (Phase 4.1 spike, `-aht.3`): a tainted value used to compute a
// memory ADDRESS — a `getelementptr` base/index, or a `load`/`store` pointer —
// or stored to memory is UNSUPPORTED and would otherwise SILENTLY MISCOMPILE.
// The motivating case: `-O1` lowers a tainted `switch`/`if-else-if` over
// rotation angles to a jump TABLE (a constant array + `gep` + `load`) indexed
// by the handle id — the gep/load escape the WP12 `SwitchInst` guard (there is
// no `SwitchInst` left), so the diamond matcher lowers it and the program reads
// the table at the quantum REGISTER ID (an allocation counter), not the
// superposed value, then rotates by garbage. There is no register-based CQ
// program that legitimately addresses memory with a quantum handle (handles are
// i32 SSA ids passed to `cqrt_*`/`cq_template_*`, never dereferenced), so this
// diagnoses loudly with the offending instruction's source location. Returns
// true (diagnosed) on the first offending op in `F`.
bool diagnoseTaintedMemoryEscape(Function &F, TaintSet &taint) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
        for (Value *Op : GEP->operands())
          if (taint.Tainted.count(Op)) {
            diagnoseEscape(GEP, "memory addressing");
            return true;
          }
      } else if (auto *LD = dyn_cast<LoadInst>(&I)) {
        if (taint.Tainted.count(LD->getPointerOperand())) {
          diagnoseEscape(LD, "memory load");
          return true;
        }
      } else if (auto *ST = dyn_cast<StoreInst>(&I)) {
        if (taint.Tainted.count(ST->getPointerOperand()) ||
            taint.Tainted.count(ST->getValueOperand())) {
          diagnoseEscape(ST, "memory store");
          return true;
        }
      }
    }
  }
  return false;
}

// WP16 (PRD §8.4): is `Sel` an INNER member of an angle-select chain — every
// user is a `select` that takes `Sel` as its FALSE value (the running base)?
// `-O1` sinks an angle `switch`/`if-else-if` to a nested select chain
// `select(f_n, a_n, …select(f_1, a_1, base))` feeding the rotation angle; the
// chain HEAD (consumed by the rotations) is recognized by `isCleanAngleSelect`,
// while inner members thread the base through false arms. Skipped at detection
// so they are neither diagnosed nor doubly-regioned — `reduceAngleSelectChain`
// dissolves the whole chain from the head.
bool isAngleChainInner(SelectInst *Sel) {
  if (Sel->use_empty())
    return false;
  for (User *U : Sel->users()) {
    auto *S2 = dyn_cast<SelectInst>(U);
    if (!S2 || S2->getFalseValue() != Sel)
      return false;
  }
  return true;
}

// WP16 (PRD §8.4): does the angle-select chain rooted at `Head` consist of
// MUTUALLY EXCLUSIVE cases — every condition down the false-arm chain is
// `icmp eq` against the SAME scrutinee with a pairwise-DISTINCT constant, each
// true arm a (non-select) case angle, the chain bottoming out at a non-select
// base? Only then does the nested select equal the additive form
// `base + Σ_k f_k·(a_k − base)` that `reduceAngleSelectChain` emits (a general,
// non-exclusive `if-else-if` angle chain would need AND-NOT guards — out of
// first-cut scope, so it stays the loud B1 diagnostic).
bool isMutuallyExclusiveAngleChain(SelectInst *Head) {
  Value *Scrut = nullptr;
  SmallVector<const ConstantInt *, 4> Consts;
  SelectInst *Cur = Head;
  while (Cur) {
    auto *Cmp = dyn_cast<ICmpInst>(Cur->getCondition());
    if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_EQ)
      return false;
    const ConstantInt *CV = nullptr;
    Value *S = nullptr;
    if ((CV = dyn_cast<ConstantInt>(Cmp->getOperand(1))))
      S = Cmp->getOperand(0);
    else if ((CV = dyn_cast<ConstantInt>(Cmp->getOperand(0))))
      S = Cmp->getOperand(1);
    else
      return false;  // not `scrutinee == const`.
    if (!Scrut)
      Scrut = S;
    else if (Scrut != S)
      return false;  // a different scrutinee — not one N-way dispatch.
    for (const ConstantInt *Prev : Consts)
      if (Prev->getValue() == CV->getValue())
        return false;  // duplicate case constant — not pairwise-exclusive.
    Consts.push_back(CV);
    if (isa<SelectInst>(Cur->getTrueValue()))
      return false;  // the true arm is a case angle, not another select.
    Value *F = Cur->getFalseValue();
    if (auto *Next = dyn_cast<SelectInst>(F)) {
      Cur = Next;
      continue;
    }
    return true;  // bottomed out at the non-select base angle.
  }
  return false;
}

// Scan the single guarded arm `Arm` for an escape (PRD §5): a `ReturnInst`, a
// measurement, or any terminator that does not fall straight through to
// `MergeBB`. On escape, diagnose at the offending instruction and return true.
// Collects the in-shadow gate-body ops into `Shadow` as it goes.
bool armEscapesOrCollect(BasicBlock *Arm, BasicBlock *MergeBB,
                         SmallVectorImpl<Instruction *> &Shadow) {
  for (Instruction &I : *Arm) {
    if (isa<ReturnInst>(&I)) {
      diagnoseEscape(&I, "return");
      return true;
    }
    if (isMeasureCall(I)) {
      diagnoseEscape(&I, "measurement");
      return true;
    }
    if (auto *Br = dyn_cast<BranchInst>(&I)) {
      // The arm's terminator must be an unconditional fall-through to the
      // merge. A conditional branch or a branch elsewhere leaves the region.
      if (Br->isConditional() || Br->getSuccessor(0) != MergeBB) {
        diagnoseEscape(&I, "control-flow escape");
        return true;
      }
      continue;  // the well-formed fall-through; not a shadow op.
    }
    if (isPhiCall(I))
      Shadow.push_back(&I);
  }
  return false;
}

// Does the block `Arm` cleanly RECONVERGE to `Sibling` — the controllable
// shape (WP3 diamond / nested-AND inner arm)? An arm reconverges iff it is
// guarded solely by the branch in `Pred` (single predecessor) and its
// terminator is an unconditional `br` to `Sibling` (it falls straight through
// to the merge). Controllable arms always reconverge; an escaping arm does
// not. Used to distinguish "controllable" from "escape" for a tainted-condition
// branch that matched no controllable shape.
bool armReconverges(BasicBlock *Arm, BasicBlock *Pred, BasicBlock *Sibling) {
  if (Arm->getSinglePredecessor() != Pred)
    return false;
  auto *Term = dyn_cast<BranchInst>(Arm->getTerminator());
  return Term && !Term->isConditional() && Term->getSuccessor(0) == Sibling;
}

// Escape guard for a tainted-condition `br i1` that matched NEITHER controllable
// shape (no diamond, no select, no nested-AND, no flag conjunction): per PRD
// line 108/309 (`if (q) return …;` / `break` / measure-in-arm), a guarded arm
// that does NOT reconverge but instead ESCAPES — contains a `ReturnInst` /
// `@cq_measure_*` / leaves the region — is "return/measure under quantum
// control." Emit the loud diagnostic (refined to reject/bridge in Phase 4.1).
//
// Fire ONLY when an arm is guarded solely by this branch (single predecessor —
// genuinely "under" the control) and does NOT reconverge to its sibling
// successor. This deliberately does NOT fire on the controllable shapes — WP3's
// diamond arm, WP4/WP5's select/conjunction (no CFG to escape), and the
// nested-AND inner arm all reconverge (`armReconverges`), so they are handled
// by their own matchers + arm walks above. Returns true (diagnosed) on escape.
bool branchEscapes(BranchInst *Br) {
  BasicBlock *Pred = Br->getParent();
  BasicBlock *S0 = Br->getSuccessor(0);
  BasicBlock *S1 = Br->getSuccessor(1);
  for (int i = 0; i < 2; ++i) {
    BasicBlock *Arm = i == 0 ? S0 : S1;
    BasicBlock *Sibling = i == 0 ? S1 : S0;
    // Only an arm guarded solely by THIS branch is "under" the control. A
    // shared block (e.g. a common merge with multiple predecessors) is not an
    // escape arm — its `ret` is reached on every path, not under the guard.
    if (Arm->getSinglePredecessor() != Pred)
      continue;
    // A reconverging arm is the controllable shape — not an escape. (Its own
    // matcher either claimed it or its body is benign fall-through.)
    if (armReconverges(Arm, Pred, Sibling))
      continue;
    for (Instruction &I : *Arm) {
      if (isa<ReturnInst>(&I)) {
        diagnoseEscape(&I, "return");
        return true;
      }
      if (isMeasureCall(I)) {
        diagnoseEscape(&I, "measurement");
        return true;
      }
    }
  }
  return false;
}

// Recognize the `&&`/`||` flag-combination idiom (PRD §2.5): `-O1` spells a
// short-circuit condition as an `i1`-select over two flags — AND =
// `select i1 %fa, i1 %fb, i1 false`; OR = `select i1 %fa, i1 true, i1 %fb`.
// Both sub-conditions are tainted compares (so the select is tainted); it is
// NOT a data select (an arm is a tainted i1 flag, never a classical value, so
// WP4's "both arms classical" test already excludes it). On a match, set
// `A`/`B` to the two sub-compares and `Kind` to the conjunction.
bool matchFlagConjunction(Value *Cond, TaintSet &taint, Value *&A, Value *&B,
                          ControlRegion::ConjKind &Kind) {
  auto *Sel = dyn_cast<SelectInst>(Cond);
  if (!Sel || !Sel->getType()->isIntegerTy(1))
    return false;  // a flag conjunction is an i1-typed select.

  Value *C = Sel->getCondition();
  Value *T = Sel->getTrueValue();
  Value *F = Sel->getFalseValue();
  auto *Tc = dyn_cast<ConstantInt>(T);
  auto *Fc = dyn_cast<ConstantInt>(F);

  // AND: `select i1 %fa, i1 %fb, i1 false` — true arm is a flag, false arm is 0.
  if (Fc && Fc->isZero() && !Tc) {
    A = C;
    B = T;
    Kind = ControlRegion::ConjAnd;
  }
  // OR: `select i1 %fa, i1 true, i1 %fb` — true arm is 1, false arm is a flag.
  else if (Tc && Tc->isOne() && !Fc) {
    A = C;
    B = F;
    Kind = ControlRegion::ConjOr;
  } else {
    return false;
  }

  // Both sub-conditions must be tainted compares (the physical content). A
  // classical sub-condition would make this a degenerate select, not a
  // quantum flag conjunction — leave it for the verifier / passthrough.
  if (!isa<CmpInst>(A) || !isa<CmpInst>(B))
    return false;
  if (!taint.Tainted.count(A) || !taint.Tainted.count(B))
    return false;
  return true;
}

// Recognize a 2-block diamond: a `br i1 %cond, A, B` where exactly one
// successor is a single-predecessor "arm" that unconditionally branches to the
// other successor (the "merge"). Sets `Arm`/`MergeBB` and returns true on a
// match. The merge must have a `PHINode` (the `[modified, original]` φ) — a
// no-φ diamond is not WP3's shape.
bool matchDiamond(BranchInst *Br, BasicBlock *&Arm, BasicBlock *&MergeBB,
                  bool &ArmIsFalse) {
  BasicBlock *S0 = Br->getSuccessor(0);
  BasicBlock *S1 = Br->getSuccessor(1);

  // Try each successor as the arm; the other is the candidate merge.
  for (int i = 0; i < 2; ++i) {
    BasicBlock *CandArm = i == 0 ? S0 : S1;
    BasicBlock *CandMerge = i == 0 ? S1 : S0;
    // The arm is guarded by exactly this branch (single predecessor) and
    // unconditionally continues to the merge.
    if (CandArm->getSinglePredecessor() != Br->getParent())
      continue;
    auto *ArmTerm = dyn_cast<BranchInst>(CandArm->getTerminator());
    if (!ArmTerm || ArmTerm->isConditional())
      continue;
    if (ArmTerm->getSuccessor(0) != CandMerge)
      continue;
    // The merge must carry the SSA merge `φ` this region dissolves.
    if (!isa<PHINode>(&CandMerge->front()))
      continue;
    Arm = CandArm;
    MergeBB = CandMerge;
    // `i == 1` ⇒ the arm is the FALSE successor (`br i1 cond, Merge, Arm`), so
    // it is taken when `cond` is false and its gates fire on ¬flag. `clang`
    // emits this for swapped branches (`if (u != 5)` → `icmp eq; br eq, M, A`).
    ArmIsFalse = (i == 1);
    return true;
  }
  return false;
}

// Recognize a SYMMETRIC two-content-arm diamond (WP8, Family C, PRD §7):
// `Pred -[tainted br]-> {ArmT, ArmF}` where BOTH successors are single-pred
// content arms that unconditionally fall through to a COMMON third merge block
// `M` carrying φ(s). `if(q){u=g(u);}else{v=g(v);}` lowers this way at `-O1`.
// Distinct from `matchDiamond` (one-content-arm: the sibling successor IS the
// merge, so the merge has two preds and fails the single-pred arm test here).
// On a match the TRUE successor is `ArmT`, the FALSE `ArmF`. `matchDiamond` is
// tried first, so by the time this runs the one-content-arm shape is excluded.
bool matchSymmetricDiamond(BranchInst *Br, BasicBlock *&ArmT, BasicBlock *&ArmF,
                           BasicBlock *&MergeBB) {
  BasicBlock *Pred = Br->getParent();
  BasicBlock *S0 = Br->getSuccessor(0);  // true arm
  BasicBlock *S1 = Br->getSuccessor(1);  // false arm
  // Both arms must be guarded solely by this branch.
  if (S0->getSinglePredecessor() != Pred || S1->getSinglePredecessor() != Pred)
    return false;
  auto *T0 = dyn_cast<BranchInst>(S0->getTerminator());
  auto *T1 = dyn_cast<BranchInst>(S1->getTerminator());
  if (!T0 || T0->isConditional() || !T1 || T1->isConditional())
    return false;  // each arm must unconditionally fall through.
  BasicBlock *M = T0->getSuccessor(0);
  if (M != T1->getSuccessor(0))
    return false;  // both arms must reconverge to the SAME merge.
  if (M == S0 || M == S1)
    return false;  // a degenerate self-loop, not a forward diamond.
  if (!isa<PHINode>(&M->front()))
    return false;  // the merge must carry the SSA merge φ(s) we dissolve.
  ArmT = S0;
  ArmF = S1;
  MergeBB = M;
  return true;
}

// Recognize an un-flattened nested `if (a) { if (b) gate; }` at the OUTER
// branch (PRD §2.7). `-O1` keeps two diamonds (vs folding to one range check)
// when the inner guard can't merge with the outer (distinct operands / an
// opaque arm). Shape — `Pred -[a]-> {Mid, Merge}`, `Mid -[b]-> {Arm, Merge}`,
// `Arm -> Merge` (Merge carries a 3-way φ). On a match, fills the nesting
// anchors + `CondA=a`/`CondB=b` so the region reuses the conjunction flag
// machinery verbatim (the gate ends up controlled by one `f_both = a ∧ b`,
// "one Toffoli per level"); linearization later splices `Mid`+`Arm`+`Merge`
// into `Pred`. The escape guard runs on the innermost `Arm` only — `Mid`'s
// trailing conditional `br` is the expected inner guard, not an escape, and
// its non-control body is spliced through.
bool matchNestedAnd(BranchInst *Br, TaintSet &taint, BasicBlock *&Mid,
                    BasicBlock *&Arm, BasicBlock *&MergeBB, Value *&CondA,
                    Value *&CondB, SmallVectorImpl<Instruction *> &Shadow) {
  BasicBlock *Pred = Br->getParent();
  for (int i = 0; i < 2; ++i) {
    BasicBlock *CandMid = Br->getSuccessor(i);     // intermediate inner guard.
    BasicBlock *CandMerge = Br->getSuccessor(1 - i);  // the common merge.
    if (CandMid->getSinglePredecessor() != Pred)
      continue;  // `Mid` must be guarded solely by the outer branch.
    auto *MidBr = dyn_cast<BranchInst>(CandMid->getTerminator());
    if (!MidBr || !MidBr->isConditional() ||
        !taint.Tainted.count(MidBr->getCondition()))
      continue;  // `Mid` holds a tainted (quantum-guard) inner `br i1`.
    // One inner successor is the merge; the other is the innermost gate arm.
    BasicBlock *CandArm = nullptr;
    for (int j = 0; j < 2; ++j)
      if (MidBr->getSuccessor(j) == CandMerge &&
          MidBr->getSuccessor(1 - j) != CandMerge)
        CandArm = MidBr->getSuccessor(1 - j);
    if (!CandArm || CandArm->getSinglePredecessor() != CandMid)
      continue;
    // The arm is a clean single-pred fall-through to the φ-merge (WP3 diamond).
    auto *ArmTerm = dyn_cast<BranchInst>(CandArm->getTerminator());
    if (!ArmTerm || ArmTerm->isConditional() ||
        ArmTerm->getSuccessor(0) != CandMerge ||
        !isa<PHINode>(&CandMerge->front()))
      continue;
    if (armEscapesOrCollect(CandArm, CandMerge, Shadow))
      return false;  // diagnosed escape on the innermost arm; not usable.
    Mid = CandMid;
    Arm = CandArm;
    MergeBB = CandMerge;
    CondA = Br->getCondition();     // outer compare.
    CondB = MidBr->getCondition();  // inner compare.
    return true;
  }
  return false;
}

// WP18 reconverge target: `Arm`'s UNIQUE predecessor is `SwBB` and it ends in an
// unconditional `br` to a merge. Unlike `valueMergeArmTarget` (SwitchNormalization),
// a NON-empty body is allowed — the arm holds the gate sequence, escape-guarded
// separately. Returns the merge it falls to (null on mismatch / self-loop).
BasicBlock *gatedArmTarget(BasicBlock *Arm, BasicBlock *SwBB) {
  if (Arm->getUniquePredecessor() != SwBB)
    return nullptr;
  auto *Br = dyn_cast<BranchInst>(Arm->getTerminator());
  if (!Br || Br->isConditional())
    return nullptr;
  BasicBlock *Merge = Br->getSuccessor(0);
  return (Merge == Arm) ? nullptr : Merge;
}

// WP18 (PRD §8.5): recognize a gated multi-arm `switch` — a tainted-scrutinee
// `SwitchInst` whose case + default arms each reconverge (single-pred,
// unconditional `br`) on a common merge carrying an N-way `φ`, with NO merge
// predecessor outside the arms, and gate bodies (`cq_phi`) per arm. On a match
// build a `SwitchRegion` (each case arm controlled on its eq-flag, the default
// on the ¬OR flag — lowered by `lowerGatedSwitch`). Returns true if HANDLED
// (region built OR an arm escape was diagnosed); false if the shape does not
// match (the caller fires the WP12 `switch` diagnostic as the fallback).
bool tryBuildGatedSwitchRegion(SwitchInst *Sw, ControlPlan &plan,
                               TaintSet &taint) {
  BasicBlock *SwBB = Sw->getParent();
  BasicBlock *Default = Sw->getDefaultDest();
  if (Sw->getNumCases() == 0)
    return false;  // degenerate (no cases) — not the gated shape.

  // Structure: every (distinct) CASE arm reconverges on one common merge. The
  // merge is recovered from the case arms (not the default) so the default can
  // be either a distinct reconverging block OR an empty `default:` routed
  // straight to the merge (test_C_libtooling-509).
  SmallPtrSet<BasicBlock *, 8> ArmBlocks;
  BasicBlock *Merge = nullptr;
  for (auto Case : Sw->cases()) {
    BasicBlock *CB = Case.getCaseSuccessor();
    BasicBlock *M = gatedArmTarget(CB, SwBB);
    if (!M)
      return false;  // a case arm does not cleanly reconverge.
    if (!Merge)
      Merge = M;
    else if (Merge != M)
      return false;  // case arms disagree on the merge.
    if (!ArmBlocks.insert(CB).second)
      return false;  // a shared arm block (duplicate target) — decline (future).
  }
  if (!Merge)
    return false;

  // Classify the default edge against that merge:
  //   * empty `default:` routed STRAIGHT to the merge (`Default == Merge`) — no
  //     default block; the default control is implicit (no case matched ⇒ the
  //     unconditional base), and the merge gains a `Pred`(switch-block) edge.
  //   * a distinct default block reconverging on the merge (the original WP18
  //     shape) — rides `Arm`/`Shadow`, controlled on the ¬OR flag.
  // Anything else (default elsewhere, or a distinct block not reconverging) is
  // declined for the WP12 diagnostic.
  bool DefaultDirect = false;
  if (Default == Merge) {
    DefaultDirect = true;
  } else {
    if (gatedArmTarget(Default, SwBB) != Merge)
      return false;  // default neither direct-to-merge nor reconverging.
    if (!ArmBlocks.insert(Default).second)
      return false;  // default block shared with a case arm — decline.
  }

  if (!isa<PHINode>(&Merge->front()))
    return false;  // no value merge → not the gated value-reconverging shape.
  for (BasicBlock *Pred : predecessors(Merge))
    if (!ArmBlocks.count(Pred) && !(DefaultDirect && Pred == SwBB))
      return false;  // an extra (non-arm) merge predecessor.

  // A classical-FP merge `φ` is a rotation angle dispatched by the switch under
  // quantum control — the `SwitchRegion` analog of the `br`-diamond cwk hole.
  // `lowerGatedSwitch` dissolves only TAINTED (handle) φ; a classical-double φ
  // would otherwise be left undissolved, then the switch linearized away,
  // leaving the φ with no live predecessors (a broken module, "PHI nodes not
  // grouped"). A CLEAN scalar-FP angle feed lowers as base + per-case
  // controlled-difference (cwk fix (b) PR3, `reduceAngleSwitchPhi`); record it +
  // its consuming rotations (which join InShadow so `lowerRotations` skips them
  // — `lowerGatedSwitch` lowers them on the per-case eq-flags). A NON-clean /
  // unlowerable-type φ (vector/i128/ptr, non-rotation use, `cq_theta`) is NOT
  // lowerable → diagnose on the "rotation angle" surface and OWN the diagnostic
  // (return true) so the caller does not also fire the WP12 `switch` fallback.
  SmallVector<PHINode *, 2> AnglePhis;
  SmallVector<Instruction *, 4> AngleCons;
  if (PHINode *BadPhi = classifyAngleMerge(Merge, taint, AnglePhis, AngleCons)) {
    diagnoseEscape(BadPhi, "rotation angle");
    return true;  // diagnosed.
  }

  // Structure matches: from here this function OWNS the diagnostic (returns true
  // even on an arm escape, so the caller does not also fire the WP12 fallback).
  ControlRegion region;
  region.Kind = ControlRegion::SwitchRegion;
  region.Condition = Sw->getCondition();  // the tainted scrutinee.
  region.Pred = SwBB;
  region.MergeBB = Merge;
  region.Merge = &Merge->front();  // the N-way merge φ.
  // Default arm: a distinct block rides `Arm`/`Shadow`; an empty direct-to-merge
  // default has NO block (`Arm` stays null) and no gate shadow.
  region.SwitchDefaultDirect = DefaultDirect;
  region.Arm = DefaultDirect ? nullptr : Default;
  for (PHINode *P : AnglePhis)
    region.AnglePhi.push_back(P);
  for (Instruction *C : AngleCons) {
    region.AngleConsumers.push_back(C);
    plan.InShadow.insert(C);
  }

  // Escape-guard + shadow-collect each arm (PRD §5). An arm with a `ret`,
  // measurement, or out-of-region branch is the quantum-controlled escape
  // (WP17) — diagnosed, no region. The direct-to-merge default has no block to
  // guard (its control is the implicit "no case matched", no gate body).
  if (!DefaultDirect && armEscapesOrCollect(Default, Merge, region.Shadow))
    return true;  // diagnosed.
  for (auto Case : Sw->cases()) {
    SwitchArm arm;
    arm.Value = Case.getCaseValue();
    arm.Block = Case.getCaseSuccessor();
    if (armEscapesOrCollect(arm.Block, Merge, arm.Shadow))
      return true;  // diagnosed.
    region.SwitchArms.push_back(std::move(arm));
  }

  // All arm gate bodies are in-shadow (so `lowerRotations` skips them; the
  // gated-switch lowering controls them instead, §1.4).
  for (Instruction *S : region.Shadow)
    plan.InShadow.insert(S);
  for (SwitchArm &A : region.SwitchArms)
    for (Instruction *S : A.Shadow)
      plan.InShadow.insert(S);
  plan.Regions.push_back(std::move(region));
  return true;
}

}  // namespace

ControlPlan detectControlRegions(Module &M, TaintSet &taint) {
  ControlPlan plan;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    // Safety guard first: a tainted value used as a memory address/index (the
    // `-O1` jump-table lowering of a tainted angle `switch`) silently
    // miscompiles. Diagnose and skip region detection for this function rather
    // than let the diamond matcher lower a handle-indexed table.
    if (diagnoseTaintedMemoryEscape(F, taint))
      continue;
    for (BasicBlock &BB : F) {
      // WP4: a tainted-condition `select i1` reduces to a controlled add onto a
      // register seeded from a chosen arm (PRD §2.2/§2.6). It has no CFG
      // diamond — `Pred`/`Arm`/`MergeBB` stay null, so linearization is a no-op
      // for it. Three arm shapes are in scope here, all keyed on the tainted
      // condition (the arm-taint discriminator is re-derived in
      // `MergeDissolution`, so no extra ControlRegion field is needed):
      //   * [classical, classical] (WP4): host `sub A−B` → controlled add (HL).
      //   * MIXED, exactly ONE tainted arm (mux.1): the tainted handle Q is one
      //     arm, a classical C the other — `delta = Q−C` via the UNCONTROLLED
      //     `sub_<W>_hl` template, then a Shape::QQ controlled add onto regC.
      //   * BOTH arms tainted (mux.2): neither arm is classical, so neither the
      //     host `sub` nor the `cqrt_alloc(C)`-from-classical seed apply. Build
      //     `regOut = alloc(0)`, then `add_controlled(f, regOut, hp)` and a ¬f
      //     `add_controlled(f, regOut, hq)` (cqrt_x flag bracket); both source
      //     handles are READ, never consumed, so they stay live for other uses.
      for (Instruction &I : BB) {
        auto *Sel = dyn_cast<SelectInst>(&I);
        if (!Sel)
          continue;
        // §1.3: keyed strictly on taint of the condition (same test as `br`).
        // A classical-condition select is left byte-untouched (§1.3, WP6).
        if (!taint.Tainted.count(Sel->getCondition()))
          continue;
        // EXCLUDE the `&&`/`||` flag-conjunction idiom (PRD §2.5): that select
        // is i1-typed and carries a tainted i1 sub-flag in exactly one arm, so
        // the "exactly one tainted arm" test below would otherwise misfire on
        // it. A data mux/reduction select is always a DATA width (i32/…), never
        // i1 — so skipping i1-typed selects here cleanly hands the conjunction
        // back to its `br i1 %and, …` carrier (the WP5 path) untouched.
        if (Sel->getType()->isIntegerTy(1))
          continue;
        // A tainted-condition select whose value type is not an integer HANDLE
        // width is a rotation-angle (or other non-handle) choice sunk under
        // quantum control — `-O1` folds `if(q){rz(u,a);}else{rz(u,b);}` into
        // `rz(u, select(cmp, a, b))` over the classical `double` angle (a valid
        // f64 ABI width, so `abiWidthFromType` alone does not reject it).
        if (!Sel->getType()->isIntegerTy() ||
            abiWidthFromType(Sel->getType()).empty()) {
          // WP10 (Family B2): a CLEAN rotation-parameter feed — the select is
          // the angle of one or more rotations — lowers as controlled-rotation-
          // by-difference (`AngleSelectRegion`). The consuming rotations join
          // the in-shadow set so `lowerRotations` leaves them for the
          // orchestrator. Otherwise (a non-rotation use of a double under
          // quantum control) keep the loud WP9 diagnostic (Family B1).
          SmallVector<Instruction *, 4> Consumers;
          if (isCleanAngleSelect(Sel, Consumers)) {
            // WP16: a CHAIN (the false arm is itself a select) must be mutually
            // exclusive (eq-flags on one scrutinee) for the additive
            // base+difference lowering to be valid; a non-exclusive chain stays
            // the loud B1 diagnostic. A single select (false arm = base angle)
            // takes the WP10 path unchanged.
            if (isa<SelectInst>(Sel->getFalseValue()) &&
                !isMutuallyExclusiveAngleChain(Sel)) {
              diagnoseEscape(Sel, "rotation angle");
              continue;
            }
            ControlRegion region;
            region.Condition = Sel->getCondition();
            region.Kind = ControlRegion::AngleSelectRegion;
            region.Merge = Sel;
            region.Depth = 0;
            for (Instruction *C : Consumers) {
              region.Shadow.push_back(C);
              plan.InShadow.insert(C);
            }
            plan.Regions.push_back(std::move(region));
          } else if (isAngleChainInner(Sel)) {
            // An inner member of an angle-select chain — the head (consumed by
            // the rotations) owns it; skip so it is neither diagnosed nor
            // doubly regioned. `reduceAngleSelectChain` walks it from the head.
          } else {
            diagnoseEscape(Sel, "rotation angle");
          }
          continue;
        }
        // Every non-i1, integer-handle-width tainted-condition select builds a
        // SelectRegion. The
        // arm-taint discriminator — neither tainted ([classical, classical],
        // WP4) / exactly one tainted (mixed mux, mux.1) / both tainted (data
        // mux, mux.2) — is re-derived from `taint` in `dissolveSelect`, which
        // dispatches the three reductions. (The both-tainted case used to be
        // rejected here; mux.2 lifted that so both-tainted gets its own add(0)
        // + two-controlled-adds branch instead of falling through unlowered.)

        ControlRegion region;
        region.Condition = Sel->getCondition();
        region.Kind = ControlRegion::SelectRegion;
        region.Merge = Sel;  // dissolved by MergeDissolution; no CFG.
        region.Depth = 0;
        // No Pred/Arm/MergeBB and no Shadow — a classical-arm select has no
        // in-shadow gate body and no diamond.
        plan.Regions.push_back(std::move(region));
      }

      // WP12 (Family D, safety): a `switch` on a tainted scrutinee branches on
      // the quantum HANDLE id and silently miscompiles — there is no SwitchInst
      // lowering (the realized lowering stays Phase 4.1, Family E: `-lowerswitch`
      // + closed-diamond guard). Diagnose loudly; a classical-scrutinee switch
      // is left untouched. Detection runs before measure lowering, so a tainted
      // scrutinee is exactly `taint.Tainted.count` of the switch condition.
      if (auto *Sw = dyn_cast<SwitchInst>(BB.getTerminator())) {
        if (taint.Tainted.count(Sw->getCondition())) {
          // WP18 (PRD §8.5): a gated multi-arm `switch` (distinct side-effecting
          // gate bodies per arm) lowers as N-way controlled substitution. On a
          // shape match `tryBuildGatedSwitchRegion` builds a SwitchRegion (or
          // diagnoses an arm escape); otherwise the WP12 fallback fires. The
          // value-merge `switch` was already rewritten away by WP15
          // (`normalizeTaintedSwitches`) before detection.
          if (!tryBuildGatedSwitchRegion(Sw, plan, taint))
            diagnoseEscape(Sw, "switch");
        }
        continue;
      }

      auto *Br = dyn_cast<BranchInst>(BB.getTerminator());
      if (!Br || !Br->isConditional())
        continue;
      // §1.3: a controlled region is exactly a TAINTED-condition branch. A
      // classical condition is left byte-untouched (no region built).
      if (!taint.Tainted.count(Br->getCondition()))
        continue;

      // WP5: try the un-flattened NESTED `if(a){if(b)gate;}` shape FIRST (its
      // outer arm is a conditional `br`, so `matchDiamond` won't accept it).
      // The inner gate-body diamond must NOT then be re-detected as a separate
      // flat region — the `InShadow` check below guards that. PRD §2.7.
      {
        BasicBlock *Mid = nullptr, *Arm = nullptr, *MergeBB = nullptr;
        Value *CondA = nullptr, *CondB = nullptr;
        ControlRegion region;
        if (matchNestedAnd(Br, taint, Mid, Arm, MergeBB, CondA, CondB,
                           region.Shadow)) {
          // A classical-FP merge `φ` is a rotation angle dispatched under
          // quantum control via the nested-AND form (cwk). A CLEAN angle feed
          // lowers as controlled-rotation-by-difference on the COMBINED `a ∧ b`
          // flag (fix (b), `reduceAngleDiamondPhi` treats the 3-way `φ` as
          // 2-way: the flag==1 angle on the innermost `Arm` edge, the base on
          // the `Pred`/`Mid` flag==0 edges); record it + its consuming rotations
          // (which join InShadow so lowerRotations skips them). A NON-clean /
          // unlowerable-type `φ` stays diagnosed.
          {
            SmallVector<PHINode *, 2> AnglePhis;
            SmallVector<Instruction *, 4> AngleCons;
            if (PHINode *BadPhi =
                    classifyAngleMerge(MergeBB, taint, AnglePhis, AngleCons)) {
              diagnoseEscape(BadPhi, "rotation angle");
              continue;
            }
            // A nested-AND angle φ is lowerable ONLY as a 2-way-on-conjunction
            // dispatch: the two flag==0 edges — `Mid` (inner-guard-false) and
            // the outer `Pred` (outer-guard-false) — must carry the SAME base
            // angle, so the 3-way φ collapses to base + single controlled
            // difference. A no-`else` nested `if` gives them the SAME SSA value;
            // but `if(a){ang=z; if(b){ang=x;}}` yields THREE distinct angles,
            // which `reduceAngleDiamondPhi` cannot reduce (its CleanBase check
            // bails, stranding the φ → a broken module). DIAGNOSE that here
            // rather than commit an unlowerable region (adversarial review,
            // 2026-06-03; restores the pre-classifyAngleMerge clean rejection).
            bool UnequalBase = false;
            for (PHINode *P : AnglePhis)
              if (P->getIncomingValueForBlock(Mid) !=
                  P->getIncomingValueForBlock(&BB)) {
                diagnoseEscape(P, "rotation angle");
                UnequalBase = true;
                break;
              }
            if (UnequalBase)
              continue;
            for (PHINode *P : AnglePhis)
              region.AnglePhi.push_back(P);
            for (Instruction *C : AngleCons) {
              region.AngleConsumers.push_back(C);
              plan.InShadow.insert(C);
            }
          }
          region.Condition = Br->getCondition();  // the outer compare.
          region.Kind = ControlRegion::BranchRegion;
          region.Merge = &MergeBB->front();  // the common merge PHINode.
          region.Pred = &BB;
          region.Mid = Mid;
          region.Arm = Arm;
          region.MergeBB = MergeBB;
          region.Conj = ControlRegion::ConjAnd;  // nesting = AND of the guards.
          region.CondA = CondA;
          region.CondB = CondB;
          for (Instruction *S : region.Shadow)
            plan.InShadow.insert(S);
          plan.Regions.push_back(std::move(region));
          continue;  // gate claimed; the inner diamond is now off-limits.
        }
      }

      BasicBlock *Arm = nullptr;
      BasicBlock *MergeBB = nullptr;
      bool ArmIsFalse = false;
      if (!matchDiamond(Br, Arm, MergeBB, ArmIsFalse)) {
        // WP8 (Family C): try the SYMMETRIC two-content-arm diamond before
        // declaring escape. Both arms hold gates and fall through to a common
        // merge; the true arm is controlled on the flag, the false arm on
        // ¬flag (the §2.5 `cqrt_x` bracket). φ dissolution is WP7's multi-φ
        // path keyed on the true-arm edge.
        BasicBlock *ArmT = nullptr, *ArmF = nullptr, *SymMerge = nullptr;
        if (matchSymmetricDiamond(Br, ArmT, ArmF, SymMerge)) {
          ControlRegion region;
          // Escape-guard + shadow-collect BOTH arms (PRD §5).
          if (armEscapesOrCollect(ArmT, SymMerge, region.Shadow))
            continue;  // diagnosed; region skipped.
          if (armEscapesOrCollect(ArmF, SymMerge, region.ShadowFalse))
            continue;  // diagnosed; region skipped.
          // Skip if either arm's body was already claimed by an enclosing
          // nested region (defensive; symmetric arms are normally fresh).
          bool AlreadyClaimed = false;
          for (Instruction *S : region.Shadow)
            if (plan.InShadow.count(S))
              AlreadyClaimed = true;
          for (Instruction *S : region.ShadowFalse)
            if (plan.InShadow.count(S))
              AlreadyClaimed = true;
          if (AlreadyClaimed)
            continue;

          // A classical-FP merge `φ` is a rotation angle dispatched under
          // quantum control (cwk). A CLEAN angle feed lowers as controlled-
          // rotation-by-difference (fix (b), reduceAngleDiamondPhi); record it
          // + its consuming rotations (which join InShadow so lowerRotations
          // skips them). A NON-clean / unlowerable-type φ stays diagnosed.
          {
            SmallVector<PHINode *, 2> AnglePhis;
            SmallVector<Instruction *, 4> AngleCons;
            if (PHINode *BadPhi =
                    classifyAngleMerge(SymMerge, taint, AnglePhis, AngleCons)) {
              diagnoseEscape(BadPhi, "rotation angle");
              continue;
            }
            for (PHINode *P : AnglePhis)
              region.AnglePhi.push_back(P);
            for (Instruction *C : AngleCons) {
              region.AngleConsumers.push_back(C);
              plan.InShadow.insert(C);
            }
          }

          region.Condition = Br->getCondition();
          region.Kind = ControlRegion::BranchRegion;
          region.Merge = &SymMerge->front();
          region.Pred = &BB;
          region.Arm = ArmT;        // true arm (flag).
          region.ArmFalse = ArmF;   // false arm (¬flag).
          region.MergeBB = SymMerge;
          region.Depth = 0;
          // A symmetric diamond may still be guarded by an `&&`/`||` flag
          // conjunction; record it so the flag machinery combines the
          // sub-compares (no-op for a plain compare).
          matchFlagConjunction(region.Condition, taint, region.CondA,
                               region.CondB, region.Conj);
          for (Instruction *S : region.Shadow)
            plan.InShadow.insert(S);
          for (Instruction *S : region.ShadowFalse)
            plan.InShadow.insert(S);
          plan.Regions.push_back(std::move(region));
          continue;
        }
        // No controllable shape (diamond/select/nested-AND/conjunction). If a
        // guarded arm ESCAPES (`ret`/`measure`/out-of-region) instead of
        // reconverging, this is "return/measure under quantum control" (PRD
        // line 108/309) — emit the loud diagnostic (refined in Phase 4.1).
        if (branchEscapes(Br))
          continue;
        // Safety net (epic invariant): the condition is TAINTED (checked above)
        // but the branch matched NO controllable shape and is not a clean
        // ret/measure escape — e.g. a quantum-controlled loop `break` or an
        // irreducible `goto` that `-O1` keeps as a `br i1` on the handle. Left
        // alone it would branch on the HANDLE id — a SILENT MISCOMPILE. Diagnose
        // loudly; the realized lowering of these escapes is Phase 4.1 (-aht.2).
        diagnoseEscape(Br, "control flow");
        continue;
      }

      // Escape guard + shadow collection in one arm walk (PRD §5).
      ControlRegion region;
      if (armEscapesOrCollect(Arm, MergeBB, region.Shadow))
        continue;  // diagnosed; region skipped.

      // Skip a diamond whose gate body was already claimed by an enclosing
      // nested region (the inner level of `if(a){if(b)gate;}`): its ops are in
      // `plan.InShadow`, and the enclosing region owns the single combined flag.
      bool AlreadyClaimed = false;
      for (Instruction *S : region.Shadow)
        if (plan.InShadow.count(S))
          AlreadyClaimed = true;
      if (AlreadyClaimed)
        continue;

      // A classical-FP merge `φ` is a rotation angle chosen under quantum
      // control via the diamond form (cwk). A CLEAN angle feed lowers as
      // controlled-rotation-by-difference (fix (b), reduceAngleDiamondPhi);
      // record it + its consuming rotations (which join InShadow so
      // lowerRotations skips them — the orchestrator lowers them). A non-clean
      // use, or an unlowerable angle type (vector/ptr/i128), stays diagnosed —
      // `dissolveBranchPhi` would otherwise miscompile it.
      {
        SmallVector<PHINode *, 2> AnglePhis;
        SmallVector<Instruction *, 4> AngleCons;
        if (PHINode *BadPhi =
                classifyAngleMerge(MergeBB, taint, AnglePhis, AngleCons)) {
          diagnoseEscape(BadPhi, "rotation angle");
          continue;
        }
        for (PHINode *P : AnglePhis)
          region.AnglePhi.push_back(P);
        for (Instruction *C : AngleCons) {
          region.AngleConsumers.push_back(C);
          plan.InShadow.insert(C);
        }
      }

      region.Condition = Br->getCondition();
      region.Kind = ControlRegion::BranchRegion;
      region.Merge = &MergeBB->front();  // the merge PHINode.
      region.Pred = &BB;
      region.Arm = Arm;
      region.MergeBB = MergeBB;
      region.ArmNegated = ArmIsFalse;  // false-successor arm ⇒ gates on ¬flag.
      region.Depth = 0;

      // WP5: if the branch condition is the `&&`/`||` flag-combination idiom
      // (PRD §2.5), record the conjunction kind + the two sub-compares so
      // `ControlFlag`/`FlagConjunction` combine them into one flag. Otherwise
      // `Conj` stays `ConjNone` and the WP3 plain-compare path is taken
      // unchanged.
      matchFlagConjunction(region.Condition, taint, region.CondA, region.CondB,
                           region.Conj);

      for (Instruction *S : region.Shadow)
        plan.InShadow.insert(S);
      plan.Regions.push_back(std::move(region));
    }
  }

  return plan;
}

}  // namespace cq
