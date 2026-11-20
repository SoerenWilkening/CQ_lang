#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) static int h(int v) { return (int)((unsigned)v * 2654435761u >> 7); }
__attribute__((noinline)) static int g(double x, int n) {
  double y = x * 3.0;
  int s = 0;
  for (int i = 0; i < n; i++) {
    if (h(i + 0) & 1) s += h(s + 0);
    if (h(i + 1) & 2) s += h(s + 1);
    if (h(i + 2) & 4) s += h(s + 2);
    if (h(i + 3) & 8) s += h(s + 3);
    if (h(i + 4) & 16) s += h(s + 4);
    if (h(i + 5) & 1) s += h(s + 5);
    if (h(i + 6) & 2) s += h(s + 6);
    if (h(i + 7) & 4) s += h(s + 7);
    if (h(i + 8) & 8) s += h(s + 8);
    if (h(i + 9) & 16) s += h(s + 9);
    if (h(i + 10) & 1) s += h(s + 10);
    if (h(i + 11) & 2) s += h(s + 11);
    if (h(i + 12) & 4) s += h(s + 12);
    if (h(i + 13) & 8) s += h(s + 13);
    if (h(i + 14) & 16) s += h(s + 14);
    if (h(i + 15) & 1) s += h(s + 15);
    if (h(i + 16) & 2) s += h(s + 16);
    if (h(i + 17) & 4) s += h(s + 17);
    if (h(i + 18) & 8) s += h(s + 18);
    if (h(i + 19) & 16) s += h(s + 19);
    if (h(i + 20) & 1) s += h(s + 20);
    if (h(i + 21) & 2) s += h(s + 21);
    if (s == 77) return s;
  }
  if (fetestexcept(FE_INEXACT)) s++;
  return s + (y > 1.0);
}
int fenvrepro(double x0, double th, int n) {
  double x = x0;
  cq_theta(&x, th);
  return cq_measure(g(x, n));
}
