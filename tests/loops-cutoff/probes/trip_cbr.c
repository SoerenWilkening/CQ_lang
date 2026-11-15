/* tests/loops-cutoff classical branches inside a K-trip (cq-jws5r, CR rule 8: "A purely classical condition is always
 * a classical branch, also inside a clone", with rule 14's K trips): each trip keeps the branch as a `br`, so the
 * arm C does not take emits nothing (no store, no call, no kept rail), and the arm it takes runs under the trip
 * predicate alone. Each entry is checked §6 against its own C program (cqcheck user); run_probes.py --br-in counts the
 * `br` on the classical condition in the lowered bodies. A pointer argument is never varied by the sampler, so NULL
 * against an object is chosen by a classical int.
 * Regenerate trip_cbr.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_cbr.c -o trip_cbr.O1.ll */
#include "CQ.h"

/* (a) The bead's probe: a store behind a classical pointer test, in a clone (mask 100). */
__attribute__((noinline)) static unsigned pa_loop(unsigned x, unsigned k, int *f) {
  while (x > k) { x >>= 1; if (f) *f = 7; }
  return x;
}
int pa_store(unsigned x0, double th, unsigned k, int sel) {
  int cell = 3;
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = pa_loop(x, k, (sel & 1) ? &cell : (int *)0);
  return (int)cq_measure(r) * 16 + cq_measure(cell);
}
/* The same with a quantum value stored and read back in place. */
__attribute__((noinline)) static unsigned pa_loop2(unsigned x, unsigned k, unsigned *f) {
  while (x > k) { x >>= 1; if (f) *f += x; }
  return x;
}
unsigned pa_update(unsigned x0, double th, unsigned k, int sel) {
  unsigned cell = 3;
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = pa_loop2(x, k, (sel & 1) ? &cell : (unsigned *)0);
  return cq_measure(r) * 64 + cq_measure(cell);
}

/* (b) A classical if/else with a call in one arm (the callee writes memory and takes a rail). */
static unsigned pb_seen;
__attribute__((noinline)) static unsigned pb_note(unsigned a, unsigned i) { pb_seen += a + i; return a * 5u + i; }
unsigned pb_call(unsigned x0, double th, unsigned k, int c) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned acc = 1;
  pb_seen = 0;
  while (x > k) {
    x >>= 1;
    if (c & 1) acc = pb_note(acc, x); else acc ^= 9;
  }
  return cq_measure(acc) * 256 + cq_measure(pb_seen);
}

/* (c) Nested: the K-loop sits in a function called under a quantum predicate (its _ctl clone). */
__attribute__((noinline)) static unsigned pc_inner(unsigned x, unsigned k, int c, unsigned *out) {
  unsigned n = 0;
  while (x > k) { x >>= 1; if (c & 2) *out += x + 1; n++; }
  return n;
}
unsigned pc_ctl(unsigned x0, double th, unsigned k, int c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned cell = 1, r = 9;
  if (y & 1) r = pc_inner(x, k, c, &cell);
  return cq_measure(r) * 256 + cq_measure(cell);
}

/* (d) The condition is computed inside the trip from classical values (the trip index and an invariant). */
unsigned pd_trip(unsigned x0, double th, unsigned k, unsigned c) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned cell[2] = {1, 2}, i = 0;
  unsigned *volatile p = cell;
  unsigned *f = p;
  while (x > k) {
    x >>= 1;
    if (((c + i * 3) & 3) == 1) f[i & 1] ^= x + i;
    i++;
  }
  return cq_measure(f[0]) * 64 + cq_measure(f[1]);
}

/* (e) A twin: the clone's result is uncomputed by its caller, so the trips are replayed in reverse. */
__attribute__((noinline)) static unsigned pe_f(unsigned x, unsigned k, unsigned c, const unsigned *tab) {
  unsigned acc = 0, i = 0;
  while (x > k) {
    x >>= 1;
    if ((c >> i) & 1) acc += tab[i & 3] ^ x; else acc ^= i;
    i++;
  }
  return acc;
}
static const unsigned pe_tab[4] = {3, 5, 11, 17};
unsigned pe_twin(unsigned x0, double th, unsigned k, unsigned c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned r = pe_f(x, k, c, pe_tab);
  if (r & 1) y += 3;
  return cq_measure(y);
}

/* (f) A nested K-loop behind the classical branch, and a `continue` on a classical condition before a store. */
unsigned pf_nested(unsigned x0, double th, unsigned k, int c, unsigned z0) {
  unsigned x = x0, z = z0; cq_theta(&x, th); cq_theta(&z, th);
  unsigned cell = 0, n = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  while (x > k) {
    x >>= 1;
    if (c & 1) {
      *f ^= 5;   /* keeps the branch a branch at -O1 (no `c && q` select) */
      unsigned w = z;
      while (w > x) { w >>= 1; n += 2; }
    }
    if (!(c & 2)) continue;
    *f += n + 1;
  }
  return cq_measure(n) * 256 + cq_measure(*f);
}

/* (g) A noreturn arm behind a classical condition inside the trip. */
void abort(void);
unsigned pg_abort(unsigned x0, double th, unsigned k, int c) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (x > k) {
    x >>= 1;
    if (c == 77 && n == 2) abort();
    n++;
  }
  return cq_measure(n);
}

/* (h) A measurement and a phase behind classical conditions inside the trip. */
unsigned ph_measure(unsigned x0, double th, unsigned k, int c, unsigned y0) {
  unsigned x = x0, y = y0; cq_theta(&x, th); cq_theta(&y, th);
  unsigned m = 0;
  while (x > k) {
    x >>= 1;
    if (c & 1) m += cq_measure(y & 3);
    if (c & 4) cq_phi(0.5);
  }
  return m * 16 + cq_measure(y);
}
