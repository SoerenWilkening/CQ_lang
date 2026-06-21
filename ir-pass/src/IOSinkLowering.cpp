// IOSinkLowering.cpp — see header. Phase 7.6 reversible I/O output tape.
//
// Lowers a tainted `printf` / `putchar` to an append-only output tape: one lazy
// `cqrt_tape_alloc()` per function, then one `cqrt_tape_write_<W>(tape, src)`
// per tainted integer-scalar argument. Each returned `out_handle` is a KEPT |0>
// output rail registered in `taint.OutputRails` (never freed, never uncomputed
// — a Bennett output tape). The original sink call is erased. NO measurement is
// ever inserted (Rule 5); the measurement is deferred to tape inspection.
//
// Runs BEFORE `lowerRotations`, so a sink operand is still the pre-RAUW tainted
// SSA value (the rotation RAUW then rewrites each emitted `src` arg to its i32
// handle — the same launder every other pre-rotation emitter relies on). Any
// arg shape it cannot PROVE lowerable declines LOUDLY (opt exits non-zero), so
// the `declineTaintEscapes` carve never becomes a silent accept (Prime
// Directive: over-declining is safe, over-accepting is a silent miscompile).

#include "IOSinkLowering.h"

#include "CompareLowering.h"    // lowerCompareToFlag (flag mint + _inv strip)
#include "ControlPlan.h"        // ControlRegion (for flattenRegion)
#include "ControlShape.h"       // uncondSucc (void-arm diamond recovery, Rule 14)
#include "ControlledSymbols.h"  // tapeWriteControlledFn / xFn
#include "OpcodeSupport.h"
#include "RegionFlatten.h"      // flattenRegion (swap-route diamond flattener)
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstrTypes.h"  // CmpInst
#include "llvm/IR/Instructions.h"

#include <utility>

using namespace llvm;

