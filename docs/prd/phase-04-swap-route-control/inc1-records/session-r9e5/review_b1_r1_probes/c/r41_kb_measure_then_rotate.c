/* r22's twin at the KICKBACK: measure the wire, then rotate it, then gate on it */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); int m=cq_measure(b0); bool b=cq_theta(b0,0.3); if(b) cq_phi(0.9); return m; }
