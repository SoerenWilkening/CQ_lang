/* slice_z0re_angle_select_runtime_base_exact_inplace.c — the INDEPENDENT witness for
   slice_z0re_angle_select_runtime_base_exact.c (bd test_C_libtooling-z0re, Rule-13
   r1B F-r1B-6).

   The same unitary on the fresh rail, written through code that predates z0re: an
   UNCONDITIONAL prep of the literal 6 (= the runtime `m + 1` under the harness) by
   Ry(.25), then an in-place controlled-Ry ARM of .5 on it (the drbq Inc-1 path):

     int r = cq_theta(6, .25); if (q > 3) r = cq_theta(r, .5);

   f = 0: Ry(.25)|6⟩; f = 1: Ry(.25 + .5) = Ry(.75)|6⟩ — the runtime-base angle
   select's by-difference stream exactly (.75 − .25 = .5 is exact in binary64). This
   golden is produced byte for byte by the frozen ORACLE (main 9a230646) — measured,
   TRACK_Z0RE.md §R2 — so `e2e-z0re-angle-select-runtime-base-exact-inplace-identical`
   compares the z0re stream against cleared code, not against itself. */
__attribute__((noinline)) int slice(int m) {
    int q = cq_theta(m, 0.5);
    int r = cq_theta(6, 0.25);
    if (q > 3) r = cq_theta(r, 0.5);
    return cq_measure(r) + cq_measure(q);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4);
    return 0;
}
