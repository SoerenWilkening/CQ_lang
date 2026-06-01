// ControlFlag.h — Control-wire lowering for a recovered region (PRD §2.3/§2.4,
// IMPLEMENTATION §5.2). Reopens the Phase-3 compare seam: a tainted `icmp`
// feeding a `br i1` lowers as the control FLAG (not as data), reusing the
// extracted `CompareLowering::lowerCompareToFlag`. The original `icmp` is left
// standing — it is erased by `CFGLinearization` — so the `br i1` stays
// well-typed at the WP boundary (§1.3).

#ifndef CQ_IRPASS_CONTROL_FLAG_H_
#define CQ_IRPASS_CONTROL_FLAG_H_

namespace cq {

class WidthDispatch;
struct TaintSet;
struct ControlRegion;

// Mint `region.Flag` from `region.Condition`. WP3 uses the HL path (`qqWidth`
// empty); the Q+Q path (reading `taint.HandleWidth`) is the forward seam for
// WP6. Returns true on success (flag stored); false if the compare was
// unsupported (diagnosed by the helper) — the caller then skips the region.
bool lowerControlFlag(ControlRegion &region, WidthDispatch &wd,
                      TaintSet &taint);

}  // namespace cq

#endif  // CQ_IRPASS_CONTROL_FLAG_H_
