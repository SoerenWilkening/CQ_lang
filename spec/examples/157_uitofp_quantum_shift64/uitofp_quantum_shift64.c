/* Rule 4: uitofp on a quantum operand, a quantum shift AMOUNT at i64 (totalization: amount mod 64), and a quantum
 * shift amount feeding a classical base (_lh). */
double uitofp_q(unsigned x0, double tx) { unsigned x = x0; cq_theta(&x, tx); return cq_measure((double)x); }
long long shl_amount_q_i64(long long a, unsigned s0, double ts) {
    unsigned s = s0; cq_theta(&s, ts); return cq_measure(a << s); }
unsigned long long lshr_qq_i64(unsigned long long a0, unsigned long long s0, double ta, double ts) {
    unsigned long long a = a0, s = s0; cq_theta(&a, ta); cq_theta(&s, ts); return cq_measure(a >> s); }
