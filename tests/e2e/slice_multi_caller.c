/* slice_multi_caller.c — the CQ translation unit for the multi-file harness
   smoke (Phase 6 DD-6, test_C_libtooling-mvna.3). Its quantum core matches
   slice_theta_add_measure (theta -> add_hl -> measure); it ADDITIONALLY calls a
   classical library helper defined in slice_multi_lib.c, so the harness's
   Stage 1b (per-lib clang, NO -include CQ.h) and the llvm-link of >1 module are
   exercised by ctest.

   The helper is called with a CLASSICAL argument and its result is used only
   post-measure (z + lib_bias()), so NO taint escapes into it — call-graph
   specialization is a later Phase 6 increment (the .7 golden); this slice is a
   pure BUILD-HARNESS guard that is independent of the specializer. lib_bias()
   returns 0, so the trace is identical to the single-TU theta-add-measure
   golden — any divergence means a harness regression, not a lowering change. */
int lib_bias(void);

int slice(void) {
    int x = 3;
    x = cq_theta(x, 0.5);
    int y = x + 1;
    int z = cq_measure(y);
    return z + lib_bias();
}

/* bd test_C_libtooling-vsfp round 2: `main` RETURNS `slice()` (0 under the trace
   runtime: `measure` returns 0 and `lib_bias` returns 0). It used to discard it, which
   left `lib_bias()` a DEAD call once llvm-link made its body (`return 0`) visible — and
   round 2's dead-argument drop deletes a dead call to a side-effect-free definition, as
   `-O1` would with both TUs visible. This smoke's point is that the caller really CALLS
   the classical helper across the TU boundary, so its result is kept live. */
int main(void) { return slice(); }
