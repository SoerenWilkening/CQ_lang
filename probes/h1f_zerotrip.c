#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc - 1;          /* no args -> n == 0 -> the loop never runs */
    int acc = 7;
    for (int i = 0; i < n; ++i) {
        bool t = 0;
        t = cq_theta(t, 0.5);
        if (t) acc = 1;
    }
    return cq_measure(acc);
}
