#include <stdbool.h>
int slice(void) { int a = 5; bool b[6] = {0};
  for (int i = 0; i < 3; ++i) if (a >= 3) b[2*i] = cq_theta(b[2*i], .5);
  return cq_measure(a) + b[1]; }
int main(void){ return slice(); }
