/* tests/chk-kept (CR rule 18, §6 item 1, cq-usir7): rd loads from the bus and has a twin; the range fact of its quantum count at
 * each call puts a bound in the clone's name (§1.4: __cq_q_rd_1_b3). Its call in the first arm is read by wr, which writes
 * memory, so that change overtakes it: the result is KEPT and no twin is called. Its call in the second arm keeps its twin. */
static const int T[4] = {5, 7, 11, 13};
int cell;
__attribute__((noinline)) int rd(int n) { int s = 0; for (int i = 0; i < n; i++) s += T[i]; return s; }
__attribute__((noinline)) int wr(int x) { cell = x; return x + 1; }
int q6(int x0, double t) {
  int x = x0;
  cq_theta(&x, t);
  int r;
  if (x > 3)
    r = wr(rd(x & 3) * 3);
  else
    r = rd((x + 1) & 3) * 5;
  return cq_measure(r);
}
