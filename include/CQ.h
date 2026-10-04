/* CQ.h — user-facing intrinsic surface (taint-driven design).
 *
 * The surface is cq_theta, cq_phi, cq_measure and the cq_invert_* bracket,
 * nothing else (owner decision 2026-10-03, bd test_C_libtooling-1501):
 *   * cq_theta(&x, θ) — Ry(θ) IN PLACE on the variable x; the sole taint
 *     source. A void expression, so a statement: there is no `b = cq_theta(q, θ)`.
 *   * cq_measure(x)   — the sole sink; returns the classical outcome.
 *   * cq_phi(θ)       — the register-free BRANCH PHASE (no data operand).
 *   * cq_invert_begin() / cq_invert_end() — the inversion bracket.
 * Underneath, cq_theta and cq_measure are per-type primitive families
 * (cq_theta_<sfx>, cq_measure_<sfx>) at 14 standard C scalar types plus the
 * conditional _Float16/long-double rows; the cq-lowering IR pass matches
 * those names. Parsed by stock Clang. See docs/frontend.md §3.
 *
 * !! Two retired spellings fail to COMPILE here, deliberately, with no shim:
 * the two-argument `cq_phi_<sfx>(x, angle)` family (bd 3qlq Inc 1,
 * 2026-09-05; see the block at cq_phi) and the value form
 * `y = cq_theta(x, θ)` with its `cq_ry(x, θ)` statement macro (bd 1501,
 * 2026-10-03; see the block at the cq_theta macro). A program written against
 * either must be rewritten, never silently re-read.
 */
