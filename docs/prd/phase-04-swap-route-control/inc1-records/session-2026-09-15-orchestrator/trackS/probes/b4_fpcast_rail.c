/* Track beta P4 — THE CAST-MINTED RAIL (IMPL_S §16.1: "the most likely next
   hole", and Track S says it did NOT construct one).  The body's ONLY
   rail-minting interior ops are an `fptrunc` + `fpext`; there is NO
   `BinaryOperator` in the body at all, so conjunct (3) finds nothing. */
#include "CQ.h"
double slice(void) {
    double y = cq_theta(5.0, 0.5);
    double w = y;
    double s = 0;
    for (int k = 0; k < 2; ++k) {
        w = (double)(float)w;      /* fptrunc f64->f32 (interior) + fpext */
        s += cq_measure(w);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return (int)slice(); }
