#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q = cq_theta(m, .5); int t = (m + 1); int t2 = (n + 1); int s = n > 2 ? t : t2; int r = s; if (m > 3) r = cq_theta(s, .2); return cq_measure(r); }
