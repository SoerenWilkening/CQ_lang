/* CQ.h — user-facing intrinsic surface (taint-driven design).
 *
 * Three primitive families (cq_theta, cq_phi, cq_measure) and one
 * inversion bracket (cq_invert_begin/_end). Parsed by stock Clang;
 * lowered by the cq-lowering IR pass. See docs/frontend.md §3.
 *
 * This slice (M03) lands the cq_theta family; cq_phi (M05),
 * cq_measure (M07), and the inversion markers (M10) follow.
 */
#ifndef CQ_H_
#define CQ_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* cq_theta — Ry(θ) rotation; the sole taint source. */
bool                cq_theta_i1  (bool               x, double angle);
char                cq_theta_c   (char               x, double angle);
signed char         cq_theta_si8 (signed char        x, double angle);
unsigned char       cq_theta_ui8 (unsigned char      x, double angle);
short               cq_theta_si16(short              x, double angle);
unsigned short      cq_theta_ui16(unsigned short     x, double angle);
int                 cq_theta_si32(int                x, double angle);
unsigned int        cq_theta_ui32(unsigned int       x, double angle);
long                cq_theta_sl  (long               x, double angle);
unsigned long       cq_theta_ul  (unsigned long      x, double angle);
long long           cq_theta_sll (long long          x, double angle);
unsigned long long  cq_theta_ull (unsigned long long x, double angle);
float               cq_theta_f32 (float              x, double angle);
double              cq_theta_f64 (double             x, double angle);
_Float16            cq_theta_f16 (_Float16           x, double angle);  /* Phase 7.1 Inc D */

/* cq_phi — Rz(φ) phase rotation; propagates taint, never a source. */
bool                cq_phi_i1  (bool               x, double angle);
char                cq_phi_c   (char               x, double angle);
signed char         cq_phi_si8 (signed char        x, double angle);
unsigned char       cq_phi_ui8 (unsigned char      x, double angle);
short               cq_phi_si16(short              x, double angle);
unsigned short      cq_phi_ui16(unsigned short     x, double angle);
int                 cq_phi_si32(int                x, double angle);
unsigned int        cq_phi_ui32(unsigned int       x, double angle);
long                cq_phi_sl  (long               x, double angle);
unsigned long       cq_phi_ul  (unsigned long      x, double angle);
long long           cq_phi_sll (long long          x, double angle);
unsigned long long  cq_phi_ull (unsigned long long x, double angle);
float               cq_phi_f32 (float              x, double angle);
double              cq_phi_f64 (double             x, double angle);
_Float16            cq_phi_f16 (_Float16           x, double angle);  /* Phase 7.1 Inc D */

/* cq_measure — measurement; the sole sink. Return is classical
   (operand only, no angle). */
bool                cq_measure_i1  (bool               x);
char                cq_measure_c   (char               x);
signed char         cq_measure_si8 (signed char        x);
unsigned char       cq_measure_ui8 (unsigned char      x);
short               cq_measure_si16(short              x);
unsigned short      cq_measure_ui16(unsigned short     x);
int                 cq_measure_si32(int                x);
unsigned int        cq_measure_ui32(unsigned int       x);
long                cq_measure_sl  (long               x);
unsigned long       cq_measure_ul  (unsigned long      x);
long long           cq_measure_sll (long long          x);
unsigned long long  cq_measure_ull (unsigned long long x);
float               cq_measure_f32 (float              x);
double              cq_measure_f64 (double             x);
_Float16            cq_measure_f16 (_Float16           x);  /* Phase 7.1 Inc D */

/* long double family (Phase 7.1 / bd 3c6m.4) — TARGET-DEPENDENT width.
   `long double` maps to a DIFFERENT ABI width per target, so the C token
   binds to exactly ONE runtime suffix selected by __LDBL_MANT_DIG__ at
   preprocess time:
     * x86_fp80  (x86-64: mantissa 64) → f80 (SHIPPED). Only this width is
       DECLARED, so the pass never sees a per-target-wrong prototype; the
       `l`-suffixed math.h variants (sqrtl/erfl/…) source through it.
     * IEEE-quad (AArch64 Linux: 113) → f128 is NOT shipped (its sound
       runtime c_type is a real 128-bit fp this x86-64 build cannot compile;
       `long double` == fp80 here would ABI-miscompile an fp128 value). With
       no association, `cq_theta((long double)…)` is a clean COMPILE ERROR
       ("unsupported type") rather than a wrong lowering — a deferred,
       must-be-built-on-AArch64 follow-up.
     * double (Apple Silicon / MSVC: 53) → NO distinct symbol; the existing
       `double:` _Generic arm already matches (long double IS double there,
       so a separate arm would be a duplicate-type error).
   The angle operand stays `double` at every width (Rule 3). */
