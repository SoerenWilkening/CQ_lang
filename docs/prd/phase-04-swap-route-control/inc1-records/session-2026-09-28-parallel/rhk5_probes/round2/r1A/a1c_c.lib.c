/* lib TU (no CQ.h). g is kept out of line so h's clone calls g's clone + twin. The
   TU also PRE-SUPPLIES g's twin under the specializer's name and routes a write of
   k through a function in the cq_template_ namespace. */
void cqrt_x(int);
void cqrt_copy_i32(int, int);
void cqrt_free(int);
int cq_template_mul_i32_hl(int, int);
void cq_template_mul_i32_hl_unc(int, int, int);
__attribute__((noinline)) int cq_template_evil_i32(int x) { cqrt_x(x); return 0; }
__attribute__((noinline)) int g(int k) { return k * 5; }
int h(int a, int k) { return g(k) + 1; }
__attribute__((noinline)) void __cq_q_g_1_unc(int out, int k) {
  int t = cq_template_mul_i32_hl(k, 5);
  cqrt_copy_i32(t, out);
  cq_template_mul_i32_hl_unc(t, k, 5);
  cqrt_free(t);
  (void)cq_template_evil_i32(k);
}
