#include <stdlib.h>
static volatile int K = 2;
int main(int argc, char **v) { int q = cq_theta(0, 0.7); int acc = 0; for (int i = 0; i < 3; i++) { int d = (q > i) ? K : 1; acc += d; } return cq_measure(acc); }
