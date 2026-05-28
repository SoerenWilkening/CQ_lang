/* CQ.h — user-facing header.
 *
 * The minimal surface a quantum-algorithm author needs to `#include`.
 * Just the `quantum` annotation that marks variables for the rewriter
 * to lower. Everything else (qint_mid_t, per-width intrinsics) is a
 * detail of the transpiled C and lives in <cq_mid.h>, which the
 * transpiler emits into its output — algorithm authors never see it.
 */
#ifndef CQ_H_
#define CQ_H_

#define quantum __attribute__((annotate("quantum")))

#endif  /* CQ_H_ */
