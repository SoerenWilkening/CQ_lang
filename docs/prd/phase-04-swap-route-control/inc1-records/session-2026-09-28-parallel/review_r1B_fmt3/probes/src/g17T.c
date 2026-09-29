#include <stdlib.h>
int slice(int m) {
    int q = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    r = cq_theta(r, ((q & 6) == m) ? 0.9 : 0.3);
    q = cq_theta(q, 0.7);
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
