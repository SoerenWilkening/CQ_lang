#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); cq_invert_begin(); int a=b?2:5; cq_invert_end(); return cq_measure(a)+cq_measure(b); }
