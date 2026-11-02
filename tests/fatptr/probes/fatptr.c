/* tests/fatptr probes (cq-w1-fatptr): rule 21 pointer compares, each entry checked §6 against its own C program
 * (cqcheck user). Regenerate fatptr.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../CQ_spec fatptr.c -o fatptr.O1.ll */
#include "CQ.h"
int G[8] = {0, 0, 0, 0, 0, 0, 0, 0};
/* two local objects, ne: tag != tag' or idx != idx' */
int f_ne_two(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0};
  int *p = ((x & 1) ? a : b) + ((x >> 1) & 3);
  int *q = b + ((x >> 3) & 3);
  return cq_measure(p != q);
}
/* three local objects through nested selects against a quantum tag of its own */
int f_eq_three(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0}, c[4] = {0, 0, 0, 0};
  int *p = ((x & 1) ? a : ((x & 2) ? b : c)) + ((x >> 2) & 3);
  int *q = ((x & 16) ? c : a) + ((x >> 5) & 3);
  return cq_measure(p == q);
}
/* both select arms carry a quantum cell index (a select of idx rails) */
int f_eq_arms(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0};
  int *p = (x & 1) ? a + ((x >> 1) & 3) : b + ((x >> 3) & 3);
  int *q = a + ((x >> 5) & 3);
  return cq_measure(p == q);
}
/* a global: compares over addresses (globals may alias), ordering within one object */
int f_lt_global(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int *p = ((x & 1) ? G : G + 4) + ((x >> 1) & 3);
  int *q = G + ((x >> 3) & 7);
  return cq_measure(p < q);
}
/* signed cell indices into two globals: a sign-extended quantum index, eq over addresses */
int H[8] = {0, 0, 0, 0, 0, 0, 0, 0};
int f_eq_signed(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int *p = (G + 4) + (x % 4), *q = (H + 4) + ((x >> 4) % 4);
  return cq_measure(p == q);
}
/* cq-qf4c (review w2a-qram-h1 t16): a classical offset onto a QROM root plus a narrow quantum index is
 * summed at i64 as the GEP does (c = 8, k = 0xfe reads cell 262, never cell 6) */
static const int QA[300] = {[0] = 3, [6] = 6, [100] = 100, [255] = 255, [262] = 262, [299] = 299};
static const int QB[300] = {[0] = 5, [6] = 60, [100] = 1000, [255] = 2550, [262] = 2620, [299] = 2990};
int f_rail_off(unsigned x0, double t, unsigned char k0, double tk, int c) {
  unsigned x = x0; cq_theta(&x, t);
  unsigned char k = k0; cq_theta(&k, tk);
  const int *p = (x & 1) ? QA : QB;
  if (c < 0 || c > 44) c = 0;
  return cq_measure((p + c)[k]);
}
/* cq-qf4c, the QRAM store path: a store through (p + c)[k] into one of two QRAM arrays lands in cell c + k */
int f_rail_off_store(unsigned x0, double t, unsigned char k0, double tk, int c, int j) {
  unsigned x = x0; cq_theta(&x, t);
  unsigned char k = k0; cq_theta(&k, tk);
  int a[300] = {0}, b[300] = {0};
  int *p = (x & 1) ? a : b;
  if (c < 0 || c > 44) c = 0;
  if (j < 0 || j > 299) j = 0;
  (p + c)[k] = 7;
  return cq_measure(a[j] + 2 * b[j]);
}
/* 89/107 (rule 21): ptrtoint of a fat pointer over three objects with a rail cell index, integer arithmetic,
 * inttoptr back (p's provenance, idx = (u - base[tag]) / 4), a load: one QROM per object merged on the tag */
