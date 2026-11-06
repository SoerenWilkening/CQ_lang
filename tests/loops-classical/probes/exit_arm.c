__attribute__((noinline)) int cf(char *x, int n, int m) {
  int r = 0, i;
  for (i = 0; i < n; i++) {
    if (i == m) goto hit;
    r += x[i];
  }
  r += 100;
  x[2] = 9;
  goto done;
hit:
  r += 200;
  x[3] = r;
done:
  return r + x[2] + x[3];
}
int pc5b(char c0) {
  char x[8] = {1, 2, 3, 4, 5, 6, 7, 8};
  x[1] = c0;
  cq_theta(&x[1], 0.3);
  int a = cf(x, 3, 1);
  int b = cf(x, 3, 7);
  int c = cf(x, 0, 7);
  cq_measure(a); cq_measure(b); cq_measure(c);
  return 0;
}
__attribute__((noinline)) int g(char *x, int n) {
  int r = 0, i;
  for (i = 0; i < n; i++) {
    if (x[i] == 0) goto found;
  }
  x[0] = 9;
  r = x[1] + 1;
found:
  r += i;
  return r + x[0];
}
int pa2b(char c0, char c1) {
  char x[8] = {1, 2, 3, 4, 5, 6, 7, 8};
  x[1] = c0; x[2] = c1;
  cq_theta(&x[1], 0.3);
  cq_theta(&x[2], 0.4);
  int a = g(x, 3);
  int b = g(x, 1);
  cq_measure(a); cq_measure(b);
  return 0;
}
__attribute__((noinline)) unsigned long h(const char *s) {
  const char *a = s;
  if ((unsigned long)s & 3) {
    if (!*s) goto done;
    for (;;) {
      s++;
      if (!((unsigned long)s & 3)) break;
      if (!*s) goto done;
    }
  }
  for (; *s; s++) ;
done:
  return s - a;
}
unsigned long pa1b(char c0, char c1) {
  char x[32] __attribute__((aligned(16))) = {0};
  for (int j = 0; j < 9; j++) x[j + 1] = "12.5e3 Ab"[j];
  x[0] = c0; x[2] = c1;
  cq_theta(&x[0], 0.3);
  cq_theta(&x[2], 0.4);
  unsigned long a = h(x);
  unsigned long b = h(x + 1);
  unsigned long c = h(x + 3);
  cq_measure(a); cq_measure(b); cq_measure(c);
  return 0;
}
// cause 4: an inner loop with exits out of the outer loop too (printf_core's literal scan and overflow return)
__attribute__((noinline)) int scan(const char *s) {
  int r = 0;
  for (;;) {
    for (;;) {
      if (r > 3) return -1;
      if (!*s) return r;
      if (*s == '%') break;
      s++; r++;
    }
    s++;
    r += 2;
  }
}
int pc4(char c0, char c1) {
  char x[8] = {1, '%', 3, 0, 5, 6, 7, 0};
  x[0] = c0; x[2] = c1;
  cq_theta(&x[0], 0.3);
  cq_theta(&x[2], 0.4);
  cq_measure(scan(x));
  return 0;
}
__attribute__((noinline)) unsigned long len0(const char *s) { const char *a = s; for (; *s; s++); return s - a; }
__attribute__((noinline)) char *chrn(const char *s, int c) {
  c = (unsigned char)c;
  if (!c) return (char *)s + len0(s);
  if ((unsigned long)s & 3) { /* classical */
    for (; (unsigned long)s & 3; s++) if (!*s || *(unsigned char *)s == c) return (char *)s;
  }
  for (; *s && *(unsigned char *)s != c; s++);
  return (char *)s;
}
int pa5(char x0e, int x1) {
  char x0[16] __attribute__((aligned(16))) = {0};
  x0[0] = x0e; x0[1] = 3; x0[2] = 4; x0[3] = 0;
  cq_theta(&x1, 0.3);
  char *r = chrn(x0, x1);
  cq_measure((long)(r - x0));
  return 0;
}
// cause 3: a pointer exit phi over two exit edges of a K-loop, with a classical other predecessor
__attribute__((noinline)) const char *wordscan(const char *s, char c) {
  for (;;) {
    if (*s == 0) return s;
    if (*s == c) return s + 1;
    s++;
  }
}
long pc3(char c0, char c1, int n) {
  char x[16] = {1, 2, 3, 4, 5, 0};
  x[1] = c0; x[3] = c1;
  cq_theta(&x[1], 0.3);
  cq_theta(&x[3], 0.4);
  const char *p = x;
  if (!(n & 1)) p = wordscan(x, 3);
  cq_measure((long)(p - x));
  return 0;
}
