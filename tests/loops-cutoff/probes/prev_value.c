/* tests/loops-cutoff probe (CR rule 14, cq-pntr): the "previous value" pattern `p = x; x = f(x)` in a K-loop, both read
 * after the loop: p's exit value is x's header phi of the exit trip, so every exit value is read before any is rebound.
 * Regenerate prev_value.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h prev_value.c -o prev_value.O1.ll */
int prev_value(int x0, double tx, int a, int b) {
  int x = x0, p = 0, s = 0;
  cq_theta(&x, tx);
  do {
    s += p;
    p = x;
    x = x * a + b;
  } while (x > 7);
  return cq_measure(p) * 1000 + cq_measure(x) * 10 + cq_measure(s);
}