namespace cq {

namespace {

// The exact diagnostic strings IOSinkLowering owns (PRD-7.6 §3 deliverable 5).
// The negative LIT fixtures mirror each CHARACTER-FOR-CHARACTER (Rule 12):
//   * lowering_reject_io_fp_arg.ll      → kMsgIOArg (a tainted `%f` double)
//   * lowering_reject_io_i128_arg.ll    → kMsgIOArg (a tainted i128 scalar)
//   * lowering_reject_io_result_used.ll → kMsgIOResult
constexpr char kMsgIOArg[] =
    "cq I/O output sink: tainted argument is not a lowerable integer scalar";
constexpr char kMsgIOResult[] =
    "cq I/O output sink: result of a tainted output call is used";
constexpr char kMsgIOFanout[] =
    "cq I/O output sink: tainted argument has continued lineage (only a "
    "terminal or measured value may be taped)";
// Increment 2 control-shape decline (PRD-7.6 §5): a tainted-condition I/O sink
// whose surrounding control flow is NOT a Tier-0 single-sink `if(q)` diamond —
// a compound/non-comparison condition (`&&` `select i1`), a deeper / non-2-pred
// (nested or shared) merge, or an arm with more than the one sink + branch.
// Mirrored char-for-char by lowering_reject_io_controlled_{compound_cond,nested}.
constexpr char kMsgIOControl[] =
    "cq I/O output sink: conditional output is not a lowerable single-sink "
    "if(q) diamond";

// Loud `DiagnosticInfoUnsupported(DS_Error)` with the offending call's `!dbg`
// (source-located; `opt` exits non-zero, which the negative fixtures invert
// with `RUN: not`). Same idiom as `diagnoseEscape` / `FreePoint::diagnose`.
void diagnose(Instruction *Where, StringRef Msg) {
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

// A direct `printf` / `putchar` call (EXACT name — never a `starts_with`
// prefix, so a user `printf_helper` is not a sink; the cq_theta_evil hazard).
// Matches the `declineTaintEscapes` carve (TaintPropagation.cpp 1d-Phase7.6).
bool isRecognizedIOSink(const CallInst *CI) {
  const Function *Callee = CI->getCalledFunction();
  if (!Callee)
    return false;  // indirect call — never a recognized sink
  // The libc printf/putchar is always an extern DECLARATION; a user-defined
  // in-module body of the same name is NOT the print sink (it is owned by the
  // Phase-6 specializer / the escape path) — taping it would silently erase the
  // user's call (Rule-13 R5 over-accept). A sink carrying OPERAND BUNDLES is
  // off-pattern: a tainted bundle operand is read by `readsTaintedValue` but not
  // by `CI->args()`, so carving without lowering it is the opaque-call silent
  // miscompile (Rule-13 R3) — decline the whole call instead. EXACT name only.
  if (!Callee->isDeclaration() || CI->hasOperandBundles())
    return false;
  StringRef N = Callee->getName();
  return N == "printf" || N == "putchar";
}

// Does `CI` read a tainted VALUE in an argument position? The called operand of
// a recognized sink is the `@printf`/`@putchar` Function (never tainted), so a
// tainted argument is the only way this is true.
bool readsTaintedArg(const CallInst *CI, const TaintSet &taint) {
  for (const Value *Arg : CI->args())
    if (taint.Tainted.count(const_cast<Value *>(Arg)))
      return true;
  return false;
}

// A taped value's lineage must be CLOSED at the sink: every user of `V` must be
// a recognized I/O sink or a `cq_measure`. If `V` feeds further tainted
// computation (a data op, a cast, a `cq_phi` continuation, a ret/store, a user
// call), it is a NON-TERMINAL rail whose DAG the whole-DAG uncompute spine
// reverses — and that reversal, anchored at the dead terminal (which may PRECEDE
// this sink), can reverse-play and `cqrt_free` V's rail BEFORE the tape write
// reads it: a verify-clean use-after-free that records |0> instead of V's value
// (the central Rule-13 R2 hazard). Decline LOUDLY (PRD-7.6 §6.3 fan-out, the
// Rule-8 linear-lineage bail). Pre-`lowerRotations`: data ops are still stock
// BinaryOperator/CastInst (non-call users); a measure is a `cq_measure_` call; a
// terminal-or-measured value's only users are sinks + measures, so its rail is
// reversed (if dead) at ITS OWN free point, which post-dominates the tape write.
// `allowedExtraUser`, when non-null, is one additional NON-call user permitted as
// a co-user of `V` without tripping the fan-out bail — used by the CONTROLLED
// path to whitelist the tainted-condition COMPARE that reads the taped value `V`
// (e.g. `if (q > 5) printf("%d", q)`, where q is BOTH the condition operand and
// the taped arg). That compare is minted into the control flag and stripped in
// place (the flag is freed; the original compare is erased by the flatten) —
// PRESERVING V, exactly the shipped SelectMergeEmit pattern — so it is not a
// lineage continuation. Every OTHER non-call user (a real data op / cast /
// cq_phi continuation / ret / store) still bails (the Rule-13 R2 use-after-free).
bool tapedLineageClosed(const Value *V, const Value *allowedExtraUser = nullptr) {
  for (const User *U : V->users()) {
    if (U == allowedExtraUser)
      continue;  // the controlled-path condition compare — preserves V (above).
    const auto *CU = dyn_cast<CallInst>(U);
    if (!CU)
      return false;  // op/cast/ret/store/phi — V continues or escapes the lineage
    if (isRecognizedIOSink(CU))
      continue;  // another printf/putchar reading V (a legitimate multi-emit of V)
    const Function *Callee = CU->getCalledFunction();
    if (!Callee)
      return false;  // indirect call — unprovable
    StringRef N = Callee->getName();
    if (N.starts_with("cq_measure_"))
      continue;  // a measure owns the rail (no reversal) — a safe co-user
    if (N.starts_with("cqrt_tape_write_"))
      continue;  // a tape write ALREADY emitted for V earlier this pass (V is
                 // taped by >1 sink — a legitimate multi-emit; the write is a
                 // sink that preserves V, not a lineage continuation)
    return false;  // any other call (cq_phi continuation, a user call) — fan-out
  }
  return true;
}

// One lazy stdout tape per function, SHARED across the controlled and
// uncontrolled I/O-lowering steps via `taint.IOTapeForFn` (PRD-7.6 §2.4 — a
// function with both must append to ONE tape, never two). The `cqrt_tape_alloc`
// is inserted at the function entry's first insertion point so it DOMINATES
// every tape write; the handle is a CLASSICAL resource token (never tainted,
// never an OutputRails member).
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

// Validate a recognized sink's arguments and collect the tainted integer-scalar
// targets (in arg order), SHARED by the uncontrolled and controlled emitters
// (Rule 14). A tainted arg must be an integer scalar with a reversible-copy
// width {i1,i8,i16,i32,i64}; an fp (`%f`), i128, vector or pointer tainted arg
// DECLINES (kMsgIOArg); a non-constant classical co-arg DECLINES (a runtime
// value / side effect we would silently drop); a constant classical arg (the
// format-string ptr / a literal) is DROPPED. Every target must additionally have
// CLOSED lineage — never a non-terminal rail the uncompute spine reverse-plays
// out from under the tape write (kMsgIOFanout, the Rule-8 linear-lineage bail).
// Returns true with `Targets` populated (non-empty) on success; false after
// firing the precise loud decline on `Sink`. PRD-7.6 §2.6 / §6.3.
bool collectTapeTargets(CallInst *Sink, const TaintSet &taint,
                        SmallVectorImpl<std::pair<Value *, StringRef>> &Targets,
                        const Value *allowedExtraUser = nullptr) {
  for (Value *Arg : Sink->args()) {
    if (taint.Tainted.count(Arg)) {
      if (Arg->getType()->isFPOrFPVectorTy()) {
        diagnose(Sink, kMsgIOArg);
        return false;
      }
      StringRef Abi = abiWidthFromType(Arg->getType());
      if (Abi.empty() || !widthHasReversibleCopy(Abi)) {
        diagnose(Sink, kMsgIOArg);
        return false;
      }
      Targets.emplace_back(Arg, Abi);
    } else if (!isa<Constant>(Arg)) {
      diagnose(Sink, kMsgIOArg);
      return false;
    }
  }
  if (Targets.empty()) {
    // A recognized sink reached us reading a tainted arg / under tainted
    // control, so a tainted target was expected — reaching here means it was
    // neither targeted nor declined (a logic hole). Decline rather than drop.
    diagnose(Sink, kMsgIOArg);
    return false;
  }
  for (auto &T : Targets)
    if (!tapedLineageClosed(T.first, allowedExtraUser)) {
      diagnose(Sink, kMsgIOFanout);
      return false;
    }
  return true;
}

}  // namespace

void lowerIOSinks(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // 1. Collect recognized sinks reading a tainted arg, in module order. Collect
  //    FIRST (do not mutate the IR while walking it). A classical-only
  //    `printf`/`putchar` (no tainted arg) is NOT collected — it stays
  //    byte-untouched (passthrough), exactly as before 7.6.
  SmallVector<CallInst *, 8> Sinks;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I))
          if (isRecognizedIOSink(CI) && readsTaintedArg(CI, taint))
            Sinks.push_back(CI);
  }
  if (Sinks.empty())
    return;

  SmallVector<Instruction *, 8> ToErase;
  for (CallInst *Sink : Sinks) {
    // 2. The sink's RESULT must be unused — we ERASE the call. A used result
    //    (`int n = printf(...)`, or a result re-entering taint) cannot be
    //    cleanly dropped: decline LOUDLY (PRD-7.6 §3, the result-re-entering
    //    decline). `putchar`/`printf` results are normally ignored.
    if (!Sink->use_empty()) {
      diagnose(Sink, kMsgIOResult);
      continue;
    }

    // 3. Validate every argument and collect the tainted integer-scalar targets
    //    (the shared `collectTapeTargets`, Rule 14: fp/i128/non-scalar →
    //    kMsgIOArg, a non-constant classical co-arg → kMsgIOArg, a non-terminal
    //    rail → kMsgIOFanout; a constant classical arg is dropped). On any
    //    failure it has already fired the precise loud decline.
    SmallVector<std::pair<Value *, StringRef>, 4> Targets;
    if (!collectTapeTargets(Sink, taint, Targets))
      continue;

    // 4. APPEND each tainted target to the tape. The tape write reads the
    //    still-tainted `src` (pre-RAUW); the rotation pass later rewrites that
    //    operand to its i32 handle. The returned `out_handle` is a KEPT output
    //    rail: it joins `Tainted` (so any downstream classifies it as quantum)
    //    and `OutputRails` (so the spine never reverses/frees it — §2.5), with
    //    a BirthOrder slot for LIFO ordering. The write is a recognized SINK
    //    (ChainWalk::isOutputSink), so `src`'s own lineage still uncomputes
    //    normally through the Phase-5 spine (Bennett copy-out, §2.4).
    Value *Tape = ioTapeFor(Sink->getFunction(), wd, taint, Sink->getDebugLoc());
    IRBuilder<> B(Sink);  // every tape write lands immediately before the sink
    const DebugLoc DL = Sink->getDebugLoc();
    bool Bad = false;
    for (auto &T : Targets) {
      FunctionCallee TW = wd.tapeWriteFn(T.second);
      if (!TW) {
        // widthHasReversibleCopy already proved a copy width exists, so this is
        // unreachable; guard defensively rather than mint a null call.
        diagnose(Sink, kMsgIOArg);
        Bad = true;
        break;
      }
      CallInst *Out = B.CreateCall(TW, {Tape, T.first});
      if (DL)
        Out->setDebugLoc(DL);
      taint.Tainted.insert(Out);
      taint.OutputRails.insert(Out);
      taint.BirthOrder[Out] = taint.NextBirth++;
    }
    if (Bad)
      continue;

    // 5. Erase the original sink. Its result is unused (step 2), so no RAUW; it
    //    is not itself a tainted value, so no taint-set scrub is needed.
    ToErase.push_back(Sink);
  }

  for (Instruction *I : ToErase)
    I->eraseFromParent();
}

