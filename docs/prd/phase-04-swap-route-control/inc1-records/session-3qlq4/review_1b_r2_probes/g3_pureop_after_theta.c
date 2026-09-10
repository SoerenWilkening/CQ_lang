#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.5); int d=q+1; return cq_measure(d)+a; }
