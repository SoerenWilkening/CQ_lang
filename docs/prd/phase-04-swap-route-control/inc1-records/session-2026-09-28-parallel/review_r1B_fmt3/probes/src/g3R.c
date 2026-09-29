#include <stdlib.h>
int slice(int m) {
    int r = cq_theta(7, 0.25);
    for (int i = 0; i < 3; ++i) {
        if ((r & 6) == m) r = cq_theta(r, 0.9);
        else              r = cq_theta(r, 0.3);
    }
    return cq_measure(r);
}
int main(int argc, char **argv) { (void) slice(atoi(argv[1])); return 0; }
