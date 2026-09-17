// COMPOSITION ATTACK 1(b). The hoisted TEMPLATE rail `t = q & 1` is Track D's
// newly-admitted condition; Group 1's P2 discharges it at the LOOP EXIT with
// `and_i32_hl_unc(h_t, h_q, 1)`. That adjoint recomputes `f(args AT THE
// REVERSAL)`. Here `q` is ROTATED IN-BODY, so at the loop exit `h_q` no longer
// holds what the forward mint read: the "adjoint" does not invert its forward,
// the rail is NOT |0> and `cqrt_free` on it is a hidden measurement (Rule 6),
// on top of the Rule-8 record. (T4g) refuses exactly this operand movement; the
// question is whether the COMPILER refuses to place the discharge there.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  int t = q & 1;
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
    q = cq_theta(q, 0.1);            /* the rail's PARENT moves per trip */
  }
  return cq_measure(q) + cq_measure(r);
}
