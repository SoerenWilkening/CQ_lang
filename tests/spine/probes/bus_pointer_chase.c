/* tests/spine probe (CR rules 5, 21): a pointer loaded from the bus is the address rail of the next access; the copy is
 * overtaken by the store it addresses. A classical pointer stored as an i64 seed. */
int A = 1, B = 2;
int *slot[2];
int pointer_chase(unsigned k0, double tk, int v) {
  unsigned k = k0;
  cq_theta(&k, tk);
  slot[0] = &A;
  slot[1] = &B;
  int *p = slot[k & 1];
  *p = v;
  return cq_measure(A + B);
}
