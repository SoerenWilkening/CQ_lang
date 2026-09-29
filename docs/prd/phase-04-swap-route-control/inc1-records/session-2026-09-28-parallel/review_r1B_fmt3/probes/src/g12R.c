#include <stdlib.h>
int slice(int m) {
    int q = cq_theta(0, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        int r = cq_theta(7, 0.25);
        if ((q & 6) == m) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);
        acc += cq_measure(r);
        q = cq_theta(q, 0.1);
    }
    return acc + cq_measure(q);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
