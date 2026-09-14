#include <stdbool.h>
int slice(int n) { int a = 5, t = 0; bool b[3] = {0};
  for (int i = 0; i < 3; ++i) { if (a >= 3) b[i] = cq_theta(b[i], .5);
    for (int k = 0; k < n; ++k) t += k;
    if (b[i]) a -= 3; }
  int s = cq_measure(a) + t; for (int i=0;i<3;++i) s += cq_measure(b[i]); return s; }
int main(void){ return slice(2); }
