#include <stdbool.h>
int slice(int a) { bool c[3] = {0};
  for (int i = 0; i < 3; ++i) { if (a >= 1) c[i] = cq_theta(c[i], .25); if (c[i]) a -= 1; }
  int s = cq_measure(a); for (int i=0;i<3;++i) s += cq_measure(c[i]); return s; }
int main(void){ return slice(5); }
