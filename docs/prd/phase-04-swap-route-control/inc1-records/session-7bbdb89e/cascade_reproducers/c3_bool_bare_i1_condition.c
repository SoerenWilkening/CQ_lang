/* shape 3 — `bool b0`: -O1 rewrites `b0 == 0` as the bare tainted i1, so the select's condition is the register itself, no compare (bd 3qlq.4) */
#include "CQ.h"
int main(void){ int a = 5; bool b0 = 1;
  if (a >= 3){ b0 = cq_theta(b0, 0.5); }
  if (b0 == 0) a -= 3;
  return cq_measure(a) + cq_measure(b0); }
