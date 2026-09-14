#include <stdbool.h>
int slice(int n) { int a = 5; bool b[3] = {0};
  for (int i = 0; i < 3; ++i) { if (i == n) continue; if (a >= 3) b[i] = cq_theta(b[i], .5); if (b[i]) a -= 3; }
  return cq_measure(a) + b[0]; }
int main(void){ return slice(1); }
