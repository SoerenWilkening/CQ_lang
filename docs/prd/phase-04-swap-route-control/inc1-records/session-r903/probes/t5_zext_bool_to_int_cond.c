#include <stdbool.h>
int main(void) {
  bool b = cq_theta((bool)0, 0.5);
  int t = b;
  if (t) cq_phi(0.3);
  return cq_measure(b);
}
