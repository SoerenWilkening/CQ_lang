#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; int m=cq_measure(b); return m+cq_measure(a); }
