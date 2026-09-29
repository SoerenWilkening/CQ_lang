#include <stdlib.h>
int main(int c, char **v) {
  int s = atoi(v[1]); int u = atoi(v[3]);
  int q = cq_theta(atoi(v[2]), 0.3);
  int b = (q > 3) ? s : u;
  int r = cq_theta(b, (q > 3) ? 0.7 : 0.2);
  return cq_measure(r) + cq_measure(q);
}
