#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc - 1;               /* RUNTIME trip bound; run with 2 args -> n == 2 */
    int acc = 5;
    for (int i = 0; i < n; ++i) {
        bool t = 0;
        t = cq_theta(t, 0.5);
        if (acc >= 3) t = cq_theta(t, 0.25);   /* the condition READS the carried register */
        if (t) acc -= 3;
    }
    acc = cq_theta(acc, 0.9);       /* TRAILING NON-DIAGONAL GATE on that register */
    return cq_measure(acc);
}
