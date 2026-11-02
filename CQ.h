/* CQ.h: the whole user surface.
 *   cq_theta(&x, angle)   Ry(angle) in place on x; makes x quantum.
 *   cq_measure(x)         measures x; returns the classical outcome.
 *   cq_phi(angle)         multiplies the amplitude of the current branch by e^(i*angle).
 *   cq_invert_begin/end   the enclosed code is emitted as its adjoint.
 * nomerge keeps clang from merging two cq_theta calls across a branch. */
#ifndef CQ_H_
#define CQ_H_

#include <stdbool.h>

#define CQ_NOMERGE_ __attribute__((nomerge))

CQ_NOMERGE_ bool               cq_theta_i1  (bool               x, double angle);
CQ_NOMERGE_ char               cq_theta_c   (char               x, double angle);
CQ_NOMERGE_ signed char        cq_theta_si8 (signed char        x, double angle);
CQ_NOMERGE_ unsigned char      cq_theta_ui8 (unsigned char      x, double angle);
CQ_NOMERGE_ short              cq_theta_si16(short              x, double angle);
CQ_NOMERGE_ unsigned short     cq_theta_ui16(unsigned short     x, double angle);
CQ_NOMERGE_ int                cq_theta_si32(int                x, double angle);
CQ_NOMERGE_ unsigned int       cq_theta_ui32(unsigned int       x, double angle);
CQ_NOMERGE_ long               cq_theta_sl  (long               x, double angle);
CQ_NOMERGE_ unsigned long      cq_theta_ul  (unsigned long      x, double angle);
CQ_NOMERGE_ long long          cq_theta_sll (long long          x, double angle);
CQ_NOMERGE_ unsigned long long cq_theta_ull (unsigned long long x, double angle);
CQ_NOMERGE_ float              cq_theta_f32 (float              x, double angle);
CQ_NOMERGE_ double             cq_theta_f64 (double             x, double angle);
#if __LDBL_MANT_DIG__ == 64
CQ_NOMERGE_ long double        cq_theta_f80 (long double        x, double angle);
#endif

bool               cq_measure_i1  (bool               x);
char               cq_measure_c   (char               x);
signed char        cq_measure_si8 (signed char        x);
unsigned char      cq_measure_ui8 (unsigned char      x);
short              cq_measure_si16(short              x);
unsigned short     cq_measure_ui16(unsigned short     x);
int                cq_measure_si32(int                x);
unsigned int       cq_measure_ui32(unsigned int       x);
long               cq_measure_sl  (long               x);
unsigned long      cq_measure_ul  (unsigned long      x);
long long          cq_measure_sll (long long          x);
unsigned long long cq_measure_ull (unsigned long long x);
float              cq_measure_f32 (float              x);
double             cq_measure_f64 (double             x);
#if __LDBL_MANT_DIG__ == 64
long double        cq_measure_f80 (long double        x);
#  define CQ_LDBL_THETA_   long double *: cq_theta_f80,
#  define CQ_LDBL_MEASURE_ long double: cq_measure_f80,
#else
#  define CQ_LDBL_THETA_
#  define CQ_LDBL_MEASURE_
#endif

void cq_phi(double angle);

/* noduplicate: -O1 (jump threading) must never copy a marker into the arms of a branch; a marker stays ONE host event
 * in the block every path reaches (CONSTRUCTION_RULES rule 17, 2026-11-02). */
__attribute__((noduplicate)) void __cq_invert_begin(void);
__attribute__((noduplicate)) void __cq_invert_end(void);

#define cq_theta(px, angle) ((void)(*(px) = _Generic((px), \
    CQ_LDBL_THETA_                                         \
    bool *:               cq_theta_i1,                     \
    char *:               cq_theta_c,                      \
    signed char *:        cq_theta_si8,                    \
    unsigned char *:      cq_theta_ui8,                    \
    short *:              cq_theta_si16,                   \
    unsigned short *:     cq_theta_ui16,                   \
    int *:                cq_theta_si32,                   \
    unsigned int *:       cq_theta_ui32,                   \
    long *:               cq_theta_sl,                     \
    unsigned long *:      cq_theta_ul,                     \
    long long *:          cq_theta_sll,                    \
    unsigned long long *: cq_theta_ull,                    \
    float *:              cq_theta_f32,                    \
    double *:             cq_theta_f64                     \
)(*(px), (angle))))

#define cq_measure(x) _Generic((x),         \
    CQ_LDBL_MEASURE_                        \
    bool:               cq_measure_i1,      \
    char:               cq_measure_c,       \
    signed char:        cq_measure_si8,     \
    unsigned char:      cq_measure_ui8,     \
    short:              cq_measure_si16,    \
    unsigned short:     cq_measure_ui16,    \
    int:                cq_measure_si32,    \
    unsigned int:       cq_measure_ui32,    \
    long:               cq_measure_sl,      \
    unsigned long:      cq_measure_ul,      \
    long long:          cq_measure_sll,     \
    unsigned long long: cq_measure_ull,     \
    float:              cq_measure_f32,     \
    double:             cq_measure_f64      \
)(x)

/* The memory barriers keep the optimizer from moving code across the markers. */
#define cq_invert_begin() do { __cq_invert_begin(); __asm__ __volatile__("" ::: "memory"); } while (0)
#define cq_invert_end()   do { __asm__ __volatile__("" ::: "memory"); __cq_invert_end(); } while (0)

/* Default loop cutoff of a function (CONSTRUCTION_RULES rule 14, rule 27). A lowered library ships a header of
 * these lines, e.g. CQ_K(sin, 53) CQ_K(fmod, 2046); a compiler flag for that function overrides it. */
#define CQ_K(fn, k) __attribute__((used)) static const int __cq_k_##fn = (k);

#endif
