/* tests/loops-classical fatal probe (cq-vqid): x*x+i is deferred to the reverse loop (the classical
 * branch on c == i splits the trip, so g's flag is read in another segment), then x is rotated
 * again in the same trip. The reverse would undo x*x against the rotated x: cq::unimplemented. */
void f_undoneread(int n, int c, double th) {
  for (int i = 0; i < n; i++) {
    int x = 0; cq_theta(&x, th);
    int g = x * x + i;
    if (c == i) cq_phi(0.2);
    if (g == 3) cq_phi(0.3);
    cq_theta(&x, th);
  }
}
