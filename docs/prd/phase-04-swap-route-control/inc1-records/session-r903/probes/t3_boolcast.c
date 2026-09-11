#include <stdbool.h>
int main(void) {
  int q = cq_theta(0, 0.3);
  if ((bool)q) cq_phi(0.3);
  return cq_measure(q);
}