#if __LDBL_MANT_DIG__ == 64
long double         cq_theta_f80 (long double         x, double angle);
long double         cq_phi_f80   (long double         x, double angle);
long double         cq_measure_f80 (long double        x);
#  define CQ_THETA_LDBL_   long double: cq_theta_f80,
#  define CQ_PHI_LDBL_     long double: cq_phi_f80,
#  define CQ_MEASURE_LDBL_ long double: cq_measure_f80,
#else  /* long double == double (dispatched by the double: arm) OR fp128
          (AArch64, deferred — no association → compile error, not a wrong
          lowering). */
#  define CQ_THETA_LDBL_
#  define CQ_PHI_LDBL_
#  define CQ_MEASURE_LDBL_
#endif

/* Inversion markers — bare extern, no attributes. LLVM cannot prove an
   unknown extern is side-effect-free, so calls survive elimination at
   every -O level (PRD §2.4). The IR pass detects the bracket via these
   names at module-level call sites (docs/frontend.md §3.5). */
void __cq_invert_begin(void);
void __cq_invert_end  (void);

#ifdef __cplusplus
}
#endif

/* User-facing dispatch — type-driven via C11 _Generic. */
#define cq_theta(x, angle) _Generic((x),           \
    CQ_THETA_LDBL_                                  \
    bool:               cq_theta_i1,               \
    char:               cq_theta_c,                \
    signed char:        cq_theta_si8,              \
    unsigned char:      cq_theta_ui8,              \
    short:              cq_theta_si16,             \
    unsigned short:     cq_theta_ui16,             \
    int:                cq_theta_si32,             \
    unsigned int:       cq_theta_ui32,             \
    long:               cq_theta_sl,               \
    unsigned long:      cq_theta_ul,               \
    long long:          cq_theta_sll,              \
    unsigned long long: cq_theta_ull,              \
    float:              cq_theta_f32,              \
    double:             cq_theta_f64,              \
    _Float16:           cq_theta_f16               \
)(x, angle)

/* cq_ry(x, θ) — the documented STATEMENT surface for an in-place Ry.
   A rotation consumes the old name (docs/frontend.md §3.2, the linear
   rule), so the assignment IS the semantics; `cq_ry(x, θ)` is exactly
   `x = cq_theta(x, θ)` and lowers to the identical IR at -O1
   (tests/frontend/cq_ry_macro.c). `cq_theta` stays declared: it is the
   expression form, and it is how state prep is written — `r = cq_theta(5, θ)`
   rotates a FRESH register seeded with 5, which has no in-place spelling. */
#define cq_ry(x, angle) ((x) = cq_theta((x), (angle)))

/* cq_phi — Rz phase-rotation dispatch (same 15 widths as cq_theta). */
#define cq_phi(x, angle) _Generic((x),             \
    CQ_PHI_LDBL_                                    \
    bool:               cq_phi_i1,                 \
    char:               cq_phi_c,                  \
    signed char:        cq_phi_si8,                \
    unsigned char:      cq_phi_ui8,                \
    short:              cq_phi_si16,               \
    unsigned short:     cq_phi_ui16,               \
    int:                cq_phi_si32,               \
    unsigned int:       cq_phi_ui32,               \
    long:               cq_phi_sl,                 \
    unsigned long:      cq_phi_ul,                 \
    long long:          cq_phi_sll,                \
    unsigned long long: cq_phi_ull,                \
    float:              cq_phi_f32,                \
    double:             cq_phi_f64,                \
    _Float16:           cq_phi_f16                 \
)(x, angle)

/* cq_measure — measurement dispatch (operand only; no angle). */
#define cq_measure(x) _Generic((x),                \
    CQ_MEASURE_LDBL_                               \
    bool:               cq_measure_i1,             \
    char:               cq_measure_c,              \
    signed char:        cq_measure_si8,            \
    unsigned char:      cq_measure_ui8,            \
    short:              cq_measure_si16,           \
    unsigned short:     cq_measure_ui16,           \
    int:                cq_measure_si32,           \
    unsigned int:       cq_measure_ui32,           \
    long:               cq_measure_sl,             \
    unsigned long:      cq_measure_ul,             \
    long long:          cq_measure_sll,            \
    unsigned long long: cq_measure_ull,            \
    float:              cq_measure_f32,            \
    double:             cq_measure_f64,            \
    _Float16:           cq_measure_f16             \
)(x)

/* Manual inversion bracket. The asm-volatile memory barrier pins the
   marker to its position so the optimizer cannot hoist bracketed code
   across it: cq_invert_begin emits the begin-call THEN a barrier (code
   can't move above begin); cq_invert_end emits a barrier THEN the
   end-call (code can't move below end). Bare-extern + barrier => the
   calls survive DCE at -O0..-O3. */
#define cq_invert_begin()  do {                                    \
        __cq_invert_begin();                                       \
        __asm__ __volatile__("" ::: "memory");                     \
    } while (0)
#define cq_invert_end()    do {                                    \
        __asm__ __volatile__("" ::: "memory");                     \
        __cq_invert_end();                                         \
    } while (0)

#endif  /* CQ_H_ */
