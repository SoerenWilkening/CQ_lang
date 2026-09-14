/* clause 2 negative: a TAINTED index — 7.5's axis must keep its own decline */
#include "CQ.h"
int main(void){ int q=cq_theta(0,0.5); bool b[4]={0}; b[q&3]=cq_theta(b[q&3],0.5); return cq_measure(b[0]); }
