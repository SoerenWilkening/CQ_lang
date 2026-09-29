#include <stdlib.h>
/* cq_measure ARGUMENT against the fmt3 merge: the pin makes both arms cq_measure(5) (the else arm measures a CLASSICAL 5) */
int main(int c, char **v) { int m0 = atoi(v[1]); int q = cq_theta(m0, .5); int t = q / 4; int m;
  if (t == 5) m = cq_measure(t); else m = cq_measure(5);
  return m + cq_measure(q); }
