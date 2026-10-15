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
#include "LiteralIntegrity.h"   // slotCarriesUndef (bd c4ow — the co-arg fence)
#include "OpcodeSupport.h"
#include "RegionFlatten.h"      // flattenRegion (control-region diamond flattener)
#include "MergeArmWrite.h"      // emitArmMux (4.4 controlled-XOR mux, bd dm7f.81)
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
// bd c4ow — the CLASSICAL co-argument definedness fence. Mirrored char-for-char
// by lowering_reject_io_undef_coarg.ll (uncontrolled) and
// lowering_reject_io_controlled_undef_coarg.ll (controlled); the accept side is
// lowering_io_accept_literal_coarg.ll and lowering_io_accept_global_pad_coarg.ll.
constexpr char kMsgIOUndefArg[] =
    "cq I/O output sink: classical argument is undef/poison, not a "
    "compile-time known value";
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
// computation (a data op, a cast, a chained `cq_theta`, a ret/store, a user
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
// chained cq_theta / ret / store) still bails (the Rule-13 R2 use-after-free).
//
// `valuePhi`, when non-null (the MIXED value+I/O path only), additionally permits
// ONE class of extra user: the VALUE-PATH COMBINER — an instruction in the merge
// block that reads BOTH V and the data-mux `valuePhi` (the `add q, mux` that
// combines the taped quantum value with the constant data-mux). This is provably
// safe WITHOUT a transitive analysis: the controlled emitter lands the tape write
// at the END of `Pred` (before the conditional branch), and `flattenRegion` then
// splices the ENTIRE merge block AFTER it — so a merge-block use of V follows the
// tape write in the single flattened block. V's free point is the post-dominator
// of all its uses, hence at-or-after that merge use and AFTER the tape write; the
// uncompute spine can never reverse/free V's rail before the tape read (the R2
// hazard needs a use that PRECEDES the sink — a merge use cannot). Requiring the
// user to also read `valuePhi` keeps the relaxation as tight as its justification
// (it admits the value-path combiner, NOT an arbitrary dead op on V in the merge —
// that still bails, matching the uncontrolled path's Rule-8 linear-lineage bail).
bool tapedLineageClosed(const Value *V, const Value *allowedExtraUser = nullptr,
                        const PHINode *valuePhi = nullptr) {
  for (const User *U : V->users()) {
    if (U == allowedExtraUser)
      continue;  // the controlled-path condition compare — preserves V (above).
    if (valuePhi)
      if (const auto *I = dyn_cast<Instruction>(U))
        if (I->getParent() == valuePhi->getParent()) {
          bool ReadsMux = false;
          for (const Use &Op : I->operands())
            if (Op.get() == valuePhi) {
              ReadsMux = true;
              break;
            }
          if (ReadsMux)
            continue;  // the value-path combiner (reads V AND the data-mux φ in the
                       // merge) — spliced AFTER the tape write, never reversed first.
        }
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
    return false;  // any other call (a chained cq_theta, a user call) — fan-out
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
// value / side effect we would silently drop); an undef/poison-bearing classical
// co-arg DECLINES (kMsgIOUndefArg, bd c4ow — see below); a constant classical arg
// (the format-string ptr / a literal) is DROPPED. Every target must additionally
// have CLOSED lineage — never a non-terminal rail the uncompute spine
// reverse-plays out from under the tape write (kMsgIOFanout, the Rule-8 linear-
// lineage bail). Returns true with `Targets` populated (non-empty) on success;
// false after firing the precise loud decline on `Sink`. PRD-7.6 §2.6 / §6.3.
//
// ─── bd c4ow: WHY A POISON CO-ARG IS A FENCE HOLE AND NOT A LOST TAPE FIELD ──
//
// *** STATE THIS ONE PRECISELY, BECAUSE THE OBVIOUS FRAMING IS FALSE AND A
// REVIEWER FALSIFIES IT IN THIRTY SECONDS. *** The ticket read the defect as "a
// printf argument the source writes does not appear in the output tape, so the
// golden trace has one fewer field than the program specifies". MEASURED, on the
// shipped plugin, from stock `clang -O1`: `printf("%d %d\n", q, <i32 7>)` and the
// same call with `<i32 poison>` lower BYTE-IDENTICALLY — one
// `cqrt_tape_write_i32`, `@printf` erased, `opt` exit 0. Dropping a CLASSICAL
// co-arg is the shipped, documented 7.6 design (only tainted args are taped), so
// nothing is lost relative to a defined literal and no observable moves.
//
// The real defect is an ACCEPT-PREDICATE hole on a UB input. The fence one line
// below was written to mean "this co-arg is COMPILE-TIME KNOWN, so dropping it
// costs the program nothing", and `isa<Constant>` is how that intent is spelled.
// `undef`/`poison` ARE `Constant`s and they DENOTE NO VALUE, so the predicate
// admits exactly the input its own justification excludes. The Prime Directive
// settles the rest: an unproven accept surface should not exist, and
// over-declining a UB input is free.
//
// *** DO NOT CALL THAT "THE ONE KIND OF `Constant`" — an earlier draft did and
// the Rule-13 round falsified it. *** A `ConstantExpr` that GENERATES poison
// without CONTAINING an `UndefValue` — the bd bu96 class, e.g.
// `ptrtoint (ptr getelementptr inbounds ([4 x i32], ptr @g, i64 0, i64 99) to i32)`
// — denotes no value just as much, and `slotCarriesUndef` returns false on it, so
// it still passes here (measured: accepted, co-arg dropped, module byte-identical
// to the `i32 7` accept fixture's). The fence discriminates on the SPELLING, not
// on "denotes no value". That residual is knowingly inherited from bd bu96
// (DECLINE TO FIX) — but note its licensing argument does NOT transfer to this
// site: bu96 is sound on the PAIRING axis (a uniqued `ConstantExpr` is one
// link-time relocation, so a forward and its adjoint read one value), and nothing
// here is paired. What makes it harmless here is the measurement above — dropping
// a classical co-arg is byte-neutral whatever it denotes.
//
// REACH IS PROVEN AND TRIVIAL, not hypothetical: `int y; printf("%d %d\n", x, y);`
// makes `clang -O1` emit `i32 noundef undef` in the arg list, with no warning.
//
// ONE SITE, TWO CALLERS. This validator is already the shared Rule-14 gate for
// BOTH emitters (`lowerIOSinks` and `lowerControlledIOSinks`, the latter once per
// arm), and both call it BEFORE their first `CreateCall`, so there is no second
// fence to keep in step *within the printf/putchar family*. SCOPE THAT CLAUSE:
// the pass has a SECOND sink family that drops arguments on the identical "never
// observable, so dropping is free" rationale with no definedness test at all —
// `AbortParkEmit`'s 7.2 recognizer (`abort`/`exit`/`_exit`/`_Exit`/`quick_exit`/
// `__assert_fail`/`__assert_rtn`/`llvm.trap`/`llvm.ubsantrap`) tests its arguments
// only for TAINT and then erases the call, so `exit(undef)` and `exit(1)` compile
// byte-identically (measured). That is almost certainly harmless — an argument to
// a process-terminating call the park semantics never execute is unobservable
// either way — but it is a RULING nobody has written down, which is precisely how
// this defect class arises. Filed as its own ticket.
//
// CLAIM-TIME, ON THE ROUND-1 PATH. `lowerIOSinks`/`lowerControlledIOSinks` fire
// before their own emitters mutate anything. They are NOT the whole story: the
// round-2 `detectSpecializations` inside `repropagateControlMerges` runs after
// `lowerControlledIOSinks`, `lowerLoops` and `lowerControlRegions` have already
// emitted and FLATTENED a region, so on that path this decline (like every other
// post-mutation decline in the pass — `Uncomputation`'s `kMsgLineageMeasured` is
// the precedent) hands back a partly-lowered module. Under `opt`, the only
// supported host, `DS_Error` exits with zero stdout bytes, so nothing mutated is
// ever written.
//
// *** THE PREDICATE IS `slotCarriesUndef`, NEVER `valueCarriesUndef`. *** A
// printf argument list is DOMINATED by global ADDRESSES — the format string is
// one on every single call — and `valueCarriesUndef` descends into a global's
// INITIALIZER, which is a different value from the address in the slot. The
// fp80-union idiom this project is built on (`clang -O1` emits
// `@v = global { i32, [12 x i8] } { i32 3, [12 x i8] undef }` for a
// partially-initialised `union { long double f; int i; }`) would then decline a
// WELL-DEFINED program. `lowering_io_accept_global_pad_coarg.ll` is that
// arm-kill. The un-skipped `valueCarriesUndef` has exactly ONE caller — the
// PredMux cone predicate — where its over-decline is PRE-EXISTING and removing it
// is an accept WIDENING (bd ajw7); do not "unify" the two.
//
// A TAINTED arg cannot reach this test, and that is checked rather than assumed:
// all 30 `Tainted.insert` sites in `ir-pass/src` insert a `CallInst`, an
// `Instruction`, or (in the clone-LOCAL taint sets only) an `Argument` — never a
// `Constant`. So the tainted branch above always wins for a non-`Constant`, and
// the new check belongs on the classical branch, where it can fire.
//
// PLACEMENT NOTE: it sits inside the per-argument loop, so an undef co-arg now
// PRE-EMPTS `kMsgIOFanout` and any later argument's `kMsgIOArg` for the same
// sink. Both outcomes are loud declines, nothing is over-accepted, and no shipped
// fixture changes message — but the message identity for a given module is not
// what the base plugin gave, so do not treat a diagnostic diff here as a
// regression without reading which fence fired.
bool collectTapeTargets(CallInst *Sink, TaintSet &taint,
                        SmallVectorImpl<std::pair<Value *, StringRef>> &Targets,
                        const Value *allowedExtraUser = nullptr,
                        const PHINode *valuePhi = nullptr) {
  for (Value *Arg : Sink->args()) {
    if (taint.Tainted.count(Arg)) {
      if (Arg->getType()->isFPOrFPVectorTy()) {
        diagnose(Sink, kMsgIOArg);
        return false;
      }
      // LOGICAL width: a laundered i32 handle (a break answer) carries it in its
      // `HandleWidth` record, not its type (lowering_loop_break_io_tape_width.ll).
      StringRef Abi = logicalOperandWidth(Arg, taint);
      if (Abi.empty() || !widthHasReversibleCopy(Abi)) {
        diagnose(Sink, kMsgIOArg);
        return false;
      }
      Targets.emplace_back(Arg, Abi);
    } else if (!isa<Constant>(Arg)) {
      diagnose(Sink, kMsgIOArg);
      return false;
    } else if (slotCarriesUndef(Arg)) {
      // A `Constant` that denotes NO value — the one kind for which "dropping a
      // compile-time known co-arg is free" is false (bd c4ow, above).
      diagnose(Sink, kMsgIOUndefArg);
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
    if (!tapedLineageClosed(T.first, allowedExtraUser, valuePhi)) {
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
    //    kMsgIOArg, a non-constant classical co-arg → kMsgIOArg, an undef/poison
    //    classical co-arg → kMsgIOUndefArg (bd c4ow), a non-terminal rail →
    //    kMsgIOFanout; a DEFINED constant classical arg is dropped). On any
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

// One I/O-sink arm of a recovered controlled candidate: the recognized sink, its
// arm block (erased by the flatten), and whether it fires on ¬flag. An arm fires
// on ¬flag when it is the FALSE successor — clang -O1 makes the gate arm the
// false successor for the `if(q!=k)` diamond (Rule 9), and in a both-arm if/else
// the FALSE arm always fires on ¬flag. Its controlled writes are then enclosed in
// a self-inverse `cqrt_x` bracket so the entry commits on the right basis branch.
struct CtrlIOArm {
  CallInst *Sink;
  BasicBlock *Arm;
  bool Negated;
};

// A recovered Tier-0 controlled-I/O candidate: a tainted-condition `br i1` whose
// taken arm(s) CONTAIN a recognized I/O sink (so the shape is OWNED by this step
// — lower it or decline it LOUDLY, never a silent skip that hands a tainted `br`
// to the backend, Rule 1). `Arms` holds ONE entry for a single-sink diamond
// (orientation A/B, `if(q)printf;`) and TWO for a both-arm if/else (orientation
// C, `if(q)printf; else putchar;`) — each arm emits under its own flag polarity
// into the ONE shared tape. All identities are captured by SSA value/block
// identity BEFORE any mutation (Rule 9; the block-lifetime hazard).
struct CtrlIOCandidate {
  BranchInst *BI;       // the tainted-condition branch in `Pred`
  CmpInst *Cond;        // the comparison, or null for a compound/non-compare cond
  BasicBlock *Pred;     // the branch block (survives the flatten)
  BasicBlock *Merge;    // the join (erased by the flatten)
  SmallVector<CtrlIOArm, 2> Arms;  // 1 (diamond) or 2 (both-arm if/else)
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
      // `Cond` may be null (a compound `select i1` AND / non-compare condition) —
      // that is an emit-time decline, captured now so the candidate still carries
      // the (Pred,Arms,Merge) shape and is OWNED (lowered or loud-declined).
      CmpInst *Cond = dyn_cast<CmpInst>(BI->getCondition());

      // Orientation A — single arm = TRUE successor S0, merge = the
      // straight-through (false) edge S1. Fires on flag (no bracket).
      if (uncondSucc(S0) == S1 && S0->getSinglePredecessor() == &BB) {
        if (CallInst *Sink = armIOSink(S0))
          Cands.push_back({BI, Cond, &BB, S1, {{Sink, S0, /*Negated=*/false}}});
        continue;  // structurally a diamond; if no sink, leave for detection.
      }
      // Orientation B — single arm = FALSE successor S1 (clang -O1 swapped them
      // for `if(q!=k)`; the gate arm fires on ¬flag, Rule 9), merge = S0.
      if (uncondSucc(S1) == S0 && S1->getSinglePredecessor() == &BB) {
        if (CallInst *Sink = armIOSink(S1))
          Cands.push_back({BI, Cond, &BB, S0, {{Sink, S1, /*Negated=*/true}}});
        continue;
      }
      // Orientation C — BOTH successors are single-pred arms reconverging at a
      // common merge M (`if(q)printf; else putchar;`). Collected only when BOTH
      // arms hold a recognized sink: a one-I/O-arm-plus-value diamond is the
      // MIXED shape (owned by the value path), not this both-arm-void-I/O shape.
      // S0 (TRUE) fires on flag, S1 (FALSE) on ¬flag. The clean-2-pred/no-phi
      // join is enforced at emit-time shape validation (a value merge φ declines,
      // never over-accepting a partial nest).
      if (BasicBlock *M = uncondSucc(S0))
        if (M == uncondSucc(S1) && M != S0 && M != S1 &&
            S0->getSinglePredecessor() == &BB &&
            S1->getSinglePredecessor() == &BB) {
          CallInst *Sink0 = armIOSink(S0);
          CallInst *Sink1 = armIOSink(S1);
          if (Sink0 && Sink1)
            Cands.push_back({BI, Cond, &BB, M,
                             {{Sink0, S0, /*Negated=*/false},
                              {Sink1, S1, /*Negated=*/true}}});
        }
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
  for (const CtrlIOCandidate &C : Cands) {
    ++Uses[C.Pred];
    ++Uses[C.Merge];
    for (const CtrlIOArm &A : C.Arms)
      ++Uses[A.Arm];
  }

  ControlledSymbols csyms(M, wd);
  for (const CtrlIOCandidate &C : Cands) {
    bool Overlaps = Uses[C.Pred] > 1 || Uses[C.Merge] > 1;
    for (const CtrlIOArm &A : C.Arms)
      if (Uses[A.Arm] > 1)
        Overlaps = true;
    if (Overlaps)
      continue;  // structural overlap — leave for detection's loud decline.

    // 3. SHAPE validation (loud decline on failure; over-decline is safe). EVERY
    //    arm must be EXACTLY {sink, br}: a single recognized sink and the
    //    terminator (so the sink's operands are defined OUTSIDE the arm and
    //    dominate the branch — an arg computed in the arm is off-pattern). The
    //    merge must be the clean 2-predecessor join; its phi structure picks the
    //    EFFECT mix this region carries:
    //      * NO phi → pure void I/O (a both-arm if/else, or a single-arm `if(q)`);
    //      * exactly one 2-incoming phi over CONSTANTS, single-arm only → MIXED
    //        value+I/O: a constant data-mux beside the I/O effect, lowered under the
    //        SAME minted flag via the 4.4 controlled-XOR copy (`ValuePhi`). The
    //        constant restriction is load-bearing: a constant is a pure basis value
    //        carrying NO phase, so the XOR copy cannot dephase (Rule 7 / the §2-H
    //        P0 leak cannot arise) — this is the SAFE subset. A COMPUTED-incoming
    //        phi (the two-base value multiplexer) or a both-arm value phi stays
    //        DECLINING (= the 65wb.5 exp2 conservative decline);
    //      * anything else (multi-phi, an fp/i128/non-const phi) → decline.
    //    Keying the merge on "single-pred sole-sink arms converging on one 2-pred
    //    merge" (not merely "2-pred merge") keeps the both-arm widening from
    //    over-accepting a partial nest (a 3-pred merge fails `hasNPredecessors(2)`).
    //    The condition must be a single comparison — a compound `select i1` AND has
    //    no one flag to mint. And the merge must be a function TAIL (ends in
    //    `ret`/`unreachable`): `flattenRegion` splices the merge into `Pred` and
    //    erases it, valid only if the merge has NO successors — a merge that
    //    branches onward (it hosts a downstream tainted region, or is a phi-
    //    predecessor of a later block) would dangle that successor / re-root that
    //    region (the block-lifetime hazard). Each failure is the kMsgIOControl
    //    decline, fired on the first arm's sink.
    Instruction *MergeTerm = C.Merge->getTerminator();
    bool ArmsAreSoleSinks = true;
    for (const CtrlIOArm &A : C.Arms)
      if (A.Arm->size() != 2 || &A.Arm->front() != A.Sink)
        ArmsAreSoleSinks = false;
    unsigned NumPhis = 0;
    for (PHINode &P : C.Merge->phis()) {
      (void)P;
      ++NumPhis;
    }
    PHINode *ValuePhi = nullptr;
    if (NumPhis == 1 && C.Arms.size() == 1) {
      PHINode *P = &*C.Merge->phis().begin();
      // i32-ONLY (Rule 15): every cq rail handle is i32, so the mux out-rail is i32
      // and the `RAUW φ→out` relaunders the φ to an i32 handle. A NON-i32 φ (i1/i8/
      // i16/i64) whose downstream consumer is NOT re-typed by `lowerOps` — a direct
      // `zext`/`trunc`, a narrow store, a narrow opaque call arg — would become
      // ill-typed under that RAUW, a BROKEN MODULE (a verifier abort on valid -O1
      // input; the Rule-13 must-fix). Over-decline every non-i32 mux width (Prime
      // Directive); a narrower/wider data-mux beside I/O is out of this Tier.
      if (P->getNumIncomingValues() == 2 &&
          isa<ConstantInt>(P->getIncomingValue(0)) &&
          isa<ConstantInt>(P->getIncomingValue(1)) &&
          P->getType()->isIntegerTy(32))
        ValuePhi = P;  // mixed value+I/O: a lowerable i32 constant data-mux.
    }
    bool MergeOk = C.Merge->hasNPredecessors(2) && (NumPhis == 0 || ValuePhi);
    bool MergeIsTail =
        isa<ReturnInst>(MergeTerm) || isa<UnreachableInst>(MergeTerm);
    if (!ArmsAreSoleSinks || !MergeOk || !MergeIsTail || !C.Cond) {
      diagnose(C.Arms.front().Sink, kMsgIOControl);
      continue;
    }

    // 4. Every sink RESULT must be unused — the flatten erases the arms (and the
    //    sinks with them). A used result (`int n = printf(...)`) cannot be cleanly
    //    dropped: decline LOUDLY (kMsgIOResult, mirroring the uncontrolled path).
    CallInst *UsedSink = nullptr;
    for (const CtrlIOArm &A : C.Arms)
      if (!A.Sink->use_empty()) {
        UsedSink = A.Sink;
        break;
      }
    if (UsedSink) {
      diagnose(UsedSink, kMsgIOResult);
      continue;
    }

    // 5. ARG validation (shared `collectTapeTargets`, Rule 14): each tainted
    //    integer-scalar arg becomes a target; fp/i128/non-scalar/non-constant-
    //    classical → kMsgIOArg, an undef/poison classical co-arg →
    //    kMsgIOUndefArg (bd c4ow), a non-terminal rail → kMsgIOFanout. A DEFINED
    //    constant classical arg (format string / literal) is dropped. Per arm:
    //    `allowedExtraUser=C.Cond` whitelists the tainted condition compare as a
    //    co-user of EACH arm's taped value (both arms typically print the same `q`
    //    that the one compare reads — the second arm would else trip kMsgIOFanout).
    SmallVector<SmallVector<std::pair<Value *, StringRef>, 4>, 2> ArmTargets;
    bool ArgBad = false;
    for (const CtrlIOArm &A : C.Arms) {
      SmallVector<std::pair<Value *, StringRef>, 4> Targets;
      // For the mixed value+I/O shape, the taped value is ALSO read by the value-
      // path combiner (the `add q, mux` in the merge that reads the data-mux φ) —
      // whitelist exactly that user (provably safe; it is spliced after the tape
      // write). Void I/O passes no φ (strict: only sinks/measures + the condition).
      if (!collectTapeTargets(A.Sink, taint, Targets, /*allowedExtraUser=*/C.Cond,
                              /*valuePhi=*/ValuePhi)) {
        ArgBad = true;
        break;  // collectTapeTargets already fired the precise loud decline.
      }
      ArmTargets.push_back(std::move(Targets));
    }
    if (ArgBad)
      continue;

    // 6. PRE-RESOLVE every controlled-write callee BEFORE any mutation. The
    //    integer-only > 64 fence already proved a width in `collectTapeTargets`,
    //    so a null here is unreachable — but resolving first means a defensive
    //    decline never leaves a half-emitted stream (the partial-mutation crash).
    SmallVector<SmallVector<FunctionCallee, 4>, 2> ArmWrites;
    bool BadWidth = false;
    for (auto &Targets : ArmTargets) {
      SmallVector<FunctionCallee, 4> Writes;
      for (auto &T : Targets) {
        FunctionCallee TW = csyms.tapeWriteControlledFn(T.second);
        if (!TW) {
          BadWidth = true;
          break;
        }
        Writes.push_back(TW);
      }
      if (BadWidth)
        break;
      ArmWrites.push_back(std::move(Writes));
    }
    if (BadWidth) {
      diagnose(C.Arms.front().Sink, kMsgIOArg);
      continue;
    }

    // 7. EMIT — everything validated. The stream lands before the conditional
    //    `br`; `flattenRegion` then erases the `br`, splices the merge tail into
    //    `Pred`, and erases the dead condition + arm(s) (incl. the sinks) + merge.
    const DebugLoc DL = C.Cond->getDebugLoc();
    IRBuilder<> B(C.BI);
    auto stamp = [&DL](CallInst *Call) {
      if (DL)
        Call->setDebugLoc(DL);
    };

    // 7a. MINT the flag ONCE from the tainted comparison — cq_template_icmp_
    //     <pred>_<Wc>_hl(q, k). A both-arm if/else mints ONE flag from the one
    //     compare; each arm rides its own polarity (S0 on flag, S1 on ¬flag). A
    //     Q+Q (both-tainted) condition is unsupported: the mint returns null after
    //     its own loud decline. Done FIRST (before the lazy `cqrt_tape_alloc`) so a
    //     Q+Q decline leaves NO partial mutation — not even a stray dead tape.
    //     (Track A.1, F-A1R2-1) `Unruled`: `lowerControlledIOSinks` runs
    //     BEFORE `detectControlRegions` in both entry points, so no classifier
    //     has looked at this condition's wire at all (MEASURED: no
    //     `findNonDiagonalWireGate` / `condWireDisposition` in this file). The
    //     gap is a CONFIRMED silent miscompile on `main` (`io3.c`: a controlled
    //     tape write minted from a register a sibling in-place Ry relabelled,
    //     while the kickback twin `io4.c` declines); the unexempted rung-(iii)
    //     re-ask this asks for is what closes it.
    Value *Flag = lowerCompareToFlag(C.Cond, wd, taint, /*qqWidth=*/{},
                                     /*inverse=*/false, /*before=*/C.BI,
                                     /*negate=*/false,
                                     /*railToStrip=*/nullptr,
                                     /*readKind=*/CondReadKind::Unruled);
    if (!Flag)
      continue;

    // The lazy stdout tape — ONE per function (shared with the uncontrolled step
    // and across BOTH arms via IOTapeForFn; never two tapes for one function).
    Value *Tape =
        ioTapeFor(C.Pred->getParent(), wd, taint, C.Arms.front().Sink->getDebugLoc());

    // 7b-c. Per arm, in successor order (S0 then S1 — deterministic tape order,
    //     pinned by the golden): a ¬flag arm wraps its writes in a self-inverse
    //     `cqrt_x` bracket (commits on the FALSE basis branch; committing on
    //     `flag` directly would commit on the WRONG branch — verify-clean-invisible,
    //     so the bracket span is pinned by the ordered CHECK). Each tainted target
    //     becomes ONE cqrt_tape_write_<W>_controlled(ctrl, tape, src): `src` is
    //     PRESERVED (CNOT-class) so q stays coherent; the copy DESTINATION is the
    //     fresh out_handle, never a `Cond` operand (so q == q0 at strip time). The
    //     out_handle is a KEPT output rail (`OutputRails`).
    //
    //     "`src` is PRESERVED, THEREFORE `src`'s LINEAGE UNCOMPUTES NORMALLY
    //     (Bennett)" — which this comment used to assert — IS FALSE, and it is the
    //     exact sentence bd 261j(a) ruled out (owner ruling 2026-08-10). Preserving
    //     the src REGISTER is true; concluding that src is then FREEABLE does not
    //     follow, because the copy's DESTINATION is never restored, so src stays
    //     CORRELATED with a carrier the reversal never touches. Whether src's
    //     lineage may be freed is decided per rail by the `FrozenRails` freeze
    //     (DagTraversal step 3b), never re-derived from "the tape preserves src".
    //     261j corrected four copies of this sentence; this was the fifth, on the
    //     emitter that actually mints the recording gate (bd urlv). BOTH arms ALWAYS append
    //     EXACTLY one entry per arg — only the CONTENT is gated (deterministic tape
    //     length; the inactive arm commits |0> content, accepted Bennett-tape
    //     semantics, pinned in the golden), never a superposition over entry count.
    for (unsigned ArmIdx = 0; ArmIdx < C.Arms.size(); ++ArmIdx) {
      bool Neg = C.Arms[ArmIdx].Negated;
      if (Neg)
        stamp(B.CreateCall(csyms.xFn(), {Flag}));
      for (unsigned I = 0; I < ArmTargets[ArmIdx].size(); ++I) {
        CallInst *Out = B.CreateCall(ArmWrites[ArmIdx][I],
                                     {Flag, Tape, ArmTargets[ArmIdx][I].first});
        stamp(Out);
        taint.Tainted.insert(Out);
        taint.OutputRails.insert(Out);
        taint.BirthOrder[Out] = taint.NextBirth++;
      }
      if (Neg)
        stamp(B.CreateCall(csyms.xFn(), {Flag}));
    }

    // 7c'. VALUE data-mux (mixed value+I/O only): the merge's constant `ValuePhi`
    //      is a data-mux gated by the SAME flag — lower it with the 4.4 controlled-
    //      XOR merge (Rule 14: reuse `emitArmMux`, the exact `emitSelectRegion`
    //      §5a recipe). `out = |0>`; write the
    //      flag-set-branch constant on `flag`; write the ¬flag-branch constant on the
    //      `cqrt_x`-bracketed `¬flag`; the φ → out RAUW lands at 7d' (before the
    //      flatten erases the merge). Which constant is the flag-set value depends on
    //      which edge reaches the merge when the flag is SET: for an un-negated arm
    //      (S0, TRUE) the flag-set edge is the arm itself; for a negated arm (S1,
    //      FALSE) it is the straight-through `Pred` edge. Constants are basis values
    //      (no phase) so the copy cannot dephase (Rule 7). `out` is a KEPT control-
    //      owned rail (never freed/reversed — left allocated, Rule 6); its downstream
    //      tainted users (an `add q, out` Q+Q op / the user's measure) see a real
    //      i32 handle. The constants are never rails (bd dm7f.81, R13).
    CallInst *MuxOut = nullptr;
    if (ValuePhi) {
      StringRef VAbi = abiWidthFromType(ValuePhi->getType());
      Type *RailTy = wd.llvmWidthType(VAbi);
      FunctionCallee Alloc = wd.allocFn(VAbi);
      FunctionCallee Copy = csyms.copyControlledFn(VAbi);
      bool Neg = C.Arms.front().Negated;
      Value *ArmInc = ValuePhi->getIncomingValueForBlock(C.Arms.front().Arm);
      Value *PredInc = ValuePhi->getIncomingValueForBlock(C.Pred);
      Value *FlagSetV = Neg ? PredInc : ArmInc;  // value committed when flag = 1
      Value *FlagClrV = Neg ? ArmInc : PredInc;  // value committed when flag = 0
      MuxOut = B.CreateCall(Alloc, {Constant::getNullValue(RailTy)}, "out");
      stamp(MuxOut);
      taint.Tainted.insert(MuxOut);
      taint.ControlOwnedRails.insert(MuxOut);
      // bd `test_C_libtooling-3jru` / xdu2.13 Rule-13 round 5 F-R5-1 — this rail
      // REPLACES a data-UNTAINTED constant-incoming φ (7d' RAUWs it), so its
      // onward users (`v*m`, a literal `v*m == n`, a `cq_measure(v)`, a `ret`)
      // were classified CLASSICAL by the first `propagate` and would compute on
      // the handle NUMBER. Record it exactly like the 6.5/4.5 merge rails so
      // `repropagateControlMerges` — which runs AFTER `lowerControlledIOSinks` in
      // BOTH entry points — re-seeds a forward propagation from it through
      // `propagateWorklist` (and its call-return closure).
      taint.UntaintedMergeRails.insert(MuxOut);
      taint.BirthOrder[MuxOut] = taint.NextBirth++;
      // bd dm7f.81: each constant is a literal operand of a controlled xor
      // (`emitArmMux`, MergeArmWrite.h), never a rail; a zero one emits nothing.
      emitArmMux(B, csyms, Flag, FlagSetV, FlagClrV, MuxOut, Copy,
                 csyms.xorcControlledFn(VAbi), taint, DL);
    }

    // 7d. STRIP the flag (the `_inv` twin) + free it. Structurally valid: every
    //     copy destination is a fresh out-rail, never a `Cond` operand, so every
    //     value `Cond` reads is pristine and the `_inv` un-computes the flag to |0>
    //     (provably free-able). Reads Cond's operands — MUST precede the flatten's
    //     erase of Cond.
    //
    //     THIS FLAG IS RECORDED ONTO THE KEPT TAPE, and the free is still sound —
    //     the ONE emitter in the tree where that combination occurs, so state the
    //     reason rather than leave it to be re-derived (bd urlv audit, and the
    //     invariant is bd memory [record-freeze-invariant-2026-08-10]). Step 7b-c
    //     above passes `Flag` as the CTRL of `cqrt_tape_write_<W>_controlled`, and a
    //     controlled write records its ctrl's label in the entry's EXISTENCE
    //     pattern exactly as it records `src`'s label in the content — which is why
    //     `recordsIntoKeptCarrier` is slot-blind. So a kept-carrier record does
    //     reach this rail. It is freeable because the flag's forward chain W is its
    //     compare mint `cq_template_icmp_*(q, k)` — a BASIS PERMUTATION of a live
    //     `cond(W) = {q}`, not an `Ry` — the `_inv` above is exactly W†, and q holds
    //     its producer-time value because no copy destination is a `Cond` operand.
    //     That is precisely the case `preservesBasisUnderRecord` whitelists, so the
    //     spine's freeze would clear it too. The 261j defect was the opposite shape:
    //     a recorded `cqrt_ry` rail, whose `cond(W)` is EMPTY and which is not
    //     trivial on |0>, so nothing returns it to |0>. If a future widening ever
    //     puts a rotation on this flag, this free becomes a hidden measurement.
    lowerCompareToFlag(C.Cond, wd, taint, /*qqWidth=*/{}, /*inverse=*/true,
                       /*before=*/C.BI, /*negate=*/false, /*railToStrip=*/Flag);
    stamp(B.CreateCall(wd.freeFn(), {Flag}));

    // 7d'. REWIRE the mixed value φ → the data-mux rail, then scrub + erase it —
    //      BEFORE the flatten splices the merge into `Pred` (a surviving φ mid-block
    //      is invalid IR; flattenRegion requires the φ already gone). The φ's
    //      downstream users (the `add q, out` / measure / ret spliced into `Pred`)
    //      now read the |0>-allocated mux rail. The φ is classical (constant
    //      incomings), so the taint-set scrub is defensive (it is not in Tainted).
    if (ValuePhi) {
      ValuePhi->replaceAllUsesWith(MuxOut);
      taint.Tainted.erase(ValuePhi);
      taint.BirthOrder.erase(ValuePhi);
      ValuePhi->eraseFromParent();
    }

    // 7e. FLATTEN the region (Rule 14: the control-region diamond flattener). For a
    //     both-arm if/else `R.ArmFalse` is the second arm, so `flattenRegion`
    //     erases BOTH arms + the merge and splices the merge tail once. The phi-
    //     less void region has no `R.Merge`, so the flattener never touches it.
    ControlRegion R;
    R.Condition = C.Cond;
    R.Pred = C.Pred;
    R.Arm = C.Arms[0].Arm;
    R.ArmFalse = C.Arms.size() > 1 ? C.Arms[1].Arm : nullptr;
    R.MergeBB = C.Merge;
    flattenRegion(R, taint);
  }
}

}  // namespace cq
