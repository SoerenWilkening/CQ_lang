/* select BEFORE the loop; the theta on the rail inside the loop body */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; for(int i=0;i<3;i++){ b=cq_theta(b,0.1);} return cq_measure(a)+cq_measure(b); }
