#!/bin/bash
# Second adversarial probe batch (caller TU + lib TU per probe).
cd "$(dirname "$0")"
YC='int h(int a, int k) { return k + 1; }
int ext_f(int x) { return x * 11; }'
YQ='int h(int a, int k) { return a + k; }
int ext_f(int x) { return x * 11; }'
HDR='#include <stdlib.h>
int h(int a, int k); int ext_f(int x);'
w() { printf '%s\n%s\n' "$HDR" "$3" > "$1.c"; printf '%s\n' "$2" > "$1.lib.c"; }
# rp1: f returns a merge of the spec result under a TAINTED branch in f -> genuine.
w rp1 "$YC" '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (q > 3) r = t + 2; return r; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m) * 3; }'
# rq3: two levels, QUANTUM verdict: f2 provisional-quantum, f1 returns f2(m)*2.
w rq3 "$YQ" '__attribute__((noinline)) int f2(int m) { int q = cq_theta(m, .5); return h(q, m); }
__attribute__((noinline)) int f1(int m) { return f2(m) * 2; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return cq_measure(f1(m)); }'
# rfc / rfq: address-taken provisional f, classical / quantum verdict.
w rfc "$YC" '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int (*volatile fp)(int) = f;
int main(int argc, char **argv) { int m = atoi(argv[1]); return fp(m); }'
w rfq "$YQ" '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int (*volatile fp)(int) = f;
int main(int argc, char **argv) { int m = atoi(argv[1]); return fp(m); }'
# r65: provisional t plus a 6.5 classical-call-arm %out (round-2 taint) -> genuine.
w r65 "$YC" '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int y = 5; if (q > 5) y = ext_f(7); return t + y; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m) * 3; }'
# r65c: the same with only the %out returned (control: genuine, no spec dependence).
w r65c "$YC" '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int y = 5; if (q > 5) y = ext_f(7); return y; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m) * 3; }'
# rloop: caller uses the classical result as a loop bound.
w rloop "$YC" '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int s = 0; for (int i = 0; i < f(m); i++) s += i; return s; }'
# rsel: caller selects on the classical result with another register in the arms.
w rsel "$YC" '__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int q2 = cq_theta(m, .25); int r = f(m) > 2 ? q2 + 1 : q2; return cq_measure(r); }'
