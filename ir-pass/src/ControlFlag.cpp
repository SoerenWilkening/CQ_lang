// ControlFlag.cpp — see header. Lowers `region.Condition` to the i32 control
// flag, storing it in `region.Flag`. The compare(s) themselves are untouched
// (erased later by linearization / the orchestrator's condition cleanup); only
// the flag is minted, inserted before the compare (the forward compute, §1.5).
//
// Plain compare (WP3): one `lowerCompareToFlag`. Compound `&&`/`||` (WP5): the
// condition is the flag-combination select — lower each sub-compare to its own
// flag, then `combineFlags` ANDs/ORs them into one (PRD §2.5, §1.2).

#include "ControlFlag.h"

#include "CompareLowering.h"
#include "ControlPlan.h"
#include "FlagConjunction.h"
#include "TaintPropagation.h"

#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

bool lowerControlFlag(ControlRegion &region, WidthDispatch &wd,
                      ControlledSymbols &csyms, TaintSet &taint) {
  if (region.Conj != ControlRegion::ConjNone) {
    // Compound `&&`/`||`: lower each tainted sub-compare to its own HL flag,
    // then combine. Both `CondA`/`CondB` are CmpInsts (checked at detection).
    auto *CmpA = dyn_cast_or_null<CmpInst>(region.CondA);
    auto *CmpB = dyn_cast_or_null<CmpInst>(region.CondB);
    if (!CmpA || !CmpB)
      return false;  // malformed conjunction; leave the region for the verifier.

    // Emit BOTH sub-flag computes AND the combine at the SAME point — just
    // before the region's condition (`region.Condition`, in the predecessor
    // block). For a flat `&&` the sub-compares already sit there, but for the
    // un-flattened nested shape `CondB` lives in the inner guard block `Mid`;
    // computing its flag at the predecessor hoists it so it dominates the
    // Toffoli (control flags are computed UNCONDITIONALLY — there is no
    // classical branch on a quantum flag). The original sub-compares stay
    // standing (erased at the region's condition cleanup).
    auto *CondI = dyn_cast_or_null<Instruction>(region.Condition);
    if (!CondI)
      return false;
    Value *FlagA = lowerCompareToFlag(CmpA, wd, taint, /*qqWidth=*/{},
                                      /*inverse=*/false, /*before=*/CondI);
    Value *FlagB = lowerCompareToFlag(CmpB, wd, taint, /*qqWidth=*/{},
                                      /*inverse=*/false, /*before=*/CondI);
    if (!FlagA || !FlagB)
      return false;  // unsupported compare (diagnosed); skip region.

    // Combine into one fresh flag, inserted just before the condition (after
    // both sub-flag computes, which dominate it). The combined flag is what
    // every downstream controlled op uses (§1.2).
    Value *Combined = combineFlags(FlagA, FlagB, region.Conj, csyms, wd, CondI);
    if (!Combined)
      return false;  // unsupported symbol (diagnosed); skip region.

    // Stash the forward sub-flags so the uncompute reuses them for
    // `cqrt_toffoli_inv` (§1.5 LIFO bracket).
    region.FlagA = FlagA;
    region.FlagB = FlagB;
    region.Flag = Combined;
    return true;
  }

  auto *Cmp = dyn_cast_or_null<CmpInst>(region.Condition);
  if (!Cmp)
    return false;  // WP3 conditions are always compares; defensive.

  // HL path for WP3 (`qqWidth` empty → Q+Q bails, exactly as Phase 3). Forward
  // compute (not inverse), inserted before the compare by default.
  Value *Flag = lowerCompareToFlag(Cmp, wd, taint, /*qqWidth=*/{},
                                   /*inverse=*/false, /*before=*/nullptr);
  if (!Flag)
    return false;  // unsupported compare (already diagnosed); skip region.

  region.Flag = Flag;
  return true;
}

}  // namespace cq
