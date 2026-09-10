/* h05 — the rail select sits inside a CLASSICALLY guarded block; the register is
   measured on the other side of the guard, AFTER the join. */
#include "CQ.h"
int main(int argc,char**argv){ (void)argv; bool b=0; b=cq_theta(b,0.5); int a=5;
  if(argc>3) a = b?2:5;
  return cq_measure(a)+cq_measure(b); }
