#!/bin/bash
# Write the extra one-boundary-out probe sources (caller TUs + their lib TUs).
cd "$(dirname "$0")"
Y='int h(int a, int k) { return k + 1; }
int g(int a) { return a * 3 + 1; }
int g2(int a, int b) { return a + b; }'
HDR='#include <stdlib.h>
#include <stdio.h>
int h(int a, int k); int g(int a); int g2(int a, int b);'
F='__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }'
w() { printf '%s\n%s\n' "$HDR" "$2" > "$1.c"; printf '%s\n' "$Y" > "$1.lib.c"; }
w ya  'int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = g(t); return cq_measure(u); }'
w yb  'int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = g2(t, q); return cq_measure(u); }'
w yc  'int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (g(t) > 3) r = m + 5; return cq_measure(r); }'
w ob1 "$F
int main(int argc, char **argv) { int m = atoi(argv[1]); int u = g(f(m)); return u; }"
w ob2 "$F
int main(int argc, char **argv) { int m = atoi(argv[1]); return cq_measure(f(m)); }"
w ob3 "$F
int G;
int main(int argc, char **argv) { int m = atoi(argv[1]); G = f(m); return 0; }"
w ob4 "$F
__attribute__((noinline)) int f1(int m) { return f(m) * 2; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f1(m) + 1; }"
w ob5 '__attribute__((noinline)) int f(int m, int c) { int q = cq_theta(m, .5); int t; if (c > 2) t = h(q, m); else t = h(q, m + 1); return t; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int c = atoi(argv[2]); return f(m, c); }'
w ob6 "$F
int main(int argc, char **argv) { int m = atoi(argv[1]); printf(\"%d\\n\", f(m)); return 0; }"
w ob7 "$F
int main(int argc, char **argv) { int m = atoi(argv[1]); int q2 = cq_theta(m, .25); int u = g2(f(m), q2); return cq_measure(u); }"
w ob8 '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t + cq_measure(q); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int r = m; if (f(m) > n) r = m + 5; return r; }'
w ob9 '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int s = g(t); return s; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m) + 7; }'
