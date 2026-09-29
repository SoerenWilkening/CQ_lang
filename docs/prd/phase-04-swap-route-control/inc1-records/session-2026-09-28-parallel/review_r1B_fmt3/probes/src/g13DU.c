#include <stdlib.h>
int slice(int k) {
    int q = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    int p = q * 3;
    if (((p ^ (0 + k)) & 6) == 4) r = cq_theta(r, 0.9);
    if (((p ^ (1 + k)) & 6) == 4) r = cq_theta(r, 0.9);
    if (((p ^ (2 + k)) & 6) == 4) r = cq_theta(r, 0.9);
    q = cq_theta(q, 0.7);
    r = cq_theta(r, 0.2);
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
