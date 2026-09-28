/* slice_control_angle_select_ry_ternary.c — ANGLE-SELECT BY DIFFERENCE, Ry stem,
   at the LINK layer, spelled the way `clang -O1` still hands it to the pass
   (bd test_C_libtooling-fmt3, 2026-09-28; the Ry stem is drbq Increment 2b,
   control-in-place-PRD §12.3).

   WHY THIS FILE EXISTS. Until fmt3 the if/else spelling
   `if (q == 5) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);`
   (`slice_control_angle_select_ry.c`) reached the pass as ONE `cq_theta` with a
   tainted-condition `select` on the ANGLE, because SimplifyCFG merged the two
   arm calls. fmt3 put `nomerge` on every `cq_theta_*` declaration (owner ruling
   2026-09-28 — the merge could erase a branch and hand the pass a DIFFERENT,
   legitimate-looking program), so that if/else now stays an if/else and lowers
   through the in-place Ry arm instead. THIS spelling writes the select itself —
   the angle is a C conditional expression — so the module is the one the fold
   used to produce: ONE call, `select i1 %c, double 0.9, double 0.3` on arg-1.
   It is now the C route into `AngleSelectEmit`'s Ry stem.

   ITS GOLDEN IS THE PRE-fmt3 GOLDEN OF THE if/else SLICE, BYTE FOR BYTE (moved,
   not regenerated — measured), and `e2e-angle-select-ry-twin-identical` now
   compares THIS golden with the unchanged by-difference twin
   (`slice_control_angle_select_ry_twin.c`). Read the if/else slice's header for
   the ONE-ULP note on `fl(0.9) - fl(0.3)`; it applies here unchanged.
   STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    r = cq_theta(r, (q == 5) ? 0.9 : 0.3);   /* the angle select, written out */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
