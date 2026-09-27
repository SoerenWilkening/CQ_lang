#include <stdlib.h>
float hw(float a, float k);
__attribute__((noinline)) float fw(float m) { float q = cq_theta(m, .5); return hw(q, m); }
int main(int argc, char **argv) { float m = (float)atoi(argv[1]); float n = (float)atoi(argv[2]); float q2 = cq_theta(n, .25); float u = q2 + fw(m); return (int)cq_measure(u); }
