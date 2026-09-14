/* clause 1 negative: a GLOBAL (not a non-escaping alloca) */
#include "CQ.h"
bool g[3];
int main(void){ int a=5; for(int i=0;i<3;++i){ if(a>=3) g[i]=cq_theta(g[i],0.5); if(g[i]) a-=3; } return cq_measure(a); }
