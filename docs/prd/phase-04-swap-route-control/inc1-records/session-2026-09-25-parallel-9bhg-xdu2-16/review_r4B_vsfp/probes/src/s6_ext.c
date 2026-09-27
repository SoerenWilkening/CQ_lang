#include <stdlib.h>
volatile int EXT = 7;
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  if (q > 3) (void)EXT;
  return cq_measure(q);
}
