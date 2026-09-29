#include <stdlib.h>
int slice(int m) {
    int q = cq_theta(0, 0.5);
    unsigned int r = cq_theta((unsigned int)1, 0.25);
    if (q == m) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);
    return cq_measure(q) + (int)cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
