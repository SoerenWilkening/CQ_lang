#include <stdbool.h>
int slice(int seed) {
  bool b0[3]; 
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
  bool t = seed ? b0[0] : b0[1];   /* a SELECT over two bank loads */
  return cq_measure(t) + cq_measure(b0[2]);
}
int main(void) { return slice(0); }
