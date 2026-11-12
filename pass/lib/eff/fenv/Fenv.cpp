// Module eff-fenv (cq-w1-eff-fenv): the floating-point environment, CR rule 23 (witnesses 65, 80, 81,
// 82, 100).
//
// MODEL. The environment is program state split in two (rule 23; 80's and 81's headers):
//  - the HOST part is the real FPU state, kept exactly by the real <fenv.h> calls, which stay in the
//    output as host calls, and by every classical floating-point instruction;
//  - the QUANTUM part is two pieces of per-function state this module tracks while the spine walks:
//      MODE   classical (the host mode is the mode) or a handle (an i32 rail holding an FE_* value);
//      FLAGS  empty or a handle (an i32 rail: the exception bits quantum code raised, host encoding
//             INVALID 1, DIVBYZERO 4, OVERFLOW 8, UNDERFLOW 16, INEXACT 32).
//    The value C reads is host | quantum: fetestexcept(m) = host call | (FLAGS & m).
//  The quantum part is an SSA variable of the OUTPUT function (cq-hzji): its value at the end of each
//  output block where it changed, and at a join of output blocks whose values differ a phi over handles
//  (Uncompute::recordMerge, rule 9 at a58c3a4), an empty / classical incoming made a rail where its edge
//  leaves (FLAGS: alloc_i32(0); MODE: alloc_i32 of the classical mode there). So a change on one
//  classical path holds after the join on that path only (cq-1dlz). Saved parts of confined fenv_t / fexcept_t
//  objects are SSA variables the same way, one per object.
//
// CONSTRUCTIONS
//  - A constrained op (llvm.experimental.constrained.*) is QUANTUM when an operand is a rail or it
//    rounds in the dynamic mode while MODE is a handle (80's quantum_mode_classical_op: a + b on
//    classical operands is cq_template_fadd_f64_ll_rmq). Its value template takes the mode last:
//    _rm with a classical i32 (a static rounding metadata as its FE_* literal; the dynamic mode as
//    the last classical fesetround constant of the same block, else a fegetround() host call), _rmq
//    with the MODE handle; round.tonearest takes none. round.tonearestaway has no x86-64 FE_* mode:
//    the x86 backend rounds such an op in the current mode (the metadata is an assumption LLVM's
//    codegen does not act on, LangRef), so it is the dynamic mode here (whatever LLVM does, we do).
//    With fpexcept.strict (ruling 2026-11-02, cq-75n4: ignore and maytrap raise nothing) a second template, the same with _exc, computes the
//    op's exception bits; under a quantum predicate they enter as select(flag, exc, 0) (100's
//    fenv_op_in_arm). FLAGS advances out of place: FLAGS' = or(FLAGS, bits); while FLAGS is empty the
//    bits rail becomes FLAGS. A compare's value is the plain fcmp template, its bits fcmps_exc
//    (signaling) or fcmp_exc (quiet). fmuladd is unfused (CR §2): fmul then fadd, each rounded in the
//    mode, bits or'ed. A vector op works per lane (rule 3): a lane with a rail (or rounding in the
//    MODE rail) is a template, every other lane the scalar host op. A classical constrained op is the
//    host op (it rounds in the host mode and raises into the host flags). Under a quantum predicate a
//    raising host op is bracketed (BRACKET): h = fetestexcept(ALL); feclearexcept(ALL); op;
//    bits = fetestexcept(ALL); feclearexcept(ALL); feraiseexcept(h) leaves the host flags as they
//    were and gives the op's bits classically, FLAGS |= select(p, bits, 0); a literal op folds (169).
//  - fesetround(r): r a classical constant and no quantum predicate: the host call, MODE classical
//    (an invalid constant changes nothing, also under a predicate: the host call alone). r classical
//    at run time while MODE is a handle: the host call, MODE' = valid(r) ? alloc(r) : MODE as a
//    classical select over handles (a merge). r quantum: MODE' = valid ? r : MODE with valid =
//    ((r & ~0xC00) == 0), the result valid ? 0 : 1; when known bits prove r valid, MODE' = r itself
//    (80). Under a quantum predicate p: MODE' = select(p, new, MODE). No host call when MODE' is a
//    handle (80, 100's fenv_quantum_mode).
//  - fegetround(): MODE's handle itself (no gate), or the host call.
//  - feraiseexcept(m): under a quantum predicate or with a quantum m, FLAGS' = FLAGS |
//    select(p, m & 63, 0) and no host call (65, 81); otherwise the host call.
//  - feclearexcept(m): the host call, and FLAGS' = FLAGS & ~m (81). Under a quantum predicate p with
//    a classical m: hb = fetestexcept(m), the host call, FLAGS' = select(p, FLAGS & ~m, FLAGS | hb).
//    A quantum m (FOLD: the host flags move into the rail): h = fetestexcept(ALL), feclearexcept(ALL),
//    T = FLAGS | h, FLAGS' = select(p, T & ~m, T) (T & ~m without a predicate).
//  - fetestexcept(m): the host call | (FLAGS & m), a fresh i32 (65, 81, 100).
//  - ENVIRONMENT OBJECTS (rule 23). Only the CONFINED shape (TaintInfo fenvObjectKind: an alloca whose every user is a
//    recognised fenv call taking the alloca itself) carries its quantum part as SSA, in the next four bullets. A
//    constant restores as the host call as it stands, its part empty (100). Every other object holds the whole
//    environment in its own bytes (objectLoad, objectMerge, objectCopy below; the choice for this target, with no
//    witness yet, CR §8): the exception-flag field is __mxcsr's low six bits at offset 4 of Darwin's 16-byte fenv_t,
//    where the host keeps the flags of SSE arithmetic and feraiseexcept, and all of the 2-byte fexcept_t; the
//    rounding-mode field is __control's bits 10-11 at offset 0, where fegetround reads the mode, FE_* values as they
//    stand. A save: the host call, then each non-empty part merged: a bus load, `or` (for the mode `and` of the rest
//    of the word, then `or`), a kept bus store. A restore: both fields loaded from the bus as the new flags rail and
//    mode, then the host call on a __cq_alloc copy (rule 22) with both fields stored as 0. "As 0" here is the mode bits
//    and the flags, in words stored classical from the live environment: the rest of each word holds the x87 and SSE
//    exception masks, zero they trap, and a host call cannot read cells that hold rails (the host reads a QUANTUM
//    cell's stale bytes); both words are then HOST, the masks the live ones (trap enables are not modelled). The mode
//    the host then holds is no authority: MODE' is a rail. Under a quantum predicate the host call would act on every
//    branch, so a save writes a fresh block and copies it `_controlled`, a restore makes no host call (FOLD below).
//    At an address rail a save goes through that block too and a restore copies from the rail.
//  - fegetexceptflag(o, m) / fesetexceptflag(o, m): the host calls; the object's quantum part is
//    FLAGS & m, reinstated as (FLAGS & ~m) | (saved & m) (100's fenv_narrow_mask). A quantum m: the
//    host save of every bit (C17 7.6.2.4: a later restore names a subset of m), the part FLAGS & m.
//  - fegetenv(e) / feholdexcept(e): the host call; e's quantum part is (MODE, FLAGS); feholdexcept
//    empties FLAGS. fesetenv(e): MODE, FLAGS := e's part; feupdateenv(e): MODE := e's mode, FLAGS :=
//    e's flags | FLAGS (100's fenv_dfl_env: FE_DFL_ENV has an empty quantum part). An object whose
//    quantum part this function never saved has an empty one.
//  - A save under a quantum predicate p makes the object's part FULL: rails holding its whole value
//    (select(p, now, before)), the host bytes left untouched and no longer read. "Before" of a part
//    that is not full is PROBED from the host object (fexcept_t: fesetexceptflag(o), fetestexcept,
//    then the host flags restored; fenv_t: fegetenv(tmp), fesetenv(o), fegetround, fetestexcept,
//    fesetenv(tmp)), of an object never saved on the path it is 0 (a restore of it is undefined).
//    A restore of a full part, or any restore under p, FOLDs: the host flags move into FLAGS and
//    FLAGS' / MODE' are computed on rails (select(p, restored, current) under p). Trap enables are not
//    part of the model (see LIMITS).
//  - feenableexcept / fedisableexcept / fegetexcept (not C17, no musl body): rule 27, not this module.
//
// ROLES. Every FLAGS state and every rail feeding one is uncomputed (Role::Garbage) except the
// FINAL flags rail, fenv state the caller can read, an output like 71's global (rule 23: "the final
// flags rail is an output"). The final quantum MODE is kept for the same reason (orchestrator
// decision under rule 23 and NORTHSTAR goal 2, recorded on cq-w1-eff-fenv). The state at each return
// of an entry is final (atEntryReturn, called by the spine before flushAtExit): kept itself when the
// entry has one return and it is no merge, else copied out (alloc_i32(0), copy_i32, the copy kept).
// Earlier, when the instruction is reached on every classical path, outside every loop, and
// no instruction that may change the state or measure is reachable after it (in the original CFG or
// in a later linearized quantum arm), its state is already final and kept then (settle). A state rail
// rule 2 makes classical (its sources measured, before or after it was computed: owner ruling
// cq-r6bc) is no output: it is uncomputed and its classical value written back to the host at the
// collapse point, feraiseexcept(v) / fesetround(m) (65; writeBack, after every measurement and
// every instruction this module lowers).
//
// ANCHOR. The state is no SSA value of the original program, so the spine's flushBefore could
// resolve a state rail at the end of its block before a later block reads it. Every rail this
// module keeps as state (MODE, FLAGS, saved parts) gets one extra noted use (Uncompute::noteUse) by
// a never-read `alloca i32` named cq.fenv in the output's entry block, the module's anchor: a
// non-call use keeps flushBefore off the rail, and flushAtExit places its uncompute after its real
// uses (Uncompute.cpp contract).
//
// LIMITS. Awaiting owner rulings (SPEC_ISSUES, each an internal compiler error naming its entry):
// a classical call
// of a body that reads, clears, saves or rounds in the environment while its quantum part is live;
// a quantum MODE passed into or returned from a clone (82's ABI carries a classical mode and returns
// only the flags; the mode clone's name is owed, CR §8); a constrained op with no rule 4 template
// (a libm intrinsic: its clone's mode parameter is the same owed name). Open (cq-v1fu, needs the loop module): a
// quantum change inside a classically bounded loop (its loop-carried state).
#include "cq/Effects.h"
#include "cq/Order.h"

#include <array>
#include <map>
#include <memory>
#include <optional>
#include <string>

#include "../../bus/BusInternal.h"
#include "cq/Abi.h"
#include "cq/Bus.h"
#include "cq/Calls.h"
#include "cq/Loops.h"
#include "cq/Predicate.h"
#include "cq/Taint.h"
#include "cq/Uncompute.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/FPEnv.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/Support/KnownBits.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace cq::fenv {

// E1 (Effects.h; contract at the end of this file).
bool cloneCarriesEnv(const TaintInfo &T, const Specialization &S);
std::array<Operand, 2> envArgs(LoweringContext &, CallBase &site);
void afterCloneCall(LoweringContext &, CallBase &site, Value *flagsOut);
void bindCloneEnv(LoweringContext &, Argument *mode, Argument *flags);
Value *cloneExitFlags(LoweringContext &, ReturnInst &);

namespace {

// x86-64 <fenv.h>: FE_ALL_EXCEPT and the rounding-control bits of an FE_* mode value.
constexpr int64_t kAllExcept = 63;
constexpr int64_t kModeBits = 0xC00;

// The SPEC_ISSUES entries this module's remaining stops await (owner rulings).
constexpr const char *kIssueHostCall =
    "awaiting owner ruling: SPEC_ISSUES rule 23: a classical call of a body that reads the live quantum environment";
constexpr const char *kIssueModeClone =
    "awaiting owner ruling: SPEC_ISSUES rule 23: a quantum rounding mode across a clone boundary";
constexpr const char *kIssueLibm =
    "awaiting owner ruling: SPEC_ISSUES rule 23: a constrained libm intrinsic with a quantum operand";
// Rule 23's objects on this target's libc (Darwin x86-64, <fenv.h>; the header at the top).
constexpr uint64_t kEnvBytes = 16, kEnvModeOff = 0, kEnvFlagsOff = 4, kXflagsBytes = 2;

// --------------------------------------------------------------------------------------------
// The <fenv.h> calls (C17 7.6), by name: a body-less callee with one of these names.

enum class FenvFn : uint8_t {
  None, ClearExcept, GetExceptFlag, RaiseExcept, SetExceptFlag, TestExcept, GetRound, SetRound,
  GetEnv, HoldExcept, SetEnv, UpdateEnv
};

FenvFn fenvFn(const CallBase &CB) {
  const Function *F = CB.getCalledFunction();
  if (!F || !hostCallee(*F))   // a body the bundle has is never lifted (rule 16, cq-rrc52)
    return FenvFn::None;
  static const std::pair<const char *, FenvFn> names[] = {
      {"feclearexcept", FenvFn::ClearExcept}, {"fegetexceptflag", FenvFn::GetExceptFlag},
      {"feraiseexcept", FenvFn::RaiseExcept}, {"fesetexceptflag", FenvFn::SetExceptFlag},
      {"fetestexcept", FenvFn::TestExcept},   {"fegetround", FenvFn::GetRound},
      {"fesetround", FenvFn::SetRound},       {"fegetenv", FenvFn::GetEnv},
      {"feholdexcept", FenvFn::HoldExcept},   {"fesetenv", FenvFn::SetEnv},
      {"feupdateenv", FenvFn::UpdateEnv}};
  // feenableexcept / fedisableexcept / fegetexcept are not C17 and have no musl body: rule 27, like any
  // bodiless callee (CR rule 23, cq-hzji 2026-11-02); not this module's.
  for (auto &[n, k] : names)
    if (F->getName() == n)
      return k;
  return FenvFn::None;
}

// CR rule 23 (ruling 2026-11-02, cq-75n4): only fpexcept.strict (FENV_ACCESS ON) raises observably;
// fpexcept.ignore and fpexcept.maytrap (-frounding-math without the pragma) raise nothing: no _exc, no
// flags rail.
bool raises(const ConstrainedFPIntrinsic &CI) {
  std::optional<fp::ExceptionBehavior> eb = CI.getExceptionBehavior();
  return eb && *eb == fp::ebStrict;
}

// Does this instruction hold or change the environment itself (rule 23: "a strict op or a fenv call")? A
// raising constrained op, a <fenv.h> call, a rounding intrinsic, or an indirect call (which may reach any).
// A non-raising constrained op only reads the mode (dynamicOp).
bool envOp(const Instruction &I) {
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB)
    return false;
  if (auto *CI = dyn_cast<ConstrainedFPIntrinsic>(CB))
    return raises(*CI);
  if (fenvFn(*CB) != FenvFn::None)
    return true;
  if (auto *II = dyn_cast<IntrinsicInst>(CB))
    return II->getIntrinsicID() == Intrinsic::set_rounding || II->getIntrinsicID() == Intrinsic::get_rounding;
  return !CB->getCalledFunction() && !CB->isInlineAsm();
}

// A constrained op that rounds in the dynamic mode (round.dynamic).
bool dynamicOp(const Instruction &I) {
  auto *CI = dyn_cast<ConstrainedFPIntrinsic>(&I);
  if (!CI)
    return false;
  std::optional<RoundingMode> rm = CI->getRoundingMode();
  return rm && *rm == RoundingMode::Dynamic;
}

