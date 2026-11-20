__attribute__((noinline)) static int h(int v) { return (int)((unsigned)v * 2654435761u >> 7); }
int bddrepro(int x0, double th, int a) {
  int x = x0;
  cq_theta(&x, th);
  int s;
  switch (x & 255) {
    case 0: if (a == 1) goto L1; goto L2;
    case 1: if (a == 4) goto L1; goto L2;
    case 2: if (a == 7) goto L1; goto L2;
    case 3: if (a == 10) goto L1; goto L2;
    case 4: if (a == 13) goto L1; goto L2;
    case 5: if (a == 16) goto L1; goto L2;
    case 6: if (a == 19) goto L1; goto L2;
    case 7: if (a == 22) goto L1; goto L2;
    case 8: if (a == 25) goto L1; goto L2;
    case 9: if (a == 28) goto L1; goto L2;
    case 10: if (a == 31) goto L1; goto L2;
    case 11: if (a == 34) goto L1; goto L2;
    default: s = a; goto E;
  }
L1: s = h(a + 1); goto E;
L2: s = h(a + 2);
E:
  return cq_measure(s + x);
}
