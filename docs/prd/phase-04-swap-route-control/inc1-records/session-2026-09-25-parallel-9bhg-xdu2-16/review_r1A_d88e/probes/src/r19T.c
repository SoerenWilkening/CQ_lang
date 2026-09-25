#include <stdlib.h>
static const int tab[8] = {3,1,4,1,5,9,2,6};
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int x = tab[t & 7]; int r = x; if (m > 3) r = cq_theta(x, .2); return cq_measure(r); }
