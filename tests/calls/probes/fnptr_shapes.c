/* tests/calls probe (cq-yrgm, CR rule 19, §1.3): escaping functions of several shapes, each with its registered row: a
 * variadic one, one taking a struct by value, a double one, a recursive one, one that writes memory; each called through a
 * classical pointer with a quantum argument.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec fnptr_shapes.c -o fnptr_shapes.O1.ll */
#include <stdarg.h>
#include "CQ.h"
typedef struct { int a; int b; long c; } trip;
int g_store;
__attribute__((noinline)) static int sumv(int n, ...) { va_list ap; va_start(ap, n); int s = 0; for (int i = 0; i < n && i < 3; i++) s += va_arg(ap, int); va_end(ap); return s; }
__attribute__((noinline)) static long bysum(trip t) { return t.a + t.b + t.c; }
__attribute__((noinline)) static double half(double d) { return d * 0.5; }
__attribute__((noinline)) static int rec(int n) { return n <= 0 ? 0 : 1 + rec(n - 2); }
__attribute__((noinline)) static int wr(int v) { g_store = v; return v + 7; }
int (*volatile p_sumv)(int, ...) = sumv;
long (*volatile p_bysum)(trip) = bysum;
double (*volatile p_half)(double) = half;
int (*volatile p_rec)(int) = rec;
int (*volatile p_wr)(int) = wr;
int s_va(int x0, double th) { int x = x0; cq_theta(&x, th); return cq_measure(p_sumv(2, x, 5)); }
long s_by(int x0, double th) { int x = x0; cq_theta(&x, th); trip t = {x, 2, 3}; return cq_measure(p_bysum(t)); }
double s_fp(double x0, double th) { double x = x0; cq_theta(&x, th); return cq_measure(p_half(x)); }
int s_rec(unsigned char x0, double th) { int x = x0 & 7; cq_theta(&x, th); return cq_measure(p_rec(x)); }
int s_wr(int x0, double th) { int x = x0; cq_theta(&x, th); int r = p_wr(x); return cq_measure(r) + cq_measure(g_store); }
