// AbortParkEmit.cpp — see header. Phase 7.2 Increment 3: the abort/exit park
// cascade — the one genuinely-new emission of Phase 7.2 (PRD-7.2 §2.8 / §2.11-B,
// IMPLEMENTATION-PLAN-7.2 §5).
//
// Correctness rests on analytic state reasoning, NOT on `opt -verify` (Rule 2).
// The park is the no-value-select member of the user's park-cascade direction
// (`bd memories abort-exit-park-cascade`):
//
//   q in (|a⟩ + |b⟩)/√2,  flag = (q>k):  →  (|a⟩|0⟩_f + |b⟩|1⟩_f)/√2
//   ─cswap(flag, q, grave)→  the would-abort (flag=1) component is MOVED into the
//   graveyard, so q reads (|a⟩|0⟩_f + |0⟩|1⟩_f)/√2 (the flag=1 branch decoupled to
//   |0⟩) while grave holds |b⟩ on flag=1, frozen + inspectable forever.
//   ─tape_write(tape, flag)→  the abort marker is committed (truncate-at-
//   inspection). The sibling/downstream then runs UNCONTROLLED: because abort
//   TERMINATES there is no coherent downstream, so the flag=1 tail-garbage is
//   never observed and never dephases (hazard (i), §2.9). The graveyard + flag
//   are KEPT (GraveyardRails — never reverse-played/freed; a dirty free is a
//   hidden measurement, Rule 6).
//
// The park `cqrt_cswap` is emitted via `emitRoute` (self-bracketed for a ¬flag /
// FALSE-successor sink arm) and is NEVER threaded through `emitInverseChain` —
// `cqrt_cswap` arg-0 is the FLAG slot (EmitInverse.cpp:99-116, the swap-route
// seam): a handle threaded there is a verify-clean wrong unitary.

#include "AbortParkEmit.h"

#include "ArmAnalysis.h"        // comparePredLowerable
#include "CompareLowering.h"    // lowerCompareToFlag (flag mint)
#include "ControlPlan.h"        // ControlRegion / diagnoseUnderControl
#include "ControlledSymbols.h"  // xFn (the ¬flag bracket for the tape record)
#include "LiteralIntegrity.h"   // declineAddressTakenBlocks (bd 7udx)
#include "OpcodeSupport.h"      // abiWidthFromType / widthHasReversibleCopy
#include "SwapRouteEmit.h"      // emitRoute (the self-bracketed park cswap, Rule 14)
#include "TaintPropagation.h"   // TaintSet
#include "WidthDispatch.h"      // allocFn / tapeAllocFn / tapeWriteFn

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"

#include <algorithm>

using namespace llvm;

