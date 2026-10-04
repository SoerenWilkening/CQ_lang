/* slice_control_angle_select_ry_derived_base_ternary.c — the DERIVED-BASE FREEZE
   in the angle-select form, spelled as an explicit angle select
   (bd test_C_libtooling-fmt3, 2026-09-28). The if/else spelling
   (`slice_control_angle_select_ry_derived_base.c`) stopped being folded into an
   angle select when fmt3 put `nomerge` on `cq_theta_*`; this spelling is the one
   that still reaches `AngleSelectEmit`'s Ry stem, so the freeze property that
   slice was written to PROBE (the rotated out-of-place `mul` rail is never
   reverse-played or freed; exactly one `cqrt_free`, the flag's) stays probed on
   the select path. ITS GOLDEN IS THE PRE-fmt3 GOLDEN OF THE if/else slice, byte
   for byte (moved, not regenerated — measured), including the two expected M-A
   `live derived record` WARNINGS (`DS_Warning`, opt exits 0). STRICT stage 2b.

   `noinline` is there to reproduce the MODULE, not only the trace: `-O1` did not
   inline the folded if/else `slice` into `main` (the inliner ran while the body
   still had its two arm blocks), but it DOES inline this smaller body, which
   would lower a second copy in `main` — the same trace, twice the warnings. With
   the attribute the stage-1 function bodies equal the pre-fmt3 fold's (measured). */
__attribute__((noinline)) int slice(void) {
    int q = 3;
    int p = 7;
    cq_theta(&q, 0.5);
    cq_theta(&p, 0.25);
    int r = p * 5;
    cq_theta(&r, (q == 5) ? 0.9 : 0.3);
    int s = r + 1;
    return cq_measure(q) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
