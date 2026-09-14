/* clause 2' negative, the REAL one: a VARIABLE but NON-INJECTIVE index (i>>1 hits
   each cell twice), so a later trip's seed load is a previously-stored HANDLE. */
#include "CQ.h"
int main(void){ int a=5; bool b[2]={0}; for(int i=0;i<4;++i){ if(a>=3) b[i>>1]=cq_theta(b[i>>1],0.5); if(b[i>>1]) a-=3; } return cq_measure(a)+cq_measure(b[0])+cq_measure(b[1]); }
