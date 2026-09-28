#include <stdlib.h>
int main(int c, char **v) {
  int x = atoi(v[1]);
  _Bool s = x & 1;
  _Bool r = cq_theta(s, 0.2);
  return cq_measure(r);
}
