#include <stdbool.h>
int slice(int seed) {
  bool b0[3] = {1,0,1};     /* a NON-zero initializer: -O1 spells it as a memcpy/stores */
  int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s;
}
int main(void) { return slice(0); }
