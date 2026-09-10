#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); bool t=(bool)(q&1); bool b=cq_theta(t,0.5); bool c=cq_theta(t,0.9); double a = b ? 0.9 : 0.3; cq_phi(a); return cq_measure(c); }
