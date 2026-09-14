/* the p2 ACCEPTING in-loop shape (carried _Bool, in-body chained theta) + a VALUE arm
   on the carried register a — isolates the in-loop value arm's wall with the prep OK. */
#include "CQ.h"
int main(void){ int a=5; bool b=0; b=cq_theta(b,0.5);
  for(int i=0;i<3;++i){ b=cq_theta(b,0.5); if(b) a-=3; }
  return cq_measure(a)+cq_measure(b); }
