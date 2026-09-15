#include "CQ.h"
/* E3 TWIN of m14f (pure op on a measured name) -> CLASSICAL arithmetic on m. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(m,0.5); int p=m+7; return p+cq_measure(a); }
