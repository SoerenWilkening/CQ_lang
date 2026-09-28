#include <stdlib.h>
/* n2 without the outer region: switch (t) { case 5: r = cq_theta(t,.9); default: r = cq_theta(5,.9); } */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  switch (t) { case 5: r = cq_theta(t, .9); break; default: r = cq_theta(5, .9); break; }
  return cq_measure(r) + cq_measure(t); }
