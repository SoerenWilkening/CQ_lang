#include <stdlib.h>
#include <stdbool.h>
int slice(int m) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(m, 0.25);
    for (int i = 0; i < 3; ++i) {
        if (b) r = cq_theta(r, 0.9);
        else   r = cq_theta(r, 0.3);
        b = cq_theta(b, 0.1);
    }
    return cq_measure(b) + cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
