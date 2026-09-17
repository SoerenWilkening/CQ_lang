/* c3 — the FLAT (loop-free) i16 twin of c2.  No loop, so no carried handle and no
 * promotion: this measures whether the "narrow rail handed to a prefix-exempt
 * external" abort is PRE-EXISTING (same verdict on both binaries) or is bd 11qv's. */
#include "CQ.h"
extern void cqrt_probe_sink(short);
int main(void) {
    short a = 5;
    bool b0 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0) a -= 3;
    cqrt_probe_sink(a);
    return (int)cq_measure(a);
}
