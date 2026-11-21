/* Consequence tests (owner ruling 2026-11-20, refined): library functions whose inputs can arrive through memory. */
long G[4] = {1, 2, 3, 4};
/* No argument: reads global state. */
long evaluate(void) { return G[0] + 2 * G[1] + 3 * G[2] + 4 * G[3]; }
/* A classical-bound loop over the pointee. */
long sum(const long *p, long n) {
  long s = 0;
  for (long i = 0; i < n; i++)
    s += p[i];
  return s;
}
