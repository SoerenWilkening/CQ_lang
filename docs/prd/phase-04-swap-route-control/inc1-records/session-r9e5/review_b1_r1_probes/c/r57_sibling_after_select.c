/* F-1b-1's class with the SIBLING theta AFTER the select — does the DT prong take it? */
#include "CQ.h"
int main(void){ int q=cq_theta(3,0.2); bool t=(bool)(q&1); bool b=cq_theta(t,0.5); int a=b?2:5; bool c=cq_theta(t,0.9); return cq_measure(a)+cq_measure(b)+cq_measure(c); }
