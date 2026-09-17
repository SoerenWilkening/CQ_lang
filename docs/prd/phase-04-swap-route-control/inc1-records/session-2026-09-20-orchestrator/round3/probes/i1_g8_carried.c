// I1 — bd 6n1s' g8 shape (an ARM-MINTED interior rail in a multi-block marked
// body, which `planInteriorComponent` §4 abandons) composed with zujr's carried
// handle. On MAIN the g8 door is closed by `declineUndischargedMarkedBodyRails`;
// the question is whether tu9q's (ii-d) marking re-opens it through the
// carried-handle route.
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int a = 5;
    int s = 0;
    for (int k = 1; k <= 4; ++k) {
        int d = (y >> k);
        s += cq_measure(d & 1);
        if (k < lim) { int e = d + 7; s += cq_measure(e & 2); }
        if (a >= 3) a -= 3;
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y) + cq_measure(a);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
