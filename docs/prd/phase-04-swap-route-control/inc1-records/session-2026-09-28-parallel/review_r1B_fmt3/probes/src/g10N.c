#include <stdlib.h>
int slice(int m) {
    int q = cq_theta(0, 0.5);
    int s = cq_theta(1, 0.4);
    int r = cq_theta(7, 0.25);
    if (s == 3) {
        if (q == m) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);
    }
    return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
