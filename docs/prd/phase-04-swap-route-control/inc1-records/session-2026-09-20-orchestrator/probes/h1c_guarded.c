#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc;
    if (n > 3) n = 3;
    int acc = 0;
    bool b0[3];
    for (int i = 0; i < n; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) acc = 1;
    }
    return cq_measure(b0[0]) + cq_measure(acc);
}
