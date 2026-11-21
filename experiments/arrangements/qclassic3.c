/* (ii'') no quantum data in memory and no tape event in the module: the calls are ordinary host calls, unchanged.
 * The result is the exit status (no printf: a printf is an effect entry, an event, rule 16). */
#ifdef NATIVE
#define cq_theta(p, a) ((void)0)
#define cq_measure(x) (x)
#endif
long evaluate(void);
long sum(const long *p, long n);
long A[8] = {3, 1, 4, 1, 5, 9, 2, 6};
int main(int argc, char **argv) {
  (void)argv;
  long x = 7;
  cq_theta(&x, 0.0);
  long w = evaluate() * 3 + sum(A, 3 + (argc > 99));
  return (int)((cq_measure(x) + w) & 0xff);
}
