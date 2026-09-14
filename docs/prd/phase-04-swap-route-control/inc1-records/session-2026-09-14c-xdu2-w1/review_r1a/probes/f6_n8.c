#include <stdbool.h>
int slice(void) { int a = 20; bool b[8] = {0};
  for (int i = 0; i < 8; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5); if (b[i]) a -= 3; }
  int s = cq_measure(a); for (int i=0;i<8;++i) s += cq_measure(b[i]); return s; }
int main(void){ return slice(); }
