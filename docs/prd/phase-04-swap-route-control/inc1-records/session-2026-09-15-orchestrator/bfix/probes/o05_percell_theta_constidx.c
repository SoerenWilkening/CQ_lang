/* o05 — per-cell theta, CONSTANT-INDEX measures (the shipped
   slice_railbank_bool_prep_constidx_measures shape). MUST ACCEPT. */
#include "CQ.h"
int main(void) {
    bool b0[3];
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]);
}
