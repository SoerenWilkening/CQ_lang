// The CQ user surface for C++: CQ.h's functions under overloads (CQ.h dispatches with _Generic, which C++ lacks).
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
#ifndef CQ_NO_NEW
// The C++ runtime's allocation functions as source (a program may replace them): over malloc/free, which the pass knows (rule 16).
#include <cstddef>
#include <new>
extern "C" { void *malloc(size_t); void free(void *); void *aligned_alloc(size_t, size_t); }
void *operator new(size_t n) { return malloc(n); }
void *operator new[](size_t n) { return malloc(n); }
void *operator new(size_t n, std::align_val_t a) { return aligned_alloc((size_t)a, n); }
void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p, size_t) noexcept { free(p); }
void operator delete[](void *p, size_t) noexcept { free(p); }
void operator delete(void *p, std::align_val_t) noexcept { free(p); }
void operator delete(void *p, size_t, std::align_val_t) noexcept { free(p); }
#endif
extern "C" {
void cq_phi(double);
__attribute__((noduplicate)) void __cq_invert_begin(void);
__attribute__((noduplicate)) void __cq_invert_end(void);
}
#define cq_invert_begin() do { __cq_invert_begin(); __asm__ __volatile__("" ::: "memory"); } while (0)
#define cq_invert_end()   do { __asm__ __volatile__("" ::: "memory"); __cq_invert_end(); } while (0)
// q(v): v made quantum, the one-line form the programs here use.
template <class T> inline __attribute__((always_inline)) T q(T v) { cq_theta(&v, 0.5); return v; }
#define ENTRY extern "C" 
