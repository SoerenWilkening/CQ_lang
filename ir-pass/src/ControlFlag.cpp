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

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace cq {

// Recover the QQ compare width for a tainted-tainted control condition
// (`if (q1 < q2)`, PRD §2.4). Both operands are i32-laundered handles, so the
// logical width is unrecoverable from the IR; it is read from the per-handle
// `taint.HandleWidth` side-table (recorded at the rotation mint, §5.6). Risk
// R3: a missing entry is staleness — a real bug, not something to paper over —
// so a missing or mismatched width is a hard `report_fatal_error`, not a quiet
// bail. Returns the (equal) width; precondition: both operands are tainted.
StringRef qqControlWidth(CmpInst *Cmp, TaintSet &taint) {
  Value *A = Cmp->getOperand(0);
  Value *B = Cmp->getOperand(1);
  auto IA = taint.HandleWidth.find(A);
  auto IB = taint.HandleWidth.find(B);
  if (IA == taint.HandleWidth.end() || IB == taint.HandleWidth.end())
    report_fatal_error(
        "cq controlled lowering: Q+Q control condition operand missing from "
        "HandleWidth side-table (stale width, risk R3)");
  if (IA->second != IB->second)
    report_fatal_error(
        "cq controlled lowering: Q+Q control condition operands have unequal "
        "recorded widths (risk R3)");
  return IA->second;
}

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

  // WP6: a Q+Q control condition (`if (q1 < q2)`, both operands tainted, PRD
  // §2.4). Phase 3 bailed here — the laundered i32 width is wrong. Recover the
  // logical width from the `HandleWidth` side-table and pass it as `qqWidth` so
  // `lowerCompareToFlag` emits the QQ template `cq_template_icmp_<pred>_<W>`
  // (no `_hl`) instead of diagnosing. The HL path (one classical operand) keeps
  // `qqWidth` empty exactly as before. Mismatched/missing widths trap (risk R3).
  StringRef QqWidth;
  if (taint.Tainted.count(Cmp->getOperand(0)) &&
      taint.Tainted.count(Cmp->getOperand(1)))
    QqWidth = qqControlWidth(Cmp, taint);

  // Forward compute (not inverse), inserted before the compare by default.
  Value *Flag = lowerCompareToFlag(Cmp, wd, taint, QqWidth,
                                   /*inverse=*/false, /*before=*/nullptr);
  if (!Flag)
    return false;  // unsupported compare (already diagnosed); skip region.

  region.Flag = Flag;
  return true;
}

}  // namespace cq
