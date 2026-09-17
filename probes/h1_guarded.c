#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc;                 /* RUNTIME trip bound -> clang -O1 rotates with a zero-trip guard */
    int acc = 0;
    bool b0[8];
    for (int i = 0; i < n && i < 8; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) acc = 1;
    }
    return cq_measure(b0[0]) + cq_measure(acc);
}
