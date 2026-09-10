#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; bool c=b^1; return cq_measure(a)+cq_measure(c); }
