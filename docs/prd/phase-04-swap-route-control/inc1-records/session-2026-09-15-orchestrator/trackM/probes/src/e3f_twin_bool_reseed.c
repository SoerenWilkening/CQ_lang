#include "CQ.h"
/* E3 WIDTH question: at _Bool. cq_measure_i1 returns i1; does cqrt_alloc_i1 take
   the measured value with no cast? */
int main(void){ _Bool q=cq_theta(0,0.3); _Bool m=cq_measure(q); _Bool a=cq_theta(m,0.5); return m+cq_measure(a); }
