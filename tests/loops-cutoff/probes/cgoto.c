/* tests/loops-cutoff computed-goto probes (CR rule 13, b137e75, cq-zaes): a computed goto is a switch whose scrutinee is
 * the ADDRESS itself (an i64), its case values ptrtoint(blockaddress(@f, %bb)), the last destination the complement. A
 * code address is an integer: a table of addresses read at a quantum index is a QROM of i64 cells, a select or phi of
 * addresses a rule 9 merge, a carried address a carried i64 handle (rule 14, classical bound and K-loop), a stored
 * address an i64 slot or QRAM cell (rule 20); a clone compares the original's addresses. Each entry is checked §6
 * against its own C program (cqcheck user).
 * Regenerate cgoto.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec cgoto.c -o cgoto.O1.ll */
#include "CQ.h"
/* K-loop trips: a classical index (the induction's parity) chooses the arm. */
int cg_classical(int x0, double th) {
  static const void *tbl[] = {&&even, &&odd};
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  while ((x >> i) & 1) {
    goto *tbl[i & 1];
  even:
    acc = acc * 3 + 1; i++; continue;
  odd:
    acc = acc + 7; i++; continue;
  }
  return cq_measure(acc);
}
/* A quantum index (a bit of x) chooses the arm. */
int cg_quantum(int x0, double th) {
  static const void *tbl[] = {&&zero, &&one};
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  do {
    goto *tbl[(x >> (i + 4)) & 1];
  zero:
    acc = acc * 5; i++; continue;
  one:
    acc = acc + 3; i++; continue;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* classical address: a table read at a classical index */
int cg_addr_classical(int x0, int c, double th) {
  static const void *tbl[] = {&&a, &&b, &&d};
  int x = x0; cq_theta(&x, th);
  int r;
  goto *tbl[(unsigned)c % 3u];
a: r = x + 1; goto out;
b: r = x * 3; goto out;
d: r = x ^ 5; goto out;
out:
  return cq_measure(r);
}
/* quantum address: a table read at a quantum index */
int cg_addr_quantum(int x0, double th) {
  static const void *tbl[] = {&&a, &&b, &&d, &&a};
  int x = x0; cq_theta(&x, th);
  int r;
  goto *tbl[x & 3];
a: r = x + 1; goto out;
b: r = x * 3; goto out;
d: r = x ^ 5; goto out;
out:
  return cq_measure(r);
}
/* a phi of addresses (two goto *p sites) chosen under a quantum branch */
int cg_addr_phi(int x0, int c, double th) {
  static const void *t1[] = {&&a, &&b};
  static const void *t2[] = {&&b, &&d, &&a};
  int x = x0; cq_theta(&x, th);
  int r;
  if (x > 3) goto *t1[c & 1];
  r = x - 2;
  goto *t2[(unsigned)x % 3u];
d: r = r * 5; goto out;
a: r = x + 1; goto out;
b: r = x * 3; goto out;
out:
  return cq_measure(r);
}
/* a loop-carried phi of addresses chosen under a quantum flag */
int cg_addr_carried(int x0, int n, double th) {
  int x = x0; cq_theta(&x, th);
  void *p = &&a;
  int acc = 1;
  for (int i = 0; i < n; i++) {
    goto *p;
  a: acc = acc * 3; p = ((x >> i) & 1) ? &&b : &&a; continue;
  b: acc = acc + 7; p = &&a; continue;
  }
  return cq_measure(acc);
}
/* an address stored to memory and reloaded */
int cg_addr_reload(int x0, int i, double th) {
  void *slot[2];
  int x = x0; cq_theta(&x, th);
  int r;
  slot[0] = &&a;
  slot[1] = (x & 1) ? &&b : &&a;
  goto *slot[i & 1];
a: r = i + 1; goto out;
b: r = i * 3; goto out;
out:
  return cq_measure(r);
}
/* a carried address in a K-loop (quantum exit) */
int cg_addr_kloop(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  void *p = &&a;
  int acc = 1, i = 0;
  do {
    goto *p;
  a: acc = acc * 3; p = ((x >> i) & 1) ? &&b : &&a; i++; continue;
  b: acc = acc + 7; p = &&a; i++; continue;
  } while ((x >> (i + 8)) & 1);
  return cq_measure(acc);
}
/* an address stored at a quantum index (QRAM) and reloaded */
int cg_addr_qram(int x0, int c, double th) {
  void *slot[4];
  int x = x0; cq_theta(&x, th);
  int r;
  slot[0] = &&a; slot[1] = &&a; slot[2] = &&a; slot[3] = &&a;
  slot[x & 3] = &&b;
  goto *slot[c & 3];
a: r = c + 1; goto out;
b: r = c * 3; goto out;
out:
  return cq_measure(r);
}
/* a computed goto in a callee reached with a quantum argument (its clone compares the original's addresses) */
__attribute__((noinline)) static int cg_callee(int v, int k) {
  static const void *tbl[] = {&&a, &&b, &&d};
  goto *tbl[(unsigned)v % 3u];
a: return v + k;
b: return v * 3;
d: return v ^ k;
}
int cg_addr_clone(int x0, int k, double th) {
  int x = x0; cq_theta(&x, th);
  int r = cg_callee(x, k) + cg_callee(k, 1);
  return cq_measure(r);
}
