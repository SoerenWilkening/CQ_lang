#include <stdbool.h>
int slice(void) { int a = 5; bool b[8] = {0};
  for (int i = 0; i < 3; ++i) if (a >= 3) b[i] = cq_theta(b[i], .5);
  return cq_measure(a) + b[7]; }
int main(void){ return slice(); }
