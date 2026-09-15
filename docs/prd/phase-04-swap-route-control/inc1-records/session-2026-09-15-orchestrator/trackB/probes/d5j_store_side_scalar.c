/* d5j — the SCALAR control for d5i: the same narrowing with no array anywhere.
   Whatever gate this emits is the gate the bank spelling must not lose. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void) argv;
    int q = cq_theta(argc, 0.5);
    char c = (char) q;
    return (int) cq_measure(c);
}
