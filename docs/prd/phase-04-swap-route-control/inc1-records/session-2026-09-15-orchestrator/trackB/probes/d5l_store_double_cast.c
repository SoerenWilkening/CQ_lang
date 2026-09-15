/* d5l — an `int` bank whose stored value is `(int)(char)q`: a NARROWING gate
   followed by a widening one, so the cast in front of the store is a `sext`
   whose source is NOT the rail the cell parks. */
#include "CQ.h"
int main(void) {
    int b0[3]; int s = 0; int q = cq_theta(q, 0.5);
    for (int i = 0; i < 3; ++i) b0[i] = (int)(char) q;
    for (int i = 0; i < 3; ++i) s += cq_measure((char) b0[i]);
    return s;
}
