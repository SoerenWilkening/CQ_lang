/* slice_z0re_angle_select_runtime_base_exact_inplace.c — the INDEPENDENT witness for
   slice_z0re_angle_select_runtime_base_exact.c (bd test_C_libtooling-z0re, Rule-13
   r1B F-r1B-6).

   The same unitary on the fresh rail, written through code that predates z0re: an
   UNCONDITIONAL prep of the literal 6 (= the runtime `m + 1` under the harness) by
   Ry(.25), then an in-place controlled-Ry ARM of .5 on it (the drbq Inc-1 path):

     int r = 6; cq_theta(&r, .25); if (q > 3) cq_theta(&r, .5);

   f = 0: Ry(.25)|6⟩; f = 1: Ry(.25 + .5) = Ry(.75)|6⟩ — the runtime-base angle
   select's by-difference stream exactly (.75 − .25 = .5 is exact in binary64). This
   golden is produced byte for byte by the frozen ORACLE (main 9a230646) — measured,
   TRACK_Z0RE.md §R2. Since bd dm7f.6 the angle select emits the X-bracket
   stream (`mint; alloc(6); cRy(.75); x; cRy(.25); x`), so the two goldens are the
   same unitary but no longer the same bytes, and the byte gate is retired (see
   tests/e2e/CMakeLists.txt: the if/else spelling that would match declines
   `if/else state prep allocates two rails`, bd gjn2). */
__attribute__((noinline)) int slice(int m) {
    int q = m; cq_theta(&q, 0.5);
    int r = 6; cq_theta(&r, 0.25);
    if (q > 3) cq_theta(&r, 0.5);
    return cq_measure(r) + cq_measure(q);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
