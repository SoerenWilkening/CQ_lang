/* k3: select, then S-dagger on the same register */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; b=cq_theta(b,-0.5); return cq_measure(b)+cq_measure(a); }
