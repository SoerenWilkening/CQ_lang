/* the merge phi with a SECOND, non-absorbable tainted user (a multiply, so -O1
   cannot fold the data read into the select's arm as it did in r07). */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3) { b1 = cq_theta(b1, 0.5); }
    if (b1) a -= 3;
    int d = ((int)b1) * 7;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a) + cq_measure(d);
}
