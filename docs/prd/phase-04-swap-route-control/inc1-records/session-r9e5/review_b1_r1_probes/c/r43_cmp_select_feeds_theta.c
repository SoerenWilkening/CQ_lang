/* r25's COMPARE twin */
#include "CQ.h"
int main(void){ int q=cq_theta(3,0.2); bool c=0,d=0; c=cq_theta(c,0.7); d=cq_theta(d,0.9); bool o=(q>5)?c:d; o=cq_theta(o,0.3); return cq_measure(o)+cq_measure(q); }
