/* bd g7ip end-to-end: by-ref out-param on a VISIBLE user function. The helper is
   forced `noinline` so the call survives clang -O1 as `call void @mysplit(i32,
   ptr)` with a visible body (a small helper would otherwise inline + SROA away).
   ByRefInline PROVES the pure single-store body + the tight out-cell shape and
   INLINES the producer's value expression into the caller (Architecture A, owner
   decision 2026-07-01), RAUWing the read-back load — byte-identical to the case
   where clang inlines the helper. The trace is the theta -> add_hl -> measure
   stream, proving the by-ref result is a genuine quantum handle. */
__attribute__((noinline)) static void mysplit(int v, int *out) { *out = v + 7; }

int slice(void) {
    int x = cq_theta(0, 0.5);
    int e;
    mysplit(x, &e);
    return cq_measure(e);
}

int main(void) { (void) slice(); return 0; }
