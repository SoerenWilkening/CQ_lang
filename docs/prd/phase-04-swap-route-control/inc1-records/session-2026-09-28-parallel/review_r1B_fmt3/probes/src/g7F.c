#include <stdlib.h>
int slice(double a, double b) {
    int q = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    if ((q & 6) == 4) r = cq_theta(r, a); else r = cq_theta(r, b);
    q = cq_theta(q, 0.7);
    r = cq_theta(r, 0.2);
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atof(argv[1]), atof(argv[2])); return 0; }
