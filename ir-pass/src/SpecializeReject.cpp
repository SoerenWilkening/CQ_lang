// SpecializeReject.cpp — the single authoritative accept predicate for Phase 6
// specialization (Rule 14), plus the loud-diagnostic renderer. WHITELIST body
// scan: only `BinaryOperator` / `UnaryOperator` / `CmpInst` / `CastInst` data
// ops, the `ret` terminator, and quantum-primitive calls (which themselves
// reject) are recognized; EVERYTHING else is an unproven shape and rejects
// (Prime Directive — over-declining is always safe).

#include "SpecializeReject.h"

#include "IntrinsicLowering.h"
#include "LibmLowering.h"
#include "OpcodeSupport.h"
#include "SpecializePlan.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Type.h"

#include <string>

using namespace llvm;

namespace cq {

namespace {

// Exact-pointer membership of the front-end intrinsic call sites
// `propagate` already collected module-wide (NEVER name-prefix — C7). A clone
// candidate's body is the ORIGINAL callee body, whose theta/phi/measure calls
// were collected by `propagate`, so a body `CallInst` is a quantum primitive iff
// it is one of those exact pointers.
struct IntrinsicSets {
  SmallPtrSet<const CallInst *, 8> Rotations;  // theta + phi
  SmallPtrSet<const CallInst *, 8> Measures;
};

IntrinsicSets buildIntrinsicSets(const TaintSet &taint) {
  IntrinsicSets S;
  S.Rotations.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  S.Rotations.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  S.Measures.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());
  return S;
}

// Does any operand or the result of `I` carry a vector type? A SIMD value has no
// per-lane reversible-copy story (`cqrt_copy` is scalar), so it is a
// non-reversibilizable construct.
bool touchesVector(const Instruction &I) {
  if (I.getType()->isVectorTy())
    return true;
  for (const Value *Op : I.operands())
    if (Op->getType()->isVectorTy())
      return true;
  return false;
}

// The first exception-handling construct in `F` (an `invoke`, a landing pad, a
// `resume`, or a Windows funclet pad/return), or null if `F` is EH-free. EH
// unwinding splits the body across blocks and threads a non-value control edge
// the straight-line Bennett reverse has no story for. Detected BEFORE the
// `size() != 1` gate so the diagnostic names "exception handling" rather than
// the generic in-body-control message (PRD §2.11).
Instruction *firstEHConstruct(Function &F) {
  for (BasicBlock &BB : F)
    for (Instruction &I : BB)
      if (isa<InvokeInst>(I) || isa<LandingPadInst>(I) || isa<ResumeInst>(I) ||
          isa<CatchSwitchInst>(I) || isa<CatchPadInst>(I) ||
          isa<CleanupPadInst>(I) || isa<CatchReturnInst>(I) ||
          isa<CleanupReturnInst>(I))
        return &I;
  // A vestigial personality with no EH instruction (defensive): still EH intent.
  if (F.hasPersonalityFn())
    return F.getEntryBlock().getTerminator();
  return nullptr;
}

// Is `T` a scalar whose width has NO reversible template — i256+ / fp80 / fp128 /
// ppc_fp128 / a pointer / a non-power-of-2 _BitInt(N) / any other width
// `abiWidthFromType` does not recognize? Vectors are EXCLUDED (handled earlier
// with the more specific "vector SIMD" kind). NOTE (n0ui Tier-1): i128 is now a
// RECOGNIZED intermediate width (abiWidthFromType non-empty), so an i128 arith/
// cast intermediate inside a clone is ACCEPTED here (it lowers to cq_template_*_i128
// + reverses via the _unc twins; cf. spec_accept_i128_body.ll). The icmp-i128
// surface is NOT covered by this gate (the i1 result has a valid width) — it is
// declined by the dedicated compare-width fence in scanBody (mirrors
// CompareLowering's i128 fence). This is the body-op analog of the lowerOps width
// gate, catching the decline at the offending body op's `!dbg` rather than the
// late, clone-named lowerOps backstop (the WI-1.13 over-accept finding).
bool unsupportedWidth(Type *T) {
  return !T->isVectorTy() && abiWidthFromType(T).empty();
}

// 5po2: the ONE in-body control shape Phase 6 specialization lifts — a liftable
// tainted `select`. Scoped tight (Prime Directive; first increment): an i32
// `select(<icmp>, <param>, 0)` — a DIRECT-param true arm, a constant-ZERO false
// arm (so the clone emits ONE `cqrt_copy_i32_controlled` with no ¬flag bracket),
// and an integer-`icmp` condition. The clone (`lowerCloneSelect`) lowers it to a
// controlled-XOR copy `out = flag ? param : 0` and the Bennett reverse plays the
// self-inverse copy + the flag `_unc` (EmitInverse 5po2). Everything off this
// shape — a non-zero / non-constant false arm, a derived (non-`Argument`) true
// arm, an `fcmp` / vector / non-`icmp` condition, a non-i32 width — stays
// `InBodyControl` (a safe over-decline). This is a SHAPE gate only (scanBody has
// no per-Site mask); `lowerCloneSelect` RE-PROVES the condition is genuinely
// tainted before it mints the controlled copy, and loudly declines a shape-match
// whose condition turns out classical.
bool isLiftableSelect(const SelectInst *SI) {
  if (abiWidthFromType(SI->getType()) != "i32")
    return false;  // copyControlledFn + the i32-return gate support only i32.
  auto *FalseC = dyn_cast<ConstantInt>(SI->getFalseValue());
  if (!FalseC || !FalseC->isZero())
    return false;  // non-zero/non-const false arm needs a 2nd (¬flag) copy — not slice 1.
  auto *TrueArg = dyn_cast<Argument>(SI->getTrueValue());
  if (!TrueArg)
    return false;  // a derived true arm is a wider shape; slice 1 is param-direct.
  auto *Cond = dyn_cast<ICmpInst>(SI->getCondition());
  if (!Cond)
    return false;  // integer compare only (no fcmp / non-icmp condition).
  // The compare must test the SAME param the true arm routes (one operand ==
  // TrueArg, the other a constant). This makes the select's CONDITION and DATA
  // share taint by construction: with the param tainted they are BOTH quantum
  // (→ `lowerCloneSelect` emits the controlled copy); with it classical they are
  // BOTH classical (→ a plain classical select, left untouched). It forecloses
  // the mixed classical-control-over-quantum-data select (a classical flag over a
  // tainted arm) — an unproven shape this slice must never emit.
  Value *A = Cond->getOperand(0), *B = Cond->getOperand(1);
  return (A == TrueArg && isa<ConstantInt>(B)) ||
         (B == TrueArg && isa<ConstantInt>(A));
}

// The Callee-only body-shape verdict (arity cap, straight-line value shape, no
// `cq_*`/measure/non-reversibilizable construct, integer-i32 return), recursing
// through nested calls (Phase 6.3 transitive). `OnStack` is the DFS recursion
// stack of callees currently being scanned; a nested call whose target is on the
// stack (self OR mutual) is a call-graph cycle → `Recursion` (the convergence
// argument requires the accepted subset to be acyclic, §2.8). A nested call to a
// VISIBLE classical body recurses (it will be transitively specialized); a nested
// call with no static body (indirect / declaration-only / inline-asm) is an
// unproven shape → reject. The per-Site argument-ABI (tainted args are i32) is
// NOT checked here — it needs the call's real taint mask and is verified by
// `classifyCandidate` for every concrete `(Site, mask)` (the top at detection,
// each inner at specialize-time).
SpecReject scanBody(Function *Callee, const IntrinsicSets &Sets,
                    WidthDispatch &wd, SmallPtrSetImpl<const Function *> &OnStack,
                    Instruction *&WhereOut, std::string &KindOut) {
  // (0a) Varargs: `taintArgMask` reads the call site's `arg_size()` (incl. the
  //      vararg tail) while seeding iterates the callee's FIXED params only — a
  //      tainted vararg-tail arg would set a mask bit that is never seeded
  //      (silent under-taint). Unreachable in 6.1/6.2 (a vararg site never became
  //      a candidate), but the transitive worklist broadens the set, so decline
  //      loudly now ([[6-3-drain-ordering-varargs-recheck]]).
  if (Callee->isVarArg()) {
    WhereOut = Callee->getEntryBlock().getTerminator();
    KindOut = "varargs";
    return SpecReject::NonReversibilizable;
  }

  // (0) Arity cap (DD-5): a 65th parameter truncates the 64-bit mask and silently
  //     aliases two distinct signatures. Applies to every specialized body — a
  //     nested callee included.
  if (Callee->arg_size() > kSpecMaxArity) {
    WhereOut = &*Callee->getEntryBlock().begin();
    return SpecReject::ArityOverflow;
  }

  // (0c) Exception handling (PRD §2.11). An `invoke` / landing-pad / funclet body
  //      unwinds via a non-value control edge spanning multiple blocks; detected
  //      BEFORE the single-block gate below so the diagnostic names "exception
  //      handling" rather than the generic "tainted control flow".
  if (Instruction *EH = firstEHConstruct(*Callee)) {
    WhereOut = EH;
    KindOut = "exception handling";
    return SpecReject::NonReversibilizable;
  }

  // (1) Straight-line value bodies only (the open Rule-13 item, §8). A body with
  //     >1 basic block has a branch/switch — in-body control flow this plan does
  //     not prove.
  if (Callee->size() != 1) {
    WhereOut = Callee->getEntryBlock().getTerminator();
    return SpecReject::InBodyControl;
  }

  // (2) ABI return: a (possibly-tainted) return must have an integer i32
  //     reversible copy. fp → null `copyFn` (the f64-angle trap, C10);
  //     i128/vector/half → empty `abiWidthFromType`; non-i32 int → no i32-handle
  //     representation. `void` is a classical no-output — exempt.
  Type *RetTy = Callee->getReturnType();
  if (!RetTy->isVoidTy()) {
    StringRef RetW = abiWidthFromType(RetTy);
    if (RetW.empty() || !wd.copyFn(RetW) || RetW != "i32") {
      WhereOut = Callee->getEntryBlock().getTerminator();
      return SpecReject::FpAbi;
    }
  }

  // (3) WHITELIST body scan over the single basic block (guaranteed by (1)). The
  //     `OnStack` insert/erase brackets this callee's frame so a deeper recursion
  //     sees it (cycle detection); `Inserted` guards the (impossible here, but
  //     defensive) re-entry of an already-stacked callee.
  bool Inserted = OnStack.insert(Callee).second;
  auto pop = [&]() {
    if (Inserted)
      OnStack.erase(Callee);
  };
  BasicBlock &BB = Callee->getEntryBlock();
  for (Instruction &I : BB) {
    // The terminator must be a plain `ret` (no branch/switch — in-body control).
    if (I.isTerminator()) {
      if (!isa<ReturnInst>(I)) {
        WhereOut = &I;
        pop();
        return SpecReject::InBodyControl;
      }
      continue;
    }
    // Calls: a quantum primitive (rejects), a recursion/cycle, inline asm, or a
    // nested classical call (Phase 6.3 — recurse into its body).
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (CB->isInlineAsm()) {
        WhereOut = &I;
        KindOut = "inline assembly";
        pop();
        return SpecReject::NonReversibilizable;
      }
      if (auto *CI = dyn_cast<CallInst>(CB)) {
        if (Sets.Rotations.count(CI)) {
          WhereOut = &I;
          pop();
          return SpecReject::QuantumPrimitive;
        }
        if (Sets.Measures.count(CI)) {
          WhereOut = &I;
          pop();
          return SpecReject::Measurement;
        }
        // Curated reversible llvm.* idiom intrinsic (Phase 7.1-E): a pure total
        // function lowered to a FROZEN `cq_template_<op>_<W>` additive producer
        // with an `_unc` twin (`bswap`/`bitreverse`/`fshl`-`fshr` rotation/
        // `ctpop`/`ctlz`/`cttz`/`abs`/`smin`/`smax`/`umin`/`umax`/`*.sat`). An
        // intrinsic call is a `CallInst` to an llvm INTRINSIC DECLARATION, so
        // without this it falls through to the declaration-only "nested call"
        // decline below (the safe over-decline this follow-up lifts). Inside a
        // specialized clone it is a reversibilizable data op exactly like the
        // `BinaryOperator`/`CastInst` whitelist further down: `seedClone`'s
        // transitive-user closure taints it, `lowerOps` (taint-gated) lowers it
        // via `rewriteIntrinsic` to the producer, the Bennett wrap captures that
        // producer in its forward stream, copies out only the i32 clone result,
        // and `emitInverseChain` reverses it through the generic `cq_template_`
        // `_unc` branch (EmitInverse.cpp:128) — clone-internal source liveness is
        // held because every scratch rail is freed only AFTER the complete
        // reverse (`emitBennettWrap` step e), so a Class-2 `_unc`'s recompute
        // reads still-live sources. ZERO new lowering/uncompute code; adds NO
        // frozen symbol (the templates are frozen by 7.1-E regardless).
        // Membership is EXACT `Intrinsic::ID` + table width + rotation-form,
        // NEVER a `starts_with("llvm.")` (the cq_theta_evil hazard, C7) —
        // symmetric with `declineTaintEscapes`' top-level acceptance
        // (TaintPropagation.cpp:530). A non-curated id, a non-table width
        // (`bswap.i8`, `abs.i128`), or a dynamic/general funnel shift fails the
        // predicate and rides the loud "nested call" decline below. A curated
        // intrinsic's result width is in-table (i8/i16/i32/i64) by the predicate,
        // and for every curated shape its tainted operands share that result
        // width, so the data-op width gate below is already satisfied — accept it
        // as a data op (`continue`, advancing the body scan, NOT a `pop()+return`
        // — this frame stays on `OnStack` for the rest of the callee).
        // [[7-1-E-intrinsics-frozen-clearance]]
        if (isCuratedReversibleIntrinsic(CI))
          continue;
        // Curated DIRECT-libm math.h call (bd 3c6m.3): the EXACT-name analog of
        // the intrinsic whitelist above. clang -O1 leaves cbrt/atan2/ilogb/ldexp/
        // hypot/… as a DIRECT `@<name>` call to a declaration-only libc extern (no
        // `Intrinsic::ID`), so without this it falls through to the declaration-
        // only "nested call" decline below — the SAFE over-decline this follow-up
        // lifts (the Rule-13 finding on bd 3c6m.2). A libm call is a tainted pure
        // additive producer lowered in Phase 2 exactly like a curated intrinsic:
        // `seedClone`'s transitive-user closure taints it (its fp operand arriving
        // from an in-clone `sitofp` off the i32-handle arg — the tainted clone-arg
        // ABI is i32, so the fp domain is always reached by a cast), `lowerOps`
        // (taint-gated) lowers it via `rewriteLibmCall` to a FROZEN
        // `cq_template_<…>` producer (adds NO frozen symbol — the templates are
        // frozen by 3c6m.2 regardless), the Bennett wrap captures that producer in
        // its forward stream and copies out ONLY the i32 clone result, and
        // `emitInverseChain` reverses it through the SAME generic `cq_template_`
        // `_unc` branch (EmitInverse) — the `_unc` twin minted by string-append +
        // operand-type copy, so cross-width (ilogb f64→i32) and mixed-arg (ldexp
        // fp,int) round-trip for free; clone-internal source liveness is held
        // because every scratch rail is freed only AFTER the complete reverse
        // (`emitBennettWrap` step e), so a Class-2 `_unc`'s recompute reads
        // still-live sources. `isLibmCall` is PURELY STRUCTURAL and is the SAME
        // predicate `rewriteLibmCall` re-checks (the accept set == the lowered
        // set, no drift), so the accept can never admit an unlowerable call.
        // Membership is EXACT NAME over a declaration-only libc extern with the
        // curated arity/result-type/operand-width shape, NEVER a `starts_with`
        // (the cq_theta_evil hazard, C7) — symmetric with `declineTaintEscapes`'
        // top-level acceptance (TaintPropagation.cpp) and OpcodeLowering's enqueue.
        // A non-curated name, a wrong signature, or a user's own in-module `cbrt`
        // BODY (not a declaration) fails the predicate and rides the loud "nested
        // call" decline below. Accept it as a data op (`continue`, NOT a
        // `pop()+return` — this frame stays on `OnStack` for the rest of the
        // callee). [[7-1-E-intrinsics-frozen-clearance]]
        if (isLibmCall(CI))
          continue;
        // setjmp/longjmp: a `returns_twice` callee can re-enter the body
        // mid-stream, breaking the single-entry straight-line assumption the
        // Bennett reverse needs. Keyed on the ATTRIBUTE clang stamps on
        // setjmp/sigsetjmp (its longjmp twin is `noreturn`), NOT the name —
        // Rule 11/C7.
        if (CI->hasFnAttr(Attribute::ReturnsTwice)) {
          WhereOut = &I;
          KindOut = "setjmp/longjmp";
          pop();
          return SpecReject::NonReversibilizable;
        }
        Function *Inner = CI->getCalledFunction();
        // syscall: a direct call to the libc `syscall` trap is an irreversible
        // kernel side effect. The ONE exact-name match in the classifier — an
        // external libc SYMBOL we lower nothing for, never a taint-identity
        // decision (the no-name-prefix discipline of C7 governs `cq_*` intrinsic
        // identification, a different axis).
        if (Inner && Inner->getName() == "syscall") {
          WhereOut = &I;
          KindOut = "syscall";
          pop();
          return SpecReject::NonReversibilizable;
        }
        // Call-graph cycle (self OR mutual): the convergence argument needs the
        // accepted subset acyclic, so a recursive callee has no static depth
        // bound and is declined loudly (§2.8, §2.11).
        if (Inner && OnStack.count(Inner)) {
          WhereOut = &I;
          pop();
          return SpecReject::Recursion;
        }
        // A nested call to a VISIBLE classical body recurses — it is the
        // transitive-specialization candidate (6.3). Its argument-ABI is checked
        // at specialize-time with the inner's real mask.
        if (Inner && !Inner->isDeclaration()) {
          SpecReject R = scanBody(Inner, Sets, wd, OnStack, WhereOut, KindOut);
          if (R != SpecReject::Accept) {
            pop();
            return R;
          }
          continue;  // nested specializable call — OK.
        }
        // Indirect (null callee) or declaration-only (no IR) nested call — an
        // unproven shape with no body to reversibilize (DD-2).
        WhereOut = &I;
        KindOut = "nested call";
        pop();
        return SpecReject::NonReversibilizable;
      }
      // A non-`CallInst` CallBase reached as a non-terminator (defensive — an
      // invoke/callbr is a terminator caught above): an unproven shape.
      WhereOut = &I;
      KindOut = "nested call";
      pop();
      return SpecReject::NonReversibilizable;
    }
    // Memory / synchronization — never pure, no reversible copy.
    if (isa<AtomicRMWInst>(I) || isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I)) {
      WhereOut = &I;
      KindOut = "atomic";
      pop();
      return SpecReject::NonReversibilizable;
    }
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      WhereOut = &I;
      KindOut = LI->isVolatile() ? "volatile" : "memory access";
      pop();
      return SpecReject::NonReversibilizable;
    }
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      WhereOut = &I;
      KindOut = SI->isVolatile() ? "volatile" : "memory access";
      pop();
      return SpecReject::NonReversibilizable;
    }
    // Control muxes. A PHI join is a multi-block branch artifact (already gated
    // by the (1) single-block requirement, so this is defensive) — InBodyControl.
    // A SELECT is a straight-line mux: most decline InBodyControl, but the tight
    // 5po2 liftable shape (`select(icmp, param, 0)`) is emitted as a controlled
    // copy in the clone, so accept it here (the emission re-proves taint).
    if (isa<PHINode>(I)) {
      WhereOut = &I;
      pop();
      return SpecReject::InBodyControl;
    }
    if (auto *SI = dyn_cast<SelectInst>(&I)) {
      if (isLiftableSelect(SI))
        continue;
      WhereOut = &I;
      pop();
      return SpecReject::InBodyControl;
    }
    // The reversibilizable data-op whitelist. A vector lane has no scalar copy.
    if (isa<BinaryOperator>(I) || isa<UnaryOperator>(I) || isa<CmpInst>(I) ||
        isa<CastInst>(I)) {
      if (touchesVector(I)) {
        WhereOut = &I;
        KindOut = "vector SIMD";
        pop();
        return SpecReject::NonReversibilizable;
      }
      // Pointer / bit-reinterpret casts (`bitcast`/`ptrtoint`/`inttoptr`/
      // `addrspacecast`) cross the pointer domain or reinterpret bits and have
      // no reversible template — reject precisely at the cast (the WI-1.13
      // over-accept finding; previously slipped into the clone and was caught
      // only LATE at lowerOps, naming the clone not the source op).
      if (auto *CA = dyn_cast<CastInst>(&I)) {
        switch (CA->getOpcode()) {
        case Instruction::BitCast:
        case Instruction::PtrToInt:
        case Instruction::IntToPtr:
        case Instruction::AddrSpaceCast:
          WhereOut = &I;
          KindOut = "pointer cast";
          pop();
          return SpecReject::NonReversibilizable;
        default:
          break;
        }
      }
      // Intermediate-width scope (the WI-1.13 over-accept finding): a result or
      // operand at a width with no reversible template (i128/half/fp80/fp128/
      // pointer) is over-accepted into the clone today and only backstopped LATE
      // at lowerOps (naming the CLONE, not source-located). Reject it HERE, at the
      // offending body op, with its precise `!dbg`. Taint-agnostic: detection has
      // no clone taint yet, and over-declining a classical wide op is always safe
      // (Prime Directive).
      if (unsupportedWidth(I.getType())) {
        WhereOut = &I;
        KindOut = "unsupported width";
        pop();
        return SpecReject::NonReversibilizable;
      }
      for (const Value *Op : I.operands())
        if (unsupportedWidth(Op->getType())) {
          WhereOut = &I;
          KindOut = "unsupported width";
          pop();
          return SpecReject::NonReversibilizable;
        }
      // Predicate / cast-direction scope — the SAME over-accept class as the
      // width gate, completed (Rule 14: detection-time accept must MIRROR the
      // lowerOps accept predicate). An out-of-scope `fcmp` predicate (after
      // 8rvn, only the degenerate `true`/`false`) or an out-of-scope arithmetic cast
      // (e.g. signed `sitofp` from `i1`) has no template; without these it slips
      // into the clone and only backstops LATE at lowerOps' `diagnoseNoTemplate`
      // (naming the CLONE, not source-located). The width-empty / pointer-cast
      // shapes already returned above, so the operands here carry valid ABI
      // widths and these calls read the true (pre-RAUW) types.
      if (auto *Cmp = dyn_cast<CmpInst>(&I)) {
        if (!compareInScope(Cmp->getOpcodeName(),
                            CmpInst::getPredicateName(Cmp->getPredicate()))) {
          WhereOut = &I;
          KindOut = "unsupported compare predicate";
          pop();
          return SpecReject::NonReversibilizable;
        }
        // i128 compare fence (n0ui Tier-1): icmp is OUT of the i128 frozen
        // surface. EXACT mirror of CompareLowering's `AbiWidth == "i128"` decline
        // (NOT `widthHasReversibleCopy`, which would also wrongly reject a
        // legitimate `fcmp f32/f64` — fp widths have intBits 0). The compare's
        // data width is its OPERAND width, NOT the i1 result; the unsupportedWidth
        // gate above tests the i1 result (supported) and the i128 OPERAND is now a
        // recognized width (`abiWidthFromType` non-empty), so without this a
        // clone-body `icmp i128` over-accepts and declines LATE at lowerOps naming
        // the CLONE (the WI-1.13 detect-mirrors-lowerOps gap). fcmp f16/f32/f64 and
        // icmp i1..i64 stay accepted; i128 (the only recognized >64 width) declines.
        if (abiWidthFromType(Cmp->getOperand(0)->getType()) == "i128") {
          WhereOut = &I;
          KindOut = "unsupported width";
          pop();
          return SpecReject::NonReversibilizable;
        }
      }
      if (auto *CA = dyn_cast<CastInst>(&I))
        if (!castInScope(CA->getOpcodeName(), abiWidthFromType(CA->getSrcTy()),
                         abiWidthFromType(CA->getDestTy()))) {
          WhereOut = &I;
          KindOut = "unsupported cast";
          pop();
          return SpecReject::NonReversibilizable;
        }
      continue;  // accepted data op.
    }
    // Anything else (getelementptr, freeze, va_arg, extract/insert, …) is an
    // unproven shape — decline (Prime Directive).
    WhereOut = &I;
    KindOut = "unsupported instruction";
    pop();
    return SpecReject::NonReversibilizable;
  }

  pop();
  return SpecReject::Accept;
}

}  // namespace