namespace cq {

namespace {

// Drop an erased instruction from every taint work-list that might still hold it
// (the §6.1 dangling-work-list hygiene). A per-TU mirror of the same helper in
// SwapRouteEmit / RegionFlatten (the house style for trivial taint maintenance).
// Idempotent.
void scrubTaint(Instruction *I, TaintSet &taint) {
  taint.Tainted.erase(I);
  taint.BirthOrder.erase(I);
  taint.StaleDeclined.erase(I);
  if (auto *CI = dyn_cast<CallInst>(I)) {
    auto &PC = taint.PhiCalls;
    PC.erase(std::remove(PC.begin(), PC.end(), CI), PC.end());
  }
}

// Loud bail for a detection-guaranteed shape that did not hold at emit time. A
// silently skipped accepted region would hand the tainted `br` to the backend as
// classical control over quantum state (the one unforgivable bug, Rule 1). The
// abort-park plan always sets `Condition` (an Instruction), so the first arm
// always fires.
void bailLoud(const ControlRegion &R) {
  if (auto *A = dyn_cast_or_null<Instruction>(R.Condition))
    diagnoseUnderControl(A, "control flow");
  else if (R.Merge)
    diagnoseUnderControl(R.Merge, "control flow");
}

// The recognized PROCESS-TERMINATING noreturn sinks (PRD-7.2 §2.11-B). EXACT
// names, DECLARATION-only (a user-defined in-module body of the same name is NOT
// the libc sink — parking its possibly-non-terminating body would be wrong, the
// IOSink isRecognizedIOSink discipline). Recognition is by NAME, not the noreturn
// ATTRIBUTE: an arbitrary `__attribute__((noreturn))` user function may DIVERGE
// (infinite loop) rather than terminate — that is the §2.11-C-ii case deferred to
// 7.3/7.4, NOT a park. Every name here TERMINATES the process, which is what makes
// "no coherent downstream" (§2.8) hold. `@llvm.trap`/`@llvm.ubsantrap` are matched
// by name (their call site may carry no explicit noreturn attr — only the decl
// does). Over-decline is safe; the attribute-based widening is reopenable.
bool isRecognizedNoreturnSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  if (!Callee || !Callee->isDeclaration())
    return false;  // indirect call / in-module body — never a recognized sink.
  if (CI->hasOperandBundles())
    return false;  // an operand bundle is an off-pattern read we do not model.
  StringRef N = Callee->getName();
  return N == "abort" || N == "exit" || N == "_exit" || N == "_Exit" ||
         N == "quick_exit" || N == "__assert_fail" || N == "__assert_rtn" ||
         N == "llvm.trap" || N == "llvm.ubsantrap";
}

// Is `Arm` a recognized noreturn-sink arm of the diamond rooted at `Pred`?
// EXACTLY {recognized-sink call, `unreachable`}: single-pred(`Pred`), terminated
// by `unreachable`, whose sole non-terminator instruction is a recognized
// noreturn-sink `CallInst` that reads NO tainted value (its args are classical)
// and whose result is unused. Returns the sink call in `*SinkOut` on a match. The
// size-2 requirement keeps an arm carrying ANY other op (a tainted gate, a
// computed sink arg) off-pattern (over-decline is safe) — clang -O1 emits exactly
// `{tail call void @abort(); unreachable}` for the verified shape.
bool isNoreturnSinkArm(BasicBlock *Arm, const BasicBlock *Pred,
                       const TaintSet &Taint, CallInst **SinkOut) {
  if (!Arm || Arm->getSinglePredecessor() != Pred)
    return false;
  if (!isa<UnreachableInst>(Arm->getTerminator()))
    return false;
  if (Arm->size() != 2)
    return false;  // exactly {sink call, unreachable}; anything else is off-pattern.
  auto *Sink = dyn_cast<CallInst>(&Arm->front());
  if (!Sink || !isRecognizedNoreturnSink(Sink))
    return false;
  if (!Sink->use_empty())
    return false;  // a USED sink result (e.g. as a value) is off-pattern.
  for (const Value *Arg : Sink->args())
    if (Taint.Tainted.count(const_cast<Value *>(Arg)))
      return false;  // a tainted sink arg (e.g. exit(q)) — out of scope, decline.
  *SinkOut = Sink;
  return true;
}

// Backward "does this value's lineage carry a relative phase (an Rz / `cq_phi`)?"
// walk — the §2.6 deferred-interaction fence. A per-TU mirror of
// `SelectClassify`'s `operandCarriesPhase` (TU-local there; the house style
// permits the trivial duplicate). A `cq_theta` (Ry) result is a real-amplitude
// basis superposition (no relative phase) and the walk STOPS at it (its operands
// are the classical seed + angle, untainted); a `cq_phi` in the lineage is the
// phase carrier. Over-decline-safe (any phi in the tainted lineage flags it).
bool lineageCarriesPhase(Value *Op, const TaintSet &Taint) {
  // ---- THE REGISTER-FREE BRANCH PHASE (bd 3qlq Inc 1 part A, Rule-13 round-1
  // finding F-L5-6 — a latent WIDENING). Identical clause and identical reason
  // as in `ControlDetect::retLineageCarriesPhase` and
  // `LoopLowering::breakLineageCarriesPhase`: the `cq_phi_` prefix row below
  // went vacuous with the surface change, and the property it protected became
  // unrepresentable in the SSA lineage. See `TaintPropagation.h`.
  if (auto *OpI = dyn_cast<Instruction>(Op))
    if (functionCarriesBranchPhase(OpI->getFunction(), Taint))
      return true;

  SmallVector<Value *, 8> Work;
  SmallPtrSet<Value *, 16> Visited;
  Work.push_back(Op);
  Visited.insert(Op);
  while (!Work.empty()) {
    Value *V = Work.pop_back_val();
    if (auto *CI = dyn_cast<CallInst>(V)) {
      const Function *F = CI->getCalledFunction();
      // ⚠ VACUOUS SINCE bd test_C_libtooling-3qlq Inc 1 — the `@cq_phi_<sfx>` family is
      // RETIRED and `StringRef("cq_phi").starts_with("cq_phi_")` is FALSE, so the
      // register-free `void @cq_phi(double)` never reaches here. Kept, not deleted
      // (PRD §6.2 row P6); see the note at `ArmClassify.cpp`'s `isPhiCall` for why
      // widening it would read the wrong operand.
      if (F && F->getName().starts_with("cq_phi_"))
        return true;  // an Rz (cq_phi) in the lineage — a relative-phase carrier.
    }
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      continue;  // an argument / constant root — basis, not a phase.
    for (Value *In : I->operands())
      if (Taint.Tainted.count(In) && Visited.insert(In).second)
        Work.push_back(In);
  }
  return false;
}

// One lazy stdout tape per function, SHARED across every I/O-lowering step via
// `taint.IOTapeForFn` (PRD-7.6 §2.4 — a function with a controlled `if(q)printf`
// AND a controlled abort must append to ONE tape, never two). A per-TU mirror of
// `IOSinkLowering::ioTapeFor` (TU-local there); the SHARED `IOTapeForFn` map IS
// the one-tape-per-function invariant — whichever step runs first creates the
// tape, the rest read the cached handle, so the per-TU copies cannot diverge. The
// alloc lands at the entry's first insertion point so it DOMINATES every write;
// the tape handle is a CLASSICAL resource token (never tainted, never a rail).
Value *ioTapeFor(Function *F, WidthDispatch &wd, TaintSet &taint,
                 const DebugLoc &DL) {
  auto It = taint.IOTapeForFn.find(F);
  if (It != taint.IOTapeForFn.end())
    return It->second;
  IRBuilder<> B(&*F->getEntryBlock().getFirstInsertionPt());
  CallInst *Tape = B.CreateCall(wd.tapeAllocFn(), {}, "tape");
  if (DL)
    Tape->setDebugLoc(DL);
  taint.IOTapeForFn[F] = Tape;
  return Tape;
}

// The tainted operand of an HL compare (exactly one operand tainted), or null if
// the compare is not HL (Q+Q or all-classical). Shared by the classifier and the
// emitter so both derive the routed handle the SAME way.
Value *hlTaintedOperand(CmpInst *Cond, const TaintSet &Taint) {
  if (Cond->getNumOperands() < 2)
    return nullptr;
  Value *A = Cond->getOperand(0), *B = Cond->getOperand(1);
  bool TA = Taint.Tainted.count(A) != 0, TB = Taint.Tainted.count(B) != 0;
  if (TA == TB)
    return nullptr;  // Q+Q or all-classical — not an HL flag mint.
  return TA ? A : B;
}

// Every tainted SSA value with a user in a block FORWARD-reachable from `Sibling`
// (the uncontrolled remainder). These are the quantum registers live across the
// park: the routed handle `Q` is the ONLY one the park preserves, so any OTHER
// live register is unparked (decline), and a phase-class one beside the park arm
// is the §2.6 deferred interaction (decline). The condition compare needs no
// exclusion here — `classifyAbortPark`'s `Cond->hasOneUse()` gate already
// guarantees its sole user is the branch (in `Pred`, never in the remainder).
void collectLiveRemainderRegs(BasicBlock *Sibling, const TaintSet &Taint,
                              SmallVectorImpl<Value *> &Out) {
  SmallPtrSet<BasicBlock *, 8> Reachable;
  SmallVector<BasicBlock *, 8> Work;
  Reachable.insert(Sibling);
  Work.push_back(Sibling);
  while (!Work.empty()) {
    BasicBlock *BB = Work.pop_back_val();
    for (BasicBlock *Succ : successors(BB))
      if (Reachable.insert(Succ).second)
        Work.push_back(Succ);
  }
  for (Value *V : Taint.Tainted) {
    for (User *U : V->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (I && Reachable.count(I->getParent())) {
        Out.push_back(V);
        break;
      }
    }
  }
}

}  // namespace

