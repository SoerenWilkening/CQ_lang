/* the rail is defined in another block (an opaque classical guard) */
#include "CQ.h"
int g(void);
int main(void){ bool b=0; if(g()) b=cq_theta(b,0.5); int a=b?2:5; return cq_measure(a)+cq_measure(b); }
