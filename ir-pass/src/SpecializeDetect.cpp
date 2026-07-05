// SpecializeDetect.cpp — the pure-analysis specialization pre-pass (C-Plan).

#include "SpecializeDetect.h"

#include "Specialization.h"  // shouldSpecialize (bd 9paa round-2 Pending dedup)
#include "SpecializePlan.h"
#include "SpecializeReject.h"
#include "TaintPropagation.h"
#include "WidthDispatch.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

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
  S.insert(taint.MeasureCalls.begin(), taint.MeasureCalls.end());
  return S;
}

bool readsTainted(const CallInst *CI, const TaintSet &taint) {
  for (const Value *Op : CI->args())
    if (taint.Tainted.count(const_cast<Value *>(Op)))
      return true;
  return false;
}

}  // namespace

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
