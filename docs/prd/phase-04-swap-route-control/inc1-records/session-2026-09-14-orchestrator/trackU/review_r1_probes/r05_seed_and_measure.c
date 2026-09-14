/* clause 4 composition: an undef SEED and a never-quantum undef MEASURE in one
   function. The measure must still decline (bd 21mg), character-for-character. */
#include <CQ.h>
int f(void) {
  _Bool b;
  _Bool z;                 /* never quantum, never written */
  b = cq_theta(b, 0.5);
  return cq_measure(b) + cq_measure(z);
}
