/* tests/calls probe (cq-57ju; CR rule 23 ruling 2026-11-02): a caller with the fenv state sets the rounding mode
 * and calls a -frounding-math body of round.dynamic ops (no strict op, fenv_reached_mode_lib.c): the mode reaches the ops
 * (the clone carries the environment), against the C program.
 * Regenerate: clang -O1 fenv_reached_mode.c; clang -O1 -frounding-math fenv_reached_mode_lib.c; llvm-link -S both -o fenv_reached_mode.O1.ll */
#include "CQ.h"
#include <fenv.h>
double third(double x);
#pragma STDC FENV_ACCESS ON
double md_plain(double a) { double x = a; cq_theta(&x, 0.5); return cq_measure(third(x)); }
double md_up(double a) { double x = a; cq_theta(&x, 0.5); fesetround(FE_UPWARD); double y = third(x); fesetround(FE_TONEAREST); return cq_measure(y); }
