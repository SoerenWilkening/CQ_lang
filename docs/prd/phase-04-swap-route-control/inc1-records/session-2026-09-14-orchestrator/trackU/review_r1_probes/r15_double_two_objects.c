/* same, but two distinct uninitialized doubles -- -O1 still spells both `undef`,
   the same uniqued constant. */
#include "CQ.h"
int main(void) {
    double s;   /* seed  */
    double t;   /* angle */
    double r = cq_theta(s, t);
    return (int)cq_measure(r);
}
