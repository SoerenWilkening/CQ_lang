/* measure the wire, THEN rotate it, THEN select on the rotated name */
#include "CQ.h"
int main(void){ bool b0=0; b0=cq_theta(b0,0.5); int m=cq_measure(b0); bool b=cq_theta(b0,0.3); int a=b?2:5; return m+cq_measure(a); }
