/* slice_z0re_runtime_seed_prep_literal.c — the INDEPENDENT witness for
   slice_z0re_runtime_seed_prep.c (bd test_C_libtooling-z0re, Rule-13 r1B F-r1B-6).

   The z0re `*-twin-identical` gates compare two spellings that BOTH run the new
   runtime-seed path (side door vs hand-inlined twin), so they witness CONSISTENCY,
   not correctness: a change that corrupted the runtime-seed stream the same way in
   both spellings would keep them green. This slice is the same program with the
   seed written as the LITERAL the runtime value takes under the harness
   (`m = argc + 4 = 5`, so `t = m + 1 = 6`). It goes through F1's LITERAL path — the
   drbq Inc-4 state prep, Rule-13-cleared code that predates z0re and produced this
   golden on the frozen ORACLE (main 9a230646) byte for byte (measured,
   TRACK_Z0RE.md §R2) up to one line: the oracle, like every build before bd 5c5b,
   also emitted a dirty `cqrt_free(h0)` after reverse-playing the dead `m` rail
   back to its birth value 5 (libcqops vmz9); that line is gone here. And
   `e2e-z0re-runtime-seed-prep-literal-identical` pins the runtime-seed golden
   BYTE-IDENTICAL to it. `m` and `n` stay runtime so every other gate is the same
   program. */
__attribute__((noinline)) int slice(int m, int n) {
    int q = cq_theta(m, 0.5);
    (void) q;
    int t = 6;
    int q2 = cq_theta(n, 0.3);
    int r = t;
    if (q2 > 3) r = cq_theta(t, 0.2);
    return cq_measure(r) + cq_measure(q2);
}

int main(int argc, char **argv) {
    (void) argv;
    (void) slice(argc + 4, argc + 6);
    return 0;
}
