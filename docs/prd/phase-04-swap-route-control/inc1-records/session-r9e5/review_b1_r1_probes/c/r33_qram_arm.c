/* the select arm reads a QROM (const global) */
#include "CQ.h"
static const int TBL[4]={7,8,9,10};
int main(void){ int q=cq_theta(1,0.2); bool b=0; b=cq_theta(b,0.5); int a=b?TBL[2]:5; return cq_measure(a)+cq_measure(b)+cq_measure(q); }
