/* r13 — item 1 (scrubTaint): measure the CONDITION compare of a flattened phase region.
   RegionFlatten/SwapRouteEmit scrubTaint() the condition out of taint.Tainted; if the
   compare survives (the measure keeps it live) its SSA name is untainted at lowerMeasures. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    bool c = (q == 3);
    if (c) cq_phi(0.5);
    return cq_measure(c);
}
