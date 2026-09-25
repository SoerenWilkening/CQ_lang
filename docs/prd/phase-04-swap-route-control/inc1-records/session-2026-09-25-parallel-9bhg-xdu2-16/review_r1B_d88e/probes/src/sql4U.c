#include <stdlib.h>
int main(int c, char **v) { long long m = atoll(v[1]); int m2 = atoi(v[2]); long long q = cq_theta(m, .5); long long t = (q + m); long long r = t; if (m2 > 3) r = cq_theta(t, .2); long long s = r; if (m2 > 5) s = cq_theta(r, .4); return (int)cq_measure(s); }
