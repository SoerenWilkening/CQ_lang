/* w4: alpha-reading of i1_arm_flag -- rotate the FLAG under its own control, flag MEASURED. */
#include "CQ.h"
int main(void){ int q = cq_theta(0,0.25); _Bool c = (q > 5); _Bool r = c;
  if (c) r = cq_theta(c, 0.9);
  return cq_measure(r)+cq_measure(c)+cq_measure(q); }
