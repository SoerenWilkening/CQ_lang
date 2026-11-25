/* tests/spine probe (CR rules 14, 19; cq-tyj2l): an entry returns the pointer a quantum-exit loop leaves (a walk back
 * over a buffer holding a quantum store). The value read at the return is the exit value, quantum, returned as its i32
 * handle, though the loop's pointer phi is classical inside the loop. */
char buf[6] = "abcde";
char *basename_q(unsigned k0, double tk, unsigned n) {
  unsigned k = k0;
  cq_theta(&k, tk);
  buf[k & 3] = '/';
  char *b = buf + (n & 1), *p = b + 4;
  while (p > b && p[-1] != '/')
    p--;
  return p;
}
