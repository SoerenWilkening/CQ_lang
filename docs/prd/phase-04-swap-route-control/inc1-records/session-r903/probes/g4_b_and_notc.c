#include <stdbool.h>
int main(void) {
  bool b = cq_theta((bool)0, 0.5);
  bool c = cq_theta((bool)0, 0.3);
  if (b && !c) cq_phi(0.3);
  return cq_measure(b) + cq_measure(c);
}
