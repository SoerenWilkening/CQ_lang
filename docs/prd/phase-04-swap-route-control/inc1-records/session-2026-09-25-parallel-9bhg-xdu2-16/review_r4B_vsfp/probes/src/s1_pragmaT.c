#include <stdlib.h>
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  return cq_measure(q);
}
