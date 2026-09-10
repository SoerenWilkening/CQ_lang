#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; int c=b?7:9; return cq_measure(a)+cq_measure(c)+cq_measure(b); }
