#include <stdlib.h>
int main(int c, char **v) { long long m = atoll(v[1]); int m2 = atoi(v[2]); long long q = cq_theta(m, .5); long long t = (m+1); long long r = t; int x = 0; if (m2 > 3) r = cq_theta(t, .2); else x = (int)cq_measure(t); return (int)cq_measure(r) + x; }
