/* d5i — the WRITE-side twin of d5g.  The rail is `int` (i32) and the CELL is
   `char` (i8), so `clang -O1` puts a real `trunc i32 -> i8` in front of the bank
   store.  That trunc is a GATE the register spelling emits
   (`cq_template_trunc_i32_to_i8`, measured in `d5j_store_side_scalar.c`), not
   the compiler's storage bridge — so the rail-width derivation must not read i32
   through it and the type rewrite must not erase it.
   ⚠ The seed comes from `argc`: an earlier spelling wrote `int q = cq_theta(q,
   0.5);` inside the loop, which is UB `clang -O1` collapses to a bare
   `unreachable` — the whole function gone, on the ORACLE as well.  A probe whose
   stage-1 module is `unreachable` measures NOTHING. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void) argv;
    char b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) { int q = cq_theta(argc, 0.5); b0[i] = (char) q; }
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
