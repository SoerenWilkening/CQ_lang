#include "CQ.h"
/* r5 where the loop body's ONLY reader is the rotation; the measure is AFTER the loop. */
int main(void){ int q=cq_theta(0,0.3); int last=0; for(int i=0;i<3;i++){ last=cq_theta(q,0.1); } return cq_measure(last); }
