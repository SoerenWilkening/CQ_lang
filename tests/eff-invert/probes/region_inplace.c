/* CR rule 17 with rule 6 (owner 2026-11-26): inside a cq_invert region an in-place add, xor or sub of a register (a rail
 * live at the begin) is one core gate on its rail, replayed inverted at the end; after the region the register is that
 * rail. Each entry reads the updated value inside the region, so -O1 keeps the update there. */
#include "CQ.h"
/* sub y, o with a rail o: sub_i32(w, a), replayed as add. */
int rinp_sub(unsigned a0, double ta, unsigned w0, double tw, unsigned k, double p) {
  unsigned a = a0; cq_theta(&a, ta);
  unsigned w = w0; cq_theta(&w, tw);
  cq_invert_begin();
  a -= w;
  if (a == k) cq_phi(p);
  cq_invert_end();
  return cq_measure(a) + cq_measure(w);
}
/* The old value read after the update in the region (a copy, cleaned inside the region) and after the end (the
 * register). */
int rinp_old(unsigned a0, double ta, unsigned w, unsigned k, double p, double q) {
  unsigned a = a0; cq_theta(&a, ta);
  unsigned t = a;
  cq_invert_begin();
  a += w;
  if ((a ^ t) == k) cq_phi(p);
  cq_invert_end();
  if (t + 1 == k) cq_phi(q);
  return cq_measure(a);
}
/* Two updates of one old value: the last is the gate, the first a value made in the region. */
int rinp_two(unsigned char y0, double ty, unsigned char k, double p, double q) {
  unsigned char y = y0; cq_theta(&y, ty);
  cq_invert_begin();
  unsigned char b = y ^ 5;
  if (b > k) cq_phi(p);
  y = y + 1;
  if (y > k) cq_phi(q);
  cq_invert_end();
  return cq_measure(y);
}
/* A register whose value at the begin is a template result (rule-5 garbage): kept, updated in place. */
int rinp_tmpl(unsigned a0, double ta, unsigned w, unsigned k, double p) {
  unsigned a = a0; cq_theta(&a, ta);
  unsigned s = a * 3;
  cq_invert_begin();
  s += w;
  if (s == k) cq_phi(p);
  cq_invert_end();
  return cq_measure(s) + cq_measure(a);
}
/* An update after a measurement in the region: replayed; the gates before the measurement run forward. */
int rinp_meas(unsigned a0, double ta, unsigned b0, double tb, unsigned k, double p) {
  unsigned a = a0; cq_theta(&a, ta);
  unsigned b = b0; cq_theta(&b, tb);
  cq_invert_begin();
  unsigned m = cq_measure(b);
  a += m;
  if (a == k) cq_phi(p);
  cq_invert_end();
  return cq_measure(a) + m;
}
/* A begin in a quantum arm, its end after the join: the update in the tail is y += f ? 3 : 0 inside the bracket and
 * y += !f ? 3 : 0 outside it. */
int rinp_arm(unsigned char a0, double ta, unsigned char c0, double tc, unsigned char k, double p) {
  unsigned char a = a0; cq_theta(&a, ta);
  unsigned char c = c0; cq_theta(&c, tc);
  if (c > 7)
    cq_invert_begin();
  a += 3;
  if (a == k) cq_phi(p);
  cq_invert_end();
  return cq_measure(a) + cq_measure(c);
}
/* An update in a quantum arm inside the region, merged with the old value at the join. */
int rinp_qarm(unsigned char a0, double ta, unsigned char c0, double tc, unsigned char w, unsigned char k, double p,
              double q) {
  unsigned char a = a0; cq_theta(&a, ta);
  unsigned char c = c0; cq_theta(&c, tc);
  cq_invert_begin();
  if (c > 7) {
    a += w;
    cq_phi(q);
  }
  if (a == k) cq_phi(p);
  cq_invert_end();
  return cq_measure(a) + cq_measure(c);
}
/* Nested regions updating one register. */
int rinp_nest(unsigned char a0, double ta, unsigned char k, double p, double q) {
  unsigned char a = a0; cq_theta(&a, ta);
  cq_invert_begin();
  a += 5;
  if (a > k) cq_phi(p);
  cq_invert_begin();
  a ^= 9;
  if (a > k) cq_phi(q);
  cq_invert_end();
  cq_invert_end();
  return cq_measure(a);
}
