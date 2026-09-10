/* measure a value DERIVED from the rail before the select (out-of-place zext -> different wire) */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int z=(int)b+1; int m=cq_measure(z); int a=b?2:5; return m+cq_measure(a); }