#include <stdint.h>
int f_ptr_roundtrip(unsigned x0, double th, int v) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {v, v + 1, v + 2, v + 3}, b[4] = {10, 11, 12, 13}, c[4] = {20, 21, 22, 23};
  int *p = ((x & 1) ? a : ((x & 2) ? b : c)) + ((x >> 2) & 1);
  uintptr_t u = (uintptr_t)p + 4 * ((x >> 3) & 1) + 4;
  return cq_measure(*(int *)u + v);
}
/* 107 union_int_to_ptr: inttoptr of a quantum offset onto a classical ptrtoint: one object, classical tag */
int f_int_to_ptr(unsigned x0, double th, int w) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {w, w + 1, w + 2, w + 3};
  uintptr_t u = (uintptr_t)a + 4 * (x & 3);
  return cq_measure(*(int *)u);
}
/* cq-r7 (105): llvm.ptrmask of a fat pointer, the flat-address round trip (2-byte cells, mask -8) */
int f_ptrmask(unsigned x0, double th, int v) {
  unsigned x = x0; cq_theta(&x, th);
  short a[8] __attribute__((aligned(16))) = {(short)v, 1, 2, 3, (short)(v + 4), 5, 6, 7};
  short *p = a + (x & 7);
  short *q = __builtin_align_down(p, 8);
  return cq_measure(*q + *p);
}
/* a clone's fat-pointer result (85): {tag, idx} over two triple formals and NULL, a NULL test, a load */
__attribute__((noinline)) static int *pick2(int *a, int *b, unsigned k) {
  int *q = (k & 2) ? b + ((k >> 2) & 1) : (int *)0, *r = a + ((k >> 1) & 3);
  return (k & 1) ? r : q;
}
int f_ret_ptr(unsigned x0, double th, int a0) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {a0, a0 + 1, a0 + 2, a0 + 3}, b[2] = {a0 + 7, a0 + 9};
  int *p = pick2(a, b, x);
  return cq_measure(p ? *p : -1);
}
/* 129 (cq-g1ty, M7; rules 6, 18, 20, 21): a read-modify-write through a quantum select of three whole local slot
 * objects, then through a clone handed the pointer (the object table, tag, idx 0); each dead old cell cleaned by
 * rule 6 (after the store; after the call, in the caller) */
__attribute__((noinline)) static void drop3(int *p) { *p -= 3; }
int f_slot_rmw(int x0, double th, int k, int a0, double ta, int b0, double tb, int c0, double tc) {
  int x = x0, a = a0, b = b0, c = c0;
  cq_theta(&x, th);
  cq_theta(&a, ta);
  cq_theta(&b, tb);
  cq_theta(&c, tc);
  int *p = (x > k) ? &a : ((x < -k) ? &b : &c);
  *p ^= 5;
  drop3(p);
  return cq_measure(a) + cq_measure(b) + cq_measure(c);
}
/* 129: the old register still read after the read-modify-write (t = a): its cell held a copy, the copy is
 * cleaned, the register kept */
__attribute__((noinline)) static void bump1(int *p) { *p += 1; }
int f_slot_rmw_old(int x0, double th, int k, int a0, double ta, int b0, double tb) {
  int x = x0, a = a0, b = b0;
  cq_theta(&x, th); cq_theta(&a, ta); cq_theta(&b, tb);
  int t = a;
  int *p = (x > k) ? &a : &b;
  *p += 1;
  bump1(p);
  return cq_measure(a) + cq_measure(b) + cq_measure(t);
}
/* 129: a clone that only reads through the object table */
__attribute__((noinline)) static int peek1(int *p) { return *p; }
int f_slot_peek(int x0, double th, int k, int a0, double ta, int b0, double tb) {
  int x = x0, a = a0, b = b0;
  cq_theta(&x, th); cq_theta(&a, ta); cq_theta(&b, tb);
  int *p = (x > k) ? &a : &b;
  *p += 2;
  int v = peek1(p);
  return cq_measure(a) + cq_measure(b) + cq_measure(v);
}
/* 129 (rule 20, 7): a guarded store at a classical index into the third field column of an array of structs
 * (the array keeps its layout); the column's seeds never hold a user register: released at its lifetime end */
