#include <stdlib.h>
int main(int c, char **v) { long long m = atoll(v[1]); int m2 = atoi(v[2]); long long q = cq_theta(m, .5); long long t = (q + m); long long r = t; switch (m2) { case 1: r = cq_theta(t, .1); break; case 4: r = cq_theta(t, .4); break; case 7: r = cq_theta(t, .7); break; } return (int)cq_measure(r); }
