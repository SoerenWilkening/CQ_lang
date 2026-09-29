#include <stdlib.h>
int slice(int m) {
    int q = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    switch (q & 3) {
    case 0: r = cq_theta(r, 0.1); break;
    case 1: r = cq_theta(r, 0.2); break;
    default: r = cq_theta(r, 0.3); break;
    }
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
