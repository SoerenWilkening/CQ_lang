/* tests/chk-kept (CR rule 14, §6 item 1, cq-1leyz): steps is a quantum-exit K-loop with no bound (B unknown, so B > K) and
 * its a_K is kept. It stores to memory, so its call stays in the arm, which the C program does not take on most inputs: the
 * circuit runs the _ctl clone under the arm flag, and the clone's a_K stays live at exit reading 0 where the C program
 * never reached the loop. The angle is a nonzero literal, so the register is in no known basis state (an Ry(0) would leave
 * every rail known, and the leak rule never reads a known rail). */
int last;
__attribute__((noinline)) int steps(unsigned x) {
  int n = 0;
  while (x > 3) {
    x = x - (x >> 2) - 1;
    n++;
  }
  last = n;
  return n;
}
int q7(int x0) {
  int x = x0;
  cq_theta(&x, 0.5);
  int r = 1;
  if ((unsigned)x < 64)
    r = steps((unsigned)x);
  return cq_measure(r);
}
