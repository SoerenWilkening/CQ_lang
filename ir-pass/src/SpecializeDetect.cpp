// SpecializeDetect.cpp — the pure-analysis specialization pre-pass (C-Plan),
// and (bd vsfp) the dead call-argument drop that normalises its input.

#include "SpecializeDetect.h"

#include "DeadValueLiveness.h"
#include "Specialization.h"  // shouldSpecialize (bd 9paa round-2 Pending dedup)
#include "SpecializePlan.h"
#include "SpecializeReject.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <cstdlib>
#include <string>

using namespace llvm;

namespace cq {

namespace {

// Exact-pointer set of the front-end intrinsic call sites (theta/phi/measure)
// so a `cq_phi(%q, θ)` — which reads the tainted handle `%q` and so LOOKS like a
// tainted-arg candidate — is skipped. NEVER name-prefix on the candidate side
// (a user function named `cq_theta_evil` must not be skipped — it is a genuine
// unknown callee the carve-out declines).
SmallPtrSet<const CallInst *, 16> intrinsicSites(const TaintSet &taint) {
  SmallPtrSet<const CallInst *, 16> S;
  S.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end());
  S.insert(taint.PhiCalls.begin(), taint.PhiCalls.end());
  // The register-free branch phase (bd 3qlq Inc 1 part A, round-1 F-L3-3).
  // `PhiCalls` above is the retired register family and is permanently empty;
  // `PhaseCalls` is where a `call void @cq_phi(double)` lives now. It matters
  // MORE at this site after the P7 re-ordering: `deleteGlobalPhases` now runs
  // AFTER `repropagateControlMerges`, so the ROUND-2 `detectSpecializations` sees
  // surviving `cq_phi` calls, and one with a TAINTED ANGLE satisfies
  // `readsTainted` — i.e. it would be a tainted-arg CANDIDATE rather than a
  // skipped intrinsic site.
  S.insert(taint.PhaseCalls.begin(), taint.PhaseCalls.end());
  S.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());
  return S;
}

bool readsTainted(const CallInst *CI, const TaintSet &taint) {
  for (const Value *Op : CI->args())
    if (taint.Tainted.count(const_cast<Value *>(Op)))
      return true;
  return false;
}

// bd vsfp (round 2, bd ctz4 / r1A F-VA-1) — the DAE PRECONDITIONS, mirrored from
// LLVM 19's `DeadArgumentEliminationPass::removeDeadArgumentsFromCallers`, which is
// the transform the drop performs across the TU boundary `-O1` cannot see. A callee
// is eligible only if ALL of these hold:
//   * it is a definition the linker cannot replace (`hasExactDefinition()` — an
//     interposable or derefinable body may not be the body that runs);
//   * it is not `naked` (its inline asm reads the argument REGISTERS; no IR use
//     exists to find — r1A's `naked1.c` printed `ident=0` at exit 0 when this
//     conjunct was missing, and `naked2.c` turned a correct decline into an accept);
//   * it is not variadic (STRICTER than DAE, which rewrites a vararg callee's
//     fixed parameters: scope, not soundness; pinned by
//     spec_accept_dropped_arg_varargs_kept.ll).
// A call SITE is eligible only if it calls the callee directly with the callee's
// own function type (DAE's own site rule: an address-taken callee's OTHER uses are
// simply not rewritten, and since the parameter is dead in the body, no caller's
// value there matters). A `musttail` site IS eligible (bd `test_C_libtooling-ev3m`,
// 2026-09-28): rounds 1–6 refused it as a POLICY conservatism, and that refusal was
// the whole reason a callee forwarding its ignored quantum argument through
// `musttail` (r5 `mt2`, r6 `mm1`) kept a phantom read and declined at the 3jru
// return refusal while its plain-`tail` twin compiled. Replacing an OPERAND by a
// constant changes no signature, no calling convention and no ABI-impacting
// attribute (the LLVM 19 verifier's `musttail` rules compare the caller's and the
// call's prototypes and their sret/byval/inalloca/inreg/alignstack/swiftself/
// swiftasync/swifterror/preallocated/byref attributes — the strip below touches
// only `range`/`nofpclass`), and the call still immediately precedes its `ret`; a
// forwarding chain (`h(a,k){ musttail return h2(a,k); }`) is handled by the
// fixpoint, one site per turn, with no signature to keep in step.
// spec_accept_dropped_arg_musttail_kept.ll pins the drop (its name records the
// retired conservatism; not renamed — L8). A PARAMETER is eligible only if it is an
// integer or floating-point scalar (scope: a pointer is never rewritten), carries
// none of `returned` / `swifterror` / a pass-pointee-by-value-copy attribute
// (`byval`/`inalloca`/`preallocated`), and every attribute on it and on the call
// site's slot is one of `noundef`/`signext`/`zeroext`/`inreg` (satisfied by, or
// ABI-only for, the constant `0`) or `range`/`nofpclass` (value constraints the
// constant could violate — STRIPPED from both, as DAE strips its UB-implying set).
// Any other attribute kind leaves the slot alone for the post-`specialize()`
// backstop.
bool dropEligibleCallee(const Function *F) {
  return F && !F->isDeclaration() && F->hasExactDefinition() &&
         !F->hasFnAttribute(Attribute::Naked) && !F->isVarArg();
}

