/* array + PHASE arm (no carried a mutation) — peels W3 away, leaves W1+W2 */
#include "CQ.h"
int main(void){ bool b[3]={0}; int a=5;
  for(int i=0;i<3;++i){ if(a>=3) b[i]=cq_theta(b[i],0.5); if(b[i]) cq_phi(0.5); }
  int s=0; for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
