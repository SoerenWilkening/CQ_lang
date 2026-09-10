#include "CQ.h"
#include <stdio.h>
int main(void){ bool b=0; b=cq_theta(b,0.5); int a=b?2:5; printf("%d\n", cq_measure(a)); return cq_measure(b); }
