#include <stdbool.h>
int slice(void) { int a = 5; bool b[3] = {0}; bool c[3] = {0};
  for (int i = 0; i < 3; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5); if (b[i]) a -= 3; }
  for (int i = 0; i < 3; ++i) { if (a >= 1) c[i] = cq_theta(c[i], .25); if (c[i]) a -= 1; }
  int s = cq_measure(a); for (int i=0;i<3;++i) s += cq_measure(b[i]) + cq_measure(c[i]); return s; }
int main(void){ return slice(); }
