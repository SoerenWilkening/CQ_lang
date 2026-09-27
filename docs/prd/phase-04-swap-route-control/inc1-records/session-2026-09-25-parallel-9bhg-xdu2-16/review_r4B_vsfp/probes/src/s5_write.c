#include <stdlib.h>
#pragma clang section bss="__DATA,__mmiob"
static volatile int CTRL;
#pragma clang section bss=""
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  if (q > 3) CTRL = 1;
  return cq_measure(q);
}
