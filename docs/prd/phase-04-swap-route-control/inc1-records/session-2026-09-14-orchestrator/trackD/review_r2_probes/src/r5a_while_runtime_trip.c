#include "CQ.h"
/* r5 with a RUNTIME trip count. */
int slice(int n){ int q=cq_theta(0,0.3); int s=0; for(int i=0;i<n;i++){ int b=cq_theta(q,0.1); s+=cq_measure(b); } return s; }
int main(void){ return slice(3); }