// May this instruction change the FLAGS / MODE part (when it runs on quantum state)?
bool writesFlags(const Instruction &I) {
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB)
    return false;
  if (auto *CI = dyn_cast<ConstrainedFPIntrinsic>(CB))
    return raises(*CI);
  switch (fenvFn(*CB)) {
  case FenvFn::RaiseExcept: case FenvFn::ClearExcept: case FenvFn::SetExceptFlag:
  case FenvFn::SetEnv: case FenvFn::UpdateEnv: case FenvFn::HoldExcept:
    return true;
  default:
    return false;
  }
}

bool writesMode(const Instruction &I) {
  auto *CB = dyn_cast<CallBase>(&I);
  if (!CB)
    return false;
  if (auto *II = dyn_cast<IntrinsicInst>(CB))
    return II->getIntrinsicID() == Intrinsic::set_rounding;
  switch (fenvFn(*CB)) {
  case FenvFn::SetRound: case FenvFn::SetEnv: case FenvFn::UpdateEnv:
    return true;
  default:
    return false;
  }
}

// What a body does to the environment, through direct calls of bodies too. A raise alone is no
// conflict with a live quantum part (the host flags are its host part); a read, clear, save or
// restore of the flags, or a use or change of the dynamic mode, is (requireWritable).
struct BodyEnv {
  bool flags = false;   // reads, clears, saves or restores the flags
  bool mode = false;    // rounds in, reads, saves or changes the dynamic mode
  bool any = false;     // touches the environment at all
};

void bodyEnv(const Function &F, BodyEnv &e, SmallPtrSetImpl<const Function *> &seen) {
  if (!seen.insert(&F).second)
    return;
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      if (auto *CI = dyn_cast<ConstrainedFPIntrinsic>(CB)) {
        e.any = true;
        std::optional<RoundingMode> rm = CI->getRoundingMode();
        if (rm && *rm == RoundingMode::Dynamic)
          e.mode = true;
        continue;
      }
      switch (fenvFn(*CB)) {
      case FenvFn::None:
        break;
      case FenvFn::RaiseExcept:
        e.any = true;
        continue;
      case FenvFn::GetRound: case FenvFn::SetRound:
        e.any = e.mode = true;
        continue;
      case FenvFn::ClearExcept: case FenvFn::GetExceptFlag: case FenvFn::SetExceptFlag: case FenvFn::TestExcept:
        e.any = e.flags = true;
        continue;
      default:
        e.any = e.flags = e.mode = true;
        continue;
      }
      if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
        if (II->getIntrinsicID() == Intrinsic::set_rounding || II->getIntrinsicID() == Intrinsic::get_rounding)
          e.any = e.mode = true;
        continue;
      }
      const Function *G = CB->getCalledFunction();
      if (!G) {
        if (!CB->isInlineAsm())
          e.any = e.flags = e.mode = true;   // an indirect call may reach anything
        continue;
      }
      if (!hostCallee(*G))
        bodyEnv(*G, e, seen);
    }
}

// Does F access the environment itself (CR rule 23)? It is compiled under FENV_ACCESS (strictfp) or
// calls a <fenv.h> function. Where it does not, the environment is the default (C17 7.6.1): the flags
// its callees' clones return are fenv state the program never reads, uncomputed and dropped, never an
// output (169: __divdc3 and logb, compiled without the pragma, reaching the strictfp ilogb).
bool accessesEnv(const Function &F) {
  if (F.hasFnAttribute(Attribute::StrictFP))
    return true;
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB)
      if (auto *CB = dyn_cast<CallBase>(&I); CB && fenvFn(*CB) != FenvFn::None)
        return true;
  return false;
}

// Does F's own body touch the environment (constrained FP work, a <fenv.h> call, a rounding intrinsic,
// or an indirect call, which may reach anything)?
bool ownBodyTouchesFenv(const Function &F) {
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB)
      if (envOp(I))
        return true;
  return false;
}

// Does a function body (transitively through direct calls of bodies) hold or change the environment?
bool bodyTouchesFenv(const Function &F, SmallPtrSetImpl<const Function *> &seen) {
  if (!seen.insert(&F).second)
    return false;
  for (const BasicBlock &BB : F)
    for (const Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      if (envOp(I))
        return true;   // an indirect call may reach anything
      const Function *G = CB->getCalledFunction();
      if (G && !hostCallee(*G) && bodyTouchesFenv(*G, seen))
        return true;
    }
  return false;
}

// Rule 23 (ruling 2026-11-02, cq-75n4): the round.dynamic mode of a body that holds no environment itself
// is the mode at the root of its call chain: the default unless an ancestor on that chain holds the fenv
// state. The chain is the lowered one: the specializations taint lifts from the roots, the edges its
// callee specializations (direct and indirect candidates). A caller elsewhere in the module that holds
// the state (musl's fma calling scalbn) is not on the chain of a clone it does not reach (cq-4e6m: sin's
// __rem_pio2_large calling scalbn is the default chain, the plain templates). May S be reached from such
// an ancestor: a specialization whose body calls S and holds or changes the environment, itself or through
// its callees (bodyTouchesFenv), or is itself so reached? A clone shared by a default and a non-default
// chain carries the environment for both (its default callers pass mode 0 and an empty flags rail, which
// is exact).
bool sameSpec(const Specialization &a, const Specialization &b) {
  return a.F == b.F && a.mask == b.mask && a.ctl == b.ctl && a.pure == b.pure &&
         a.bounds == b.bounds;
}

bool callsSpec(const TaintInfo &T, const Specialization &P, const Specialization &S) {
  for (const BasicBlock &BB : *P.F)
    for (const Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB || CB->isInlineAsm())
        continue;
      if (const Function *G = CB->getCalledFunction()) {
        if (G != S.F)
          continue;
        if (const Specialization *cs = T.calleeSpecialization(*CB, P); cs && sameSpec(*cs, S))
          return true;
        continue;
      }
      for (auto &[G, cs] : T.calleeCandidates(*CB, P))
        if (G == S.F && cs && sameSpec(*cs, S))
          return true;
    }
  return false;
}

bool envReached(const TaintInfo &T, const Specialization &S, SmallVectorImpl<const Specialization *> &seen) {
  if (any_of(seen, [&](const Specialization *x) { return sameSpec(*x, S); }))
    return false;
  seen.push_back(&S);
  for (const Specialization &P : T.specializations()) {
    if (!P.F || P.F->isDeclaration() || !callsSpec(T, P, S))
      continue;
    SmallPtrSet<const Function *, 8> s2;
    if (bodyTouchesFenv(*P.F, s2) || envReached(T, P, seen))
      return true;
  }
  return false;
}

bool readsReachedMode(const TaintInfo &T, const Specialization &S) {
  if (!any_of(instructions(*S.F), [](const Instruction &I) { return dynamicOp(I); }))
    return false;
  SmallVector<const Specialization *, 8> seen;
  return envReached(T, S, seen);
}

// E1 (82): does a clone of S carry the environment (CR rule 23: "a clone that does constrained FP work
// takes the caller's mode and flags rail and returns the new flags rail beside its result")? Ruling
// 2026-11-02 (cq-75n4): its own body holds a strict op, a fenv call or a rounding intrinsic (envOp), or a
// call in it lifts (taint's callee specialization from S) a clone that carries it, or it reads the dynamic
// mode while an ancestor may hold the fenv state (readsReachedMode). fpexcept.ignore/maytrap work alone
// carries nothing: those ops are plain templates. A callee reached by an ordinary classical call runs on
// the host, what it raises is the host part (173, 174: __divsc3's logbf of a classical argument reaches
// the strictfp ilogbf; the references' clones take no environment). A body without the fenv state
// (accessesEnv) never carries it: it passes mode 0 and an empty flags rail to the carrying clones it
// lifts and drops the flags it gets back (169's __divdc3).
// Decided on the run's taint, so the caller, the clone's construction and the twin agree on the ABI
// (cq-xhv4).
bool liftsCarrying(const TaintInfo &T, const Specialization &S, SmallPtrSetImpl<const Specialization *> &seen);

bool carriesEnvImpl(const TaintInfo &T, const Specialization &S, SmallPtrSetImpl<const Specialization *> &seen) {
  // §1.4: a table clone's ABI follows from the C signature alone: it carries no environment.
  if (!S.F || S.F->isDeclaration() || S.isEntry() || S.table)
    return false;
  if (!seen.insert(&S).second)
    return false;   // a cycle of lifted calls: its bodies are judged where they are first reached
  if (ownBodyTouchesFenv(*S.F) || readsReachedMode(T, S))
    return true;
  // Rule 23 (ruling 2026-11-02): a body with the fenv state (FENV_ACCESS or -frounding-math: strictfp, or
  // a fenv call) that holds a strict op through a callee takes 82's ABI (169's __cq_q_logb_1(x, mode,
  // flags) lifting the strict ilogb). A body without it is a caller without the fenv state: it passes mode
  // 0 and an empty flags rail and drops the returned flags (169's __divdc3), even when a caller of its own
  // holds the state (C17 7.6.1: flags tested across code translated with FENV_ACCESS off are undefined).
  return liftsCarrying(T, S, seen) && accessesEnv(*S.F);
}

bool liftsCarrying(const TaintInfo &T, const Specialization &S, SmallPtrSetImpl<const Specialization *> &seen) {
  for (const BasicBlock &BB : *S.F)
    for (const Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      const Function *G = CB ? CB->getCalledFunction() : nullptr;
      if (!G || G->isDeclaration() || G->isIntrinsic())
        continue;
      if (const Specialization *cs = T.calleeSpecialization(*CB, S))
        if (carriesEnvImpl(T, *cs, seen))
          return true;
    }
  return false;
}

bool carriesEnvImpl(const TaintInfo &T, const Specialization &S) {
  SmallPtrSet<const Specialization *, 8> seen;
  return carriesEnvImpl(T, S, seen);
}

// --------------------------------------------------------------------------------------------
// Per-output-function state.

// A value of one SSA variable: the quantum part of the environment (KState) or the saved quantum part
// of one fenv_t (KEnv) / fexcept_t (KXflags) object.
struct Part {
  Value *flags = nullptr;   // handle or null (empty)
  Value *mode = nullptr;    // handle or null (classical: the host mode; of an object, its host bytes)
  std::optional<uint64_t> mask;   // fexcept_t: fegetexceptflag's mask when a constant
  bool full = false;        // object: the rails hold the whole saved value, the host bytes are stale
  bool saved = false;       // object: a save reached it on this path
  bool pending = false;     // a read around an output cycle (readStart), never stored
  bool same(const Part &o) const {
    return flags == o.flags && mode == o.mode && mask == o.mask && full == o.full && saved == o.saved;
  }
};

enum PartKind : unsigned { KState = 0, KEnv = 1, KXflags = 2 };
using Key = std::pair<const Value *, unsigned>;
const Key kState{nullptr, KState};

struct Var {
  DenseMap<BasicBlock *, Part> end;     // the value at the end of an output block where it changed
  DenseMap<BasicBlock *, Part> start;   // a merge made at the start of an output block
};

struct State {
  const Function *orig = nullptr;   // the walked original function (an entry's)
  std::map<Key, Var> vars;
  Part initial;                     // the state at the output's entry (a clone's bound flags)
  bool any = false;                 // some quantum part was made
  // The classical mode value known at a point of one original block.
  Value *modeVal = nullptr;
  const Instruction *modeValAt = nullptr;
  AllocaInst *anchor = nullptr;
  AllocaInst *probeEnv = nullptr;   // a scratch fenv_t for host probes
  DenseSet<const Value *> anchored;
  // E1 (82): in a clone carrying the environment, the caller's classical mode (its trailing mode
  // parameter), whether bindCloneEnv bound the trailing parameters, and whether the clone may change
  // the mode (then the classical mode is the host's).
  Value *cloneMode = nullptr;
  bool cloneBound = false;
  bool cloneWritesMode = false;
  DenseSet<const Value *> output;     // rails this module set Role::Output
  DenseSet<const Value *> copied;     // final state rails kept through a copy (keepFinal)
  DenseSet<const Value *> merges;     // phis and selects over handles this module recorded as merges
  // Rule 2 collapse probes (writeBack): private binding keys, one per state piece (0 FLAGS, 1 MODE).
  Instruction *probeKey[2] = {nullptr, nullptr};
  // Analyses of original functions (the walked one).
  std::map<const Function *, std::unique_ptr<DominatorTree>> dt;
  std::map<const Function *, std::unique_ptr<LoopInfo>> li;
  std::map<const Function *, std::unique_ptr<PostDominatorTree>> pdt;
  std::map<const Function *, DenseMap<const BasicBlock *, unsigned>> walk;   // the spine's order L
};

// Keyed by the output function. A key reused by a later module's function is reset on first use
// (orig differs).
std::map<const Function *, std::unique_ptr<State>> &states() {
  static thread_local std::map<const Function *, std::unique_ptr<State>> m;
  return m;
}

State &state(LoweringContext &ctx, const Module *M) {
  auto &p = states()[&ctx.out()];
  // The walked original is taken from the first context that reaches this output function.
  if (!p || (p->orig && p->orig->getParent() != M))
    p = std::make_unique<State>();
  if (!p->orig)
    p->orig = ctx.S.F;
  return *p;
}

// The state of the function being lowered. In a clone carrying the environment (E1), the spine binds
// the caller's mode and flags (bindCloneEnv) before it lowers any instruction (Construct.cpp's formal
// binding): a clone reaching this module unbound is a broken invariant of the pass.
State &state(LoweringContext &ctx, const Instruction &I) {
  State &st = state(ctx, I.getModule());
  if (!ctx.S.isEntry() && ctx.S.F && I.getFunction() == ctx.S.F && !st.cloneBound && carriesEnvImpl(ctx.T, ctx.S))
    internalError("eff-fenv: a clone carrying the floating-point environment reached before bindCloneEnv bound "
                  "the caller's mode and flags (E1, 82)",
                  &I);
  return st;
}

LoopInfo &loopInfo(State &st, const Function &F) {
  auto &d = st.dt[&F];
  if (!d)
    d = std::make_unique<DominatorTree>(const_cast<Function &>(F));
  auto &l = st.li[&F];
  if (!l)
    l = std::make_unique<LoopInfo>(*d);
  return *l;
}

PostDominatorTree &postDom(State &st, const Function &F) {
  auto &p = st.pdt[&F];
  if (!p)
    p = std::make_unique<PostDominatorTree>(const_cast<Function &>(F));
  return *p;
}

// --------------------------------------------------------------------------------------------
// Helpers over the lowering context.

bool isQ(LoweringContext &ctx, const Value *v) {
  if (isa<Constant>(v) || isa<BasicBlock>(v) || isa<MetadataAsValue>(v) || isa<InlineAsm>(v))
    return false;
  return ctx.T.isQuantum(v, ctx.S);
}

LLVMContext &C(LoweringContext &ctx) { return ctx.M.getContext(); }
RailType i32Rail() { return RailType{Kind::Int, 32}; }
ConstantInt *i32(LoweringContext &ctx, int64_t v) {
  return ConstantInt::get(Type::getInt32Ty(C(ctx)), v, /*IsSigned=*/true);
}