bool dropEligibleParamAttrs(AttributeSet AS) {
  for (Attribute A : AS) {
    if (A.isStringAttribute())
      return false;  // a string attribute: unknown meaning, leave the slot.
    switch (A.getKindAsEnum()) {
    case Attribute::NoUndef:
    case Attribute::SExt:
    case Attribute::ZExt:
    case Attribute::InReg:
    case Attribute::Range:
    case Attribute::NoFPClass:
      continue;
    default:
      return false;
    }
  }
  return true;
}

bool dropEligibleParam(const Argument &P) {
  Type *Ty = P.getType();
  if (!Ty->isIntegerTy() && !Ty->isFloatingPointTy())
    return false;
  return !P.hasAttribute(Attribute::Returned) && !P.hasSwiftErrorAttr() &&
         !P.hasPassPointeeByValueCopyAttr();
}

}  // namespace

bool nullSafeSlot(const CallBase &CB, unsigned A) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee || A >= Callee->arg_size())
    return false;
  return dropEligibleParam(*Callee->getArg(A)) &&
         dropEligibleParamAttrs(Callee->getAttributes().getParamAttrs(A)) &&
         dropEligibleParamAttrs(CB.getAttributes().getParamAttrs(A));
}

bool dropEligibleSlot(const CallBase &CB, unsigned A) {
  const Function *Callee = CB.getCalledFunction();
  if (!dropEligibleCallee(Callee) || CB.getFunctionType() != Callee->getFunctionType())
    return false;
  // No `musttail` refusal since bd ev3m: a constant changes no signature (see the
  // precondition list above).
  return nullSafeSlot(CB, A);
}

