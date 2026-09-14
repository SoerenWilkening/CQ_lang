#include <stdbool.h>
int slice(void) { int a = 5; bool b[3] = {0}; int i = 0;
  do { b[i] = cq_theta(b[i], .5); if (b[i]) a -= 3; ++i; } while (i < 3);
  int s = cq_measure(a); for (int k=0;k<3;++k) s += cq_measure(b[k]); return s; }
int main(void){ return slice(); }