// The quantum control in scope: the block's quantum predicate (rule 8) and, under a rule-14 trip, the
// trip rail (cq-99f7: currentFlag() is the control, currentPredicate() does not see the trip).
Value *predicateFlag(LoweringContext &ctx) { return ctx.currentFlag(); }

// The original instruction copied to the host, operands remapped.
Instruction *copyHost(LoweringContext &ctx, Instruction &I) {
  Instruction *n = I.clone();
  for (unsigned i = 0; i < n->getNumOperands(); ++i) {
    Value *v = I.getOperand(i);
    if (isa<BasicBlock>(v) || isa<MetadataAsValue>(v) || isa<Function>(v) || isa<InlineAsm>(v))
      continue;
    Operand op = ctx.operand(v);
    if (op.handle)
      internalError("eff-fenv: a rail handle reaching a host call", &I);
    n->setOperand(i, op.v);
  }
  if (!I.getName().empty())
    n->setName(I.getName());
  ctx.B().Insert(n);
  return n;
}

// A host call of a <fenv.h> function of the original module with these arguments.
CallInst *hostCall(LoweringContext &ctx, const CallBase &like, ArrayRef<Value *> args) {
  return ctx.B().CreateCall(like.getFunctionType(), like.getCalledOperand(), args);
}

// A host call of a <fenv.h> function by name: i32 name(params).
CallInst *hostFn(LoweringContext &ctx, const char *name, ArrayRef<Value *> args) {
  SmallVector<Type *, 2> ps;
  for (Value *a : args)
    ps.push_back(a->getType());
  FunctionCallee f = ctx.M.getOrInsertFunction(name, FunctionType::get(Type::getInt32Ty(C(ctx)), ps, false));
  return ctx.B().CreateCall(f, args);
}

CallInst *hostGetRound(LoweringContext &ctx) { return hostFn(ctx, "fegetround", {}); }
CallInst *hostTest(LoweringContext &ctx, Value *m) { return hostFn(ctx, "fetestexcept", {m}); }
CallInst *hostClear(LoweringContext &ctx, Value *m) { return hostFn(ctx, "feclearexcept", {m}); }
CallInst *hostRaise(LoweringContext &ctx, Value *m) { return hostFn(ctx, "feraiseexcept", {m}); }

void anchor(LoweringContext &ctx, State &st, Value *h) {
  if (!st.anchor) {
    BasicBlock &E = ctx.out().getEntryBlock();
    IRBuilder<> B(&E, E.getFirstInsertionPt());
    st.anchor = B.CreateAlloca(Type::getInt32Ty(C(ctx)), nullptr, "cq.fenv");
  }
  if (st.anchored.insert(h).second)
    ctx.unc().noteUse(ctx.unc().idOf(h), st.anchor);
}

// A template of this module: emitted, recorded (Role::Garbage) and anchored.
Value *tmpl(LoweringContext &ctx, State &st, const abi::TemplateSpec &spec, ArrayRef<Operand> ops,
            const Value *orig = nullptr) {
  Value *h = ctx.emitTemplate(spec, ops, orig);
  anchor(ctx, st, h);
  return h;
}

abi::TemplateSpec intOp(const char *op, const char *shape) {
  abi::TemplateSpec s;
  s.op = op;
  s.w = i32Rail();
  s.shape = shape;
  return s;
}

// A fresh rail holding the classical i32 c (rule 7 seed), anchored.
Value *seed(LoweringContext &ctx, State &st, Value *c) {
  CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i32Rail()}, {c});
  ctx.unc().recordSeed(a);
  anchor(ctx, st, a);
  return a;
}

// a | b over FLAGS parts (null = empty).
Value *orFlags(LoweringContext &ctx, State &st, Value *a, Value *b) {
  if (!a)
    return b;
  if (!b)
    return a;
  return tmpl(ctx, st, intOp("or", ""), {Operand{a, true}, Operand{b, true}});
}

// h & m with m classical.
Value *andLit(LoweringContext &ctx, State &st, Value *h, Value *m) {
  return tmpl(ctx, st, intOp("and", "hl"), {Operand{h, true}, Operand{m, false}});
}

// ~m as a classical i32 (folded for a constant).
Value *notClassical(LoweringContext &ctx, Value *m) {
  if (auto *c = dyn_cast<ConstantInt>(m))
    return ConstantInt::get(c->getType(), ~c->getValue());
  return ctx.B().CreateNot(m);
}

// Bitwise ops over i32 operands, each a rail or a classical value; a classical result when both are.
Operand opOr(LoweringContext &ctx, State &st, Operand a, Operand b) {
  if (!a.handle && !b.handle)
    return Operand{ctx.B().CreateOr(a.v, b.v), false};
  if (!a.handle)
    std::swap(a, b);
  if (!b.handle)
    return Operand{tmpl(ctx, st, intOp("or", "hl"), {a, b}), true};
  return Operand{tmpl(ctx, st, intOp("or", ""), {a, b}), true};
}

Operand opAnd(LoweringContext &ctx, State &st, Operand a, Operand b) {
  if (!a.handle && !b.handle)
    return Operand{ctx.B().CreateAnd(a.v, b.v), false};
  if (!a.handle)
    std::swap(a, b);
  if (!b.handle)
    return Operand{tmpl(ctx, st, intOp("and", "hl"), {a, b}), true};
  return Operand{tmpl(ctx, st, intOp("and", ""), {a, b}), true};
}

Operand opNot(LoweringContext &ctx, State &st, Operand a) {
  if (!a.handle)
    return Operand{notClassical(ctx, a.v), false};
  return Operand{tmpl(ctx, st, intOp("xor", "hl"), {a, Operand{i32(ctx, -1), false}}), true};
}

// FOLD: r | c as a rail (r a rail or null, c classical).
Value *fold(LoweringContext &ctx, State &st, Value *r, Value *c) {
  if (!r)
    return seed(ctx, st, c);
  return tmpl(ctx, st, intOp("or", "hl"), {Operand{r, true}, Operand{c, false}});
}

// select(flag, a, b) on i32 arms (handles or classical values).
Value *select32(LoweringContext &ctx, State &st, Value *flag, Operand a, Operand b) {
  std::string sh;
  if (a.handle && b.handle)
    sh = "";
  else
    sh = std::string(a.handle ? "h" : "l") + (b.handle ? "h" : "l");
  abi::TemplateSpec s;
  s.op = "select";
  s.w = i32Rail();
  s.shape = sh;
  return tmpl(ctx, st, s, {Operand{flag, true}, a, b});
}

// Binds a lowered fenv result; taint decides the kind. A classical value taint calls quantum
// becomes a seed rail of that value (rule 7); a rail taint calls classical is a taint bug.
void bindResult(LoweringContext &ctx, const CallBase &CB, Operand r) {
  if (CB.getType()->isVoidTy())
    return;
  bool q = isQ(ctx, &CB);
  if (r.handle && !q)
    internalError("eff-fenv: a quantum fenv result that taint calls classical (rule 23 taint)", &CB);
  if (!r.handle && q) {
    if (CB.use_empty())
      return;
    RailType w = railTypeOf(CB.getType());
    CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {r.v});
    ctx.unc().recordSeed(a);
    r = Operand{a, true};
  }
  ctx.bindFields(&CB, {r});
}

// The classical mode at the builder's point, read afresh (no cache).
Value *classicalModeNow(LoweringContext &ctx, State &st) {
  if (st.cloneBound && !st.cloneWritesMode)
    return st.cloneMode;   // E1: the caller's mode, which the clone does not change
  if (!st.cloneBound && !accessesEnv(*ctx.S.F))
    return i32(ctx, 0);    // a function without the fenv state runs in the default environment (169)
  return hostGetRound(ctx);
}

// The scratch fenv_t of the host probes, in the output's entry block.
AllocaInst *probeEnvObject(LoweringContext &ctx, State &st) {
  if (!st.probeEnv) {
    BasicBlock &E = ctx.out().getEntryBlock();
    IRBuilder<> B(&E, E.getFirstInsertionPt());
    st.probeEnv = B.CreateAlloca(ArrayType::get(Type::getInt8Ty(C(ctx)), 64), nullptr, "cq.fenv.probe");
    st.probeEnv->setAlignment(Align(16));
  }
  return st.probeEnv;
}

// PROBE of an object's host bytes, the host environment left as it was. fexcept_t: the bits it holds
// under its saving mask (63 when not a constant: the bytes hold no other bits, C17 7.6.2.4).
Value *probeXflags(LoweringContext &ctx, Value *obj, std::optional<uint64_t> mask) {
  Value *mm = i32(ctx, mask ? int64_t(*mask & kAllExcept) : kAllExcept);
  Value *h = hostTest(ctx, i32(ctx, kAllExcept));
  hostClear(ctx, mm);   // a host fesetexceptflag may only raise (macOS libm): start from no bits
  hostFn(ctx, "fesetexceptflag", {obj, mm});
  Value *hb = hostTest(ctx, mm);
  hostClear(ctx, i32(ctx, kAllExcept));
  hostRaise(ctx, h);
  return hb;
}

// fenv_t: its mode and flags.
std::pair<Value *, Value *> probeEnv(LoweringContext &ctx, State &st, Value *obj) {
  AllocaInst *tmp = probeEnvObject(ctx, st);
  hostFn(ctx, "fegetenv", {tmp});
  hostFn(ctx, "fesetenv", {obj});
  Value *hm = hostGetRound(ctx);
  Value *hf = hostTest(ctx, i32(ctx, kAllExcept));
  hostFn(ctx, "fesetenv", {tmp});
  return {hm, hf};
}

// The output pointer of a save object (a local or a global: requireSaveTarget, mergeAt).
Value *objectPtr(LoweringContext &ctx, const Value *obj) {
  Operand o = ctx.operand(obj);
  if (o.handle)
    internalError("eff-fenv: a fenv object pointer that is a rail", obj);
  return o.v;
}

// --------------------------------------------------------------------------------------------
// The SSA variables over the output CFG.

// One read (readAt): the blocks on the walk's stack with their depths, and the value at the start of every block
// this read already settled. Without the memo a read walks every path of the output CFG back to the defining blocks,
// exponential in a chain of classical diamonds with no definition (cq-e0tq: musl __rem_pio2_large's cutoff loops
// under sinf, every op reading the mode). `low` is the least stack depth a pending read in the current subtree hit:
// a block's value is settled when no pending below it refers to a block above it (then it is the same in every
// walk of this read), and only a settled value is kept. Nothing a read does adds blocks, edges or definitions.
struct ReadWalk {
  DenseMap<BasicBlock *, unsigned> onStack;
  DenseMap<BasicBlock *, Part> settled;
  unsigned low = ~0u;
};

Part readStart(LoweringContext &ctx, State &st, const Key &k, BasicBlock *B, ReadWalk &w);

Part readEnd(LoweringContext &ctx, State &st, const Key &k, BasicBlock *B, ReadWalk &w) {
  Var &v = st.vars[k];
  auto it = v.end.find(B);
  if (it != v.end.end())
    return it->second;
  return readStart(ctx, st, k, B, w);
}

// The part of an object made FULL at the builder's point (its rails hold the whole value).
Part toFull(LoweringContext &ctx, State &st, const Key &k, Part p) {
  if (p.full)
    return p;
  Part r = p;
  r.full = true;
  if (!p.saved) {
    // Never saved on this path: a restore reads an indeterminate object (undefined); 0.
    r.flags = seed(ctx, st, i32(ctx, 0));
    if (k.second == KEnv)
      r.mode = p.mode ? p.mode : seed(ctx, st, i32(ctx, 0));
    return r;
  }
  Value *obj = objectPtr(ctx, k.first);
  if (k.second == KXflags) {
    r.flags = fold(ctx, st, p.flags, probeXflags(ctx, obj, p.mask));
    return r;
  }
  auto [hm, hf] = probeEnv(ctx, st, obj);
  r.mode = p.mode ? p.mode : seed(ctx, st, hm);
  r.flags = fold(ctx, st, p.flags, hf);
  return r;
}

// One field of a merge at the start of B: the common value, or a phi over handles (a merge), a missing
// incoming made by `make` where its edge leaves.
Value *mergeField(LoweringContext &ctx, State &st, BasicBlock *B, ArrayRef<BasicBlock *> ups, ArrayRef<Part> ps,
                  Value *Part::*f, function_ref<Value *(unsigned)> make) {
  bool same = true;
  for (const Part &p : ps)
    same &= p.*f == ps.front().*f;
  if (same)
    return ps.front().*f;
  DenseMap<BasicBlock *, Value *> in;
  for (unsigned i = 0; i < ups.size(); ++i) {
    Value *v = ps[i].*f;
    if (!v) {
      IRBuilderBase::InsertPointGuard g(ctx.B());
      ctx.B().SetInsertPoint(ups[i]->getTerminator());
      v = make(i);
    }
    in[ups[i]] = v;
  }
  SmallVector<BasicBlock *, 4> preds(predecessors(B));
  PHINode *phi = PHINode::Create(Type::getInt32Ty(C(ctx)), unsigned(preds.size()), "cq.fenv.merge");
  phi->insertInto(B, B->begin());
  for (BasicBlock *P : preds)
    phi->addIncoming(in.lookup(P), P);
  ctx.unc().recordMerge(phi);
  st.merges.insert(phi);
  anchor(ctx, st, phi);
  return phi;
}

Part mergeAt(LoweringContext &ctx, State &st, const Key &k, BasicBlock *B, ArrayRef<BasicBlock *> preds,
             ArrayRef<Part> in) {
  SmallVector<BasicBlock *, 4> ups;
  SmallVector<Part, 4> ps;
  for (unsigned i = 0; i < preds.size(); ++i)
    if (!is_contained(ups, preds[i])) {
      ups.push_back(preds[i]);
      ps.push_back(in[i]);
    }
  bool obj = k.second != KState;
  bool anyFull = obj && any_of(ps, [](const Part &p) { return p.full; });
  if (anyFull)
    for (unsigned i = 0; i < ups.size(); ++i)
      if (!ps[i].full) {
        IRBuilderBase::InsertPointGuard g(ctx.B());
        ctx.B().SetInsertPoint(ups[i]->getTerminator());
        ps[i] = toFull(ctx, st, k, ps[i]);
      }
  Part r;
  r.full = anyFull;
  r.saved = any_of(ps, [](const Part &p) { return p.saved; });
  r.mask = ps.front().mask;
  for (const Part &p : ps)
    if (p.mask != r.mask)
      r.mask = std::nullopt;
  r.flags = mergeField(ctx, st, B, ups, ps, &Part::flags, [&](unsigned) { return seed(ctx, st, i32(ctx, 0)); });
  if (k.second != KXflags)
    r.mode = mergeField(ctx, st, B, ups, ps, &Part::mode, [&](unsigned i) -> Value * {
      if (!obj)
        return seed(ctx, st, classicalModeNow(ctx, st));
      if (!ps[i].saved)
        return seed(ctx, st, i32(ctx, 0));
      return seed(ctx, st, probeEnv(ctx, st, objectPtr(ctx, k.first)).first);
    });
  return r;
}

