/* w5: alpha-reading of range_knownbits -- rotate the zext'd compare under a cond on it. */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.25); int b = (q > 7); int r = b;
  if (b > 0) r = cq_theta(b, 0.9);
  return cq_measure(r)+cq_measure(q); }
