#include <stdlib.h>
__attribute__((noinline,used)) int h(int m) { return cq_theta(m, .3); }
int main(int argc, char **argv) { int m = atoi(argv[1]); h(m); return 0; }
