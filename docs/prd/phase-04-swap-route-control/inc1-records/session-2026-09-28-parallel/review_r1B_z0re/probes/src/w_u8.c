#include <stdlib.h>
int main(int c, char **v) {
  unsigned char s = (unsigned char)atoi(v[1]);
  int q = cq_theta(atoi(v[2]), 0.3);
  unsigned char r = s;
  if (q > 3) r = cq_theta(s, 0.2);
  return (int)cq_measure(r) + cq_measure(q);
}
