// cq.hpp: the CQ user surface for C++, what CQ.h is for C: the same functions under overloads (CQ.h dispatches with
// _Generic, which C++ lacks). cqcc includes it in every C++ unit.
#pragma once
// libc++'s documented knobs: its hardening abort as a plain abort, and std::string's bodies in the module instead of in libc++.dylib.
#define _LIBCPP_VERBOSE_ABORT(...) __builtin_abort()
#define _LIBCPP_DISABLE_EXTERN_TEMPLATE
#define CQ_T(sfx, T) \
  extern "C" { [[clang::nomerge]] T cq_theta_##sfx(T, double); T cq_measure_##sfx(T); } \
  inline __attribute__((always_inline)) void cq_theta(T *p, double a) { *p = cq_theta_##sfx(*p, a); } \
  inline __attribute__((always_inline)) T cq_measure(T x) { return cq_measure_##sfx(x); }
CQ_T(i1, bool) CQ_T(c, char) CQ_T(si8, signed char) CQ_T(ui8, unsigned char) CQ_T(si16, short)
CQ_T(ui16, unsigned short) CQ_T(si32, int) CQ_T(ui32, unsigned) CQ_T(sl, long) CQ_T(ul, unsigned long)
CQ_T(sll, long long) CQ_T(ull, unsigned long long) CQ_T(f32, float) CQ_T(f64, double) CQ_T(f80, long double)
extern "C" {
void cq_phi(double);
__attribute__((noduplicate)) void __cq_invert_begin(void);
__attribute__((noduplicate)) void __cq_invert_end(void);
}
#define cq_invert_begin() do { __cq_invert_begin(); __asm__ __volatile__("" ::: "memory"); } while (0)
#define cq_invert_end()   do { __asm__ __volatile__("" ::: "memory"); __cq_invert_end(); } while (0)
