#include <stdlib.h>
long long hw(long long a, long long k);
__attribute__((noinline)) long long fw(long long m) { long long q = cq_theta(m, .5); return hw(q, m); }
int main(int argc, char **argv) { long long m = (long long)atoi(argv[1]); long long n = (long long)atoi(argv[2]); long long q2 = cq_theta(n, .25); long long u = q2 + fw(m); return (int)cq_measure(u); }
