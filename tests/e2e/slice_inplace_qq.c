/* slice_inplace_qq.c — bd test_C_libtooling-r2j3.33 / dm7f.51 step 1: a
   quantum-quantum `x ^= y`, `x += y`, `x -= y` whose OLD `x` is dead lowers IN
   PLACE on `x`'s rail (owner ruling owner-ruling-dm7f51-inplace-qq-2026-10-14).

   The only test layer that LINKS: it proves the new hand-maintained core ABI
   `cqrt_{xor,add,sub}_<W>(src, dst)` (runtime/cq_runtime.h) and the i1 form
   `cqrt_cnot(src, dst)` resolve and signature-match through the runtime.

   Each block is design shape V6 or its add/sub analogue: rotate `a` and `t`,
   reassign `t` from `a`, rotate `a` again, measure both. The golden must show,
   per block, exactly ONE void in-place gate whose DESTINATION is `t`'s handle
   (whichever side -O1 spelled it on), NO `cq_template_{xor,add,sub}_<W>` call,
   no third rail, and the later Ry on `a`'s handle. Analytic (i1 block, Ry(θ)|0> =
   cos θ/2|0> + sin θ/2|1>): the emitted CNOT(a->t); Ry(.7) on a gives
   P(a=0,t=0) = 0.7659, P(a=0,t=1) = 0.0095, the textbook values; the pre-r2j3.33
   out-of-place stream gave 0.7960 / 0.0396. */
#include <stdbool.h>

static int v6_bool(void) {
  bool a = 0, t = 0;
  cq_theta(&a, .5);
  cq_theta(&t, .4);
  t ^= a;
  cq_theta(&a, .7);
  return cq_measure(a) + cq_measure(t);
}

static int v6_int(void) {
  int a = 1, t = 2;
  cq_theta(&a, .5);
  cq_theta(&t, .4);
  t ^= a;
  cq_theta(&a, .7);
  return cq_measure(a) + cq_measure(t);
}

static long add_long(void) {
  long a = 3, t = 4;
  cq_theta(&a, .5);
  cq_theta(&t, .4);
  t += a;
  cq_theta(&a, .7);
  return cq_measure(a) + cq_measure(t);
}

static short sub_short(void) {
  short a = 5, t = 6;
  cq_theta(&a, .5);
  cq_theta(&t, .4);
  t -= a;
  cq_theta(&a, .7);
  return cq_measure(a) + cq_measure(t);
}

static signed char xor_char(void) {
  signed char a = 7, t = 8;
  cq_theta(&a, .5);
  cq_theta(&t, .4);
  t ^= a;
  cq_theta(&a, .7);
  return cq_measure(a) + cq_measure(t);
}

int slice(void) {
  return v6_bool() + v6_int() + (int)add_long() + sub_short() + xor_char();
}

int main(void) {
  (void)slice();
  return 0;
}
