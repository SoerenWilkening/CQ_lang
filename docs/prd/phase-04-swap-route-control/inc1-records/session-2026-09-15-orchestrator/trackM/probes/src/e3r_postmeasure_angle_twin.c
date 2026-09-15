#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int r=cq_theta(0,(double)m); return m+cq_measure(r); }
