#include <stdlib.h>
int slice(int m) {
    int q = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    int p = r * 3;
    for (int i = 0; i < 3; ++i) {
        if (((p ^ q) & 6) == m) r = cq_theta(r, 0.9);
        else                    r = cq_theta(r, 0.3);
        q = cq_theta(q, 0.1);
    }
    return cq_measure(q) + cq_measure(r) + cq_measure(p);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
