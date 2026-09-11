#include <stdbool.h>
int main(void) {
  unsigned char q = cq_theta((unsigned char)0, 0.3);
  bool t = q & 1u;
  if (t) cq_phi(0.3);
  return cq_measure(q);
}
