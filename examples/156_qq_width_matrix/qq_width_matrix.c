/* Rule 4: both-operands-quantum forms of the ops that only had a classical operand so far, at i8, i16, i64 and f32. */
signed char sub_qq_i8(signed char a0, signed char b0, double ta, double tb) {
    signed char a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure((signed char)(a - b)); }
short shl_qq_i16(short a0, short b0, double ta, double tb) {
    short a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure((short)(a << (b & 7))); }
long long ashr_qq_i64(long long a0, long long b0, double ta, double tb) {
    long long a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a >> (b & 63)); }
int sdiv_qq_i32(int a0, int b0, double ta, double tb) {
    int a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a / b); }
int srem_qq_i32(int a0, int b0, double ta, double tb) {
    int a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a % b); }
unsigned udiv_qq_i32(unsigned a0, unsigned b0, double ta, double tb) {
    unsigned a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a / b); }
long long and_qq_i64(long long a0, long long b0, double ta, double tb) {
    long long a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a & b); }
float fadd_qq_f32(float a0, float b0, double ta, double tb) {
    float a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a + b); }
float fdiv_qq_f32(float a0, float b0, double ta, double tb) {
    float a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a / b); }
double fdiv_qq_f64(double a0, double b0, double ta, double tb) {
    double a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb); return cq_measure(a / b); }
