/* tests/calls probe, cq-o1swj (CR 778-779, rule 16): K&R's getline (The C Programming Language, 1.9), int (char *, int),
   is not POSIX getline's ssize_t (char **, size_t *, FILE *): the program's own function, lifted, lowered, compared. */
int getchar(void);
__attribute__((noinline)) static int getline(char s[], int lim) {
  int c, i;
  for (i = 0; i < lim - 1 && (c = getchar()) != -1 && c != '\n'; ++i)
    s[i] = c;
  s[i] = '\0';
  return i;
}
int p8(int x0, double t) {
  int x = x0;
  cq_theta(&x, t);
  char buf[16];
  int n = getline(buf, (x & 3) + 2);
  return cq_measure(n);
}
