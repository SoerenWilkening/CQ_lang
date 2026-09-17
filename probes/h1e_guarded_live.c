#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc;
    int acc = 0;
    for (int i = 0; i < n; ++i) {
        bool t = 0;
        t = cq_theta(t, 0.5);
        if (t) acc = 1;
    }
    return cq_measure(acc);
}
