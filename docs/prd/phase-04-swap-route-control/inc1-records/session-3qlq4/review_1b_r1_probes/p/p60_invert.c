#include "CQ.h"
int main(void){ bool b = cq_theta((bool)0,0.5);
  cq_invert_begin();
  if (b) cq_phi(0.7);
  cq_invert_end();
  return cq_measure(b); }
