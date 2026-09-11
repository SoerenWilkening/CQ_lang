#include <stdbool.h>
int main(void) {
  bool a = cq_theta((bool)0, 0.5);
  bool b = cq_theta((bool)0, 0.3);
  if (a) { cq_phi(0.2); if (b) cq_phi(0.3); }
  return cq_measure(a) + cq_measure(b);
}
