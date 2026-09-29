#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int b[4]; for (int i = 0; i < 4; i++) { g(q); b[i] = i + 1; } int s = 0; for (int i = 0; i < 4; i++) s += cq_measure(b[i]); return s + cq_measure(q); }