namespace {

// A recovered Tier-0 controlled-I/O candidate: a tainted-condition `br i1` whose
// taken arm CONTAINS a recognized I/O sink (so the shape is OWNED by this step —
// lower it or decline it LOUDLY, never a silent skip that hands a tainted `br` to
// the backend, Rule 1). All identities are captured by SSA value/block identity
// BEFORE any mutation (Rule 9; the block-lifetime hazard).
struct CtrlIOCandidate {
  BranchInst *BI;       // the tainted-condition branch in `Pred`
  CmpInst *Cond;        // the comparison, or null for a compound/non-compare cond
  CallInst *Sink;       // the recognized I/O sink in `Arm`
  BasicBlock *Pred;     // the branch block (survives the flatten)
  BasicBlock *Arm;      // the single-sink arm (erased by the flatten)
  BasicBlock *Merge;    // the join (erased by the flatten)
  bool Negated;         // Rule 9: the arm is the FALSE successor (¬flag bracket)
};

// The recognized I/O sink in `Arm`, or null if `Arm` holds none. Used to decide
// whether a tainted-condition `br` is an I/O-sink shape this step OWNS.
CallInst *armIOSink(BasicBlock *Arm) {
  for (Instruction &I : *Arm)
    if (auto *CI = dyn_cast<CallInst>(&I))
      if (isRecognizedIOSink(CI))
        return CI;
  return nullptr;
}

}  // namespace

