/* tests/chk-kept (CR rule 18, §6 item 1): rd loads from the bus and has a twin. Its call in the first arm is read by wr, which
 * writes memory, so that change overtakes it: the result is KEPT and no twin is called. Its call in the second arm keeps its twin. */
static const int T[4] = {5, 7, 11, 13};
int cell;
__attribute__((noinline)) int rd(int x) { return T[x & 3] + x; }
__attribute__((noinline)) int wr(int x) { cell = x; return x + 1; }
int q5(int x0, double t) {
  int x = x0;
  cq_theta(&x, t);
  int r;
  if (x > 3)
    r = wr(rd(x) * 3);
  else
    r = rd(x + 1) * 5;
  return cq_measure(r);
}
