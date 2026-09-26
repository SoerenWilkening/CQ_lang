#include <stdlib.h>
short hw(short a, short k);
__attribute__((noinline)) short fw(short m) { short q = cq_theta(m, .5); return hw(q, m); }
int main(int argc, char **argv) { short m = (short)atoi(argv[1]); short n = (short)atoi(argv[2]); short q2 = cq_theta(n, .25); short u = q2 + fw(m); return (int)cq_measure(u); }
