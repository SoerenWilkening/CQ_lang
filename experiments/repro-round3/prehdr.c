/* cq-03rdt (SQLite sqlite3Pragma): a loop headed by a case of a quantum switch (its preheader is the switch's block), the
   scrutinee loaded at an address a template made there. The preheader does not dominate the loop's exit, so its template
   results are resolved on the loop's exit path (resolvePreheader); the address was taken although the load it addresses
   is the switch's atom, read by the flags of the other cases' blocks after the loop: resolveAt found it read by a pending
   item. */
struct P { long a; char k; } tab[2] = {{1, 3}, {2, 5}};
int acc, other;
__attribute__((noinline)) void step(int *a, int i) { *a = *a * 3 + i; }
int prehdr(int idx, int n, char k0) {
  tab[0].k = k0;
  cq_theta(&idx, 0.5);
  struct P *p = &tab[idx & 1];
  int i = 0;
  if (n == 9)
    other = 1;
  else
  switch (p->k) {
  case 3:
    do {
      step(&acc, i);
      i++;
    } while (i < n && i < 3);
    break;
  case 5:
    other = 9;
    break;
  case 7:
    other = 4;
    break;
  }
  return cq_measure(acc + other);
}
