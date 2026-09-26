// SpecializeDetect.cpp — the pure-analysis specialization pre-pass (C-Plan),
// and (bd vsfp) the dead call-argument drop that normalises its input.

#include "SpecializeDetect.h"

#include "Specialization.h"  // shouldSpecialize (bd 9paa round-2 Pending dedup)
#include "SpecializePlan.h"
#include "SpecializeReject.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"

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

// bd vsfp — the ONLY attributes a dropped argument slot may carry, on the
// callee's parameter or at the call site. A null constant satisfies `noundef`
// and the three are ABI-only; anything else (`range`, `nofpclass`, a string
// attribute, a future kind) could make the substituted constant a violation,
// so the slot is left alone for the post-`specialize()` backstop.
bool dropSafeParamAttrs(AttributeSet AS) {
  for (Attribute A : AS) {
    if (!A.isEnumAttribute())
      return false;
    switch (A.getKindAsEnum()) {
    case Attribute::NoUndef:
    case Attribute::SExt:
    case Attribute::ZExt:
    case Attribute::InReg:
      continue;
    default:
      return false;
    }
  }
  return true;
}

// bd vsfp — delete `Root` and the part of its operand cone that dies with it,
// `RecursivelyDeleteTriviallyDeadInstructions`' walk with ONE difference: a CALL
// is never deleted, whatever LLVM thinks of its side effects. A dead `cq_theta`
// is the user's gate (CLAUDE.md §4i: "never this stage's to erase, WHATEVER ITS
// USE COUNT"), and a dead call to a `memory(none)` user function is kept too so
// the stage has one rule, not a curated list. `clang -O1` keeps both in the
// hand-inlined twin as well (`cq_theta` carries no attributes in `CQ.h`).
void deleteDeadOperandCone(Instruction *Root) {
  auto deletable = [](Instruction *I) {
    return I->use_empty() && !isa<CallBase>(I) && isInstructionTriviallyDead(I);
  };
  if (!deletable(Root))
    return;
  SmallVector<Instruction *, 16> Dead{Root};
  while (!Dead.empty()) {
    Instruction *I = Dead.pop_back_val();
    salvageDebugInfo(*I);
    for (Use &OpU : I->operands()) {
      Value *OpV = OpU.get();
      OpU.set(nullptr);
      auto *OpI = dyn_cast_or_null<Instruction>(OpV);
      // An operand is queued at most once: only the use that EMPTIES it pushes.
      if (OpI && deletable(OpI))
        Dead.push_back(OpI);
    }
    I->eraseFromParent();
  }
}

}  // namespace

bool dropDeadCallArguments(Module &M, const TaintSet &taint) {
  // The front-end intrinsic sites are skipped by MEMBERSHIP (the
  // `detectSpecializations` rule, never a name prefix). Their callees are
  // declarations in every well-formed input, so this is a belt.
  SmallPtrSet<const CallInst *, 16> Intrinsics = intrinsicSites(taint);
  bool Changed = false;
  // Fixpoint: a drop inside `h`'s body can empty `h`'s own parameter
  // (`h(a, k) { return h2(a, k); }` with `h2` ignoring `a`), which licenses a
  // drop at `h`'s callers on the next turn. Terminates: every drop replaces a
  // NON-constant operand by a constant, and constants are never revisited.
  for (bool Again = true; Again;) {
    Again = false;
    // Snapshot the call sites first: a deleted cone can reach an instruction
    // laid out AFTER the call (a header phi's back-edge incoming), so no block
    // iterator may be live across `deleteDeadOperandCone`. The calls themselves
    // survive — the cone walk never deletes a call.
    SmallVector<CallInst *, 32> Sites;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *CI = dyn_cast<CallInst>(&I); CI && !Intrinsics.count(CI))
            Sites.push_back(CI);
    }
    for (CallInst *CI : Sites) {
      Function *Callee = CI->getCalledFunction();
      if (!Callee || !Callee->hasExactDefinition() || Callee->isVarArg() ||
          CI->getFunctionType() != Callee->getFunctionType())
        continue;
      for (unsigned A = 0, E = Callee->arg_size(); A < E; ++A) {
        Value *Op = CI->getArgOperand(A);
        if (isa<Constant>(Op))
          continue;
        Argument *P = Callee->getArg(A);
        Type *Ty = P->getType();
        if (!Ty->isIntegerTy() && !Ty->isFloatingPointTy())
          continue;
        if (!P->use_empty())
          continue;
        if (!dropSafeParamAttrs(Callee->getAttributes().getParamAttrs(A)) ||
            !dropSafeParamAttrs(CI->getAttributes().getParamAttrs(A)))
          continue;
        // Debug lever (env-gated, no behaviour change; the CQ_SPEC_DBG
        // precedent): one line per drop, so a census can list the modules this
        // stage touches — a decline fixture whose subject it removes can keep
        // its STRING under another owner, which no stdout/stderr A/B can see.
        if (::getenv("CQ_DEADARG_DBG"))
          errs() << "CQ_DEADARG_DBG: drop arg " << A << " of @"
                 << Callee->getName() << " in @" << CI->getFunction()->getName()
                 << (isa<Instruction>(Op) ? " (inst)" : " (arg)") << "\n";
        CI->setArgOperand(A, Constant::getNullValue(Ty));
        if (auto *OpI = dyn_cast<Instruction>(Op))
          deleteDeadOperandCone(OpI);
        Changed = Again = true;
      }
    }
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
