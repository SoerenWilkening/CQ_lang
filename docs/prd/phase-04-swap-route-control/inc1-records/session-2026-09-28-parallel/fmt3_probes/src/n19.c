#include <stdlib.h>
/* the owner-style bool cascade: a legitimate literal prep beside an OFF-wire live bool (coarse-fence cost probe) */
#include <stdbool.h>
int main(int c, char **v) { bool b0 = cq_theta(0, .5); bool b1 = 0; bool b2 = 0;
  if (b0) b1 = cq_theta(0, .7);
  if (b1) b2 = cq_theta(0, .3);
  return cq_measure(b0) + cq_measure(b1) + cq_measure(b2); }
