#include <stdlib.h>
/* r2A scale: N independent (b') chains in ONE function, each with a clone consumer before its Ry */
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  int acc = 0;
  { int q = cq_theta((m + 0) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 10) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 1) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 11) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 2) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 12) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 3) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 13) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 4) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 14) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 5) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 15) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 6) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 16) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 7) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 17) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 8) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 18) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 9) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 19) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 10) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 20) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 11) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 21) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 12) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 22) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 13) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 23) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 14) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 24) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 15) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 25) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 16) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 26) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 17) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 27) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 18) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 28) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 19) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 29) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 20) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 30) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 21) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 31) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 22) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 32) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 23) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 33) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 24) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 34) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 25) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 35) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 26) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 36) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 27) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 37) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 28) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 38) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 29) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 39) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 30) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 40) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 31) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 41) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 32) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 42) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 33) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 43) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 34) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 44) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 35) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 45) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 36) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 46) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 37) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 47) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 38) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 48) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  { int q = cq_theta((m + 39) & 7, 0.5); int p = q * 3; int u = p ^ q; if (u == 49) cq_phi(3.14159); int s = h(m, p); q = cq_theta(q, 0.7); acc += cq_measure(s) + cq_measure(q); }
  return acc;
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
