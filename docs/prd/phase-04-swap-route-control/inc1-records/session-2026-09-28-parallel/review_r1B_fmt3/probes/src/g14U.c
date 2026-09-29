#include <stdlib.h>
int slice(int m) {
    int r = cq_theta(7, 0.25);
    int t = r ^ m;
    if ((t & 6) == 4) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);
    t = r ^ m;
    if ((t & 6) == 4) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);
    t = r ^ m;
    if ((t & 6) == 4) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);
    t = r ^ m;
    return cq_measure(r) + cq_measure(t);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
