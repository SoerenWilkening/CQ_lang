/* Frozen interface (cq-arch). Changes only under cq-arch's freeze rule. */
#ifndef CQE_H_
#define CQE_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* checker/rt/cqe.h (C17, linked with the program under test) */
typedef struct { uint32_t bits; char kind; uint32_t nw; uint64_t *w; } cqe_val;   /* 'i' or 'f', little-endian words */
typedef struct { char op[24], pred[8], w[8], to[8], shape[8]; uint8_t rm, exc, strided, unc; } cqe_tname;
int     cqe_parse_template(const char *sym, cqe_tname *out);
typedef int (*cqe_op_fn)(const cqe_tname *, const cqe_val *args, int nargs, cqe_val *out);
void    cqe_register_op(const char *op, cqe_op_fn);   /* a family registers from a constructor */
#define CQE_OP_NOT_MINE 1                            /* M1: cqe_op_fn return, see below */
/* M1 (freeze bead cq-mgi): the op registry and the handler contract.
 * Registry. cqe_register_op keeps every (op, fn) pair, per op name in registration order; a second
 *   registration of the same pair is a no-op. op is the exact cqe_tname.op the dispatcher looks up:
 *   the template's op for cq_template_*, the stem for a non-core cqrt_* call. The dispatcher calls
 *   the handlers of tname.op in registration order until one returns other than CQE_OP_NOT_MINE.
 *   Every handler returning CQE_OP_NOT_MINE, or none registered, is a violation (no_family).
 * Return. 0: out holds the value. CQE_OP_NOT_MINE: the call is outside this handler's family,
 *   decided from tname and nargs alone; the handler has not called cqe_fail or cqe_log nor touched
 *   a rail, and whatever it wrote to out->w is discarded (out->w is zeroed again before the next
 *   handler). -1: the call is malformed and the handler has called cqe_fail; no handler follows.
 * out, owned by the dispatcher. On entry out->w is non-NULL with out->nw = ceil(out->bits / 64)
 *   words (at least 1), all zero, and out->bits and out->kind are preset to the result type: what
 *   the template name implies, or the declared return type on the family path (bits 0 for void).
 *   The handler writes the value into out->w with bits above out->bits zero. It never frees,
 *   reallocates or replaces out->w, and leaves out->bits, out->kind and out->nw at their preset
 *   values; anything else is a violation (result_width).
 * args, owned by the dispatcher and valid for the call only.
 *   Template path (cq_template_*): every argument of the forward form in signature order, literals
 *   included, the _unc form's leading out handle omitted: the select condition, the data operands,
 *   the _rm/_rmq mode, qrom_load's table, n, stride and index. Each is resolved to a value: a
 *   handle to a copy of its rail's value (bits and kind the rail's), a literal to its value (bits
 *   its LLVM type's width; kind 'f' for half, float, double, x86_fp80, else 'i'; ptr a 64-bit 'i').
 *   The handler computes the forward value f(args) whatever tname->unc says; the dispatcher
 *   allocates the result rail (forward) or XORs the value into the out rail and checks the
 *   residue (_unc).
 *   Family path (any other non-core cqrt_*): every ABI argument raw, in signature order: a handle
 *   as its i32 number, a literal as its value, a ptr as a 64-bit 'i'. The family manages rails
 *   through cqe_new_rail, cqe_rail, cqe_xor_into and cqe_set_known and returns a handle as an i32
 *   in out. */
int32_t cqe_new_rail(const char *w, const cqe_val *init, int known);
const cqe_val *cqe_rail(int32_t h);
void    cqe_xor_into(int32_t h, const cqe_val *v);
void    cqe_set_known(int32_t h, int known);
void    cqe_log(const char *json_object);              /* one trace line */
void    cqe_fail(const char *fmt, ...);                /* a violation: logged, run marked failed */

#ifdef __cplusplus
}
#endif

#endif /* CQE_H_ */
