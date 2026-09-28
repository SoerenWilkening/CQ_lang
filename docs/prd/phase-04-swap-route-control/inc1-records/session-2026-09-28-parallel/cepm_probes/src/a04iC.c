#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int acc = 0; for (int i = 0; i < 8; i++) { if (h(q, i + m) > 5) break; acc += i; } return acc + cq_measure(q); }
