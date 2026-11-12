/* Rulings Q2 (owner 2026-11-11), cq-auqs3 (review R1 t4/q2g.c): sink's object is buf, 4 bytes, holding no rail; the
 * global q placed after it holds one. The input is compared (run_q2.py): the lowered run's record (the bus knows no
 * global's extent) never widens the C program's decision, and a lowering returning c*3 FAILs. */
void sink(const void *p);
char buf[4] = "abc";
unsigned q = 1;
int q2g(unsigned c, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  if (c) q = x;
  sink(buf);
  return (int)c * 2;
}
