#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); for(int i=0;i<3;i++){ b=cq_theta(b,0.1);} int a=b?2:5; return cq_measure(a)+cq_measure(b); }
