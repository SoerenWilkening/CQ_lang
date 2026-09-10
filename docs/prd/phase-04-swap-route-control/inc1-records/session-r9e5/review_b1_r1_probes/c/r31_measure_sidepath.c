#include "CQ.h"
int g(void);
int main(void){ bool b=0; b=cq_theta(b,0.5); int m=0; if(g()) m=cq_measure(b); int a=b?2:5; return m+cq_measure(a); }
