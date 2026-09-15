#include "CQ.h"
/* E3 TWIN of m14b (measure -> rotate -> RE-MEASURE THE NAME). Under (b) the second
   cq_measure(q) relabels to cq_measure(m) — a measure of a measure RESULT, which is
   never tainted, so bd 21mg's CLASSICAL measure path RAUWs it to m with no trace
   line. This twin spells that directly. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(m,0.5); int m2=cq_measure(m); return m+m2+cq_measure(a); }
