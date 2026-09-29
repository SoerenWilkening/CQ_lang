#include <stdlib.h>
int slice(int m) {
    int q = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    if (q == m) { r = cq_theta(r, 0.9); r = cq_theta(r, 0.1); }
    else        { r = cq_theta(r, 0.1); }
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
