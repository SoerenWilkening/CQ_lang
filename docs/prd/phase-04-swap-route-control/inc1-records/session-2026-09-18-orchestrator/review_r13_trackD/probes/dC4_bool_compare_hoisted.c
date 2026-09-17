// The i8 _Bool wire: a compare on a _Bool register, hoisted out of the loop.
#include <CQ.h>
int main(void) {
  _Bool b = cq_theta((_Bool)0, 0.5);
  int r = cq_theta(0, 0.3);
  for (int i = 0; i < 2; i++) {
    if (b) r = cq_theta(r, 0.9);
  }
  return cq_measure(b) + cq_measure(r);
}
