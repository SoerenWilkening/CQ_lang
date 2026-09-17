#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int z = 0;
  for (int i = 0; i < 2; i++) {
    if (q == 5) r = cq_theta(r, 0.9);
    int x = 5 - q;
    z = cq_theta(x, 0.2);
  }
  return cq_measure(r) + cq_measure(z);
}
