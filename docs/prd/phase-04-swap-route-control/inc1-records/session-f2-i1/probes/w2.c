/* w2: beta-reading -- straight-through is the LIVE register, arm is a genuine prep. */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.25); int r = q;
  if (q > 5) r = cq_theta(5, 0.9);
  return cq_measure(r)+cq_measure(q); }
