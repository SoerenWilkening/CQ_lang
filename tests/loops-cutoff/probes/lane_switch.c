/* tests/loops-cutoff probe (CR rules 3, 13, 14, 26). ls_lane: musl cacoshf's shape, a bitcast of a complex value with one
 * quantum part keeps the other part classical (rule 26), so a branch on it is a classical branch.
 * ls_switch: musl __get_locale's shape, a classically bounded loop whose quantum switch sends two cases into the loop's
 * one exit block: the exit flag is the trip's test. Regenerate lane_switch.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec lane_switch.c -o lane_switch.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static float _Complex rot(float _Complex z) {
  union { float _Complex z; unsigned u[2]; } v;
  v.z = z;
  int neg = (int)v.u[1] < 0;
  float re = __real__ z, im = __imag__ z;
  return neg ? __builtin_complex(im, -re) : __builtin_complex(-im, re);
}
float ls_lane(float a, float b, double th) {
  cq_theta(&a, th);
  float _Complex r = rot(__builtin_complex(a, b));
  return cq_measure(__imag__ r);
}
int ls_switch(unsigned char *p0, long a, double th) {
  unsigned char s[8] = {1, 2, 47, 3, 0, 5, 6, 7};
  s[0] = (unsigned char)a;
  cq_theta(&s[0], th);
  (void)p0;
  long i;
  for (i = 0; i < 6; i++) {
    switch (s[i]) {
    case 0:
    case 47:
      goto out;
    }
  }
out:
  return cq_measure((int)i);
}
