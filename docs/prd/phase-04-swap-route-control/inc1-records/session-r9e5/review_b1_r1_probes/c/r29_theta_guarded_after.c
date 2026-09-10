/* the post-select theta is inside a classical guard that does not dominate */
#include "CQ.h"
int g(void);
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; if(g()) b=cq_theta(b,-0.5); return cq_measure(a)+cq_measure(b); }