struct tri { int f; int g; int h; };
int f_field_store(int x0, double th, int k, int y0, double ty, int c, int i) {
  int x = x0, y = y0;
  cq_theta(&x, th);
  cq_theta(&y, ty);
  struct tri s[3] = {{1, c, c + 2}, {2, c + 1, c + 3}, {3, c, c - 1}};
  if (x < k)
    s[i].h = y + c;
  return cq_measure(s[0].h + s[1].h + s[2].h + s[i].g);
}
/* cq-b244: roots inside their objects (&t[4]) reach the cells before them at negative cell indices */
static const int NT1[8] = {10, 11, 12, 13, 14, 15, 16, 17};
static const int NT2[8] = {20, 21, 22, 23, 24, 25, 26, 27};
/* a QROM read through a summed rail index (zext term, then -4 cells) */
int f_neg_qrom(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  const int *p = (x & 1) ? &NT1[4] : &NT2[4];
  int d = (int)((x >> 1) & 7) - 4;
  return cq_measure(p[d]);
}
/* a QROM read through a lone sign-extended rail index (in-domain: -4 .. 3) */
int f_neg_qrom_sext(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  const int *p = (x & 1) ? &NT1[4] : &NT2[4];
  int d = ((int)x) >> 28;
  return cq_measure(p[d]);
}
int NG1[8], NG2[8];
/* address compares of a summed rail index below the root */
int f_neg_cmp(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int *p = (x & 1) ? &NG1[4] : &NG2[4];
  int *r = p + ((x >> 1) & 7) - 4;
  return cq_measure(r < &NG1[3]) + 2 * cq_measure(r == &NG1[2]);
}
/* an inttoptr of an address moved below the root (a negative ptrtoint difference) */
int f_neg_inttoptr(unsigned x0, double th, int v) {
  unsigned x = x0; cq_theta(&x, th);
  int a[8] = {v, v + 1, v + 2, v + 3, v + 4, v + 5, v + 6, v + 7}, b[8] = {9, 8, 7, 6, 5, 4, 3, 2};
  int *p = (x & 1) ? &a[4] : &b[4];
  unsigned long u = (unsigned long)p + ((x >> 1) & 7) * 4;
  int *r = (int *)(u - 16);
  return cq_measure(*r);
}
/* cq-5xm0 (rules 20, 21): a 2-D index into a quantum select of two 2-D tables: two quantum GEP terms of scales
 * 20 and 4, idx = 5 i + j in 4-byte cells (the flattened form) */
static const int T2A[4][5] = {{1, 2, 3, 4, 5}, {6, 7, 8, 9, 10}, {11, 12, 13, 14, 15}, {16, 17, 18, 19, 20}};
static const int T2B[4][5] = {{21, 22, 23, 24, 25}, {26, 27, 28, 29, 30}, {31, 32, 33, 34, 35}, {36, 37, 38, 39, 40}};
int f_2d_qrom(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  const int(*t)[5] = (x & 1) ? T2A : T2B;
  return cq_measure(t[(x >> 1) & 3][(x >> 3) % 5]);
}
/* cq-5xm0: the same flattened 2-D index on the QRAM store path */
int f_2d_qram(unsigned x0, double th, int v) {
  unsigned x = x0; cq_theta(&x, th);
  int a[3][4] = {{0}}, b[3][4] = {{0}};
  int(*t)[4] = (x & 1) ? a : b;
  t[(x >> 1) % 3][(x >> 3) & 3] = v;
  return cq_measure(a[1][2] + 2 * b[2][3] + 4 * a[0][0]);
}
/* cq-5xm0: arms of two cell sizes (int and long) merge in their common 4-byte cells */
static const long LW[4] = {100, -200, 300, -400};
int f_sel_cells(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  const int *pa = NT1 + ((x >> 1) & 7), *pb = (const int *)(LW + ((x >> 4) & 3));
  const int *p = __builtin_unpredictable(x & 1) ? pa : pb;
  return cq_measure(*p);
}
/* cq-5xm0: a classical condition choosing between two fat pointers with rail fields (rule 9 at a classical
 * predicate: a classical select of the rails) */
int f_sel_classical(unsigned x0, double th, int c) {
  unsigned x = x0; cq_theta(&x, th);
  const int *p = (x & 1) ? NT1 + ((x >> 1) & 3) : NT2 + ((x >> 3) & 7);
  const int *q = (x & 2) ? NT2 + ((x >> 4) & 1) : NT1;
  const int *r = c ? p : q;
  return cq_measure(*r + r[1]);
}
/* cq-5xm0 (rule 21): a load through a quantum tag at a run-time classical index from host objects: each object's
 * access checked against its extent, 0 beyond it */
int HG1[4] = {1, 2, 3, 4}, HG2[6] = {5, 6, 7, 8, 9, 10};
int f_host_idx(unsigned x0, double th, int j) {
  unsigned x = x0; cq_theta(&x, th);
  if (j < 0 || j > 3) j = 0;
  int *p = (x & 1) ? HG1 : HG2 + 2;
  return cq_measure(p[j]);
}
/* cq-5xm0 (rules 9, 20, 21): a plain store (no read-modify-write) through a quantum select of slot objects, and
 * one under a quantum predicate */
