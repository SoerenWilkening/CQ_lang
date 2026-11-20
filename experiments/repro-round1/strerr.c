// cq-zd8jo: a switch clang -O1 turns into a relative table of string pointers (llvm.load.relative), quantum index.
static const char *name(int e) {
  switch (e) {
  case 0: return "zero";
  case 1: return "one";
  case 2: return "two";
  case 3: return "three";
  case 4: return "four";
  default: return "other";
  }
}
int strerr(int x0, double th) {
  int x = x0;
  cq_theta(&x, th);
  const char *s = name(x & 7);
  return cq_measure(s[1]);
}
