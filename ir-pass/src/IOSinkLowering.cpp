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

#include "OpcodeSupport.h"
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
bool tapedLineageClosed(const Value *V) {
  for (const User *U : V->users()) {
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

  // One lazy stdout tape per function (the stream→tape registry; v1 has a
  // single stdout stream). The tape handle is a CLASSICAL resource token — NOT
  // inserted into `taint.Tainted` and NOT an OutputRails member (PRD-7.6 §2.5),
  // so the uncompute spine never touches it. Allocated at the function entry's
  // first insertion point so it DOMINATES every tape write in the function.
  DenseMap<Function *, Value *> TapeForFn;
  auto getTape = [&](CallInst *Sink) -> Value * {
    Function *F = Sink->getFunction();
    auto It = TapeForFn.find(F);
    if (It != TapeForFn.end())
      return It->second;
    IRBuilder<> B(&*F->getEntryBlock().getFirstInsertionPt());
    CallInst *Tape = B.CreateCall(wd.tapeAllocFn(), {}, "tape");
    if (DebugLoc DL = Sink->getDebugLoc())
      Tape->setDebugLoc(DL);
    TapeForFn[F] = Tape;
    return Tape;
  };

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
    //    (in arg order). A tainted arg must be an integer scalar with a
    //    reversible-copy width {i1,i8,i16,i32,i64}; an fp (`%f`), i128, vector,
    //    or pointer tainted arg DECLINES. A classical arg is allowed ONLY if it
    //    is a compile-time Constant (the format-string ptr, a literal int) —
    //    dropped (the format text stays a classical inspection concept, §2.9);
    //    a NON-constant classical co-arg (a runtime value / possible side
    //    effect we would silently drop) DECLINES.
    SmallVector<std::pair<Value *, StringRef>, 4> Targets;
    bool Bad = false;
    for (Value *Arg : Sink->args()) {
      if (taint.Tainted.count(Arg)) {
        // fp-data in a rail is the f64/angle miscompile family — test
        // isFPOrFPVectorTy (NOT scalar-only isFloatingPointTy; catches
        // <2 x double>), then the reversible-copy width gate (NOT
        // `abiWidthFromType(..).empty()`, which i128 no longer satisfies).
        if (Arg->getType()->isFPOrFPVectorTy()) {
          diagnose(Sink, kMsgIOArg);
          Bad = true;
          break;
        }
        StringRef Abi = abiWidthFromType(Arg->getType());
        if (Abi.empty() || !widthHasReversibleCopy(Abi)) {
          diagnose(Sink, kMsgIOArg);
          Bad = true;
          break;
        }
        Targets.emplace_back(Arg, Abi);
      } else if (!isa<Constant>(Arg)) {
        diagnose(Sink, kMsgIOArg);
        Bad = true;
        break;
      }
    }
    if (Bad)
      continue;
    if (Targets.empty()) {
      // A recognized sink reached us via `readsTaintedArg`, so a tainted arg
      // exists — reaching here would mean it was neither targeted nor declined
      // (a logic hole). Decline rather than silently drop it.
      diagnose(Sink, kMsgIOArg);
      continue;
    }

    // 3b. Every target must be a TERMINAL or measured value (closed lineage) —
    //     never a non-terminal rail the uncompute spine reverse-plays out from
    //     under the tape write (Rule-13 R2 use-after-free). Decline LOUDLY.
    bool Fanout = false;
    for (auto &T : Targets)
      if (!tapedLineageClosed(T.first)) {
        diagnose(Sink, kMsgIOFanout);
        Fanout = true;
        break;
      }
    if (Fanout)
      continue;

    // 4. APPEND each tainted target to the tape. The tape write reads the
    //    still-tainted `src` (pre-RAUW); the rotation pass later rewrites that
    //    operand to its i32 handle. The returned `out_handle` is a KEPT output
    //    rail: it joins `Tainted` (so any downstream classifies it as quantum)
    //    and `OutputRails` (so the spine never reverses/frees it — §2.5), with
    //    a BirthOrder slot for LIFO ordering. The write is a recognized SINK
    //    (ChainWalk::isOutputSink), so `src`'s own lineage still uncomputes
    //    normally through the Phase-5 spine (Bennett copy-out, §2.4).
    Value *Tape = getTape(Sink);
    IRBuilder<> B(Sink);  // every tape write lands immediately before the sink
    const DebugLoc DL = Sink->getDebugLoc();
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

}  // namespace cq