void lowerControlledIOSinks(Module &M, WidthDispatch &wd, TaintSet &taint) {
  // 1. COLLECT candidate void-arm diamonds (pure analysis; capture identities
  //    BEFORE any mutation). A candidate is a tainted-condition `br i1` whose
  //    taken arm holds a recognized I/O sink and reconverges directly at the
  //    straight-through successor (the merge has NO phi — the sink result is
  //    discarded — so `recoverRegion` itself returns OffPattern; this step owns
  //    the phi-less I/O shape detection never accepts). Both polarities (Rule 9:
  //    clang -O1 makes the gate arm the FALSE successor for the `!=` shape).
  SmallVector<CtrlIOCandidate, 4> Cands;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
      if (!BI || !BI->isConditional() ||
          !taint.Tainted.count(BI->getCondition()))
        continue;
      BasicBlock *S0 = BI->getSuccessor(0);
      BasicBlock *S1 = BI->getSuccessor(1);
      BasicBlock *Arm = nullptr, *Merge = nullptr;
      bool Negated = false;
      // Orientation A — arm = TRUE successor, merge = the straight-through edge.
      if (uncondSucc(S0) == S1 && S0->getSinglePredecessor() == &BB) {
        Arm = S0;
        Merge = S1;
        Negated = false;
        // Orientation B — arm = FALSE successor (clang -O1 swapped them for the
        // `if(q!=k)` shape; the gate arm fires on ¬flag, Rule 9).
      } else if (uncondSucc(S1) == S0 && S1->getSinglePredecessor() == &BB) {
        Arm = S1;
        Merge = S0;
        Negated = true;
      } else {
        continue;  // not a void-arm diamond — not an I/O shape; leave for
                   // detectControlRegions (a real phase/value/select/switch
                   // region, or its own loud decline).
      }
      CallInst *Sink = armIOSink(Arm);
      if (!Sink)
        continue;  // the arm holds no recognized I/O sink (a phase/value/other
                   // arm owned by ControlDetect) — leave it untouched.
      // The shape is OWNED by this step from here. `Cond` may be null (a compound
      // `select i1` AND / non-compare condition) — that is an emit-time decline,
      // captured now so the candidate still carries the (Pred,Arm,Merge) shape.
      Cands.push_back({BI, dyn_cast<CmpInst>(BI->getCondition()), Sink, &BB, Arm,
                       Merge, Negated});
    }
  }
  if (Cands.empty())
    return;

  // 2. OVERLAP guard (the block-lifetime hazard, ControlDetect's discipline): a
  //    flatten erases its arm + merge and splices the merge tail into the pred.
  //    If two candidates share any Pred/Arm/Merge block — e.g. one diamond's
  //    merge is the next diamond's pred (sequential `if(q)printf; if(q)printf`)
  //    — flattening one dangles the other's captured pointers (SIGSEGV on valid
  //    input). Conservatively LEAVE every candidate touching a shared block for
  //    `detectControlRegions` to decline loudly (over-decline is safe).
  DenseMap<BasicBlock *, unsigned> Uses;
  for (const CtrlIOCandidate &C : Cands)
    for (BasicBlock *B : {C.Pred, C.Arm, C.Merge})
      ++Uses[B];

  ControlledSymbols csyms(M, wd);
  for (const CtrlIOCandidate &C : Cands) {
    bool Overlaps = false;
    for (BasicBlock *B : {C.Pred, C.Arm, C.Merge})
      if (Uses[B] > 1) {
        Overlaps = true;
        break;
      }
    if (Overlaps)
      continue;  // structural overlap — leave for detection's loud decline.

    // 3. SHAPE validation (loud decline on failure; over-decline is safe). The
    //    arm must be EXACTLY {sink, br}: a single recognized sink and the
    //    terminator (so the sink's operands are defined OUTSIDE the arm and
    //    dominate the branch — an arg computed in the arm is off-pattern). The
    //    merge must be the clean 2-predecessor join (Pred + Arm) with NO phi (a
    //    phi would be a real data mux, off-pattern; the sink result is discarded
    //    here). The condition must be a single comparison — a compound `select
    //    i1` AND has no one flag to mint. And the merge must be a function TAIL
    //    (ends in `ret`/`unreachable`): `flattenRegion` splices the merge's
    //    instructions into `Pred` and erases the merge, which is only valid if
    //    the merge has NO successors — a merge that branches onward (it hosts a
    //    downstream tainted region, or is a phi-predecessor of a later block)
    //    would dangle that successor's phi / re-root that region (the block-
    //    lifetime hazard; the adjacency a flatten-before-detection must not
    //    touch). Each failure is the kMsgIOControl decline.
    Instruction *MergeTerm = C.Merge->getTerminator();
    bool ArmIsSoleSink = C.Arm->size() == 2 && &C.Arm->front() == C.Sink;
    bool MergeIsCleanJoin =
        C.Merge->hasNPredecessors(2) &&
        (C.Merge->empty() || !isa<PHINode>(C.Merge->front()));
    bool MergeIsTail =
        isa<ReturnInst>(MergeTerm) || isa<UnreachableInst>(MergeTerm);
    if (!ArmIsSoleSink || !MergeIsCleanJoin || !MergeIsTail || !C.Cond) {
      diagnose(C.Sink, kMsgIOControl);
      continue;
    }

    // 4. The sink RESULT must be unused — the flatten erases the arm (and the
    //    sink with it). A used result (`int n = printf(...)`) cannot be cleanly
    //    dropped: decline LOUDLY (kMsgIOResult, mirroring the uncontrolled path).
    if (!C.Sink->use_empty()) {
      diagnose(C.Sink, kMsgIOResult);
      continue;
    }

    // 5. ARG validation (shared `collectTapeTargets`, Rule 14): each tainted
    //    integer-scalar arg becomes a target; fp/i128/non-scalar/non-constant-
    //    classical → kMsgIOArg, a non-terminal rail → kMsgIOFanout. A constant
    //    classical arg (format string / literal) is dropped.
    SmallVector<std::pair<Value *, StringRef>, 4> Targets;
    if (!collectTapeTargets(C.Sink, taint, Targets, /*allowedExtraUser=*/C.Cond))
      continue;

    // 6. PRE-RESOLVE every controlled-write callee BEFORE any mutation. The
    //    integer-only > 64 fence already proved a width in `collectTapeTargets`,
    //    so a null here is unreachable — but resolving first means a defensive
    //    decline never leaves a half-emitted stream (the partial-mutation crash).
    SmallVector<FunctionCallee, 4> Writes;
    bool BadWidth = false;
    for (auto &T : Targets) {
      FunctionCallee TW = csyms.tapeWriteControlledFn(T.second);
      if (!TW) {
        BadWidth = true;
        break;
      }
      Writes.push_back(TW);
    }
    if (BadWidth) {
      diagnose(C.Sink, kMsgIOArg);
      continue;
    }

    // 7. EMIT — everything validated. The stream lands before the conditional
    //    `br`; `flattenRegion` then erases the `br`, splices the merge tail into
    //    `Pred`, and erases the dead condition + arm (incl. the sink) + merge.
    const DebugLoc DL = C.Cond->getDebugLoc();
    IRBuilder<> B(C.BI);
    auto stamp = [&DL](CallInst *Call) {
      if (DL)
        Call->setDebugLoc(DL);
    };

    // 7a. MINT the flag from the tainted comparison — cq_template_icmp_<pred>_
    //     <Wc>_hl(q, k). A Q+Q (both-tainted) condition is unsupported: the mint
    //     returns null after its own loud decline. Done FIRST (before the lazy
    //     `cqrt_tape_alloc`) so a Q+Q decline leaves NO partial mutation — not
    //     even a stray dead tape allocation.
    Value *Flag = lowerCompareToFlag(C.Cond, wd, taint, /*qqWidth=*/{},
                                     /*inverse=*/false, /*before=*/C.BI);
    if (!Flag)
      continue;

    // The lazy stdout tape (shared with the uncontrolled step via IOTapeForFn).
    Value *Tape = ioTapeFor(C.Pred->getParent(), wd, taint, C.Sink->getDebugLoc());

    // 7b. ¬flag bracket for the negated polarity (the arm is the FALSE successor;
    //     clang -O1 swapped them for `if(q!=k)`). The self-inverse `cqrt_x`
    //     encloses ONLY the controlled write(s): committing on `flag` directly
    //     would commit on the WRONG basis branch — verify-clean-invisible, so the
    //     bracket span is pinned by the `_ne` fixture's ordered CHECK (§16.3).
    if (C.Negated)
      stamp(B.CreateCall(csyms.xFn(), {Flag}));

    // 7c. APPEND each tainted target under the flag — ONE
    //     cqrt_tape_write_<W>_controlled(ctrl, tape, src) per tainted arg. `src`
    //     is PRESERVED (CNOT-class), so q stays coherent and `src`'s own lineage
    //     uncomputes normally (Bennett, §2.4); the copy DESTINATION is the fresh
    //     out_handle, never any operand of `Cond` (so q == q0 at strip time). The
    //     returned out_handle is a KEPT output rail (`OutputRails` — never freed
    //     / reversed; the spine recognizes the `cqrt_tape_write_` prefix as
    //     sink-class). The entry is ALWAYS appended; only its content is gated.
    for (unsigned I = 0; I < Targets.size(); ++I) {
      CallInst *Out = B.CreateCall(Writes[I], {Flag, Tape, Targets[I].first});
      stamp(Out);
      taint.Tainted.insert(Out);
      taint.OutputRails.insert(Out);
      taint.BirthOrder[Out] = taint.NextBirth++;
    }
    if (C.Negated)
      stamp(B.CreateCall(csyms.xFn(), {Flag}));

    // 7d. STRIP the flag (the `_inv` twin) + free it. Structurally valid: the
    //     copy destination is the fresh out-rail, never a `Cond` operand, so
    //     every value `Cond` reads is pristine and the `_inv` un-computes the
    //     flag to |0> (provably free-able). Reads Cond's operands — MUST precede
    //     the flatten's erase of Cond.
    lowerCompareToFlag(C.Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                       /*before=*/C.BI);
    stamp(B.CreateCall(wd.freeFn(), {Flag}));

    // 7e. FLATTEN the diamond (Rule 14: the swap-route diamond flattener). A
    //     diamond has no ArmFalse; `flattenRegion` does not touch `R.Merge` (the
    //     phi field), so the phi-less void arm flattens cleanly: drop the `br`,
    //     splice the merge tail (the user's measure / ret) into `Pred`, erase the
    //     dead condition + arm (incl. the now-unused sink) + merge.
    ControlRegion R;
    R.Condition = C.Cond;
    R.Pred = C.Pred;
    R.Arm = C.Arm;
    R.ArmFalse = nullptr;
    R.MergeBB = C.Merge;
    flattenRegion(R, taint);
  }
}

}  // namespace cq