bool dropDeadCallArguments(Module &M, const TaintSet &taint) {
  // The front-end intrinsic sites are skipped by MEMBERSHIP (the
  // `detectSpecializations` rule, never a name prefix). LOAD-BEARING, not a belt
  // (r1A F-VA-5, measured): a module may DEFINE `cq_theta_si32` with an unused
  // angle parameter, and without this skip the user's rotation angle becomes 0.0.
  SmallPtrSet<const CallInst *, 16> Intrinsics = intrinsicSites(taint);
  bool Changed = false;
  // Fixpoint: a drop inside `h`'s body can make `h`'s own parameter dead
  // (`h(a, k) { return h2(a, k); }` with `h2` ignoring `a`), which licenses a
  // drop at `h`'s callers on the next turn. Terminates: every drop replaces a
  // NON-constant operand by a constant, and constants are never revisited.
  for (bool Again = true; Again;) {
    Again = false;
    // Snapshot the call sites first; every rewrite of this turn happens before
    // any deletion, so no pointer in `Sites` dangles while it is used.
    SmallVector<CallInst *, 32> Sites;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *CI = dyn_cast<CallInst>(&I); CI && !Intrinsics.count(CI))
            Sites.push_back(CI);
    }
    // One liveness per callee per turn. A mask computed before this turn's
    // rewrites of the callee's own body can only UNDER-report dead parameters
    // (rewrites and deletions only remove reads), which the next turn repairs.
    DenseMap<const Function *, uint64_t> DeadMask;
    MapVector<Function *, SmallVector<Value *, 4>> Seeds;
    for (CallInst *CI : Sites) {
      Function *Callee = CI->getCalledFunction();
      if (!dropEligibleCallee(Callee) ||
          CI->getFunctionType() != Callee->getFunctionType())
        continue;  // (a `musttail` site is eligible since bd ev3m — see above)
      auto It = DeadMask.find(Callee);
      if (It == DeadMask.end())
        It = DeadMask.try_emplace(Callee, deadParamMask(*Callee, taint)).first;
      const uint64_t Mask = It->second;
      if (!Mask)
        continue;
      for (unsigned A = 0, E = std::min<unsigned>(Callee->arg_size(), 64); A < E;
           ++A) {
        if (!((Mask >> A) & 1))
          continue;
        Value *Op = CI->getArgOperand(A);
        if (isa<Constant>(Op))
          continue;
        Argument *P = Callee->getArg(A);
        if (!dropEligibleSlot(*CI, A))
          continue;
        // Debug lever (env-gated, no behaviour change; the CQ_SPEC_DBG
        // precedent): one line per drop, so a census can list the modules this
        // stage touches — a decline fixture whose subject it removes can keep
        // its STRING under another owner, which no stdout/stderr A/B can see.
        if (::getenv("CQ_DEADARG_DBG"))
          errs() << "CQ_DEADARG_DBG: drop arg " << A << " of @"
                 << Callee->getName() << " in @" << CI->getFunction()->getName()
                 << (isa<Instruction>(Op) ? " (inst)" : " (arg)") << "\n";
        for (Attribute::AttrKind K : {Attribute::Range, Attribute::NoFPClass}) {
          Callee->removeParamAttr(A, K);
          CI->removeParamAttr(A, K);
        }
        CI->setArgOperand(A, Constant::getNullValue(P->getType()));
        Seeds[CI->getFunction()].push_back(Op);
        Changed = Again = true;
      }
    }
    // THE DEAD CALLS TO USER DEFINITIONS (bd vsfp round 2). Every unused call
    // to a function DEFINED in the module (never an LLVM intrinsic, never a
    // declaration) is a seed too, dropped operand or not; the liveness predicate
    // then deletes it only if it is dead (not a root). After `clang -O1` each TU
    // is dead-code free, so the only dead code an `llvm-link`ed module still
    // carries is a call whose callee body the CALLER's TU could not see — e.g.
    // `if (q > 3) r = K(m);` with `r` feeding only a dropped slot and `K` a
    // `const` function in another TU (r2A `s3d`), or `t = h(q, p, m);` with `t`
    // unused (whose clone's out rail was left entangled with `p` across a later
    // `Ry` on it, warned — `dc1`): the hand-inlined twin deletes both, and so
    // does this. A dead call is by definition not a root: LLVM proves it
    // side-effect-free from the callee's attributes, or the callee's BODY is
    // (`DeadValueLiveness.h`), and it is never a front-end intrinsic site or a
    // clone. Intrinsics are not seeded: `-O1` sees them in every TU, so a dead
    // one never survives stage 1 — one arises only inside a dropped operand's
    // cone (r1A `prov1`, bd m1gi), and those are seeded above.
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *CI = dyn_cast<CallInst>(&I);
              CI && !Intrinsics.count(CI) && CI->use_empty())
            if (const Function *Callee = CI->getCalledFunction();
                Callee && !Callee->isDeclaration() && !Callee->isIntrinsic())
              Seeds[&F].push_back(CI);
    }
    // The clean-up, per function, with the ONE liveness predicate
    // (`DeadValueLiveness.h`): the dead part of each seed's cone — dead
    // intrinsics, dead side-effect-free calls and dead phi cycles included,
    // never a root — and the empty-arm / two-entry-phi fold it can create. A
    // deletion can make another callee's parameter dead (a dead call inside it
    // was that parameter's last reader), so it licenses another turn.
    for (auto &[F, Vs] : Seeds)
      if (deleteDeadCones(*F, Vs, taint, "drop"))
        Changed = Again = true;
  }
  return Changed;
}