SpecReject classifyCandidate(const SpecCandidate &Cand, const TaintSet &taint,
                             WidthDispatch &wd, Instruction *&WhereOut,
                             std::string &KindOut) {
  WhereOut = nullptr;
  KindOut.clear();

  // (A) Per-Site argument ABI (Rule 15): the runtime handle is ALWAYS i32, so
  //     every TAINTED argument (mask bit set) must arrive as an i32 handle. A
  //     classical pass-through arg may be any width. This is the one check that
  //     needs the call's concrete taint mask — it is verified for the top
  //     candidate at detection and for every inner candidate at specialize-time
  //     (each with its own real `(Site, mask)`).
  for (unsigned i = 0, n = Cand.Site->arg_size(); i < n; ++i) {
    if (!(Cand.Mask & (SpecMask(1) << i)))
      continue;  // classical pass-through arg — any width is fine.
    if (!Cand.Site->getArgOperand(i)->getType()->isIntegerTy(32)) {
      WhereOut = Cand.Site;
      return SpecReject::FpAbi;
    }
  }

  // (B) Callee body shape + transitive closure (arity, straight-line value body,
  //     no `cq_*`/measure/non-reversibilizable construct, i32 return, no
  //     call-graph cycle), recursing through nested calls (6.3). The single
  //     authoritative body verdict (Rule 14).
  IntrinsicSets Sets = buildIntrinsicSets(taint);
  SmallPtrSet<const Function *, 8> OnStack;
  return scanBody(Cand.Callee, Sets, wd, OnStack, WhereOut, KindOut);
}

void diagnoseReject(Instruction *Where, SpecReject Why, StringRef Kind) {
  std::string Msg;
  switch (Why) {
  case SpecReject::Recursion:
    Msg = kMsgRecursion;
    break;
  case SpecReject::FpAbi:
    Msg = kMsgFpAbi;
    break;
  case SpecReject::QuantumPrimitive:
    Msg = kMsgQuantumPrimitive;
    break;
  case SpecReject::Measurement:
    Msg = kMsgMeasurement;
    break;
  case SpecReject::InBodyControl:
    Msg = kMsgInBodyControl;
    break;
  case SpecReject::ArityOverflow:
    Msg = kMsgArityOverflow;
    break;
  case SpecReject::NonReversibilizable:
    Msg = (Twine(kMsgNonRevizPrefix) + " (" + Kind + ")").str();
    break;
  case SpecReject::Accept:
    return;  // never diagnosed.
  }
  Where->getFunction()->getContext().diagnose(DiagnosticInfoUnsupported(
      *Where->getFunction(), Msg, Where->getDebugLoc()));
}

}  // namespace cq
