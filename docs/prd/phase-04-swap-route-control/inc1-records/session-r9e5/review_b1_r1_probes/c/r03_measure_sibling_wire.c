/* two SIBLING thetas off one template parent; measure the sibling before the select on b */
#include "CQ.h"
int main(void){ int q=cq_theta(3,0.2); bool t=(bool)(q&1); bool b=cq_theta(t,0.5); bool c=cq_theta(t,0.9); int m=cq_measure(c); int a=b?2:5; return m+cq_measure(a); }
