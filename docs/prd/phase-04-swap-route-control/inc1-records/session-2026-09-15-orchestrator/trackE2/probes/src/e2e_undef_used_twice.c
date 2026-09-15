#include "CQ.h"
/* E2 q3: the undef operand is ALSO read outside the measure. Does the RAUW target
   (undef vs zero) become observable? Under the zero rewrite `r` and the measured
   value agree; under an undef passthrough they need not. */
int main(void){ int u; int m = cq_measure(u); return m + u; }
