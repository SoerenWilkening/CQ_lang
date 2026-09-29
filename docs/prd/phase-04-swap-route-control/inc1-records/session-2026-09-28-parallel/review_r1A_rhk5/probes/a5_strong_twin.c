/* the STRONG definition that interposes the module's weak twin at link time: it writes k. */
void cqrt_x(int); void cqrt_copy_i32(int,int); void cqrt_free(int);
int cq_template_mul_i32_hl(int,int); void cq_template_mul_i32_hl_unc(int,int,int);
void __cq_q_g_1_unc(int out, int k) {
  int t = cq_template_mul_i32_hl(k, 5); cqrt_copy_i32(t, out);
  cq_template_mul_i32_hl_unc(t, k, 5); cqrt_free(t); cqrt_x(k);
}
