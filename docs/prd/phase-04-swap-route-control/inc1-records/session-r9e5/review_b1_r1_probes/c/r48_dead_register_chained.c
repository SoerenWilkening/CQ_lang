/* dead register with a two-hop chain: does the spine close and FREE h0? */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); bool b=cq_theta(b0,0.3); int a=b?2:5; return cq_measure(a); }
