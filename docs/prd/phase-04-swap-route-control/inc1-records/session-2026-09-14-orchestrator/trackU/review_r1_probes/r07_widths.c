/* the widths the implementer did not fixture: i8 i16 i64 float half */
#include <CQ.h>
int f(void) {
  char c8; short s16; long long l64; float f32;
  c8  = cq_theta(c8, 0.5);
  s16 = cq_theta(s16, 0.5);
  l64 = cq_theta(l64, 0.5);
  f32 = cq_theta(f32, 0.5);
  return (int)cq_measure(c8) + (int)cq_measure(s16) + (int)cq_measure(l64) + (int)cq_measure(f32);
}
