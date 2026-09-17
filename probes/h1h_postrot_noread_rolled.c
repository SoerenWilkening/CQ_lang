#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc - 1;
    int acc = 5;
    for (int i = 0; i < n; ++i) {
        bool t = 0;
        t = cq_theta(t, 0.5);
        if (t) acc -= 3;
    }
    acc = cq_theta(acc, 0.9);       /* trailing NON-DIAGONAL gate on the carried register */
    return cq_measure(acc);
}
