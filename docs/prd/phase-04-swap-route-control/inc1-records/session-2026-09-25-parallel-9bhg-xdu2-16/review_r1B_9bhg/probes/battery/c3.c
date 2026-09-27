#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
volatile int G;
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); bool b[3]; for (int i = 0; i < 3; i++) b[i] = cq_theta((bool)((n >> i) & 1), .25); int u = h(q, m); for (int i = 0; i < 3; i++) if (b[i]) u = cq_theta(u, 0.3); int s = 0; for (int i = 0; i < 3; i++) s += cq_measure(b[i]); return cq_measure(u) + s; }