void detectSpecializations(Module &M, const TaintSet &taint, WidthDispatch &wd,
                           SpecPlan &out,
                           const SmallPtrSetImpl<Value *> *reseed) {
  SmallPtrSet<const CallInst *, 16> Intrinsics = intrinsicSites(taint);

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        // SHAPE filter, decline-by-default. Only a DIRECT `CallInst` (the
        // `dyn_cast<CallInst>` narrowing excludes `InvokeInst`/`CallBrInst`),
        // with a non-null callee (excludes indirect), to a DEFINITION (excludes
        // declaration-only / opaque externs — the DD-2 no-IR contract) is a
        // candidate. A site failing any of these is SILENTLY not a candidate;
        // the carve-out fires `kMsgUnknownCallee` for it.
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        if (Intrinsics.count(CI))
          continue;  // a front-end intrinsic, never a specialization candidate.
        Function *Callee = CI->getCalledFunction();
        if (!Callee || Callee->isDeclaration())
          continue;
        if (!readsTainted(CI, taint))
          continue;  // no tainted operand — not in the taint-escape domain.

        // ── Round-2 re-detection (bd 9paa) ─────────────────────────────────
        // A NON-null `reseed` marks the SECOND propagation pass
        // (`repropagateControlMerges`): a wholly-new candidate `g(%out)` whose
        // args were ALL classical at round 1 (so it never entered the plan) now
        // reads a tainted control-merge `%out`. Three round-2-only filters (each
        // a no-op at round 1, where `reseed == nullptr`, the plan is built one
        // Site at a time, and each CallInst is visited exactly once so the
        // Pending/Diagnosed scans never self-hit):
        //   (a) a site already proven-Accept (in `Pending`) — owned by the
        //       step-262 driver, or already re-planned by
        //       `replanReseedSpecialization`; re-pushing would clone/retarget the
        //       SAME Site twice with a duplicate candidate.
        //   (b) a site already loud-declined (in `Diagnosed`, by round-1
        //       detection OR by `replanReseedSpecialization`) — it rendered its
        //       one specialization message; re-diagnosing double-fires it.
        //   (c) consider ONLY a site whose newly-tainted arg is a RESEED value
        //       (the control-merge `%out`, a yn71-produced `%out2` control rail, or
        //       a data-derivation of either — the set computed in
        //       `repropagateControlMerges` AFTER the control fixpoint, so it spans
        //       every round-2 taint delta, bd afmv). A round-1-tainted-arg site was
        //       already adjudicated in round 1 (and is in Pending/Diagnosed, so
        //       (a)/(b) already skipped it). Restricting to the reseed set keeps a
        //       site tainted for any OTHER reason out of round-2 re-detection.
        if (reseed) {
          if (shouldSpecialize(CI, out) || out.Diagnosed.count(CI))
            continue;
          bool ReadsReseed = false;
          for (const Use &Op : CI->args())
            if (reseed->count(Op.get())) {
              ReadsReseed = true;
              break;
            }
          if (!ReadsReseed)
            continue;
        }

        // The §2.2 taint signature. `mask == 0` cannot happen here
        // (`readsTainted` is true), but a value used ONLY as a classical angle
        // never entered `taint.Tainted`, so the mask is purely the quantum-arg
        // bits.
        SpecMask Mask = taintArgMask(CI, taint);
        if (Mask == 0)
          continue;

        SpecCandidate Cand{CI, Callee, Mask};
        Instruction *Where = nullptr;
        std::string Kind;
        SpecReject Why = classifyCandidate(Cand, taint, wd, Where, Kind);
        if (Why == SpecReject::Accept) {
          out.Pending.push_back(Cand);
          continue;
        }
        // A classified reject: loud, source-located on the offending body
        // instruction, and recorded so the carve-out renders exactly one
        // message (its specialization message, not also `kMsgUnknownCallee`).
        diagnoseReject(Where, Why, Kind);
        out.Diagnosed.insert(CI);
      }
    }
  }
}

}  // namespace cq
