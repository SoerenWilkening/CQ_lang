#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); if(b) cq_phi(0.9); int a=b?2:5; return cq_measure(a)+cq_measure(b); }
