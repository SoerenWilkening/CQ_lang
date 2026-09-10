/* the rail is a CHAINED theta; the MEASURE is on the PARENT name (same physical wire) BEFORE the select */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); bool b=cq_theta(b0,0.3); int m=cq_measure(b0); int a=b?2:5; return m+cq_measure(a); }