Part readStart(LoweringContext &ctx, State &st, const Key &k, BasicBlock *B, ReadWalk &w) {
  {
    Var &v = st.vars[k];
    auto it = v.start.find(B);
    if (it != v.start.end())
      return it->second;
  }
  if (auto it = w.settled.find(B); it != w.settled.end())
    return it->second;
  SmallVector<BasicBlock *, 4> preds(predecessors(B));
  if (preds.empty())
    return k == kState ? st.initial : Part{};
  if (auto it = w.onStack.find(B); it != w.onStack.end()) {
    w.low = std::min(w.low, it->second);
    Part p;
    p.pending = true;
    return p;
  }
  unsigned depth = w.onStack.size(), outerLow = w.low;
  w.onStack[B] = depth;
  w.low = ~0u;
  SmallVector<Part, 4> in;
  for (BasicBlock *P : preds)
    in.push_back(readEnd(ctx, st, k, P, w));
  w.onStack.erase(B);
  bool settles = w.low >= depth;   // every pending below B was a read of B itself
  w.low = std::min(outerLow, w.low);
  const Part *first = nullptr;
  bool anyPending = false, differ = false;
  for (const Part &p : in) {
    if (p.pending) {
      anyPending = true;
      continue;
    }
    if (!first)
      first = &p;
    else if (!first->same(p))
      differ = true;
  }
  if (!first) {
    Part p;
    p.pending = true;
    return p;
  }
  if (!differ) {
    if (settles)
      w.settled[B] = *first;
    return *first;
  }
  if (anyPending)
    internalError("eff-fenv: the floating-point environment state differs around an output cycle (requirePlaced "
                  "admits no change in a classically bounded loop)",
                  B->getTerminator() ? (const Value *)B->getTerminator() : (const Value *)B);
  Part m = mergeAt(ctx, st, k, B, preds, in);
  st.vars[k].start[B] = m;
  return m;
}

Part readAt(LoweringContext &ctx, State &st, const Key &k) {
  ReadWalk w;
  Part p = readEnd(ctx, st, k, ctx.B().GetInsertBlock(), w);
  if (p.pending)
    internalError("eff-fenv: the floating-point environment state read on an output cycle with no entry");
  return p;
}

Part cur(LoweringContext &ctx, State &st) { return readAt(ctx, st, kState); }

void define(LoweringContext &ctx, State &st, const Key &k, Part p) {
  if (p.flags)
    anchor(ctx, st, p.flags);
  if (p.mode)
    anchor(ctx, st, p.mode);
  if (p.flags || p.mode)
    st.any = true;
  st.vars[k].end[ctx.B().GetInsertBlock()] = p;
}

void setFlags(LoweringContext &ctx, State &st, Value *f) {
  Part p = cur(ctx, st);
  if (p.flags == f)
    return;
  p.flags = f;
  define(ctx, st, kState, p);
}

void setMode(LoweringContext &ctx, State &st, Value *m) {
  Part p = cur(ctx, st);
  st.modeVal = nullptr;
  if (p.mode == m)
    return;
  p.mode = m;
  define(ctx, st, kState, p);
}

// --------------------------------------------------------------------------------------------
// Where the quantum part may change.

// Is B reached on every classical path of its function: every block it is control dependent on,
// transitively, ends in a quantum terminator (whose arms the spine linearizes)?
bool classicallyTop(LoweringContext &ctx, State &st, const BasicBlock *B) {
  const Function &F = *B->getParent();
  PostDominatorTree &PDT = postDom(st, F);
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 8> work{B};
  seen.insert(B);
  while (!work.empty()) {
    const BasicBlock *X = work.pop_back_val();
    for (const BasicBlock &Y : F) {
      const Instruction *t = Y.getTerminator();
      if (!t || t->getNumSuccessors() < 2)
        continue;
      bool cd = false;
      for (const BasicBlock *s : successors(&Y))
        if ((s == X || PDT.dominates(X, s)) && !(X != &Y && PDT.dominates(X, &Y)))
          cd = true;
      if (!cd)
        continue;
      bool quantum = false;
      if (auto *br = dyn_cast<BranchInst>(t))
        quantum = br->isConditional() && isQ(ctx, br->getCondition());
      else if (auto *sw = dyn_cast<SwitchInst>(t))
        quantum = isQ(ctx, sw->getCondition());
      if (!quantum)
        return false;
      if (seen.insert(&Y).second)
        work.push_back(&Y);
    }
  }
  return true;
}

// Instructions reachable strictly after I in its function (I itself again only through a cycle).
template <typename Pred> bool anyAfter(const Instruction &I, Pred p) {
  for (const Instruction *n = I.getNextNode(); n; n = n->getNextNode())
    if (p(*n))
      return true;
  SmallPtrSet<const BasicBlock *, 16> seen;
  SmallVector<const BasicBlock *, 16> work;
  for (const BasicBlock *s : successors(I.getParent()))
    if (seen.insert(s).second)
      work.push_back(s);
  while (!work.empty()) {
    const BasicBlock *b = work.pop_back_val();
    for (const Instruction &n : *b)
      if (p(n))
        return true;
    for (const BasicBlock *s : successors(b))
      if (seen.insert(s).second)
        work.push_back(s);
  }
  return false;
}

// The spine's walk order L of F's blocks (spine/Construct.cpp Walker::plan: reverse post-order with
// successors visited last to first, so a quantum branch's then arm is linearized before its else arm).
const DenseMap<const BasicBlock *, unsigned> &walkOrder(State &st, const Function &F) {
  auto &idx = st.walk[&F];
  if (!idx.empty())
    return idx;
  std::vector<const BasicBlock *> post;
  SmallPtrSet<const BasicBlock *, 32> seen;
  std::vector<std::pair<const BasicBlock *, unsigned>> stack;
  const BasicBlock *E = &F.getEntryBlock();
  seen.insert(E);
  stack.push_back({E, E->getTerminator()->getNumSuccessors()});
  while (!stack.empty()) {
    auto &[b, k] = stack.back();
    if (k == 0) {
      post.push_back(b);
      stack.pop_back();
      continue;
    }
    const BasicBlock *s = b->getTerminator()->getSuccessor(--k);
    if (seen.insert(s).second)
      stack.push_back({s, s->getTerminator()->getNumSuccessors()});
  }
  unsigned n = 0;
  for (auto it = post.rbegin(); it != post.rend(); ++it)
    idx[*it] = n++;
  return idx;
}

// Instructions the output runs after I although the original CFG does not reach them from I: those
// of a later arm of a quantum branch I's block is in, linearized after it (rules 8, 9, 13). A block
// y counts when it comes after I's block x in the spine's walk, is not reachable from x, and the
// nearest common dominator of x and y ends in a quantum terminator (the spine's next(), cq-kti4).
template <typename Pred>
bool anyLinearizedAfter(LoweringContext &ctx, State &st, const Instruction &I, Pred p) {
  const BasicBlock *x = I.getParent();
  const Function &F = *x->getParent();
  const auto &idx = walkOrder(st, F);
  loopInfo(st, F);
  DominatorTree &DT = *st.dt[&F];
  SmallPtrSet<const BasicBlock *, 32> reach;
  SmallVector<const BasicBlock *, 16> work{x};
  while (!work.empty())
    for (const BasicBlock *s : successors(work.pop_back_val()))
      if (reach.insert(s).second)
        work.push_back(s);
  unsigned ix = idx.lookup(x);
  for (const BasicBlock &Y : F) {
    auto it = idx.find(&Y);
    if (it == idx.end() || it->second <= ix || reach.count(&Y))
      continue;
    const BasicBlock *d = DT.findNearestCommonDominator(const_cast<BasicBlock *>(x),
                                                          const_cast<BasicBlock *>(&Y));
    if (!d)
      continue;
    const Instruction *t = d->getTerminator();
    bool quantum = false;
    if (auto *br = dyn_cast<BranchInst>(t))
      quantum = br->isConditional() && isQ(ctx, br->getCondition());
    else if (auto *sw = dyn_cast<SwitchInst>(t))
      quantum = isQ(ctx, sw->getCondition());
    if (!quantum)
      continue;
    for (const Instruction &n : Y)
      if (p(n))
        return true;
  }
  return false;
}

// The quantum part (state or a saved part) may change here. A classically bounded loop (rule 14 cases
// 1 and 3, loops::lowerClassical) keeps a real loop in the output: a state it changes is loop-carried,
// a header phi over handles with its back edge and the reverse loop's mirror (not built yet: build step
// 5). A quantum-exit loop (case 2) is unrolled trip by trip under the trip rail (cq-99f7): its changes
// are straight-line state changes under predicateFlag, nothing more.
void requirePlaced(LoweringContext &ctx, State &st, const Instruction &I) {
  if (I.getFunction() != ctx.S.F)
    return;   // not the walked function: its loops are no unit of this walk
  LoopInfo &LI = loopInfo(st, *I.getFunction());
  for (const Loop *L = LI.getLoopFor(I.getParent()); L; L = L->getParentLoop())
    if (loops::classify(*L, ctx.T, ctx.S) != loops::Case::QuantumExit)
      unimplemented("eff-fenv: the quantum floating-point environment changes inside a classically bounded loop "
                    "(rule 14 cases 1 and 3: a loop-carried rule 23 state, its header phi and the copy-out before the "
                    "reverse need the loop module, cq-v1fu)",
                    &I);
}

// The quantum part may change here (flags: the FLAGS part, mode: the MODE part). A later call that
// runs on the host and reads, clears, saves or rounds in that part would see the host part alone: a
// classical call of a body touching it (the call is not lifted, so no clone takes the quantum part),
// an indirect call, or llvm.set.rounding. A body that only raises is no conflict: its flags are host
// flags. A lifted call of a clone carrying the environment (E1, 82) takes the state.
void requireWritable(LoweringContext &ctx, State &st, const Instruction &I, bool flags, bool mode) {
  requirePlaced(ctx, st, I);
  const Instruction *bad = nullptr;
  anyAfter(I, [&](const Instruction &n) {
    auto *CB = dyn_cast<CallBase>(&n);
    if (!CB || isa<ConstrainedFPIntrinsic>(CB) || fenvFn(*CB) != FenvFn::None)
      return false;
    if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
      if (II->getIntrinsicID() == Intrinsic::set_rounding || II->getIntrinsicID() == Intrinsic::get_rounding)
        bad = mode ? &n : nullptr;
      return bad != nullptr;
    }
    const Function *G = CB->getCalledFunction();
    if (G && hostCallee(*G))
      return false;   // a library function leaves the mode alone; what it raises is host flags
    if (CB->isInlineAsm())
      return false;
    BodyEnv e;
    if (G) {
      SmallPtrSet<const Function *, 8> seen;
      bodyEnv(*G, e, seen);
    } else {
      e.any = e.flags = e.mode = true;
    }
    if (!e.any || !((flags && e.flags) || (mode && e.mode)))
      return false;
    // E1 (82): a call of a clone carrying the environment takes the state and returns the new flags.
    if (G && n.getFunction() == ctx.S.F && calls::classify(*CB, ctx.T, ctx.S) == calls::Class::Lift)
      if (const Specialization *cs = ctx.T.calleeSpecialization(*CB, ctx.S);
          cs && !cs->isEntry() && carriesEnvImpl(ctx.T, *cs))
        return false;
    bad = &n;
    return true;
  });
  if (bad)
    unimplemented(kIssueHostCall, bad);
}

// The classical value rail h holds at the builder's point when rule 2 collapses it (every source a
// measured rail or classical, at least one measured), else nullptr. The spine's collapse is reached
// through LoweringContext::operand: h is bound to a private key of this module, a detached
// instruction no original program has, so the query reads exactly what operand() of an original
// value bound to h would read. The keys are never freed: a binding outlives this module's state.
Value *collapsedValue(LoweringContext &ctx, State &st, unsigned which, Value *h) {
  Instruction *&key = st.probeKey[which];
  if (!key) {
    key = new AllocaInst(Type::getInt32Ty(C(ctx)), 0, nullptr, Align(4), "", static_cast<Instruction *>(nullptr));
    ctx.bindFields(key, {Operand{h, true}});
  } else {
    ctx.rebind(key, {Operand{h, true}});
  }
  Operand op = ctx.operand(key);
  return op.handle ? nullptr : op.v;
}

// CR rule 2 with rule 23 (owner ruling cq-r6bc, 2026-10-29): a FLAGS or MODE rail computed only from
// measured rails and classical values (data flow, not program order: it may predate the
// measurement) collapses. Its rail is uncomputed (Role::Garbage again if this module had made it
// the final output; the spine's flush uncomputes it while its measured sources hold the outcome),
// and its classical value is written to the HOST environment at the collapse point:
// feraiseexcept(v) for the flags (v = 0 raises nothing), fesetround(m) for the mode. The quantum
// part is then empty / classical, so rule 23's final-rail output covers only what stays quantum.
// Called after every measurement (afterMeasure) and after every instruction this module lowers (a
// state set from a saved part may already be classical). Saved parts in fenv_t / fexcept_t objects
// stay rails until a restore makes them the state. The write-back moves the state from the rail to
// the host where the builder is: the state rail is the state on every path through this point (its
// SSA value here; a quantum predicate's arms are linearized, so it already holds both arms' state), so
// one host write is exact under a quantum predicate, in a classical arm (the other path keeps its own
// state, merged at the join), in a trip and in a clone (a carrying clone returns an empty flags rail
// then: cloneExitFlags).
void writeBack(LoweringContext &ctx, State &st, const Instruction &I) {
  if (!st.any)
    return;
  Part p = cur(ctx, st);
  for (unsigned which = 0; which < 2; ++which) {
    Value *h = which == 0 ? p.flags : p.mode;
    if (!h)
      continue;
    Value *v = collapsedValue(ctx, st, which, h);
    if (!v)
      continue;
    Type *i32Ty = Type::getInt32Ty(C(ctx));
    if (v->getType() != i32Ty)
      internalError("eff-fenv: a collapsed fenv state of a type other than i32", &I);
    hostFn(ctx, which == 0 ? "feraiseexcept" : "fesetround", {v});
    if (st.output.erase(h))
      ctx.unc().setRole(ctx.unc().idOf(h), Role::Garbage);
    if (which == 0) {
      setFlags(ctx, st, nullptr);
    } else {
      setMode(ctx, st, nullptr);
      st.modeVal = v;
      st.modeValAt = &I;
    }
  }
}

// A cq_measure of the CQ.h surface (cq_measure_<T>).
bool isMeasure(const Instruction &I) {
  auto *CB = dyn_cast<CallBase>(&I);
  const Function *G = CB ? CB->getCalledFunction() : nullptr;
  return G && G->getName().starts_with("cq_measure");
}

// Does the walked function have exactly one return? Then the state at it is the state on every path
// that ends.
bool oneReturn(const Function &F) {
  unsigned n = 0;
  for (const BasicBlock &BB : F)
    n += isa<ReturnInst>(BB.getTerminator());
  return n == 1;
}

// A final state rail kept (Role::Output): itself when it is the final state on every path (the function's
// only return, or settle's early final) and no merge, else a copy (alloc_i32(0), copy_i32, the copy
// kept, the rail uncomputed after it).
void keepFinal(LoweringContext &ctx, State &st, Value *h, bool everyPath) {
  if (!h || st.output.count(h) || st.copied.count(h))
    return;
  if (everyPath && !st.merges.count(h)) {
    ctx.unc().setRole(ctx.unc().idOf(h), Role::Output);
    st.output.insert(h);
    return;
  }
  CallInst *f = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, i32Rail()}, {i32(ctx, 0)});
  RailId fid = ctx.unc().recordSeed(f);
  abi::CoreSpec cp{abi::Core::Copy, i32Rail()};
  CallInst *c = ctx.emitCore(cp, {h, f});
  ctx.unc().recordCore(c, cp, {Operand{h, true}, Operand{f, true}}, fid);
  ctx.unc().setRole(fid, Role::Output);
  st.output.insert(f);
  st.copied.insert(h);
}

