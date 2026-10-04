/* spec_scrub_dangling_key_caller.c — bd test_C_libtooling-8e5r e2e pin: a
   DANGLING `taint.Tainted` key aliased by a Phase-6 clone's CLASSICAL
   instruction (the lit twin is ir-pass/test/spec_scrub_dangling_key_clone_classical_mul.ll).

   THE DEFECT (pre-existing, from plain C). `lowerShadowMemory` erased the shadow
   array's tainted stores/load/GEPs without removing them from `taint.Tainted`;
   `specialize()` then allocated the clone of `k1` and its classical
   `mul nsw i32 %0, 7` landed on a freed store's address, so the module-level
   `lowerOps` lowered it as a QUANTUM op. The unfixed binary's trace (ctest
   entry below runs with `CQ_OPT_DEBUG_ALLOC=lifo`, which makes that aliasing
   deterministic — 10/10 wrong on oracle `def1b088` + the test allocator):
       cq_template_mul_i32_hl(h7, 5) -> h10     ; h7 is the (q2+1) rail, ALREADY FREED
       cq_template_add_i32_hl(h1, 10) -> h11    ; a handle id used as the literal
   `opt` exit 0, verify-clean, stage 2b `3 verified, 0 violation(s)` — only the
   golden sees it.

   TRACE CONTRACT (analytically audited). h1 = |5> rotated by Ry(0.5) (q), h2 =
   |3> rotated by Ry(0.25) (q2). The shadow array becomes QRAM a0: two stores at
   (q2&7) and (q&7) — index rails h3, h5, each discharged right after its own
   store (and_unc against the unmoved source, then free; the stores are never
   reversed, bd r2j3.1 — before that fix both stood allocated to the end), value
   rails h4=|7>, h6=|9> — and one load at ((q2+1)&7): h7 = q2+1, h8 = h7&7, the
   load h9, then the index chain uncomputed LIFO (and_unc, free h8; add_unc,
   free h7 — both proven |0>), and h9 measured. Then the two calls of the ONE
   clone `k1(classical, quantum)`: k1(5, q) = q + 35 → `add_hl(h1, 35)` into h10,
   copied out to a fresh |0> rail h11, h10 uncomputed and freed; k1(3, q2) =
   q2 + 21 → `add_hl(h2, 21)`, h12 → h13, same discipline. 35 = 5*7 and 21 = 3*7
   are the CLASSICAL products as literals — exactly the operands the unfixed
   binary replaced by a handle. Then measure h11, h13, h2, h1. */
int k1(int a, int b);

volatile int M = 5, N = 3;

int main(void) {
  int m = M, n = N;
  int acc = 0;
  int q = m; cq_theta(&q, .5);
  int q2 = n; cq_theta(&q2, .25);
  int arr[8] = {0};
  arr[q2 & 7] = 7;
  arr[q & 7] = 9;
  int r1 = arr[(q2 + 1) & 7];
  acc += cq_measure(r1);
  int u = k1(m, q);
  int v = k1(n, q2);
  return (acc + cq_measure(u) + cq_measure(v) + cq_measure(q2) + cq_measure(q)) & 0;
}
