/* mixed tree, theta on the RAIL after the select — the rail prong accepts, the compare prong is untouched */
#include "CQ.h"
int main(void){ int q=cq_theta(3,0.2); bool b=0; b=cq_theta(b,0.5); int a=(b&(q>5))?2:5; b=cq_theta(b,-0.5); return cq_measure(a)+cq_measure(b)+cq_measure(q); }