AbortParkDisp classifyAbortPark(BranchInst *BI, TaintSet &Taint,
                                ControlRegion &R) {
  // Caller guarantees: `BI` is a conditional branch on a tainted condition.
  BasicBlock *Pred = BI->getParent();
  BasicBlock *S0 = BI->getSuccessor(0);  // cond == true
  BasicBlock *S1 = BI->getSuccessor(1);  // cond == false

  // Which successor is the recognized noreturn-sink arm? Orientation A — the sink
  // arm is the TRUE successor (`if(q>k) abort();`), so the abort fires on flag=1
  // (un-negated). Orientation B — clang -O1 swapped the successors (Rule 9), so
  // the sink arm is the FALSE successor and the abort fires on flag=0 (the park
  // cswap + tape record ride the self-inverse `cqrt_x` ¬flag bracket).
  CallInst *Sink = nullptr;
  BasicBlock *ArmBB = nullptr, *Sibling = nullptr;
  bool Negated = false;
  if (isNoreturnSinkArm(S0, Pred, Taint, &Sink)) {
    ArmBB = S0;
    Sibling = S1;
    Negated = false;
  } else if (isNoreturnSinkArm(S1, Pred, Taint, &Sink)) {
    ArmBB = S1;
    Sibling = S0;
    Negated = true;
  } else {
    return AbortParkDisp::NotApplicable;  // not a park — fall through to recoverRegion.
  }

  // From here this step OWNS the shape (an unmistakable `unreachable`-after-
  // recognized-sink arm): every unmet precondition is a LOUD decline, never
  // NotApplicable (a silent skip would hand the tainted `br` to the backend as
  // classical control over quantum state, Rule 1).
  auto *Cond = dyn_cast<CmpInst>(BI->getCondition());
  if (!Cond || !comparePredLowerable(Cond)) {
    diagnoseUnderControl(BI, "control flow");  // no lowerable flag-mint template.
    return AbortParkDisp::Declined;
  }
  // The condition compare must be used ONLY by the branch (Rule-13 hardening). A
  // SECOND use is a DATA use of the compare somewhere in the program: after the
  // CFG surgery erases the branch, that surviving compare becomes a pure
  // data-position compare which `lowerOps` recomputes AT ITS POSITION — and if
  // that position is post-park it reads the PARKED routed handle, a verify-clean
  // wrong value (the data use intended the PRE-park `(q>k)`). The park mints its
  // OWN flag and has no shared-condition-flag (ziov) machinery, so DECLINE rather
  // than recompute. This makes the guard sound INDEPENDENT of the `-O1` fold that
  // happens to value-propagate such a compare on the surviving edge today (Rule 10
  // — never lean on an incidental canonicalization); over-decline is safe. Reuses
  // the existing `condition used outside the branch` dialect (SwapRouteEmit's ziov
  // value-arm decline).
  if (!Cond->hasOneUse()) {
    diagnoseUnderControl(Cond, "condition used outside the branch");
    return AbortParkDisp::Declined;
  }
  Value *Q = hlTaintedOperand(Cond, Taint);
  if (!Q) {  // Q+Q (both operands tainted) — no single HL flag mint.
    diagnoseUnderControl(Cond, "control flow");
    return AbortParkDisp::Declined;
  }
  // The routed handle width must have a real allocator + flag-mint template
  // (`widthHasReversibleCopy` = the {i1,i8,i16,i32,i64} integer surface, EXACTLY
  // the IOSink/select fence; an i128 / fp width has no `cqrt_alloc`/copy and must
  // decline, never mint a phantom).
  if (!widthHasReversibleCopy(abiWidthFromType(Q->getType()))) {
    diagnoseUnderControl(Cond, "control flow");
    return AbortParkDisp::Declined;
  }

  // §2.6 phase fence + sole-live-register guard. The park preserves ONLY the
  // routed handle `Q`. Scan the tainted registers live in the remainder
  // (reachable from the sibling): a phase-class one (Q itself, or any other
  // escaping value beside the park arm) is the §2.6 deferred park-vs-dephasing
  // interaction → conservatively DECLINE `phase-class value escaping` (do NOT
  // assert the park preserves the phase). Any OTHER (value-class) live register is
  // unparked → conservatively DECLINE (over-decline is safe; the multi-register
  // park is reopenable). The verified -O1 shape (`if(q>5)abort(); return q;`) has
  // `Q` as the sole live register, value-class, so it accepts.
  SmallVector<Value *, 4> LiveRegs;
  collectLiveRemainderRegs(Sibling, Taint, LiveRegs);
  for (Value *V : LiveRegs)
    if (lineageCarriesPhase(V, Taint)) {
      diagnoseUnderControl(Cond, "phase-class value escaping");
      return AbortParkDisp::Declined;
    }
  for (Value *V : LiveRegs)
    if (V != Q) {
      diagnoseUnderControl(Cond, "control flow");  // an unparked live register.
      return AbortParkDisp::Declined;
    }

  // ACCEPT. Populate the by-identity plan. `Merge`/`MergeBB`/`ArmFalse` stay null:
  // the sink arm has nothing to merge, and the sibling/remainder SURVIVES (it is
  // NOT a doomed block — the emitter erases only `Arm`). `Condition` (an
  // Instruction) is set so the cross-region pre-flight's first diagnose arm always
  // fires (never a bare-return silent accept, the one unforgivable bug).
  R.Kind = ControlRegion::AbortPark;
  R.Pred = Pred;
  R.Arm = ArmBB;
  R.Condition = Cond;
  R.ArmNegated = Negated;
  return AbortParkDisp::Accept;
}

