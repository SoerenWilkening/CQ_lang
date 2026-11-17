/* Entries for the repo's checker on the lowered SoftFloat roots (softfloat/test/checker/run.sh): each makes
 * its operands quantum with cq_theta, calls one root and measures the result. CQ.h has no _Float16/__bf16
 * forms: their operands are quantum 16-bit patterns bit-cast to the float type, and the result is measured
 * as its pattern. The roots' bodies come from the internalized clang -O1 module of the library. */
#include <stdbool.h>
#include <stdint.h>
typedef unsigned short u16;
#define BC(T, x) __builtin_bit_cast(T, x)
static double qd(double x0) { double x = x0; cq_theta(&x, 0.0); return x; }
static float qf(float x0) { float x = x0; cq_theta(&x, 0.0); return x; }
static u16 qh(u16 x0) { u16 x = x0; cq_theta(&x, 0.0); return x; }
static unsigned qu(unsigned x0) { unsigned x = x0; cq_theta(&x, 0.0); return x; }
static long long ql(long long x0) { long long x = x0; cq_theta(&x, 0.0); return x; }
static signed char qc(signed char x0) { signed char x = x0; cq_theta(&x, 0.0); return x; }

#ifndef CQ_F80
double cqsf_fadd_f64(double, double);           uint32_t cqsf_fadd_f64_x(double, double, uint32_t);
float cqsf_fmul_f32(float, float);              _Float16 cqsf_fdiv_f16(_Float16, _Float16);
double cqsf_sqrt_f64(double);                   _Float16 cqsf_frem_f16(_Float16, _Float16);
double cqsf_fma_f64(double, double, double);    bool cqsf_fcmp_olt_f64(double, double);
float cqsf_rint_f32_m(float, uint32_t);         _Float16 cqsf_floor_f16(_Float16);
int32_t cqsf_fptosi_f64_to_i32(double);         float cqsf_sitofp_i64_to_f32(int64_t);
double cqsf_fpext_f16_to_f64(_Float16);         __bf16 cqsf_fptrunc_f64_to_bf16(double);
__bf16 cqsf_fadd_bf16(__bf16, __bf16);          __bf16 cqsf_fmul_bf16_m(__bf16, __bf16, uint32_t);
bool cqsf_fcmp_ueq_bf16(__bf16, __bf16);        double cqsf_sitofp_i7_to_f64(_BitInt(7));
float cqsf_fneg_f32(float);

double e_fadd_f64(double a, double b) { return cq_measure(cqsf_fadd_f64(qd(a), qd(b))); }
unsigned e_fadd_f64_x(double a, double b, unsigned m) { return cq_measure((unsigned)cqsf_fadd_f64_x(qd(a), qd(b), qu(m))); }
float e_fmul_f32(float a, float b) { return cq_measure(cqsf_fmul_f32(qf(a), qf(b))); }
u16 e_fdiv_f16(u16 a, u16 b) { return cq_measure(BC(u16, cqsf_fdiv_f16(BC(_Float16, qh(a)), BC(_Float16, qh(b))))); }
double e_sqrt_f64(double a) { return cq_measure(cqsf_sqrt_f64(qd(a))); }
u16 e_frem_f16(u16 a, u16 b) { return cq_measure(BC(u16, cqsf_frem_f16(BC(_Float16, qh(a)), BC(_Float16, qh(b))))); }
double e_fma_f64(double a, double b, double c) { return cq_measure(cqsf_fma_f64(qd(a), qd(b), qd(c))); }
bool e_fcmp_olt_f64(double a, double b) { return cq_measure(cqsf_fcmp_olt_f64(qd(a), qd(b))); }
float e_rint_f32_m(float a, unsigned m) { return cq_measure(cqsf_rint_f32_m(qf(a), qu(m))); }
u16 e_floor_f16(u16 a) { return cq_measure(BC(u16, cqsf_floor_f16(BC(_Float16, qh(a))))); }
int e_fptosi_f64_to_i32(double a) { return cq_measure((int)cqsf_fptosi_f64_to_i32(qd(a))); }
float e_sitofp_i64_to_f32(long long a) { return cq_measure(cqsf_sitofp_i64_to_f32(ql(a))); }
double e_fpext_f16_to_f64(u16 a) { return cq_measure(cqsf_fpext_f16_to_f64(BC(_Float16, qh(a)))); }
u16 e_fptrunc_f64_to_bf16(double a) { return cq_measure(BC(u16, cqsf_fptrunc_f64_to_bf16(qd(a)))); }
u16 e_fadd_bf16(u16 a, u16 b) { return cq_measure(BC(u16, cqsf_fadd_bf16(BC(__bf16, qh(a)), BC(__bf16, qh(b))))); }
u16 e_fmul_bf16_m(u16 a, u16 b, unsigned m) { return cq_measure(BC(u16, cqsf_fmul_bf16_m(BC(__bf16, qh(a)), BC(__bf16, qh(b)), qu(m)))); }
bool e_fcmp_ueq_bf16(u16 a, u16 b) { return cq_measure(cqsf_fcmp_ueq_bf16(BC(__bf16, qh(a)), BC(__bf16, qh(b)))); }
double e_sitofp_i7_to_f64(signed char a) { return cq_measure(cqsf_sitofp_i7_to_f64((_BitInt(7))qc(a))); }
float e_fneg_f32(float a) { return cq_measure(cqsf_fneg_f32(qf(a))); }
#else
static long double qx(long double x0) { long double x = x0; cq_theta(&x, 0.0); return x; }
long double cqsf_fadd_f80(long double, long double);   long double cqsf_fma_f80(long double, long double, long double);
long double cqsf_sqrt_f80(long double);                uint64_t cqsf_fptoui_f80_to_i64(long double);
bool cqsf_fcmp_ogt_f80(long double, long double);
long double e_fadd_f80(long double a, long double b) { return cq_measure(cqsf_fadd_f80(qx(a), qx(b))); }
long double e_fma_f80(long double a, long double b, long double c) { return cq_measure(cqsf_fma_f80(qx(a), qx(b), qx(c))); }
long double e_sqrt_f80(long double a) { return cq_measure(cqsf_sqrt_f80(qx(a))); }
unsigned long long e_fptoui_f80_to_i64(long double a) { return cq_measure((unsigned long long)cqsf_fptoui_f80_to_i64(qx(a))); }
bool e_fcmp_ogt_f80(long double a, long double b) { return cq_measure(cqsf_fcmp_ogt_f80(qx(a), qx(b))); }
#endif
