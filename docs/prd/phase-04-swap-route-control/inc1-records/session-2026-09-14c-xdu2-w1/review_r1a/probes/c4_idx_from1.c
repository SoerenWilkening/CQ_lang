#include <stdbool.h>
int slice(void) { int a = 5; bool b[3] = {0};
  for (int i = 1; i < 3; ++i) if (a >= 3) b[i] = cq_theta(b[i], .5);
  return cq_measure(a) + b[0]; }
int main(void){ return slice(); }
