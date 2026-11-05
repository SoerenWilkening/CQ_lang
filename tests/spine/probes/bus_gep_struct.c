/* tests/spine probe (CR rule 20 Address arithmetic): a tainted index, a classical run-time index, a struct field in one
 * getelementptr: the untainted part is one classical i64. */
struct S { int a; int b[3]; } tab[4] = {{1, {2, 3, 4}}, {5, {6, 7, 8}}, {9, {10, 11, 12}}, {13, {14, 15, 16}}};
int gep_struct(unsigned k0, double tk, unsigned j) {
  unsigned k = k0;
  cq_theta(&k, tk);
  return cq_measure(tab[k & 3].b[j & 1]);
}
