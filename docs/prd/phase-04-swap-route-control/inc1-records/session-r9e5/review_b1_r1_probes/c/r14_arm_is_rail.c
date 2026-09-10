/* the CONDITION is also (via zext) related to an arm */
#include "CQ.h"
int main(void){ bool c=0; c=cq_theta(c,0.7); bool b=0; b=cq_theta(b,0.5); bool a=b?c:0; return cq_measure(a)+cq_measure(b)+cq_measure(c); }
