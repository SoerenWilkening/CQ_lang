/* tests/chk-kept (CR rule 22, §0 K2, §6 item 1, cq-dl7da): a memset and a memcpy whose length n is a rail with a bound
 * B = 8191 above K2 = 4096 copy at most K2 bytes, and each keeps its overflow predicate n > K2. No predicate is in scope,
 * so each is rule 22's unpredicated n > K2, live at exit. Half the inputs have n > K2; the program reads only byte 0,
 * which it writes itself before the copy and every n >= 1 copies, and the buffers are locals, so nothing compared reads past the cutoff. The angle is a
 * nonzero literal, so the register is in no known basis state. */
__attribute__((noinline)) int rd(const unsigned char *p) { return p[0]; }
int q9(int x0) {
  int x = x0;
  cq_theta(&x, 0.5);
  unsigned n = ((unsigned)x & 0x1fff) | 1;
  unsigned char a[8192], b[8192];
  __builtin_memset(a, 7, n);
  a[0] = (unsigned char)x;
  __builtin_memcpy(b, a, n);
  return cq_measure(rd(a) + rd(b));
}
