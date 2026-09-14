/* clause 2' negative: a NON-INJECTIVE index (every trip writes cell 0) */
#include "CQ.h"
int main(void){ int a=5; bool b[3]={0}; for(int i=0;i<3;++i){ if(a>=3) b[0]=cq_theta(b[0],0.5); if(b[0]) a-=3; } return cq_measure(a)+cq_measure(b[0]); }
