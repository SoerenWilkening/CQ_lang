/* unconditional prep + value arm — is the in-loop VALUE arm the wall? */
#include "CQ.h"
int main(void){ int a=5; for(int i=0;i<3;++i){ bool t=0; t=cq_theta(t,0.5); if(t) a-=3;} return cq_measure(a);}
