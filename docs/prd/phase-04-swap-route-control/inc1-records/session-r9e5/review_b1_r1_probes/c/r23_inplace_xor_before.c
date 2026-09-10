/* an in-place-capable xor on the rail BEFORE the select, select reads the pre-xor name */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); bool c=b^1; int a=b?2:5; return cq_measure(a)+cq_measure(c); }
