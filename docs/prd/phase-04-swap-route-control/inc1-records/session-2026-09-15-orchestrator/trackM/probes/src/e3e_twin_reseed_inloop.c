#include "CQ.h"
/* E3 TWIN of m14c (in-loop re-use of a measured name). */
int main(void){ int q=cq_theta(0,0.3); int s=0; for(int i=0;i<3;i++){ int m=cq_measure(q); int a=cq_theta(m,0.5); s+=cq_measure(a);} return s; }
