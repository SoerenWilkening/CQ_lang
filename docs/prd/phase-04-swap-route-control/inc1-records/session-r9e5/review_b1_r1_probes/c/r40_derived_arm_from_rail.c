/* the true arm is derived FROM the condition register itself */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int z=(int)b; int a=b?z:5; return cq_measure(a)+cq_measure(b); }
