#include "CQ.h"
int main(void){ int q = cq_theta(0,0.5); _Bool b = 0;
  if (q == 1) b = cq_theta(0, 0.9);      /* prepped rail NEVER measured -> leak? */
  return cq_measure(q); }
