#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int acc=0; for(int i=0;i<32;i++){ int a=b?2+i:5; acc+=cq_measure(a);} return acc+cq_measure(b); }
