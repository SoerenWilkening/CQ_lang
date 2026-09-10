#include "CQ.h"
int run(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; return cq_measure(a)+cq_measure(b); }
int main(void){ return run(); }