// After every lowered instruction (and every measurement): rule 2's write-back, then the early final
// state (ROLES): I is reached on every classical path, outside every loop, in the walked function, and
// no writer or measurement is reachable after it (in the original CFG or in a later linearized quantum
// arm). A measurement ahead may make the state classical (rule 2, writeBack), and an output's sources
// are freed after their last use, which its later uncompute would need. Every other final state is
// kept at the entry's returns (atEntryReturn).
void settle(LoweringContext &ctx, State &st, const Instruction &I) {
  writeBack(ctx, st, I);
  if (st.cloneBound)
    return;   // E1: a clone's final flags are copied out at its returns (cloneExitFlags), never an output
  if (!accessesEnv(*ctx.S.F) || !ctx.S.isEntry())
    return;   // the environment is the default here: what its callees raised is dropped (169)
  if (I.getFunction() != st.orig || loopInfo(st, *I.getFunction()).getLoopFor(I.getParent()) ||
      !classicallyTop(ctx, st, I.getParent()))
    return;
  Part p = cur(ctx, st);
  auto final = [&](bool (*writes)(const Instruction &)) {
    auto later = [&](const Instruction &n) { return writes(n) || isMeasure(n); };
    return !anyAfter(I, later) && !anyLinearizedAfter(ctx, st, I, later);
  };
  if (p.flags && !st.output.count(p.flags) && final(writesFlags))
    keepFinal(ctx, st, p.flags, true);
  if (p.mode && !st.output.count(p.mode) && final(writesMode))
    keepFinal(ctx, st, p.mode, true);
}

// --------------------------------------------------------------------------------------------
// The mode operand of a rounding op.

// Is the classical mode value cached at modeValAt still the mode at I (same original block, no call
// in between that may change it)?
bool cacheValid(const State &st, const Instruction &I) {
  if (!st.modeVal || !st.modeValAt || st.modeValAt->getParent() != I.getParent() ||
      !cq::comesBefore(st.modeValAt, &I))
    return false;
  for (const Instruction *n = st.modeValAt->getNextNode(); n && n != &I; n = n->getNextNode()) {
    auto *CB = dyn_cast<CallBase>(n);
    if (!CB || isa<ConstrainedFPIntrinsic>(CB))
      continue;
    if (auto *II = dyn_cast<IntrinsicInst>(CB)) {
      if (II->getIntrinsicID() == Intrinsic::set_rounding)
        return false;
      continue;
    }
    const Function *G = CB->getCalledFunction();
    if (G && G->isDeclaration() && (G->getName().starts_with("cq_") || G->getName().starts_with("__cq_")))
      continue;
    if (fenvFn(*CB) != FenvFn::None && !writesMode(*CB))
      continue;
    return false;
  }
  return true;
}

// The classical dynamic mode at I.
Value *classicalMode(LoweringContext &ctx, State &st, const Instruction &I) {
  if (st.cloneBound && !st.cloneWritesMode)
    return st.cloneMode;   // E1: the caller's mode
  if (!st.cloneBound && !accessesEnv(*ctx.S.F))
    return i32(ctx, 0);    // a function without the fenv state runs in the default environment: FE_TONEAREST
                           // (169's __divdc3; rule 23 ruling 2026-11-02: a default caller passes mode 0)
  if (cacheValid(st, I))
    return st.modeVal;
  st.modeVal = hostGetRound(ctx);
  st.modeValAt = &I;
  return st.modeVal;
}

struct ModeOp {
  abi::TemplateSpec::Rm rm = abi::TemplateSpec::NoRm;
  Operand v{nullptr, false};
  bool dynamic = false;
};

// CI lies in the clone being lowered (not a callee lowered into it) and that clone carries no environment.
bool defaultModeClone(LoweringContext &ctx, const ConstrainedFPIntrinsic &CI) {
  return ctx.S.F && CI.getFunction() == ctx.S.F && !carriesEnvImpl(ctx.T, ctx.S);
}

// The mode operand of a constrained op; the classical dynamic value is only fetched on `need`.
ModeOp modeOperand(LoweringContext &ctx, State &st, const ConstrainedFPIntrinsic &CI, bool need) {
  ModeOp m;
  std::optional<RoundingMode> rm = CI.getRoundingMode();
  if (!rm)
    return m;
  switch (*rm) {
  case RoundingMode::NearestTiesToEven:
    return m;
  case RoundingMode::TowardNegative:
    m.rm = abi::TemplateSpec::RmLit;
    m.v = Operand{i32(ctx, 1024), false};
    return m;
  case RoundingMode::TowardPositive:
    m.rm = abi::TemplateSpec::RmLit;
    m.v = Operand{i32(ctx, 2048), false};
    return m;
  case RoundingMode::TowardZero:
    m.rm = abi::TemplateSpec::RmLit;
    m.v = Operand{i32(ctx, 3072), false};
    return m;
  default:
    // round.dynamic, and round.tonearestaway, which x86-64 cannot hold: its backend rounds the op in
    // the current mode (header).
    break;
  }
  m.dynamic = true;
  Value *q = cur(ctx, st).mode;
  if (!ctx.S.isEntry() && !st.cloneBound && !q && defaultModeClone(ctx, CI))
    return m;   // rule 23 (ruling 2026-11-02): a clone that does not carry the environment rounds in the
                // default mode of its chain's root: the plain template (169's scalbn, 175's exp)
  if (q) {
    m.rm = abi::TemplateSpec::RmRail;
    m.v = Operand{q, true};
  } else if (need) {
    m.rm = abi::TemplateSpec::RmLit;
    m.v = Operand{classicalMode(ctx, st, CI), false};
  } else {
    m.rm = abi::TemplateSpec::RmLit;
  }
  return m;
}

// --------------------------------------------------------------------------------------------
// Constrained ops.

bool provablyNotNaN(const Value *v) {
  if (auto *c = dyn_cast<ConstantFP>(v))
    return !c->isNaN();
  return true;
}

const char *constrainedOp(Intrinsic::ID id) {
  switch (id) {
  case Intrinsic::experimental_constrained_fadd: return "fadd";
  case Intrinsic::experimental_constrained_fsub: return "fsub";
  case Intrinsic::experimental_constrained_fmul: return "fmul";
  case Intrinsic::experimental_constrained_fdiv: return "fdiv";
  case Intrinsic::experimental_constrained_frem: return "frem";
  case Intrinsic::experimental_constrained_fma: return "fma";
  case Intrinsic::experimental_constrained_sqrt: return "sqrt";
  case Intrinsic::experimental_constrained_rint: return "rint";
  case Intrinsic::experimental_constrained_floor: return "floor";
  case Intrinsic::experimental_constrained_ceil: return "ceil";
  case Intrinsic::experimental_constrained_trunc: return "trunc";
  case Intrinsic::experimental_constrained_round: return "round";
  case Intrinsic::experimental_constrained_maxnum: return "fmax";
  case Intrinsic::experimental_constrained_minnum: return "fmin";
  case Intrinsic::experimental_constrained_fptrunc: return "fptrunc";
  case Intrinsic::experimental_constrained_fpext: return "fpext";
  case Intrinsic::experimental_constrained_sitofp: return "sitofp";
  case Intrinsic::experimental_constrained_uitofp: return "uitofp";
  case Intrinsic::experimental_constrained_fptosi: return "fptosi";
  case Intrinsic::experimental_constrained_fptoui: return "fptoui";
  case Intrinsic::experimental_constrained_fcmp: return "fcmp";
  case Intrinsic::experimental_constrained_fcmps: return "fcmps";
  default: return nullptr;
  }
}

bool isCast(StringRef op) {
  return op == "fptrunc" || op == "fpext" || op == "sitofp" || op == "uitofp" || op == "fptosi" ||
         op == "fptoui";
}

// One quantum template step: its value spec and operands (mode last), and its _exc twin.
struct Step {
  abi::TemplateSpec spec;
  SmallVector<Operand, 4> ops;
};

// Builds the value template of op over data operands (handles or classical values) and the mode.
Step makeStep(StringRef op, CmpInst::Predicate pred, Type *wTy, Type *toTy, SmallVector<Operand, 3> data,
              const ModeOp &mode) {
  Step s;
  s.spec.op = op.str();
  s.spec.w = railTypeOf(wTy);
  if (toTy)
    s.spec.to = railTypeOf(toTy);
  bool fcmp = op == "fcmp" || op == "fcmps";
  if (fcmp) {
    // The value of a compare is the plain fcmp (81); compares never take _lh: flip the predicate.
    s.spec.op = "fcmp";
    if (!data[0].handle && data[1].handle) {
      std::swap(data[0], data[1]);
      pred = CmpInst::getSwappedPredicate(pred);
    }
    s.spec.pred = CmpInst::getPredicateName(pred).str();
    s.spec.shape = data[1].handle ? "" : "hl";
  } else if (data.size() == 1) {
    s.spec.shape = data[0].handle ? "" : "l";
  } else if (data.size() == 2) {
    bool comm = op == "fadd" || op == "fmul";
    if (data[0].handle && data[1].handle)
      s.spec.shape = "";
    else if (data[0].handle)
      s.spec.shape = "hl";
    else if (data[1].handle) {
      if (comm && provablyNotNaN(data[0].v)) {
        std::swap(data[0], data[1]);
        s.spec.shape = "hl";
      } else {
        s.spec.shape = "lh";
      }
    } else {
      s.spec.shape = "ll";
    }
  } else {
    // fma: one letter per operand, q or l, bare for qqq; the product operands commute unless the
    // literal is a NaN (CR §1.2).
    if (!data[0].handle && data[1].handle && provablyNotNaN(data[0].v))
      std::swap(data[0], data[1]);
    std::string sh;
    for (const Operand &o : data)
      sh += o.handle ? 'q' : 'l';
    s.spec.shape = sh == "qqq" ? "" : sh;
  }
  s.ops.append(data.begin(), data.end());
  if (!fcmp && mode.rm != abi::TemplateSpec::NoRm) {
    s.spec.rm = mode.rm;
    s.ops.push_back(mode.v);
  }
  return s;
}

// The exception bits of a step: the same template with _exc; a compare's are fcmps/fcmp_exc.
Value *excOf(LoweringContext &ctx, State &st, const Step &s, StringRef origOp) {
  abi::TemplateSpec e = s.spec;
  e.exc = true;
  if (origOp == "fcmp" || origOp == "fcmps")
    e.op = origOp.str();
  return tmpl(ctx, st, e, s.ops);
}

// FLAGS |= the bits I raised: a rail (bits), or classical (lit, a constant or a run-time i32 the host
// gave, BRACKET); under the quantum control they enter as select(flag, bits, 0).
void raiseBits(LoweringContext &ctx, State &st, const Instruction &I, Value *bits, Value *lit = nullptr) {
  Value *flag = predicateFlag(ctx);
  if (!bits) {
    if (!lit)
      internalError("eff-fenv: raiseBits without bits", &I);
    if (!flag) {
      hostRaise(ctx, lit);
      return;
    }
    bits = select32(ctx, st, flag, Operand{lit, false}, Operand{i32(ctx, 0), false});
  } else if (flag) {
    bits = select32(ctx, st, flag, Operand{bits, true}, Operand{i32(ctx, 0), false});
  }
  setFlags(ctx, st, orFlags(ctx, st, cur(ctx, st).flags, bits));
}

// A classical constrained op whose data operands are all literals (169's FORCE_EVAL(0/0.0f) in ilogb:
// sitofp(0) then fdiv(0.0f, 0.0f); data are the lowered operands, a folded one a literal), folded: its
// result and its exception bits (x86 FE_* values), the same in every rounding mode it may run in (a
// static mode, or all four for round.dynamic). nullopt when an operand is not a literal, the op is not
// one folded here, the bits include underflow (the tininess rule is the target's), or the result or
// bits depend on the mode.
struct Folded { Constant *result; uint32_t bits; };
std::optional<Folded> foldLiteralConstrained(const ConstrainedFPIntrinsic &CI, ArrayRef<Operand> data) {
  const char *op = constrainedOp(CI.getIntrinsicID());
  if (!op || CI.getType()->isVectorTy())
    return std::nullopt;
  StringRef o(op);
  for (const Operand &d : data)
    if (d.handle || (!isa<ConstantFP>(d.v) && !isa<ConstantInt>(d.v)))
      return std::nullopt;
  SmallVector<RoundingMode, 4> modes;
  std::optional<RoundingMode> rm = CI.getRoundingMode();
  if (rm && *rm != RoundingMode::Dynamic && *rm != RoundingMode::NearestTiesToAway)
    modes.push_back(*rm);
  else
    modes = {RoundingMode::NearestTiesToEven, RoundingMode::TowardPositive, RoundingMode::TowardNegative,
             RoundingMode::TowardZero};
  auto fpArg = [&](unsigned i) { return cast<ConstantFP>(data[i].v)->getValueAPF(); };
  std::optional<Folded> out;
  for (RoundingMode m : modes) {
    APFloat::opStatus stt = APFloat::opOK;
    Constant *res = nullptr;
    Type *T = CI.getType();
    if (o == "fadd" || o == "fsub" || o == "fmul" || o == "fdiv") {
      APFloat a = fpArg(0), b = fpArg(1);
      stt = o == "fadd" ? a.add(b, m) : o == "fsub" ? a.subtract(b, m) : o == "fmul" ? a.multiply(b, m)
                                                                         : a.divide(b, m);
      res = ConstantFP::get(T, a);
    } else if (o == "sitofp" || o == "uitofp") {
      auto *ci = dyn_cast<ConstantInt>(data[0].v);
      if (!ci)
        return std::nullopt;
      APFloat r(T->getFltSemantics());
      stt = r.convertFromAPInt(ci->getValue(), o == "sitofp", m);
      res = ConstantFP::get(T, r);
    } else if (o == "fptrunc" || o == "fpext") {
      APFloat a = fpArg(0);
      bool loses = false;
      stt = a.convert(T->getFltSemantics(), m, &loses);
      res = ConstantFP::get(T, a);
    } else {
      return std::nullopt;
    }
    if (stt & APFloat::opUnderflow)
      return std::nullopt;
    uint32_t bits = ((stt & APFloat::opInvalidOp) ? 1u : 0u) | ((stt & APFloat::opDivByZero) ? 4u : 0u) |
                    ((stt & APFloat::opOverflow) ? 8u : 0u) | ((stt & APFloat::opInexact) ? 32u : 0u);
    if (out && (out->bits != bits || out->result != res))
      return std::nullopt;
    out = Folded{res, bits};
  }
  return out;
}

// BRACKET (header): runs `body` on the host with the host flags saved and restored around it; returns
// the bits body raised (classical).
Value *bracket(LoweringContext &ctx, function_ref<void()> body) {
  Value *h = hostTest(ctx, i32(ctx, kAllExcept));
  hostClear(ctx, i32(ctx, kAllExcept));
  body();
  Value *bits = hostTest(ctx, i32(ctx, kAllExcept));
  hostClear(ctx, i32(ctx, kAllExcept));
  hostRaise(ctx, h);
  return bits;
}