void emitAbortParkRegion(const ControlRegion &R, WidthDispatch &wd,
                         ControlledSymbols &csyms, TaintSet &taint) {
  auto *Cond = dyn_cast_or_null<CmpInst>(R.Condition);
  if (!Cond || !R.Pred || !R.Arm)
    return bailLoud(R);
  auto *BI = dyn_cast<BranchInst>(R.Pred->getTerminator());
  if (!BI || !BI->isConditional())
    return bailLoud(R);
  // The sibling is the successor that is NOT the doomed sink arm — the
  // uncontrolled remainder downstream runs into it.
  BasicBlock *Sibling =
      BI->getSuccessor(0) == R.Arm ? BI->getSuccessor(1) : BI->getSuccessor(0);

  // Re-derive the routed handle Q (the condition's sole tainted operand) — a pure
  // consumer of the by-identity plan, the same derivation the classifier proved.
  Value *Q = hlTaintedOperand(Cond, taint);
  if (!Q)
    return bailLoud(R);

  StringRef Abi = abiWidthFromType(Q->getType());
  Type *RailTy = Abi.empty() ? nullptr : wd.llvmWidthType(Abi);
  FunctionCallee Alloc = Abi.empty() ? FunctionCallee() : wd.allocFn(Abi);
  // The abort flag is recorded as a 1-bit tape entry (the truncate-at-inspection
  // marker, PRD-7.2 §2.8) — `cqrt_tape_write_i1`, NO new frozen symbol (it already
  // exists, 7.6). The 1-bit width is the flag's LOGICAL width; the handle is i32.
  FunctionCallee TapeWrite = wd.tapeWriteFn("i1");
  if (!RailTy || !Alloc || !TapeWrite)
    return bailLoud(R);

  const DebugLoc DL = Cond->getDebugLoc();
  IRBuilder<> B(BI);  // the park stream lands in Pred, before the conditional br.
  auto stamp = [&DL](CallInst *C) {
    if (DL)
      C->setDebugLoc(DL);
  };

  // 1. Mint the abort flag from the PRE-park routed handle — the flag must read
  //    q0 (the live value), so this precedes the park cswap that swaps q.
  //    (Track A.1, F-A1R2-1) `Unruled`: `classifyAbortPark` is a PRE-PEEL in
  //    `handleBranchRegion` — it pushes the region and returns before
  //    `classifyArms` ever reaches `condWireDisposition`, and this file contains
  //    no wire walk of its own (MEASURED: `grep -n findNonDiagonalWireGate
  //    ir-pass/src/AbortParkEmit.cpp` is empty). So NO round-1 ruling exists for
  //    this compare and `reverifyCmpCondReads` must exempt nothing.
  Value *Flag = lowerCompareToFlag(Cond, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/BI,
                                   /*negate=*/false, /*railToStrip=*/nullptr,
                                   /*readKind=*/CondReadKind::Unruled);
  if (!Flag)
    return;  // lowerCompareToFlag already diagnosed (unsupported width / Q+Q).

  // 2. Alloc the |0> graveyard rail (one rail; the sole live register is Q).
  CallInst *Grave = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "grave");
  stamp(Grave);

  // 3. PARK q into the graveyard under the flag — `cqrt_cswap(flag, q, grave)`,
  //    self-bracketed for a ¬flag (FALSE-successor) sink arm via `emitRoute`
  //    (Rule 14: the swap-route router; NEVER threaded through `emitInverseChain`,
  //    whose Args[0] handle in the FLAG slot is a verify-clean wrong unitary). The
  //    would-abort component moves aside; q reads |0> there, decoupled from the
  //    uncontrolled downstream.
  emitRoute(B, csyms, Flag, Q, Grave, R.ArmNegated, DL);

  // 4. RECORD the abort indicator on the shared tape (1 = aborted here). For a
  //    ¬flag (FALSE-successor) sink the recorded value must be the abort
  //    CONDITION, not its complement — the self-inverse `cqrt_x` bracket flips the
  //    flag around the write so `cqrt_tape_write_i1` commits the abort indicator.
  //    The bracket encloses ONLY the write (a mis-span is verify-clean-invisible —
  //    pinned by an ordered CHECK).
  Value *Tape = ioTapeFor(R.Pred->getParent(), wd, taint, DL);
  if (R.ArmNegated)
    stamp(B.CreateCall(csyms.xFn(), {Flag}));
  CallInst *TW = B.CreateCall(TapeWrite, {Tape, Flag});
  stamp(TW);
  if (R.ArmNegated)
    stamp(B.CreateCall(csyms.xFn(), {Flag}));

  // 5. Bookkeep the KEPT rails (plan §2-A). The graveyard rail joins
  //    `taint.Tainted` (so downstream classifies it as a quantum handle) AND the
  //    new `taint.GraveyardRails` (subtracted at BOTH uncompute spine sites — so a
  //    parked entangled rail is NEVER selected as a data terminal nor reversed/
  //    freed as a DAG ancestor; a dirty free is a hidden measurement, Rule 6). The
  //    flag joins `GraveyardRails` too (defense-in-depth: lowerCompareToFlag does
  //    not taint it today, but the explicit image must not rest on that). The tape
  //    out-handle is an `OutputRails` member (the 7.6 keep-discipline).
  taint.Tainted.insert(Grave);
  taint.GraveyardRails.insert(Grave);
  taint.BirthOrder[Grave] = taint.NextBirth++;
  taint.GraveyardRails.insert(Flag);
  taint.Tainted.insert(TW);
  taint.OutputRails.insert(TW);
  taint.BirthOrder[TW] = taint.NextBirth++;

  // 6. CFG surgery — the downstream runs UNCONTROLLED: redirect Pred straight to
  //    the sibling, then erase the now-unreachable noreturn arm and the dead
  //    condition compare. There is NO flag strip (the park changed q, so
  //    `icmp_inv(q)` would not zero the flag) and NO graveyard/flag free (Rule 6).
  IRBuilder<> B2(BI);
  B2.CreateBr(Sibling);  // the new unconditional terminator (lands before BI).
  scrubTaint(BI, taint);
  BI->eraseFromParent();
  if (Cond->use_empty()) {
    scrubTaint(Cond, taint);
    Cond->eraseFromParent();
  }
  // The sink arm has a single predecessor (the now-rewired Pred) and never
  // branched to the sibling, so it is unreachable and references nothing live —
  // erase it whole (the `unreachable` + the dead sink call go with it).
  //
  // bd 7udx — nothing else in this function erases a BasicBlock, so the guard
  // sits immediately before the only one. `BasicBlock::~BasicBlock()` replaces
  // every `BlockAddress` of a destroyed block with `inttoptr (i32 1 to ptr)`
  // MODULE-WIDE, silently rewriting a compared-against address to `i32 1` on a
  // WELL-DEFINED source (no UB, no refinement argument to excuse it).
  if (declineAddressTakenBlocks({R.Arm}, R.Arm->getTerminator()))
    return;
  R.Arm->eraseFromParent();
}

}  // namespace cq
