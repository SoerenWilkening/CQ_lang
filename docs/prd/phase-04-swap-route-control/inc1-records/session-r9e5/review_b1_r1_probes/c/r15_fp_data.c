#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); double a=b?1.5:2.5; return (int)cq_measure(a)+cq_measure(b); }
