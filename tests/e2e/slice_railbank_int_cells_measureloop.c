/* slice_railbank_int_cells_measureloop.c — THE WIDTH AXIS of the rail bank.
   bd `xdu2` / L-1a Increment W1, the SECOND HALF (Track B, session 2026-09-15).

   The same program as `slice_railbank_bool_prep_measureloop.c` with `int` cells.

   ⚠ WHY THE AXIS IS NOT COSMETIC.  An `int` cell's C storage type IS the rail
   type (`abi=i32`), so there is NO storage cast anywhere — neither the write's
   `zext i1 -> i8` nor the read's `trunc i8 -> i1` — and the type rewrite takes
   its "the stored value is already the handle" arm instead of its cast arm.  The
   `_Bool` slice exercises the other arm.  A rewrite that only ever saw one of
   them would pass half the layer.

   ⚠ AND THE MEASURES MUST BE IN A LOOP.  MEASURED: at `-O1` clang emits the
   CONSTANT-INDEX reads of a `[3 x i32]` array as BYTE-OFFSET geps
   (`getelementptr inbounds i8, ptr %b, i64 4`), which the carve's cell-type
   agreement refuses — `cq rail bank: array mixes a rail cell access with an
   unrecognized one`.  The `_Bool` bank escapes that only because its cell type
   IS `i8`.  Whether the byte-offset gep is worth admitting is a separate,
   costed question that this increment did NOT widen.

   ⚠ STAGE 2B COUNTS `cqrt_alloc` SITES, so the ROLLED per-trip allocation reads
   as ONE rail PER SITE.  MEASURED: `2 rail mint(s) of which 2 left allocated,
   0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven` — two sites
   because `-O1` keeps both `@slice` and its inlined copy in `@main`. */
#include "CQ.h"

int slice(void) {
    int b0[3];
    int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}

int main(void) { (void) slice(); return 0; }
