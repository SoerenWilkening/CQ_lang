#include "CQ.h"
int main(void){ bool b=0; int acc=0; for(int i=0;i<3;i++){ b=cq_theta(b,0.5); int a=b?2:5; acc+=cq_measure(a);} return acc+cq_measure(b); }
