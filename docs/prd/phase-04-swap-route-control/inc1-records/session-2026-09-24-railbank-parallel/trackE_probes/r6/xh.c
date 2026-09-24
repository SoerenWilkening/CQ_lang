#include <stdlib.h>
int h(int a, int k);
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int t = h(q, m); int r = m; if ((t > 3) & (m == n)) r = m + 5; return cq_measure(r); }
