#include <stdlib.h>
__attribute__((noinline)) int g(int m, int n) { return cq_theta(m,.3); }
int main(int argc, char **argv) { g(atoi(argv[1]), 0); return 0; }
