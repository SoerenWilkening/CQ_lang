#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); long long a=b?2LL:5LL; short s=b?(short)3:(short)4; return (int)cq_measure(a)+cq_measure(s)+cq_measure(b); }
