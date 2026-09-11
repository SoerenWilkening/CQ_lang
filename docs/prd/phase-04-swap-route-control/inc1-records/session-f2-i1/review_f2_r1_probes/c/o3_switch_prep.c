#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); int r = 5;
  switch(q){ case 5: r = cq_theta(5,0.9); break; default: break; }
  return cq_measure(q)+cq_measure(r); }
