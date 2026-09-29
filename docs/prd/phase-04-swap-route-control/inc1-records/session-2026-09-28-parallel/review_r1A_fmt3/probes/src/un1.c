#include <stdlib.h>
/* r1A: pin by __builtin_unreachable: SimplifyCFG turns the branch into llvm.assume and the rotated t becomes 5 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4;
  if (t != 5) __builtin_unreachable();
  int r = cq_theta(t, .9);
  return cq_measure(r) + cq_measure(q); }
