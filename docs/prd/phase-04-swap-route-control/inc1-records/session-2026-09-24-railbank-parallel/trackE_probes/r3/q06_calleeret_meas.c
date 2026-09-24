#include <stdlib.h>
__attribute__((noinline)) int g(int k) { return cq_theta(k, 0.7); }
int main(int argc, char **argv) { int r = g(atoi(argv[1])); return cq_measure(r); }
