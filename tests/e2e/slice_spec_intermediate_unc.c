/* slice_spec_intermediate_unc.c — bd test_C_libtooling-p3kd.13 e2e golden.
 *
 * A lifted call's result (`@__cq_q_h_1`, the clone of the noinline helper `h`)
 * consumed by another tainted op is uncomputed by its Bennett twin
 * `@__cq_q_h_1_unc` (`out ^= 3x + 1`), LIFO, and freed — as a template
 * intermediate is. Before the fix every one of these clone rails stood allocated
 * and entangled with q (stage 2b: "template rail mint(s) ... left dirty"), and in
 * dephase() the chained cq_theta(&q, .3) rotated q under that live record.
 *
 * The golden pins, per function: the twin's recompute / XOR-copy / uncompute
 * gates after the clone rail's last reader, then `cqrt_free` of that rail —
 *   consumer: a template consumer; dephase: the discharge BEFORE the second Ry;
 *   fanout: two consumers, one twin; nested: h(h(q)) — outer twin first;
 *   mixed: h(h(q) * 5) — mul_unc, then the inner twin; dead_rotated: a dead,
 *   rotated clone result reverse-played and freed; qram_index: a QROM index.
 * Stage 2b (run_slice.sh) checks every free pairs with a rail returned to |0>.
 * LINK PROVES the synthesized twin resolves (internal, fastcc like the clone).
 */
__attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};

__attribute__((noinline)) int consumer(int m) {
  int q = m & 7;
  cq_theta(&q, .5);
  int s = h(q) * 5;
  return cq_measure(s);
}
__attribute__((noinline)) int dephase(int m) {
  int q = m & 7;
  cq_theta(&q, .5);
  int s = h(q) * 5;
  int r = cq_measure(s);
  cq_theta(&q, .3);
  return r + cq_measure(q);
}
__attribute__((noinline)) int fanout(int m) {
  int q = m & 7;
  cq_theta(&q, .5);
  int p = h(q);
  int s1 = p * 5;
  int s2 = p ^ 3;
  return cq_measure(s1) + cq_measure(s2);
}
__attribute__((noinline)) int nested(int m) {
  int q = m & 7;
  cq_theta(&q, .5);
  int s = h(h(q)) * 5;
  return cq_measure(s);
}
__attribute__((noinline)) int mixed(int m) {
  int q = m & 7;
  cq_theta(&q, .5);
  int s = h(h(q) * 5);
  return cq_measure(s);
}
__attribute__((noinline)) int dead_rotated(int m) {
  int q = m & 7;
  cq_theta(&q, .5);
  int r = h(q);
  cq_theta(&r, .3);
  cq_theta(&q, .7);
  return cq_measure(q);
}
__attribute__((noinline)) int qram_index(int m) {
  int q = m & 7;
  cq_theta(&q, .5);
  int v = tbl[h(q) & 7];
  return cq_measure(v);
}
int main(int argc, char **argv) {
  (void)argv;
  return consumer(argc) + dephase(argc) + fanout(argc) + nested(argc) + mixed(argc) +
         dead_rotated(argc) + qram_index(argc);
}
