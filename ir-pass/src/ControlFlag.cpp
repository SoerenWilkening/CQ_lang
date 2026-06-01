// ControlFlag.cpp — see header. Lowers `region.Condition` (a tainted `icmp`)
// to the i32 control flag via the shared `lowerCompareToFlag`, storing it in
// `region.Flag`. The compare itself is untouched (erased later by
// linearization); only the flag is minted, inserted before the compare (the
// forward compute, §1.5).

#include "ControlFlag.h"

#include "CompareLowering.h"
#include "ControlPlan.h"
#include "TaintPropagation.h"

#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq {

bool lowerControlFlag(ControlRegion &region, WidthDispatch &wd,
                      TaintSet &taint) {
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
