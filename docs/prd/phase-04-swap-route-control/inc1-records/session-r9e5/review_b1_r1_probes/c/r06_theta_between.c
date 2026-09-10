/* chained theta BETWEEN the def and the select, select reads the STALE name */
#include "CQ.h"
int main(void){ bool b=0; bool b1=cq_theta(b,0.5); bool b2=cq_theta(b1,0.3); int a=b1?2:5; return cq_measure(b2)+cq_measure(a); }
