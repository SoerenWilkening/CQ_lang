#include <stdlib.h>
long long h(long long a, long long k);
int main(int c, char **v) { long long m = atoll(v[1]); int m2 = atoi(v[2]); long long q = cq_theta(m, .5); long long t = h(q, m); int acc = 0; for (int i = 0; i < m2; i++) { long long r = t; if ((i & 1) == 0) r = cq_theta(t, .2); acc += (int)cq_measure(r); } return acc; }
