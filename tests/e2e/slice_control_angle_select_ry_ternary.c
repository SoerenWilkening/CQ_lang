/* slice_control_angle_select_ry_ternary.c — ANGLE-SELECT BY DIFFERENCE, Ry stem,
   at the LINK layer, spelled the way `clang -O1` still hands it to the pass
   (bd test_C_libtooling-fmt3, 2026-09-28; the Ry stem is drbq Increment 2b,
   control-in-place-PRD §12.3).

   WHY THIS FILE EXISTS. Until fmt3 the if/else spelling
   `if (q == 5) cq_theta(&r, 0.9); else cq_theta(&r, 0.3);`
   (`slice_control_angle_select_ry.c`) reached the pass as ONE `cq_theta` with a
   tainted-condition `select` on the ANGLE, because SimplifyCFG merged the two
   arm calls. fmt3 put `nomerge` on every `cq_theta_*` declaration (owner ruling
   2026-09-28 — the merge could erase a branch and hand the pass a DIFFERENT,
   legitimate-looking program), so that if/else now stays an if/else and lowers
   through the in-place Ry arm instead. THIS spelling writes the select itself —
   the angle is a C conditional expression — so the module is the one the fold
   used to produce: ONE call, `select i1 %c, double 0.9, double 0.3` on arg-1.
   It is now the C route into `AngleSelectEmit`'s Ry stem.

   GOLDEN REGENERATED for bd dm7f.6 (owner ruling 2026-10-13, X-bracket Ry stem):
   `ry(r, 0.3)` plus one controlled gate at the folded `fl(0.9 - 0.3)`
   (`0x1.3333333333334p-1`, one ulp above 0.6) became `cRy(f, r, 0.9); x(f);
   cRy(f, r, 0.3); x(f)`, every angle the source's own double. It is now
   byte-identical to the if/else slice's golden
   (`slice_control_angle_select_ry.c`), which `e2e-angle-select-ry-twin-identical`
   asserts. The by-difference twin `slice_control_angle_select_ry_twin.c` was the
   oracle until then; it shared the rounding it was meant to witness (bd memory
   `by-difference-twin-blind-to-arithmetic`). STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    cq_theta(&r, (q == 5) ? 0.9 : 0.3);      /* the angle select, written out */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
