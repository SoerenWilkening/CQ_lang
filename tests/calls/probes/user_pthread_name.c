/* tests/calls probe, cq-o1swj (CR 778-779, rule 16: "recognised by name and signature"): a program's own function whose
   name starts with pthread_ is no POSIX <pthread.h> interface (a closed list, not a prefix): lifted, lowered, compared. */
__attribute__((noinline)) static int pthread_sum(int a, int b) { return a * 3 + b; }
int p7(int x0, double t) {
  int x = x0;
  cq_theta(&x, t);
  int y = x & 15;
  return cq_measure(pthread_sum(y, 1));
}
