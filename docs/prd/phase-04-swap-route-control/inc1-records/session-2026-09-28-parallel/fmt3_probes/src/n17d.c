#include <stdlib.h>
/* n17's parts: the diamond (no else) — the in-place Ry arm on W under q == 5 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int W = q + 1; int r = W;
  if (q == 5) r = cq_theta(W, .9);
  return cq_measure(r) + cq_measure(q); }
