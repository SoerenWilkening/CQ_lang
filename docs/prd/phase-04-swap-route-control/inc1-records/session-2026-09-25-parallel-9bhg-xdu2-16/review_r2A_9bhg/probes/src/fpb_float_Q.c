#include <stdlib.h>
float hd(float a, float k);
__attribute__((noinline)) float f(float m) { float q = cq_theta(m, .5); return hd(q, m); }
int main(int c, char **v) { float m = atoi(v[1]); float r = f(m); if (r > 3) cq_phi(.3); float q2 = cq_theta(m, .2); return (int)cq_measure(q2) + (int)r; }
