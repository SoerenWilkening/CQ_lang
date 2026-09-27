#include <stdlib.h>
int main(int argc, char **v) { int q = cq_theta(0, 0.7); int acc = 0; for (int i = 0; i < 3; i++) { int d = (q > i) ? 2 : 1; acc += d; } return cq_measure(acc); }
