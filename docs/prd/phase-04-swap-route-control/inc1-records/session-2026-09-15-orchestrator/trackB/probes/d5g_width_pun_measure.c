/* d5g — a bank cell measured at a DIFFERENT WIDTH from the rail the bank's store
   minted.  The cells are `int` (rail i32, `cqrt_alloc_i32`) but the read is cast
   to `short` first, so `-O1` emits `trunc i32 -> i16` and `cq_measure_i16`.  Is
   that a width pun the allow-list lets through? */
#include "CQ.h"
int main(void) {
    int b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure((short) b0[i]);
    return s;
}
