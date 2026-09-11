#include <stdbool.h>
int main(void) {
  bool b = cq_theta((bool)0, 0.5);
  bool t = b ^ 1;
  if (t) cq_phi(0.3);
  return cq_measure(b);
}
