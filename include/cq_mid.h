/* cq_mid.h — transpiled-C ABI for Phase 1 / Phase 2.
 *
 * Emitted into transpiled output by the rewriter; not part of the
 * user-facing surface in <CQ.h>. Declares the mid-level structs that
 * carry quantum signal at C-source boundaries (`qT_mid_t`) and the
 * per-width frontend intrinsics that clang -O1 -emit-llvm leaves for
 * the cq-lowering IR pass to rewrite into cqrt_ and cq_template_
 * runtime calls.
 *
 * Phase 2 generalizes Phase 1's i32-only surface to the full C scalar
 * type set: 14 mid-structs (one per C scalar kind tracked by the type
 * map) and 28 intrinsics (init + measure per mid-struct). Bodies are
 * intentionally absent — the IR pass lowers each call site before any
 * linker would resolve a definition (PRD §"Intrinsic surface").
 *
 * Architecture references: docs/architecture.md §3 (mid-type), §6.1
 * (init), §6.2 (measure).
 */
#ifndef CQ_MID_H_
#define CQ_MID_H_

#include <stdint.h>

/* `bool` is a macro for `_Bool` in C11 via <stdbool.h>; it is a native
 * keyword in C++. Including <stdbool.h> keeps the `bool` spellings
 * below working under both languages with identical ABI (PRD §Type map
 * line 62 treats `_Bool` and `bool` as equivalent). */
#ifndef __cplusplus
#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ------------------------------------------------------------------ */
/* Mid-struct typedefs (PRD §Type map: 14 entries).                    */
/*                                                                     */
/* Each is a thin `struct { T val; }` whose .val type drives Clang's   */
/* opcode selection at the C-source boundary. After IR-pass lowering   */
/* every mid-struct collapses to an opaque `int32_t handle` at the     */
/* runtime ABI.                                                        */
/*                                                                     */
/* Note: `qint_mid_t.val` is `int32_t` (not plain `int`) to preserve   */
/* the Phase 1 binary layout — PRD §Type map line 79.                  */
/* ------------------------------------------------------------------ */
typedef struct { bool               val; } qbool_mid_t;
typedef struct { char               val; } qchar_mid_t;
typedef struct { signed char        val; } qschar_mid_t;
typedef struct { unsigned char      val; } quchar_mid_t;
typedef struct { short              val; } qshort_mid_t;
typedef struct { unsigned short     val; } qushort_mid_t;
typedef struct { int32_t            val; } qint_mid_t;          /* unchanged from Phase 1 */
typedef struct { unsigned int       val; } quint_mid_t;
typedef struct { long               val; } qlong_mid_t;
typedef struct { unsigned long      val; } qulong_mid_t;
typedef struct { long long          val; } qlonglong_mid_t;
typedef struct { unsigned long long val; } qulonglong_mid_t;
typedef struct { float              val; } qfloat_mid_t;
typedef struct { double             val; } qdouble_mid_t;

/* ------------------------------------------------------------------ */
/* Init intrinsics (PRD §Intrinsic surface: 14 entries).               */
/*                                                                     */
/* `qT_mid_t cq_init_<sfx>(T value)` — wrap a classical scalar into    */
/* its mid-struct sibling. The IR pass replaces each call with         */
/* `cqrt_alloc_<W>(value)` per width.                                  */
/* ------------------------------------------------------------------ */
qbool_mid_t        cq_init_i1   (bool               value);
qchar_mid_t        cq_init_c    (char               value);
qschar_mid_t       cq_init_si8  (int8_t             value);
quchar_mid_t       cq_init_ui8  (uint8_t            value);
qshort_mid_t       cq_init_si16 (int16_t            value);
qushort_mid_t      cq_init_ui16 (uint16_t           value);
qint_mid_t         cq_init_si32 (int32_t            value);
quint_mid_t        cq_init_ui32 (uint32_t           value);
qlong_mid_t        cq_init_sl   (long               value);
qulong_mid_t       cq_init_ul   (unsigned long      value);
qlonglong_mid_t    cq_init_sll  (long long          value);
qulonglong_mid_t   cq_init_ull  (unsigned long long value);
qfloat_mid_t       cq_init_f32  (float              value);
qdouble_mid_t      cq_init_f64  (double             value);

/* ------------------------------------------------------------------ */
/* Measure intrinsics (PRD §Intrinsic surface: 14 entries).            */
/*                                                                     */
/* `T cq_measure_<sfx>(qT_mid_t q)` — extract a classical scalar from  */
/* a mid-struct value. Return type mirrors the matching init's `value` */
/* parameter type. The IR pass replaces each call with                 */
/* `cqrt_measure_<W>(handle)` per width.                               */
/* ------------------------------------------------------------------ */
bool               cq_measure_i1   (qbool_mid_t      q);
char               cq_measure_c    (qchar_mid_t      q);
int8_t             cq_measure_si8  (qschar_mid_t     q);
uint8_t            cq_measure_ui8  (quchar_mid_t     q);
int16_t            cq_measure_si16 (qshort_mid_t     q);
uint16_t           cq_measure_ui16 (qushort_mid_t    q);
int32_t            cq_measure_si32 (qint_mid_t       q);
uint32_t           cq_measure_ui32 (quint_mid_t      q);
long               cq_measure_sl   (qlong_mid_t      q);
unsigned long      cq_measure_ul   (qulong_mid_t     q);
long long          cq_measure_sll  (qlonglong_mid_t  q);
unsigned long long cq_measure_ull  (qulonglong_mid_t q);
float              cq_measure_f32  (qfloat_mid_t     q);
double             cq_measure_f64  (qdouble_mid_t    q);

#ifdef __cplusplus
}
#endif

#endif  /* CQ_MID_H_ */
