#include <stdlib.h>
float hd(float a, float k); float g2d(float a, float b);
int main(int argc, char **argv) { float m = (float)atoi(argv[1]); float n = (float)atoi(argv[2]); float q = cq_theta(m, .5); float q2 = cq_theta(n, .25); float t1 = m + 1; float t2 = hd(m, q2); float u = g2d(t1, t2); return (int)cq_measure(u); }
