/* prep region only, no value arm — is the CONTROLLED STATE PREP the in-loop wall? */
#include "CQ.h"
int main(void){ int a=5; int s=0; for(int i=0;i<3;++i){ bool t=0; if(a>=3) t=cq_theta(t,0.5); s+=cq_measure(t);} return s+cq_measure(a);}
