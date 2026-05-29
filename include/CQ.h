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

/* Legacy annotation macro — unused under the taint-driven design;
   removed in M07. Retained here so the M03/M05 slices stay minimal. */
#define quantum __attribute__((annotate("quantum")))

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

#ifdef __cplusplus
}
#endif

/* User-facing dispatch — type-driven via C11 _Generic. */
#define cq_theta(x, angle) _Generic((x),           \
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
    double:             cq_theta_f64               \
)(x, angle)

/* cq_phi — Rz phase-rotation dispatch (same 14 widths as cq_theta). */
#define cq_phi(x, angle) _Generic((x),             \
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
    double:             cq_phi_f64                 \
)(x, angle)

#endif  /* CQ_H_ */
