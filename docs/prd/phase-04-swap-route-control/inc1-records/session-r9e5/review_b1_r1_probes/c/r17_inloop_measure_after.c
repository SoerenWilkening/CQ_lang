/* F-B1-1 reproducer: loop-variant arm keeps the select in the body, measure of b AFTER it */
#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int acc=0; for(int i=0;i<3;i++){ int a=b?i:5; acc+=cq_measure(a)+cq_measure(b);} return acc; }
