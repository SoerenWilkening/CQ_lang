/* Rulings Q2 (owner 2026-11-11), cq-auqs3: the callee's object holds no rail, a neighbouring object does (a local
 * the lowered side keeps as a QUANTUM cell on the stack; a heap block next to the callee's block). Compared
 * (run_q2.py): the C program's real object decides, and a lowering returning c*3 FAILs. */
void sink(const void *p);
void *malloc(unsigned long n);
int q2s(unsigned c, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  volatile unsigned q = 1;
  char a[4] = "abc";
  if (c) q = x;
  sink(a);
  return (int)c * 2;
}
int q2h(unsigned c, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  unsigned *q = malloc(4);
  char *a = malloc(4);
  *q = 1, a[0] = 'a', a[1] = 0;
  if (c) *q = x;
  sink(a);
  return (int)c * 2;
}
