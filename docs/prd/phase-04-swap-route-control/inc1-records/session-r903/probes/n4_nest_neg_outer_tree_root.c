#include <stdbool.h>
int main(void) {
  bool a = cq_theta((bool)0, 0.5);
  bool a2 = cq_theta((bool)0, 0.7);
  bool b = cq_theta((bool)0, 0.3);
  if (!(a && a2)) { cq_phi(0.2); if (b) cq_phi(0.3); }
  return cq_measure(a) + cq_measure(a2) + cq_measure(b);
}
