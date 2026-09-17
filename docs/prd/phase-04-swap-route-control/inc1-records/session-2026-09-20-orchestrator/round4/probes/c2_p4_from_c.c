/* c2 — PROBE (P4), PLAIN C.  A user-declared external whose name carries the
 * `cqrt_` prefix is EXEMPT from `declineTaintEscapes` (TaintPropagation.cpp:826,
 * the `starts_with("cqrt_") || starts_with("cq_template_") ||
 * starts_with("cq_invert_")` accept) and is ALSO admitted by (P4)'s
 * `starts_with("cq_")/starts_with("cqrt_")` allowance — but NOTHING rewrites its
 * operand, so the narrow carried phi is retyped under it. */
#include "CQ.h"
extern void cqrt_probe_sink(short);
int main(void) {
    short a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    cqrt_probe_sink(a);
    return (int)cq_measure(a);
}
