/* slice_railwindow_rewalk_fixed.c — a cell walk RE-EXECUTED through an
   irreducible goto cycle rotates the SAME rail twice (Ry·Ry), never a fresh one.
   bd test_C_libtooling-01po.19.21 (review F3, 2026-10-15); the program is
   railbank_dynamic_matrix.c CASE 25 with `side` defined in this TU.

   WHAT THIS GOLDEN FORBIDS. Before 01po.19 S4 the rail-bank promoter forwarded a
   fresh |0> seed to the second walk: Ry on a NEW rail where the source means
   Ry·Ry on one (the HEAD-oracle miscompile recorded in the matrix source, then
   fenced as `the cell walk is re-executed by an enclosing loop`). Since S4
   (a3fbac74) the rail window holds each cell's handle in memory. Each walk loads
   the rail, rotates it in place and stores it back, so the second walk rotates
   the rails the first one did. With no argv, e = argc + 1 = 2 is even: the
   function enters at H, walks, jumps to A (side), walks again, and leaves. The
   golden is therefore 4 mints, Ry(0.5) on h0..h3, Ry(0.5) on h0..h3 AGAIN, and
   4 measurements. That is 4 rails, not 8: a fresh-seed regression would show as
   new mints before the second pass.
   ⚠ `noinline` keeps the function outside `main` (FreePoint treats `main`'s
   handles as Escaped); `side` writes a volatile so -O1 keeps the call and the
   cycle. */
#include "CQ.h"

static volatile int sink;
__attribute__((noinline)) static void side(int k) { sink = k; }

__attribute__((noinline)) static int slice(int e) {
    int b[4] = {0};
    int k = 0;
    if (e & 1) goto A;
H: ;
    for (int i = 0; i < 4; ++i) cq_theta(&b[i], 0.5);
    if (k++ < 1) goto A; else goto R;
A:
    side(k);
    goto H;
R: ;
    int s = 0;
    for (int j = 0; j < 4; ++j) s += cq_measure(b[j]);
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 1); }
