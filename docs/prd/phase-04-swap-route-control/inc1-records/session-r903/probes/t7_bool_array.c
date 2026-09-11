#include <stdbool.h>
int main(void) {
  bool a[2] = {0, 0};
  a[0] = cq_theta((bool)0, 0.5);
  if (a[0]) cq_phi(0.3);
  return cq_measure(a[0]);
}
