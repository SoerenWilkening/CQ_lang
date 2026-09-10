/* a rail crosses a call boundary — clone-on-taint */
#include "CQ.h"
static int f(bool b){ return b?2:5; }
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=f(b); return cq_measure(a)+cq_measure(b); }
