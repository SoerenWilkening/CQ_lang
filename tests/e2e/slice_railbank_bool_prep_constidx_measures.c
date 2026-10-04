/* slice_railbank_bool_prep_constidx_measures.c — the CONSTANT-INDEX read
   spelling of the rail bank.  bd `xdu2` / L-1a W1, second half, 2026-09-15.

   The cells are read back as `b0[0]`, `b0[1]`, `b0[2]` rather than through a
   loop.  For a `_Bool` bank `-O1` keeps those as canonical cell addresses (the
   cell type IS `i8`, so the byte-offset gep it emits for an `int` bank coincides
   with the cell gep here), so the carve admits them and the type rewrite retypes
   BOTH gep spellings — the array-decay form in the write loop and the flat
   element form `getelementptr inbounds i8, ptr %b, i64 1` here.  A rewrite that
   handled only the first would leave a gep striding by ONE BYTE over an `i32`
   bank: verify-clean, and reading the wrong cell.

   ⚠ The `int`-cell spelling of THIS program declines
   `cq rail bank: array mixes a rail cell access with an unrecognized one`, which
   is why the width axis lives in `slice_railbank_int_cells_measureloop.c` with a
   measure LOOP.  The two slices are not redundant: this one is about the ADDRESS
   form, that one about the CELL WIDTH. */
#include "CQ.h"

int slice(void) {
    bool b0[3];
    for (int i = 0; i < 3; ++i) cq_theta(&b0[i], 0.5);
    return (int) cq_measure(b0[0]) + (int) cq_measure(b0[1])
         + (int) cq_measure(b0[2]);
}

int main(void) { (void) slice(); return 0; }
