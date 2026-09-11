/* v4: _Bool unfolded self-controlled via a compare on the bool's int twin. */
#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.25); _Bool b = cq_theta((_Bool)0, 0.25);
  _Bool c = b;
  if (q > 5) c = cq_theta(b, 0.9);
  return cq_measure(c) + cq_measure(q); }
