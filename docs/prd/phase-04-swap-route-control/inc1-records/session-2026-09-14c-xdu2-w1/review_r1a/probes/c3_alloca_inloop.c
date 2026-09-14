#include <stdbool.h>
int slice(int n) {
  int a = 5, s = 0;
  for (int k = 0; k < n; ++k) { bool b[3] = {0};
    for (int i = 0; i < 3; ++i) if (a >= 3) b[i] = cq_theta(b[i], .5);
    s += b[0]; }
  return s + cq_measure(a);
}
int main(void){ return slice(2); }