int f_slot_store(int x0, double th, int a0, double ta, int b0, double tb, int v) {
  int x = x0, a = a0, b = b0;
  cq_theta(&x, th); cq_theta(&a, ta); cq_theta(&b, tb);
  int *p = (x & 1) ? &a : &b;
  *p = v;
  if (x & 2)
    *p = x;
  int w = peek1(p);
  return cq_measure(a) + 2 * cq_measure(b) + 4 * cq_measure(w);
}
/* cq-5xm0 (rule 20): a slot cell holding a classical value read through the fat pointer */
int f_slot_cls(int x0, double th, int a0, double ta, int c) {
  int x = x0, a = a0, b = c;
  cq_theta(&x, th); cq_theta(&a, ta);
  int *p = (x & 1) ? &a : &b;
  int r = *p;
  *p = r + 1;
  int w = peek1(p);
  return cq_measure(r) + 2 * cq_measure(a) + 4 * cq_measure(b) + 8 * cq_measure(w);
}
/* cq-5xm0 (rule 21): a load at the classical idx 0 through a quantum select of two host globals (each object's
 * access unguarded, merged on the tag) */
static int LA[4] = {1, 2, 3, 4}, LB[4] = {5, 6, 7, 8};
int f_host_zero(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  int *p = (x & 1) ? LB : LA;
  return cq_measure(*p);
}
/* cq-5xm0 (rules 9, 20, 21; 129): a plain store through a quantum select of slot objects, then a clone's
 * read-modify-write through the same pointer (the object table) */
__attribute__((noinline)) static void bump2(int *p) { *p += 1; }
int f_slot_plain(int x0, double th, int k, int a0, double ta, int b0, double tb) {
  int x = x0, a = a0, b = b0;
  cq_theta(&x, th); cq_theta(&a, ta); cq_theta(&b, tb);
  int *p = (x > k) ? &a : &b;
  *p = 7;
  bump2(p);
  return cq_measure(a) + cq_measure(b);
}
/* cq-5xm0 (rule 21): an integer of unknown origin (a select of two addresses) back to a pointer: decoded by range
 * tests over the candidate objects */
int f_int_unknown(unsigned x0, double th, int v) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {v, v + 1, v + 2, v + 3}, b[4] = {10, 11, 12, 13};
  uintptr_t ua = (uintptr_t)a, ub = (uintptr_t)b;
  uintptr_t m = (uintptr_t)0 - (x & 1);
  uintptr_t u = ((ua & m) | (ub & ~m)) + 4 * ((x >> 1) & 3);
  return cq_measure(*(int *)u);
}
/* cq-5xm0 (rule 21): an inttoptr accessed at two sizes and through a GEP: byte cells, converted at each access */
int f_int_bytes(unsigned x0, double th, int v) {
  unsigned x = x0; cq_theta(&x, th);
  int a[4] = {v, v + 1, v + 2, v + 3}, b[4] = {10, 11, 12, 13};
  int *p = (x & 1) ? a : b;
  uintptr_t u = (uintptr_t)p + 4 * ((x >> 1) & 3);
  short *s = (short *)u;
  return cq_measure(s[1] + *(int *)u);
}
/* cq-5xm0 (rule 21; 189): pointers to cells inside objects stored into host memory, loaded through a fat pointer:
 * each loaded address decoded by range tests over the stored pointers' roots (tag and idx) */
int IG1[4] = {1, 2, 3, 4}, IG2[6] = {5, 6, 7, 8, 9, 10};
int f_host_interior(unsigned x0, double th, int i, int j) {
  unsigned x = x0; cq_theta(&x, th);
  if (i < 0 || i > 3) i = 0;
  if (j < 0 || j > 5) j = 0;
  int *tab[2];
  tab[0] = &IG1[i];
  tab[1] = IG2 + j;
  int **p = (x & 1) ? &tab[1] : &tab[0];
  int *q = *p;
  return cq_measure(*q);
}
/* the same through a global table the program keeps (its stores not forwarded to the load) */
int *ITAB[2];
int f_host_interior_tab(unsigned x0, double th, int i, int j) {
  unsigned x = x0; cq_theta(&x, th);
  if (i < 0 || i > 3) i = 0;
  if (j < 0 || j > 5) j = 0;
  ITAB[0] = &IG1[i];
  ITAB[1] = IG2 + j;
  int **p = (x & 1) ? &ITAB[1] : &ITAB[0];
  int *q = *p;
  return cq_measure(q[0]);
}
/* cq-5xm0 (rule 21): an address compare of fat pointers into two global QRAM objects (globals may alias: over
 * addresses, each object's base in the QRAM address space) */
static int QG1[8], QG2[8];
int f_qram_addr(unsigned x0, double th, int v) {
  unsigned x = x0; cq_theta(&x, th);
  int *p = ((x & 1) ? QG1 : QG2) + ((x >> 1) & 7);
  *p = v;
  int *q = ((x & 16) ? QG1 : QG2) + ((x >> 5) & 7);
  return cq_measure(p == q) + 2 * cq_measure(QG1[3] + QG2[5]);
}
