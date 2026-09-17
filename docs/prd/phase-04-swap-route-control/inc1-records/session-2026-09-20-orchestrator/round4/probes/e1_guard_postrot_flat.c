/* e1 flat — the ONE-TRIP hand-expansion of e1 rolled (argc==1 under run_slice).
 * If the rolled form ACCEPTS, its trace must be compared against this. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    (void)argc;
    int acc = 5;
    {
        bool t = 0;
        t = cq_theta(t, 0.5);
        if (t) acc = 1;
    }
    acc = cq_theta(acc, 0.9);   /* TRAILING NON-DIAGONAL GATE */
    return cq_measure(acc);
}
