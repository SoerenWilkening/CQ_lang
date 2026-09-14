/* unconditional prep + PHASE arm — the known-good in-loop shape (control) */
#include "CQ.h"
int main(void){ int a=5; for(int i=0;i<3;++i){ bool t=0; t=cq_theta(t,0.5); if(t) cq_phi(0.5);} return cq_measure(a);}
