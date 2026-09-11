#include <stdbool.h>
int main(void) {
  int q = cq_theta(0, 0.3);
  bool t = q;
  if (t) cq_phi(0.3);
  return cq_measure(q);
}