// The lanes of an operand: its fields, or the elements of one classical vector value.
SmallVector<Operand, 4> lanesOf(LoweringContext &ctx, const Value *v, unsigned n) {
  if (n == 1)
    return {ctx.operand(v)};
  SmallVector<Operand, 4> f = ctx.fields(v);
  if (f.size() == n)
    return f;
  if (f.size() != 1 || f[0].handle || !f[0].v->getType()->isVectorTy())
    internalError("eff-fenv: a vector operand bound to neither its lanes nor one classical vector", v);
  SmallVector<Operand, 4> out;
  for (unsigned l = 0; l < n; ++l) {
    if (auto *c = dyn_cast<Constant>(f[0].v))
      out.push_back(Operand{c->getAggregateElement(l), false});
    else
      out.push_back(Operand{ctx.B().CreateExtractElement(f[0].v, uint64_t(l)), false});
  }
  return out;
}

// The scalar constrained intrinsic of a lane of CI, on the host with classical lane operands.
Value *hostLane(LoweringContext &ctx, const ConstrainedFPIntrinsic &CI, ArrayRef<Value *> lane) {
  Intrinsic::ID id = CI.getIntrinsicID();
  Type *ret = CI.getType()->getScalarType();
  SmallVector<Type *, 2> tys;
  StringRef o = constrainedOp(id) ? constrainedOp(id) : "";
  if (o == "fcmp" || o == "fcmps")
    tys = {CI.getArgOperand(0)->getType()->getScalarType()};
  else if (isCast(o))
    tys = {ret, CI.getArgOperand(0)->getType()->getScalarType()};
  else
    tys = {ret};
  Function *decl = Intrinsic::getDeclaration(&ctx.M, id, tys);
  SmallVector<Value *, 5> args(lane.begin(), lane.end());
  for (unsigned i = CI.getNonMetadataArgCount(); i < CI.arg_size(); ++i)
    args.push_back(CI.getArgOperand(i));
  CallInst *c = ctx.B().CreateCall(decl, args);
  c->setAttributes(CI.getAttributes());
  return c;
}

} // namespace

void lowerConstrained(LoweringContext &ctx, CallBase &CB) {
  auto &CI = cast<ConstrainedFPIntrinsic>(CB);
  State &st = state(ctx, CI);
  const char *op = constrainedOp(CI.getIntrinsicID());
  bool fmuladd = CI.getIntrinsicID() == Intrinsic::experimental_constrained_fmuladd;
  unsigned n = CI.getNonMetadataArgCount();
  // Rule 3: a vector op works per lane.
  Type *laneTy = n ? CI.getArgOperand(0)->getType() : CI.getType();
  auto *vty = dyn_cast<FixedVectorType>(CI.getType()->isVectorTy() ? CI.getType() : laneTy);
  if (CI.getType()->isVectorTy() != laneTy->isVectorTy())
    internalError("eff-fenv: a constrained op mixing vector and scalar operands", &CI);
  if (!vty && (CI.getType()->isVectorTy()))
    internalError("eff-fenv: a scalable vector in a C program", &CI);
  unsigned L = vty ? unsigned(vty->getNumElements()) : 1;
  SmallVector<SmallVector<Operand, 4>, 3> lanes;
  bool anyHandle = false;
  for (unsigned i = 0; i < n; ++i) {
    lanes.push_back(lanesOf(ctx, CI.getArgOperand(i), L));
    for (const Operand &o : lanes.back())
      anyHandle |= o.handle;
  }
  auto laneData = [&](unsigned l) {
    SmallVector<Operand, 3> d;
    for (unsigned i = 0; i < n; ++i)
      d.push_back(lanes[i][l]);
    return d;
  };
  ModeOp mode0 = modeOperand(ctx, st, CI, /*need=*/false);
  bool quantum = anyHandle || mode0.rm == abi::TemplateSpec::RmRail;

  if (!quantum) {
    // The host op: rounds in the host mode, raises into the host flags.
    if (raises(CI) && predicateFlag(ctx)) {
      // Its bits are quantum (raised only where the control holds). A literal op folds (169): the
      // folded value, no host op; any other is BRACKETed.
      SmallVector<Operand, 3> data = laneData(0);
      if (std::optional<Folded> f = L == 1 ? foldLiteralConstrained(CI, data) : std::nullopt) {
        if (f->bits) {
          requireWritable(ctx, st, CI, true, false);
          raiseBits(ctx, st, CI, nullptr, i32(ctx, f->bits));
        }
        bindResult(ctx, CB, Operand{f->result, false});
        settle(ctx, st, CI);
        return;
      }
      Instruction *h = nullptr;
      Value *bits = bracket(ctx, [&] { h = copyHost(ctx, CI); });
      requireWritable(ctx, st, CI, true, false);
      raiseBits(ctx, st, CI, nullptr, bits);
      bindResult(ctx, CB, Operand{h, false});
      settle(ctx, st, CI);
      return;
    }
    bindResult(ctx, CB, Operand{copyHost(ctx, CI), false});
    settle(ctx, st, CI);
    return;
  }
  if (!op && !fmuladd)
    unimplemented(kIssueLibm, &CI);
  if (!isQ(ctx, &CI))
    internalError("eff-fenv: a quantum constrained op that taint calls classical (rule 23 taint)", &CI);
  if (raises(CI))
    requireWritable(ctx, st, CI, true, false);
  ModeOp mode = modeOperand(ctx, st, CI, /*need=*/true);
  bool railMode = mode.rm == abi::TemplateSpec::RmRail;
  Value *flag = raises(CI) ? predicateFlag(ctx) : nullptr;
  StringRef o = op ? op : "fmuladd";
  bool fcmp = o == "fcmp" || o == "fcmps";
  Type *wTy = (isCast(o) || fcmp ? CI.getArgOperand(0)->getType() : CI.getType())->getScalarType();
  Type *toTy = isCast(o) ? CI.getType()->getScalarType() : nullptr;
  CmpInst::Predicate pred = CmpInst::BAD_FCMP_PREDICATE;
  if (auto *cmp = dyn_cast<ConstrainedFPCmpIntrinsic>(&CI))
    pred = cmp->getPredicate();

  // A lane is a template when it reads a rail (a rounding lane also when the mode is the MODE rail);
  // every other lane of a quantum vector op is the scalar host op. Host lanes and host products are
  // BRACKETed together under the control (their bits classical).
  auto isTemplateLane = [&](unsigned l, unsigned upto) {
    for (unsigned i = 0; i < upto; ++i)
      if (lanes[i][l].handle)
        return true;
    return railMode && !fcmp;
  };
  SmallVector<Operand, 4> result(L, Operand{nullptr, false});
  SmallVector<Value *, 4> prods(L, nullptr);   // fmuladd: a host product per lane
  auto hostWork = [&] {
    for (unsigned l = 0; l < L; ++l) {
      if (fmuladd) {
        if (!isTemplateLane(l, 2))
          prods[l] = ctx.B().CreateConstrainedFPBinOp(Intrinsic::experimental_constrained_fmul, lanes[0][l].v,
                                                      lanes[1][l].v, nullptr, "", nullptr, CI.getRoundingMode(),
                                                      CI.getExceptionBehavior());
        continue;
      }
      if (isTemplateLane(l, n))
        continue;
      SmallVector<Value *, 3> args;
      for (unsigned i = 0; i < n; ++i)
        args.push_back(lanes[i][l].v);
      result[l] = Operand{hostLane(ctx, CI, args), false};
    }
  };
  bool anyHost = false;
  for (unsigned l = 0; l < L; ++l)
    anyHost |= fmuladd ? !isTemplateLane(l, 2) : !isTemplateLane(l, n);
  Value *hostBits = nullptr;
  if (anyHost) {
    if (flag)
      hostBits = bracket(ctx, hostWork);
    else
      hostWork();
  }

  // A result is an ordinary value (never anchored); a scalar's is bound to CI where it is emitted.
  auto emitValue = [&](const Step &s) {
    return L == 1 ? ctx.emitTemplate(s.spec, s.ops, &CI) : ctx.emitTemplate(s.spec, s.ops);
  };
  Value *bits = nullptr;
  auto addBits = [&](Value *b) {
    bits = bits ? tmpl(ctx, st, intOp("or", ""), {Operand{bits, true}, Operand{b, true}}) : b;
  };
  for (unsigned l = 0; l < L; ++l) {
    SmallVector<Operand, 3> data = laneData(l);
    if (fmuladd) {
      // CR §2: unfused, fmul then fadd, each rounded in the mode.
      Operand prod{prods[l], false};
      if (!prods[l]) {
        Step mul = makeStep("fmul", pred, wTy, nullptr, {data[0], data[1]}, mode);
        prod = Operand{tmpl(ctx, st, mul.spec, mul.ops), true};
        if (raises(CI))
          addBits(excOf(ctx, st, mul, "fmul"));
      }
      if (!prod.handle && !data[2].handle && !railMode) {
        // A host product and a classical addend in a quantum vector op: the host fadd.
        Value *s = nullptr;
        auto addHost = [&] {
          s = ctx.B().CreateConstrainedFPBinOp(Intrinsic::experimental_constrained_fadd, prod.v, data[2].v,
                                               nullptr, "", nullptr, CI.getRoundingMode(), CI.getExceptionBehavior());
        };
        if (flag) {
          Value *b2 = bracket(ctx, addHost);
          hostBits = hostBits ? ctx.B().CreateOr(hostBits, b2) : b2;
        } else {
          addHost();
        }
        result[l] = Operand{s, false};
        continue;
      }
      Step add = makeStep("fadd", pred, wTy, nullptr, {prod, data[2]}, mode);
      result[l] = Operand{emitValue(add), true};
      if (raises(CI))
        addBits(excOf(ctx, st, add, "fadd"));
      continue;
    }
    if (result[l].v)
      continue;   // a host lane
    Step s = makeStep(o, pred, wTy, toTy, data, mode);
    result[l] = Operand{emitValue(s), true};
    if (raises(CI))
      addBits(excOf(ctx, st, s, o));
  }
  if (raises(CI)) {
    if (bits && hostBits)
      bits = tmpl(ctx, st, intOp("or", "hl"), {Operand{bits, true}, Operand{hostBits, false}});
    if (bits)
      raiseBits(ctx, st, CI, bits);
    else if (hostBits)
      raiseBits(ctx, st, CI, nullptr, hostBits);
  }
  if (L == 1) {
    if (!result[0].handle)
      internalError("eff-fenv: a quantum scalar constrained op lowered to a classical value", &CI);
  } else {
    for (Operand &r : result)
      if (!r.handle) {
        CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, railTypeOf(r.v->getType())}, {r.v});
        ctx.unc().recordSeed(a);
        r = Operand{a, true};
      }
    ctx.bindFields(&CI, result);
  }
  settle(ctx, st, CI);
}

namespace {

const Value *objectOf(const Value *p) { return getUnderlyingObject(p); }

// The saved part of the object p points to (an object never saved here has an empty one). A save target
// holding a quantum part is accessed by fenv calls only (requireSaveTarget), so a pointer whose
// underlying object is another one never reaches it.
Key keyOf(const Value *p, unsigned kind) { return Key{objectOf(p), kind}; }

void save(LoweringContext &ctx, State &st, const Key &k, Part s, const Instruction &I) {
  Part prev = readAt(ctx, st, k);
  bool q = s.mode || s.flags;
  if (q || prev.mode || prev.flags)
    requirePlaced(ctx, st, I);
  s.saved = true;
  define(ctx, st, k, s);
}

std::optional<uint64_t> constMask(Value *v) {
  if (auto *c = dyn_cast<ConstantInt>(v))
    return c->getZExtValue();
  return std::nullopt;
}

bool knownValidMode(LoweringContext &ctx, const Value *orig) {
  KnownBits k = computeKnownBits(orig, ctx.M.getDataLayout());
  APInt outside = ~APInt(k.getBitWidth(), kModeBits);
  return (k.Zero & outside) == outside;
}

// The whole value an object's part holds at the builder's point (FULL), as operands: a full part's
// rails, else the host bytes PROBEd under its quantum part, else (never saved) 0.
std::pair<Operand, Operand> wholeOf(LoweringContext &ctx, State &st, const Key &k, const Part &p) {
  Operand zero{i32(ctx, 0), false};
  if (p.full)
    return {p.mode ? Operand{p.mode, true} : zero, p.flags ? Operand{p.flags, true} : zero};
  if (!p.saved)
    return {p.mode ? Operand{p.mode, true} : zero, p.flags ? Operand{p.flags, true} : zero};
  Value *obj = objectPtr(ctx, k.first);
  if (k.second == KXflags)
    return {zero, Operand{fold(ctx, st, p.flags, probeXflags(ctx, obj, p.mask)), true}};
  auto [hm, hf] = probeEnv(ctx, st, obj);
  return {p.mode ? Operand{p.mode, true} : Operand{hm, false}, Operand{fold(ctx, st, p.flags, hf), true}};
}

// A memory object (rule 23, the header): its address on the bus.
Operand objectAddress(LoweringContext &ctx, const Value *p) { return bus::address(ctx, p); }

// A field loaded from the bus, zero-extended to the state's i32, and its bits.
Value *objectLoad(LoweringContext &ctx, State &st, Operand addr, uint64_t off, Type *T, int64_t bits) {
  Operand l{bus::emitLoad(ctx, T, bus::offsetAddress(ctx, addr, off)), true};
  anchor(ctx, st, l.v);
  Operand w = l;
  if (T->getIntegerBitWidth() < 32) {
    abi::TemplateSpec z;
    z.op = "zext";
    z.w = RailType{Kind::Int, T->getIntegerBitWidth()};
    z.to = RailType{Kind::Int, 32};
    w = Operand{tmpl(ctx, st, z, {l}), true};
  }
  return opAnd(ctx, st, w, Operand{i32(ctx, bits), false}).v;
}

// The field's word with `clear` bits cleared and `bits` (an i32 rail, or null) or'ed in, a kept bus store.
void objectMerge(LoweringContext &ctx, State &st, Operand addr, uint64_t off, Type *T, int64_t clear, Value *bits) {
  unsigned W = T->getIntegerBitWidth();
  RailType wt{Kind::Int, W};
  Operand field = bus::offsetAddress(ctx, addr, off);
  Operand v{bus::emitLoad(ctx, T, field), true};
  anchor(ctx, st, v.v);
  auto op = [&](const char *name, const char *shape, ArrayRef<Operand> ops) {
    abi::TemplateSpec t;
    t.op = name;
    t.w = wt;
    t.shape = shape;
    return Operand{tmpl(ctx, st, t, ops), true};
  };
  if (clear)
    v = op("and", "hl", {v, Operand{ConstantInt::get(T, ~clear), false}});
  if (bits) {
    Operand b{bits, true};
    if (W < 32) {
      abi::TemplateSpec tr;
      tr.op = "trunc";
      tr.w = RailType{Kind::Int, 32};
      tr.to = wt;
      b = Operand{tmpl(ctx, st, tr, {b}), true};
    }
    v = op("or", "", {v, b});
  }
  bus::emitKeptStore(ctx, T, field, v);
}

// A fresh block of n bytes (rule 16), for a host fenv call.
Value *objectBlock(LoweringContext &ctx, uint64_t n) {
  IRBuilder<> &B = ctx.B();
  CallInst *q = B.CreateCall(abi::declareHost(ctx.M, abi::Host::Alloc), {B.getInt64(n), B.getInt64(16)});
  ctx.unc().noteVersionChange(q);
  return q;
}

// A save: the host call `host(target)` on the object when it is a classical pointer and no control is in scope, else on a
// fresh block copied over the object under the control (rule 22). Returns the call.
template <class F> Value *objectSave(LoweringContext &ctx, const CallBase &CB, Operand addr, uint64_t n, Value *flag, F host) {
  if (!addr.handle && !flag)
    return host(ctx.operand(CB.getArgOperand(0)).v);
  Value *q = objectBlock(ctx, n);
  Value *r = host(q);
  IRBuilder<> &B = ctx.B();
  bus::lowerCopy(ctx, addr, Operand{B.CreatePtrToInt(q, B.getInt64Ty()), false}, Operand{B.getInt64(n), false}, flag,
                 const_cast<CallBase &>(CB));
  return r;
}

// A restore's host object: a __cq_alloc copy of the object (rule 22) with both fields stored as classical words, so
// the host reads them whatever rails the object's own cells hold (the header).
Value *objectCopy(LoweringContext &ctx, const CallBase &CB, Operand addr, uint64_t n) {
  Value *q = objectBlock(ctx, n);
  IRBuilder<> &B = ctx.B();
  Operand qa{B.CreatePtrToInt(q, B.getInt64Ty()), false};
  bus::lowerCopy(ctx, qa, addr, Operand{B.getInt64(n), false}, nullptr, const_cast<CallBase &>(CB));
  if (n == kXflagsBytes) {
    bus::emitKeptStore(ctx, B.getInt16Ty(), qa, Operand{B.getInt16(0), false});
    return q;
  }
  // The live control word and __mxcsr, their masks the host's, with the mode bits and the flags 0.
  Value *live = objectBlock(ctx, kEnvBytes);
  hostFn(ctx, "fegetenv", {live});
  Value *cw = B.CreateLoad(B.getInt16Ty(), B.CreateConstGEP1_64(B.getInt8Ty(), live, kEnvModeOff));
  Value *mx = B.CreateLoad(B.getInt32Ty(), B.CreateConstGEP1_64(B.getInt8Ty(), live, kEnvFlagsOff));
  bus::emitKeptStore(ctx, B.getInt16Ty(), bus::offsetAddress(ctx, qa, kEnvModeOff),
                     Operand{B.CreateAnd(cw, B.getInt16(uint16_t(~kModeBits))), false});
  bus::emitKeptStore(ctx, B.getInt32Ty(), bus::offsetAddress(ctx, qa, kEnvFlagsOff),
                     Operand{B.CreateAnd(mx, B.getInt32(uint32_t(~kAllExcept))), false});
  return q;
}

// A state value from an operand: a rail, null for the empty flags literal 0, else a seed.
Value *flagsRail(LoweringContext &ctx, State &st, Operand o) {
  if (o.handle)
    return o.v;
  if (auto *c = dyn_cast<ConstantInt>(o.v); c && c->isZero())
    return nullptr;
  return seed(ctx, st, o.v);
}

} // namespace

