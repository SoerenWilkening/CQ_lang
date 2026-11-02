/* tests/calls probe (cq-4e6m; CR rule 23 ruling 2026-11-02): the mode of round.dynamic ops is the mode at the root
 * of the LOWERED call chain. ch_split (no fenv state) calls split, which writes a caller cell from third (both
 * -frounding-math, fenv_chain_default_lib.c); `other` holds the fenv state and calls third too, but is not on the
 * chain: third and split are plain-template clones with no mode and no flags (musl sin's __rem_pio2 calling
 * __rem_pio2_large calling scalbn, which fma also calls).
 * Regenerate: clang -O1 fenv_chain_default.c; clang -O1 -frounding-math fenv_chain_default_lib.c;
 * clang -O1 fenv_chain_default_other.c; llvm-link -S all three -o fenv_chain_default.O1.ll */
#include "CQ.h"
void split(double x, double *y);
double ch_split(double a) { double x = a; cq_theta(&x, 0.5); double y[2]; split(x, y); return cq_measure(y[0] + y[1]); }
