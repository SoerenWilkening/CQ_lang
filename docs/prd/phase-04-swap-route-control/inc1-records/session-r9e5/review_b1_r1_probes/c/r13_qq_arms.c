#include "CQ.h"
int main(void){ int q=cq_theta(3,0.2); bool b=0; b=cq_theta(b,0.5); int a=b?q+1:q; return cq_measure(a)+cq_measure(b); }
