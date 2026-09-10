#include "CQ.h"
int main(void){ bool b=0,c=0; b=cq_theta(b,0.5); c=cq_theta(c,0.7); int a=b?(c?1:2):(c?3:4); return cq_measure(a)+cq_measure(b)+cq_measure(c); }