void lowerFenvCall(LoweringContext &ctx, CallBase &CB) {
  FenvFn fn = fenvFn(CB);
  if (fn == FenvFn::None)
    internalError("eff-fenv: lowerFenvCall on a call that is no <fenv.h> function", &CB);
  State &st = state(ctx, CB);
  auto arg = [&](unsigned i) { return ctx.operand(CB.getArgOperand(i)); };
  auto hostCopy = [&]() {
    Instruction *h = copyHost(ctx, CB);
    bindResult(ctx, CB, Operand{h, false});
    return h;
  };
  Operand zero{i32(ctx, 0), false};
  Value *flag = predicateFlag(ctx);   // the quantum control (predicate or trip), nullptr when none
  auto control = [&]() { return flag; };
  // valid(r) of a classical run-time mode as a fresh i1 rail (rule 7 seed).
  auto validSeed = [&](Value *rv) {
    IRBuilder<> &B = ctx.B();
    Value *valid = B.CreateICmpEQ(B.CreateAnd(rv, i32(ctx, ~kModeBits)), i32(ctx, 0));
    CallInst *a = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, RailType{Kind::Int, 1}}, {valid});
    ctx.unc().recordSeed(a);
    anchor(ctx, st, a);
    return a;
  };
  // FOLD's host half: the host flags read and cleared; T = FLAGS | them (a rail).
  auto foldHost = [&](Value *flags) {
    Value *h = hostTest(ctx, i32(ctx, kAllExcept));
    hostClear(ctx, i32(ctx, kAllExcept));
    return fold(ctx, st, flags, h);
  };

  switch (fn) {
  case FenvFn::GetRound: {
    if (Value *m = cur(ctx, st).mode) {
      bindResult(ctx, CB, Operand{m, true});   // the mode handle itself, no gate (80)
      break;
    }
    Instruction *h = hostCopy();
    st.modeVal = h;
    st.modeValAt = &CB;
    break;
  }

  case FenvFn::SetRound: {
    Operand r = arg(0);
    Part c = cur(ctx, st);
    if (!r.handle) {
      if (auto *k = dyn_cast<ConstantInt>(r.v);
          k && (k->getZExtValue() & ~uint64_t(kModeBits) & 0xffffffffu) != 0) {
        hostCopy();   // an invalid mode changes nothing; the host call says so (also under a control)
        break;
      }
    }
    if (!r.handle && !control()) {
      if (auto *k = dyn_cast<ConstantInt>(r.v)) {
        if (c.mode)
          requirePlaced(ctx, st, CB);
        hostCopy();
        setMode(ctx, st, nullptr);
        st.modeVal = k;
        st.modeValAt = &CB;
        break;
      }
      hostCopy();
      if (c.mode) {
        // MODE' = valid(r) ? r : MODE, valid seeded as an i1 rail (rule 7).
        requirePlaced(ctx, st, CB);
        setMode(ctx, st, select32(ctx, st, validSeed(r.v), r, Operand{c.mode, true}));
      }
      st.modeVal = nullptr;
      break;
    }
    requireWritable(ctx, st, CB, false, true);
    Operand old = c.mode ? Operand{c.mode, true} : Operand{classicalMode(ctx, st, CB), false};
    if (!r.handle) {
      // A valid or run-time classical argument under a quantum control: no host call;
      // MODE' = select(p, r', MODE).
      Value *nv = r.v, *ret = i32(ctx, 0);
      Operand nvo{nv, false};
      if (!isa<ConstantInt>(r.v)) {
        IRBuilder<> &B = ctx.B();
        Value *valid = B.CreateICmpEQ(B.CreateAnd(r.v, notClassical(ctx, i32(ctx, kModeBits))), i32(ctx, 0));
        ret = B.CreateSelect(valid, i32(ctx, 0), i32(ctx, 1));
        if (old.handle) {
          nvo = Operand{select32(ctx, st, validSeed(r.v), r, old), true};
        } else {
          nvo = Operand{B.CreateSelect(valid, r.v, old.v), false};
        }
      }
      setMode(ctx, st, select32(ctx, st, flag, nvo, old));
      bindResult(ctx, CB, Operand{ret, false});
      break;
    }
    // A quantum argument (100's fenv_quantum_mode; 80 when known bits prove it valid).
    if (knownValidMode(ctx, CB.getArgOperand(0))) {
      Value *nm = control() ? select32(ctx, st, flag, r, old) : r.v;
      setMode(ctx, st, nm);
      if (!CB.use_empty())
        bindResult(ctx, CB, Operand{i32(ctx, 0), false});
      break;
    }
    Value *stray = tmpl(ctx, st, intOp("and", "hl"), {r, Operand{i32(ctx, ~kModeBits), false}});
    abi::TemplateSpec eq = intOp("icmp", "hl");
    eq.pred = "eq";
    Value *valid = tmpl(ctx, st, eq, {Operand{stray, true}, Operand{i32(ctx, 0), false}});
    Value *take = valid;
    if (control()) {
      abi::TemplateSpec a;
      a.op = "and";
      a.w = RailType{Kind::Int, 1};
      take = tmpl(ctx, st, a, {Operand{valid, true}, Operand{flag, true}});
    }
    setMode(ctx, st, select32(ctx, st, take, r, old));
    if (!CB.use_empty())
      bindResult(ctx, CB,
                 Operand{select32(ctx, st, valid, Operand{i32(ctx, 0), false}, Operand{i32(ctx, 1), false}),
                         true});
    break;
  }

  case FenvFn::RaiseExcept: {
    Operand m = arg(0);
    if (!m.handle && !control()) {
      hostCopy();
      break;
    }
    requireWritable(ctx, st, CB, true, false);
    Value *bits;
    if (m.handle) {
      KnownBits k = computeKnownBits(CB.getArgOperand(0), ctx.M.getDataLayout());
      APInt outside = ~APInt(k.getBitWidth(), kAllExcept);
      bits = (k.Zero & outside) == outside ? m.v : andLit(ctx, st, m.v, i32(ctx, kAllExcept));
      if (control())
        bits = select32(ctx, st, flag, Operand{bits, true}, Operand{i32(ctx, 0), false});
    } else {
      Value *lit = isa<ConstantInt>(m.v) ? (Value *)ConstantInt::get(m.v->getType(),
                                                                     cast<ConstantInt>(m.v)->getValue() & kAllExcept)
                                         : ctx.B().CreateAnd(m.v, i32(ctx, kAllExcept));
      bits = select32(ctx, st, flag, Operand{lit, false}, Operand{i32(ctx, 0), false});
    }
    setFlags(ctx, st, orFlags(ctx, st, cur(ctx, st).flags, bits));
    bindResult(ctx, CB, Operand{i32(ctx, 0), false});   // feraiseexcept succeeds
    break;
  }

  case FenvFn::ClearExcept: {
    Operand m = arg(0);
    Part c = cur(ctx, st);
    if (!m.handle && !control()) {
      hostCopy();
      if (!c.flags)
        break;
      if (auto k = constMask(m.v); k && (*k & kAllExcept) == 0)
        break;
      requireWritable(ctx, st, CB, true, false);
      setFlags(ctx, st, andLit(ctx, st, c.flags, notClassical(ctx, m.v)));
      break;
    }
    requireWritable(ctx, st, CB, true, false);
    if (!m.handle) {
      // A classical mask under the control p: FLAGS' = select(p, FLAGS & ~m, FLAGS | (host & m)).
      Value *hb = hostTest(ctx, m.v);
      hostCopy();
      Operand a = c.flags ? Operand{andLit(ctx, st, c.flags, notClassical(ctx, m.v)), true} : zero;
      Operand b{fold(ctx, st, c.flags, hb), true};
      setFlags(ctx, st, select32(ctx, st, flag, a, b));
      break;
    }
    // A quantum mask: FOLD.
    Value *T = foldHost(c.flags);
    Operand nw = opAnd(ctx, st, Operand{T, true}, opNot(ctx, st, m));
    setFlags(ctx, st, control() ? select32(ctx, st, flag, nw, Operand{T, true}) : nw.v);
    bindResult(ctx, CB, zero);
    break;
  }

  case FenvFn::TestExcept: {
    Operand m = arg(0);
    Part c = cur(ctx, st);
    if (!m.handle) {
      Instruction *h = copyHost(ctx, CB);
      if (!c.flags) {
        bindResult(ctx, CB, Operand{h, false});
        break;
      }
      Value *q = tmpl(ctx, st, intOp("and", "hl"), {Operand{c.flags, true}, m});
      bindResult(ctx, CB, Operand{tmpl(ctx, st, intOp("or", "hl"), {Operand{q, true}, Operand{h, false}}), true});
      break;
    }
    // A quantum mask: (host(ALL) | FLAGS) & m.
    CallInst *h = hostCall(ctx, CB, {i32(ctx, kAllExcept)});
    Value *r;
    if (c.flags) {
      Value *u = tmpl(ctx, st, intOp("or", "hl"), {Operand{c.flags, true}, Operand{h, false}});
      r = tmpl(ctx, st, intOp("and", ""), {Operand{u, true}, m});
    } else {
      r = tmpl(ctx, st, intOp("and", "hl"), {m, Operand{h, false}});
    }
    bindResult(ctx, CB, Operand{r, true});
    break;
  }

  case FenvFn::GetExceptFlag: {
    Operand m = arg(1);
    Key k = keyOf(CB.getArgOperand(0), KXflags);
    Part c = cur(ctx, st);
    if (fenvObjectKind(CB.getArgOperand(0)) == FenvObject::Memory) {
      // The host save of every bit under a quantum m (a later restore names a subset); then the part, FLAGS & m.
      Operand a = objectAddress(ctx, CB.getArgOperand(0));
      Value *mh = m.handle ? i32(ctx, kAllExcept) : m.v;
      Value *r = objectSave(ctx, CB, a, kXflagsBytes, flag, [&](Value *p) { return hostCall(ctx, CB, {p, mh}); });
      if (c.flags) {
        requirePlaced(ctx, st, CB);
        objectMerge(ctx, st, a, 0, ctx.B().getInt16Ty(), 0, opAnd(ctx, st, Operand{c.flags, true}, m).v);
      }
      bindResult(ctx, CB, flag ? zero : Operand{r, false});
      break;
    }
    if (!control()) {
      Part s;
      if (!m.handle) {
        hostCopy();
        s.mask = constMask(m.v);
      } else {
        // C17 7.6.2.4: a later restore names a subset of m; the host bytes hold every host bit.
        bindResult(ctx, CB, Operand{hostCall(ctx, CB, {arg(0).v, i32(ctx, kAllExcept)}), false});
      }
      if (c.flags)
        s.flags = opAnd(ctx, st, Operand{c.flags, true}, m).v;
      save(ctx, st, k, s, CB);
      break;
    }
    // Under the control p: the part becomes FULL, select(p, (FLAGS | host) & m, before).
    Value *h = hostTest(ctx, i32(ctx, kAllExcept));
    Operand nw = opAnd(ctx, st, Operand{fold(ctx, st, c.flags, h), true}, m);
    Part prev = readAt(ctx, st, k);
    Operand before = wholeOf(ctx, st, k, prev).second;
    Part s;
    s.full = true;
    s.flags = select32(ctx, st, flag, nw, before);
    save(ctx, st, k, s, CB);
    bindResult(ctx, CB, zero);
    break;
  }

  case FenvFn::SetExceptFlag: {
    Operand m = arg(1);
    Key k = keyOf(CB.getArgOperand(0), KXflags);
    Part s = readAt(ctx, st, k);
    Part c = cur(ctx, st);
    bool memory = fenvObjectKind(CB.getArgOperand(0)) == FenvObject::Memory;
    if (memory && !m.handle && !control()) {
      Operand a = objectAddress(ctx, CB.getArgOperand(0));
      requireWritable(ctx, st, CB, true, false);
      Value *S = objectLoad(ctx, st, a, 0, ctx.B().getInt16Ty(), kAllExcept);
      Value *q = objectCopy(ctx, CB, a, kXflagsBytes);
      bindResult(ctx, CB, Operand{hostCall(ctx, CB, {q, m.v}), false});
      Value *cr = c.flags ? andLit(ctx, st, c.flags, notClassical(ctx, m.v)) : nullptr;
      setFlags(ctx, st, orFlags(ctx, st, cr, andLit(ctx, st, S, m.v)));
      break;
    }
    if (!memory && !m.handle && !s.full && !control()) {
      hostCopy();
      if (!c.flags && !s.flags)
        break;
      std::optional<uint64_t> cm = constMask(m.v);
      if (cm && (*cm & kAllExcept) == 0)
        break;
      requireWritable(ctx, st, CB, true, false);
      Value *cr = nullptr, *sv = nullptr;
      if (c.flags) {
        // FE_ALL_EXCEPT (82): every bit is reinstated from the saved part, the current rail is dropped.
        if (!(cm && (*cm & kAllExcept) == kAllExcept))
          cr = andLit(ctx, st, c.flags, notClassical(ctx, m.v));
      }
      if (s.flags) {
        bool covered = cm && s.mask && (*s.mask & ~*cm & kAllExcept) == 0;
        sv = covered ? s.flags : andLit(ctx, st, s.flags, m.v);
      }
      setFlags(ctx, st, orFlags(ctx, st, cr, sv));
      break;
    }
    // FOLD: the saved whole value S (a full part, or the host bytes PROBEd), the host flags moved into
    // T; FLAGS' = (T & ~m) | (S & m), select(p, that, T) under the control.
    requireWritable(ctx, st, CB, true, false);
    Value *h = hostTest(ctx, i32(ctx, kAllExcept));
    Operand S = memory ? Operand{objectLoad(ctx, st, objectAddress(ctx, CB.getArgOperand(0)), 0, ctx.B().getInt16Ty(), kAllExcept), true}
                       : wholeOf(ctx, st, k, s).second;
    hostClear(ctx, i32(ctx, kAllExcept));
    Value *T = fold(ctx, st, c.flags, h);
    Operand nw = opOr(ctx, st, opAnd(ctx, st, Operand{T, true}, opNot(ctx, st, m)), opAnd(ctx, st, S, m));
    setFlags(ctx, st, control() ? select32(ctx, st, flag, nw, Operand{T, true}) : flagsRail(ctx, st, nw));
    bindResult(ctx, CB, zero);
    break;
  }

  case FenvFn::GetEnv:
  case FenvFn::HoldExcept: {
    Key k = keyOf(CB.getArgOperand(0), KEnv);
    Part c = cur(ctx, st);
    if (fenvObjectKind(CB.getArgOperand(0)) == FenvObject::Memory) {
      Operand a = objectAddress(ctx, CB.getArgOperand(0));
      // Under a control the block is saved with fegetenv: feholdexcept's clear holds where the control does (below).
      bool hold = fn == FenvFn::HoldExcept && !flag;
      Value *r = objectSave(ctx, CB, a, kEnvBytes, flag, [&](Value *p) -> Value * {
        return hold ? hostFn(ctx, "feholdexcept", {p}) : hostFn(ctx, "fegetenv", {p});
      });
      if (c.mode || c.flags)
        requirePlaced(ctx, st, CB);
      if (c.mode)
        objectMerge(ctx, st, a, kEnvModeOff, ctx.B().getInt16Ty(), kModeBits, c.mode);
      if (c.flags)
        objectMerge(ctx, st, a, kEnvFlagsOff, ctx.B().getInt32Ty(), 0, c.flags);
      if (fn == FenvFn::HoldExcept && flag) {
        requireWritable(ctx, st, CB, true, false);
        Value *T = fold(ctx, st, c.flags, hostTest(ctx, i32(ctx, kAllExcept)));
        hostClear(ctx, i32(ctx, kAllExcept));
        setFlags(ctx, st, select32(ctx, st, flag, zero, Operand{T, true}));
      } else if (hold && c.flags) {
        requireWritable(ctx, st, CB, true, false);
        setFlags(ctx, st, nullptr);
      }
      bindResult(ctx, CB, flag ? zero : Operand{r, false});
      break;
    }
    if (!control()) {
      hostCopy();
      Part s;
      s.mode = c.mode;
      s.flags = c.flags;
      save(ctx, st, k, s, CB);
      if (fn == FenvFn::HoldExcept && c.flags) {
        requireWritable(ctx, st, CB, true, false);
        setFlags(ctx, st, nullptr);
      }
      break;
    }
    // Under the control p: the part becomes FULL, select(p, now, before); feholdexcept also empties the
    // flags where p holds (FOLD).
    Value *h = hostTest(ctx, i32(ctx, kAllExcept));
    Value *T = fold(ctx, st, c.flags, h);
    Operand nowMode = c.mode ? Operand{c.mode, true} : Operand{classicalMode(ctx, st, CB), false};
    Part prev = readAt(ctx, st, k);
    auto [pm, pf] = wholeOf(ctx, st, k, prev);
    Part s;
    s.full = true;
    s.mode = select32(ctx, st, flag, nowMode, pm);
    s.flags = select32(ctx, st, flag, Operand{T, true}, pf);
    save(ctx, st, k, s, CB);
    if (fn == FenvFn::HoldExcept) {
      requireWritable(ctx, st, CB, true, false);
      hostClear(ctx, i32(ctx, kAllExcept));
      setFlags(ctx, st, select32(ctx, st, flag, zero, Operand{T, true}));
    }
    bindResult(ctx, CB, zero);
    break;
  }

  case FenvFn::SetEnv:
  case FenvFn::UpdateEnv: {
    Key k = keyOf(CB.getArgOperand(0), KEnv);
    Part s = readAt(ctx, st, k);
    Part c = cur(ctx, st);
    if (fenvObjectKind(CB.getArgOperand(0)) == FenvObject::Memory) {
      requireWritable(ctx, st, CB, true, true);
      Operand a = objectAddress(ctx, CB.getArgOperand(0));
      Value *Sm = objectLoad(ctx, st, a, kEnvModeOff, ctx.B().getInt16Ty(), kModeBits);
      Value *Sf = objectLoad(ctx, st, a, kEnvFlagsOff, ctx.B().getInt32Ty(), kAllExcept);
      if (!control()) {
        Value *q = objectCopy(ctx, CB, a, kEnvBytes);
        bindResult(ctx, CB, Operand{hostCall(ctx, CB, {q}), false});
        setMode(ctx, st, Sm);
        setFlags(ctx, st, fn == FenvFn::SetEnv ? Sf : orFlags(ctx, st, Sf, c.flags));
        break;
      }
      // The control's FOLD, the object's fields the saved whole value.
      Value *T = fold(ctx, st, c.flags, hostTest(ctx, i32(ctx, kAllExcept)));
      hostClear(ctx, i32(ctx, kAllExcept));
      Operand nowMode = c.mode ? Operand{c.mode, true} : Operand{classicalMode(ctx, st, CB), false};
      Operand nf = fn == FenvFn::SetEnv ? Operand{Sf, true} : opOr(ctx, st, Operand{Sf, true}, Operand{T, true});
      setMode(ctx, st, select32(ctx, st, flag, Operand{Sm, true}, nowMode));
      setFlags(ctx, st, select32(ctx, st, flag, nf, Operand{T, true}));
      bindResult(ctx, CB, zero);
      break;
    }
    if (!s.full && !control()) {
      hostCopy();
      if (c.mode || c.flags || s.mode || s.flags)
        requireWritable(ctx, st, CB, true, true);
      setMode(ctx, st, s.mode);
      if (fn == FenvFn::SetEnv)
        setFlags(ctx, st, s.flags);
      else
        setFlags(ctx, st, orFlags(ctx, st, s.flags, cur(ctx, st).flags));
      break;
    }
    // FOLD: the saved whole value (a full part, or the host object PROBEd), the host flags moved into
    // T; the host mode left as it is (MODE' a rail overrides it).
    requireWritable(ctx, st, CB, true, true);
    Value *h = hostTest(ctx, i32(ctx, kAllExcept));
    auto [Sm, Sf] = wholeOf(ctx, st, k, s);
    hostClear(ctx, i32(ctx, kAllExcept));
    Value *T = fold(ctx, st, c.flags, h);
    Operand nowMode = c.mode ? Operand{c.mode, true} : Operand{classicalMode(ctx, st, CB), false};
    Operand nf = fn == FenvFn::SetEnv ? Sf : opOr(ctx, st, Sf, Operand{T, true});
    if (control()) {
      setMode(ctx, st, select32(ctx, st, flag, Sm, nowMode));
      setFlags(ctx, st, select32(ctx, st, flag, nf, Operand{T, true}));
    } else {
      if (Sm.handle) {
        setMode(ctx, st, Sm.v);
      } else {
        hostFn(ctx, "fesetround", {Sm.v});
        setMode(ctx, st, nullptr);
      }
      setFlags(ctx, st, flagsRail(ctx, st, nf));
    }
    bindResult(ctx, CB, zero);
    break;
  }

  case FenvFn::None:
    break;
  }
  settle(ctx, st, CB);
}

