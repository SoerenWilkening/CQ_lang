/* clause 1 negative: a VLA — no compile-time shape */
#include "CQ.h"
__attribute__((noinline)) int slice(int n){ int a=5; bool b[n]; for(int i=0;i<n;++i){ b[i]=0; if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) a-=3; } return cq_measure(a)+cq_measure(b[0]); }
int main(void){ return slice(3); }