#ifndef CQ_H_
#define CQ_H_

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* cq_theta — Ry(θ) rotation; the sole taint source.

   EVERY cq_theta_* DECLARATION CARRIES `nomerge` (bd test_C_libtooling-fmt3,
   owner ruling 2026-09-28, option B). `clang -O1` may otherwise MERGE two
   cq_theta calls that CQ reads as DIFFERENT registers, and the merge erases
   the branch between them — after which no pass can recover what the source
   said. Measured (inc1-records/session-2026-09-28-parallel/TRACK_FMT3.md §1):

       int t = q / 4;  int r = 5;
       if (q2 > 3) { if (t == 5) { r = t; cq_theta(&r, .9); }
                     else        { r = 5; cq_theta(&r, .9); } }

   IPSCCP substitutes t := 5 into the first arm, the two arms become the
   identical call cq_theta_si32(5, .9), and the late SimplifyCFG hoists the pair
   and DELETES the inner branch. The module that reaches cq-lowering is then
   the stage-1 IR of the unrelated LEGITIMATE program
   `if (q2 > 3) { r = 5; cq_theta(&r, .9); }` — identical, trace for trace — so it
   was compiled as a fresh |5> prep and `t` was never rotated. A second
   route (sink the two calls with ONE phi, fold `select (q == 20), t, 5` by
   simplifyWithOpReplaced) produces the SAME module from a source whose
   rotated register is NOT the compare's operand, so the two readings cannot
   be told apart in IR by anything, and neither from the legitimate one.
   For DIRECT calls, `nomerge` keeps both calls and the branch; the pass then
   sees the shape and declines it (nested control / two-rail if/else / 2c)
   instead of silently accepting a different program.

   ⚠ WHAT IT DOES NOT CLOSE (two open P1s, both PRE-EXISTING): clang puts
   `nomerge` on each CALL SITE naming these declarations, not on the LLVM
   declaration, so a call through a FUNCTION POINTER (`f = cq_theta_si32;`,
   `(&cq_theta_si32)(…)`, a higher-order helper) reaches -O1 without it and the
   fold returns (bd 4e4p); and `int m = (t == s) ? t : s; cq_theta(&m, θ);` is
   folded to `cq_theta_si32(s, θ)` with NO merge at all, which for a quantum
   `s` is a different unitary (bd uw5u). Neither is reachable by a header
   attribute.

   ⚠ COST, ACCEPTED BY THE OWNER (docs/frontend.md §3.1 prices each):
   - the IF/ELSE spelling over ONE register under a QUANTUM condition,
     `if (c) cq_theta(&r, A); else cq_theta(&r, B);`, no longer folds into
     one call with a SELECTED ANGLE; it lowers as two controlled Ry — the same
     unitary. The TERNARY spelling `cq_theta(&r, c ? A : B);` still produces
     the select-angle call directly (no merge) and still reaches
     AngleSelectEmit's by-difference Ry stem;
   - over-declines: that if/else under a CLASSICAL condition inside a loop, and
     an if/else preparing the same literal on both arms (bd cx6j); a legitimate
     common-code merge on ONE register (bd 4l5q);
   - some programs moved DECLINE → ACCEPT, measured correct against their twins
     (the in-loop Ry if/else, flat programs the in-place Ry arm lowers).
   `cq_phi` and `cq_measure` deliberately do NOT carry `nomerge`
   (TRACK_FMT3.md §9.6: a merged measure keeps the outcome distribution under
   CQ's coherent-control model, an unruled choice tied to bd yiid).

   ⚠ A compiler without the attribute is REFUSED below rather than silently
   re-opening the merge: CQ's stage 1 is stock clang, where it exists. */
#if defined(__has_attribute)
#  if __has_attribute(nomerge)
#    define CQ_THETA_NOMERGE_ __attribute__((nomerge))
#  endif
#endif
#ifndef CQ_THETA_NOMERGE_
#  error "CQ.h: this compiler lacks __attribute__((nomerge)); cq_theta calls could be merged across branches (bd fmt3)"
#endif
CQ_THETA_NOMERGE_ bool                cq_theta_i1  (bool               x, double angle);
CQ_THETA_NOMERGE_ char                cq_theta_c   (char               x, double angle);
CQ_THETA_NOMERGE_ signed char         cq_theta_si8 (signed char        x, double angle);
CQ_THETA_NOMERGE_ unsigned char       cq_theta_ui8 (unsigned char      x, double angle);
CQ_THETA_NOMERGE_ short               cq_theta_si16(short              x, double angle);
CQ_THETA_NOMERGE_ unsigned short      cq_theta_ui16(unsigned short     x, double angle);
CQ_THETA_NOMERGE_ int                 cq_theta_si32(int                x, double angle);
CQ_THETA_NOMERGE_ unsigned int        cq_theta_ui32(unsigned int       x, double angle);
CQ_THETA_NOMERGE_ long                cq_theta_sl  (long               x, double angle);
CQ_THETA_NOMERGE_ unsigned long       cq_theta_ul  (unsigned long      x, double angle);
CQ_THETA_NOMERGE_ long long           cq_theta_sll (long long          x, double angle);
CQ_THETA_NOMERGE_ unsigned long long  cq_theta_ull (unsigned long long x, double angle);
CQ_THETA_NOMERGE_ float               cq_theta_f32 (float              x, double angle);
CQ_THETA_NOMERGE_ double              cq_theta_f64 (double             x, double angle);
CQ_THETA_NOMERGE_ _Float16            cq_theta_f16 (_Float16           x, double angle);  /* Phase 7.1 Inc D */

/* cq_phi — BRANCH PHASE (bd test_C_libtooling-3qlq Inc 1, PRD
   `retire-swap-route-PRD.md` §4.1, owner decision D1, 2026-09-05).

   `cq_phi(θ)` means "multiply the amplitude of the CURRENT BRANCH by
   e^{iθ}". It takes NO register: it is ordered by the block it sits in,
   not by taint, and it is neither a taint source nor a propagator.

     * Under a tainted condition it lowers by KICKBACK — the condition flag
       is minted into a |0> ancilla by the ordinary compare mint, the phase
       goes on the FLAG (`cqrt_rz_i1(f, θ)`, UNCONTROLLED), the ordinary
       compare `_unc` returns the flag to |0> on every branch, and the flag
       is freed. Nothing on the data register is touched.
     * Uncontrolled or classically-controlled, it is a GLOBAL phase and is
       DELETED (D2) — a documented semantic, not a diagnostic.

   The 15-width `cq_phi_<sfx>(x, angle)` family it REPLACES emitted a
   TENSORED `cqrt_rz_<W>` (Rz on each qubit of the register), which puts
   phase (-1)^popcount(target) on the marked branch and can NEVER mark
   |0..0> — so every Grover golden built on it was the identity on q
   (PRD §1, bd `grover-goldens-are-identity-tensored-rz-2026-09-05`). A
   program using the old spelling now fails to COMPILE against this header;
   there is deliberately no migration shim.

   A register-wide Z rotation is the classical per-bit loop (D4):
       for (int i = 0; i < W; i++) if ((q >> i) & 1) cq_phi(θ);   */
void                cq_phi     (double angle);

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
       no association, `cq_theta(&ld, …)` on a long double is a clean COMPILE ERROR
       ("unsupported type") rather than a wrong lowering — a deferred,
       must-be-built-on-AArch64 follow-up.
     * double (Apple Silicon / MSVC: 53) → NO distinct symbol; the existing
       `double:` _Generic arm already matches (long double IS double there,
       so a separate arm would be a duplicate-type error).
   The angle operand stays `double` at every width (Rule 3). */
#if __LDBL_MANT_DIG__ == 64
CQ_THETA_NOMERGE_ long double         cq_theta_f80 (long double         x, double angle);
long double         cq_measure_f80 (long double        x);
#  define CQ_THETA_LDBL_   long double *: cq_theta_f80,
#  define CQ_MEASURE_LDBL_ long double: cq_measure_f80,
#else  /* long double == double (dispatched by the double: arm) OR fp128
          (AArch64, deferred — no association → compile error, not a wrong
          lowering). */
#  define CQ_THETA_LDBL_
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

/* cq_theta(&x, θ) — Ry(θ) IN PLACE on the variable x (bd
   test_C_libtooling-1501, owner decision 2026-10-03). A rotation changes x,
   and the `&` says so, as in `frexp(v, &e)`. It is a void expression, so it
   is a statement in practice: there is no `y = cq_theta(&x, θ)`.

   `cq_theta(&x, θ)` is exactly the retired `x = cq_theta(x, θ)`: it expands to
   `*(px) = cq_theta_<sfx>(*(px), θ)`, the _Generic selecting the raw entry
   point by the POINTER type. The call is emitted in the user's own function,
   so the pass sees the same `%x2 = call @cq_theta_<sfx>(%x, θ)` it has always
   matched. Measured 2026-10-04 over the repository's C sources (docs/frontend.md
   §3.2): the stage-1 IR is byte-identical to the retired spelling's except a
   `phi` permutation where a prep variable gains a second store; an always_inline
   wrapper per type moved the `declare` and flipped `phi` incoming order, and a
   do/while statement form or a local copy of the pointer perturbed `phi` and
   predecessor order. Hence no wrapper, no statement form and no local.

   The price is that `px` is evaluated twice, so it must be free of side
   effects (`&x`, `&a[i]`, `&s->f`, `p` are; `&a[i++]` and `next_ptr()` are
   not). That is checked, not hoped: the unevaluated `__builtin_assume` below
   costs no IR, and clang's side-effect diagnostic on it is raised to an
   error for this expansion only.

   Spellings:
     * state prep goes through a variable: `int r = 5; cq_theta(&r, θ);`
     * a rotated COPY is an explicit copy: `int c = q; cq_theta(&c, θ);`
       (c is rotated, q keeps its value; a later read of q is a stale read,
       bd 57ch).
   Each of these fails to compile: a pointer to a const or volatile object (no
   generic association), a non-lvalue (`&5`), the retired value form
   `cq_theta(x, θ)` (indirection of a non-pointer) and a use of the result. */
#define cq_theta(px, angle) ((void)(                                  \
    _Pragma("clang diagnostic push")                                   \
    _Pragma("clang diagnostic error \"-Wassume\"")                     \
    (void)sizeof((__builtin_assume((px) != 0), 0)),                    \
    _Pragma("clang diagnostic pop")                                    \
    *(px) = _Generic((px),                                             \
        CQ_THETA_LDBL_                                                 \
        bool *:               cq_theta_i1,                             \
        char *:               cq_theta_c,                              \
        signed char *:        cq_theta_si8,                            \
        unsigned char *:      cq_theta_ui8,                            \
        short *:              cq_theta_si16,                           \
        unsigned short *:     cq_theta_ui16,                           \
        int *:                cq_theta_si32,                           \
        unsigned int *:       cq_theta_ui32,                           \
        long *:               cq_theta_sl,                             \
        unsigned long *:      cq_theta_ul,                             \
        long long *:          cq_theta_sll,                            \
        unsigned long long *: cq_theta_ull,                            \
        float *:              cq_theta_f32,                            \
        double *:             cq_theta_f64,                            \
        _Float16 *:           cq_theta_f16                             \
    )(*(px), (angle))))

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
