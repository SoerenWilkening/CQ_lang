#include <stdbool.h>
int main(void) {
  bool b = cq_theta((bool)0, 0.5);
  bool c = cq_theta((bool)0, 0.3);
  bool d = cq_theta((bool)0, 0.7);
  if (!b && c && d) cq_phi(0.3);
  return cq_measure(b) + cq_measure(c) + cq_measure(d);
}
