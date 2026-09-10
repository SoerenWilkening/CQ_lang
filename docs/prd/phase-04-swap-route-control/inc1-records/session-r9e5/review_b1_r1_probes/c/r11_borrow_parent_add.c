/* a chain that BORROWS the register as a parent, beside the select */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int z=(int)b+1; int a=b?2:5; return cq_measure(a)+cq_measure(z); }