// After the spine lowered a cq_measure: rule 2 may have made the quantum state classical (65).
void afterMeasure(LoweringContext &ctx, CallInst &measure) {
  auto &m = states();
  auto it = m.find(&ctx.out());
  if (it == m.end() || !it->second || !it->second->orig || it->second->orig->getParent() != measure.getModule())
    return;
  State &st = *it->second;
  if (st.any)
    settle(ctx, st, measure);
}

// ROLES: at a return of an entry, before the spine's flushAtExit: the state there is final.
void atEntryReturn(LoweringContext &ctx, ReturnInst &ret) {
  auto &m = states();
  auto it = m.find(&ctx.out());
  if (it == m.end() || !it->second || !it->second->orig || it->second->orig->getParent() != ret.getModule())
    return;
  State &st = *it->second;
  if (!st.any || !ctx.S.isEntry() || !accessesEnv(*ctx.S.F))
    return;
  Part p = cur(ctx, st);
  bool every = ret.getFunction() == st.orig && oneReturn(*st.orig);
  keepFinal(ctx, st, p.flags, every);
  keepFinal(ctx, st, p.mode, every);
}

// --------------------------------------------------------------------------------------------
// E1 (CR rule 23, 82): the clone ABI of the environment (Effects.h).
//
//  - cloneCarriesEnv(T, S): a clone of S (by the run's taint T: carriesEnvImpl) takes two trailing i32
//    parameters after every other one (the caller's MODE, a classical FE_* value, then its FLAGS, a
//    handle) and returns the new FLAGS handle as the LAST field of its result: `i32` alone for a clone
//    whose result is otherwise void, else a literal struct of its result fields (C types where
//    classical, handles where quantum; the M2 store handles included) followed by i32. The twin's outs
//    are every handle field in that order (the new flags last), then the clone's parameters (mode and
//    flags included).
//  - envArgs(ctx, site): caller, at the builder before the clone call: {mode (classical), flags
//    (handle)}. An empty FLAGS becomes a fresh |0> seed first. MODE a handle (a clone rounding in a
//    quantum mode) awaits a ruling (kIssueModeClone). Under a quantum predicate (the clone called
//    unguarded, rule 19, or a _ctl clone) afterCloneCall merges: FLAGS := select(predicate, flagsOut,
//    FLAGS).
//  - afterCloneCall(ctx, site, flagsOut): caller, right after the call and after recordCall recorded
//    flagsOut (the extractvalue of the last field, or the call itself) as an out: FLAGS := flagsOut.
//  - bindCloneEnv(ctx, mode, flags): clone, at its entry after the formals are bound (before any
//    instruction is lowered): MODE := mode (classical), FLAGS := flags (recorded here as the caller's
//    rail, Role::UserRegister, never freed in the clone). A _ctl clone's raised bits enter under its
//    entry flag (the predicate atom every block carries). A clone that changes the mode classically
//    reads the host mode afterwards; a quantum mode it makes must be classical again at its returns.
//  - cloneExitFlags(ctx, ret): clone, at each return before the copy-outs: the FLAGS handle to copy
//    out into the returned flags rail (alloc_i32(0), copy_i32, Role::Result, as the result's); an
//    empty FLAGS (cleared or written back) a fresh |0> seed.

bool cloneCarriesEnv(const TaintInfo &T, const Specialization &S) { return carriesEnvImpl(T, S); }

std::array<Operand, 2> envArgs(LoweringContext &ctx, CallBase &site) {
  State &st = state(ctx, site);
  Part c = cur(ctx, st);
  if (c.mode)
    unimplemented(kIssueModeClone, &site);
  Value *mode = classicalMode(ctx, st, site);
  if (!c.flags)
    setFlags(ctx, st, seed(ctx, st, i32(ctx, 0)));
  return {Operand{mode, false}, Operand{cur(ctx, st).flags, true}};
}

void afterCloneCall(LoweringContext &ctx, CallBase &site, Value *flagsOut) {
  State &st = state(ctx, site);
  if (!flagsOut || !flagsOut->getType()->isIntegerTy(32))
    internalError("eff-fenv: afterCloneCall without the clone's returned flags handle", &site);
  if (Value *flag = predicateFlag(ctx)) {
    // Under a quantum predicate the clone ran unguarded (rule 19: no non-pure gate in its body), on the
    // flags envArgs passed: its new flags hold only where the predicate does, the old ones elsewhere
    // (169's logb calling ilogb in one arm; the merge as feraiseexcept's, 65).
    Value *old = cur(ctx, st).flags;
    if (!old)
      internalError("eff-fenv: a clone call under a quantum predicate with no flags passed", &site);
    flagsOut = select32(ctx, st, flag, Operand{flagsOut, true}, Operand{old, true});
  }
  setFlags(ctx, st, flagsOut);
  settle(ctx, st, site);
}

void bindCloneEnv(LoweringContext &ctx, Argument *mode, Argument *flags) {
  if (ctx.S.isEntry() || !cloneCarriesEnv(ctx.T, ctx.S))
    internalError("eff-fenv: bindCloneEnv in a function that does not carry the environment", mode);
  if (!mode->getType()->isIntegerTy(32) || !flags->getType()->isIntegerTy(32))
    internalError("eff-fenv: a clone's trailing mode and flags parameters are not i32", mode);
  State &st = state(ctx, ctx.S.F->getParent());
  if (st.cloneBound)
    internalError("eff-fenv: bindCloneEnv called twice for one clone", mode);
  ctx.unc().recordExternal(flags, Role::UserRegister);
  st.cloneBound = true;
  st.cloneMode = mode;
  for (const BasicBlock &BB : *ctx.S.F)
    for (const Instruction &I : BB)
      st.cloneWritesMode |= writesMode(I);
  st.initial = Part{};
  // cq-ndwfr (rule 23): where every caller's flags are classical (taint's entry fact; a caller without the fenv state
  // passes an empty flags rail, 169), the rail holds no quantum bit and FLAGS starts empty: a read is the host part
  // alone, as taint has it, and the first raise makes FLAGS. The caller's rail stays the caller's (UserRegister).
  if (ctx.T.fenvAtEntry(ctx.S) & 2)
    st.initial.flags = flags;   // defined at the clone's entry: on every path
  st.any = true;
}

Value *cloneExitFlags(LoweringContext &ctx, ReturnInst &ret) {
  State &st = state(ctx, ret);
  if (!st.cloneBound)
    internalError("eff-fenv: cloneExitFlags in a clone whose environment was not bound", &ret);
  Part c = cur(ctx, st);
  if (c.mode)
    unimplemented(kIssueModeClone, &ret);
  if (!c.flags)
    return seed(ctx, st, i32(ctx, 0));
  return c.flags;
}

} // namespace cq::fenv
