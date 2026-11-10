/* tests/chk-kept (CR rule 22 with rule 14's chain, §0 K2, §6 item 1, cq-cwl9g): q9's memset and memcpy of a rail length n
 * with a bound B = 8191 above K2 = 4096, inside an `if` on a quantum condition. Under the arm's predicate c each keeps
 * (n > K2) & c, written into a fresh i1 and live at exit, the raw compare undone. Half the inputs take the arm, and half of
 * those have n > K2; the program reads only byte 0 of each buffer, which it writes itself in both arms, and the buffers
 * are locals, so nothing compared reads past the cutoff. The angle is a nonzero literal, so the register is in no known
 * basis state. */
__attribute__((noinline)) int rd(const unsigned char *p) { return p[0]; }
int q10(int x0) {
  int x = x0;
  cq_theta(&x, 0.5);
  unsigned n = ((unsigned)x & 0x1fff) | 1;
  unsigned char a[8192], b[8192];
  a[0] = 3;
  b[0] = 5;
  if ((unsigned)x & 0x4000u) {
    __builtin_memset(a, 7, n);
    a[0] = (unsigned char)x;
    __builtin_memcpy(b, a, n);
  }
  return cq_measure(rd(a) + rd(b));
}
