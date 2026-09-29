#include <stdlib.h>
int main(int c, char **v) {
  _Bool s = atoi(v[1]) != 0;
  _Bool b = cq_theta((_Bool)(atoi(v[2]) != 0), 0.3);
  _Bool r = s;
  if (b) r = cq_theta(s, 0.2);
  _Bool r2 = s;
  if (r) r2 = cq_theta(s, 0.4);
  return cq_measure(r2) + cq_measure(r) + cq_measure(b);
}
