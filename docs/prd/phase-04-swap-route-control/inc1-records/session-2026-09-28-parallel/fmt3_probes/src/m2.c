#include <stdlib.h>
/* cq_measure, second route: arms differ in ONE operand -> sink -> select(q == 20, t, 5) -> 5 */
int main(int c, char **v) { int m0 = atoi(v[1]); int q = cq_theta(m0, .5); int t = q / 4; int m;
  if (q == 20) m = cq_measure(t); else m = cq_measure(5);
  return m + cq_measure(q); }
