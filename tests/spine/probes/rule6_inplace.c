/* tests/spine probe (CR rule 6, in-place update; owner 2026-11-25, cq-2h7xa): an add or xor of a dead value is one
 * core gate on the old rail (add_<W>, addc_<W>, copy_<W>, xorc_<W>); the old form stays where the old value is read
 * later, for y + y and for a select-merged update. */
int add_reg(int x0, double tx, int y0, double ty) {
  int x = x0, y = y0;
  cq_theta(&x, tx);
  cq_theta(&y, ty);
  x += y;
  return cq_measure(x) + cq_measure(y);
}
int xor_reg(int x0, double tx, int y0, double ty) {
  int x = x0, y = y0;
  cq_theta(&x, tx);
  cq_theta(&y, ty);
  x ^= y;
  return cq_measure(x) + cq_measure(y);
}
int add_lit(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  x += 7;
  return cq_measure(x);
}
int xor_lit(int x0, double tx, int c) {
  int x = x0;
  cq_theta(&x, tx);
  x ^= c;
  return cq_measure(x);
}
int chain(int x0, double tx, int a0, int b0, double ta) {
  int x = x0, a = a0, b = b0;
  cq_theta(&x, tx);
  cq_theta(&a, ta);
  cq_theta(&b, ta);
  x += a;
  x ^= b;
  x += 3;
  return cq_measure(x) + cq_measure(a) + cq_measure(b);
}
int cell;
int mem_add(int q0, double tq) {
  int q = q0;
  cq_theta(&q, tq);
  int *p = &cell;
  *p += q;
  return cq_measure(*p) + cq_measure(q);
}
char arr[4];
int mem_xor(int i, int b0, double tb) {
  char b = (char)b0;
  cq_theta(&b, tb);
  arr[i & 3] ^= b;
  return cq_measure(arr[i & 3]) + cq_measure(b);
}
int g1, g2, g3;
int arm(int x0, double tx, int c0, double tc) {
  int x = x0, c = c0;
  cq_theta(&x, tx);
  cq_theta(&c, tc);
  if (c > 5) {
    int t = x * 3;
    t += c;
    g1 = t;
  }
  return cq_measure(x) + cq_measure(c);
}
int arm_dead_everywhere(int x0, double tx, int c0, double tc) {
  int x = x0, c = c0;
  cq_theta(&x, tx);
  cq_theta(&c, tc);
  int t = x * 3;
  if (c > 5) {
    t ^= 12;
    g2 = t;
  }
  return cq_measure(x) + cq_measure(c);
}
int inverted(int x0, double tx, int y0, double ty) {
  int x = x0, y = y0;
  cq_theta(&x, tx);
  cq_theta(&y, ty);
  cq_invert_begin();
  int t = x * 3;
  t += y;
  g3 = t;
  cq_invert_end();
  return cq_measure(x) + cq_measure(y);
}
__attribute__((noinline)) int bump(int v) {
  int t = v * 5;
  t ^= 9;
  return cq_measure(t);
}
int callee_update(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  int r = bump(x);
  return r + cq_measure(x);
}
int both_dead(int s0, int t0, double th) {
  int s = s0, t = t0;
  cq_theta(&s, th);
  cq_theta(&t, th);
  int sum = s + t;
  return cq_measure(sum);
}
int read_later(int x0, double tx, int y0, double ty) {
  int x = x0, y = y0;
  cq_theta(&x, tx);
  cq_theta(&y, ty);
  int z = x + y;
  int w = x * 3;
  return cq_measure(z) + cq_measure(w) + cq_measure(y);
}
int doubled(int x0, double tx) {
  int x = x0;
  cq_theta(&x, tx);
  x = x + x;
  return cq_measure(x);
}
int merged(int x0, double tx, int c0, double tc) {
  int x = x0, c = c0;
  cq_theta(&x, tx);
  cq_theta(&c, tc);
  int y = c > 3 ? x + 5 : x;
  return cq_measure(y) + cq_measure(c);
}
