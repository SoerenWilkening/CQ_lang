/* clause 1 negative: the array's address ESCAPES to an opaque callee */
#include "CQ.h"
void sink(bool*);
int main(void){ int a=5; bool b[3]={0}; for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) a-=3; } sink(b); return cq_measure(a); }
