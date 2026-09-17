/* HAND-UNROLLED TWIN of t5j_twoblock_noexit_rot.c (bd `test_C_libtooling-6n1s`).
   The loop is written out at K = 4 with the SAME two-block body shape per trip
   (the classical `if (k < lim)` is kept, so `-O1` still produces a second block
   per unrolled copy).  The claim the pair witnesses is MULTISET + per-trip
   commutation, never byte identity (owner ruling S3, $THIS/DECISIONS.md). */
#include "CQ.h"
int slice(int lim) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    {
        int d = (y >> 1);
        s += cq_measure(d & 1);
        if (1 < lim) s += cq_measure(d & 2);
    }
    {
        int d = (y >> 2);
        s += cq_measure(d & 1);
        if (2 < lim) s += cq_measure(d & 2);
    }
    {
        int d = (y >> 3);
        s += cq_measure(d & 1);
        if (3 < lim) s += cq_measure(d & 2);
    }
    {
        int d = (y >> 4);
        s += cq_measure(d & 1);
        if (4 < lim) s += cq_measure(d & 2);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
