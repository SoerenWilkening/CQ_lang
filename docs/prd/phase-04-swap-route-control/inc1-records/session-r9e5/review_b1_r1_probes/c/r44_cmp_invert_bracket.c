/* r32's COMPARE twin — is the ignored invert bracket pre-existing? */
#include "CQ.h"
int main(void){ int q=cq_theta(3,0.2); cq_invert_begin(); int a=(q>5)?2:5; cq_invert_end(); return cq_measure(a)+cq_measure(q); }
