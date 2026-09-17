/* ATTACK A5 on the c1 conversion: A SECOND READER OF THE RAIL AFTER THE LOOP.
   The last trip's compare value escapes the body and is read after the
   interference, so the rail cannot be discharged per trip. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    int last = 0;
    for (int k = 1; k <= 2; ++k) { last = (y > k); s += cq_measure(last); }
    y = cq_theta(y, 0.9);
    return s + cq_measure(last) + cq_measure(y);   /* <-- second reader, post-loop */
}
int main(void) { return slice(); }
