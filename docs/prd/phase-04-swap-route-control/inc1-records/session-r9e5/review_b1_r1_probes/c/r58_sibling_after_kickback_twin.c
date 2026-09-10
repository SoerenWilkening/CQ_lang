/* the KICKBACK twin of r57 — the 1b behaviour on main */
#include "CQ.h"
int main(void){ int q=cq_theta(3,0.2); bool t=(bool)(q&1); bool b=cq_theta(t,0.5); if(b) cq_phi(0.4); bool c=cq_theta(t,0.9); return cq_measure(b)+cq_measure(c); }
