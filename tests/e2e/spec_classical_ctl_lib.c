/* spec_classical_ctl_lib.c — the CLASSICAL library TU for the bd p3kd.7.2 golden.
   Compiles WITHOUT CQ.h. Both helpers branch on a parameter the caller passes
   CLASSICAL while another parameter is quantum (the CQ/QC math.h mixture shape):

     clampsub: `lim < 0 ? -lim : (x > lim ? x - lim : 0)`: a quantum branch nested
               inside a classical one, sharing its merge (fdim/scalbn).
     pick:     a switch on the classical `mode` choosing between three quantum
               computations of `x`. */

/* bd p3kd.7.8 (2026-10-07): the lifted clone now runs MAIN'S stage list, so its
   tainted select lowers through main's 4.4 merge (CondTreeEmit/SelectMergeEmit)
   and the Bennett wrap reverses it mechanically. Two trace changes, golden
   regenerated deliberately: the merge's trailing ¬flag `cqrt_x` (nothing reads
   the flag after the second copy) and its mirror at the start of the reverse are
   elided as a pair; where an arm is a constant zero, its materialized |0> rail
   is copied (a no-op) and now freed after the reverse. Every other gate is
   unchanged. The descriptions above are
   the pre-p3kd.7.8 stream. */

int clampsub(int x, int lim) {
    if (lim < 0)
        return -lim;
    return x > lim ? x - lim : 0;
}

int pick(int x, int mode) {
    switch (mode) {
    case 0:
        return x + 1;
    case 1:
        return x * 2;
    default:
        return x - 3;
    }
}
