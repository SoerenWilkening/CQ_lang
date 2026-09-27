#include <stdlib.h>
static volatile int STATUS __attribute__((section("__DATA,__mmiob")));
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int r = 3;
  if (q > 3) r = STATUS;
  return cq_measure(r) + cq_measure(q);
}
