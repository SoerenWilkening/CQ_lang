#include "CQ.h"
/* E2 adversarial: the undef measure's OUTCOME feeds a rotation ANGLE (Rule 3's
   classical arg-1 slot). The angle is classical, so this must NOT become a
   quantum-derived-angle decline; it must become a defined angle. */
int main(void){ int u; int m = cq_measure(u); int q = cq_theta(0, (double)m); return cq_measure(q); }
