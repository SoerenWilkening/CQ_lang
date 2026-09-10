/* a select inside a phase-kickback arm, on the same rail */
#include "CQ.h"
int g(void);
int main(void){ int q=cq_theta(3,0.2); bool b=0; b=cq_theta(b,0.5); int a=5; if(q>5){ a=b?2:5; } return cq_measure(a)+cq_measure(b)+cq_measure(q); }
