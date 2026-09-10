#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.125); int b=cq_theta(a,0.25); return cq_measure(a)+cq_measure(b); }
