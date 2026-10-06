/* spec_classical_ctl_lib.c — the CLASSICAL library TU for the bd p3kd.7.2 golden.
   Compiles WITHOUT CQ.h. Both helpers branch on a parameter the caller passes
   CLASSICAL while another parameter is quantum (the CQ/QC math.h mixture shape):

     clampsub: `lim < 0 ? -lim : (x > lim ? x - lim : 0)`: a quantum branch nested
               inside a classical one, sharing its merge (fdim/scalbn).
     pick:     a switch on the classical `mode` choosing between three quantum
               computations of `x`. */
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
